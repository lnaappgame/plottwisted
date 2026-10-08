import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:cine_devinette/l10n/app_localizations.dart';
import 'package:cine_devinette/screens/instructions_screen.dart';
import 'package:cine_devinette/services/ad_service.dart';
import 'package:cine_devinette/services/app_settings.dart';
import 'package:cine_devinette/services/game_state.dart';
import 'package:cine_devinette/services/save_service.dart';
import 'package:cine_devinette/theme/app_theme.dart';

Future<void> _pump(WidgetTester tester, String locale) async {
  await tester.binding.setSurfaceSize(const Size(360, 640));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final saveService = SaveService();
  final settings = AppSettings(saveService: saveService)..locale = locale;
  final game = GameState(adService: AdService(), saveService: saveService, settings: settings);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: game),
      ],
      child: MaterialApp(
        theme: buildAppTheme(isLight: false),
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: const Scaffold(body: InstructionsScreen()),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('Comment jouer : onglet Jokers puis onglet Modes de jeu', (tester) async {
    await _pump(tester, 'fr');
    expect(find.text('COMMENT JOUER'), findsOneWidget);
    expect(find.text('OBTENIR DES JOKERS'), findsOneWidget);
    expect(find.text('🎯 Défi du jour'), findsNothing);

    await tester.tap(find.text('Modes de jeu'));
    await tester.pump();
    expect(find.text('OBTENIR DES JOKERS'), findsNothing);
    expect(find.text('🎬 Jeu principal'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('⚔️ Multijoueur'), 200, scrollable: find.byType(Scrollable).last);
    expect(find.text('⚔️ Multijoueur'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('How to play : version anglaise, texte agrandi, sans débordement', (tester) async {
    await _pump(tester, 'en');
    expect(find.text('HOW TO PLAY'), findsOneWidget);
    await tester.tap(find.text('Game modes'));
    await tester.pump();
    expect(find.text('🧩 Weekly Puzzle'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
