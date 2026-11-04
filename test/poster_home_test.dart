import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cine_devinette/l10n/app_localizations.dart';
import 'package:cine_devinette/screens/home_screen.dart';
import 'package:cine_devinette/services/ad_service.dart';
import 'package:cine_devinette/services/app_settings.dart';
import 'package:cine_devinette/services/game_state.dart';
import 'package:cine_devinette/services/save_service.dart';
import 'package:cine_devinette/services/streak_state.dart';

Future<void> _pumpHome(WidgetTester tester, {required bool poster, required String locale, required Size size}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final saveService = SaveService();
  final settings = AppSettings(saveService: saveService)
    ..posterHome = poster
    ..locale = locale;
  // Après l'event Halloween : son bouton (texte long avec la police des
  // tests) n'est pas l'objet de ces tests.
  final game = GameState(adService: AdService(), saveService: saveService, settings: settings)
    ..clock = () => DateTime(2026, 11, 20);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: StreakState(saveService: saveService)),
        ChangeNotifierProvider.value(value: game),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale(locale),
        home: HomeScreen(onPlay: () {}),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  // 320x568 : plus petit iPhone encore pris en charge ; 360x640 : le petit
  // Android qui débordait avant ; 412x915 : un grand Android courant.
  const sizes = [Size(320, 568), Size(360, 640), Size(412, 915)];

  for (final size in sizes) {
    for (final locale in ['fr', 'en']) {
      testWidgets('accueil jaune sans débordement en ${size.width.toInt()}x${size.height.toInt()} ($locale)',
          (tester) async {
        await _pumpHome(tester, poster: true, locale: locale, size: size);
        expect(tester.takeException(), isNull);
        expect(find.text(locale == 'fr' ? 'SHERLOCK HOLMES ?' : 'SHERLOCK HOLMES?'), findsOneWidget);
      });
    }
  }

  testWidgets("accueil d'origine : pas de bandeau de pellicule", (tester) async {
    await _pumpHome(tester, poster: false, locale: 'fr', size: const Size(412, 915));
    expect(tester.takeException(), isNull);
    expect(find.text('SHERLOCK HOLMES ?'), findsNothing);
  });
}
