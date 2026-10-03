import 'dart:async';
import 'dart:ui';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';
import 'screens/game_screen.dart';
import 'screens/home_screen.dart';
import 'screens/intro_teaser_screen.dart';
import 'services/ad_service.dart';
import 'services/analytics_service.dart';
import 'services/app_settings.dart';
import 'services/cloud_sync_service.dart';
import 'services/defi_state.dart';
import 'services/enigme_state.dart';
import 'services/game_state.dart';
import 'services/leaderboard_service.dart';
import 'services/multiplayer_matchmaking_service.dart';
import 'services/multiplayer_state.dart';
import 'services/notification_service.dart';
import 'services/purchase_service.dart';
import 'services/review_service.dart';
import 'services/save_service.dart';
import 'services/sound_service.dart';
import 'services/streak_state.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final analytics = AnalyticsService();
  final adService = AdService(analytics: analytics);
  final saveService = SaveService();
  final appSettings = AppSettings(saveService: saveService);
  await appSettings.restore();
  // Persiste immédiatement (plutôt que d'attendre un premier changement de
  // réglage, qui peut ne jamais arriver) : sinon firstLaunchDay et playerId,
  // générés "maintenant" à la construction ci-dessus, ne sont jamais écrits
  // sur disque tant que le joueur ne touche aucun réglage. Résultat observé
  // en prod : firstLaunchDay se réinitialise à "aujourd'hui" à chaque
  // lancement à froid, donc defiIndexFor() (voir defi_service.dart) reste
  // bloqué sur l'index 0 pour toujours — Défi du jour ne change jamais.
  await saveService.saveSettings(appSettings.toJson());
  final gameState = GameState(adService: adService, saveService: saveService, settings: appSettings, analytics: analytics);
  await gameState.restore();
  final enigmeState = EnigmeState(saveService: saveService, settings: appSettings, analytics: analytics);
  await enigmeState.restore();
  final defiState = DefiState(saveService: saveService, analytics: analytics);
  await defiState.restore();
  final leaderboardService = LeaderboardService();
  final multiplayerMatchmaking = MultiplayerMatchmakingService();
  final multiplayerState = MultiplayerState(
      saveService: saveService, matchmaking: multiplayerMatchmaking, settings: appSettings, analytics: analytics);
  await multiplayerState.restore();

  // Série de jours consécutifs joués (tous modes confondus) — récompense
  // câblée ici plutôt que dans StreakState pour éviter toute dépendance
  // croisée entre services (voir streak_state.dart).
  final streakState = StreakState(saveService: saveService);
  await streakState.restore();
  final reviewService = ReviewService();
  streakState.onMilestoneReached = (palier) {
    switch (palier) {
      case 3:
        gameState.grantJokers(hint: 1);
        // Premier moment de vraie fidélité (3 jours de suite joués) : bon
        // point d'ancrage pour la demande d'avis native du store, une seule
        // fois par installation (voir consumeReviewRequestPending).
        if (appSettings.consumeReviewRequestPending()) reviewService.requestReview();
      case 7:
        gameState.grantJokers(redJoker: 1);
      case 14:
        gameState.grantJokers(reveal: 1, eliminate: 1, actor: 1, character: 1);
      case 28:
        // Cycle de 4 semaines complet : le bonus majeur habituel, triplé.
        gameState.grantJokers(redJoker: 3, reveal: 3, eliminate: 3, actor: 3, character: 3);
    }
  };
  // Bonus mineur : tout jour du cycle de 28 qui n'est pas un palier
  // ci-dessus (voir kStreakPaliers) — un joker Indice, le plus modeste des
  // jokers existants.
  streakState.onDailyReward = (_) => gameState.grantJokers(hint: 1);
  // Bonus supplémentaire, cumulé avec celui du jour, quand le jour réel
  // tombe sur un grand événement du cinéma (César, Oscars...) — voir
  // kCinemaEvents. En jokers pour l'instant, faute de monnaie dédiée.
  streakState.onCinemaEventReached =
      (_) => gameState.grantJokers(reveal: 1, eliminate: 1, actor: 1, character: 1);
  defiState.streakState = streakState;
  multiplayerState.streakState = streakState;

  final notificationService = NotificationService();
  final cloudSyncService = CloudSyncService();

  final purchaseService = PurchaseService();
  purchaseService.onPurchaseComplete = (item) {
    if (item.jokers.total > 0) {
      gameState.grantJokers(
        reveal: item.jokers.reveal,
        eliminate: item.jokers.eliminate,
        actor: item.jokers.actor,
        character: item.jokers.character,
        hint: item.jokers.hint,
        redJoker: item.jokers.redJoker,
      );
    }
    if (item.removesAdsForever) {
      adService.isAdFree = true;
    } else if (item.removeAdsForHours > 0) {
      final until = DateTime.now().add(Duration(hours: item.removeAdsForHours));
      if (adService.adFreeUntil == null || until.isAfter(adService.adFreeUntil!)) {
        adService.adFreeUntil = until;
      }
    }
    gameState.flushSave();
    analytics.logPurchase(productId: item.productId);
  };
  // Comme Firebase/pubs/notifications plus bas : touche le réseau (Play
  // Billing/App Store) et peut être lent, en particulier tant que Play
  // Console n'a pas encore les produits configurés (voir PurchaseService) —
  // jamais question de faire attendre le joueur devant le splash natif pour
  // ça. `purchaseService` est déjà construit et fourni au widget tree ci-
  // dessous ; seul l'appel réseau proprement dit passe en arrière-plan.
  unawaited(purchaseService.init());

  runApp(CineDevinetteApp(
    adService: adService,
    gameState: gameState,
    purchaseService: purchaseService,
    appSettings: appSettings,
    enigmeState: enigmeState,
    defiState: defiState,
    leaderboardService: leaderboardService,
    multiplayerState: multiplayerState,
    notificationService: notificationService,
    streakState: streakState,
    saveService: saveService,
    cloudSyncService: cloudSyncService,
  ));

  // Tout ce qui suit touche le réseau (RGPD/pubs, Firebase, permission de
  // notifications) et peut être lent ou échouer selon la connexion — jamais
  // question de faire attendre le joueur devant un écran noir pour ça.
  // Volontairement non attendu ("fire and forget"), et volontairement
  // déclenché depuis _RootNavigator (onComplete de l'intro), pas ici : le
  // popup de consentement RGPD (UMP) est une fenêtre NATIVE Android, pas un
  // widget Flutter, elle s'affiche par-dessus l'écran actuel quel qu'il
  // soit — y compris par-dessus la vidéo d'intro encore en train de jouer
  // en dessous, la rendant invisible sans que rien ne semble "cassé" côté
  // Flutter. Un délai fixe ici serait fragile (calé sur un temps de
  // démarrage du moteur Flutter qui varie selon l'appareil) ; déclencher
  // au vrai onComplete de la vidéo est exact quel que soit ce temps.
}

Future<void> _initBackgroundServices({
  required bool adsSupported,
  required AdService adService,
  required NotificationService notificationService,
  required AppSettings appSettings,
}) async {
  if (adsSupported) {
    // Classement de L'énigme de la semaine — jamais bloquant : une erreur
    // d'initialisation (pas de config sur cette plateforme, hors-ligne...)
    // ne doit jamais empêcher l'app de fonctionner.
    try {
      await Firebase.initializeApp();
      // RGPD : la collecte Analytics est coupée dès l'initialisation, et ne
      // sera réactivée plus bas qu'une fois le consentement obtenu (ou
      // confirmé non requis pour ce joueur) — jamais avant. Sans ça, les
      // évènements automatiques de Firebase (session_start, first_open...)
      // partiraient avant même que le joueur ait pu répondre au popup RGPD.
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(false);
      // Remontée automatique des crashs et erreurs non fatales — seulement
      // si Firebase a pu s'initialiser, jamais de dépendance dure dessus.
      // Toujours active (jamais soumise au consentement RGPD/pubs) : la
      // stabilité de l'app relève de l'intérêt légitime, pas du marketing.
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    } catch (_) {}

    // RGPD (UMP) — obligatoire pour les utilisateurs UE/UK/Suisse avant
    // toute requête publicitaire (détecté automatiquement par Google via
    // l'IP). Le même geste de consentement gouverne aussi Firebase
    // Analytics ci-dessous, plutôt que d'imposer un second popup distinct.
    final canRequestAds = await adService.requestConsentAndPrepareAds();
    try {
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(canRequestAds);
    } catch (_) {}
    if (canRequestAds) {
      await MobileAds.instance.initialize();
      adService.preload();
    }
  }

  // Rappels locaux (Défi du jour, L'énigme de la semaine) — replanifiés à
  // chaque lancement plutôt que de compter sur la persistance des alarmes
  // après un redémarrage du téléphone. Pas de réglage in-app pour les
  // couper : un joueur qui n'en veut pas passe par les paramètres système
  // de l'app (comme requestPermission() le lui propose déjà au 1er lancement).
  await notificationService.init();
  final granted = await notificationService.requestPermission();
  if (granted) {
    await notificationService.scheduleDailyDefiReminder(locale: appSettings.locale);
    await notificationService.scheduleWeeklyEnigmeReminder(locale: appSettings.locale);
  }
}

class CineDevinetteApp extends StatelessWidget {
  final AdService adService;
  final GameState gameState;
  final PurchaseService purchaseService;
  final AppSettings appSettings;
  final EnigmeState enigmeState;
  final DefiState defiState;
  final LeaderboardService leaderboardService;
  final MultiplayerState multiplayerState;
  final NotificationService notificationService;
  final StreakState streakState;
  final SaveService saveService;
  final CloudSyncService cloudSyncService;
  const CineDevinetteApp({
    super.key,
    required this.adService,
    required this.gameState,
    required this.purchaseService,
    required this.appSettings,
    required this.enigmeState,
    required this.defiState,
    required this.leaderboardService,
    required this.multiplayerState,
    required this.notificationService,
    required this.streakState,
    required this.saveService,
    required this.cloudSyncService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appSettings),
        ChangeNotifierProvider.value(value: gameState),
        ChangeNotifierProvider.value(value: enigmeState),
        ChangeNotifierProvider.value(value: defiState),
        ChangeNotifierProvider.value(value: multiplayerState),
        ChangeNotifierProvider.value(value: streakState),
        Provider(create: (_) => SoundService()),
        Provider.value(value: purchaseService),
        Provider.value(value: leaderboardService),
        Provider.value(value: notificationService),
        Provider.value(value: saveService),
        Provider.value(value: cloudSyncService),
      ],
      child: Consumer<AppSettings>(
        builder: (context, settings, _) {
          AppTextStyles.useDyslexicFont = settings.dyslexicMode;
          return MaterialApp(
            title: 'Plot Twist(ed)',
            debugShowCheckedModeBanner: false,
            locale: Locale(settings.locale),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: buildAppTheme(isLight: settings.isLightTheme, dyslexicMode: settings.dyslexicMode),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(settings.largeText ? 1.3 : 1.0),
              ),
              // Le jeu est pensé pour un écran de téléphone en portrait : au-delà
              // d'une certaine largeur (tablette, écran dépliable), on centre le
              // contenu dans une colonne de largeur raisonnable plutôt que de
              // l'étirer bord à bord, avec le fond de la couleur du thème de
              // part et d'autre.
              child: Container(
                color: AppColors(settings.isLightTheme).bgDeep,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: child!,
                  ),
                ),
              ),
            ),
            home: const _RootNavigator(),
          );
        },
      ),
    );
  }
}

enum _Screen { intro, home, game }

class _RootNavigator extends StatefulWidget {
  const _RootNavigator();
  @override
  State<_RootNavigator> createState() => _RootNavigatorState();
}

class _RootNavigatorState extends State<_RootNavigator> with WidgetsBindingObserver {
  _Screen _screen = _Screen.intro;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Filet de sécurité : force l'écriture immédiate de la sauvegarde quand
    // l'app passe en arrière-plan ou se ferme, sans attendre le débounce.
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      // Les 4 services utilisent le même débounce de 600ms avant écriture —
      // sans forcer les 4 ici, seul GameState était vidé sur le disque à
      // temps, exposant les 3 autres à une perte silencieuse si l'app est
      // tuée juste après une action (partie multijoueur, défi, énigme).
      context.read<GameState>().flushSave();
      context.read<EnigmeState>().flushSave();
      context.read<DefiState>().flushSave();
      context.read<MultiplayerState>().flushSave();
      // Sauvegarde cloud automatique, seulement si un compte est lié — un
      // joueur qui n'a jamais lié de compte ne doit jamais déclencher de
      // trafic réseau supplémentaire pour ça.
      final cloudSync = context.read<CloudSyncService>();
      if (cloudSync.isLinked) {
        context.read<SaveService>().readAllForBackup().then(cloudSync.backup);
      }
    }
  }

  Future<void> _startGame() async {
    final game = context.read<GameState>();
    if (!game.gameStarted) {
      final skipTutorial = await _askSkipTutorial();
      if (!mounted) return;
      game.enterWorld(skipTutorial ? 1 : 0);
    }
    setState(() => _screen = _Screen.game);
  }

  Future<bool> _askSkipTutorial() async {
    final settings = context.read<AppSettings>();
    final colors = AppColors(settings.isLightTheme);
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: colors.bgPanel2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🎬 LE RÉALISATEUR', style: AppTextStyles.body(size: 11, weight: FontWeight.w700, color: AppColors.gold)),
              const SizedBox(height: 10),
              Text(
                'Première fois sur les planches ? Le tutoriel te montre les bases '
                'en douceur — ou tu peux passer directement au Monde 1 si tu connais déjà le jeu.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body(size: 14, color: colors.cream).copyWith(height: 1.5),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.crimson),
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('FAIRE LE TUTORIEL', style: AppTextStyles.display(size: 15, color: colors.cream)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text('PASSER AU MONDE 1', style: AppTextStyles.body(size: 13, weight: FontWeight.w700, color: AppColors.gold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return result ?? false;
  }

  void _backToMenu() => setState(() => _screen = _Screen.home);

  bool _backgroundServicesStarted = false;

  /// Déclenché une seule fois, à la toute fin de l'intro (voir le
  /// commentaire dans main() sur pourquoi ce n'est pas lancé plus tôt).
  void _onIntroComplete() {
    if (!mounted) return;
    setState(() => _screen = _Screen.home);
    if (_backgroundServicesStarted) return;
    _backgroundServicesStarted = true;
    final adsSupported =
        !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
    unawaited(_initBackgroundServices(
      adsSupported: adsSupported,
      adService: context.read<GameState>().adService,
      notificationService: context.read<NotificationService>(),
      appSettings: context.read<AppSettings>(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    switch (_screen) {
      case _Screen.intro:
        return IntroTeaserScreen(onComplete: _onIntroComplete);
      case _Screen.home:
        return HomeScreen(onPlay: _startGame);
      case _Screen.game:
        return GameScreen(onBackToMenu: _backToMenu);
    }
  }
}
