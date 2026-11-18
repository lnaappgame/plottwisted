// Exporte les films du test web de Plot Twisted v2bis (docs/v2/films.json).
//
// Fusionne la base du jeu (pitch, noms piégés, couleurs de départ, indice,
// liens) et le contenu ajouté pour le test
// (notes/refonte-pt2/contenu-test-v2bis.json : faux titres, anecdotes, vrai ou
// faux, question bonus). Français seulement : le test vise les testeurs FR.
//
// Usage : dart run tool/export_test_v2.dart

import 'dart:convert';
import 'dart:io';

import '../lib/data/puzzles_data.dart';
import '../lib/models/puzzle.dart';

const _contenu = 'notes/refonte-pt2/contenu-test-v2bis.json';
const _sortie = 'docs/v2/films.json';

const _accents = {
  'à': 'a', 'â': 'a', 'ä': 'a', 'ç': 'c', 'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
  'î': 'i', 'ï': 'i', 'ô': 'o', 'ö': 'o', 'ù': 'u', 'û': 'u', 'ü': 'u', 'œ': 'oe',
};

String _slug(String s) {
  var t = s.toLowerCase();
  _accents.forEach((a, b) => t = t.replaceAll(a, b));
  return t.replaceAll(RegExp('[^a-z0-9]'), '');
}

/// Apostrophes typographiques dans tout ce qui s'affiche.
String _typo(String s) => s.replaceAll("'", '’').trim();

Map<String, dynamic> _personne(String titre, PersonRef r, NameColor c, String? origine) {
  final affiche = r.displayFor(c);
  if (affiche.isEmpty) {
    throw StateError('$titre : couleur de départ ${c.name} sans nom à afficher (${r.real}).');
  }
  return {
    'c': c.name,
    if (r.decoy.isNotEmpty) 'decoy': _typo(r.decoy),
    if (r.sameRoleActor.isNotEmpty) 'other': _typo(r.sameRoleActor),
    if (r.violet.isNotEmpty) 'violet': _typo(r.violet),
    'actor': _typo(r.actor),
    'real': _typo(r.real),
    if (origine != null) 'df': origine,
  };
}

void main() {
  final contenu = jsonDecode(File(_contenu).readAsStringSync()) as Map<String, dynamic>;
  final ajouts = contenu['films'] as Map<String, dynamic>;
  final salles = <Map<String, dynamic>>[];
  final films = <String, dynamic>{};

  for (final s in (contenu['salles'] as List).cast<Map<String, dynamic>>()) {
    final monde = kWorlds.firstWhere((w) => w.number == s['monde']);
    final ids = <String, List<String>>{'s1': [], 's2': []};
    for (final cle in ['s1', 's2']) {
      for (final titre in (s[cle] as List).cast<String>()) {
        final p = monde.puzzles.firstWhere((x) => x.title == titre,
            orElse: () => throw StateError('$titre introuvable dans le monde ${monde.number}.'));
        if (!p.hasP2) throw StateError('$titre : un seul personnage, non prévu par le test.');
        final a = ajouts[titre] as Map<String, dynamic>? ?? (throw StateError('$titre : pas de contenu ajouté.'));
        final df = (a['df'] as Map<String, dynamic>?) ?? const {};
        final id = _slug(titre);
        if (films.containsKey(id)) throw StateError('Identifiant en double : $id');
        films[id] = {
          't': a['t'],
          'y': int.parse(p.year),
          's': s['id'],
          if (a['al'] != null) 'al': a['al'],
          'pitch': _typo(p.pitchTemplate),
          'p1': _personne(titre, p.p1, p.p1InitialColor, df['p1'] as String?),
          'p2': _personne(titre, p.p2, p.p2InitialColor, df['p2'] as String?),
          'hint': _typo(p.extraHint),
          'tag': a['tag'],
          'fact': a['fact'],
          if (a['vf'] != null) 'vf': a['vf'],
          'faux': a['faux'],
          if (a['bonus'] != null) 'bonus': a['bonus'],
          if (p.allocineUrl.isNotEmpty) 'allocine': p.allocineUrl,
        };
        ids[cle]!.add(id);
      }
    }
    salles.add({'id': s['id'], 'nom': s['nom'], 's1': ids['s1'], 's2': ids['s2']});
  }

  // La question bonus porte sur un nom rouge : on le vérifie ici plutôt que dans la page.
  films.forEach((id, f) {
    final b = (f as Map<String, dynamic>)['bonus'] as Map<String, dynamic>?;
    if (b == null) return;
    final p = f[b['k']] as Map<String, dynamic>;
    if (p['c'] != 'red') throw StateError('$id : question bonus sur un nom qui n\'est pas rouge.');
  });

  final sortie = File(_sortie)..createSync(recursive: true);
  sortie.writeAsStringSync(jsonEncode({
    'generatedAt': DateTime.now().toIso8601String().substring(0, 10),
    'salles': salles,
    'films': films,
  }));
  final couleurs = <String, int>{};
  for (final f in films.values) {
    for (final k in ['p1', 'p2']) {
      final c = ((f as Map)[k] as Map)['c'] as String;
      couleurs[c] = (couleurs[c] ?? 0) + 1;
    }
  }
  print('${films.length} films, ${salles.length} salles → $_sortie (${sortie.lengthSync()} octets)');
  print('Couleurs de départ : $couleurs');
}
