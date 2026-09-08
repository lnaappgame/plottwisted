import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:cine_devinette/models/puzzle.dart';
import 'package:cine_devinette/services/ad_service.dart';
import 'package:cine_devinette/services/app_settings.dart';
import 'package:cine_devinette/services/game_state.dart';
import 'package:cine_devinette/services/save_service.dart';
import 'package:cine_devinette/widgets/answer_row.dart';

Future<void> _pumpAnswerRow(WidgetTester tester, String title, {double textScale = 1.0}) async {
  final saveService = SaveService();
  final appSettings = AppSettings(saveService: saveService);
  final gameState = GameState(adService: AdService(), saveService: saveService, settings: appSettings);
  final slots = title.split('').map(AnswerSlot.fromChar).toList();
  gameState.slots = slots;
  gameState.guess = List<int?>.filled(slots.length, null);
  gameState.pool = [];
  gameState.lockedWords = {};
  gameState.cursorIndex = -1;
  final wordRanges = <List<int>>[];
  var current = <int>[];
  for (var i = 0; i < slots.length; i++) {
    if (slots[i].isSpace) {
      if (current.isNotEmpty) wordRanges.add(current);
      current = [];
    } else {
      current.add(i);
    }
  }
  if (current.isNotEmpty) wordRanges.add(current);
  gameState.wordRanges = wordRanges;

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appSettings),
        ChangeNotifierProvider.value(value: gameState),
      ],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const Scaffold(body: Center(child: AnswerRow())),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('AnswerRow : mot unique très long, texte normal', (tester) async {
    await _pumpAnswerRow(tester, 'ANTICONSTITUTIONNELLEMENT');
    expect(tester.takeException(), isNull);
  });

  testWidgets('AnswerRow : mot unique très long, texte agrandi', (tester) async {
    await _pumpAnswerRow(tester, 'ANTICONSTITUTIONNELLEMENT', textScale: 1.3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AnswerRow : titre normal à plusieurs mots reste inchangé', (tester) async {
    await _pumpAnswerRow(tester, 'HOOK OU LA REVANCHE DU CAPITAINE CROCHET');
    expect(tester.takeException(), isNull);
  });
}
