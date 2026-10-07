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

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('après la révélation, le niveau suivant démarre en haut de la page', (tester) async {
    // Petit écran : la page de jeu défile.
    tester.view.physicalSize = const Size(360, 560);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final saveService = SaveService();
    final settings = AppSettings(saveService: saveService)
      ..sfxOn = false
      ..vibrationsOn = false;
    final game = GameState(adService: AdService(), saveService: saveService, settings: settings);
    game.enterWorld(1);
    game.currentLevelNumber = 1;
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
          locale: const Locale('fr'),
          home: GameScreen(onBackToMenu: () {}),
        ),
      ),
    );
    await tester.pump();

    final scroll = find.descendant(of: find.byType(SingleChildScrollView), matching: find.byType(Scrollable)).first;
    double offset() => tester.state<ScrollableState>(scroll).position.pixels;

    await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -400));
    await tester.pump();
    expect(offset(), greaterThan(0));

    // Bonne réponse saisie, puis VALIDER (visible : on est en bas de page).
    for (final s in game.slots.where((s) => !s.isSpace && !s.isAuto)) {
      game.onLetterTap(game.pool.firstWhere((t) => t.letter == s.char && !t.used && !t.eliminated));
    }
    await tester.pump();
    await tester.tap(find.text('VALIDER'));
    await tester.pump(const Duration(milliseconds: 1200)); // titre en vert, puis révélation
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('SUIVANT'), findsOneWidget);

    await tester.ensureVisible(find.text('SUIVANT'));
    await tester.pump();
    await tester.tap(find.text('SUIVANT'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(game.currentLevelNumber, 2);
    expect(offset(), 0);
    await tester.pump(const Duration(seconds: 2));
  });
}
