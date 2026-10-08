import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cine_devinette/data/enigmes_data.dart';
import 'package:cine_devinette/data/puzzles_data.dart';
import 'package:cine_devinette/services/ad_service.dart';
import 'package:cine_devinette/services/app_settings.dart';
import 'package:cine_devinette/services/enigme_state.dart';
import 'package:cine_devinette/services/game_state.dart';
import 'package:cine_devinette/services/save_service.dart';

GameState _newGame() {
  final saveService = SaveService();
  final settings = AppSettings(saveService: saveService)
    ..sfxOn = false
    ..vibrationsOn = false;
  return GameState(adService: AdService(), saveService: saveService, settings: settings);
}

/// Ouvre le premier niveau dont la réponse est (ou n'est pas) identique en
/// français et en anglais.
void _openLevel(GameState game, {required bool sameAnswer}) {
  for (final world in kWorlds) {
    for (final puzzle in world.puzzles) {
      final same = normalize(puzzle.titleFor('fr')) == normalize(puzzle.titleFor('en'));
      if (same != sameAnswer) continue;
      game.enterWorld(world.number);
      game.currentLevelNumber = world.puzzles.indexOf(puzzle) + 1;
      game.loadPuzzle();
      return;
    }
  }
  fail('aucun niveau trouvé (sameAnswer: $sameAnswer)');
}

String _answer(List slots) => slots.map((s) => s.char).join();

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('passer le jeu en anglais en cours de niveau : le niveau passe en anglais', () {
    final game = _newGame();
    _openLevel(game, sameAnswer: false);
    expect(game.locale, 'fr');
    final p1 = game.p1Colors.length;

    game.settings.setLocale('en');

    expect(game.locale, 'en');
    expect(_answer(game.slots), normalize(game.currentPuzzle.titleFor('en')));
    expect(game.p1Colors.length, p1);
  });

  test('réponse identique dans les deux langues : la grille commencée est conservée', () {
    final game = _newGame();
    _openLevel(game, sameAnswer: true);
    final slot = game.slots.indexWhere((s) => !s.isSpace && !s.isAuto);
    game.onLetterTap(game.pool.firstWhere((t) => t.letter == game.slots[slot].char));
    final guess = List.of(game.guess);

    game.settings.setLocale('en');

    expect(game.locale, 'en');
    expect(game.guess, guess);
  });

  test('indice déjà révélé : il reste acquis et passe dans la nouvelle langue', () {
    final game = _newGame();
    _openLevel(game, sameAnswer: false);
    game.hintCount = 1;
    game.useHintJoker();

    game.settings.setLocale('en');

    expect(game.hintRevealed, isTrue);
    expect(game.hintCount, 0);
    final hint = game.currentPuzzle.extraHintFor('en');
    expect(game.revealedHintText, hint.isNotEmpty ? hint : 'No extra hint available for this puzzle.');
  });

  test('énigme de la semaine : elle suit aussi la langue du jeu', () {
    final saveService = SaveService();
    final settings = AppSettings(saveService: saveService);
    final state = EnigmeState(saveService: saveService, settings: settings);
    state.currentIndex = kEnigmes.indexWhere((e) => normalize(e.sujetFor('fr')) != normalize(e.sujetFor('en')));
    state.currentWeekStart = DateTime.now();
    state.rebuildTiles();
    expect(state.locale, 'fr');

    settings.setLocale('en');

    expect(state.locale, 'en');
    expect(_answer(state.slots), normalize(state.enigme.sujetFor('en')));
  });
}
