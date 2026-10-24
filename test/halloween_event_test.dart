import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cine_devinette/data/halloween_pitches_data.dart';
import 'package:cine_devinette/l10n/app_localizations.dart';
import 'package:cine_devinette/models/joker.dart';
import 'package:cine_devinette/screens/halloween_event_screen.dart';
import 'package:cine_devinette/services/ad_service.dart';
import 'package:cine_devinette/services/app_settings.dart';
import 'package:cine_devinette/services/game_state.dart';
import 'package:cine_devinette/services/halloween_event.dart';
import 'package:cine_devinette/services/save_service.dart';
import 'package:cine_devinette/services/sound_service.dart';
import 'package:cine_devinette/services/streak_state.dart';

GameState _newGame({DateTime? now}) {
  final saveService = SaveService();
  final game = GameState(adService: AdService(), saveService: saveService, settings: AppSettings(saveService: saveService));
  if (now != null) game.clock = () => now;
  return game;
}

/// Remplit les cases encore vides avec les bonnes lettres.
void _typeTitle(HalloweenEvent e) {
  for (var s = 0; s < e.slots.length; s++) {
    final slot = e.slots[s];
    if (slot.isSpace || slot.isAuto || e.guess[s] != null) continue;
    final tile = e.pool.firstWhere((t) => t.letter == slot.char && !t.used && !t.eliminated);
    e.onBlankTap(s);
    e.onLetterTap(tile);
  }
}

String _answer(HalloweenEvent e) => e.slots.map((s) => s.char).join();

/// Mots de 4 lettres ou plus, sans accents ni ponctuation.
Set<String> _words(String text) =>
    normalize(text).split(RegExp(r'[^A-Z0-9]+')).where((w) => w.length >= 4).toSet();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('le contenu : 30 pitchs en FR et EN, sans le titre dans le pitch', () {
    expect(kHalloweenPitches.length, 30);
    expect(kHalloweenPitches.map((p) => p.titleFr).toSet().length, 30);
    for (final p in kHalloweenPitches) {
      expect(p.pitchFr.trim(), isNotEmpty, reason: p.titleFr);
      expect(p.pitchEn.trim(), isNotEmpty, reason: p.titleEn);
      expect(_words(p.pitchFr).intersection(_words(p.titleFr)), isEmpty, reason: p.titleFr);
      expect(_words(p.pitchEn).intersection(_words(p.titleEn)), isEmpty, reason: p.titleEn);
    }
  });

  group('calendrier', () {
    test('10 pitchs le premier jour, puis 2 de plus par jour', () {
      var now = DateTime(2026, 10, 26, 20);
      final game = _newGame()..clock = () => now;
      final e = game.halloween..markVisited();
      expect(e.availableCount, 10);
      now = DateTime(2026, 10, 27, 0, 5);
      expect(e.availableCount, 12);
      now = DateTime(2026, 11, 4, 9);
      expect(e.availableCount, 28);
      now = DateTime(2026, 11, 5, 9);
      expect(e.availableCount, 30);
    });

    test('un joueur arrivé tard a tout le dernier jour', () {
      var now = DateTime(2026, 11, 5, 10);
      final game = _newGame()..clock = () => now;
      game.halloween.markVisited();
      expect(game.halloween.availableCount, 24, reason: 'il reste 3 jours : 30 - 3 × 2');
      now = DateTime(2026, 11, 8, 23);
      expect(game.halloween.availableCount, 30);
      expect(game.halloween.isActive, isTrue);
      now = DateTime(2026, 11, 9, 0, 1);
      expect(game.halloween.isActive, isFalse);
    });

    test('pitchs du jour finis : « reviens demain »', () {
      final game = _newGame(now: DateTime(2026, 10, 26, 12));
      final e = game.halloween..markVisited();
      e.solved.addAll(List.generate(10, (i) => i));
      expect(e.currentPitch, isNull);
      expect(e.waitingForTomorrow, isTrue);
      expect(e.toPlayCount, 0);
    });
  });

  group('jouer', () {
    test('mots justes gardés après une erreur, puis pitch trouvé : citrouille, pitch suivant', () {
      final game = _newGame(now: DateTime(2026, 10, 26));
      final e = game.halloween..loadCurrent();
      expect(e.loadedPitch, 0);
      expect(_answer(e), 'LES DENTS DE LA MER');
      // Tout juste sauf la première lettre du dernier mot (MER).
      final wrongSlot = e.wordRanges.last.first;
      final decoy = e.pool.firstWhere((t) => !_answer(e).contains(t.letter));
      e.onBlankTap(wrongSlot);
      e.onLetterTap(decoy);
      _typeTitle(e);
      expect(e.validate(), 'wrong');
      expect(e.lockedWords, {0, 1, 2, 3});
      expect(e.guess[wrongSlot], isNull);

      _typeTitle(e);
      expect(e.validate(), 'solved');
      expect(e.solved, {0});
      expect(e.lastReward!.pumpkinUnlocked, isTrue);
      expect(e.lastReward!.joker, isNull);
      expect(game.settings.isAvatarUnlocked(kPumpkinAvatar), isTrue);
      expect(e.currentPitch, 1);
      e.loadCurrent();
      expect(_answer(e), 'CA');
    });

    test('un joker de l\'event tous les 5 pitchs trouvés', () {
      final game = _newGame(now: DateTime(2026, 10, 26));
      final e = game.halloween;
      final jokers = <JokerKind?>[];
      for (var i = 0; i < 5; i++) {
        e.loadCurrent();
        _typeTitle(e);
        expect(e.validate(), 'solved');
        jokers.add(e.lastReward!.joker);
      }
      expect(jokers.take(4), everyElement(isNull));
      expect(kEventJokers, contains(jokers.last));
      expect(game.countOf(jokers.last!), 1);
    });

    test('titre en anglais quand le jeu est en anglais', () {
      final game = _newGame()..settings.setLocale('en');
      game.halloween.loadCurrent();
      expect(_answer(game.halloween), 'JAWS');
    });

    test('les 30 pitchs : bonus final et citrouille en feu, une seule fois', () {
      final game = _newGame(now: DateTime(2026, 11, 8));
      final e = game.halloween;
      for (var i = 0; i < 30; i++) {
        e.loadCurrent();
        _typeTitle(e);
        expect(e.validate(), 'solved', reason: kHalloweenPitches[e.loadedPitch!].titleFr);
        expect(e.lastReward!.finalReward, i == 29);
      }
      expect(game.redJokerCount, 1);
      expect(game.settings.isAvatarUnlocked(kFirePumpkinAvatar), isTrue);
      expect(e.allSolved, isTrue);
      expect(e.currentPitch, isNull);
    });
  });

  group('passer, j\'y reviendrai', () {
    test('le pitch repart en fin de file avec sa grille et ses jokers', () {
      final game = _newGame(now: DateTime(2026, 10, 26))..grantJokers(eliminate: 1);
      final e = game.halloween..loadCurrent();
      e.onLetterTap(e.pool.firstWhere((t) => t.letter == 'L'));
      expect(e.useEliminateJoker().length, 3);
      final eliminated = [for (final t in e.pool) t.eliminated];
      expect(e.skipCurrent(), isTrue);
      expect(e.loadedPitch, 1);
      expect(e.queue.last, 0);

      // Les 9 autres pitchs du jour trouvés : retour au premier.
      for (var i = 0; i < 9; i++) {
        _typeTitle(e);
        expect(e.validate(), 'solved');
        e.loadCurrent();
      }
      expect(e.loadedPitch, 0);
      expect(e.pool[e.guess[0]!].letter, 'L');
      expect([for (final t in e.pool) t.eliminated], eliminated);
      expect(e.canSkip, isFalse, reason: 'dernier pitch ouvert');
      expect(e.skipCurrent(), isFalse);
    });
  });

  group('jokers', () {
    test('Révéler, Éliminer et Révéler un mot puisent dans le stock du jeu', () {
      final game = _newGame(now: DateTime(2026, 10, 26))
        ..grantJokers(reveal: 1, eliminate: 1)
        ..revealWordCount = 1;
      final e = game.halloween..loadCurrent(); // LES DENTS DE LA MER
      final slot = e.useRevealJoker()!;
      expect(e.pool[e.guess[slot]!].letter, e.slots[slot].char);
      expect(e.lockedSlots, contains(slot));
      expect(game.revealCount, 0);
      expect(e.useRevealJoker(), isNull, reason: 'plus de joker');

      final gone = e.useEliminateJoker();
      expect(gone.length, 3);
      for (final i in gone) {
        expect(_answer(e).contains(e.pool[i].letter), isFalse);
      }
      expect(game.eliminateCount, 0);

      final revealed = e.useRevealWordJoker();
      expect(revealed, isNotEmpty);
      expect(e.lockedWords.length, 1);
      expect(game.revealWordCount, 0);
    });

    test('Révéler un mot sur un titre d\'un seul mot : un tiers des lettres', () {
      final game = _newGame(now: DateTime(2026, 11, 8))..revealWordCount = 1;
      final e = game.halloween;
      e.queue
        ..remove(3)
        ..insert(0, 3); // FRANKENSTEIN
      e.loadCurrent();
      expect(e.revealWordIsNerfed, isTrue);
      expect(e.useRevealWordJoker().length, 4);
      expect(game.revealWordCount, 0);
    });

    test('pub : toujours un des trois jokers de l\'event', () {
      final game = _newGame();
      for (var i = 0; i < 20; i++) {
        expect(kEventJokers, contains(game.halloween.grantAdJoker()));
      }
    });
  });

  test('l\'event est sauvegardé avec le jeu, grille en cours comprise', () async {
    final game = _newGame(now: DateTime(2026, 10, 26));
    final e = game.halloween
      ..markVisited()
      ..loadCurrent();
    _typeTitle(e);
    e.validate();
    e.loadCurrent(); // pitch 2 : ÇA
    e.skipCurrent(); // pitch 3 : DRACULA
    e.onLetterTap(e.pool.firstWhere((t) => t.letter == 'D'));
    await game.flushSave();

    final reopened = _newGame(now: DateTime(2026, 10, 27));
    await reopened.restore();
    final r = reopened.halloween;
    expect(r.firstDay, '2026-10-26');
    expect(r.availableCount, 12);
    expect(r.solved, {0});
    expect(r.queue.last, 1);
    r.loadCurrent();
    expect(r.loadedPitch, 2);
    expect(r.pool[r.guess[0]!].letter, 'D');
  });

  test('une sauvegarde de l\'ancienne version (questions) est ignorée', () {
    final e = _newGame().halloween;
    e.restore({
      'firstDay': '2026-10-24',
      'progress': {
        '0': {'answers': [0, 0, 0, 0], 'solved': true}
      },
    });
    expect(e.firstDay, isNull);
    expect(e.solved, isEmpty);
  });

  test('avatars d\'event : sauvegardés, et jamais affichés sans avoir été gagnés', () async {
    final saveService = SaveService();
    // Champs posés directement (sans notifyListeners) : pas d'écritures
    // asynchrones concurrentes dans le faux SharedPreferences.
    final settings = AppSettings(saveService: saveService)
      ..unlockedAvatars.add(kPumpkinAvatar)
      ..avatar = kPumpkinAvatar;
    await saveService.saveSettings(settings.toJson());
    final reloaded = AppSettings(saveService: saveService);
    await reloaded.restore();
    expect(reloaded.isAvatarUnlocked(kPumpkinAvatar), isTrue);
    expect(reloaded.avatar, kPumpkinAvatar);

    SharedPreferences.setMockInitialValues({});
    final cheat = AppSettings(saveService: SaveService())..avatar = kFirePumpkinAvatar;
    await SaveService().saveSettings(cheat.toJson());
    final restored = AppSettings(saveService: SaveService());
    await restored.restore();
    expect(cheat.avatar, kFirePumpkinAvatar);
    expect(restored.avatar, isNot(kFirePumpkinAvatar));
  });

  testWidgets('écran : présentation, puis un pitch trouvé et le suivant', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    final game = _newGame(now: DateTime(2026, 10, 26, 12));
    await tester.pumpWidget(
      MultiProvider(
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
          home: const HalloweenEventScreen(),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('ET SI LES MÉCHANTS AVAIENT RAISON ?'), findsOneWidget);
    expect(find.text('0/30 pitchs trouvés'), findsOneWidget);

    await tester.scrollUntilVisible(find.byKey(const ValueKey('eventPlay')), 200);
    await tester.tap(find.byKey(const ValueKey('eventPlay')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800)); // transition de page (le fond animé empêche pumpAndSettle)
    expect(find.text('PITCH 1/30'), findsOneWidget);
    expect(find.textContaining('Un nageur solitaire'), findsOneWidget);

    _typeTitle(game.halloween);
    await tester.pump();
    await tester.ensureVisible(find.byKey(const ValueKey('eventValidate')));
    await tester.tap(find.byKey(const ValueKey('eventValidate')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1100));
    expect(find.byKey(const ValueKey('eventSolvedTitle')), findsOneWidget);
    expect(find.text('Les Dents de la mer'), findsOneWidget);
    expect(find.text('Nouvel avatar débloqué : Tête de citrouille !'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('eventNext')));
    await tester.pump();
    expect(find.text('PITCH 2/30'), findsOneWidget);
    expect(find.textContaining('Un clown très investi'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('eventSkip')));
    await tester.tap(find.byKey(const ValueKey('eventSkip')));
    await tester.pump();
    expect(find.textContaining('Un comte insomniaque'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });
}
