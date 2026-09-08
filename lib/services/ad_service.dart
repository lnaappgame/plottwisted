import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'analytics_service.dart';

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
    try {
      await ConsentForm.showPrivacyOptionsForm((_) {});
    } catch (_) {}
  }

  static String get _interstitialUnitId => defaultTargetPlatform == TargetPlatform.iOS
      ? 'ca-app-pub-3940256099942544/4411468910'
      : 'ca-app-pub-3940256099942544/1033173712';

  static String get _rewardedUnitId => defaultTargetPlatform == TargetPlatform.iOS
      ? 'ca-app-pub-3940256099942544/1712485313'
      : 'ca-app-pub-3940256099942544/5224354917';

  /// À appeler une fois au démarrage pour précharger les deux formats.
  void preload() {
    if (!_adsSupported) return;
    _loadInterstitial();
    _loadRewarded();
  }

  void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: _interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (_) => _interstitialAd = null,
      ),
    );
  }

  void _loadRewarded() {
    RewardedAd.load(
      adUnitId: _rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedAd = ad,
        onAdFailedToLoad: (_) => _rewardedAd = null,
      ),
    );
  }

  /// Pub interstitielle forcée. Ne fait rien si aucune pub n'est encore
  /// chargée (pas de blocage maison de secours) : le niveau suivant démarre
  /// simplement sans pub cette fois-ci.
  Future<void> showForcedAd() async {
    if (isCurrentlyAdFree || !_adsSupported) return;
    final ad = _interstitialAd;
    if (ad == null) {
      _loadInterstitial();
      return;
    }
    _interstitialAd = null;
    final completer = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!completer.isCompleted) completer.complete();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        if (!completer.isCompleted) completer.complete();
        _loadInterstitial();
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

  /// Pub à récompense pour le bouton "Gagner un joker". Retourne true
  /// seulement si la récompense a effectivement été gagnée (pub regardée
  /// jusqu'au bout).
  Future<bool> showRewardedAdForJoker() async {
    if (!_adsSupported) return false;
    final ad = _rewardedAd;
    if (ad == null) {
      _loadRewarded();
      return false;
    }
    _rewardedAd = null;
    var earned = false;
    final completer = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!completer.isCompleted) completer.complete(earned);
        _loadRewarded();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        if (!completer.isCompleted) completer.complete(false);
        _loadRewarded();
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
