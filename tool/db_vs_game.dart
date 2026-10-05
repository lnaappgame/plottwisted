// Compare un export xlsx de la base à l'état actuel des fichiers Dart du jeu
// (onglet Jeu principal, par monde/niveau) et liste les titres par monde.
// Usage : dart run tool/db_vs_game.dart <export.xlsx>

import 'dart:io';

import '../lib/data/puzzles_data.dart';
import '../lib/models/puzzle.dart';
import 'xlsx_read.dart';

String _fields(Puzzle p) => [
      p.title, p.titleUs, p.year, p.pitchTemplate, p.pitchTemplateUs,
      p.p1.real, p.p1.actor, p.p1.decoy, p.p1.sameRoleActor, p.p1.violet,
      p.p2.real, p.p2.actor, p.p2.decoy, p.p2.sameRoleActor, p.p2.violet,
      p.extraHint, p.revealNote,
    ].join(' ¦ ');

void main(List<String> args) {
  final wb = readXlsx(args[0], '${Directory.systemTemp.path}\\plottwisted_dbgame');
  final sheet = wb['Jeu principal']!;
  final byKey = <String, List<String>>{};
  for (final row in sheet.skip(1)) {
    final monde = cellAt(row, 0), niveau = cellAt(row, 3);
    if (int.tryParse(monde) == null || int.tryParse(niveau) == null) continue;
    byKey['$monde-$niveau'] = row;
  }

  final game = <String, Puzzle>{
    for (var i = 0; i < kTutorialPuzzles.length; i++) '0-${i + 1}': kTutorialPuzzles[i],
    for (final w in kWorlds)
      for (var i = 0; i < w.puzzles.length; i++) '${w.number}-${i + 1}': w.puzzles[i],
  };

  var titleDiffs = 0, otherDiffs = 0;
  for (final e in game.entries) {
    final row = byKey[e.key];
    if (row == null) {
      print('${e.key} absent de l\'export');
      continue;
    }
    if (cellAt(row, 5).trim() != e.value.title.trim()) {
      titleDiffs++;
      print('TITRE ${e.key} : export="${cellAt(row, 5)}" / jeu="${e.value.title}"');
    } else {
      final exp = [5, 6, 7, 8, 9, 11, 13, 15, 17, 19, 22, 24, 26, 28, 30, 32, 34].map((c) => cellAt(row, c).trim()).join(' ¦ ');
      if (exp != _fields(e.value).split(' ¦ ').map((s) => s.trim()).join(' ¦ ')) otherDiffs++;
    }
  }
  print('--- niveaux dont le titre diffère : $titleDiffs ; même titre mais autres champs différents : $otherDiffs');

  print('\n=== Mondes du jeu actuel ===');
  for (final w in kWorlds) {
    print('Monde ${w.number} — ${w.categoryLabel} : ${[for (var i = 0; i < w.puzzles.length; i++) '${i + 1}.${w.puzzles[i].title}'].join(', ')}');
  }
}
