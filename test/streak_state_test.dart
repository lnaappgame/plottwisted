import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cine_devinette/services/save_service.dart';
import 'package:cine_devinette/services/streak_state.dart';

StreakState _state() => StreakState(saveService: SaveService());

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  test('première action démarre la série à 1', () {
    final state = _state();
    state.recordAction();
    expect(state.currentStreak, 1);
  });

  test('une deuxième action le même jour ne change rien', () {
    final state = _state();
    state.recordAction();
    state.recordAction();
    expect(state.currentStreak, 1);
  });

  test('une action le jour suivant incrémente la série', () {
    final state = _state();
    state.lastActionDay = DateTime.now().toUtc().subtract(const Duration(days: 1));
    state.currentStreak = 4;
    state.recordAction();
    expect(state.currentStreak, 5);
  });

  test('un jour sauté réinitialise la série à 1', () {
    final state = _state();
    state.lastActionDay = DateTime.now().toUtc().subtract(const Duration(days: 3));
    state.currentStreak = 10;
    state.recordAction();
    expect(state.currentStreak, 1);
  });

  test('onDayCounted reçoit la série une seule fois par jour (calendrier retiré, compteur conservé)', () {
    final state = _state();
    final comptes = <int>[];
    state.onDayCounted = comptes.add;

    state.recordAction(); // jour 1
    state.recordAction(); // même jour : rien
    for (var jour = 2; jour <= 3; jour++) {
      state.lastActionDay = DateTime.now().toUtc().subtract(const Duration(days: 1));
      state.recordAction();
    }

    expect(comptes, [1, 2, 3]);
    expect(state.currentStreak, 3);
  });

  test('toJson()/restore() conservent la série', () async {
    final state = _state();
    state.recordAction();
    final json = state.toJson();

    final restored = _state();
    restored.currentStreak = json['currentStreak'] as int;
    restored.lastActionDay = DateTime.parse(json['lastActionDay'] as String);

    expect(restored.currentStreak, state.currentStreak);
    expect(restored.lastActionDay, state.lastActionDay);
  });
}
