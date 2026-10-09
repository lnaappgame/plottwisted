import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cine_devinette/l10n/app_localizations.dart';
import 'package:cine_devinette/screens/enigme_screen.dart';
import 'package:cine_devinette/services/ad_service.dart';
import 'package:cine_devinette/services/app_settings.dart';
import 'package:cine_devinette/services/enigme_service.dart';
import 'package:cine_devinette/services/enigme_state.dart';
import 'package:cine_devinette/services/game_state.dart';
import 'package:cine_devinette/services/leaderboard_service.dart';
import 'package:cine_devinette/services/save_service.dart';
import 'package:cine_devinette/services/streak_state.dart';
import 'package:cine_devinette/theme/app_theme.dart';

/// Classement simulé : rang 3 sur 40, score déjà enregistré.
class _FakeLeaderboard extends LeaderboardService {
  int submits = 0;
  @override
  Future<bool> submitScore({required String weekId, required int solveSeconds, required int solvedDay}) async {
    submits++;
    return true;
  }

  @override
  Future<LeaderboardResult?> fetchRank({required String weekId, required int solveSeconds}) async =>
      const LeaderboardResult(rang: 3, total: 40);
}

Future<(GameState, EnigmeState)> _pump(WidgetTester tester, {required String locale, required bool solved}) async {
  await tester.binding.setSurfaceSize(const Size(360, 740));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final saveService = SaveService();
  final settings = AppSettings(saveService: saveService)..locale = locale;
  final game = GameState(adService: AdService(), saveService: saveService, settings: settings);
  // État d'une semaine terminée : le bilan se prépare à l'ouverture de l'écran.
  final debut = enigmeWeekStart(DateTime.now()).subtract(const Duration(days: 7));
  final enigme = EnigmeState(saveService: saveService, settings: settings)
    ..currentIndex = enigmeIndexFor(debut)
    ..currentWeekStart = debut
    ..participated = true
    ..solved = solved
    ..solvedDay = solved ? 2 : null
    ..solveSeconds = solved ? 100000 : null;
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: settings),
      ChangeNotifierProvider.value(value: game),
      ChangeNotifierProvider.value(value: enigme),
      ChangeNotifierProvider(create: (_) => StreakState(saveService: saveService)),
      Provider<LeaderboardService>.value(value: _FakeLeaderboard()),
    ],
    child: MaterialApp(
      theme: buildAppTheme(isLight: false),
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const EnigmeScreen(),
    ),
  ));
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
  return (game, enigme);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('bilan trouvé (FR) : classement final, top %, jokers remis une seule fois', (tester) async {
    final (game, enigme) = await _pump(tester, locale: 'fr', solved: true);
    expect(find.text('🏆 BILAN DE LA SEMAINE'), findsOneWidget);
    expect(find.text('Félicitations ! Tu as terminé 3e sur 40 joueur(s).'), findsOneWidget);
    expect(find.text('Tu es dans le top 8 % des joueurs de la semaine.'), findsOneWidget);
    expect(find.text('JOKERS GAGNÉS'), findsOneWidget);
    // Jour 2 : 2 majeurs + 2 mineurs ; rang 3/40 = top 10 % → joker rouge.
    final total = game.revealCount + game.eliminateCount + game.characterCount + game.actorCount +
        game.hintCount + game.revealWordCount;
    expect(total, 4);
    expect(game.redJokerCount, 1);
    expect(enigme.pendingBilan, isNull);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('SUPER !'));
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('bilan trouvé (EN) : tout est traduit', (tester) async {
    await _pump(tester, locale: 'en', solved: true);
    expect(find.text("🏆 LAST WEEK'S RESULTS"), findsOneWidget);
    expect(find.text('Congratulations! You finished 3rd of 40 player(s).'), findsOneWidget);
    expect(find.text("You're in the top 8% of this week's players."), findsOneWidget);
    expect(find.text('JOKERS WON'), findsOneWidget);
    expect(find.text('AWESOME!'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('AWESOME!'));
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('bilan non trouvé (EN) : la réponse, sans jokers', (tester) async {
    final (game, _) = await _pump(tester, locale: 'en', solved: false);
    expect(find.text("You didn't solve it this time. The answer was:"), findsOneWidget);
    expect(find.text('No jokers this week… the new puzzle awaits!'), findsOneWidget);
    expect(game.revealCount + game.actorCount + game.redJokerCount, 0);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('GOT IT!'));
    await tester.pump(const Duration(seconds: 1));
  });
}
