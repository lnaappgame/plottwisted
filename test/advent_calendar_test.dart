import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cine_devinette/data/advent_data.dart';
import 'package:cine_devinette/l10n/app_localizations.dart';
import 'package:cine_devinette/models/joker.dart';
import 'package:cine_devinette/screens/advent_calendar_screen.dart';
import 'package:cine_devinette/screens/home_screen.dart';
import 'package:cine_devinette/services/ad_service.dart';
import 'package:cine_devinette/services/advent_calendar.dart';
import 'package:cine_devinette/services/analytics_service.dart';
import 'package:cine_devinette/services/app_settings.dart';
import 'package:cine_devinette/services/event_grid.dart';
import 'package:cine_devinette/services/game_state.dart';
import 'package:cine_devinette/services/save_service.dart';
import 'package:cine_devinette/services/sound_service.dart';
import 'package:cine_devinette/services/streak_state.dart';

/// Analytics sans Firebase : garde les cases trouvées.
class _FakeAnalytics extends AnalyticsService {
  final solvedCases = <(int, bool)>[];

  @override
  Future<void> logAdventCaseSolved({required int day, required bool onTime}) async => solvedCases.add((day, onTime));
}

/// Jeu dont l'horloge est [now] (modifiable en cours de test).
class _Clock {
  DateTime now;
  _Clock(this.now);
}

GameState _newGame(_Clock clock, {AnalyticsService? analytics}) {
  final saveService = SaveService();
  return GameState(
      adService: AdService(), saveService: saveService, settings: AppSettings(saveService: saveService), analytics: analytics)
    ..clock = () => clock.now;
}

/// Remplit les cases encore vides avec les bonnes lettres.
void _typeTitle(EventGrid e) {
  for (var s = 0; s < e.slots.length; s++) {
    final slot = e.slots[s];
    if (slot.isSpace || slot.isAuto || e.guess[s] != null) continue;
    final tile = e.pool.firstWhere((t) => t.letter == slot.char && !t.used && !t.eliminated);
    e.onBlankTap(s);
    e.onLetterTap(tile);
  }
}

String _answer(EventGrid e) => e.slots.map((s) => s.char).join();

/// Ouvre et trouve la case [day] ; retourne ce qu'elle a rapporté.
AdventSolveReward _solve(AdventCalendar a, int day) {
  expect(a.open(day), isTrue, reason: 'case $day');
  _typeTitle(a);
  expect(a.validate(), 'solved', reason: 'case $day');
  return a.lastReward!;
}

int _eventJokers(GameState g) => kEventJokers.map(g.countOf).reduce((a, b) => a + b);

/// Petits mots tolérés dans un pitch même s'ils sont dans le titre (« le »,
/// « de », « the », « of »… : tous les mots de 1 ou 2 lettres, plus ceux-ci).
const _toleratedWords = {'LES', 'DES', 'UNE', 'AUX', 'THE', 'AND'};

List<String> _words(String text) =>
    normalize(text).split(RegExp(r'[^A-Z0-9]+')).where((w) => w.isNotEmpty).toList();

/// Mots du titre retrouvés dans le pitch (à l'identique, ou en début de mot
/// pour les mots de 4 lettres et plus : « Noël » attrape « Noëls »).
Set<String> _titleWordsInPitch(String title, String pitch) {
  final titleWords = _words(title).where((w) => w.length > 2 && !_toleratedWords.contains(w)).toSet();
  final pitchWords = _words(pitch);
  return {
    for (final t in titleWords)
      if (pitchWords.any((p) => p == t || (t.length >= 4 && p.startsWith(t)))) t
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('contenu', () {
    test('25 cases, titres FR/EN et années renseignés', () {
      expect(kAdventPitches.length, 25);
      expect(kAdventPitches.map((p) => p.titleFr).toSet().length, 25);
      expect(kAdventPitches.map((p) => p.titleEn).toSet().length, 25);
      for (final p in kAdventPitches) {
        expect(p.pitchFr.trim(), isNotEmpty, reason: p.titleFr);
        expect(p.pitchEn.trim(), isNotEmpty, reason: p.titleEn);
        expect(RegExp(r'^\d{4}$').hasMatch(p.year), isTrue, reason: p.titleFr);
        // Pas de mention entre parenthèses dans une réponse à taper.
        expect(p.titleEn.contains('('), isFalse, reason: p.titleEn);
      }
    });

    test('aucun mot du titre dans son pitch (FR et EN)', () {
      for (final (i, p) in kAdventPitches.indexed) {
        expect(_titleWordsInPitch(p.titleFr, p.pitchFr), isEmpty, reason: 'case ${i + 1} FR : ${p.titleFr}');
        expect(_titleWordsInPitch(p.titleEn, p.pitchEn), isEmpty, reason: 'case ${i + 1} EN : ${p.titleEn}');
      }
    });

    test('longueurs : pitch FR 200 à 330 caractères, pitch EN 180 à 300', () {
      for (final (i, p) in kAdventPitches.indexed) {
        expect(p.pitchFr.length, inInclusiveRange(200, 330), reason: 'case ${i + 1} FR : ${p.pitchFr.length}');
        expect(p.pitchEn.length, inInclusiveRange(180, 300), reason: 'case ${i + 1} EN : ${p.pitchEn.length}');
      }
    });

    test('réponses supplémentaires acceptées (notes du 21/11)', () {
      bool fr(int day, String a) => kAdventPitches[day - 1].accepts('fr', a);
      bool en(int day, String a) => kAdventPitches[day - 1].accepts('en', a);
      expect(fr(15, 'Klaus'), isTrue);
      expect(fr(15, 'La Légende de Klaus'), isTrue);
      expect(fr(20, 'Le Frère Noël'), isTrue);
      expect(fr(20, 'frere noel'), isTrue);
      expect(fr(17, 'Mission : Noël'), isTrue);
      expect(fr(17, 'Mission : Noël - Les Aventures de la famille Noël'), isTrue);
      expect(fr(17, 'mission noel'), isTrue);
      expect(fr(12, 'Le Miracle sur la 34e rue'), isTrue);
      expect(fr(12, 'Miracle sur la 34e rue'), isTrue);
      expect(en(1, 'The Grinch'), isTrue);
      expect(en(1, 'How the Grinch Stole Christmas'), isTrue);
      expect(en(12, 'Miracle on 34th Street'), isTrue);
      // Une réponse d'une autre case reste refusée.
      expect(fr(15, 'Frère Noël'), isFalse);
      expect(fr(20, 'Klaus'), isFalse);
    });

    test('le contrôle des mots du titre attrape bien un mot interdit', () {
      // Les textes « validés » des notes, refusés pour cette raison.
      expect(_titleWordsInPitch('How the Grinch Stole Christmas', 'A small green creature stole my suit'), {'STOLE'});
      expect(_titleWordsInPitch('Home Alone', 'he defended his house alone against two burglars'), {'ALONE'});
      expect(_titleWordsInPitch('Mission : Noël', 'quatre Noëls à enchaîner'), {'NOEL'});
      expect(_titleWordsInPitch('Le Grinch', 'Je le connais'), isEmpty, reason: '« le » est toléré');
    });
  });

  group('ouverture par date', () {
    test('aucune case avant le 1er décembre, puis une de plus chaque jour à minuit', () {
      final clock = _Clock(DateTime(2026, 11, 30, 23, 59));
      final a = _newGame(clock).advent;
      expect(a.isActive, isFalse);
      expect(a.openedCount, 0);
      expect(a.open(1), isFalse);

      clock.now = DateTime(2026, 12, 1, 0, 0);
      expect(a.isActive, isTrue);
      expect(a.openedCount, 1);
      expect(a.todayCase, 1);
      expect(a.isPlayable(1), isTrue);
      expect(a.isPlayable(2), isFalse, reason: 'jamais en avance');
      expect(a.open(2), isFalse);

      clock.now = DateTime(2026, 12, 10, 23, 59);
      expect(a.openedCount, 10);
      expect(a.isPlayable(10), isTrue);
      expect(a.isPlayable(11), isFalse);

      clock.now = DateTime(2026, 12, 25, 8);
      expect(a.openedCount, 25);
      expect(a.todayCase, 25);
      expect(a.toPlayCount, 25);

      clock.now = DateTime(2026, 12, 31);
      expect(a.openedCount, 25);
      expect(a.todayCase, isNull);
    });

    test('rattrapage jusqu\'au 3 janvier inclus, puis le calendrier ferme', () {
      final clock = _Clock(DateTime(2027, 1, 3, 23, 59));
      final a = _newGame(clock).advent;
      expect(a.isActive, isTrue);
      expect(a.isPlayable(5), isTrue);
      _solve(a, 5);

      clock.now = DateTime(2027, 1, 4, 0, 0);
      expect(a.isActive, isFalse);
      expect(a.isOver, isTrue);
      expect(a.isPlayable(6), isFalse);
      expect(a.open(6), isFalse);
      expect(a.toPlayCount, 0);
      expect(a.suggestedDay, isNull);
    });

    test('case proposée : celle du jour d\'abord, puis la plus ancienne manquée', () {
      final clock = _Clock(DateTime(2026, 12, 4, 9));
      final a = _newGame(clock).advent;
      expect(a.suggestedDay, 4);
      _solve(a, 4);
      expect(a.suggestedDay, 1);
      _solve(a, 1);
      _solve(a, 2);
      _solve(a, 3);
      expect(a.suggestedDay, isNull);
      expect(a.waitingForTomorrow, isTrue);
    });
  });

  group('récompenses', () {
    test('joker du jour seulement si la case est trouvée le jour même', () {
      final clock = _Clock(DateTime(2026, 12, 3, 12));
      final analytics = _FakeAnalytics();
      final game = _newGame(clock, analytics: analytics);
      final a = game.advent;
      final reminded = <int>[];
      a.onSolvedOnTime = reminded.add;

      final onTime = _solve(a, 3);
      expect(onTime.onTime, isTrue);
      expect(kEventJokers, contains(onTime.dayJoker));
      expect(_eventJokers(game), 1);
      expect(a.solvedOnTime, {3});

      final late = _solve(a, 1);
      expect(late.onTime, isFalse);
      expect(late.dayJoker, isNull);
      expect(_eventJokers(game), 1, reason: 'case rattrapée : pas de joker');

      // Le lendemain, la case d'hier est une case rattrapée.
      clock.now = DateTime(2026, 12, 4, 0, 1);
      expect(_solve(a, 2).dayJoker, isNull);
      expect(_solve(a, 4).dayJoker, isNotNull);
      expect(_eventJokers(game), 2);

      expect(analytics.solvedCases, [(3, true), (1, false), (2, false), (4, true)]);
      expect(reminded, [3, 4], reason: 'rappel de 18 h annulé pour les cases du jour');
    });

    test('bonnet de Noël à la première case trouvée, une seule fois', () {
      final clock = _Clock(DateTime(2026, 12, 2, 10));
      final game = _newGame(clock);
      final a = game.advent;
      expect(game.settings.isAvatarUnlocked(kSantaHatAvatar), isFalse);
      expect(_solve(a, 1).hatUnlocked, isTrue);
      expect(game.settings.isAvatarUnlocked(kSantaHatAvatar), isTrue);
      expect(_solve(a, 2).hatUnlocked, isFalse);
    });

    test('les 25 cases : gros lot de 5 jokers et avatar final, donnés à la case 25', () {
      final clock = _Clock(DateTime(2026, 12, 25, 10));
      final game = _newGame(clock);
      final a = game.advent;
      for (var day = 1; day <= 24; day++) {
        expect(_solve(a, day).finalReward, isFalse, reason: 'case $day');
      }
      expect(game.settings.isAvatarUnlocked(kSnowHatAvatar), isFalse);
      final before = {for (final k in JokerKind.values) k: game.countOf(k)};
      final last = _solve(a, 25);
      expect(last.finalReward, isTrue);
      expect(last.onTime, isTrue);
      expect(game.settings.isAvatarUnlocked(kSnowHatAvatar), isTrue);
      expect(kAdventFinalJokers.length, 5);
      // 5 jokers du gros lot + le joker du jour de la case 25.
      final gained = JokerKind.values.map((k) => game.countOf(k) - before[k]!).reduce((x, y) => x + y);
      expect(gained, 6);
      for (final k in kAdventFinalJokers) {
        expect(game.countOf(k), greaterThanOrEqualTo(1), reason: k.name);
      }
      expect(a.allSolved, isTrue);
      expect(a.suggestedDay, isNull);
    });

    test('case 25 trouvée avant d\'avoir les 24 autres : le gros lot tombe à la dernière case rattrapée', () {
      final clock = _Clock(DateTime(2026, 12, 25, 10));
      final game = _newGame(clock);
      final a = game.advent;
      expect(_solve(a, 25).finalReward, isFalse);
      clock.now = DateTime(2026, 12, 28);
      for (var day = 1; day <= 23; day++) {
        expect(_solve(a, day).finalReward, isFalse);
      }
      expect(_solve(a, 24).finalReward, isTrue);
      expect(a.finalRewardGranted, isTrue);
    });

    test('un calendrier incomplet au 3 janvier ne donne jamais le gros lot', () {
      final clock = _Clock(DateTime(2027, 1, 3, 20));
      final game = _newGame(clock);
      final a = game.advent;
      for (var day = 1; day <= 24; day++) {
        _solve(a, day);
      }
      clock.now = DateTime(2027, 1, 4);
      expect(a.open(25), isFalse);
      expect(a.finalRewardGranted, isFalse);
      expect(game.settings.isAvatarUnlocked(kSnowHatAvatar), isFalse);
    });
  });

  group('grille', () {
    test('titre en anglais quand le jeu est en anglais', () {
      final game = _newGame(_Clock(DateTime(2026, 12, 25)))..settings.setLocale('en');
      game.advent.open(25);
      expect(_answer(game.advent), 'HOME ALONE');
      game.settings.setLocale('fr');
      game.advent.loadCurrent();
      expect(_answer(game.advent), "MAMAN, J'AI RATE L'AVION !");
    });

    test('ponctuation seule (« : », « ! ») : rien à trouver, jamais un joker gaspillé dessus', () {
      final game = _newGame(_Clock(DateTime(2026, 12, 25)))..revealWordCount = 1;
      final a = game.advent..open(17);
      expect(_answer(a), 'MISSION : NOEL');
      expect(a.lockedWords, {1});
      final revealed = a.useRevealWordJoker();
      expect(revealed, isNotEmpty);
      expect(game.revealWordCount, 0);
      expect(revealed.every((i) => !a.slots[i].isAuto), isTrue);
      _typeTitle(a);
      expect(a.validate(), 'solved');

      a.open(25); // MAMAN, J'AI RATE L'AVION !
      final wrong = a.pool.firstWhere((t) => !_answer(a).contains(t.letter));
      a.onBlankTap(0);
      a.onLetterTap(wrong);
      _typeTitle(a);
      expect(a.validate(), 'wrong');
      expect(a.attemptRows.last, [false, true, true, true], reason: 'le « ! » ne compte pas');
    });

    test('titre avec des chiffres : chiffres du titre et deux leurres', () {
      final a = _newGame(_Clock(DateTime(2026, 12, 12))).advent..open(12);
      expect(_answer(a), 'MIRACLE SUR LA 34E RUE');
      final digits = a.pool.where((t) => RegExp(r'^[0-9]$').hasMatch(t.letter)).map((t) => t.letter).toList();
      expect(digits.length, 4);
      expect(digits, containsAll(['3', '4']));
      _typeTitle(a);
      expect(a.validate(), 'solved');
    });

    test('une case laissée en cours garde sa grille quand le joueur en ouvre une autre', () {
      final game = _newGame(_Clock(DateTime(2026, 12, 5)))..grantJokers(eliminate: 1);
      final a = game.advent..open(5); // ELFE
      a.onLetterTap(a.pool.firstWhere((t) => t.letter == 'E'));
      expect(a.useEliminateJoker().length, 3);
      final eliminated = [for (final t in a.pool) t.eliminated];
      a.open(3);
      expect(_answer(a), 'PIEGE DE CRISTAL');
      a.open(5);
      expect(a.pool[a.guess[0]!].letter, 'E');
      expect([for (final t in a.pool) t.eliminated], eliminated);
    });
  });

  test('rappels de 18 h : un par case encore à trouver, jamais dans le passé', () {
    final clock = _Clock(DateTime(2026, 11, 20));
    final a = _newGame(clock).advent;
    final all = a.reminderTimes();
    expect(all.length, 25);
    expect(all[1], DateTime(2026, 12, 1, 18));
    expect(all[25], DateTime(2026, 12, 25, 18));

    clock.now = DateTime(2026, 12, 10, 12);
    expect(a.reminderTimes().keys.first, 10);
    _solve(a, 10);
    expect(a.reminderTimes().keys.first, 11, reason: 'case du jour déjà trouvée');

    clock.now = DateTime(2026, 12, 11, 18, 30);
    expect(a.reminderTimes().keys.first, 12, reason: '18 h passé');
    clock.now = DateTime(2026, 12, 25, 19);
    expect(a.reminderTimes(), isEmpty);
  });

  test('analytics : advent_case_solved, jamais un nom réservé par Firebase', () {
    expect(kAdventCaseSolvedEvent, 'advent_case_solved');
    const reserved = {
      'ad_activeview', 'ad_click', 'ad_exposure', 'ad_impression', 'ad_query', 'ad_reward', 'adunit_exposure',
      'app_background', 'app_clear_data', 'app_exception', 'app_remove', 'app_store_refund',
      'app_store_subscription_cancel', 'app_store_subscription_convert', 'app_store_subscription_renew',
      'app_update', 'app_upgrade', 'dynamic_link_app_open', 'dynamic_link_app_update', 'dynamic_link_first_open',
      'error', 'first_open', 'first_visit', 'in_app_purchase', 'notification_dismiss', 'notification_foreground',
      'notification_open', 'notification_receive', 'os_update', 'screen_view', 'session_start',
      'session_start_with_rollout', 'user_engagement',
    };
    expect(reserved.contains(kAdventCaseSolvedEvent), isFalse);
    expect(RegExp(r'^(firebase_|google_|ga_)').hasMatch(kAdventCaseSolvedEvent), isFalse);
    expect(kAdventCaseSolvedEvent.length, lessThanOrEqualTo(40));
  });

  test('le calendrier est sauvegardé avec le jeu, grille en cours comprise', () async {
    final clock = _Clock(DateTime(2026, 12, 3, 12));
    final game = _newGame(clock);
    final a = game.advent;
    _solve(a, 3);
    _solve(a, 1);
    a.open(2); // LE POLE EXPRESS
    a.onLetterTap(a.pool.firstWhere((t) => t.letter == 'L'));
    await game.flushSave();

    final reopened = _newGame(_Clock(DateTime(2026, 12, 4)));
    await reopened.restore();
    final r = reopened.advent;
    expect(r.solved, {1, 3});
    expect(r.solvedOnTime, {3});
    expect(r.open(2), isTrue);
    expect(r.pool[r.guess[0]!].letter, 'L');
  });

  test('une sauvegarde d\'une autre année est ignorée', () {
    final a = _newGame(_Clock(DateTime(2026, 12, 3))).advent;
    a.restore({'year': 2025, 'solved': [1, 2], 'onTime': [1], 'finalRewardGranted': true});
    expect(a.solved, isEmpty);
    expect(a.finalRewardGranted, isFalse);
    a.restore({'year': kAdventYear, 'solved': [1, 2, 99, 'x'], 'onTime': [1, 5]});
    expect(a.solved, {1, 2});
    expect(a.solvedOnTime, {1}, reason: 'une case « à l\'heure » doit être trouvée');
  });

  test('avatars de l\'Avent : jamais affichés sans avoir été gagnés', () async {
    SharedPreferences.setMockInitialValues({});
    final cheat = AppSettings(saveService: SaveService())..avatar = kSnowHatAvatar;
    await SaveService().saveSettings(cheat.toJson());
    final restored = AppSettings(saveService: SaveService());
    await restored.restore();
    expect(restored.avatar, isNot(kSnowHatAvatar));
  });

  group('écrans', () {
    Widget app(GameState game, Widget home) => MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: game.settings),
            ChangeNotifierProvider.value(value: game),
            ChangeNotifierProvider(create: (_) => StreakState(saveService: game.saveService)),
            Provider(create: (_) => SoundService()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
            home: home,
          ),
        );

    testWidgets('calendrier : case fermée, case du jour trouvée, puis case rattrapée', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.6;
      addTearDown(tester.view.reset);
      final game = _newGame(_Clock(DateTime(2026, 12, 3, 12)));
      await tester.pumpWidget(app(game, const AdventCalendarScreen()));
      await tester.pump();
      expect(find.text('LE PÈRE NOËL FAIT SON CINÉMA'), findsOneWidget);
      expect(find.text('0/25 cases trouvées'), findsOneWidget);

      final list = find.byType(Scrollable).first; // la page (la grille des cases ne défile pas)
      await tester.scrollUntilVisible(find.byKey(const ValueKey('adventCase10')), 200, scrollable: list);
      await tester.tap(find.byKey(const ValueKey('adventCase10')));
      await tester.pump();
      expect(find.text('Patience ! Cette case s\'ouvre le 10 décembre.'), findsOneWidget);
      // Le message est retiré avant de toucher le bouton du bas, qu'il couvrirait.
      ScaffoldMessenger.of(tester.element(find.byType(AdventCalendarScreen))).removeCurrentSnackBar();
      await tester.pump();

      await tester.scrollUntilVisible(find.byKey(const ValueKey('adventPlay')), 200, scrollable: list);
      await tester.ensureVisible(find.byKey(const ValueKey('adventPlay')));
      expect(find.text('JOUER LA CASE 3'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('adventPlay')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800)); // transition (le fond animé empêche pumpAndSettle)
      expect(find.text('🎄 CASE 3'), findsOneWidget);
      expect(find.textContaining('Un policier new-yorkais'), findsOneWidget);
      expect(find.text('Trouve-la aujourd\'hui : +1 joker !'), findsOneWidget);

      _typeTitle(game.advent);
      await tester.pump();
      await tester.ensureVisible(find.byKey(const ValueKey('adventValidate')));
      await tester.tap(find.byKey(const ValueKey('adventValidate')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1100));
      expect(find.byKey(const ValueKey('adventSolvedTitle')), findsOneWidget);
      expect(find.text('Piège de cristal'), findsOneWidget);
      expect(find.byKey(const ValueKey('adventRewardJoker')), findsOneWidget);
      expect(find.text('Nouvel avatar débloqué : Bonnet de Noël !'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('adventNext')));
      await tester.pump();
      expect(find.text('🎄 CASE 1'), findsOneWidget);
      expect(find.text('Case rattrapée : le joker n\'est donné que le jour même.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
    });

    Future<void> pumpHome(WidgetTester tester, DateTime now) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final game = _newGame(_Clock(now));
      await tester.pumpWidget(app(game, HomeScreen(onPlay: () {})));
      await tester.pump();
    }

    testWidgets('accueil : entrée visible du 1er décembre au 3 janvier, avec les cases à jouer', (tester) async {
      await pumpHome(tester, DateTime(2026, 12, 5, 9));
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('homeAdventCalendar')), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const ValueKey('homeAdventBadge'))).data, '5');

      await pumpHome(tester, DateTime(2027, 1, 3, 22));
      expect(find.byKey(const ValueKey('homeAdventCalendar')), findsOneWidget);
    });

    testWidgets('accueil : pas d\'entrée avant le 1er décembre ni après le 3 janvier', (tester) async {
      await pumpHome(tester, DateTime(2026, 11, 30, 22));
      expect(find.byKey(const ValueKey('homeAdventCalendar')), findsNothing);
      await pumpHome(tester, DateTime(2027, 1, 4, 0, 5));
      expect(find.byKey(const ValueKey('homeAdventCalendar')), findsNothing);
    });
  });
}
