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
