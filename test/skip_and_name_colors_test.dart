import 'package:flutter_test/flutter_test.dart';

import 'package:cine_devinette/models/puzzle.dart';
import 'package:cine_devinette/models/shop_item.dart';
import 'package:cine_devinette/services/ad_service.dart';
import 'package:cine_devinette/services/app_settings.dart';
import 'package:cine_devinette/services/game_state.dart';
import 'package:cine_devinette/services/save_service.dart';

GameState _gameOnLevel(int world, int level) {
  final saveService = SaveService();
  final game = GameState(adService: AdService(), saveService: saveService, settings: AppSettings(saveService: saveService));
  game.enterWorld(world);
  game.currentLevelNumber = level;
  game.loadPuzzle();
  return game;
}

void _useNameJoker(GameState game, NameColor color, String slot) {
  game.selectNameJoker(color);
  expect(game.onNameTap(slot), isNull);
}

void main() {
  group('Couleurs des noms après jokers', () {
    test('au départ, une seule couleur affichée', () {
      final game = _gameOnLevel(1, 10); // STAR WARS : p1 rouge
      expect(game.displayedColors('p1'), [NameColor.red]);
    });

    test('un joker affiche la nouvelle couleur puis l\'ancienne', () {
      final game = _gameOnLevel(1, 10);
      game.actorCount = 1;
      _useNameJoker(game, NameColor.blue, 'p1');
      expect(game.displayedColors('p1'), [NameColor.blue, NameColor.red]);
      expect(game.p1State, NameColor.blue);
    });

    test('un 2e joker chasse la couleur d\'origine (2 couleurs maximum)', () {
      final game = _gameOnLevel(1, 10);
      game.actorCount = 1;
      game.characterCount = 1;
      _useNameJoker(game, NameColor.blue, 'p1');
      _useNameJoker(game, NameColor.green, 'p1');
      expect(game.displayedColors('p1'), [NameColor.green, NameColor.blue]);
    });

    test('4 jokers sur le même nom : toujours les 2 plus récents, sans erreur', () {
      final game = _gameOnLevel(1, 10);
      game.actorCount = 2;
      game.characterCount = 2;
      _useNameJoker(game, NameColor.blue, 'p1');
      _useNameJoker(game, NameColor.green, 'p1');
      _useNameJoker(game, NameColor.blue, 'p1');
      _useNameJoker(game, NameColor.green, 'p1');
      expect(game.displayedColors('p1'), [NameColor.green, NameColor.blue]);
      expect(game.p1Colors.length, 2);
    });

    test('les couleurs repartent de zéro au niveau suivant', () {
      final game = _gameOnLevel(1, 10);
      game.actorCount = 1;
      _useNameJoker(game, NameColor.blue, 'p1');
      game.currentLevelNumber = 9;
      game.loadPuzzle();
      expect(game.displayedColors('p1').length, 1);
    });
  });

  group('Joker "Passer définitivement"', () {
    test('sans stock : refusé', () {
      final game = _gameOnLevel(1, 3);
      expect(game.solveWithSkipJoker(), isFalse);
      expect(game.lockedWords, isEmpty);
    });

    test('avec stock : consomme 1 joker et résout tout le titre', () {
      final game = _gameOnLevel(1, 3);
      game.grantJokers(skip: 2);
      expect(game.solveWithSkipJoker(), isTrue);
      expect(game.skipJokerCount, 1);
      expect(game.lockedWords.length, game.wordRanges.length);
      expect(game.advanceAfterSolve(), 'next-level');
    });

    test('inutilisable dans le tutoriel', () {
      final game = _gameOnLevel(0, 1);
      game.skipJokerCount = 1;
      expect(game.solveWithSkipJoker(), isFalse);
      expect(game.skipJokerCount, 1);
    });

    test('le stock est sauvegardé', () {
      final game = _gameOnLevel(1, 3);
      game.skipJokerCount = 4;
      expect(game.toJson()['skipJokerCount'], 4);
    });

    test('l\'article de boutique accorde 1 joker', () {
      final item = kShopItems.firstWhere((i) => i.productId == 'skip_level_joker');
      expect(item.jokers.skip, 1);
      expect(item.jokers.total, 1);
      expect(item.isConsumable, isTrue);
    });
  });

  group('"Passer, j\'y reviendrai"', () {
    test('le niveau passe en fin de file', () {
      final game = _gameOnLevel(1, 1);
      expect(game.canPostponeLevel, isTrue);
      game.skipCurrentLevel();
      expect(game.currentLevelNumber, 2);
      expect(game.remainingLevels.last, 1);
    });

    test('impossible sur le dernier niveau restant du monde', () {
      final game = _gameOnLevel(1, 1);
      game.remainingLevels = [7];
      game.currentLevelNumber = 7;
      game.loadPuzzle();
      expect(game.canPostponeLevel, isFalse);
      game.skipCurrentLevel();
      expect(game.currentLevelNumber, 7);
    });

    test('impossible dans le tutoriel', () {
      final game = _gameOnLevel(0, 1);
      expect(game.canPostponeLevel, isFalse);
    });
  });
}
