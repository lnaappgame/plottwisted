import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'analytics_service.dart';
import 'tcf_consent.dart';

/// Service publicitaire branché sur AdMob (google_mobile_ads).
///
/// Utilise les ID de blocs d'annonces de TEST publics fournis par Google
/// (aucun compte AdMob requis pour développer) — à remplacer par de vrais ID
/// avant publication, une fois le compte AdMob créé (voir README).
///
/// Le SDK AdMob affiche sa propre interface plein écran, avec sa propre
/// croix de fermeture gérée par Google : on ne bloque jamais l'écran
/// nous-mêmes ni n'impose de délai artificiel, pour rester conforme aux
/// règles d'expérience utilisateur d'AdMob.
///
/// AdMob ne fonctionne pas sur Flutter Web : sur cette plateforme, les pubs
/// sont simplement indisponibles (aucune récompense, aucun blocage).
class AdService {
  final AnalyticsService analytics;
  AdService({AnalyticsService? analytics}) : analytics = analytics ?? AnalyticsService();

  bool isAdFree = false; // achat "retrait des pubs" (définitif)
  DateTime? adFreeUntil; // retrait temporaire (ex. pack "30 jokers + no ads 24h")

  bool get isCurrentlyAdFree => isAdFree || (adFreeUntil != null && DateTime.now().isBefore(adFreeUntil!));

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  bool get _adsSupported =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  /// Flux de consentement RGPD (UMP) — obligatoire avant toute requête
  /// publicitaire pour les utilisateurs UE/UK/Suisse (détecté automatiquement
  /// par Google via l'IP, aucune détection à coder ici). À appeler une seule
  /// fois au démarrage, avant [preload] et avant `MobileAds.instance.initialize()`.
  /// Retourne `false` (jamais bloquant) en cas d'erreur ou de refus — l'app
  /// continue simplement sans pub.
  Future<bool> requestConsentAndPrepareAds() async {
    if (!_adsSupported) return false;
    final completer = Completer<bool>();
    void resolve(bool value) {
      if (!completer.isCompleted) completer.complete(value);
    }

    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () async {
          try {
            await ConsentForm.loadAndShowConsentFormIfRequired((_) async {
              resolve(await ConsentInformation.instance.canRequestAds());
            });
          } catch (_) {
            resolve(false);
          }
        },
        (_) => resolve(false),
      );
    } catch (_) {
      resolve(false);
    }
    return completer.future;
  }

  /// `true` si un bouton "Options de confidentialité des pubs" doit être
  /// proposé quelque part dans l'app (exigence Google UMP, indépendante du
  /// flux de consentement initial).
  Future<bool> get privacyOptionsRequired async {
    if (!_adsSupported) return false;
    try {
      final status = await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
      return status == PrivacyOptionsRequirementStatus.required;
    } catch (_) {
      return false;
    }
  }

  /// Ouvre le formulaire de gestion des options de confidentialité des pubs
  /// — no-op silencieux si non requis pour ce joueur (autre région) ou en
  /// cas d'erreur.
  Future<void> showPrivacyOptionsForm() async {
    if (!await privacyOptionsRequired) return;
    final ferme = Completer<void>();
    try {
      await ConsentForm.showPrivacyOptionsForm((_) {
        if (!ferme.isCompleted) ferme.complete();
      });
      await ferme.future;
      // Le joueur a pu changer d'avis : Analytics suit sa nouvelle réponse
      // tout de suite, sans attendre le prochain lancement.
      final canRequest = await ConsentInformation.instance.canRequestAds();
      await TcfConsent.applyToAnalytics(canRequestAds: canRequest);
    } catch (_) {}
  }

  // Vrais blocs AdMob uniquement avec --dart-define=REAL_ADS=true (build de production) ; sinon pubs de test.
  static const bool _useRealAds = bool.fromEnvironment('REAL_ADS');

  static String get _interstitialUnitId => defaultTargetPlatform == TargetPlatform.iOS
      ? _useRealAds
          ? 'ca-app-pub-7543651245365030/5713118339'
          : 'ca-app-pub-3940256099942544/4411468910'
      : _useRealAds
          ? 'ca-app-pub-7543651245365030/7976627080'
          : 'ca-app-pub-3940256099942544/1033173712';

  static String get _rewardedUnitId => defaultTargetPlatform == TargetPlatform.iOS
      ? _useRealAds
          ? 'ca-app-pub-7543651245365030/3306446844'
          : 'ca-app-pub-3940256099942544/1712485313'
      : _useRealAds
          ? 'ca-app-pub-7543651245365030/7785055396'
          : 'ca-app-pub-3940256099942544/5224354917';

  // Chargement « à la demande » (08/11/2026). Avant, preload() chargeait au
  // lancement une interstitielle ET une pub à récompense, souvent jamais
  // affichées (paliers de fréquence, bouton joker pas touché) : 125 demandes
  // AdMob pour 56 impressions le 07/11, autant de mégaoctets et de batterie
  // dépensés pour rien chez les joueurs. Désormais :
  //  - l'interstitielle n'est chargée que lorsque le niveau qui démarre en
  //    déclenchera une à sa résolution (GameState.loadPuzzle → prepareForcedAd) ;
  //  - la pub à récompense n'est chargée qu'au moment où le joueur la
  //    demande, et l'appel attend son chargement (quelques secondes) ;
  //  - un chargement en cours est partagé : un double tap ne déclenche pas
  //    une deuxième requête ;
  //  - aucun rechargement « pour la prochaine fois » après un affichage.
  bool _enabled = false;
  Future<InterstitialAd?>? _interstitialLoading;
  Future<RewardedAd?>? _rewardedLoading;

  /// Attente maximale d'un chargement demandé par le joueur (pub à récompense).
  static const Duration _rewardedLoadTimeout = Duration(seconds: 8);

  /// Attente maximale de l'interstitielle préparée en avance, si elle n'est
  /// pas encore arrivée au moment de la montrer.
  static const Duration _interstitialGrace = Duration(seconds: 3);

  bool get _canRequest => _enabled && _adsSupported;

  /// À appeler une fois au démarrage, après le consentement et
  /// `MobileAds.instance.initialize()` : autorise les requêtes publicitaires.
  /// Ne charge rien par lui-même.
  void enableAds() {
    if (!_adsSupported) return;
    _enabled = true;
  }

  /// Charge l'interstitielle en avance, à appeler quand démarre un niveau qui
  /// en déclenchera une à sa résolution (voir GameState.loadPuzzle). Sans
  /// effet si une pub est déjà prête ou en cours de chargement, si le joueur
  /// est sans pub, ou si les pubs ne sont pas activées (tests, web,
  /// consentement refusé).
  void prepareForcedAd() {
    if (!_canRequest || isCurrentlyAdFree) return;
    if (_interstitialAd != null || _interstitialLoading != null) return;
    _interstitialLoading = _loadInterstitial();
  }

  Future<InterstitialAd?> _loadInterstitial() async {
    final completer = Completer<InterstitialAd?>();
    try {
      await InterstitialAd.load(
        adUnitId: _interstitialUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            if (!completer.isCompleted) completer.complete(ad);
          },
          onAdFailedToLoad: (_) {
            if (!completer.isCompleted) completer.complete(null);
          },
        ),
      );
    } catch (_) {
      if (!completer.isCompleted) completer.complete(null);
    }
    final ad = await completer.future;
    _interstitialLoading = null;
    return ad;
  }

  Future<RewardedAd?> _loadRewarded() async {
    final completer = Completer<RewardedAd?>();
    try {
      await RewardedAd.load(
        adUnitId: _rewardedUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            if (!completer.isCompleted) completer.complete(ad);
          },
          onAdFailedToLoad: (_) {
            if (!completer.isCompleted) completer.complete(null);
          },
        ),
      );
    } catch (_) {
      if (!completer.isCompleted) completer.complete(null);
    }
    final ad = await completer.future;
    _rewardedLoading = null;
    return ad;
  }

  /// Attend (au plus [timeout]) un chargement déjà en cours, sans en lancer
  /// un nouveau. Un dépassement n'annule pas le chargement : la pub arrivée
  /// en retard reste prête pour la prochaine demande.
  Future<T?> _awaitPending<T>(Future<T?>? pending, Duration timeout) async {
    if (pending == null) return null;
    try {
      return await pending.timeout(timeout);
    } catch (_) {
      return null;
    }
  }

  /// Pub interstitielle forcée. Si la pub préparée par [prepareForcedAd]
  /// n'est pas encore arrivée, on l'attend brièvement ; sinon le niveau
  /// suivant démarre simplement sans pub cette fois-ci (aucun blocage maison
  /// de secours, et aucun chargement « pour la prochaine fois »).
  Future<void> showForcedAd() async {
    if (isCurrentlyAdFree || !_canRequest) return;
    final ad = _interstitialAd ?? await _awaitPending(_interstitialLoading, _interstitialGrace);
    if (ad == null) return;
    _interstitialAd = null;
    final completer = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!completer.isCompleted) completer.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        if (!completer.isCompleted) completer.complete();
      },
    );
    try {
      await ad.show();
    } catch (_) {
      // ad.show() peut lever (ex: état "déjà en cours d'affichage" côté
      // SDK) — sans ce filet, l'exception remonterait non gérée et un
      // éventuel indicateur "pub en cours" côté appelant resterait bloqué.
      ad.dispose();
      if (!completer.isCompleted) completer.complete();
      return;
    }
    await completer.future;
    analytics.logAdWatched(type: 'interstitial');
  }

  /// Pub à récompense pour le bouton "Gagner un joker", chargée à la demande :
  /// l'appel attend le chargement (au plus [_rewardedLoadTimeout]) puis
  /// affiche la pub. Retourne true seulement si la récompense a effectivement
  /// été gagnée (pub regardée jusqu'au bout) ; false si rien n'a pu être
  /// chargé à temps (l'appelant affiche « pub indisponible »).
  Future<bool> showRewardedAdForJoker() async {
    if (!_canRequest) return false;
    var ad = _rewardedAd;
    if (ad == null) {
      _rewardedLoading ??= _loadRewarded();
      ad = await _awaitPending(_rewardedLoading, _rewardedLoadTimeout);
      if (ad == null) return false;
    }
    // Deux taps pendant le même chargement reçoivent la même pub : seul le
    // premier arrivé ici l'affiche, l'autre repart sans rien demander.
    if (!identical(_rewardedAd, ad)) return false;
    _rewardedAd = null;
    var earned = false;
    final completer = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!completer.isCompleted) completer.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    try {
      await ad.show(onUserEarnedReward: (ad, reward) => earned = true);
    } catch (_) {
      // Même filet que showForcedAd() ci-dessus : ad.show() qui lève ne
      // doit jamais laisser un bouton "pub en cours" bloqué côté appelant.
      ad.dispose();
      if (!completer.isCompleted) completer.complete(false);
      return false;
    }
    final result = await completer.future;
    if (result) analytics.logAdWatched(type: 'rewarded');
    return result;
  }
}
