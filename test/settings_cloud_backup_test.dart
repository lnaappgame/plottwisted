import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cine_devinette/l10n/app_localizations.dart';
import 'package:cine_devinette/screens/settings_screen.dart';
import 'package:cine_devinette/services/ad_service.dart';
import 'package:cine_devinette/services/app_settings.dart';
import 'package:cine_devinette/services/cloud_sync_service.dart';
import 'package:cine_devinette/services/game_state.dart';
import 'package:cine_devinette/services/save_service.dart';

Future<void> _pump(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(400, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final saveService = SaveService();
  final settings = AppSettings(saveService: saveService);
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: settings),
      ChangeNotifierProvider.value(
          value: GameState(adService: AdService(), saveService: saveService, settings: settings)),
      Provider.value(value: saveService),
      Provider.value(value: CloudSyncService()),
    ],
    child: MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: SettingsScreen()),
    ),
  ));
  await tester.pump();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Android : la sauvegarde Google est proposée', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await _pump(tester);
    expect(find.text('🔗 Sauvegarder avec Google'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('iPhone : pas de connexion Google (règle 4.8 d\'Apple)', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await _pump(tester);
    expect(find.text('🔗 Sauvegarder avec Google'), findsNothing);
    expect(find.textContaining('Google'), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });
}
