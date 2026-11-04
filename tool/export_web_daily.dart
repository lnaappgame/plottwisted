// Exporte les énigmes du jeu principal pour « L'énigme du jour » web
// (docs/jouer/index.html, servie par GitHub Pages) : un JSON bilingue avec
// l'ordre quotidien, les noms affichés dans leur couleur de départ, les
// indices progressifs et les explications de la révélation.
//
// Usage : dart run tool/export_web_daily.dart
// Périmètre : mondes 1 à 30, positions 1 à 9 (pas le tutoriel, pas le
// niveau « extrême »). L'ordre est mélangé avec une graine fixe, donc stable
// d'une régénération à l'autre tant que la liste ne change pas ; le jour 0
// est le 5 novembre 2026 et commence par Shutter Island, l'énigme qu'on
// cite partout en exemple.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../lib/data/puzzles_data.dart';
import '../lib/models/puzzle.dart';

const _epoch = '2026-11-05';

String _colorName(NameColor c) => c.name;

List<String> _revealLines(Puzzle p, String l) {
  final out = <String>[];
  for (final (ref, color) in [(p.p1, p.p1InitialColor), if (p.hasP2) (p.p2, p.p2InitialColor)]) {
    final real = ref.realFor(l), actor = ref.actorFor(l);
    final fr = l == 'fr';
    switch (color) {
      case NameColor.green:
        out.add(fr ? '$real : joué par $actor.' : '$real: played by $actor.');
      case NameColor.blue:
        out.add(fr ? '$actor joue $real.' : '$actor plays $real.');
      case NameColor.red:
        // Le film d'origine n'est pas toujours renseigné (le nom rouge est
        // parfois déjà un titre de film) : pas de parenthèses vides.
        final film = ref.decoyFilmFor(l);
        final src = film.isEmpty ? '' : ' ($film)';
        out.add(fr
            ? '${ref.decoyFor(l)}, c\'est $actor$src, qui joue ici $real.'
            : '${ref.decoyFor(l)} is $actor$src, who plays $real here.');
      case NameColor.orange:
        final film = ref.sameRoleFilmFor(l);
        final src = film.isEmpty ? '' : ' ($film)';
        out.add(fr
            ? '${ref.sameRoleActorFor(l)} a aussi incarné $real$src ; ici, c\'est $actor.'
            : '${ref.sameRoleActorFor(l)} also played $real$src; here it\'s $actor.');
      case NameColor.violet:
        out.add(fr
            ? '« ${ref.violetFor(l)} » désigne $real, joué par $actor.'
            : '“${ref.violetFor(l)}” refers to $real, played by $actor.');
    }
  }
  return out;
}

Map<String, dynamic> _locale(Puzzle p, GameWorld w, String l) => {
      'title': p.titleFor(l),
      'pitch': p.pitchTemplateFor(l),
      'p1': p.p1.displayFor(p.p1InitialColor, l),
      if (p.hasP2) 'p2': p.p2.displayFor(p.p2InitialColor, l),
      'hint': p.extraHintFor(l),
      'note': p.revealNoteFor(l),
      'actors': [p.p1.actorFor(l), if (p.hasP2) p.p2.actorFor(l)],
      'category': w.categoryLabelFor(l),
      'reveal': _revealLines(p, l),
      'link': p.linkUrlFor(l),
    };

void main() {
  final puzzles = <Map<String, dynamic>>[];
  for (final w in kWorlds) {
    if (w.number < 1 || w.number > 30) continue;
    for (var i = 0; i < w.puzzles.length && i < 9; i++) {
      final p = w.puzzles[i];
      puzzles.add({
        'id': 'w${w.number}-${i + 1}',
        'year': p.year,
        'c1': _colorName(p.p1InitialColor),
        if (p.hasP2) 'c2': _colorName(p.p2InitialColor),
        'fr': _locale(p, w, 'fr'),
        'en': _locale(p, w, 'en'),
      });
    }
  }

  final order = List<int>.generate(puzzles.length, (i) => i)..shuffle(Random(20261105));
  final first = puzzles.indexWhere((p) => (p['fr']['title'] as String).toUpperCase() == 'SHUTTER ISLAND');
  if (first >= 0) {
    order.remove(first);
    order.insert(0, first);
  }

  final out = {
    'generatedAt': DateTime.now().toUtc().toIso8601String().substring(0, 10),
    'epoch': _epoch,
    'order': order,
    'puzzles': puzzles,
  };
  final file = File('docs/jouer/enigmes.json')..createSync(recursive: true);
  file.writeAsStringSync(jsonEncode(out));
  stdout.writeln('${puzzles.length} énigmes, jour 0 = ${puzzles[order[0]]['fr']['title']} → ${file.path} (${file.lengthSync() ~/ 1024} Ko)');
}
