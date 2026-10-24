import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cine_devinette/l10n/app_localizations.dart';
import 'package:cine_devinette/models/daily_wheel.dart';
import 'package:cine_devinette/models/joker.dart';
import 'package:cine_devinette/models/puzzle.dart';
import 'package:cine_devinette/services/ad_service.dart';
import 'package:cine_devinette/services/app_settings.dart';
import 'package:cine_devinette/services/game_state.dart';
import 'package:cine_devinette/services/save_service.dart';
import 'package:cine_devinette/services/sound_service.dart';
import 'package:cine_devinette/widgets/daily_wheel_dialog.dart';
import 'package:cine_devinette/widgets/input_mode_tip_dialog.dart';
import 'package:cine_devinette/widgets/pitch_card.dart';

GameState _newGame() {
  final saveService = SaveService();
  return GameState(adService: AdService(), saveService: saveService, settings: AppSettings(saveService: saveService));
}

GameState _gameOnLevel(int world, int level) {
  final game = _newGame();
  game.enterWorld(world);
  game.currentLevelNumber = level;
  game.loadPuzzle();
  return game;
}

Future<void> _pump(WidgetTester tester, GameState game, Widget child) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: game.settings),
        ChangeNotifierProvider.value(value: game),
        Provider(create: (_) => SoundService()),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('1. Plus de pub forcée pour un niveau de plus de 60 s', () {
    test('un niveau long ne déclenche plus la pub hors des paliers', () {
      final game = _gameOnLevel(1, 2);
      game.worldsPlayedHistory = {1, 2, 3, 4, 5, 6, 7, 8};
      game.lastSolveDuration = const Duration(seconds: 150);
      expect(game.mustShowForcedAd, isFalse);
      game.worldsPlayedHistory = {1, 2, 3, 4, 5};
      expect(game.mustShowForcedAd, isFalse);
    });

    test('les paliers fixes restent en place', () {
      final game = _gameOnLevel(1, 3);
      game.worldsPlayedHistory = {1, 2, 3, 4, 5, 6, 7, 8};
      expect(game.mustShowForcedAd, isTrue);
      game.currentLevelNumber = 5;
      expect(game.mustShowForcedAd, isTrue);
    });
  });

  group('4. Les jokers joués restent sur un niveau passé', () {
    late GameState game;
    late int revealedSlot;
    late List<int> eliminated;

    void playJokersThenSkip() {
      game = _gameOnLevel(1, 1);
      game
        ..revealCount = 1
        ..hintCount = 1
        ..actorCount = 1
        ..eliminateCount = 1;
      revealedSlot = game.useRevealJoker()!;
      expect(game.useHintJoker(), isNotNull);
      game.selectNameJoker(NameColor.blue);
      expect(game.onNameTap('p1'), isNull);
      eliminated = game.useEliminateJoker();
      expect(eliminated, isNotEmpty);
      game.skipCurrentLevel();
      expect(game.currentLevelNumber, 2);
      expect(game.hintRevealed, isFalse, reason: 'le niveau suivant repart de zéro');
    }

    void expectJokersKept(GameState g) {
      expect(g.currentLevelNumber, 1);
      expect(g.lockedSlots, contains(revealedSlot));
      expect(g.guess[revealedSlot], isNotNull);
      expect(g.hintRevealed, isTrue);
      expect(g.revealedHintText, isNotNull);
      expect(g.p1State, NameColor.blue);
      for (final i in eliminated) {
        expect(g.pool[i].eliminated, isTrue);
      }
    }

    test('en revenant sur le niveau, tout est encore là', () {
      playJokersThenSkip();
      while (game.currentLevelNumber != 1) {
        game.skipCurrentLevel();
      }
      expectJokersKept(game);
    });

    test('même après avoir fermé et rouvert l\'app', () async {
      playJokersThenSkip();
      await game.flushSave();
      final reopened = _newGame();
      await reopened.restore();
      reopened.loadPuzzle();
      expect(reopened.currentLevelNumber, 2);
      while (reopened.currentLevelNumber != 1) {
        reopened.skipCurrentLevel();
      }
      expectJokersKept(reopened);
    });

    test('un nouveau monde oublie les niveaux passés de l\'ancien', () {
      playJokersThenSkip();
      expect(game.toJson()['postponedLevels'], isNotEmpty);
      game.enterWorld(2);
      expect(game.toJson()['postponedLevels'], isEmpty);
    });
  });

  group('2. Bobine du jour', () {
    test('les chances font 100 % et suivent la demande', () {
      expect(kWheelSegments.fold<int>(0, (s, seg) => s + seg.percent), 100);
      int percentOf(bool Function(WheelSegment) test) =>
          kWheelSegments.where(test).fold<int>(0, (s, seg) => s + seg.percent);
      for (final kind in [JokerKind.reveal, JokerKind.eliminate, JokerKind.character]) {
        expect(percentOf((s) => s.jokers.length == 1 && s.jokers.single == kind), 15);
      }
      for (final kind in [JokerKind.actor, JokerKind.hint, JokerKind.revealWord]) {
        expect(percentOf((s) => s.jokers.length == 1 && s.jokers.single == kind), 10);
      }
      expect(percentOf((s) => s.isJackpot && s.jokers.every((k) => k.isMinor)), 15);
      expect(percentOf((s) => s.isJackpot && s.jokers.every((k) => !k.isMinor)), 10);
      expect(kWheelSegments.any((s) => s.jokers.contains(JokerKind.red)), isFalse);
    });

    test('le tirage respecte les seuils', () {
      expect(wheelSegmentFor(0), 0);
      expect(wheelSegmentFor(0.1499), 0);
      expect(wheelSegmentFor(0.15), 1);
      expect(wheelSegmentFor(0.9999), kWheelSegments.length - 1);
      final counts = List.filled(kWheelSegments.length, 0);
      for (var i = 0; i < 10000; i++) {
        counts[wheelSegmentFor(i / 10000)]++;
      }
      for (var i = 0; i < kWheelSegments.length; i++) {
        expect(counts[i], kWheelSegments[i].percent * 100);
      }
    });

    test('un tour gratuit par jour, puis un seul relancement après pub', () {
      final game = _newGame();
      var now = DateTime(2026, 10, 24, 9);
      game.clock = () => now;
      expect(game.wheelFreeSpinAvailable, isTrue);
      expect(game.wheelAdSpinAvailable, isFalse);
      expect(game.spinWheel(afterAd: true), isNull, reason: 'pas de relancement avant le tour gratuit');

      expect(game.spinWheel(roll: 0.0), 0); // 1 Révéler
      expect(game.revealCount, 1);
      expect(game.wheelFreeSpinAvailable, isFalse);
      expect(game.wheelAdSpinAvailable, isTrue);
      expect(game.spinWheel(), isNull);

      final jackpot = kWheelSegments.indexWhere((s) => s.isJackpot && s.jokers.every((k) => !k.isMinor));
      final (start, sweep) = wheelSegmentArc(jackpot);
      expect(game.spinWheel(afterAd: true, roll: start + sweep / 2), jackpot);
      expect([game.actorCount, game.hintCount, game.revealWordCount], [1, 1, 1]);
      expect(game.wheelAdSpinAvailable, isFalse);

      now = DateTime(2026, 10, 24, 23, 59);
      expect(game.wheelFreeSpinAvailable, isFalse);
      now = DateTime(2026, 10, 25, 0, 0, 1); // minuit, heure du téléphone
      expect(game.wheelFreeSpinAvailable, isTrue);
    });

    test('l\'état de la bobine est sauvegardé', () async {
      final game = _newGame();
      game.clock = () => DateTime(2026, 10, 24, 12);
      game.spinWheel();
      await game.flushSave();
      final reopened = _newGame()..clock = () => DateTime(2026, 10, 24, 18);
      await reopened.restore();
      expect(reopened.wheelFreeSpinAvailable, isFalse);
      expect(reopened.wheelAdSpinAvailable, isTrue);
    });

    testWidgets('tourner, lire le gain 2 s, puis fermer', (tester) async {
      final game = _newGame()..clock = () => DateTime(2026, 10, 24, 12);
      await _pump(
        tester,
        game,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog(context: context, barrierDismissible: false, builder: (_) => const DailyWheelDialog()),
            child: const Text('ouvrir'),
          ),
        ),
      );
      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();
      expect(find.text('FAIRE TOURNER'), findsOneWidget);

      await tester.tap(find.text('FAIRE TOURNER'));
      await tester.pump();
      final total = [game.revealCount, game.eliminateCount, game.characterCount, game.actorCount, game.hintCount, game.revealWordCount]
          .fold<int>(0, (s, n) => s + n);
      expect(total, anyOf(1, 3), reason: 'le gain est accordé dès le lancer');
      expect(find.byKey(const ValueKey('wheelClose')).hitTestable(), findsNothing);

      await tester.pump(DailyWheelDialog.spinDuration);
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.byKey(const ValueKey('wheelResultStrip')), findsOneWidget);
      expect(find.text('TU GAGNES'), findsOneWidget);
      // Le gain reste affiché 2 s avant de pouvoir fermer.
      final close = tester.widget<TextButton>(find.byKey(const ValueKey('wheelClose')));
      expect(close.onPressed, isNull);

      await tester.pump(DailyWheelDialog.resultLock);
      expect(find.text('RELANCER LA ROUE'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('wheelClose')));
      await tester.pumpAndSettle();
      expect(find.byType(DailyWheelDialog), findsNothing);
      await tester.pump(const Duration(seconds: 1)); // sauvegarde différée
    });

    testWidgets('pub indisponible : message, pas de relancement', (tester) async {
      final game = _newGame()..clock = () => DateTime(2026, 10, 24, 12);
      game.spinWheel();
      await _pump(tester, game, const DailyWheelDialog());
      expect(find.text('RELANCER LA ROUE'), findsOneWidget);
      await tester.tap(find.text('RELANCER LA ROUE'));
      await tester.pump();
      expect(find.text('Pub indisponible pour le moment, réessaie plus tard.'), findsOneWidget);
      expect(game.wheelAdSpinAvailable, isTrue);
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('tours du jour épuisés : rendez-vous demain', (tester) async {
      final game = _newGame()..clock = () => DateTime(2026, 10, 24, 12);
      game.spinWheel();
      game.spinWheel(afterAd: true);
      await _pump(tester, game, const DailyWheelDialog());
      expect(find.text('Reviens demain pour un nouveau tour gratuit !'), findsOneWidget);
      expect(find.text('FAIRE TOURNER'), findsNothing);
      await tester.pump(const Duration(seconds: 1));
    });
  });

  group('3. Conseil tuiles ou clavier : 3 s minimum', () {
    testWidgets('impossible de choisir ni de fermer avant 3 s', (tester) async {
      final game = _newGame();
      await _pump(
        tester,
        game,
        Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                showDialog(context: context, barrierDismissible: false, builder: (_) => const InputModeTipDialog()),
            child: const Text('ouvrir'),
          ),
        ),
      );
      await tester.tap(find.text('ouvrir'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('AZERTY'), warnIfMissed: false);
      await tester.pump();
      expect(find.byType(InputModeTipDialog), findsOneWidget);
      expect(game.settings.inputMode, 'tiles');
      await tester.tapAt(const Offset(5, 5)); // à côté du pop-up
      await tester.pump();
      expect(find.byType(InputModeTipDialog), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      await tester.tap(find.text('AZERTY'));
      await tester.pumpAndSettle();
      expect(find.byType(InputModeTipDialog), findsNothing);
      expect(game.settings.inputMode, 'azerty');
      await tester.pump(const Duration(seconds: 1));
    });
  });

  group('5. Info-bulle sur un nom coloré', () {
    testWidgets('toucher un nom rappelle sa couleur, le retoucher la ferme', (tester) async {
      final game = _gameOnLevel(1, 2); // MATRIX : p1 rouge, p2 bleu
      await _pump(tester, game, const Padding(padding: EdgeInsets.only(top: 220), child: PitchCard()));
      final p1 = game.displayFor('p1', NameColor.red);
      final p2 = game.displayFor('p2', NameColor.blue);

      await tester.tap(find.text(p1));
      await tester.pump();
      expect(find.text('Rouge : un autre rôle du même acteur (piège)'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing, reason: 'plus de message « choisis d\'abord un joker »');

      await tester.tap(find.text(p2));
      await tester.pump();
      expect(find.text('Rouge : un autre rôle du même acteur (piège)'), findsNothing);
      expect(find.text('Bleu : le nom de l\'acteur'), findsOneWidget);

      await tester.tap(find.text(p2));
      await tester.pump();
      expect(find.byKey(const ValueKey('nameInfoBubble')), findsNothing);
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('avec un joker armé, toucher le nom joue le joker', (tester) async {
      final game = _gameOnLevel(1, 2);
      game.actorCount = 1;
      await _pump(tester, game, const Padding(padding: EdgeInsets.only(top: 220), child: PitchCard()));
      game.selectNameJoker(NameColor.blue);
      await tester.pump();
      await tester.tap(find.text(game.displayFor('p1', NameColor.red)));
      await tester.pump();
      expect(game.p1State, NameColor.blue);
      expect(find.byKey(const ValueKey('nameInfoBubble')), findsNothing);
      await tester.pump(const Duration(seconds: 1));
    });
  });
}
