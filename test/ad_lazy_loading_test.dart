// Chargement des pubs « à la demande » (08/11/2026) : l'interstitielle n'est
// préparée que lorsque le niveau qui démarre en déclenchera une à sa
// résolution. Voir AdService.prepareForcedAd et GameState.loadPuzzle.
import 'package:flutter_test/flutter_test.dart';
import 'package:cine_devinette/services/ad_service.dart';
import 'package:cine_devinette/services/app_settings.dart';
import 'package:cine_devinette/services/game_state.dart';
import 'package:cine_devinette/services/save_service.dart';

class _CountingAdService extends AdService {
  int prepareCalls = 0;

  @override
  void prepareForcedAd() {
    prepareCalls++;
  }
}

GameState _newGame(_CountingAdService ads) {
  final saveService = SaveService();
  return GameState(adService: ads, saveService: saveService, settings: AppSettings(saveService: saveService));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('interstitielle préparée seulement aux niveaux qui en déclenchent une', () {
    final ads = _CountingAdService();
    final game = _newGame(ads);
    // 2e monde joué : pubs forcées après les niveaux 5 et 10 seulement.
    game.worldsPlayedHistory = {1, 2};
    game.enterWorld(2);

    game.currentLevelNumber = 4;
    game.loadPuzzle();
    expect(ads.prepareCalls, 0, reason: 'niveau 4 : aucune pub à venir, rien à charger');

    game.currentLevelNumber = 5;
    game.loadPuzzle();
    expect(ads.prepareCalls, 1, reason: 'niveau 5 : pub après résolution, on prépare');

    game.currentLevelNumber = 10;
    game.loadPuzzle();
    expect(ads.prepareCalls, 2);
  });

  test('premier monde joué et tutoriel : jamais de préparation', () {
    final ads = _CountingAdService();
    final game = _newGame(ads);
    game.enterWorld(1);
    for (var level = 1; level <= 10; level++) {
      game.currentLevelNumber = level;
      game.loadPuzzle();
    }
    expect(ads.prepareCalls, 0);

    game.enterWorld(0);
    game.loadPuzzle();
    expect(ads.prepareCalls, 0);
  });

  test('sans activation (tests, web, consentement refusé), rien ne part', () async {
    // Le vrai AdService ne touche pas au SDK tant que enableAds() n'a pas été
    // appelé : prepareForcedAd() est un no-op et la pub à récompense répond
    // false tout de suite, sans requête ni plugin.
    final ads = AdService();
    ads.prepareForcedAd();
    expect(await ads.showRewardedAdForJoker(), isFalse);
    await ads.showForcedAd();
  });
}
