// Écran de jeu du premier lancement (1.0.16, B1) : règle sur une ligne, aucune
// fenêtre, un seul joker visible, lien « J'ai déjà joué » ; un joueur existant
// garde ses fenêtres habituelles.
import 'package:cine_devinette/l10n/app_localizations.dart';
import 'package:cine_devinette/screens/game_screen.dart';
import 'package:cine_devinette/services/ad_service.dart';
import 'package:cine_devinette/services/app_settings.dart';
import 'package:cine_devinette/services/game_state.dart';
import 'package:cine_devinette/services/save_service.dart';
import 'package:cine_devinette/services/sound_service.dart';
import 'package:cine_devinette/services/streak_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<GameState> _pump(WidgetTester tester, {required bool fresh}) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final saveService = SaveService();
  final settings = AppSettings(saveService: saveService)
    ..sfxOn = false
    ..vibrationsOn = false;
  if (fresh) settings.beginOnboarding();
  final game = GameState(adService: AdService(), saveService: saveService, settings: settings);
  // Comme main() au premier lancement : l'énigme 0-1 est chargée avant l'écran.
  game.enterWorld(0);
  game.startOnboardingMeasure();
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
  return game;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  _tw('nouvelle installation : énigme 0-1 tout de suite, règle sur une ligne, aucune fenêtre', (tester) async {
    final game = await _pump(tester, fresh: true);
    expect(find.byType(Dialog), findsNothing, reason: 'ni « Indice de départ » ni fenêtre de règle');
    expect(find.byKey(const ValueKey('onboarding-rule')), findsOneWidget);
    expect(find.textContaining('Le nom en 🟢 vert est le vrai personnage'), findsOneWidget);
    expect(find.text("J'ai déjà joué"), findsOneWidget);
    expect(game.currentLevelNumber, 1);
    expect(game.inOnboardingIntro, isTrue);
  });

  _tw('un seul joker est visible dans l\'énigme 0-1', (tester) async {
    await _pump(tester, fresh: true);
    // Un seul bouton de joker (Révéler) : pas d'Éliminer, d'Acteur, de Personnage, d'Indice.
    expect(find.text('RÉVÉLER'), findsWidgets);
    expect(find.text('ÉLIMINER'), findsNothing);
    expect(find.text('ACTEUR'), findsNothing);
    expect(find.text('INDICE'), findsNothing);
  });

  _tw('énigme 0-2 : sa règle est dans l\'écran, sans fenêtre, tous les jokers reviennent', (tester) async {
    final game = await _pump(tester, fresh: true);
    game.advanceAfterSolve(); // 0-1 -> 0-2
    game.loadPuzzle();
    await tester.pump();
    expect(find.byType(Dialog), findsNothing);
    expect(find.textContaining('Le nom en 🔵 bleu'), findsOneWidget);
    expect(find.text('ÉLIMINER'), findsWidgets);
  });

  _tw('« J\'ai déjà joué » : sortie vers l\'écran du monde 1, tutoriel terminé', (tester) async {
    final game = await _pump(tester, fresh: true);
    await tester.tap(find.text("J'ai déjà joué"));
    await tester.pump();
    expect(game.settings.onboardingActive, isFalse);
    expect(game.worldIndex, 1);
    expect(find.text("J'ai déjà joué"), findsNothing);
    expect(find.byKey(const ValueKey('onboarding-rule')), findsNothing);
  });

  _tw('joueur existant : ni règle écrite, ni lien, tous les jokers', (tester) async {
    await _pump(tester, fresh: false);
    expect(find.byKey(const ValueKey('onboarding-rule')), findsNothing);
    expect(find.text("J'ai déjà joué"), findsNothing);
    expect(find.text('ÉLIMINER'), findsWidgets);
  });
}

/// Comme testWidgets, puis laisse passer les minuteurs de sauvegarde (600 ms) du jeu.
void _tw(String name, Future<void> Function(WidgetTester tester) body) {
  testWidgets(name, (tester) async {
    await body(tester);
    await tester.pump(const Duration(seconds: 2));
  });
}
