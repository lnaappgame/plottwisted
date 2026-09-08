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

  test('les paliers 3/7/14/28 déclenchent onMilestoneReached, les autres onDailyReward', () {
    final state = _state();
    final paliersDeclenches = <int>[];
    final joursMineurs = <int>[];
    state.onMilestoneReached = paliersDeclenches.add;
    state.onDailyReward = joursMineurs.add;

    state.recordAction(); // jour 1
    for (var jour = 2; jour <= 28; jour++) {
      state.lastActionDay = DateTime.now().toUtc().subtract(const Duration(days: 1));
      state.recordAction();
    }

    expect(paliersDeclenches, [3, 7, 14, 28]);
    expect(joursMineurs, [1, 2, 4, 5, 6, 8, 9, 10, 11, 12, 13, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27]);
    expect(state.currentStreak, 28);
  });

  test('jourDuCycle boucle tous les 28 jours (jour 29 redevient jour 1)', () {
    final state = _state();
    final paliersDeclenches = <int>[];
    final joursMineurs = <int>[];
    state.onMilestoneReached = paliersDeclenches.add;
    state.onDailyReward = joursMineurs.add;

    state.currentStreak = 28;
    state.lastActionDay = DateTime.now().toUtc().subtract(const Duration(days: 1));
    state.recordAction(); // jour 29 -> jourDuCycle 1

    expect(state.currentStreak, 29);
    expect(state.jourDuCycle, 1);
    expect(joursMineurs, [1]); // jour 1 du cycle = bonus mineur, pas un palier
    expect(paliersDeclenches, isEmpty);
  });

  test('un 2e cycle redéclenche les mêmes paliers (jour 31 = jourDuCycle 3)', () {
    final state = _state();
    final paliersDeclenches = <int>[];
    state.onMilestoneReached = paliersDeclenches.add;

    state.currentStreak = 30;
    state.lastActionDay = DateTime.now().toUtc().subtract(const Duration(days: 1));
    state.recordAction(); // jour 31 -> jourDuCycle 3

    expect(state.currentStreak, 31);
    expect(state.jourDuCycle, 3);
    expect(paliersDeclenches, [3]);
  });

  test('pendingCelebration est renseigné au palier puis effacé par acknowledgeCelebration()', () {
    final state = _state();
    state.currentStreak = 2;
    state.lastActionDay = DateTime.now().toUtc().subtract(const Duration(days: 1));
    state.recordAction(); // atteint 3
    expect(state.pendingCelebration, 3);

    state.acknowledgeCelebration();
    expect(state.pendingCelebration, isNull);
  });

  group('dateForJourDuCycle() / cycleStartDay', () {
    test('null tant qu\'aucune série n\'est en cours', () {
      final state = _state();
      expect(state.cycleStartDay, isNull);
      expect(state.dateForJourDuCycle(1), isNull);
    });

    test('projette correctement les dates passées et à venir du cycle courant', () {
      final state = _state();
      // Jour réel du dernier passage = 14 mars 2027 (Oscars), 5e jour du cycle.
      state.lastActionDay = DateTime.utc(2027, 3, 14);
      state.currentStreak = 5;
      expect(state.jourDuCycle, 5);

      expect(state.cycleStartDay, DateTime.utc(2027, 3, 10)); // jour 1 du cycle
      expect(state.dateForJourDuCycle(1), DateTime.utc(2027, 3, 10));
      expect(state.dateForJourDuCycle(5), DateTime.utc(2027, 3, 14)); // == lastActionDay
      expect(state.dateForJourDuCycle(28), DateTime.utc(2027, 4, 6)); // 27 jours après le jour 1
    });
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
