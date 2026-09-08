// Export ponctuel : régénère un xlsx à 5 onglets (même structure que le
// fichier source cine_devinette_structure_us.xlsx) reflétant l'état actuel
// du jeu — V1 (déjà en jeu) directement depuis les fichiers Dart (donc avec
// toutes les corrections faites depuis l'import initial), "en attente"
// (jamais traduit, pas dans le jeu) recopié tel quel depuis le xlsx source,
// seul endroit où ce contenu existe encore.
//
// Usage : dart run tool/export_xlsx.dart
// Jamais utilisé par l'app elle-même. Nécessite le package `excel` : ajouter
// `excel: ^4.0.6` aux dev_dependencies de pubspec.yaml avant de lancer ce
// script, puis le retirer ensuite (il entrait en conflit de compileSdk avec
// flutter_native_splash — c'est pour ça qu'il n'est pas laissé en place).

import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:excel/excel.dart';

import '../lib/data/defis_data.dart';
import '../lib/data/enigmes_data.dart';
import '../lib/data/multiplayer_data.dart';
import '../lib/data/puzzles_data.dart';
import '../lib/models/puzzle.dart';
import '../lib/services/elo_service.dart';

const _sourceXlsxPath = r'C:\Users\Neophilis\Downloads\cine_devinette_structure_us.xlsx';
const _outputPath = r'C:\Users\Neophilis\Documents\cine-devinette\tool\out\Base-de-donnees-PlotTwisted.xlsx';

// ─── Lecture brute du xlsx source (uniquement pour les lignes "en attente",
// qui n'existent nulle part dans le code Dart) ───

String _unescapeXml(String s) {
  var out = s.replaceAllMapped(RegExp(r'&#(\d+);'), (m) => String.fromCharCode(int.parse(m.group(1)!)));
  out = out
      .replaceAll('&amp;', '&')
      .replaceAll('&apos;', "'")
      .replaceAll('&quot;', '"')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>');
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

/// Lignes brutes (numéro de ligne 1-based -> cellules) d'une feuille du xlsx source.
Map<int, Map<String, String>> _readSourceSheet(Archive zip, int sheetIndex) {
  final entry = zip.files.firstWhere((f) => f.name == 'xl/worksheets/sheet$sheetIndex.xml');
  final xml = utf8.decode(entry.content as List<int>);
  final rowMatches = RegExp(r'<row r="(\d+)"[^>]*>(.*?)</row>', dotAll: true).allMatches(xml);
  final rows = <int, Map<String, String>>{};
  for (final m in rowMatches) {
    rows[int.parse(m.group(1)!)] = _parseRowCells(m.group(2)!);
  }
  return rows;
}

/// Lignes "en attente" d'une feuille source : de (markerRow+1) à lastDataRow,
/// dans l'ordre des colonnes de [columns] (lettres Excel).
List<List<String>> _pendingRows(Map<int, Map<String, String>> sheet, int markerRow, int lastDataRow, List<String> columns) {
  final out = <List<String>>[];
  for (var r = markerRow + 1; r <= lastDataRow; r++) {
    final cells = sheet[r];
    if (cells == null || cells.values.every((v) => v.trim().isEmpty)) continue;
    out.add(columns.map((c) => cells[c] ?? '').toList());
  }
  return out;
}

// ─── Écriture du classeur de sortie ───

void main() {
  print('Lecture du xlsx source...');
  final sourceBytes = File(_sourceXlsxPath).readAsBytesSync();
  final zip = ZipDecoder().decodeBytes(sourceBytes);

  final sheet1Raw = _readSourceSheet(zip, 1); // Jeu principal
  final sheet2Raw = _readSourceSheet(zip, 2); // Énigme
  final sheet3Raw = _readSourceSheet(zip, 3); // Défi

  final pendingJeuPrincipal = _pendingRows(sheet1Raw, 209, 509, [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U',
    'V', 'W', 'X', 'Y', 'Z', 'AA', 'AB', 'AC', 'AD', 'AE', 'AF', 'AG', 'AH', 'AI', 'AJ', 'AK', 'AL', 'AM',
  ]);
  final pendingEnigme = _pendingRows(sheet2Raw, 31, 109, ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I']);
  final pendingDefi = _pendingRows(sheet3Raw, 313, 1413, ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J']);

  print('En attente : ${pendingJeuPrincipal.length} devinettes, ${pendingEnigme.length} énigmes, ${pendingDefi.length} cases de défi.');

  final excel = Excel.createExcel();
  // Feuille par défaut créée automatiquement par le package — supprimée à la fin.
  final defaultSheetName = excel.getDefaultSheet()!;

  _buildJeuPrincipal(excel, pendingJeuPrincipal);
  _buildEnigme(excel, pendingEnigme);
  _buildDefi(excel, pendingDefi);
  _buildMultijoueur(excel);
  _buildTitres(excel);

  excel.delete(defaultSheetName);

  Directory(File(_outputPath).parent.path).createSync(recursive: true);
  final bytes = excel.encode()!;
  File(_outputPath).writeAsBytesSync(bytes);
  print('Écrit : $_outputPath');
}

CellStyle _headerStyle() => CellStyle(bold: true, backgroundColorHex: ExcelColor.fromHexString('FFE4D8BA'));
CellStyle _markerStyle() => CellStyle(bold: true, backgroundColorHex: ExcelColor.fromHexString('FFF5C36B'));

void _writeRow(Sheet sheet, int rowIndex, List<String> values, {CellStyle? style}) {
  for (var c = 0; c < values.length; c++) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: rowIndex));
    cell.value = TextCellValue(values[c]);
    if (style != null) cell.cellStyle = style;
  }
}

void _writeMarker(Sheet sheet, int rowIndex, int colSpan, String text) {
  final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
  cell.value = TextCellValue(text);
  cell.cellStyle = _markerStyle();
  sheet.merge(
    CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
    CellIndex.indexByColumnRow(columnIndex: colSpan - 1, rowIndex: rowIndex),
  );
}

const _kMarkerText =
    '── LIMITE DU JEU ACTUELLE (V1, catalogue 100% bilingue FR/EN) — TOUT CE QUI SUIT N\'EST PAS ENCORE TRADUIT NI DANS L\'APP ──';

NameColor _colorFrom(NameColor c) => c; // no-op, gardé pour lisibilité des call sites
String _colorLabelFr(NameColor c) => switch (c) {
      NameColor.green => 'Vert',
      NameColor.blue => 'Bleu',
      NameColor.red => 'Rouge',
      NameColor.orange => 'Orange',
      NameColor.violet => 'Violet',
    };

void _buildJeuPrincipal(Excel excel, List<List<String>> pending) {
  final sheet = excel['Jeu principal'];
  final header = [
    'Monde', 'Categorie du monde', 'Categorie du monde (US)', 'Niveau', 'Difficulte',
    'Titre du film', 'Titre du film (US)', 'Annee', 'Pitch (avec {p1}/{p2})', 'Pitch (avec {p1}/{p2}) (US)',
    'P1 - couleur depart', 'P1 - Vert (reel)', 'P1 - Vert (reel) (US)', 'P1 - Bleu (acteur)', 'P1 - Bleu (acteur) (US)',
    'P1 - Rouge (autre film)', 'P1 - Rouge (autre film) (US)', 'P1 - Orange (meme role ailleurs)', 'P1 - Orange (meme role ailleurs) (US)',
    'P1 - Violet', 'P1 - Violet (US)',
    'P2 - couleur depart', 'P2 - Vert (reel)', 'P2 - Vert (reel) (US)', 'P2 - Bleu (acteur)', 'P2 - Bleu (acteur) (US)',
    'P2 - Rouge (autre film)', 'P2 - Rouge (autre film) (US)', 'P2 - Orange (meme role ailleurs)', 'P2 - Orange (meme role ailleurs) (US)',
    'P2 - Violet', 'P2 - Violet (US)',
    'Indice (bonus)', 'Indice (bonus) (US)', 'Texte de revelation', 'Texte de revelation (US)',
    'Lien Allocine', 'Lien IMDb (US)', 'Statut',
  ];
  var r = 0;
  _writeRow(sheet, r++, header, style: _headerStyle());

  List<String> puzzleRow(int monde, String cat, String catUs, int niveau, String difficulte, Puzzle p) => [
        '$monde', cat, catUs, '$niveau', difficulte,
        p.title, p.titleUs, p.year, p.pitchTemplate, p.pitchTemplateUs,
        _colorLabelFr(p.p1InitialColor), p.p1.real, p.p1.realUs, p.p1.actor, p.p1.actorUs,
        p.p1.decoy, p.p1.decoyUs, p.p1.sameRoleActor, p.p1.sameRoleActorUs,
        p.p1.violet, p.p1.violetUs,
        p.hasP2 ? _colorLabelFr(p.p2InitialColor) : '', p.p2.real, p.p2.realUs, p.p2.actor, p.p2.actorUs,
        p.p2.decoy, p.p2.decoyUs, p.p2.sameRoleActor, p.p2.sameRoleActorUs,
        p.p2.violet, p.p2.violetUs,
        p.extraHint, p.extraHintUs, p.revealNote, p.revealNoteUs,
        p.allocineUrl, p.imdbUrl, 'V1 (en jeu)',
      ];

  for (var i = 0; i < kTutorialPuzzles.length; i++) {
    _writeRow(sheet, r++, puzzleRow(0, 'Tutoriel', 'Tutorial', i + 1, 'Tutoriel', kTutorialPuzzles[i]));
  }
  for (final world in kWorlds) {
    for (var i = 0; i < world.puzzles.length; i++) {
      final niveau = i + 1;
      final diff = kDifficultyPattern[niveau] ?? '';
      _writeRow(sheet, r++, puzzleRow(world.number, world.categoryLabel, world.categoryLabelUs, niveau, diff, world.puzzles[i]));
    }
  }

  _writeMarker(sheet, r++, header.length, _kMarkerText);
  for (final row in pending) {
    _writeRow(sheet, r++, [...row, 'En attente']);
  }

  sheet.setColumnWidth(0, 8);
  for (var c = 1; c < header.length; c++) {
    sheet.setColumnWidth(c, 22);
  }
}

void _buildEnigme(Excel excel, List<List<String>> pending) {
  final sheet = excel['Enigme de la semaine'];
  final header = ['Ordre (rotation)', '#', 'Categorie', 'Sujet a deviner', 'Sujet a deviner (US)', 'Texte', 'Texte (US)', 'Nb caracteres', 'Annee / Date de naissance', 'Statut'];
  var r = 0;
  _writeRow(sheet, r++, header, style: _headerStyle());

  for (var i = 0; i < kEnigmes.length; i++) {
    final e = kEnigmes[i];
    final annee = e.anneeSortie ?? (e.dateNaissance != null ? '${e.dateNaissance!.year}-${e.dateNaissance!.month.toString().padLeft(2, '0')}-${e.dateNaissance!.day.toString().padLeft(2, '0')}' : '');
    _writeRow(sheet, r++, [
      '${i + 1}', '', e.categorieLabel, e.sujet, e.sujetUs, e.texte, e.texteUs, '${e.sujet.length}', annee, 'V1 (en jeu)',
    ]);
  }

  _writeMarker(sheet, r++, header.length, _kMarkerText);
  for (final row in pending) {
    _writeRow(sheet, r++, [...row, 'En attente']);
  }

  sheet.setColumnWidth(0, 10);
  for (var c = 1; c < header.length; c++) {
    sheet.setColumnWidth(c, 24);
  }
}

void _buildDefi(Excel excel, List<List<String>> pending) {
  final sheet = excel['Defi du jour'];
  final header = ['Type', 'Commun', 'Commun (US)', 'Consigne', 'Consigne (US)', 'Ordre', 'Reponse (case)', 'Reponse (case) (US)', 'Indice', 'Indice (US)', 'Statut'];
  var r = 0;
  _writeRow(sheet, r++, header, style: _headerStyle());

  for (final defi in kDefis) {
    for (var i = 0; i < defi.cases.length; i++) {
      final c = defi.cases[i];
      _writeRow(sheet, r++, [
        defi.typeLabel, defi.commun, defi.communUs, defi.consigne, defi.consigneUs,
        '${i + 1}', c.reponse, c.reponseUs, c.indice, c.indiceUs, 'V1 (en jeu)',
      ]);
    }
  }

  _writeMarker(sheet, r++, header.length, _kMarkerText);
  for (final row in pending) {
    _writeRow(sheet, r++, [...row, 'En attente']);
  }

  sheet.setColumnWidth(0, 14);
  for (var c = 1; c < header.length; c++) {
    sheet.setColumnWidth(c, 26);
  }
}

void _buildMultijoueur(Excel excel) {
  final sheet = excel['Multijoueur'];
  final header = ['id', 'type', 'pitch', 'pitch (US)', 'reponse', 'reponse (US)', 'Nb caracteres'];
  var r = 0;
  _writeRow(sheet, r++, header, style: _headerStyle());
  for (final e in kMultiplayerEnigmes) {
    _writeRow(sheet, r++, [e.id, e.typeLabelFor('fr'), e.pitch, e.pitchUs, e.reponse, e.reponseUs, '${e.reponse.length}']);
  }
  sheet.setColumnWidth(0, 10);
  for (var c = 1; c < header.length; c++) {
    sheet.setColumnWidth(c, 26);
  }
}

void _buildTitres(Excel excel) {
  final sheet = excel['Titres honorifiques'];
  final header = ['Seuil de points (mini)', 'Titre honorifique', 'Titre honorifique (US)'];
  var r = 0;
  _writeRow(sheet, r++, header, style: _headerStyle());
  for (final (seuil, fr, us) in kTitresHonorifiques) {
    _writeRow(sheet, r++, ['$seuil', fr, us]);
  }
  sheet.setColumnWidth(0, 18);
  sheet.setColumnWidth(1, 40);
  sheet.setColumnWidth(2, 40);
}
