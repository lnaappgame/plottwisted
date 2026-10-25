import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cine_devinette/models/joker.dart';
import 'package:cine_devinette/services/ad_service.dart';
import 'package:cine_devinette/services/app_settings.dart';
import 'package:cine_devinette/services/game_state.dart';
import 'package:cine_devinette/services/save_service.dart';
import 'package:cine_devinette/services/share_service.dart';

GameState _gameOnLevel(int world, int level) {
  final saveService = SaveService();
  final game = GameState(adService: AdService(), saveService: saveService, settings: AppSettings(saveService: saveService));
  game.enterWorld(world);
  game.currentLevelNumber = level;
  game.loadPuzzle();
  return game;
}

/// Remplit les cases encore vides : avec les bonnes lettres, sauf la première
/// case du mot [wrongWord] qui reçoit une lettre absente du titre.
void _fill(GameState game, {int? wrongWord}) {
  final answer = game.slots.map((s) => s.char).join();
  for (var w = 0; w < game.wordRanges.length; w++) {
    for (final i in game.wordRanges[w]) {
      if (game.slots[i].isAuto || game.guess[i] != null) continue;
      final wrong = w == wrongWord && i == game.wordRanges[w].first;
      final tile = game.pool.firstWhere(
          (t) => !t.used && !t.eliminated && (wrong ? !answer.contains(t.letter) : t.letter == game.slots[i].char));
      game.onBlankTap(i);
      game.onLetterTap(tile);
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('grilles', () {
    test('une ligne par validation, un carré par mot', () {
      expect(
          ShareService.attemptGrid([
            [false, true],
            [true, true],
          ]),
          '🟥🟩\n🟩🟩\n');
      expect(ShareService.attemptGrid([]), '');
    });

    test('au-delà de 6 validations, seules les dernières restent', () {
      final rows = [
        for (var i = 0; i < 8; i++) [i == 7]
      ];
      final grid = ShareService.attemptGrid(rows);
      expect(grid.split('\n').first, '…');
      expect(grid.split('\n').where((l) => l.isNotEmpty).length, 7);
      expect(grid.trimRight().endsWith('🟩'), isTrue);
    });

    test('détails : temps, jokers en icônes, ou rien / passé', () {
      String d(List<JokerKind> j, {bool skipped = false}) =>
          ShareService.resultDetails('0:47', j, skipped: skipped, noJoker: '0 joker 💪', skippedLabel: '⏭️ passé');
      expect(d([]), '⏱️ 0:47 · 0 joker 💪');
      expect(d([JokerKind.reveal, JokerKind.eliminate]), '⏱️ 0:47 · 🃏 💡✂️');
      expect(d([JokerKind.reveal], skipped: true), '⏱️ 0:47 · ⏭️ passé');
    });

    test('Défi du jour et semaine de l\'énigme', () {
      expect(ShareService.defiGrid([true, false, true]), '🟩🟥🟩\n');
      expect(ShareService.defiGrid([]), '');
      expect(ShareService.weekBar(1), '🟩⬜⬜⬜⬜⬜⬜');
      expect(ShareService.weekBar(3), '⬛⬛🟩⬜⬜⬜⬜');
      expect(ShareService.enigmeWeekNumber(DateTime.utc(2026, 10, 19)), 1);
      expect(ShareService.enigmeWeekNumber(DateTime.utc(2026, 10, 26)), 2);
      expect(ShareService.enigmeWeekNumber(DateTime.utc(2026, 1, 5)), 1);
    });
  });

  group('suivi d\'un niveau', () {
    test('chaque validation ajoute une ligne, les jokers sont notés', () {
      final game = _gameOnLevel(8, 8); // JURASSIC PARK : 2 mots
      game.grantJokers(eliminate: 1);
      expect(game.attemptRows, isEmpty);
      expect(game.useEliminateJoker(), isNotEmpty);
      _fill(game, wrongWord: 1);
      expect(game.validate(), 'wrong');
      _fill(game);
      expect(game.validate(), 'solved');
      expect(game.attemptRows, [
        [true, false],
        [true, true],
      ]);
      expect(game.jokersUsed, [JokerKind.eliminate]);
      expect(game.isHappySolve, isFalse);
    });

    test('du premier coup sans joker après le monde 1 : moment pour un avis', () {
      final game = _gameOnLevel(8, 8);
      _fill(game);
      expect(game.validate(), 'solved');
      expect(game.isHappySolve, isTrue);

      final early = _gameOnLevel(1, 2);
      _fill(early);
      expect(early.validate(), 'solved');
      expect(early.isHappySolve, isFalse, reason: 'pas dès le premier monde');
    });

    test('les lignes et jokers suivent le niveau quand on le passe pour plus tard', () {
      final game = _gameOnLevel(8, 8);
      game.grantJokers(eliminate: 1);
      game.useEliminateJoker();
      _fill(game, wrongWord: 1);
      expect(game.validate(), 'wrong');
      final key = game.currentLevelNumber;
      game.skipCurrentLevel();
      expect(game.attemptRows, isEmpty);
      while (game.currentLevelNumber != key) {
        game.skipCurrentLevel();
      }
      expect(game.attemptRows.length, 1);
      expect(game.jokersUsed, [JokerKind.eliminate]);
    });

    test('un nouveau niveau repart de zéro', () {
      final game = _gameOnLevel(8, 8);
      _fill(game);
      game.validate();
      game.advanceAfterSolve();
      game.loadPuzzle();
      expect(game.attemptRows, isEmpty);
      expect(game.jokersUsed, isEmpty);
    });
  });
}
