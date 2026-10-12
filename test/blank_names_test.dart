import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cine_devinette/data/puzzles_data.dart';
import 'package:cine_devinette/services/ad_service.dart';
import 'package:cine_devinette/services/app_settings.dart';
import 'package:cine_devinette/services/game_state.dart';
import 'package:cine_devinette/services/save_service.dart';

GameState _game(String locale) {
  final saveService = SaveService();
  final settings = AppSettings(saveService: saveService)..locale = locale;
  return GameState(adService: AdService(), saveService: saveService, settings: settings);
}

void _expectNoBlank(GameState game, String where) {
  expect(game.displayFor('p1', game.p1State).trim(), isNotEmpty, reason: '$where p1');
  if (game.currentPuzzle.hasP2) {
    expect(game.displayFor('p2', game.p2State).trim(), isNotEmpty, reason: '$where p2');
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('aucun nom vide dans le pitch au départ, en français comme en anglais', () {
    for (final locale in ['fr', 'en']) {
      final game = _game(locale);
      for (final world in kWorlds) {
        for (var level = 1; level <= world.puzzles.length; level++) {
          game.enterWorld(world.number);
          game.currentLevelNumber = level;
          game.loadPuzzle();
          _expectNoBlank(game, '${world.number}-$level ($locale)');
        }
      }
    }
  });

  test('17-6 : un nom sans version anglaise part en bleu (l\'acteur) au lieu d\'un trou', () {
    final game = _game('fr');
    game.enterWorld(17);
    game.currentLevelNumber = 6;
    game.loadPuzzle();
    final redFr = game.p2State; // la petite Maggie : pas d'autre rôle connu en anglais
    // Changement de langue en plein niveau : la couleur gardée n'a pas de nom
    // en anglais, elle passe en bleu.
    game.settings.setLocale('en');
    _expectNoBlank(game, '17-6 après passage en anglais');
    expect(game.p2State, isNot(redFr));
  });
}
