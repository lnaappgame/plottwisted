import 'package:flutter_test/flutter_test.dart';

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

void main() {
  test('une lettre révélée par le joker Révéler survit à une mauvaise réponse', () {
    final game = _gameOnLevel(1, 1);
    game.revealCount = 1;
    game.useRevealJoker();

    final revealedSlot = game.lockedSlots.first;
    final revealedTileId = game.guess[revealedSlot];
    expect(revealedTileId, isNotNull);

    // Remplit le reste de la grille avec des lettres volontairement fausses
    // (n'importe quelle tuile non utilisée) pour provoquer une mauvaise
    // réponse sans résoudre le niveau.
    for (var i = 0; i < game.slots.length; i++) {
      final slot = game.slots[i];
      if (slot.isSpace || slot.isAuto || game.guess[i] != null) continue;
      final wrongTile = game.pool.indexWhere((t) => !t.used && !t.eliminated);
      game.guess[i] = wrongTile;
      game.pool[wrongTile].used = true;
    }

    final result = game.validate();
    expect(result, isNot('solved'));
    // La lettre gagnée via joker doit toujours être là, avec la même tuile.
    expect(game.guess[revealedSlot], revealedTileId);
    expect(game.lockedSlots.contains(revealedSlot), isTrue);
  });

  test('une lettre verrouillée par joker ne peut pas être effacée manuellement', () {
    final game = _gameOnLevel(1, 1);
    game.revealCount = 1;
    game.useRevealJoker();
    final revealedSlot = game.lockedSlots.first;
    final revealedTileId = game.guess[revealedSlot];

    game.onBlankTap(revealedSlot); // tentative de suppression directe
    expect(game.guess[revealedSlot], revealedTileId);

    game.clearLastLetter(); // tentative via "EFFACER" — doit ignorer la case verrouillée
    expect(game.guess[revealedSlot], revealedTileId);
  });

  test('un nouveau niveau réinitialise les verrous de lettres', () {
    final game = _gameOnLevel(1, 1);
    game.revealCount = 1;
    game.useRevealJoker();
    expect(game.lockedSlots, isNotEmpty);

    game.currentLevelNumber = 2;
    game.loadPuzzle();
    expect(game.lockedSlots, isEmpty);
  });
}
