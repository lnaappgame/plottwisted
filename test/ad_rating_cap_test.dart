// Plafond de classification des annonces (1.0.16) : « T » (Ado), appliqué
// avant l'initialisation du SDK et avant toute requête, comme dans les autres
// jeux du studio. Sans plafond en place, aucune pub n'est demandée.
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cine_devinette/services/ad_service.dart';

class _CountingAdService extends AdService {
  _CountingAdService({super.applyRequestConfiguration, super.initializeSdk});

  int prepareCalls = 0;

  @override
  void prepareForcedAd() {
    prepareCalls++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('plafond « T » appliqué avant l\'initialisation du SDK, puis les pubs partent', () async {
    final calls = <String>[];
    RequestConfiguration? applied;
    final ads = _CountingAdService(
      applyRequestConfiguration: (c) async {
        applied = c;
        calls.add('plafond');
      },
      initializeSdk: () async => calls.add('sdk'),
    );

    expect(await ads.prepareSdk(), isTrue);
    expect(calls, ['plafond', 'sdk']);
    expect(applied!.maxAdContentRating, MaxAdContentRating.t);

    ads.enableAds();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(ads.prepareCalls, 1, reason: 'préchargement après le plafond');
  });

  test('plafond impossible à poser : SDK non initialisé, aucune pub demandée', () async {
    var sdk = 0;
    final ads = _CountingAdService(
      applyRequestConfiguration: (_) async => throw StateError('canal indisponible'),
      initializeSdk: () async => sdk++,
    );

    expect(await ads.prepareSdk(), isFalse);
    expect(sdk, 0);

    // Même si l'appelant activait les pubs quand même : rien ne part.
    ads.enableAds();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(ads.prepareCalls, 0);
  });

  test('sans prepareSdk, enableAds ne demande rien', () async {
    final ads = _CountingAdService(
      applyRequestConfiguration: (_) async {},
      initializeSdk: () async {},
    );
    ads.enableAds();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(ads.prepareCalls, 0);
  });

  test('la configuration demandée est bien le plafond « T »', () {
    expect(AdService.requestConfiguration.maxAdContentRating, MaxAdContentRating.t);
  });
}
