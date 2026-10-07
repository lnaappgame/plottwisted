import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cine_devinette/l10n/app_localizations.dart';
import 'package:cine_devinette/models/puzzle.dart';
import 'package:cine_devinette/services/ad_service.dart';
import 'package:cine_devinette/services/app_settings.dart';
import 'package:cine_devinette/services/game_state.dart';
import 'package:cine_devinette/services/save_service.dart';
import 'package:cine_devinette/widgets/answer_row.dart';
import 'package:cine_devinette/widgets/pitch_card.dart';

Future<GameState> _pump(WidgetTester tester, Widget child) async {
  final saveService = SaveService();
  final settings = AppSettings(saveService: saveService);
  final game = GameState(adService: AdService(), saveService: saveService, settings: settings);
  game.enterWorld(1);
  game.currentLevelNumber = 10; // STAR WARS : p1 rouge
  game.loadPuzzle();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: game),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
  return game;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('le pitch affiche les deux dernières couleurs d\'un nom', (tester) async {
    final game = await _pump(tester, const PitchCard());
    final p1 = game.currentPuzzle.p1;
    expect(find.text(p1.decoy), findsOneWidget);
    expect(find.text(p1.actor), findsNothing);

    game.actorCount = 1;
    game.selectNameJoker(NameColor.blue);
    game.onNameTap('p1');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text(p1.actor), findsOneWidget);
    expect(find.text(p1.decoy), findsOneWidget);

    game.characterCount = 1;
    game.selectNameJoker(NameColor.green);
    game.onNameTap('p1');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text(p1.real), findsOneWidget);
    expect(find.text(p1.actor), findsOneWidget);
    expect(find.text(p1.decoy), findsNothing); // couleur d'origine chassée
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 1)); // laisse partir la sauvegarde différée
  });

  testWidgets('la pulsation du cadre ne déplace jamais le texte du pitch', (tester) async {
    await _pump(tester, const PitchCard());
    // Les flammes du niveau "Extrême" bougent volontairement : on ne mesure que le texte.
    List<Rect> textRects() => tester
        .widgetList<RichText>(find.descendant(of: find.byType(PitchCard), matching: find.byType(RichText)))
        .where((w) => w.text.toPlainText() != '🔥')
        .map((w) => tester.getRect(find.byWidget(w)))
        .toList();
    final atRest = textRects();
    // Pulsation : montée sur 420 ms, puis descente ; on échantillonne tout le long.
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      expect(textRects(), atRest);
    }
    await tester.pump(const Duration(seconds: 1)); // laisse partir la sauvegarde différée
  });

  testWidgets('la surbrillance verte affiche tout le titre, même sans lettre placée', (tester) async {
    final game = await _pump(tester, const AnswerRow(highlightSolved: true));
    for (final slot in game.slots.where((s) => !s.isSpace)) {
      expect(find.text(slot.char), findsWidgets);
    }
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 1)); // laisse partir la sauvegarde différée
  });
}
