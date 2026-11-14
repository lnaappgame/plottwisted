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

  // Signalé le 13/11/2026 après la 1.0.13 (Marie, Sybil) : « en arrivant à
  // la fin des mondes de la version précédente, quand on télécharge la mise
  // à jour, on se refait le dernier monde ». Avec la réserve, le dernier
  // monde joué n'est souvent pas le 30 : l'ancien calcul partait de lui.
  group('nouveaux mondes après une fin de contenu atteinte par la réserve', () {
    List<int> upTo(int n) => [for (var i = 1; i <= n; i++) i];

    Future<GameState> restored(Map<String, dynamic> overrides) async {
      final saveService = SaveService();
      await saveService.save(_game(saveService).toJson()..addAll(overrides));
      final game = _game(saveService);
      await game.restore();
      return game;
    }

    Map<String, dynamic> finished30({required int lastPlayed}) => {
          'worldIndex': lastPlayed,
          'currentLevelNumber': 10,
          'remainingLevels': <int>[],
          'worldsPlayedHistory': upTo(30),
          'allWorldsCompleted': true,
          'allWorldsCompletedAtMax': 30,
          'worldChoicesExhausted': true,
          'worldChoiceReserve': null,
          'gameStarted': true,
        };

    for (final lastPlayed in [29, 28, 25]) {
      test('fini sur le monde $lastPlayed (30 déjà fait) : on propose 31 et 32, pas un monde fini', () async {
        final game = await restored(finished30(lastPlayed: lastPlayed));
        expect(game.shouldShowComingSoonPage, isFalse);
        expect(game.worldChoiceOptions, [31, 32]);
      });
    }

    test('le choix suivant continue après les nouveaux mondes', () async {
      final game = await restored(finished30(lastPlayed: 29));
      game.chooseNextWorld(31);
      expect(game.worldIndex, 31);
      expect(game.worldChoiceReserve, 32);
      expect(game.allWorldsCompleted, isFalse, reason: 'plus de « tout fini » périmé');
      expect(game.worldChoiceOptions, [32, 33]); // fin du monde 31
    });

    test('mise à jour reçue PENDANT le dernier monde : les nouveaux mondes sont proposés à sa fin', () async {
      final game = await restored({
        'worldIndex': 28,
        'currentLevelNumber': 10,
        'remainingLevels': [10],
        'worldsPlayedHistory': upTo(30),
        'allWorldsCompleted': false,
        'worldChoicesExhausted': true,
        'worldChoiceReserve': null,
        'gameStarted': true,
      });
      final status = game.advanceAfterSolve();
      expect(status, startsWith('world-choice'), reason: 'et non « tout le contenu est fini »');
      expect(game.shouldShowComingSoonPage, isFalse);
      expect(game.worldChoiceOptions, [31, 32]);
    });

    test('une joueuse déjà en train de rejouer le monde 30 revient au choix 31 / 32', () async {
      // État laissé par l'ancien calcul : [30, 31] proposés, 30 choisi.
      final game = await restored({
        'worldIndex': 30,
        'currentLevelNumber': 3,
        'remainingLevels': [3, 4, 5, 6, 7, 8, 9, 10],
        'worldsPlayedHistory': upTo(30),
        'allWorldsCompleted': true,
        'allWorldsCompletedAtMax': 30,
        'worldChoicesExhausted': false,
        'worldChoiceReserve': 31,
        'worldChoiceFrontier': 32,
        'solvedPending': '30-3',
        'gameStarted': true,
      });
      expect(game.remainingLevels, isEmpty);
      expect(game.hasPendingSolve, isFalse);
      expect(game.worldChoiceOptions, [31, 32]);
    });

    test('une joueuse bloquée sur « prochainement » sans avoir vu 31-35 revient au choix', () async {
      final game = await restored({
        ...finished30(lastPlayed: 28),
        'allWorldsCompletedAtMax': 35, // l'ancien calcul l'a déclarée au bout
      });
      expect(game.shouldShowComingSoonPage, isFalse);
      expect(game.worldChoiceOptions, [31, 32]);
    });

    test('une joueuse déjà dans un nouveau monde n\'est pas touchée', () async {
      final game = await restored({
        'worldIndex': 31,
        'currentLevelNumber': 5,
        'remainingLevels': [5, 6, 7, 8, 9, 10],
        'worldsPlayedHistory': [...upTo(30), 31],
        'allWorldsCompleted': true, // indicateur périmé de la fin des 30 mondes
        'allWorldsCompletedAtMax': 30,
        'worldChoicesExhausted': false,
        'worldChoiceReserve': 32,
        'worldChoiceFrontier': 33,
        'gameStarted': true,
      });
      expect(game.worldIndex, 31);
      expect(game.remainingLevels, [5, 6, 7, 8, 9, 10]);
    });

    test('une sauvegarde venue d\'une version plus récente ne fait pas croire au bout du jeu', () async {
      final game = await restored({
        'worldIndex': 1,
        'currentLevelNumber': 10,
        'remainingLevels': <int>[],
        'worldsPlayedHistory': [1, 38, 39], // mondes d'une version à venir
        'worldChoiceReserve': null,
        'gameStarted': true,
      });
      expect(game.worldChoiceOptions, [2, 3]);
    });

    test('tout le contenu vraiment fini : toujours la page « prochainement »', () async {
      final game = await restored({
        'worldIndex': 34,
        'currentLevelNumber': 10,
        'remainingLevels': <int>[],
        'worldsPlayedHistory': upTo(35),
        'allWorldsCompleted': true,
        'allWorldsCompletedAtMax': 35,
        'worldChoicesExhausted': true,
        'worldChoiceReserve': null,
        'gameStarted': true,
      });
      expect(game.shouldShowComingSoonPage, isTrue);
      expect(game.worldChoiceOptions, isEmpty);
    });
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
