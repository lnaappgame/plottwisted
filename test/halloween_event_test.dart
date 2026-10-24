import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cine_devinette/data/halloween_event_data.dart';
import 'package:cine_devinette/l10n/app_localizations.dart';
import 'package:cine_devinette/screens/halloween_event_screen.dart';
import 'package:cine_devinette/services/ad_service.dart';
import 'package:cine_devinette/services/app_settings.dart';
import 'package:cine_devinette/services/game_state.dart';
import 'package:cine_devinette/services/save_service.dart';
import 'package:cine_devinette/services/sound_service.dart';

GameState _newGame({DateTime? now}) {
  final saveService = SaveService();
  final game = GameState(adService: AdService(), saveService: saveService, settings: AppSettings(saveService: saveService));
  if (now != null) game.clock = () => now;
  return game;
}

/// Répond aux 4 questions du film [i] : juste si [right] vaut true.
void _answerAll(GameState game, int i, List<bool> right) {
  for (var q = 0; q < 4; q++) {
    game.halloween.answer(i, q, right[q] ? 0 : 1);
  }
}

/// Remplit la grille avec le bon titre.
void _typeTitle(GameState game) {
  final e = game.halloween;
  for (var s = 0; s < e.slots.length; s++) {
    final slot = e.slots[s];
    if (slot.isSpace || slot.isAuto) continue;
    final tile = e.pool.firstWhere((t) => t.letter == slot.char && !t.used);
    e.onBlankTap(s);
    e.onLetterTap(tile);
  }
}

int _jokerTotal(GameState g) =>
    g.revealCount + g.eliminateCount + g.characterCount + g.actorCount + g.hintCount + g.revealWordCount;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('le contenu : 10 films, 4 questions de 6 choix, en FR et EN', () {
    expect(kHalloweenFilms.length, 10);
    for (final film in kHalloweenFilms) {
      expect(film.questions.length, 4, reason: film.titleFr);
      for (final q in film.questions) {
        expect(q.choicesFr.length, 6, reason: q.fr);
        expect(q.choicesEn.length, 6, reason: q.en);
        expect(q.choicesFr.toSet().length, 6, reason: 'choix en double : ${q.fr}');
        expect(q.choicesEn.toSet().length, 6, reason: 'duplicate choice: ${q.en}');
      }
    }
  });

  group('calendrier', () {
    test('5 films le premier jour, puis un de plus par jour', () {
      var now = DateTime(2026, 10, 26, 20);
      final game = _newGame()..clock = () => now;
      final e = game.halloween;
      expect(e.availableCount, 5);
      e.markVisited();
      expect(e.availableCount, 5);
      expect(e.daysUntilAvailable(5), 1);
      expect(e.daysUntilAvailable(9), 5);
      now = DateTime(2026, 10, 27, 0, 5);
      expect(e.availableCount, 6);
      now = DateTime(2026, 10, 31, 9);
      expect(e.availableCount, 10);
      expect(e.moreToCome, isFalse);
    });

    test('un joueur arrivé tard a tout le dernier jour', () {
      var now = DateTime(2026, 11, 5, 10);
      final game = _newGame()..clock = () => now;
      game.halloween.markVisited();
      expect(game.halloween.availableCount, 7, reason: 'il reste 3 jours : 10 - 3');
      now = DateTime(2026, 11, 8, 23);
      expect(game.halloween.availableCount, 10);
      expect(game.halloween.isActive, isTrue);
      now = DateTime(2026, 11, 9, 0, 1);
      expect(game.halloween.isActive, isFalse);
    });

    test('films du jour finis : « reviens demain »', () {
      final game = _newGame(now: DateTime(2026, 10, 26, 12));
      final e = game.halloween..markVisited();
      for (var i = 0; i < 5; i++) {
        e.progressOf(i).solved = true;
      }
      expect(e.waitingForTomorrow, isTrue);
    });
  });

  group('questions et indices', () {
    test('bonnes réponses = indices, ratées cachées, pub = la plus simple d\'abord', () {
      final game = _newGame(now: DateTime(2026, 10, 26));
      final e = game.halloween;
      _answerAll(game, 0, [true, false, true, false]);
      expect(e.questionsDone(0), isTrue);
      expect([for (var q = 0; q < 4; q++) e.clueFound(0, q)], [true, false, true, false]);
      expect(e.hiddenClueCount(0), 2);
      expect(e.nextClueToReveal(0), 1);
      e.revealClue(0);
      expect(e.clueFound(0, 1), isTrue);
      expect(e.nextClueToReveal(0), 3);
      e.revealClue(0);
      expect(e.hiddenClueCount(0), 0);
      e.revealClue(0); // plus rien à dévoiler : sans effet
      expect(e.progressOf(0).adRevealed, {1, 3});
      expect(e.perfect(0), isFalse);
    });

    test('une réponse donnée ne change plus', () {
      final game = _newGame();
      expect(game.halloween.answer(1, 0, 3), isFalse);
      expect(game.halloween.answer(1, 0, 0), isFalse);
    });

    test('l\'ordre des choix est mélangé mais stable', () {
      final e = _newGame().halloween;
      final order = e.choiceOrder(0, 1);
      expect(order.toSet(), {0, 1, 2, 3, 4, 5});
      expect(e.choiceOrder(0, 1), order);
    });
  });

  group('trouver le film', () {
    test('mauvais titre : la grille se vide ; bon titre : joker + avatar citrouille', () {
      final game = _newGame(now: DateTime(2026, 10, 26));
      final e = game.halloween;
      _answerAll(game, 0, [true, true, false, true]);
      e.startGuess(0);
      // Lettres au hasard : faux.
      for (final tile in e.pool.where((t) => !e.slots.any((s) => s.char == t.letter)).take(e.slots.length)) {
        e.onLetterTap(tile);
      }
      for (final tile in e.pool) {
        if (!e.gridFull && !tile.used) e.onLetterTap(tile);
      }
      expect(e.validate(), 'wrong');
      expect(e.guess.every((g) => g == null), isTrue);

      final before = _jokerTotal(game);
      _typeTitle(game);
      expect(e.validate(), 'solved');
      expect(e.progressOf(0).solved, isTrue);
      expect(_jokerTotal(game), before + 1);
      expect(e.lastReward!.joker.isMinor, isTrue, reason: 'une erreur : joker mineur');
      expect(e.lastReward!.pumpkinUnlocked, isTrue);
      expect(game.settings.isAvatarUnlocked(kPumpkinAvatar), isTrue);
    });

    test('sans faute : joker majeur', () {
      final game = _newGame();
      _answerAll(game, 2, [true, true, true, true]);
      game.halloween.startGuess(2);
      _typeTitle(game);
      expect(game.halloween.validate(), 'solved');
      expect(game.halloween.lastReward!.joker.isMinor, isFalse);
    });

    test('titre en anglais quand le jeu est en anglais', () {
      final game = _newGame()..settings.setLocale('en');
      game.halloween.startGuess(1);
      expect(game.halloween.slots.map((s) => s.char).join(), 'THE ADDAMS FAMILY');
    });

    test('les 10 films : bonus final et citrouille en feu, une seule fois', () {
      final game = _newGame(now: DateTime(2026, 11, 8));
      final e = game.halloween;
      for (var i = 0; i < 10; i++) {
        _answerAll(game, i, [true, true, true, true]);
        e.startGuess(i);
        final redBefore = game.redJokerCount;
        _typeTitle(game);
        expect(e.validate(), 'solved', reason: kHalloweenFilms[i].titleFr);
        if (i < 9) {
          expect(e.lastReward!.finalReward, isFalse);
          expect(game.redJokerCount, redBefore);
        }
      }
      expect(e.lastReward!.finalReward, isTrue);
      expect(game.redJokerCount, 1);
      expect(game.settings.isAvatarUnlocked(kFirePumpkinAvatar), isTrue);
      expect(e.allSolved, isTrue);
      expect(e.finalRewardGranted, isTrue);
    });
  });

  test('l\'event est sauvegardé avec le jeu', () async {
    final game = _newGame(now: DateTime(2026, 10, 26));
    game.halloween.markVisited();
    _answerAll(game, 0, [true, false, true, true]);
    game.halloween.revealClue(0);
    game.halloween.progressOf(3).solved = true;
    await game.flushSave();
    final reopened = _newGame(now: DateTime(2026, 10, 27));
    await reopened.restore();
    final e = reopened.halloween;
    expect(e.firstDay, '2026-10-26');
    expect(e.availableCount, 6);
    expect(e.progressOf(0).answers, [0, 1, 0, 0]);
    expect(e.progressOf(0).adRevealed, {1});
    expect(e.progressOf(3).solved, isTrue);
  });

  test('avatars d\'event : sauvegardés, et jamais affichés sans avoir été gagnés', () async {
    final saveService = SaveService();
    // Champs posés directement (sans notifyListeners) : pas d'écritures
    // asynchrones concurrentes dans le faux SharedPreferences.
    final settings = AppSettings(saveService: saveService)
      ..unlockedAvatars.add(kPumpkinAvatar)
      ..avatar = kPumpkinAvatar;
    await saveService.saveSettings(settings.toJson());
    final reloaded = AppSettings(saveService: saveService);
    await reloaded.restore();
    expect(reloaded.isAvatarUnlocked(kPumpkinAvatar), isTrue);
    expect(reloaded.avatar, kPumpkinAvatar);

    SharedPreferences.setMockInitialValues({});
    final cheat = AppSettings(saveService: SaveService())..avatar = kFirePumpkinAvatar;
    await SaveService().saveSettings(cheat.toJson());
    final restored = AppSettings(saveService: SaveService());
    await restored.restore();
    expect(cheat.avatar, kFirePumpkinAvatar);
    expect(restored.avatar, isNot(kFirePumpkinAvatar));
  });

  testWidgets('écran : jouer un film des questions jusqu\'au titre', (tester) async {
    final game = _newGame(now: DateTime(2026, 10, 26, 12));
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
          home: const HalloweenEventScreen(),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('FILM 1'), findsOneWidget);
    await tester.scrollUntilVisible(find.byKey(const ValueKey('eventFilm9')), 200);
    expect(find.text('Disponible dans 5 jours'), findsOneWidget);
    await tester.scrollUntilVisible(find.byKey(const ValueKey('eventFilm0')), -200);

    await tester.tap(find.byKey(const ValueKey('eventFilm0')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800)); // transition de page (le fond animé empêche pumpAndSettle)
    expect(find.text('QUESTION 1/4  ·  Facile'), findsOneWidget);
    for (var q = 0; q < 4; q++) {
      // Bonne réponse aux questions 1 et 3, mauvaise aux 2 et 4.
      await tester.tap(find.byKey(ValueKey(q.isEven ? 'eventChoice0' : 'eventChoice4')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1200));
    }
    await tester.pump();
    expect(find.byKey(const ValueKey('eventClue0')), findsOneWidget);
    expect(find.text('La citrouille'), findsOneWidget);
    expect(find.byKey(const ValueKey('eventMissed1')), findsOneWidget);
    expect(find.text('Dévoiler un indice (2)'), findsOneWidget);

    _typeTitle(game);
    await tester.pump();
    await tester.ensureVisible(find.byKey(const ValueKey('eventValidate')));
    await tester.tap(find.byKey(const ValueKey('eventValidate')));
    await tester.pump();
    expect(find.byKey(const ValueKey('eventSolvedTitle')), findsOneWidget);
    expect(find.text('Nouvel avatar débloqué : Tête de citrouille !'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });
}
