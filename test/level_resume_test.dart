import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cine_devinette/models/puzzle.dart';
import 'package:cine_devinette/services/ad_service.dart';
import 'package:cine_devinette/services/app_settings.dart';
import 'package:cine_devinette/services/game_state.dart';
import 'package:cine_devinette/services/save_service.dart';

GameState _newGame(SaveService saveService) {
  final settings = AppSettings(saveService: saveService)
    ..sfxOn = false
    ..vibrationsOn = false;
  return GameState(adService: AdService(), saveService: saveService, settings: settings);
}

/// Simule une fermeture puis un relancement de l'app : nouvel état, même sauvegarde.
Future<GameState> _relaunch(GameState before) async {
  await before.flushSave();
  final after = _newGame(before.saveService);
  await after.restore();
  return after;
}

List<List<Object>> _poolOf(GameState game) => [
      for (final t in game.pool) [t.letter, t.used, t.eliminated, t.consumed]
    ];

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('jokers joués puis app fermée : le niveau rouvre avec leurs effets', () async {
    final game = _newGame(SaveService());
    game.enterWorld(1);
    game.loadPuzzle();
    game
      ..revealCount = 1
      ..eliminateCount = 1
      ..hintCount = 1
      ..characterCount = 1;
    final revealed = game.useRevealJoker();
    final eliminated = game.useEliminateJoker();
    game.useHintJoker();
    game.selectNameJoker(NameColor.green);
    expect(game.onNameTap('p1'), isNull);
    expect(revealed, isNotNull);
    expect(eliminated, isNotEmpty);

    final pool = _poolOf(game);
    final guess = List.of(game.guess);
    final p1 = List.of(game.p1Colors);
    final hint = game.revealedHintText;

    final after = await _relaunch(game);
    expect(after.puzzleLoaded, isFalse);
    after.loadPuzzle(); // entrée dans l'écran de jeu
    expect(_poolOf(after), pool);
    expect(after.guess, guess);
    expect(after.lockedSlots, contains(revealed));
    expect(after.p1Colors, p1);
    expect(after.hintRevealed, isTrue);
    expect(after.revealedHintText, hint);
    // Les jokers dépensés restent dépensés.
    expect(after.revealCount + after.eliminateCount + after.hintCount + after.characterCount, 0);
  });

  test('l\'état sauvegardé survit à une sauvegarde faite avant de rentrer dans le jeu', () async {
    final game = _newGame(SaveService());
    game.enterWorld(1);
    game.loadPuzzle();
    game.eliminateCount = 1;
    game.useEliminateJoker();
    final pool = _poolOf(game);

    final middle = await _relaunch(game); // relancée, mais le joueur reste à l'accueil
    final after = await _relaunch(middle);
    after.loadPuzzle();
    expect(_poolOf(after), pool);
  });

  test('un autre niveau ne reprend pas l\'état sauvegardé', () async {
    final game = _newGame(SaveService());
    game.enterWorld(1);
    game.loadPuzzle();
    game.eliminateCount = 1;
    game.useEliminateJoker();

    final after = await _relaunch(game);
    after.currentLevelNumber = 2;
    after.loadPuzzle();
    expect(after.pool.any((t) => t.eliminated), isFalse);
  });

  test('langue changée entre-temps : noms et indice gardés, grille neuve', () async {
    final saveService = SaveService();
    final game = _newGame(saveService);
    // Monde 1 niveau 4 : réponse différente en anglais ? Sinon on cherche plus loin.
    game.enterWorld(1);
    var level = 1;
    while (true) {
      game.currentLevelNumber = level;
      game.loadPuzzle();
      if (normalize(game.currentPuzzle.titleFor('fr')) != normalize(game.currentPuzzle.titleFor('en'))) break;
      level++;
    }
    game
      ..eliminateCount = 1
      ..hintCount = 1;
    game.useEliminateJoker();
    game.useHintJoker();

    final after = await _relaunch(game);
    after.settings.setLocale('en');
    after.loadPuzzle();
    expect(after.slots.map((s) => s.char).join(), normalize(after.currentPuzzle.titleFor('en')));
    expect(after.pool.any((t) => t.eliminated), isFalse);
    expect(after.hintRevealed, isTrue);
  });
}
