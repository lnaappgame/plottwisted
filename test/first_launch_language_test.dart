// Langue détectée au tout premier lancement (1.0.16) : fr* = français, toute
// autre langue = anglais ; enregistrée comme un choix du joueur ; un joueur
// existant garde sa langue.
import 'package:cine_devinette/services/app_settings.dart';
import 'package:cine_devinette/services/save_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _fresh(String lang) {
  final s = AppSettings(saveService: SaveService());
  s.beginOnboarding(deviceLanguage: lang);
  return s.locale;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('fr_FR et fr_CA : français', () {
    expect(_fresh('fr'), 'fr');
    expect(AppSettings.localeForDeviceLanguage('fr_FR'), 'fr');
    expect(AppSettings.localeForDeviceLanguage('fr_CA'), 'fr');
    expect(AppSettings.localeForDeviceLanguage('fr-CA'), 'fr');
  });

  test('en_US et de_DE : anglais', () {
    expect(_fresh('en'), 'en');
    expect(_fresh('de'), 'en');
    expect(AppSettings.localeForDeviceLanguage('en_US'), 'en');
    expect(AppSettings.localeForDeviceLanguage('de_DE'), 'en');
  });

  test('la langue détectée est enregistrée et reste changeable', () async {
    final save = SaveService();
    AppSettings(saveService: save).beginOnboarding(deviceLanguage: 'de');
    await Future<void>.delayed(Duration.zero);
    final again = AppSettings(saveService: save);
    await again.restore();
    expect(again.locale, 'en');
    again.locale = 'fr';
    expect(again.locale, 'fr');
  });

  test('joueur existant : sa langue ne bouge pas, pas de premier lancement', () async {
    SharedPreferences.setMockInitialValues({'cine_devinette_settings_v1': '{"locale":"fr"}'});
    final save = SaveService();
    final fresh = await save.loadSettings() == null; // comme main()
    final s = AppSettings(saveService: save);
    await s.restore();
    if (fresh) s.beginOnboarding(deviceLanguage: 'de');
    expect(fresh, isFalse);
    expect(s.locale, 'fr');
    expect(s.onboardingActive, isFalse);
  });
}
