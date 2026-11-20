// Préchargement des pubs (rétabli le 20/11/2026) : une interstitielle et une
// pub à récompense sont chargées au lancement puis après chaque affichage, et
// une pub n'est montrée que si elle est déjà prête. GameState.loadPuzzle
// garde un filet : il redemande une interstitielle au début d'un niveau qui
// en déclenchera une. Voir AdService.preload et AdService.prepareForcedAd.
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

  test('filet : interstitielle redemandée seulement aux niveaux qui en déclenchent une', () {
    final ads = _CountingAdService();
    final game = _newGame(ads);
    // 2e monde joué : pubs forcées après les niveaux 5 et 10 seulement.
    game.worldsPlayedHistory = {1, 2};
    game.enterWorld(2);

    game.currentLevelNumber = 4;
    game.loadPuzzle();
    expect(ads.prepareCalls, 0, reason: 'niveau 4 : aucune pub à venir, rien à redemander');

    game.currentLevelNumber = 5;
    game.loadPuzzle();
    expect(ads.prepareCalls, 1, reason: 'niveau 5 : pub après résolution, on vérifie qu\'une est prête');

    game.currentLevelNumber = 10;
    game.loadPuzzle();
    expect(ads.prepareCalls, 2);
  });

  test('premier monde joué et tutoriel : jamais de filet', () {
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

  test('preload() passe par prepareForcedAd pour l\'interstitielle', () {
    final ads = _CountingAdService();
    ads.preload();
    expect(ads.prepareCalls, 1);
  });

  test('sans activation (tests, web, consentement refusé), rien ne part', () async {
    // Le vrai AdService ne touche pas au SDK tant que enableAds() n'a pas été
    // appelé : preload() et prepareForcedAd() sont des no-op, et les deux
    // affichages répondent tout de suite, sans requête ni plugin.
    final ads = AdService();
    ads.preload();
    ads.prepareForcedAd();
    expect(await ads.showRewardedAdForJoker(), isFalse);
    await ads.showForcedAd();
  });

  test('aucune pub prête : les deux affichages rendent la main sans attendre', () async {
    // Garde-fou de la règle « on n'attend jamais un chargement » : sans pub
    // prête, l'appel doit se terminer immédiatement (ici bien avant 1 s),
    // jamais après plusieurs secondes d'attente comme en 1.0.13.
    final ads = AdService();
    final chrono = Stopwatch()..start();
    await ads.showForcedAd();
    expect(await ads.showRewardedAdForJoker(), isFalse);
    expect(chrono.elapsed, lessThan(const Duration(seconds: 1)));
  });
}
