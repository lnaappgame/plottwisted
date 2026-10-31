// Modifications de la base demandées par Damien le 31/10/2026 (voir
// notes/modifs-base-a-faire.md). Lit le xlsx du 13/10, écrit une copie
// datée du 31/10 en ne touchant qu'à l'onglet « Jeu principal » :
//   - Billy Elliot (25-9) et Thor (23-9) ne dévoilent plus le titre ;
//   - Star Wars 5 (23-10) : indice violet « Père de Luke Skywalker » ;
//   - Captain Phillips (20-9) devient CAPITAINE PHILLIPS ;
//   - Hôtel Rwanda (20-7) et Le Majordome (20-10) échangent leur place ;
//   - monde 19 : Psychose, Les Oiseaux, Chantons sous la pluie et Working
//     Girl remplacent La Bidasse, Sailor et Lula, Kramer contre Kramer et
//     Retour à Howards End ;
//   - The Pitt remplace Private Practice dans le monde « Série médicale » ;
//   - les mondes 28, 45, 46, 27 et 33 du tableur passent au-dessus de la ligne
//     LIMITE et deviennent les mondes 26 à 30 ; les mondes en attente restants
//     sont renumérotés de 31 à 50.
// Les cellules gardent leur style ; les nouveaux textes sont ajoutés aux
// chaînes partagées. Outil de dev, jamais utilisé par l'app.
//
// Usage : dart run tool/apply_modifs_2026_10_31.dart

import 'dart:io';

import 'xlsx_read.dart' show unescapeXml;

const _src = r'C:\Users\Neophilis\Documents\cine-devinette\exports\Base-de-donnees-PlotTwisted-2026-10-13.xlsx';
const _dst = r'C:\Users\Neophilis\Documents\cine-devinette\exports\Base-de-donnees-PlotTwisted-2026-10-31.xlsx';

late List<String> _shared;
final _added = <String, int>{};

String _escape(String s) =>
    s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;');

int _colIndex(String letters) {
  var n = 0;
  for (final c in letters.codeUnits) {
    n = n * 26 + (c - 64);
  }
  return n;
}

class _Row {
  _Row(this.cells);
  // colonne -> XML complet de la cellule (r="" sans numéro de ligne réécrit à l'écriture)
  final Map<String, String> cells;

  String get(String col) {
    final xml = cells[col];
    if (xml == null) return '';
    final v = RegExp(r'<v>(.*?)</v>', dotAll: true).firstMatch(xml)?.group(1);
    if (v == null) return '';
    if (xml.contains('t="s"')) return _shared[int.parse(v)];
    return unescapeXml(v);
  }

  String get style => RegExp(r' s="(\d+)"').firstMatch(cells['F'] ?? cells['A'] ?? '')?.group(1) ?? '2';

  void set(String col, String value) {
    if (value.isEmpty) {
      cells.remove(col);
      return;
    }
    final idx = _added.putIfAbsent(value, () {
      _shared.add(value);
      return _shared.length - 1;
    });
    final s = RegExp(r' s="(\d+)"').firstMatch(cells[col] ?? '')?.group(1) ?? style;
    cells[col] = '<c r="$col#" s="$s" t="s"><v>$idx</v></c>';
  }

  String toXml(int r) {
    final cols = cells.keys.toList()..sort((a, b) => _colIndex(a).compareTo(_colIndex(b)));
    final buf = StringBuffer('<row r="$r">');
    for (final c in cols) {
      buf.write(cells[c]!.replaceFirst(RegExp(r'<c r="[A-Z]+[0-9#]*"'), '<c r="$c$r"'));
    }
    buf.write('</row>');
    return buf.toString();
  }
}

/// Remplit une ligne complète (colonnes F à AL) ; les clés absentes sont vidées.
void _fill(_Row row, Map<String, String> v, {String empty = ''}) {
  const cols = ['F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
      'AA', 'AB', 'AC', 'AD', 'AE', 'AF', 'AG', 'AH', 'AI', 'AJ', 'AK', 'AL'];
  for (final c in cols) {
    row.set(c, v[c] ?? empty);
  }
}

String _google(String title, String kind) =>
    'https://www.google.com/search?q=${Uri.encodeComponent(title)}%20$kind%20allocine';
String _imdb(String q) => 'https://www.imdb.com/find/?q=${Uri.encodeComponent(q)}';

void main() {
  final work = Directory('${Directory.systemTemp.path}\\pt_modifs_1031');
  if (work.existsSync()) work.deleteSync(recursive: true);
  final zip = '${work.path}.zip';
  File(_src).copySync(zip);
  var r = Process.runSync('powershell', ['-NoProfile', '-Command', "Expand-Archive -Path '$zip' -DestinationPath '${work.path}' -Force"]);
  if (r.exitCode != 0) throw Exception(r.stderr);

  final sstFile = File('${work.path}/xl/sharedStrings.xml');
  final sstXml = sstFile.readAsStringSync();
  final siList = RegExp(r'<si>(.*?)</si>', dotAll: true).allMatches(sstXml).map((m) => m.group(0)!).toList();
  _shared = [
    for (final si in siList)
      RegExp(r'<t(?:\s[^>]*)?>(.*?)</t>', dotAll: true).allMatches(si).map((m) => unescapeXml(m.group(1)!)).join(),
  ];
  final originalShared = _shared.length;

  final sheetFile = File('${work.path}/xl/worksheets/sheet1.xml');
  final sheetXml = sheetFile.readAsStringSync();
  final dataStart = sheetXml.indexOf('<sheetData>');
  final dataEnd = sheetXml.indexOf('</sheetData>');
  final rows = <_Row>[];
  for (final m in RegExp(r'<row r="(\d+)"[^>]*>(.*?)</row>', dotAll: true).allMatches(sheetXml.substring(dataStart, dataEnd))) {
    final cells = <String, String>{};
    for (final c in RegExp(r'<c r="([A-Z]+)\d+"[^>]*?(?:/>|>.*?</c>)', dotAll: true).allMatches(m.group(2)!)) {
      cells[c.group(1)!] = c.group(0)!;
    }
    rows.add(_Row(cells));
  }
  print('Lignes lues : ${rows.length}');

  final limit = rows.indexWhere((x) => x.get('A').contains('LIMITE DU JEU'));
  _Row at(String world, int level) => rows.firstWhere((x) => x.get('A') == world && x.get('D') == '$level');

  // ── 1. Billy Elliot : p1 rouge « Tintin » (autre rôle de Jamie Bell) ──
  final billy = at('25', 9);
  billy.set('K', 'Rouge');
  billy.set('P', 'Tintin');
  billy.set('Q', 'Tintin');

  // ── 2. Thor : p2 rouge « Le Chasseur » (autre rôle de Chris Hemsworth) ──
  final thor = at('23', 9);
  thor.set('V', 'Rouge');
  thor.set('AA', 'Le Chasseur (Blanche-Neige)');
  thor.set('AB', 'The Huntsman (Snow White)');

  // ── 3. Star Wars 5 : indice violet ──
  final sw5 = at('23', 10);
  sw5.set('AE', 'Père de Luke Skywalker');
  sw5.set('AF', 'Father of Luke Skywalker');

  // ── 5. Capitaine Phillips ──
  final phillips = at('20', 9);
  phillips.set('F', 'CAPITAINE PHILLIPS');
  phillips.set('AK', _google('CAPITAINE PHILLIPS', 'film'));

  // ── 6. Hôtel Rwanda (20-7) <-> Le Majordome (20-10) : on échange le contenu,
  // chaque position garde son numéro et son libellé de difficulté ──
  final r7 = at('20', 7), r10 = at('20', 10);
  final keep7 = {for (final c in ['A', 'B', 'C', 'D', 'E']) c: r7.cells[c]};
  final keep10 = {for (final c in ['A', 'B', 'C', 'D', 'E']) c: r10.cells[c]};
  final tmp = Map<String, String>.from(r7.cells);
  r7.cells
    ..clear()
    ..addAll(r10.cells);
  r10.cells
    ..clear()
    ..addAll(tmp);
  keep7.forEach((c, v) => v == null ? r7.cells.remove(c) : r7.cells[c] = v);
  keep10.forEach((c, v) => v == null ? r10.cells.remove(c) : r10.cells[c] = v);

  // ── 4. Monde 19 « Mère de... » : 4 films remplacés ──
  _fill(at('19', 3), {
    'F': 'PSYCHOSE', 'G': 'PSYCHO', 'H': '1960',
    'I': "{p1}, secrétaire en cavale avec l'argent de son patron, fait halte pour la nuit dans un motel isolé tenu par {p2}, un jeune homme timide très attaché à sa mère.",
    'J': "{p1}, a secretary on the run with her boss's money, stops for the night at a remote motel run by {p2}, a shy young man very attached to his mother.",
    'K': 'Violet', 'L': 'Marion Crane', 'M': 'Marion Crane', 'N': 'Janet Leigh', 'O': 'Janet Leigh',
    'T': 'Mère de Jamie Lee Curtis', 'U': 'Mother of Jamie Lee Curtis',
    'V': 'Vert', 'W': 'Norman Bates', 'X': 'Norman Bates', 'Y': 'Anthony Perkins', 'Z': 'Anthony Perkins',
    'AG': "La scène la plus célèbre du film se déroule dans une salle de bain, sous la douche.",
    'AH': "The film's most famous scene takes place in a bathroom, in the shower.",
    'AI': "L'actrice principale est la mère de Jamie Lee Curtis.",
    'AJ': 'The lead actress is the mother of Jamie Lee Curtis.',
    'AK': _google('PSYCHOSE', 'film'), 'AL': _imdb('Psycho 1960'),
  });
  _fill(at('19', 4), {
    'F': 'LES OISEAUX', 'G': 'THE BIRDS', 'H': '1963',
    'I': "{p1}, jeune femme de la bonne société de San Francisco, débarque dans une paisible baie de Californie pour séduire {p2}, un avocat, au moment où la nature se retourne mystérieusement contre les habitants.",
    'J': '{p1}, a young San Francisco socialite, arrives in a quiet California bay town to win over {p2}, a lawyer, just as nature mysteriously turns against the locals.',
    'K': 'Violet', 'L': 'Melanie Daniels', 'M': 'Melanie Daniels', 'N': 'Tippi Hedren', 'O': 'Tippi Hedren',
    'T': 'Mère de Melanie Griffith', 'U': 'Mother of Melanie Griffith',
    'V': 'Vert', 'W': 'Mitch Brenner', 'X': 'Mitch Brenner', 'Y': 'Rod Taylor', 'Z': 'Rod Taylor',
    'AG': "Pour faire bonne impression, l'héroïne arrive avec un cadeau : un couple d'inséparables en cage.",
    'AH': 'To make a good impression, the heroine arrives bearing a gift: a pair of caged lovebirds.',
    'AI': "L'actrice principale est la mère de Melanie Griffith, elle-même mère de Dakota Johnson.",
    'AJ': 'The lead actress is the mother of Melanie Griffith, herself the mother of Dakota Johnson.',
    'AK': _google('LES OISEAUX', 'film'), 'AL': _imdb('The Birds 1963'),
  });
  _fill(at('19', 6), {
    'F': 'CHANTONS SOUS LA PLUIE', 'G': "SINGIN' IN THE RAIN", 'H': '1952',
    'I': "À Hollywood, à l'arrivée du cinéma parlant, {p1}, star du muet, tombe amoureux de {p2}, une jeune danseuse dont la voix va sauver son premier film sonore.",
    'J': 'In Hollywood, as talking pictures arrive, {p1}, a silent-film star, falls for {p2}, a young dancer whose voice will save his first sound picture.',
    'K': 'Vert', 'L': 'Don Lockwood', 'M': 'Don Lockwood', 'N': 'Gene Kelly', 'O': 'Gene Kelly',
    'V': 'Violet', 'W': 'Kathy Selden', 'X': 'Kathy Selden', 'Y': 'Debbie Reynolds', 'Z': 'Debbie Reynolds',
    'AE': 'Mère de Carrie Fisher', 'AF': 'Mother of Carrie Fisher',
    'AG': 'Le film se moque du passage difficile des stars du muet au cinéma parlant, à la fin des années 1920.',
    'AH': "The film pokes fun at silent stars' rocky move to talking pictures in the late 1920s.",
    'AI': "L'actrice principale est la mère de Carrie Fisher, la princesse Leia de Star Wars.",
    'AJ': "The lead actress is the mother of Carrie Fisher, Star Wars' Princess Leia.",
    'AK': _google('CHANTONS SOUS LA PLUIE', 'film'), 'AL': _imdb("Singin' in the Rain 1952"),
  });
  _fill(at('19', 9), {
    'F': 'WORKING GIRL', 'G': 'WORKING GIRL', 'H': '1988',
    'I': "{p1}, secrétaire ambitieuse à Wall Street, profite de l'absence de sa patronne pour monter une grosse fusion avec {p2}, un négociateur qu'elle séduit en se faisant passer pour une cadre.",
    'J': "{p1}, an ambitious Wall Street secretary, takes advantage of her boss's absence to put together a big merger with {p2}, a dealmaker she wins over by posing as an executive.",
    'K': 'Violet', 'L': 'Tess McGill', 'M': 'Tess McGill', 'N': 'Melanie Griffith', 'O': 'Melanie Griffith',
    'T': 'Mère de Dakota Johnson', 'U': 'Mother of Dakota Johnson',
    'V': 'Rouge', 'W': 'Jack Trainer', 'X': 'Jack Trainer', 'Y': 'Harrison Ford', 'Z': 'Harrison Ford',
    'AA': 'Indiana Jones', 'AB': 'Indiana Jones',
    'AG': "Sa patronne, jouée par Sigourney Weaver, est clouée au lit après un accident de ski.",
    'AH': 'Her boss, played by Sigourney Weaver, is laid up after a skiing accident.',
    'AI': "L'actrice principale est la mère de Dakota Johnson et la fille de Tippi Hedren.",
    'AJ': 'The lead actress is the mother of Dakota Johnson and the daughter of Tippi Hedren.',
    'AK': _google('WORKING GIRL', 'film'), 'AL': _imdb('Working Girl 1988'),
  });

  // ── 7a. The Pitt remplace Private Practice (monde « Série médicale ») ──
  _fill(at('28', 8), {
    'F': 'THE PITT', 'G': 'THE PITT', 'H': '2025',
    'I': "{p1}, chef des urgences d'un hôpital de Pittsburgh, enchaîne une garde de quinze heures racontée en temps réel, épaulé par {p2}, son médecin résident le plus brillant.",
    'J': "{p1}, head of a Pittsburgh hospital's emergency department, battles through a fifteen-hour shift told in real time, backed by {p2}, his most gifted senior resident.",
    'K': 'Rouge', 'L': 'Dr Michael Robinavitch', 'M': 'Dr Michael Robinavitch', 'N': 'Noah Wyle', 'O': 'Noah Wyle',
    'P': 'Dr John Carter', 'Q': 'Dr John Carter',
    'V': 'Vert', 'W': 'Dr Frank Langdon', 'X': 'Dr Frank Langdon', 'Y': 'Patrick Ball', 'Z': 'Patrick Ball',
    'AG': 'Chaque épisode de la série correspond à une heure de la même garde aux urgences.',
    'AH': 'Each episode of the show covers one hour of the same ER shift.',
    'AI': "L'acteur principal jouait déjà un médecin urgentiste dans Urgences, trente ans plus tôt.",
    'AJ': 'The lead actor already played an emergency doctor in ER, thirty years earlier.',
    'AK': _google('THE PITT', 'serie'), 'AL': _imdb('The Pitt TV series'),
  }, empty: '0');

  // ── 7b. Mondes 28, 45, 46, 27, 33 -> 26 à 30, au-dessus de la ligne LIMITE ──
  final above = rows.sublist(0, limit);
  final limitRow = rows[limit];
  final below = rows.sublist(limit + 1);
  const promoted = ['28', '45', '46', '27', '33'];
  // On regroupe d'abord, puis on renumérote : sinon le monde 45 devenu « 27 »
  // se mélangerait à l'ancien monde 27.
  final groups = [for (final w in promoted) below.where((x) => x.get('A') == w).toList()];
  final newWorlds = <_Row>[];
  for (var i = 0; i < promoted.length; i++) {
    if (groups[i].length != 10) throw Exception('Monde ${promoted[i]} : ${groups[i].length} lignes');
    for (final w in groups[i]) {
      w.set('A', '${26 + i}');
      w.set('AM', 'V1 (en jeu)');
    }
    newWorlds.addAll(groups[i]);
  }
  final rest = below.where((x) => !newWorlds.contains(x)).toList();
  final oldNumbers = <String>[];
  for (final x in rest) {
    final a = x.get('A');
    if (int.tryParse(a) != null && !oldNumbers.contains(a)) oldNumbers.add(a);
  }
  final renumber = {for (var i = 0; i < oldNumbers.length; i++) oldNumbers[i]: '${31 + i}'};
  for (final x in rest) {
    final a = x.get('A');
    if (renumber.containsKey(a)) x.set('A', renumber[a]!);
  }
  print('Renumérotation des mondes en attente : $renumber');
  limitRow.set('A',
      "── LIMITE DU JEU ACTUELLE (tutoriel + mondes 1 à 30, catalogue 100% bilingue FR/EN) — TOUT CE QUI SUIT N'EST PAS ENCORE DANS L'APP ──");

  final ordered = [...above, ...newWorlds, limitRow, ...rest];
  final newLimitRowNumber = above.length + newWorlds.length + 1;

  // ── Écriture ──
  final dataXml = StringBuffer('<sheetData>');
  for (var i = 0; i < ordered.length; i++) {
    dataXml.write(ordered[i].toXml(i + 1));
  }
  var newSheet = sheetXml.substring(0, dataStart) + dataXml.toString() + sheetXml.substring(dataEnd);
  newSheet = newSheet.replaceFirst(RegExp(r'<mergeCell ref="A\d+:AM\d+"/>'), '<mergeCell ref="A$newLimitRowNumber:AM$newLimitRowNumber"/>');
  sheetFile.writeAsStringSync(newSheet);

  final newSi = [for (final s in _shared.sublist(originalShared)) '<si><t xml:space="preserve">${_escape(s)}</t></si>'];
  final refs = RegExp(r't="s"').allMatches(newSheet).length;
  var newSst = sstXml.replaceFirst('</sst>', '${newSi.join()}</sst>');
  newSst = newSst.replaceFirst(RegExp(r'count="\d+" uniqueCount="\d+"'), 'count="$refs" uniqueCount="${_shared.length}"');
  sstFile.writeAsStringSync(newSst);

  // Re-zip avec des chemins à barres obliques (Compress-Archive de PowerShell 5 met des \).
  if (File(_dst).existsSync()) File(_dst).deleteSync();
  final ps = '''
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
\$root = '${work.path}'
\$zip = [System.IO.Compression.ZipFile]::Open('$_dst', 'Create')
Get-ChildItem -Path \$root -Recurse -File | ForEach-Object {
  \$rel = \$_.FullName.Substring(\$root.Length + 1).Replace('\\', '/')
  [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(\$zip, \$_.FullName, \$rel)
}
\$zip.Dispose()
''';
  r = Process.runSync('powershell', ['-NoProfile', '-Command', ps]);
  if (r.exitCode != 0) throw Exception(r.stderr);
  print('Écrit : $_dst (${ordered.length} lignes, ${_shared.length - originalShared} nouveaux textes, LIMITE en ligne $newLimitRowNumber)');
}
