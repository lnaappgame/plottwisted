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

  test('la V1 compte 25 mondes de 10 niveaux, numérotés sans trou', () {
    expect([for (final w in kWorlds) w.number], [for (var n = 1; n <= 25; n++) n]);
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
}
