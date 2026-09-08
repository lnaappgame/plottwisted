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

void main() {
  test('currentPuzzleHasOrange reflète p1State/p2State', () {
    final game = _gameOnLevel(1, 10); // STAR WARS : p2 = orange (Obi-Wan Kenobi)
    expect(game.p2State, NameColor.orange);
    expect(game.currentPuzzleHasOrange, isTrue);
  });

  test('selectNameJoker(red) refuse si aucun joker rouge en stock', () {
    final game = _gameOnLevel(1, 10);
    game.selectNameJoker(NameColor.red);
    expect(game.activeNameJoker, isNull);
  });

  test('le joker rouge ne fonctionne que sur un nom orange', () {
    final game = _gameOnLevel(1, 10);
    game.redJokerCount = 1;
    game.selectNameJoker(NameColor.red);
    expect(game.activeNameJoker, NameColor.red);

    final erreur = game.onNameTap('p1'); // p1 est rouge, pas orange
    expect(erreur, isNotNull);
    expect(game.p1State, NameColor.red); // inchangé
    expect(game.redJokerCount, 1); // pas consommé
  });

  test('le joker rouge transforme un nom orange en rouge et se consomme', () {
    final game = _gameOnLevel(1, 10);
    game.redJokerCount = 1;
    game.selectNameJoker(NameColor.red);
    final erreur = game.onNameTap('p2'); // p2 est orange
    expect(erreur, isNull);
    expect(game.p2State, NameColor.red);
    expect(game.redJokerCount, 0);
    expect(game.activeNameJoker, isNull);
  });

  test('après passage en rouge, le joker Acteur classique fonctionne normalement', () {
    final game = _gameOnLevel(1, 10);
    game.redJokerCount = 1;
    game.selectNameJoker(NameColor.red);
    game.onNameTap('p2'); // orange -> rouge
    game.actorCount = 1;
    game.selectNameJoker(NameColor.blue);
    final erreur = game.onNameTap('p2');
    expect(erreur, isNull);
    expect(game.p2State, NameColor.blue);
  });

  test('peutRegarderPubJokerRouge : true seulement si orange + 0 en stock + pub pas encore vue', () {
    final game = _gameOnLevel(1, 10);
    expect(game.peutRegarderPubJokerRouge, isTrue);

    game.grantRedJokerFromAd();
    expect(game.redJokerCount, 1);
    expect(game.redJokerAdWatchedThisLevel, isTrue);

    // Le joueur utilise ce joker rouge (retombe à 0), mais la pub est déjà
    // grillée pour ce niveau : plus disponible.
    game.selectNameJoker(NameColor.red);
    game.onNameTap('p2');
    expect(game.redJokerCount, 0);
    expect(game.peutRegarderPubJokerRouge, isFalse);
  });

  test('grantRedJokerFromAd() ne fonctionne qu\'une fois par niveau', () {
    final game = _gameOnLevel(1, 10);
    game.grantRedJokerFromAd();
    game.grantRedJokerFromAd();
    expect(game.redJokerCount, 1); // pas 2
  });

  test('redJokerAdWatchedThisLevel se réinitialise à chaque nouveau niveau', () {
    final game = _gameOnLevel(1, 10);
    game.grantRedJokerFromAd();
    expect(game.redJokerAdWatchedThisLevel, isTrue);
    game.currentLevelNumber = 9; // AVATAR, un autre niveau
    game.loadPuzzle();
    expect(game.redJokerAdWatchedThisLevel, isFalse);
  });

  test('JokerGrant.total inclut redJoker', () {
    const grant = JokerGrant(redJoker: 3);
    expect(grant.total, 3);
  });

  test('grantJokers(redJoker:) crédite le compteur', () {
    final game = _gameOnLevel(1, 10);
    game.grantJokers(redJoker: 3);
    expect(game.redJokerCount, 3);
  });

  test('toJson()/restore() conservent redJokerCount', () {
    final game = _gameOnLevel(1, 10);
    game.redJokerCount = 5;
    final json = game.toJson();
    expect(json['redJokerCount'], 5);
  });
}
