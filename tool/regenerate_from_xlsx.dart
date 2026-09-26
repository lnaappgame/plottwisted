// Regenere puzzles_data.dart, enigmes_data.dart, defis_data.dart et
// multiplayer_data.dart depuis cine_devinette_CORRIGE_v2.xlsx (derniere MAJ
// V1, 2026-09-15) — le xlsx est la source de verite complete (structure,
// ordre et contenu), pas juste une liste de champs a corriger. Ecrit
// directement les fichiers Dart. Jamais utilise par l'app elle-meme.
//
// Usage : dart run tool/regenerate_from_xlsx.dart

import 'dart:io';

import '../lib/data/defis_data.dart';
import '../lib/data/enigmes_data.dart';
import '../lib/data/multiplayer_data.dart';

const _xlsxPath = r'C:\Users\Neophilis\Downloads\cine_devinette_CORRIGE_v2.xlsx';
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
  if (result.exitCode != 0) throw Exception('Expand-Archive failed: ${result.stderr}');
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

String _cell(Map<String, String> row, String col) {
  final v = (row[col] ?? '').trim();
  return v == '0' ? '' : v;
}

/// Litteral Dart valide pour [s], quotes simples, echappement minimal.
String _lit(String s) {
  final escaped = s.replaceAll('\\', '\\\\').replaceAll("'", "\\'").replaceAll('\$', '\\\$').replaceAll('\n', '\\n');
  return "'$escaped'";
}

NameColorX _colorFromLabel(String s) {
  switch (s.trim().toLowerCase()) {
    case 'vert': return NameColorX.green;
    case 'bleu': return NameColorX.blue;
    case 'orange': return NameColorX.orange;
    case 'violet': return NameColorX.violet;
    default: return NameColorX.red;
  }
}

// Reimplemente ici (pas d'import de puzzle.dart : on ecrit du texte Dart brut,
// pas besoin du vrai enum).
enum NameColorX { green, blue, red, orange, violet }
String _colorEnumLit(NameColorX c) => 'NameColor.${c.name}';

void main() {
  _extractXlsx();
  _regeneratePuzzles();
  _regenerateEnigmes();
  _regenerateDefis();
  _regenerateMultiplayer();
  _regenerateTitres();
  print('Termine.');
}

// ─────────────────────────── Jeu principal ───────────────────────────

void _regeneratePuzzles() {
  final sheet = _readSheetOrdered(1);
  final headerIdx = sheet.indexWhere((r) => r['A']?.trim() == 'Monde');
  final dataRows = <Map<String, String>>[];
  for (var i = headerIdx + 1; i < sheet.length; i++) {
    final row = sheet[i];
    if (row.values.every((v) => v.trim().isEmpty)) continue;
    if ((row['A'] ?? '').contains('LIMITE DU JEU')) break;
    dataRows.add(row);
  }
  // Les lignes Monde=0 sont le tutoriel ; le reste, groupe par Monde, sont
  // les mondes en jeu (1..20 dans le perimetre V1 actuel). Lecture brute de
  // la colonne A (pas via _cell, qui traite "0" comme "vide" — a raison pour
  // les champs optionnels, a tort ici ou 0 est une valeur de monde valide).
  String worldNum(Map<String, String> r) => (r['A'] ?? '').trim();
  final tutorialRows = dataRows.where((r) => worldNum(r) == '0').toList();
  final worldNumbers = dataRows.map((r) => int.tryParse(worldNum(r)) ?? -1).toSet().where((n) => n >= 1 && n <= 20).toList()..sort();

  String personRefLit(Map<String, String> row, String colColor, String colReal, String colRealUs, String colActor,
      String colActorUs, String colDecoy, String colDecoyUs, String colSame, String colSameUs, String colViolet, String colVioletUs) {
    return '''PersonRef(
      real: ${_lit(_cell(row, colReal))},
      realUs: ${_lit(_cell(row, colRealUs))},
      actor: ${_lit(_cell(row, colActor))},
      actorUs: ${_lit(_cell(row, colActorUs))},
      decoy: ${_lit(_cell(row, colDecoy))},
      decoyUs: ${_lit(_cell(row, colDecoyUs))},
      decoyFilm: '',
      decoyFilmUs: '',
      sameRoleActor: ${_lit(_cell(row, colSame))},
      sameRoleActorUs: ${_lit(_cell(row, colSameUs))},
      sameRoleFilm: '',
      sameRoleFilmUs: '',
      violet: ${_lit(_cell(row, colViolet))},
      violetUs: ${_lit(_cell(row, colVioletUs))},
    )''';
  }

  String puzzleLit(Map<String, String> row) {
    final p2Color = _cell(row, 'V');
    return '''Puzzle(
    title: ${_lit(_cell(row, 'F'))},
    titleUs: ${_lit(_cell(row, 'G'))},
    year: ${_lit(_cell(row, 'H'))},
    pitchTemplate: ${_lit(_cell(row, 'I'))},
    pitchTemplateUs: ${_lit(_cell(row, 'J'))},
    allocineUrl: ${_lit(_cell(row, 'AK'))},
    imdbUrl: ${_lit(_cell(row, 'AL'))},
    extraHint: ${_lit(_cell(row, 'AG'))},
    extraHintUs: ${_lit(_cell(row, 'AH'))},
    revealNote: ${_lit(_cell(row, 'AI'))},
    revealNoteUs: ${_lit(_cell(row, 'AJ'))},
    p1InitialColor: ${_colorEnumLit(_colorFromLabel(_cell(row, 'K')))},
    p2InitialColor: ${p2Color.isEmpty ? _colorEnumLit(NameColorX.green) : _colorEnumLit(_colorFromLabel(p2Color))},
    p1: ${personRefLit(row, 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U')},
    p2: ${personRefLit(row, 'V', 'W', 'X', 'Y', 'Z', 'AA', 'AB', 'AC', 'AD', 'AE', 'AF')},
  )''';
  }

  final buf = StringBuffer();
  buf.writeln("import '../models/puzzle.dart';");
  buf.writeln();
  buf.writeln('// Fichier regenere automatiquement depuis cine_devinette_CORRIGE_v2.xlsx');
  buf.writeln('// (derniere MAJ V1, 2026-09-15). Perimetre inchange : tutoriel + mondes 1 a 20.');
  buf.writeln('// Pour regenerer, relancer tool/regenerate_from_xlsx.dart.');
  buf.writeln();
  buf.writeln('final List<Puzzle> kTutorialPuzzles = [');
  for (final row in tutorialRows) {
    buf.writeln('  ${puzzleLit(row)},');
  }
  buf.writeln('];');
  buf.writeln();
  buf.writeln('final List<GameWorld> kWorlds = [');
  for (final wn in worldNumbers) {
    final worldRows = dataRows.where((r) => worldNum(r) == '$wn').toList();
    final cat = _cell(worldRows.first, 'B');
    final catUs = _cell(worldRows.first, 'C');
    buf.writeln('  GameWorld(number: $wn, categoryLabel: ${_lit(cat)}, categoryLabelUs: ${_lit(catUs)}, puzzles: [');
    for (final row in worldRows) {
      buf.writeln('    ${puzzleLit(row)},');
    }
    buf.writeln('  ]),');
  }
  buf.writeln('];');

  final totalPuzzles = tutorialRows.length + worldNumbers.fold<int>(0, (sum, wn) => sum + dataRows.where((r) => worldNum(r) == '$wn').length);
  File(r'C:\Users\Neophilis\Documents\cine-devinette\lib\data\puzzles_data.dart').writeAsStringSync(buf.toString());
  print('puzzles_data.dart : ${tutorialRows.length} tutoriel + ${worldNumbers.length} mondes ($totalPuzzles devinettes).');
}

// ─────────────────────────── Enigme de la semaine ───────────────────────────

void _regenerateEnigmes() {
  final sheet = _readSheetOrdered(2);
  final headerIdx = sheet.indexWhere((r) => _cell(r, 'A') == 'Ordre');
  final dataRows = <Map<String, String>>[];
  for (var i = headerIdx + 1; i < sheet.length; i++) {
    final row = sheet[i];
    if (row.values.every((v) => v.trim().isEmpty)) continue;
    dataRows.add(row);
  }
  // Cle de correspondance : Sujet (normalise) -> ligne xlsx ; repli sur le
  // Sujet US si le Sujet FR a ete traduit/renomme par la correction (ex.
  // "HOMELANDER" -> "LE PROTECTEUR" en FR, "HOMELANDER" inchange en US).
  final bySujet = <String, Map<String, String>>{};
  final bySujetUs = <String, Map<String, String>>{};
  for (final row in dataRows) {
    bySujet[_cell(row, 'D').toUpperCase()] = row;
    bySujetUs[_cell(row, 'E').toUpperCase()] = row;
  }

  final buf = StringBuffer();
  buf.writeln("import '../models/enigme.dart';");
  buf.writeln();
  buf.writeln('// Fichier regenere automatiquement depuis cine_devinette_CORRIGE_v2.xlsx');
  buf.writeln('// (derniere MAJ V1, 2026-09-15). Perimetre et ordre de rotation inchanges :');
  buf.writeln('// chaque enigme deja en jeu est retrouvee par son Sujet dans le fichier.');
  buf.writeln('// Pour regenerer, relancer tool/regenerate_from_xlsx.dart.');
  buf.writeln();
  buf.writeln('final List<Enigme> kEnigmes = [');
  var notFound = 0;
  for (final e in kEnigmes) {
    final row = bySujet[e.sujet.toUpperCase()] ?? bySujetUs[e.sujetUs.toUpperCase()];
    if (row == null) {
      notFound++;
      print('  ATTENTION : sujet non retrouve dans le xlsx, entree Dart conservee telle quelle : ${e.sujet}');
      buf.writeln('  Enigme(');
      buf.writeln('    categorie: EnigmeCategorie.${e.categorie.name},');
      buf.writeln('    sujet: ${_lit(e.sujet)},');
      buf.writeln('    sujetUs: ${_lit(e.sujetUs)},');
      buf.writeln('    texte: ${_lit(e.texte)},');
      buf.writeln('    texteUs: ${_lit(e.texteUs)},');
      if (e.anneeSortie != null) buf.writeln('    anneeSortie: ${_lit(e.anneeSortie!)},');
      if (e.dateNaissance != null) {
        final d = e.dateNaissance!;
        buf.writeln('    dateNaissance: DateTime(${d.year}, ${d.month}, ${d.day}),');
      }
      buf.writeln('  ),');
      continue;
    }
    final catLabel = _cell(row, 'C').toLowerCase();
    final categorie = catLabel == 'film' ? 'film' : (catLabel == 'personnage' ? 'personnage' : 'acteur');
    final anneeDate = _cell(row, 'I');
    buf.writeln('  Enigme(');
    buf.writeln('    categorie: EnigmeCategorie.$categorie,');
    buf.writeln('    sujet: ${_lit(_cell(row, 'D'))},');
    buf.writeln('    sujetUs: ${_lit(_cell(row, 'E'))},');
    buf.writeln('    texte: ${_lit(_cell(row, 'F'))},');
    buf.writeln('    texteUs: ${_lit(_cell(row, 'G'))},');
    if (categorie == 'film') {
      buf.writeln('    anneeSortie: ${_lit(anneeDate)},');
    } else if (categorie == 'acteur' && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(anneeDate)) {
      final parts = anneeDate.split('-');
      buf.writeln('    dateNaissance: DateTime(${int.parse(parts[0])}, ${int.parse(parts[1])}, ${int.parse(parts[2])}),');
    }
    buf.writeln('  ),');
  }
  buf.writeln('];');

  File(r'C:\Users\Neophilis\Documents\cine-devinette\lib\data\enigmes_data.dart').writeAsStringSync(buf.toString());
  print('enigmes_data.dart : ${kEnigmes.length} enigmes (${kEnigmes.length - notFound} retrouvees dans le xlsx, $notFound conservees telles quelles).');
}

// ─────────────────────────── Defi du jour ───────────────────────────

void _regenerateDefis() {
  final sheet = _readSheetOrdered(3);
  final headerIdx = sheet.indexWhere((r) => _cell(r, 'A') == 'Type');
  final dataRows = <Map<String, String>>[];
  for (var i = headerIdx + 1; i < sheet.length; i++) {
    final row = sheet[i];
    if (row.values.every((v) => v.trim().isEmpty)) continue;
    if ((row['A'] ?? '').contains('LIMITE DU JEU')) break;
    dataRows.add(row);
  }
  // Segmente en blocs (un bloc = un "commun") a chaque retour a Ordre=1.
  final blocks = <List<Map<String, String>>>[];
  for (final row in dataRows) {
    if (_cell(row, 'F') == '1' || blocks.isEmpty) blocks.add([]);
    blocks.last.add(row);
  }

  String typeEnumFromLabel(String label) => switch (label.trim().toLowerCase()) {
        'personnage' => 'personnage',
        'acteur' => 'acteur',
        'realisateur' => 'realisateur',
        'film' => 'film',
        _ => 'personnage',
      };

  // Cle de correspondance : (commun normalise, consigne normalisee) -> bloc.
  // Necessaire car un meme nom de commun peut couvrir 2 defis differents
  // (ex. Batman = acteurs du role, et separement Batman = mechants des films).
  final byKey = <String, List<Map<String, String>>>{};
  for (final block in blocks) {
    final first = block.first;
    final key = '${_cell(first, "B").toUpperCase()}|||${_cell(first, "D").toUpperCase()}';
    byKey[key] = block;
  }
  // Repli : commun seul, si une seule occurrence de ce commun existe.
  final byCommunOnly = <String, List<List<Map<String, String>>>>{};
  for (final block in blocks) {
    final commun = _cell(block.first, 'B').toUpperCase();
    (byCommunOnly[commun] ??= []).add(block);
  }

  final buf = StringBuffer();
  buf.writeln("import '../models/defi.dart';");
  buf.writeln();
  buf.writeln('// Fichier regenere automatiquement depuis cine_devinette_CORRIGE_v2.xlsx');
  buf.writeln('// (derniere MAJ V1, 2026-09-15). Chaque defi deja en jeu est retrouve par');
  buf.writeln('// (Commun + Consigne) dans le fichier ; ses cases (nombre, ordre, contenu)');
  buf.writeln('// sont entierement recalculees depuis le bloc xlsx correspondant.');
  buf.writeln('// Pour regenerer, relancer tool/regenerate_from_xlsx.dart.');
  buf.writeln();
  buf.writeln('final List<Defi> kDefis = [');
  var notFound = 0;
  for (final defi in kDefis) {
    final key = '${defi.commun.toUpperCase()}|||${defi.consigne.toUpperCase()}';
    var block = byKey[key];
    block ??= (byCommunOnly[defi.commun.toUpperCase()]?.length == 1) ? byCommunOnly[defi.commun.toUpperCase()]!.first : null;
    if (block == null) {
      notFound++;
      print('  ATTENTION : defi non retrouve dans le xlsx (ambigu ou absent), conserve tel quel : ${defi.id} / ${defi.commun}');
      buf.writeln('  Defi(');
      buf.writeln('    id: ${_lit(defi.id)},');
      buf.writeln('    type: DefiType.${defi.type.name},');
      buf.writeln('    commun: ${_lit(defi.commun)},');
      buf.writeln('    communUs: ${_lit(defi.communUs)},');
      buf.writeln('    consigne: ${_lit(defi.consigne)},');
      buf.writeln('    consigneUs: ${_lit(defi.consigneUs)},');
      buf.writeln('    cases: [');
      for (final c in defi.cases) {
        buf.writeln('      DefiCase(reponse: ${_lit(c.reponse)}, reponseUs: ${_lit(c.reponseUs)}, indice: ${_lit(c.indice)}, indiceUs: ${_lit(c.indiceUs)}),');
      }
      buf.writeln('    ],');
      buf.writeln('  ),');
      continue;
    }
    final first = block.first;
    buf.writeln('  Defi(');
    buf.writeln('    id: ${_lit(defi.id)},');
    buf.writeln('    type: DefiType.${typeEnumFromLabel(_cell(first, 'A'))},');
    buf.writeln('    commun: ${_lit(_cell(first, 'B'))},');
    buf.writeln('    communUs: ${_lit(_cell(first, 'C'))},');
    buf.writeln('    consigne: ${_lit(_cell(first, 'D'))},');
    buf.writeln('    consigneUs: ${_lit(_cell(first, 'E'))},');
    buf.writeln('    cases: [');
    for (final row in block) {
      buf.writeln('      DefiCase(');
      buf.writeln('        reponse: ${_lit(_cell(row, 'G'))},');
      buf.writeln('        reponseUs: ${_lit(_cell(row, 'H'))},');
      buf.writeln('        indice: ${_lit(_cell(row, 'I'))},');
      buf.writeln('        indiceUs: ${_lit(_cell(row, 'J'))},');
      buf.writeln('      ),');
    }
    buf.writeln('    ],');
    buf.writeln('  ),');
  }
  buf.writeln('];');

  File(r'C:\Users\Neophilis\Documents\cine-devinette\lib\data\defis_data.dart').writeAsStringSync(buf.toString());
  print('defis_data.dart : ${kDefis.length} defis (${kDefis.length - notFound} retrouves dans le xlsx, $notFound conserves tels quels).');
}

// ─────────────────────────── Multijoueur ───────────────────────────

void _regenerateMultiplayer() {
  final sheet = _readSheetOrdered(4);
  final headerIdx = sheet.indexWhere((r) => _cell(r, 'A') == 'id');
  final dataRows = <Map<String, String>>[];
  for (var i = headerIdx + 1; i < sheet.length; i++) {
    final row = sheet[i];
    if (row.values.every((v) => v.trim().isEmpty)) continue;
    dataRows.add(row);
  }
  final byId = <String, Map<String, String>>{};
  for (final row in dataRows) {
    byId[_cell(row, 'A')] = row;
  }

  String typeEnumFromLabel(String label) => switch (label.trim().toLowerCase()) {
        'film' => 'film',
        'personnalite' => 'personnalite',
        'personnalité' => 'personnalite',
        'serie' => 'serie',
        'série' => 'serie',
        _ => 'film',
      };

  final buf = StringBuffer();
  buf.writeln("import '../models/multiplayer.dart';");
  buf.writeln();
  buf.writeln('// Fichier regenere automatiquement depuis cine_devinette_CORRIGE_v2.xlsx');
  buf.writeln('// (derniere MAJ V1, 2026-09-15). Chaque enigme deja en jeu est retrouvee par');
  buf.writeln('// son id dans le fichier.');
  buf.writeln('// Pour regenerer, relancer tool/regenerate_from_xlsx.dart.');
  buf.writeln();
  buf.writeln('final List<MultiplayerEnigme> kMultiplayerEnigmes = [');
  var notFound = 0;
  for (final e in kMultiplayerEnigmes) {
    final row = byId[e.id];
    if (row == null) {
      notFound++;
      print('  ATTENTION : id non retrouve dans le xlsx, conserve tel quel : ${e.id}');
      buf.writeln('  MultiplayerEnigme(');
      buf.writeln('    id: ${_lit(e.id)},');
      buf.writeln('    type: MultiplayerType.${e.type.name},');
      buf.writeln('    pitch: ${_lit(e.pitch)},');
      buf.writeln('    pitchUs: ${_lit(e.pitchUs)},');
      buf.writeln('    reponse: ${_lit(e.reponse)},');
      buf.writeln('    reponseUs: ${_lit(e.reponseUs)},');
      buf.writeln('  ),');
      continue;
    }
    buf.writeln('  MultiplayerEnigme(');
    buf.writeln('    id: ${_lit(_cell(row, 'A'))},');
    buf.writeln('    type: MultiplayerType.${typeEnumFromLabel(_cell(row, 'B'))},');
    buf.writeln('    pitch: ${_lit(_cell(row, 'C'))},');
    buf.writeln('    pitchUs: ${_lit(_cell(row, 'D'))},');
    buf.writeln('    reponse: ${_lit(_cell(row, 'E'))},');
    buf.writeln('    reponseUs: ${_lit(_cell(row, 'F'))},');
    buf.writeln('  ),');
  }
  buf.writeln('];');

  File(r'C:\Users\Neophilis\Documents\cine-devinette\lib\data\multiplayer_data.dart').writeAsStringSync(buf.toString());
  print('multiplayer_data.dart : ${kMultiplayerEnigmes.length} enigmes (${kMultiplayerEnigmes.length - notFound} retrouvees, $notFound conservees telles quelles).');
}

// ─────────────────────────── Titres honorifiques ───────────────────────────

void _regenerateTitres() {
  final sheet = _readSheetOrdered(5);
  final headerIdx = sheet.indexWhere((r) => _cell(r, 'A').contains('Seuil'));
  final dataRows = <Map<String, String>>[];
  for (var i = headerIdx + 1; i < sheet.length; i++) {
    final row = sheet[i];
    if (row.values.every((v) => v.trim().isEmpty)) continue;
    dataRows.add(row);
  }
  dataRows.sort((a, b) => (int.tryParse(_cell(a, 'A')) ?? 0).compareTo(int.tryParse(_cell(b, 'A')) ?? 0));

  final buf = StringBuffer();
  buf.writeln('const List<(int, String, String)> kTitresHonorifiquesNouveau = [');
  for (final row in dataRows) {
    final seuil = int.tryParse(_cell(row, 'A')) ?? 0;
    buf.writeln('  ($seuil, ${_lit(_cell(row, 'B'))}, ${_lit(_cell(row, 'C'))}),');
  }
  buf.writeln('];');

  File(r'C:\Users\Neophilis\Documents\cine-devinette\tool\out\titres_honorifiques_snippet.dart').writeAsStringSync(buf.toString());
  print('titres_honorifiques_snippet.dart : ${dataRows.length} paliers ecrits dans tool/out (a fusionner manuellement dans elo_service.dart).');
}
