import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cine_devinette/services/app_settings.dart';
import 'package:cine_devinette/services/save_service.dart';

AppSettings _settings() => AppSettings(saveService: SaveService());

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  test('playerId généré par défaut est unique-ish (jamais le même pour deux instances)', () {
    // Pas une vraie garantie d'unicité (6 chiffres), mais vérifie au moins
    // que ce n'est plus le "#000001" figé d'origine.
    final a = _settings();
    expect(a.playerId, isNot('#000001'));
    expect(a.playerId, matches(RegExp(r'^#\d{6}$')));
  });

  group('setPlayerId()', () {
    test('accepte un pseudo personnalisé', () {
      final settings = _settings();
      settings.setPlayerId('DimitriDu92');
      expect(settings.playerId, 'DimitriDu92');
    });

    test('rogne les espaces', () {
      final settings = _settings();
      settings.setPlayerId('  Zaz  ');
      expect(settings.playerId, 'Zaz');
    });

    test('ignore une valeur vide (ou seulement des espaces) — garde l\'ancien identifiant', () {
      final settings = _settings();
      final avant = settings.playerId;
      settings.setPlayerId('   ');
      expect(settings.playerId, avant);
    });

    test('tronque au-delà de kPlayerIdMaxLength caractères', () {
      final settings = _settings();
      settings.setPlayerId('X' * (kPlayerIdMaxLength + 10));
      expect(settings.playerId.length, kPlayerIdMaxLength);
    });
  });

  group('consumeReviewRequestPending()', () {
    test('true la première fois, false ensuite', () {
      final settings = _settings();
      expect(settings.consumeReviewRequestPending(), isTrue);
      expect(settings.consumeReviewRequestPending(), isFalse);
      expect(settings.consumeReviewRequestPending(), isFalse);
    });

    test('reste consommé après un cycle toJson()/restore()', () async {
      final settings = _settings();
      settings.consumeReviewRequestPending();

      final restored = _settings();
      final json = settings.toJson();
      restored.reviewRequested = json['reviewRequested'] as bool;

      expect(restored.consumeReviewRequestPending(), isFalse);
    });
  });

  group('firstLaunchDay', () {
    test('vaut aujourd\'hui (UTC) par défaut, pour une toute nouvelle installation', () {
      final settings = _settings();
      final aujourdhui = DateTime.now().toUtc();
      expect(settings.firstLaunchDay.year, aujourdhui.year);
      expect(settings.firstLaunchDay.month, aujourdhui.month);
      expect(settings.firstLaunchDay.day, aujourdhui.day);
    });

    test('conserve la vraie date d\'origine après un cycle toJson()/restore(), '
        'plutôt que de la réinitialiser à "aujourd\'hui" à chaque lancement', () async {
      final settings = _settings();
      settings.firstLaunchDay = DateTime.utc(2026, 1, 15);
      final json = settings.toJson();

      final restored = _settings(); // son propre champ par défaut vaut "aujourd'hui"
      restored.firstLaunchDay = DateTime.tryParse(json['firstLaunchDay'] as String)!;

      expect(restored.firstLaunchDay, DateTime.utc(2026, 1, 15));
    });
  });
}
