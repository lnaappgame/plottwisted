// Insère dans lib/data/puzzles_data.dart les mondes préparés hors de lib/
// (notes/maj-nouveaux-mondes/mondes-maj.dart.txt), entre deux repères, à la
// fin de kWorlds. Relançable : la section précédente est remplacée.
//
//   dart run tool/insert_new_worlds.dart [bloc] [premier numéro]
//
// Outil de dev, jamais utilisé par l'app. Tant que le classeur de la base
// n'a pas reçu ces mondes, ne pas relancer tool/regenerate_from_xlsx.dart :
// il les effacerait.

import 'dart:io';

const _begin = '  // >>> MAJ nouveaux mondes (tool/insert_new_worlds.dart) — ne pas modifier à la main';
const _end = '  // <<< MAJ nouveaux mondes';

void main(List<String> args) {
  final blockPath = args.isNotEmpty ? args[0] : 'notes/maj-nouveaux-mondes/mondes-maj.dart.txt';
  var next = args.length > 1 ? int.parse(args[1]) : 31;

  final blockLines = File(blockPath).readAsStringSync().replaceAll('\r\n', '\n').split('\n');
  final out = <String>[];
  var worlds = 0;
  for (var line in blockLines) {
    if (out.isEmpty && (line.trim().isEmpty || line.trimLeft().startsWith('//'))) continue; // en-tête du bloc
    if (line.trimLeft().startsWith('GameWorld(number:')) {
      line = line.replaceFirst(RegExp(r'number: \d+'), 'number: ${next++}');
      // La règle « film + enfant star » ne tient pas dans le nom du monde
      // (libellés affichés en gros) : nom court + libellé de la réponse bonus.
      if (line.contains('Enfants stars')) {
        line = line.replaceFirst(
          RegExp(r"categoryLabel: '.*?', categoryLabelUs: '.*?', puzzles: \["),
          "categoryLabel: 'Enfants stars', categoryLabelUs: 'Child Stars', "
              "extraLabel: 'l\\'enfant star', extraLabelUs: 'the child star', puzzles: [",
        );
        if (!line.contains('extraLabel:')) throw 'ligne du monde Enfants stars non reconnue : $line';
      }
      worlds++;
    }
    out.add(line);
  }
  while (out.isNotEmpty && out.last.trim().isEmpty) {
    out.removeLast();
  }
  if (worlds == 0) throw 'aucun GameWorld dans $blockPath';

  final dataFile = File('lib/data/puzzles_data.dart');
  final original = dataFile.readAsStringSync();
  final eol = original.contains('\r\n') ? '\r\n' : '\n';
  var data = original.replaceAll('\r\n', '\n');

  final b = data.indexOf(_begin);
  if (b != -1) {
    final e = data.indexOf(_end, b);
    if (e == -1) throw 'repère de fin introuvable';
    data = data.substring(0, b) + data.substring(e + _end.length + 1);
  }
  final close = data.lastIndexOf('\n];');
  if (close == -1) throw 'fin de kWorlds introuvable';
  final section = '$_begin\n${out.join('\n')}\n$_end\n';
  data = '${data.substring(0, close + 1)}$section${data.substring(close + 1)}';

  dataFile.writeAsStringSync(data.replaceAll('\n', eol));
  stdout.writeln('$worlds mondes insérés (numéros ${next - worlds} à ${next - 1}) depuis $blockPath');
}
