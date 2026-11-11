import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cine_devinette/data/puzzles_data.dart';
import 'package:cine_devinette/l10n/app_localizations.dart';
import 'package:cine_devinette/models/puzzle.dart';
import 'package:cine_devinette/screens/game_screen.dart';
import 'package:cine_devinette/services/ad_service.dart';
import 'package:cine_devinette/services/app_settings.dart';
import 'package:cine_devinette/services/game_state.dart';
import 'package:cine_devinette/services/save_service.dart';
import 'package:cine_devinette/services/sound_service.dart';
import 'package:cine_devinette/services/streak_state.dart';

// Écran de jeu complet sur le plus petit téléphone visé (320 x 568), pour le
// monde à réponse bonus : c'est là que se trouvent les plus longues grilles
// du jeu (« ENTRETIEN AVEC UN VAMPIRE » + « KIRSTEN DUNST », 34 lettres).

GameWorld get _extraWorld => kWorlds.firstWhere((w) => w.puzzles.any((p) => p.extraAnswer.isNotEmpty));

Future<GameState> _pumpGame(WidgetTester tester, int level, String locale) async {
  tester.view.physicalSize = const Size(320, 568);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final saveService = SaveService();
  final settings = AppSettings(saveService: saveService)
    ..sfxOn = false
    ..vibrationsOn = false;
  if (locale == 'en') settings.setLocale('en');
  final game = GameState(adService: AdService(), saveService: saveService, settings: settings);
  game.enterWorld(_extraWorld.number);
  game.currentLevelNumber = level;
  game.loadPuzzle();

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: game),
        ChangeNotifierProvider(create: (_) => StreakState(saveService: saveService)),
        Provider(create: (_) => SoundService()),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale(locale),
        home: GameScreen(onBackToMenu: () {}),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  return game;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('les 10 niveaux s\'affichent sans débordement, en français et en anglais', (tester) async {
    for (final locale in ['fr', 'en']) {
      for (var level = 1; level <= _extraWorld.puzzles.length; level++) {
        final game = await _pumpGame(tester, level, locale);
        expect(tester.takeException(), isNull, reason: '${game.currentPuzzle.answerFor(locale)} ($locale)');
        expect(find.byKey(const ValueKey('extra-answer-caption')), findsOneWidget);
        // Remplace l'écran avant le niveau suivant, pour repartir d'un état neuf.
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
      }
    }
  });

  testWidgets('la plus longue grille se joue jusqu\'au bout : film + nom, puis révélation', (tester) async {
    final world = _extraWorld;
    var longest = 0;
    for (var i = 1; i < world.puzzles.length; i++) {
      if (world.puzzles[i].answerFor('fr').length > world.puzzles[longest].answerFor('fr').length) longest = i;
    }
    final game = await _pumpGame(tester, longest + 1, 'fr');
    final puzzle = game.currentPuzzle;

    for (final s in game.slots.where((s) => !s.isSpace && !s.isAuto)) {
      game.onLetterTap(game.pool.firstWhere((t) => t.letter == s.char && !t.used && !t.eliminated));
    }
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('VALIDER'));
    await tester.pump();
    await tester.tap(find.text('VALIDER'));
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);

    expect(find.text('SUIVANT'), findsOneWidget);
    expect(find.text(puzzle.title), findsWidgets);
    expect(find.text('+ ${puzzle.extraAnswer}'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });
}
