import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cine_devinette/data/puzzles_data.dart';
import 'package:cine_devinette/services/ad_service.dart';
import 'package:cine_devinette/services/app_settings.dart';
import 'package:cine_devinette/services/game_state.dart';
import 'package:cine_devinette/services/save_service.dart';

GameState _game(SaveService saveService) {
  final settings = AppSettings(saveService: saveService);
  return GameState(adService: AdService(), saveService: saveService, settings: settings);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('le jeu compte 35 mondes de 10 niveaux, numérotés sans trou', () {
    expect([for (final w in kWorlds) w.number], [for (var n = 1; n <= 35; n++) n]);
    for (final w in kWorlds) {
      expect(w.puzzles, hasLength(10), reason: 'monde ${w.number}');
    }
  });

  test('un joueur qui avait fini les 20 mondes se voit proposer les nouveaux', () async {
    final saveService = SaveService();
    final seed = _game(saveService)..enterWorld(20);
    final save = seed.toJson()
      ..['remainingLevels'] = <int>[]
      ..['allWorldsCompleted'] = true
      ..['allWorldsCompletedAtMax'] = 20
      ..['worldChoicesExhausted'] = true
      ..['worldChoiceReserve'] = null;
    await saveService.save(save);

    final game = _game(saveService);
    await game.restore();
    expect(game.shouldShowComingSoonPage, isFalse);
    expect(game.worldChoiceOptions, [21, 22]);
  });

  test('un joueur qui avait fini les 25 mondes se voit proposer les mondes 26 et 27', () async {
    final saveService = SaveService();
    final seed = _game(saveService)..enterWorld(25);
    final save = seed.toJson()
      ..['remainingLevels'] = <int>[]
      ..['allWorldsCompleted'] = true
      ..['allWorldsCompletedAtMax'] = 25
      ..['worldChoicesExhausted'] = true
      ..['worldChoiceReserve'] = null;
    await saveService.save(save);

    final game = _game(saveService);
    await game.restore();
    expect(game.shouldShowComingSoonPage, isFalse);
    expect(game.worldChoiceOptions, [26, 27]);
  });

  test('un joueur qui avait fini les 30 mondes se voit proposer les mondes 31 et 32', () async {
    final saveService = SaveService();
    final seed = _game(saveService)..enterWorld(30);
    final save = seed.toJson()
      ..['remainingLevels'] = <int>[]
      ..['allWorldsCompleted'] = true
      ..['allWorldsCompletedAtMax'] = 30
      ..['worldChoicesExhausted'] = true
      ..['worldChoiceReserve'] = null;
    await saveService.save(save);

    final game = _game(saveService);
    await game.restore();
    expect(game.shouldShowComingSoonPage, isFalse);
    expect(game.worldChoiceOptions, [31, 32]);
  });

  test('les 5 mondes de la 1.0.13 : aucun film déjà en jeu, tous les champs FR et US remplis', () {
    String norm(String s) => normalize(s).replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final before = <String, String>{};
    for (final w in kWorlds.where((w) => w.number <= 30)) {
      for (final p in w.puzzles) {
        before[norm(p.title)] = '${w.number} ${p.title}';
        before[norm(p.titleUs)] = '${w.number} ${p.titleUs}';
      }
    }
    final seen = <String>{};
    for (final w in kWorlds.where((w) => w.number > 30)) {
      expect(w.categoryLabel, isNotEmpty);
      expect(w.categoryLabelUs, isNotEmpty);
      for (final p in w.puzzles) {
        final where = 'monde ${w.number}, ${p.title}';
        for (final t in {norm(p.title), norm(p.titleUs)}) {
          expect(before.containsKey(t), isFalse, reason: '$where : déjà en jeu (${before[t]})');
        }
        expect(seen.add(norm(p.title)), isTrue, reason: '$where : deux fois dans la mise à jour');
        for (final field in [
          p.title, p.titleUs, p.year, p.pitchTemplate, p.pitchTemplateUs,
          p.extraHint, p.extraHintUs, p.revealNote, p.revealNoteUs, p.imdbUrl,
          p.p1.real, p.p1.realUs, p.p1.actor, p.p1.actorUs,
        ]) {
          expect(field.trim(), isNotEmpty, reason: where);
        }
        for (final (tpl, loc) in [(p.pitchTemplate, 'fr'), (p.pitchTemplateUs, 'en')]) {
          expect(tpl.contains('{p1}'), isTrue, reason: '$where ($loc) : pas de {p1}');
          // Le film peut changer d'une langue à l'autre (Gilbert Grape / The
          // Piano) : on regarde le personnage de la langue jouée.
          final hasP2 = (loc == 'en' ? p.p2.realUs : p.p2.real).isNotEmpty;
          expect(tpl.contains('{p2}'), hasP2, reason: '$where ($loc) : {p2} et p2 ne vont pas ensemble');
          // Aucun nom affiché au départ n'est vide.
          expect(p.p1.displayFor(p.p1InitialColor, loc).trim(), isNotEmpty, reason: '$where ($loc) : p1 vide');
          if (hasP2) {
            expect(p.p2.displayFor(p.p2InitialColor, loc).trim(), isNotEmpty, reason: '$where ($loc) : p2 vide');
          }
        }
      }
    }
  });

  test('aucun titre ne se dévoile par un nom vert dans son propre pitch', () {
    String norm(String s) => s.toUpperCase().replaceAll(RegExp(r"[^A-Z0-9]"), '');
    // Gardé tel quel pour la 1.0.11 (décision de Damien du 31/10/2026), à revoir plus tard.
    const tolerated = {'22-7'};
    final offenders = <String>[];
    for (final w in kWorlds) {
      for (var i = 0; i < w.puzzles.length; i++) {
        final p = w.puzzles[i];
        for (final (color, person) in [(p.p1InitialColor, p.p1), (p.p2InitialColor, p.p2)]) {
          if (color.name != 'green' || person.real.isEmpty) continue;
          final name = norm(person.real), title = norm(p.title);
          if ((name.contains(title) || title.contains(name)) && !tolerated.contains('${w.number}-${i + 1}')) {
            offenders.add('${w.number}-${i + 1} ${p.title} : « ${person.real} »');
          }
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
