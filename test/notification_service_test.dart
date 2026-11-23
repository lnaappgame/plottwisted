import 'package:flutter_test/flutter_test.dart';

import 'package:cine_devinette/services/notification_service.dart';

void main() {
  group('prochaineOccurrenceLocale (rappel quotidien de 18 h)', () {
    test('avant 18 h : aujourd\'hui à 18 h', () {
      final now = DateTime(2026, 11, 23, 9, 30);
      expect(NotificationService.prochaineOccurrenceLocale(now, heure: 18), DateTime(2026, 11, 23, 18));
    });

    test('après 18 h : demain à 18 h', () {
      final now = DateTime(2026, 11, 23, 19);
      expect(NotificationService.prochaineOccurrenceLocale(now, heure: 18), DateTime(2026, 11, 24, 18));
    });

    test('défi déjà fait le matin : jamais aujourd\'hui, demain à 18 h', () {
      final now = DateTime(2026, 11, 23, 9, 30);
      expect(NotificationService.prochaineOccurrenceLocale(now, heure: 18, apresAujourdhui: true), DateTime(2026, 11, 24, 18));
    });

    test('défi fait après 18 h : demain à 18 h aussi (pas après-demain)', () {
      final now = DateTime(2026, 11, 23, 21);
      expect(NotificationService.prochaineOccurrenceLocale(now, heure: 18, apresAujourdhui: true), DateTime(2026, 11, 24, 18));
    });

    test('rappel hebdomadaire : le prochain lundi à 9 h, inchangé par apresAujourdhui', () {
      final now = DateTime(2026, 11, 23, 12); // un lundi, midi
      expect(NotificationService.prochaineOccurrenceLocale(now, heure: 9, jourSemaine: DateTime.monday), DateTime(2026, 11, 30, 9));
      expect(NotificationService.prochaineOccurrenceLocale(now, heure: 9, jourSemaine: DateTime.monday, apresAujourdhui: true),
          DateTime(2026, 11, 30, 9));
    });
  });
}
