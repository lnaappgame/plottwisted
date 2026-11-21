// Nouveau premier lancement (1.0.16, B1 + B4) : seulement pour une toute
// nouvelle installation ; un joueur existant ne voit aucune différence.
// Mesures : tutorial_begin, tutorial_step {step, step_name}, tutorial_complete,
// level_start, level_abandon. Demande de note : jamais pendant le tutoriel.
import 'package:cine_devinette/services/ad_service.dart';
import 'package:cine_devinette/services/analytics_service.dart';
import 'package:cine_devinette/services/app_settings.dart';
import 'package:cine_devinette/services/game_state.dart';
import 'package:cine_devinette/services/save_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Event {
  final String name;
  final Map<String, Object> params;
  _Event(this.name, this.params);
  @override
  String toString() => '$name$params';
}

late List<_Event> events;

List<String> names() => [for (final e in events) e.name];

Future<void> flush() => Future<void>.delayed(Duration.zero);

/// Pose la bonne réponse, lettre par lettre.
void solve(GameState g) {
  for (var i = 0; i < g.slots.length; i++) {
    final s = g.slots[i];
    if (s.isSpace || s.isAuto || g.guess[i] != null) continue;
    final tile = g.pool.firstWhere((t) => t.letter == s.char && !t.used && !t.eliminated);
    g.onLetterTap(tile);
  }
}

class _Setup {
  final AppSettings settings;
  final GameState game;
  final AdService ads;
  _Setup(this.settings, this.game, this.ads);
}

Future<_Setup> newPlayer({required bool fresh, int seconds = 0}) async {
  final save = SaveService();
  final settings = AppSettings(saveService: save);
  await settings.restore();
  if (fresh) settings.beginOnboarding();
  final ads = AdService();
  ads.adsHeld = settings.onboardingActive;
  final game = GameState(adService: ads, saveService: save, settings: settings, playSeconds: () => seconds);
  await game.restore();
  return _Setup(settings, game, ads);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AnalyticsService.resetForTests();
    AnalyticsService.supportedOverride = true;
    events = [];
    AnalyticsService.sender = (name, params) async => events.add(_Event(name, params));
    AnalyticsService.consentDecided(true); // la réponse est déjà donnée : les événements partent tout de suite
  });
  tearDown(AnalyticsService.resetForTests);

  group('joueur existant : aucune différence', () {
    test('sans la clé de la sauvegarde, pas de premier lancement allégé', () async {
      SharedPreferences.setMockInitialValues({});
      final s = await newPlayer(fresh: false);
      s.game.enterWorld(0);
      s.game.startOnboardingMeasure();
      s.game.loadPuzzle();
      await flush();
      expect(s.settings.onboardingActive, isFalse);
      expect(s.game.inOnboardingIntro, isFalse);
      expect(s.game.onboardingRuleLevel, isNull, reason: 'ses fenêtres habituelles restent');
      expect(s.game.revealCount, 0, reason: 'aucun joker offert');
      expect(names(), isNot(contains('tutorial_begin')));
      expect(names(), isNot(contains('tutorial_step')));
      expect(names(), contains('level_start'), reason: 'level_start vaut pour tous');
    });

    test('un joueur qui finit le vieux tutoriel ne déclenche pas tutorial_complete', () async {
      final s = await newPlayer(fresh: false);
      s.game.enterWorld(0);
      for (var level = 1; level <= 4; level++) {
        s.game.loadPuzzle();
        solve(s.game);
        expect(s.game.validate(), 'solved');
        s.game.advanceAfterSolve();
      }
      await flush();
      expect(names(), isNot(contains('tutorial_complete')));
    });

    test('« J\'ai déjà joué » est sans effet hors premier lancement', () async {
      final s = await newPlayer(fresh: false);
      s.game.enterWorld(0);
      s.game.loadPuzzle();
      s.game.skipOnboarding();
      expect(s.game.worldIndex, 0, reason: 'rien ne bouge');
      expect(names(), isNot(contains('tutorial_skip')));
    });

    test('une sauvegarde d\'avant la 1.0.16 se relit sans premier lancement', () async {
      SharedPreferences.setMockInitialValues({
        'cine_devinette_settings_v1': '{"locale":"fr","firstLaunchDay":"2026-10-01T00:00:00.000Z"}',
      });
      final save = SaveService();
      final fresh = await save.loadSettings() == null;
      expect(fresh, isFalse, reason: 'préférences présentes : pas une nouvelle installation');
      final settings = AppSettings(saveService: save);
      await settings.restore();
      expect(settings.onboardingActive, isFalse);
    });
  });

  group('nouvelle installation', () {
    test('ouverture directe sur 0-1 : règle du vert à l\'écran, un seul joker visible et utilisable', () async {
      final s = await newPlayer(fresh: true);
      s.game.enterWorld(0);
      s.game.startOnboardingMeasure();
      s.game.loadPuzzle();
      await flush();
      expect(s.settings.onboardingActive, isTrue);
      expect(s.game.inTutorial, isTrue);
      expect(s.game.currentLevelNumber, 1);
      expect(s.game.inOnboardingIntro, isTrue);
      expect(s.game.onboardingRuleLevel, 1);
      expect(s.game.revealCount, 1, reason: 'le seul joker visible peut servir');
      expect(s.ads.adsHeld, isTrue);
    });

    test('mesures : tutorial_begin, puis une étape à chaque fois, chacune une seule fois', () async {
      final s = await newPlayer(fresh: true);
      s.game.enterWorld(0);
      s.game.startOnboardingMeasure();
      s.game.startOnboardingMeasure(); // relancé : pas de doublon
      s.game.loadPuzzle();
      s.game.loadPuzzle(); // même niveau rechargé : pas de doublon non plus
      s.game.onLetterTap(s.game.pool.first);
      s.game.onLetterTap(s.game.pool[1]); // 2e lettre : pas une nouvelle étape
      await flush();
      expect(names(), ['tutorial_begin', 'tutorial_step', 'level_start', 'tutorial_step', 'tutorial_step']);
      final steps = [
        for (final e in events)
          if (e.name == 'tutorial_step') (e.params['step'], e.params['step_name'])
      ];
      expect(steps, [(1, 'launch'), (2, 'puzzle_1_shown'), (3, 'first_letter')]);
    });

    test('1re réussite, puis les 4 niveaux : tutorial_complete {seconds}, pubs de nouveau permises', () async {
      final s = await newPlayer(fresh: true, seconds: 95);
      s.game.enterWorld(0);
      s.game.startOnboardingMeasure();
      s.game.loadPuzzle();
      solve(s.game);
      expect(s.game.validate(), 'solved');
      await flush();
      expect(
          [for (final e in events) if (e.name == 'tutorial_step') e.params['step_name']],
          ['launch', 'puzzle_1_shown', 'first_letter', 'first_success']);
      expect(s.ads.adsHeld, isTrue, reason: 'aucune pub avant la fin du tutoriel');
      expect(s.game.advanceAfterSolve(), 'next-level');
      for (var level = 2; level <= 4; level++) {
        s.game.loadPuzzle();
        expect(s.game.onboardingRuleLevel, level <= 3 ? level : isNull);
        solve(s.game);
        expect(s.game.validate(), 'solved');
        final status = s.game.advanceAfterSolve();
        expect(status, level == 3 ? 'tutorial-final-transition' : (level == 4 ? 'tutorial-complete' : 'next-level'));
      }
      await flush();
      expect(s.settings.onboardingActive, isFalse);
      expect(s.ads.adsHeld, isFalse);
      final complete = events.where((e) => e.name == 'tutorial_complete').toList();
      expect(complete.length, 1);
      expect(complete.single.params['seconds'], 95);
      expect(
          [for (final e in events) if (e.name == 'tutorial_step') e.params['step_name']],
          ['launch', 'puzzle_1_shown', 'first_letter', 'first_success', 'puzzle_2_shown', 'puzzle_3_shown', 'puzzle_4_shown']);
      expect([for (final e in events) if (e.name == 'level_start') e.params['level']], [1, 2, 3, 4]);
    });

    test('quitter et revenir ne remesure pas les étapes déjà passées (sauvegarde)', () async {
      final s = await newPlayer(fresh: true);
      s.game.enterWorld(0);
      s.game.startOnboardingMeasure();
      s.game.loadPuzzle();
      await flush();
      events.clear();
      // Nouveau lancement : même sauvegarde.
      final again = await newPlayer(fresh: false);
      expect(again.settings.onboardingActive, isTrue, reason: 'tutoriel pas fini : on reprend');
      expect(again.settings.onboardingStep, 2);
      again.game.startOnboardingMeasure();
      again.game.loadPuzzle();
      await flush();
      expect(names(), ['level_start'], reason: 'ni tutorial_begin ni étape déjà comptée');
    });

    test('« J\'ai déjà joué » : sortie vers le monde 1, tutorial_skip et abandon du niveau', () async {
      final s = await newPlayer(fresh: true, seconds: 12);
      s.game.enterWorld(0);
      s.game.startOnboardingMeasure();
      s.game.loadPuzzle();
      s.game.skipOnboarding();
      await flush();
      expect(s.settings.onboardingActive, isFalse);
      expect(s.ads.adsHeld, isFalse);
      expect(s.game.worldIndex, 1);
      final skip = events.firstWhere((e) => e.name == 'tutorial_skip');
      expect(skip.params['seconds'], 12);
      final abandon = events.firstWhere((e) => e.name == 'level_abandon');
      expect(abandon.params['reason'], 'skip_tutorial');
      expect(abandon.params['world'], 0);
      expect(abandon.params['level'], 1);
      expect(names(), isNot(contains('tutorial_complete')));
    });
  });

  test('level_abandon : « Passer, revenir plus tard » compte comme un abandon', () async {
    final s = await newPlayer(fresh: false);
    s.game.worldsPlayedHistory = {1};
    s.game.enterWorld(1);
    s.game.loadPuzzle();
    s.game.skipCurrentLevel();
    await flush();
    final abandon = events.firstWhere((e) => e.name == 'level_abandon');
    expect(abandon.params['reason'], 'postpone');
    expect(abandon.params['level'], 1);
    // Le niveau suivant démarre.
    expect([for (final e in events) if (e.name == 'level_start') e.params['level']], [1, 2]);
  });

  test('changer de langue en cours de niveau ne recompte pas level_start', () async {
    final s = await newPlayer(fresh: false);
    s.game.worldsPlayedHistory = {1};
    s.game.enterWorld(1);
    s.game.loadPuzzle();
    s.settings.locale = 'en';
    s.settings.notifyListeners();
    await flush();
    expect(names().where((n) => n == 'level_start').length, 1);
  });

  group('demande de note', () {
    test('jamais pendant le tutoriel, ni pendant le premier lancement, et sans être comptée', () async {
      final settings = AppSettings(saveService: SaveService());
      expect(settings.consumeReviewRequestPending(inTutorial: true), isFalse);
      settings.beginOnboarding();
      expect(settings.consumeReviewRequestPending(), isFalse);
      expect(settings.reviewRequestCount, 0, reason: 'une demande refusée n\'est pas comptée');
      settings.endOnboarding();
      expect(settings.consumeReviewRequestPending(), isTrue);
    });

    test('2 demandes au plus par installation, espacées de 21 jours', () {
      final settings = AppSettings(saveService: SaveService());
      final t0 = DateTime(2026, 12, 1);
      expect(settings.consumeReviewRequestPending(now: t0), isTrue);
      expect(settings.consumeReviewRequestPending(now: t0.add(const Duration(days: 3))), isFalse, reason: 'trop tôt');
      expect(settings.consumeReviewRequestPending(now: t0.add(const Duration(days: 22))), isTrue);
      expect(settings.consumeReviewRequestPending(now: t0.add(const Duration(days: 80))), isFalse, reason: 'plafond de 2');
      expect(settings.reviewRequestCount, 2);
    });

    test('la fin du niveau 1-5 est un moment de demande, pas un autre niveau ni le tutoriel', () async {
      final s = await newPlayer(fresh: false);
      s.game.worldsPlayedHistory = {1};
      s.game.enterWorld(1);
      for (var level = 1; level <= 5; level++) {
        s.game.currentLevelNumber = level;
        expect(s.game.isLevel15End, level == 5, reason: 'niveau 1-$level');
      }
      s.game.worldsPlayedHistory = {1, 2};
      s.game.enterWorld(2);
      s.game.currentLevelNumber = 5;
      expect(s.game.isLevel15End, isFalse, reason: '2-5 n\'est pas 1-5');
      s.game.enterWorld(0);
      s.game.currentLevelNumber = 5;
      expect(s.game.isLevel15End, isFalse, reason: 'jamais pendant le tutoriel');
    });
  });
}
