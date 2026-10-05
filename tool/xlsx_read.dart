// Lecture minimale d'un .xlsx (feuilles nommées -> lignes de cellules texte),
// y compris les chaînes partagées qu'Excel écrit quand il réenregistre un
// fichier. Extraction via PowerShell Expand-Archive : package:archive a déjà
// corrompu du texte sur ces fichiers. Outil de dev, jamais utilisé par l'app.

import 'dart:io';

String unescapeXml(String s) {
  var out = s.replaceAllMapped(RegExp(r'&#(\d+);'), (m) => String.fromCharCode(int.parse(m.group(1)!)));
  out = out.replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (m) => String.fromCharCode(int.parse(m.group(1)!, radix: 16)));
  return out.replaceAll('&lt;', '<').replaceAll('&gt;', '>').replaceAll('&quot;', '"').replaceAll('&apos;', "'").replaceAll('&amp;', '&');
}

String _textOf(String xml) =>
    RegExp(r'<t(?:\s[^>]*)?>(.*?)</t>', dotAll: true).allMatches(xml).map((m) => unescapeXml(m.group(1)!)).join();

int colIndex(String letters) {
  var n = 0;
  for (final c in letters.codeUnits) {
    n = n * 26 + (c - 64);
  }
  return n - 1;
}

/// Feuilles du classeur, dans l'ordre des onglets : nom -> lignes (index 0 =
/// ligne 1 d'Excel), chaque ligne étant une liste de textes (index = colonne).
Map<String, List<List<String>>> readXlsx(String xlsxPath, String scratchDir) {
  final dir = Directory(scratchDir);
  if (dir.existsSync()) dir.deleteSync(recursive: true);
  final zipPath = '$scratchDir.zip';
  File(xlsxPath).copySync(zipPath);
  final r = Process.runSync('powershell', ['-Command', "Expand-Archive -Path '$zipPath' -DestinationPath '$scratchDir' -Force"]);
  if (r.exitCode != 0) throw Exception('Expand-Archive failed: ${r.stderr}');

  final shared = <String>[];
  final sstFile = File('$scratchDir/xl/sharedStrings.xml');
  if (sstFile.existsSync()) {
    for (final m in RegExp(r'<si>(.*?)</si>', dotAll: true).allMatches(sstFile.readAsStringSync())) {
      shared.add(_textOf(m.group(1)!));
    }
  }

  final rels = <String, String>{};
  final relsXml = File('$scratchDir/xl/_rels/workbook.xml.rels').readAsStringSync();
  for (final m in RegExp(r'<Relationship\b[^>]*>').allMatches(relsXml)) {
    final tag = m.group(0)!;
    final id = RegExp(r'Id="([^"]+)"').firstMatch(tag)?.group(1);
    final target = RegExp(r'Target="([^"]+)"').firstMatch(tag)?.group(1);
    if (id != null && target != null) rels[id] = target.replaceFirst(RegExp(r'^/?xl/'), '');
  }

  final out = <String, List<List<String>>>{};
  final wbXml = File('$scratchDir/xl/workbook.xml').readAsStringSync();
  for (final m in RegExp(r'<sheet\b[^>]*>').allMatches(wbXml)) {
    final tag = m.group(0)!;
    final name = unescapeXml(RegExp(r'name="([^"]+)"').firstMatch(tag)!.group(1)!);
    final rid = RegExp(r'r:id="([^"]+)"').firstMatch(tag)!.group(1)!;
    final sheetXml = File('$scratchDir/xl/${rels[rid]}').readAsStringSync();
    final rows = <int, List<String>>{};
    for (final rm in RegExp(r'<row\b[^>]*\br="(\d+)"[^>]*>(.*?)</row>', dotAll: true).allMatches(sheetXml)) {
      final cells = <String>[];
      for (final cm in RegExp(r'<c\b([^>]*?)(?:/>|>(.*?)</c>)', dotAll: true).allMatches(rm.group(2)!)) {
        final attrs = cm.group(1)!;
        final ref = RegExp(r'r="([A-Z]+)\d+"').firstMatch(attrs)!.group(1)!;
        final body = cm.group(2) ?? '';
        final type = RegExp(r'\bt="([^"]+)"').firstMatch(attrs)?.group(1);
        String value;
        if (type == 's') {
          final v = RegExp(r'<v>(.*?)</v>').firstMatch(body)?.group(1);
          value = v == null ? '' : shared[int.parse(v)];
        } else if (type == 'inlineStr') {
          value = _textOf(body);
        } else {
          value = unescapeXml(RegExp(r'<v>(.*?)</v>', dotAll: true).firstMatch(body)?.group(1) ?? '');
        }
        final ci = colIndex(ref);
        while (cells.length <= ci) {
          cells.add('');
        }
        cells[ci] = value;
      }
      rows[int.parse(rm.group(1)!)] = cells;
    }
    final maxRow = rows.keys.isEmpty ? 0 : rows.keys.reduce((a, b) => a > b ? a : b);
    out[name] = [for (var i = 1; i <= maxRow; i++) rows[i] ?? <String>[]];
  }
  return out;
}

String cellAt(List<String> row, int col) => col < row.length ? row[col] : '';
