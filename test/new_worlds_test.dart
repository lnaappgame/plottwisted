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

  test('le jeu compte 30 mondes de 10 niveaux, numérotés sans trou', () {
    expect([for (final w in kWorlds) w.number], [for (var n = 1; n <= 30; n++) n]);
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
