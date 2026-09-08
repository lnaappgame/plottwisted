import 'package:flutter_test/flutter_test.dart';

import 'package:cine_devinette/services/ad_service.dart';
import 'package:cine_devinette/services/app_settings.dart';
import 'package:cine_devinette/services/game_state.dart';
import 'package:cine_devinette/services/save_service.dart';

GameState _game() {
  final saveService = SaveService();
  return GameState(adService: AdService(), saveService: saveService, settings: AppSettings(saveService: saveService));
}

void main() {
  test('juste après le monde 1, le choix propose 2 et 3', () {
    final game = _game();
    game.worldIndex = 1;
    expect(game.worldChoiceOptions, [2, 3]);
  });

  test('une sauvegarde existante en cours de monde 15 propose 16 et 17, pas 2 et 3', () {
    final game = _game();
    game.worldIndex = 15; // sauvegarde d'avant l'ajout de ce mécanisme : reserve jamais persisté
    expect(game.worldChoiceReserve, isNull);
    expect(game.worldChoiceOptions, [16, 17]);
  });

  test('chooseNextWorld après une sauvegarde existante avance correctement', () {
    final game = _game();
    game.worldIndex = 15;
    game.chooseNextWorld(16);
    expect(game.worldIndex, 16);
    expect(game.worldChoiceReserve, 17);
    // Le prochain choix doit continuer après 16/17, pas revenir à 2/3.
    game.worldIndex = 16; // simule la fin du monde 16
    expect(game.worldChoiceOptions, [17, 18]);
  });
}
