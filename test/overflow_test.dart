import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:cine_devinette/l10n/app_localizations.dart';
import 'package:cine_devinette/models/puzzle.dart';
import 'package:cine_devinette/services/ad_service.dart';
import 'package:cine_devinette/services/app_settings.dart';
import 'package:cine_devinette/services/game_state.dart';
import 'package:cine_devinette/services/save_service.dart';
import 'package:cine_devinette/theme/app_theme.dart';
import 'package:cine_devinette/widgets/result_overlay.dart';

Puzzle _puzzleWithTitle(String title) => Puzzle(
      title: title,
      year: '2024',
      pitchTemplate: '{p1} rencontre {p2} dans une aventure extraordinaire.',
      p1InitialColor: NameColor.green,
      p2InitialColor: NameColor.blue,
      p1: const PersonRef(real: 'Jean Dupont', actor: 'Jean Acteur'),
      p2: const PersonRef(real: 'Marie Martin', actor: 'Marie Actrice'),
      extraHint: 'Un indice assez long pour occuper plusieurs lignes de texte.',
      revealNote: 'Une anecdote assez longue pour occuper plusieurs lignes de texte également.',
    );

Future<void> _pumpResultOverlay(WidgetTester tester, String title) async {
  final saveService = SaveService();
  final adService = AdService();
  final appSettings = AppSettings(saveService: saveService);
  final gameState = GameState(adService: adService, saveService: saveService, settings: appSettings);
  gameState.currentPuzzle = _puzzleWithTitle(title);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appSettings),
        ChangeNotifierProvider.value(value: gameState),
      ],
      child: MaterialApp(
        theme: buildAppTheme(isLight: false),
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: Scaffold(body: ResultOverlay(onNext: () {})),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets('ResultOverlay : titre long à un seul mot, texte agrandi', (tester) async {
    await _pumpResultOverlay(tester, 'ANTICONSTITUTIONNELLEMENT');
    expect(tester.takeException(), isNull);
  });

  testWidgets('ResultOverlay : titre long à plusieurs mots, texte agrandi', (tester) async {
    await _pumpResultOverlay(tester, 'HOOK OU LA REVANCHE DU CAPITAINE CROCHET');
    expect(tester.takeException(), isNull);
  });

  testWidgets('ResultOverlay : titre extrêmement long, texte agrandi', (tester) async {
    await _pumpResultOverlay(
        tester, 'QU\'EST-CE QU\'ON A FAIT AU BON DIEU POUR MÉRITER UN TITRE AUSSI INTERMINABLE ?');
    expect(tester.takeException(), isNull);
  });
}
