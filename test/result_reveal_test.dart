import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cine_devinette/l10n/app_localizations.dart';
import 'package:cine_devinette/services/ad_service.dart';
import 'package:cine_devinette/services/app_settings.dart';
import 'package:cine_devinette/services/game_state.dart';
import 'package:cine_devinette/services/save_service.dart';
import 'package:cine_devinette/widgets/result_overlay.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('révélation : pas de « () » quand la précision du nom manque', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final saveService = SaveService();
    final settings = AppSettings(saveService: saveService);
    final game = GameState(adService: AdService(), saveService: saveService, settings: settings);
    game.enterWorld(0);
    game.currentLevelNumber = 2; // ROCKY : Apollo Creed n'a pas d'acteur renseigné
    game.loadPuzzle();
    expect(game.currentPuzzle.p2.actor, isEmpty);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: game),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: Scaffold(body: ResultOverlay(onNext: () {})),
        ),
      ),
    );
    await tester.pump();

    final pitch = find.textContaining('Apollo Creed', findRichText: true);
    expect(pitch, findsWidgets);
    final text = tester.widgetList<RichText>(pitch).map((r) => r.text.toPlainText()).join('\n');
    expect(text, isNot(contains('()')));
    expect(text, contains('Rocky Balboa (')); // les autres noms gardent leur précision
    await tester.pump(const Duration(seconds: 1));
  });
}
