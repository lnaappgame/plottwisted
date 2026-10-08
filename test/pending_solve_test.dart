import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cine_devinette/l10n/app_localizations.dart';
import 'package:cine_devinette/screens/game_screen.dart';
import 'package:cine_devinette/services/ad_service.dart';
import 'package:cine_devinette/services/app_settings.dart';
import 'package:cine_devinette/services/game_state.dart';
import 'package:cine_devinette/services/save_service.dart';
import 'package:cine_devinette/services/sound_service.dart';
import 'package:cine_devinette/services/streak_state.dart';
import 'package:cine_devinette/widgets/world_intro_overlay.dart';

GameState _newGame(SaveService saveService) {
  final settings = AppSettings(saveService: saveService)
    ..sfxOn = false
    ..vibrationsOn = false;
  return GameState(adService: AdService(), saveService: saveService, settings: settings);
}

void _typeAnswer(GameState game) {
  for (final s in game.slots.where((s) => !s.isSpace && !s.isAuto)) {
    game.onLetterTap(game.pool.firstWhere((t) => t.letter == s.char && !t.used && !t.eliminated));
  }
}

Future<void> _pumpGame(WidgetTester tester, GameState game) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: game.settings),
        ChangeNotifierProvider.value(value: game),
        ChangeNotifierProvider(create: (_) => StreakState(saveService: game.saveService)),
        Provider(create: (_) => SoundService()),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: GameScreen(onBackToMenu: () {}),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('bonne réponse : le niveau est sauvegardé comme trouvé, retrouvé au relancement', () async {
    final saveService = SaveService();
    final game = _newGame(saveService);
    game.enterWorld(1);
    game.loadPuzzle();
    _typeAnswer(game);
    expect(game.validate(), 'solved');
    expect(game.hasPendingSolve, isTrue);
    await game.flushSave();

    // « Fermeture » de l'app avant SUIVANT, puis relancement.
    final relaunched = _newGame(saveService);
    await relaunched.restore();
    expect(relaunched.hasPendingSolve, isTrue);
    expect(relaunched.puzzleLoaded, isTrue); // rechargé pour rouvrir la révélation
    expect(relaunched.currentLevelNumber, 1);

    relaunched.advanceAfterSolve();
    expect(relaunched.hasPendingSolve, isFalse);
    expect(relaunched.currentLevelNumber, 2);
  });

  test('sans bonne réponse, rien n\'est marqué trouvé', () async {
    final game = _newGame(SaveService());
    game.enterWorld(1);
    game.loadPuzzle();
    expect(game.hasPendingSolve, isFalse);
    expect(game.toJson()['solvedPending'], isNull);
  });

  testWidgets('retour dans le jeu après une bonne réponse : la révélation se rouvre, SUIVANT enchaîne', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final saveService = SaveService();
    final game = _newGame(saveService);
    game.enterWorld(1);
    game.loadPuzzle();
    _typeAnswer(game);
    game.validate();
    await game.flushSave();
    final relaunched = _newGame(saveService);
    await relaunched.restore();

    await _pumpGame(tester, relaunched);
    expect(find.text('SUIVANT'), findsOneWidget);
    await tester.ensureVisible(find.text('SUIVANT'));
    await tester.pump();
    await tester.tap(find.text('SUIVANT'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(relaunched.currentLevelNumber, 2);
    expect(relaunched.hasPendingSolve, isFalse);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('fin du contenu avec un seul monde en réserve : on y entre au lieu de reboucler sur le dernier niveau',
      (tester) async {
    // Cas d'une testeuse (bundle 8) : monde 20 = dernier monde, le 20-6 gardé
    // pour la fin, et un monde laissé en réserve plus tôt. Le choix n'avait
    // alors qu'une option, et la valider rechargeait le 20-6 : boucle infinie.
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final saveService = SaveService();
    final seed = _newGame(saveService);
    seed.enterWorld(20);
    final save = seed.toJson()
      ..['remainingLevels'] = [6]
      ..['currentLevelNumber'] = 6
      ..['worldChoiceReserve'] = 17
      ..['worldChoiceFrontier'] = 21; // au-delà du dernier monde
    await saveService.save(save);
    final game = _newGame(saveService);
    await game.restore();
    expect(game.worldChoiceOptions, [17]);

    await _pumpGame(tester, game);
    await tester.tap(find.text('COMMENCER')); // intro du monde 20 en cours
    for (var t = 0; t < 1500; t += 50) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(game.currentLevelNumber, 6);
    _typeAnswer(game);
    await tester.pump();
    await tester.ensureVisible(find.text('VALIDER'));
    await tester.tap(find.text('VALIDER'));
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.ensureVisible(find.text('SUIVANT'));
    await tester.pump();
    await tester.tap(find.text('SUIVANT'));
    await tester.pump(const Duration(seconds: 3)); // bannière de fin de monde
    // Une seule option : le monde en réserve.
    final intro = tester.widget<WorldIntroOverlay>(find.byType(WorldIntroOverlay));
    expect(intro.worlds.map((w) => w.number), [17]);
    await tester.tap(find.text('COMMENCER'));
    for (var t = 0; t < 1500; t += 50) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(game.worldIndex, 17); // on est bien entré dans le monde 17
    expect(game.currentLevelNumber, isNot(6) );
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('quitté sur la fin de monde : le choix du monde suivant revient', (tester) async {
    final game = _newGame(SaveService());
    game.enterWorld(1);
    game.remainingLevels = []; // monde 1 terminé, choix pas encore fait
    await _pumpGame(tester, game);
    final intro = tester.widget<WorldIntroOverlay>(find.byType(WorldIntroOverlay));
    expect(intro.worlds.map((w) => w.number), [2, 3]);
    await tester.pump(const Duration(seconds: 1));
  });
}
