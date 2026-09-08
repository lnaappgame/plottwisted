import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

import 'package:cine_devinette/data/puzzles_data.dart';
import 'package:cine_devinette/services/ad_service.dart';
import 'package:cine_devinette/services/app_settings.dart';
import 'package:cine_devinette/services/game_state.dart';
import 'package:cine_devinette/services/save_service.dart';

GameState _game() {
  final saveService = SaveService();
  return GameState(adService: AdService(), saveService: saveService, settings: AppSettings(saveService: saveService));
}

void main() {
  test('worldChoiceOptions ne repropose jamais un monde déjà entré (fuzz, départ frais)', () {
    final maxWorld = kWorlds.map((w) => w.number).reduce(max);
    final rng = Random(42);

    for (var trial = 0; trial < 500; trial++) {
      final game = _game();
      final entered = <int>{1};
      game.worldIndex = 1;
      var steps = 0;
      while (steps < 60) {
        steps++;
        final options = game.worldChoiceOptions;
        if (options.isEmpty) break;
        for (final o in options) {
          expect(entered.contains(o), isFalse,
              reason: 'trial=$trial steps=$steps entered=$entered options=$options '
                  'reserve=${game.worldChoiceReserve}');
        }
        if (options.every((o) => o > maxWorld)) break;
        final chosen = options[rng.nextInt(options.length)];
        game.chooseNextWorld(chosen);
        entered.add(chosen);
      }
    }
  });

  test('worldChoiceOptions ne repropose jamais un monde déjà entré (fuzz, avec restore() réel entre les choix)',
      () async {
    SharedPreferences.setMockInitialValues({});
    final maxWorld = kWorlds.map((w) => w.number).reduce(max);
    final rng = Random(7);

    for (var trial = 0; trial < 80; trial++) {
      final saveService = SaveService();
      final settings = AppSettings(saveService: saveService);
      var game = GameState(adService: AdService(), saveService: saveService, settings: settings);
      final startWorld = 1 + rng.nextInt(5); // simule une sauvegarde déjà en cours
      final entered = <int>{startWorld};
      game.worldIndex = startWorld;
      var steps = 0;
      while (steps < 30) {
        steps++;
        final options = game.worldChoiceOptions;
        if (options.isEmpty) break;
        for (final o in options) {
          expect(entered.contains(o), isFalse,
              reason: 'trial=$trial steps=$steps entered=$entered options=$options '
                  'reserve=${game.worldChoiceReserve}');
        }
        if (options.every((o) => o > maxWorld)) break;
        final chosen = options[rng.nextInt(options.length)];
        game.chooseNextWorld(chosen);
        entered.add(chosen);

        // Simule une fermeture/réouverture de l'app entre deux mondes : passe
        // par le vrai cycle sauvegarde/restauration (SharedPreferences réel,
        // mocké en mémoire), comme ce qui se passe vraiment entre deux
        // lancements de l'app.
        if (rng.nextBool()) {
          await game.flushSave();
          final restored = GameState(adService: AdService(), saveService: saveService, settings: settings);
          await restored.restore();
          game = restored;
        }
      }
    }
  });
}
