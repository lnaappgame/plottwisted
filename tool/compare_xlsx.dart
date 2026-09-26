// Script de comparaison ponctuel : compare cine_devinette_CORRIGE_v2.xlsx
// (corrections du 2026-09-14, "derniere MAJ pour la v1") au contenu Dart
// actuel, et affiche les différences champ par champ. Jamais utilisé par
// l'app elle-même — lecture seule, n'écrit rien.
//
// Usage : dart run tool/compare_xlsx.dart

import 'dart:io';

import '../lib/data/defis_data.dart';
import '../lib/data/enigmes_data.dart';
import '../lib/data/multiplayer_data.dart';
import '../lib/data/puzzles_data.dart';
import '../lib/models/puzzle.dart';
import '../lib/services/elo_service.dart';

const _xlsxPath = r'C:\Users\Neophilis\Downloads\cine_devinette_CORRIGE_v2.xlsx';
// package:archive's ZipDecoder corrupted scattered characters when decoding
// this specific file (confirmed 2026-09-15 : comparing its output against a
// PowerShell Expand-Archive extraction of the same bytes showed invented
// typos like "artistre"/"millardaire" that don't exist anywhere in the real
// file). Shell out to Windows' own unzip instead — verified correct.
const _extractDir = r'C:\Users\NEOPHI~1\AppData\Local\Temp\claude\C--Users-Neophilis-Documents-cine-devinette\ff928cde-e881-4c2d-9efa-ad7518acd640\scratchpad\xlsx_extract_verified';

void _extractXlsx() {
  final dir = Directory(_extractDir);
  if (dir.existsSync()) dir.deleteSync(recursive: true);
  final zipPath = '$_extractDir.zip';
  File(_xlsxPath).copySync(zipPath);
  final result = Process.runSync('powershell', [
    '-Command',
    "Expand-Archive -Path '$zipPath' -DestinationPath '$_extractDir' -Force",
  ]);
  if (result.exitCode != 0) {
    throw Exception('Expand-Archive failed: ${result.stderr}');
  }
}

String _unescapeXml(String s) {
  var out = s.replaceAllMapped(RegExp(r'&#(\d+);'), (m) => String.fromCharCode(int.parse(m.group(1)!)));
  out = out.replaceAll('&amp;', '&').replaceAll('&apos;', "'").replaceAll('&quot;', '"').replaceAll('&lt;', '<').replaceAll('&gt;', '>');
  return out;
}

Map<String, String> _parseRowCells(String rowXml) {
  final out = <String, String>{};
  final cellMatches = RegExp(r'<c r="([A-Z]+)\d+"([^>]*)>(.*?)</c>', dotAll: true).allMatches(rowXml);
  for (final cm in cellMatches) {
    final col = cm.group(1)!;
    final cellXml = cm.group(3)!;
    final isMatch = RegExp(r'<is><t[^>]*>(.*?)</t></is>', dotAll: true).firstMatch(cellXml);
    if (isMatch != null) {
      out[col] = _unescapeXml(isMatch.group(1)!);
      continue;
    }
    final vMatch = RegExp(r'<v>(.*?)</v>', dotAll: true).firstMatch(cellXml);
    if (vMatch != null) out[col] = _unescapeXml(vMatch.group(1)!);
  }
  return out;
}

List<Map<String, String>> _readSheetOrdered(int sheetIndex) {
  final xml = File('$_extractDir/xl/worksheets/sheet$sheetIndex.xml').readAsStringSync();
  final rowMatches = RegExp(r'<row r="(\d+)"[^>]*>(.*?)</row>', dotAll: true).allMatches(xml);
  final rows = <int, Map<String, String>>{};
  for (final m in rowMatches) {
    rows[int.parse(m.group(1)!)] = _parseRowCells(m.group(2)!);
  }
  final maxRow = rows.keys.isEmpty ? 0 : rows.keys.reduce((a, b) => a > b ? a : b);
  final out = <Map<String, String>>[];
  for (var r = 1; r <= maxRow; r++) {
    out.add(rows[r] ?? {});
  }
  return out;
}

String _norm(String s) {
  final t = s.trim();
  return t == '0' ? '' : t;
}

int _diffCount = 0;

// Attention a l'ordre des arguments partout ou _cmp est appele : c'est
// toujours (loc, field, valeur xlsx, valeur Dart actuelle).
void _cmp(String location, String field, String xlsxVal, String dartVal) {
  final a = _norm(xlsxVal);
  final b = _norm(dartVal);
  if (a != b) {
    _diffCount++;
    print('[$location] $field:');
    print('  DART ACTUEL (en jeu): $b');
    print('  XLSX (correction a appliquer): $a');
  }
}

void main() {
  _extractXlsx();

  final sheet1 = _readSheetOrdered(1); // Jeu principal
  final sheet2 = _readSheetOrdered(2); // Enigme
  final sheet3 = _readSheetOrdered(3); // Defi
  final sheet4 = _readSheetOrdered(4); // Multijoueur
  final sheet5 = _readSheetOrdered(5); // Titres

  // ─── Jeu principal : trouver la ligne d'en-tete (colonne A == 'Monde'),
  // les donnees commencent juste apres, dans l'ordre tutoriel puis mondes 1..N.
  final headerIdx1 = sheet1.indexWhere((r) => r['A']?.trim() == 'Monde');
  print('=== Jeu principal (en-tete ligne ${headerIdx1 + 1}) ===');
  var idx = headerIdx1 + 1;
  final dataRows1 = <Map<String, String>>[];
  final rowNums1 = <int>[];
  for (; idx < sheet1.length; idx++) {
    final row = sheet1[idx];
    if (row.values.every((v) => v.trim().isEmpty)) continue;
    if ((row['A'] ?? '').contains('LIMITE DU JEU')) break; // marqueur : fin du perimetre V1
    dataRows1.add(row);
    rowNums1.add(idx + 1); // 1-based excel row number
  }
  print('Lignes V1 trouvees dans le xlsx : ${dataRows1.length}');

  String colorLabel(NameColor c) => switch (c) {
        NameColor.green => 'Vert', NameColor.blue => 'Bleu', NameColor.red => 'Rouge',
        NameColor.orange => 'Orange', NameColor.violet => 'Violet',
      };

  void comparePuzzle(String loc, Map<String, String> row, Puzzle p, {required bool p2Expected}) {
    _cmp(loc, 'Titre', row['F'] ?? '', p.title);
    _cmp(loc, 'Titre US', row['G'] ?? '', p.titleUs);
    _cmp(loc, 'Annee', row['H'] ?? '', p.year);
    _cmp(loc, 'Pitch', row['I'] ?? '', p.pitchTemplate);
    _cmp(loc, 'Pitch US', row['J'] ?? '', p.pitchTemplateUs);
    _cmp(loc, 'P1 couleur', row['K'] ?? '', colorLabel(p.p1InitialColor));
    _cmp(loc, 'P1 Vert', row['L'] ?? '', p.p1.real);
    _cmp(loc, 'P1 Vert US', row['M'] ?? '', p.p1.realUs);
    _cmp(loc, 'P1 Bleu', row['N'] ?? '', p.p1.actor);
    _cmp(loc, 'P1 Bleu US', row['O'] ?? '', p.p1.actorUs);
    _cmp(loc, 'P1 Rouge', row['P'] ?? '', p.p1.decoy);
    _cmp(loc, 'P1 Rouge US', row['Q'] ?? '', p.p1.decoyUs);
    _cmp(loc, 'P1 Orange', row['R'] ?? '', p.p1.sameRoleActor);
    _cmp(loc, 'P1 Orange US', row['S'] ?? '', p.p1.sameRoleActorUs);
    _cmp(loc, 'P1 Violet', row['T'] ?? '', p.p1.violet);
    _cmp(loc, 'P1 Violet US', row['U'] ?? '', p.p1.violetUs);
    _cmp(loc, 'P2 couleur', row['V'] ?? '', p2Expected ? colorLabel(p.p2InitialColor) : '');
    _cmp(loc, 'P2 Vert', row['W'] ?? '', p.p2.real);
    _cmp(loc, 'P2 Vert US', row['X'] ?? '', p.p2.realUs);
    _cmp(loc, 'P2 Bleu', row['Y'] ?? '', p.p2.actor);
    _cmp(loc, 'P2 Bleu US', row['Z'] ?? '', p.p2.actorUs);
    _cmp(loc, 'P2 Rouge', row['AA'] ?? '', p.p2.decoy);
    _cmp(loc, 'P2 Rouge US', row['AB'] ?? '', p.p2.decoyUs);
    _cmp(loc, 'P2 Orange', row['AC'] ?? '', p.p2.sameRoleActor);
    _cmp(loc, 'P2 Orange US', row['AD'] ?? '', p.p2.sameRoleActorUs);
    _cmp(loc, 'P2 Violet', row['AE'] ?? '', p.p2.violet);
    _cmp(loc, 'P2 Violet US', row['AF'] ?? '', p.p2.violetUs);
    _cmp(loc, 'Indice', row['AG'] ?? '', p.extraHint);
    _cmp(loc, 'Indice US', row['AH'] ?? '', p.extraHintUs);
    _cmp(loc, 'Revelation', row['AI'] ?? '', p.revealNote);
    _cmp(loc, 'Revelation US', row['AJ'] ?? '', p.revealNoteUs);
    _cmp(loc, 'Allocine', row['AK'] ?? '', p.allocineUrl);
    _cmp(loc, 'IMDb', row['AL'] ?? '', p.imdbUrl);
  }

  var ri = 0;
  for (var i = 0; i < kTutorialPuzzles.length; i++, ri++) {
    comparePuzzle('Tutoriel #${i + 1} (ligne ${rowNums1[ri]})', dataRows1[ri], kTutorialPuzzles[i], p2Expected: kTutorialPuzzles[i].hasP2);
  }
  for (final world in kWorlds) {
    _cmp('Monde ${world.number} (categorie, ligne ${rowNums1[ri]})', 'Categorie', dataRows1[ri]['B'] ?? '', world.categoryLabel);
    _cmp('Monde ${world.number} (categorie, ligne ${rowNums1[ri]})', 'Categorie US', dataRows1[ri]['C'] ?? '', world.categoryLabelUs);
    for (var i = 0; i < world.puzzles.length; i++, ri++) {
      comparePuzzle('Monde ${world.number} #${i + 1} (ligne ${rowNums1[ri]})', dataRows1[ri], world.puzzles[i], p2Expected: world.puzzles[i].hasP2);
    }
  }
  print('Lignes Dart comparees : $ri (xlsx en avait ${dataRows1.length})');

  // ─── Enigme de la semaine ───
  print('\n=== Enigme de la semaine ===');
  final headerIdx2 = sheet2.indexWhere((r) => r['A']?.trim().contains('Ordre') == true);
  var idx2 = headerIdx2 + 1;
  final dataRows2 = <Map<String, String>>[];
  for (; idx2 < sheet2.length; idx2++) {
    final row = sheet2[idx2];
    if (row.values.every((v) => v.trim().isEmpty)) continue;
    if ((row['A'] ?? '').contains('LIMITE DU JEU')) break;
    dataRows2.add(row);
  }
  print('Lignes V1 trouvees : ${dataRows2.length}, kEnigmes: ${kEnigmes.length}');
  for (var i = 0; i < kEnigmes.length && i < dataRows2.length; i++) {
    final e = kEnigmes[i];
    final loc = 'Enigme #${i + 1}';
    final row = dataRows2[i];
    _cmp(loc, 'Sujet', row['D'] ?? '', e.sujet);
    _cmp(loc, 'Sujet US', row['E'] ?? '', e.sujetUs);
    _cmp(loc, 'Texte', row['F'] ?? '', e.texte);
    _cmp(loc, 'Texte US', row['G'] ?? '', e.texteUs);
    final annee = e.anneeSortie ?? (e.dateNaissance != null ? '${e.dateNaissance!.year}-${e.dateNaissance!.month.toString().padLeft(2, '0')}-${e.dateNaissance!.day.toString().padLeft(2, '0')}' : '');
    _cmp(loc, 'Annee/Naissance', row['I'] ?? '', annee);
  }

  // ─── Defi du jour ───
  print('\n=== Defi du jour ===');
  final headerIdx3 = sheet3.indexWhere((r) => r['A']?.trim() == 'Type');
  var idx3 = headerIdx3 + 1;
  final dataRows3 = <Map<String, String>>[];
  for (; idx3 < sheet3.length; idx3++) {
    final row = sheet3[idx3];
    if (row.values.every((v) => v.trim().isEmpty)) continue;
    if ((row['A'] ?? '').contains('LIMITE DU JEU')) break;
    dataRows3.add(row);
  }
  var totalCases = 0;
  for (final d in kDefis) {
    totalCases += d.cases.length;
  }
  print('Lignes V1 trouvees : ${dataRows3.length}, kDefis cases totales: $totalCases');
  var ri3 = 0;
  for (final defi in kDefis) {
    _cmp('Defi ${defi.id} (commun)', 'Commun', dataRows3[ri3]['B'] ?? '', defi.commun);
    _cmp('Defi ${defi.id} (commun)', 'Commun US', dataRows3[ri3]['C'] ?? '', defi.communUs);
    _cmp('Defi ${defi.id} (commun)', 'Consigne', dataRows3[ri3]['D'] ?? '', defi.consigne);
    _cmp('Defi ${defi.id} (commun)', 'Consigne US', dataRows3[ri3]['E'] ?? '', defi.consigneUs);
    for (var i = 0; i < defi.cases.length; i++, ri3++) {
      final c = defi.cases[i];
      final loc = 'Defi ${defi.id} case ${i + 1}';
      final row = dataRows3[ri3];
      _cmp(loc, 'Reponse', row['G'] ?? '', c.reponse);
      _cmp(loc, 'Reponse US', row['H'] ?? '', c.reponseUs);
      _cmp(loc, 'Indice', row['I'] ?? '', c.indice);
      _cmp(loc, 'Indice US', row['J'] ?? '', c.indiceUs);
    }
  }

  // ─── Multijoueur ───
  print('\n=== Multijoueur ===');
  final headerIdx4 = sheet4.indexWhere((r) => r['A']?.trim() == 'id');
  var idx4 = headerIdx4 + 1;
  final dataRows4 = <Map<String, String>>[];
  for (; idx4 < sheet4.length; idx4++) {
    final row = sheet4[idx4];
    if (row.values.every((v) => v.trim().isEmpty)) continue;
    dataRows4.add(row);
  }
  print('Lignes trouvees : ${dataRows4.length}, kMultiplayerEnigmes: ${kMultiplayerEnigmes.length}');
  for (var i = 0; i < kMultiplayerEnigmes.length && i < dataRows4.length; i++) {
    final e = kMultiplayerEnigmes[i];
    final loc = 'Multi ${e.id}';
    final row = dataRows4[i];
    _cmp(loc, 'pitch', row['C'] ?? '', e.pitch);
    _cmp(loc, 'pitch US', row['D'] ?? '', e.pitchUs);
    _cmp(loc, 'reponse', row['E'] ?? '', e.reponse);
    _cmp(loc, 'reponse US', row['F'] ?? '', e.reponseUs);
  }

  // ─── Titres honorifiques ───
  print('\n=== Titres honorifiques ===');
  final headerIdx5 = sheet5.indexWhere((r) => r['A']?.trim().contains('Seuil') == true);
  var idx5 = headerIdx5 + 1;
  final dataRows5 = <Map<String, String>>[];
  for (; idx5 < sheet5.length; idx5++) {
    final row = sheet5[idx5];
    if (row.values.every((v) => v.trim().isEmpty)) continue;
    dataRows5.add(row);
  }
  print('Lignes trouvees : ${dataRows5.length}, kTitresHonorifiques: ${kTitresHonorifiques.length}');
  for (var i = 0; i < kTitresHonorifiques.length && i < dataRows5.length; i++) {
    final (seuil, fr, us) = kTitresHonorifiques[i];
    final loc = 'Titre seuil $seuil';
    final row = dataRows5[i];
    _cmp(loc, 'Seuil', row['A'] ?? '', '$seuil');
    _cmp(loc, 'Titre FR', row['B'] ?? '', fr);
    _cmp(loc, 'Titre US', row['C'] ?? '', us);
  }

  print('\n=== TOTAL DIFFERENCES: $_diffCount ===');
}
