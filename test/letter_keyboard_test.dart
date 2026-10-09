import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cine_devinette/models/puzzle.dart';
import 'package:cine_devinette/theme/app_theme.dart';
import 'package:cine_devinette/widgets/letter_keyboard.dart';

List<LetterTile> _pool() => [
      LetterTile(letter: 'A'),
      LetterTile(letter: 'B'),
      LetterTile(letter: 'A'),
      LetterTile(letter: 'C', used: true),
      LetterTile(letter: 'D', eliminated: true),
    ];

Future<List<LetterTile>> _pump(WidgetTester tester, List<LetterTile> pool,
    {String layout = 'azerty', double width = 400}) async {
  final tapped = <LetterTile>[];
  await tester.binding.setSurfaceSize(Size(width, 700));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: LetterKeyboard(pool: pool, layout: layout, colors: AppColors(false), onTap: tapped.add),
      ),
    ),
  ));
  return tapped;
}

void main() {
  testWidgets('lettres proposées en surbrillance, avec le nombre d\'exemplaires', (tester) async {
    final pool = _pool();
    final tapped = await _pump(tester, pool);
    expect(find.text('2'), findsOneWidget); // deux A
    await tester.tap(find.text('A'));
    expect(tapped, [pool[0]]);
    await tester.tap(find.text('B'));
    expect(tapped.last, pool[1]);
  });

  testWidgets('lettres absentes, déjà placées ou éliminées : touches sombres, sans effet', (tester) async {
    final tapped = await _pump(tester, _pool());
    for (final letter in ['Z', 'C', 'D']) {
      await tester.tap(find.text(letter));
    }
    expect(tapped, isEmpty);
  });

  testWidgets('AZERTY et QWERTY : ordre de la première rangée', (tester) async {
    await _pump(tester, _pool());
    expect(tester.getCenter(find.text('A')).dx, lessThan(tester.getCenter(find.text('Z')).dx));
    expect(tester.getCenter(find.text('A')).dy, tester.getCenter(find.text('P')).dy);
    await _pump(tester, _pool(), layout: 'qwerty');
    expect(tester.getCenter(find.text('Q')).dx, lessThan(tester.getCenter(find.text('W')).dx));
    expect(tester.getCenter(find.text('Q')).dy, tester.getCenter(find.text('P')).dy);
  });

  testWidgets('rangée de chiffres seulement si la réponse en contient', (tester) async {
    await _pump(tester, _pool());
    expect(find.text('7'), findsNothing);
    await _pump(tester, [..._pool(), LetterTile(letter: '7')]);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('petit écran (320 px) : pas de débordement', (tester) async {
    await _pump(tester, [..._pool(), LetterTile(letter: '1')], width: 320);
    expect(tester.takeException(), isNull);
  });
}
