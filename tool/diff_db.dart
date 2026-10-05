// Compare deux exports de la base (ex. export d'origine vs fichier corrigé à
// la main) cellule par cellule et écrit le rapport des différences.
// Usage : dart run tool/diff_db.dart <base.xlsx> <modifie.xlsx> <rapport.txt>

import 'dart:io';

import 'xlsx_read.dart';

void main(List<String> args) {
  final scratch = '${Directory.systemTemp.path}\\plottwisted_diff';
  final base = readXlsx(args[0], '${scratch}_base');
  final mine = readXlsx(args[1], '${scratch}_mine');
  final report = StringBuffer();

  print('Onglets base   : ${base.keys.map((k) => '$k(${base[k]!.length})').join(', ')}');
  print('Onglets modifié: ${mine.keys.map((k) => '$k(${mine[k]!.length})').join(', ')}');

  for (final name in {...base.keys, ...mine.keys}) {
    final b = base[name], m = mine[name];
    if (b == null || m == null) {
      report.writeln('### Onglet "$name" absent de ${b == null ? 'la base' : 'du fichier modifié'}');
      continue;
    }
    final header = b.isNotEmpty ? b[0] : <String>[];
    var diffs = 0;
    final rows = b.length > m.length ? b.length : m.length;
    for (var r = 0; r < rows; r++) {
      final br = r < b.length ? b[r] : <String>[];
      final mr = r < m.length ? m[r] : <String>[];
      final cols = br.length > mr.length ? br.length : mr.length;
      for (var c = 0; c < cols; c++) {
        final bv = cellAt(br, c).trim(), mv = cellAt(mr, c).trim();
        if (bv == mv) continue;
        diffs++;
        final label = c < header.length ? header[c] : 'col$c';
        final key = '${cellAt(mr.isEmpty ? br : mr, 0)} | ${cellAt(mr.isEmpty ? br : mr, 3)}';
        report.writeln('[$name] ligne ${r + 1} ($key) — $label\n   AVANT : $bv\n   APRÈS : $mv');
      }
    }
    print('Onglet "$name" : $diffs cellule(s) différente(s) (base ${b.length} lignes, modifié ${m.length} lignes)');
  }
  File(args[2]).writeAsStringSync(report.toString());
  print('Rapport : ${args[2]}');
}
