import 'dart:async';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform, debugPrint;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_click_guard.dart';
import 'analytics_service.dart';
import 'consent_flow.dart';
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

  /// [applyRequestConfiguration] et [initializeSdk] remplacent les appels au
  /// SDK AdMob dans les tests.
  AdService({
    AnalyticsService? analytics,
    AdClickGuard? clickGuard,
    Future<void> Function(RequestConfiguration configuration)? applyRequestConfiguration,
    Future<void> Function()? initializeSdk,
  })  : analytics = analytics ?? AnalyticsService(),
        clickGuard = clickGuard ?? AdClickGuard(),
        _applyRequestConfiguration =
            applyRequestConfiguration ?? ((c) => MobileAds.instance.updateRequestConfiguration(c)),
        _initializeSdk = initializeSdk ?? (() => MobileAds.instance.initialize());

  final Future<void> Function(RequestConfiguration configuration) _applyRequestConfiguration;
  final Future<void> Function() _initializeSdk;

  /// Plafond de classification des annonces : « T » (Ado), quel que soit le
  /// réglage du compte AdMob, comme Faisceau, Méninges, Jardin et le Clos.
  static RequestConfiguration get requestConfiguration =>
      RequestConfiguration(maxAdContentRating: MaxAdContentRating.t);

  bool _ratingCapApplied = false;

  /// Après le consentement, avant [enableAds] : applique le plafond de
  /// classification puis initialise le SDK. Vrai si les deux ont réussi ;
  /// sinon aucune pub n'est demandée de la session (jamais de requête sans
  /// le plafond).
  Future<bool> prepareSdk() async {
    if (!_adsSupported) return false;
    try {
      await _applyRequestConfiguration(requestConfiguration);
      _ratingCapApplied = true;
      await _initializeSdk();
      return true;
    } catch (e) {
      debugPrint('AdMob : préparation impossible ($e)');
      return false;
    }
  }

  /// Plafond de clics par jour (voir [AdClickGuard]).
  final AdClickGuard clickGuard;

  /// Vrai tant que le premier lancement n'est pas terminé : aucune pub n'est
  /// montrée avant la fin du tutoriel (1.0.16).
  bool adsHeld = false;

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
  /// fois au démarrage, avant [prepareSdk] et [enableAds].
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
            await ConsentForm.loadAndShowConsentFormIfRequired((formError) async {
              if (formError != null) reportUmpError('form', formError.errorCode, formError.message);
              resolve(await ConsentInformation.instance.canRequestAds());
            });
          } catch (e) {
            reportUmpError('form', 0, '$e');
            resolve(false);
          }
        },
        (error) {
          reportUmpError('update', error.errorCode, error.message);
          resolve(false);
        },
      );
    } catch (e) {
      reportUmpError('update', 0, '$e');
      resolve(false);
    }
    return completer.future;
  }

  /// Règle C7 (1.0.16) : mise à jour UMP sans fenêtre au lancement. Vrai si
  /// rien n'est à demander (accord déjà donné, ou pays où le consentement
  /// n'est pas requis) : la mesure et les pubs peuvent démarrer tout de suite.
  /// Faux en cas d'erreur : la fenêtre suit alors son moment habituel.
  Future<bool> consentAlreadySettled() async {
    if (!_adsSupported) return false;
    final done = Completer<bool>();
    void resolve(bool v) {
      if (!done.isCompleted) done.complete(v);
    }

    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () async {
          try {
            final status = await ConsentInformation.instance.getConsentStatus();
            final settled = status == ConsentStatus.notRequired || status == ConsentStatus.obtained;
            resolve(settled && await ConsentInformation.instance.canRequestAds());
          } catch (e) {
            reportUmpError('status', 0, '$e');
            resolve(false);
          }
        },
        (error) {
          reportUmpError('update', error.errorCode, error.message);
          resolve(false);
        },
      );
    } catch (e) {
      reportUmpError('update', 0, '$e');
      resolve(false);
    }
    return done.future;
  }

  /// Une erreur de la fenêtre de consentement ne reste jamais invisible :
  /// erreur non fatale dans Crashlytics (hors consentement, comme les
  /// plantages), jamais d'événement Analytics `ump_error`.
  void reportUmpError(String stage, int code, String message) {
    debugPrint('UMP en erreur ($stage, $code) : $message');
    try {
      unawaited(FirebaseCrashlytics.instance
          .recordError(StateError('UMP $stage $code : $message'), null,
              reason: 'consentement UMP en erreur', fatal: false)
          .catchError((Object _) {}));
    } catch (_) {}
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

  // Préchargement, rétabli le 20/11/2026 (décision de Damien). Une
  // interstitielle et une pub à récompense sont gardées prêtes : chargées au
  // lancement, puis rechargées après chaque affichage.
  //
  // Règle : une pub n'est montrée que si elle est DÉJÀ prête à l'instant où
  // elle est demandée. On n'attend jamais un chargement, pour qu'aucune pub
  // plein écran n'apparaisse en retard, sous le doigt du joueur.
  //
  // Historique : la 1.0.13 chargeait les pubs à la demande, pour économiser
  // des requêtes (125 demandes pour 56 impressions le 07/11), et attendait
  // jusqu'à 3 s l'interstitielle et 8 s la pub à récompense, écran de jeu
  // visible dessous. La semaine suivante, le taux de clics de l'interstitielle
  // Android en France est passé d'environ 6 % à 17 % (relevé AdMob du 20/11,
  // lien de cause non démontré). Un clic accidentel met en danger le compte
  // AdMob commun à tous les jeux : on préfère quelques requêtes en trop.
  bool _enabled = false;
  bool _interstitialLoading = false;
  bool _rewardedLoading = false;

  bool get _canRequest => _enabled && _adsSupported;

  /// À appeler une fois au démarrage, après le consentement et [prepareSdk] :
  /// autorise les requêtes publicitaires et précharge une pub de chaque
  /// format. Sans effet tant que le plafond « T » n'est pas en place.
  void enableAds() {
    if (!_adsSupported || !_ratingCapApplied) return;
    _enabled = true;
    unawaited(clickGuard.load().whenComplete(preload));
  }

  /// Garde une pub de chaque format prête. Sans effet pour un format déjà
  /// prêt ou en cours de chargement, ni si les pubs ne sont pas activées
  /// (tests, web, consentement refusé).
  void preload() {
    prepareForcedAd();
    _preloadRewarded();
  }

  /// S'assure qu'une interstitielle est prête ou en cours de chargement.
  /// Appelé au lancement, après chaque affichage, et en filet quand démarre
  /// un niveau qui en déclenchera une à sa résolution (GameState.loadPuzzle),
  /// au cas où le chargement précédent aurait échoué. Rien n'est chargé pour
  /// un joueur sans pub.
  void prepareForcedAd() {
    if (!_canRequest || isCurrentlyAdFree) return;
    if (_interstitialAd != null || _interstitialLoading) return;
    _interstitialLoading = true;
    try {
      unawaited(InterstitialAd.load(
        adUnitId: _interstitialUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _interstitialLoading = false;
          },
          onAdFailedToLoad: (_) => _interstitialLoading = false,
        ),
      ).catchError((Object _) {
        _interstitialLoading = false;
      }));
    } catch (_) {
      _interstitialLoading = false;
    }
  }

  /// S'assure qu'une pub à récompense est prête ou en cours de chargement.
  /// Chargée même pour un joueur « sans pub » : il garde le droit de regarder
  /// une vidéo pour gagner un joker.
  void _preloadRewarded() {
    if (!_canRequest) return;
    if (_rewardedAd != null || _rewardedLoading) return;
    _rewardedLoading = true;
    try {
      unawaited(RewardedAd.load(
        adUnitId: _rewardedUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _rewardedLoading = false;
          },
          onAdFailedToLoad: (_) => _rewardedLoading = false,
        ),
      ).catchError((Object _) {
        _rewardedLoading = false;
      }));
    } catch (_) {
      _rewardedLoading = false;
    }
  }

  /// Pub interstitielle forcée. Affichée seulement si elle est déjà prête ;
  /// sinon le niveau suivant démarre sans pub cette fois-ci (aucune attente,
  /// aucun blocage maison de secours) et un chargement part pour la
  /// prochaine occasion.
  Future<void> showForcedAd() async {
    if (isCurrentlyAdFree || !_canRequest || adsHeld || clickGuard.interstitialsBlocked) return;
    final ad = _interstitialAd;
    if (ad == null) {
      prepareForcedAd();
      return;
    }
    _interstitialAd = null;
    final completer = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdClicked: (_) => unawaited(clickGuard.recordClick()),
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!completer.isCompleted) completer.complete();
        prepareForcedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        if (!completer.isCompleted) completer.complete();
        prepareForcedAd();
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
      prepareForcedAd();
      return;
    }
    await completer.future;
    analytics.logAdWatched(type: 'interstitial');
  }

  /// Pub à récompense pour le bouton "Gagner un joker". Affichée seulement si
  /// elle est déjà prête. Retourne true seulement si la récompense a
  /// effectivement été gagnée (pub regardée jusqu'au bout) ; false si aucune
  /// pub n'est prête : l'appelant affiche « pub indisponible », un chargement
  /// part, et le joueur peut retoucher le bouton quelques secondes plus tard.
  Future<bool> showRewardedAdForJoker() async {
    // Règle C7 : une vidéo demandée avant la réponse au consentement ouvre la
    // fenêtre maintenant ; la vidéo se charge dès que la réponse est traitée.
    final gate = ConsentGate.instance;
    var justConsented = false;
    if (gate.waiting) {
      gate.askNow();
      await gate.decided;
      justConsented = true;
    }
    if (!_canRequest || adsHeld) return false;
    if (_rewardedAd == null && justConsented) {
      // Les pubs viennent juste d'être activées : le joueur a demandé cette
      // vidéo, on lui laisse quelques secondes pour qu'elle se charge.
      _preloadRewarded();
      for (var i = 0; i < 30 && _rewardedAd == null && _rewardedLoading; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
    }
    final ad = _rewardedAd;
    if (ad == null) {
      _preloadRewarded();
      return false;
    }
    _rewardedAd = null;
    var earned = false;
    final completer = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdClicked: (_) => unawaited(clickGuard.recordClick()),
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!completer.isCompleted) completer.complete(earned);
        _preloadRewarded();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        if (!completer.isCompleted) completer.complete(false);
        _preloadRewarded();
      },
    );
    try {
      await ad.show(onUserEarnedReward: (ad, reward) => earned = true);
    } catch (_) {
      // Même filet que showForcedAd() ci-dessus : ad.show() qui lève ne
      // doit jamais laisser un bouton "pub en cours" bloqué côté appelant.
      ad.dispose();
      if (!completer.isCompleted) completer.complete(false);
      _preloadRewarded();
      return false;
    }
    final result = await completer.future;
    if (result) analytics.logAdWatched(type: 'rewarded');
    return result;
  }
}
