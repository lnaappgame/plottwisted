import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cine_devinette/l10n/app_localizations.dart';
import 'package:cine_devinette/models/joker.dart';
import 'package:cine_devinette/models/puzzle.dart';
import 'package:cine_devinette/services/ad_service.dart';
import 'package:cine_devinette/services/app_settings.dart';
import 'package:cine_devinette/services/game_state.dart';
import 'package:cine_devinette/services/save_service.dart';
import 'package:cine_devinette/services/sound_service.dart';
import 'package:cine_devinette/theme/app_theme.dart';
import 'package:cine_devinette/widgets/answer_row.dart';
import 'package:cine_devinette/widgets/joker_bar.dart';
import 'package:cine_devinette/widgets/joker_fx.dart';
import 'package:cine_devinette/widgets/joker_style.dart';
import 'package:cine_devinette/widgets/letter_pool.dart';
import 'package:cine_devinette/widgets/pitch_card.dart';

void _setCount(GameState game, JokerKind kind, int n) {
  switch (kind) {
    case JokerKind.reveal:
      game.revealCount = n;
    case JokerKind.eliminate:
      game.eliminateCount = n;
    case JokerKind.actor:
      game.actorCount = n;
    case JokerKind.character:
      game.characterCount = n;
    case JokerKind.hint:
      game.hintCount = n;
    case JokerKind.revealWord:
      game.revealWordCount = n;
    case JokerKind.red:
      game.redJokerCount = n;
  }
}

GameState _gameOnLevel(int world, int level) {
  final saveService = SaveService();
  final game = GameState(adService: AdService(), saveService: saveService, settings: AppSettings(saveService: saveService));
  game.enterWorld(world);
  game.currentLevelNumber = level;
  game.loadPuzzle();
  return game;
}

/// [onEvent] reçoit "ad" (bouton Gagner un joker) ou "red" (joker rouge épuisé touché).
Future<void> _pumpBar(WidgetTester tester, GameState game, JokerFx fx, void Function(String) onEvent,
    {Widget? above}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: game.settings),
        ChangeNotifierProvider.value(value: game),
        Provider(create: (_) => SoundService()),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(
          body: Stack(
            children: [
              if (above != null) Align(alignment: Alignment.topCenter, child: above),
              Align(
                  alignment: Alignment.bottomCenter,
                  child: JokerBar(
                      fx: fx, onWatchAdForJoker: () => onEvent('ad'), onRedJokerEmpty: () => onEvent('red'))),
              Positioned.fill(child: JokerFxLayer(fx: fx)),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// Avance le temps frame par frame (~60 i/s), comme sur un vrai écran.
Future<void> _frames(WidgetTester tester, int ms) async {
  for (var t = 0; t < ms; t += 16) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('chaque libellé d\'octroi correspond à un type de joker', () {
    for (final label in ['Révéler', 'Éliminer', 'Personnage', 'Acteur', 'Indice', 'Révéler un mot', 'Personnage (rouge)']) {
      expect(JokerKind.fromLabel(label), isNotNull, reason: label);
    }
  });

  group('Pub « Gagner un joker » : tirage', () {
    void resetCounts(GameState game) {
      for (final kind in [...GameState.kMinorJokers, ...GameState.kMajorJokers]) {
        _setCount(game, kind, 0);
      }
    }

    test('1/3 chacun au sein de sa catégorie', () {
      final game = _gameOnLevel(1, 1);
      for (final odds in [game.jokerOddsWithin(GameState.kMinorJokers), game.jokerOddsWithin(GameState.kMajorJokers)]) {
        expect(odds.values, everyElement(closeTo(1 / 3, 1e-9)));
      }
    });

    test('5 exemplaires ou plus : chance divisée par 2, reportée sur les autres de la catégorie', () {
      final game = _gameOnLevel(1, 1);
      game.characterCount = 5;
      var odds = game.jokerOddsWithin(GameState.kMinorJokers);
      expect(odds[JokerKind.character], closeTo(1 / 6, 1e-9));
      expect(odds[JokerKind.reveal], closeTo(5 / 12, 1e-9));
      expect(odds[JokerKind.eliminate], closeTo(5 / 12, 1e-9));
      // Les majeurs ne bougent pas.
      expect(game.jokerOddsWithin(GameState.kMajorJokers).values, everyElement(closeTo(1 / 3, 1e-9)));

      game.revealCount = 7;
      odds = game.jokerOddsWithin(GameState.kMinorJokers);
      expect(odds[JokerKind.character], closeTo(1 / 6, 1e-9));
      expect(odds[JokerKind.reveal], closeTo(1 / 6, 1e-9));
      expect(odds[JokerKind.eliminate], closeTo(2 / 3, 1e-9));

      game.eliminateCount = 5; // tous abondants : retour à l'égalité
      expect(game.jokerOddsWithin(GameState.kMinorJokers).values, everyElement(closeTo(1 / 3, 1e-9)));
    });

    test('1re pub du niveau : 80 % mineurs, puis 60 %', () {
      final game = _gameOnLevel(1, 1);
      const draws = 4000;
      var firstMinor = 0, laterMinor = 0;
      for (var i = 0; i < draws; i++) {
        resetCounts(game);
        game.adsWatchedThisLevel = 0;
        if (game.grantWeightedRandomJoker().isMinor) firstMinor++;
        resetCounts(game);
        if (game.grantWeightedRandomJoker().isMinor) laterMinor++;
      }
      expect(firstMinor / draws, closeTo(0.8, 0.04));
      expect(laterMinor / draws, closeTo(0.6, 0.04));
      expect(game.adsWatchedThisLevel, 2);
    });

    test('exemple : 5 Personnage, 2e pub : Personnage tombe à 10 % au total', () {
      final game = _gameOnLevel(1, 1);
      const draws = 6000;
      final hits = <JokerKind, int>{};
      for (var i = 0; i < draws; i++) {
        resetCounts(game);
        game.characterCount = 5;
        game.adsWatchedThisLevel = 1;
        final kind = game.grantWeightedRandomJoker();
        hits[kind] = (hits[kind] ?? 0) + 1;
      }
      expect((hits[JokerKind.character] ?? 0) / draws, closeTo(0.10, 0.03));
      expect((hits[JokerKind.reveal] ?? 0) / draws, closeTo(0.25, 0.03));
      expect((hits[JokerKind.actor] ?? 0) / draws, closeTo(0.40 / 3, 0.03));
    });

    test('le joker tiré est bien ajouté au stock', () {
      final game = _gameOnLevel(1, 1);
      final kind = game.grantRandomJoker(minor: false);
      expect(GameState.kMajorJokers, contains(kind));
      expect(game.countOf(kind), 1);
    });
  });

  group('Cibles renvoyées par les jokers (pour le faisceau)', () {
    test('Révéler renvoie la case remplie', () {
      final game = _gameOnLevel(1, 1);
      game.revealCount = 1;
      final slot = game.useRevealJoker();
      expect(slot, isNotNull);
      expect(game.pool[game.guess[slot!]!].letter, game.slots[slot].char);
      expect(game.useRevealJoker(), isNull); // plus de stock
    });

    test('Éliminer renvoie les lettres éliminées', () {
      final game = _gameOnLevel(1, 1);
      game.eliminateCount = 1;
      final tiles = game.useEliminateJoker();
      expect(tiles, isNotEmpty);
      expect(tiles.every((i) => game.pool[i].eliminated), isTrue);
    });

    test('Révéler un mot renvoie les cases du mot', () {
      final game = _gameOnLevel(1, 3); // TITANIC : un seul mot
      game.revealWordCount = 1;
      final slots = game.useRevealWordJoker();
      expect(slots, isNotEmpty);
      expect(slots.every((i) => game.guess[i] != null), isTrue);
      expect(game.revealWordCount, 0);
    });
  });

  group('Barre de jokers', () {
    testWidgets('joker à 0 : éteint, le toucher ne fait rien ; un seul bouton pour la pub', (tester) async {
      final game = _gameOnLevel(1, 1);
      final events = <String>[];
      await _pumpBar(tester, game, JokerFx(), events.add);
      await tester.tap(find.text('RÉVÉLER'));
      await tester.pump();
      expect(events, isEmpty);
      expect(game.revealCount, 0);
      await tester.tap(find.text('GAGNER UN JOKER'));
      expect(events, ['ad']);
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('joker à 0 : garde sa couleur, plus pâle, avec une bordure fine', (tester) async {
      final game = _gameOnLevel(1, 1);
      game.actorCount = 1;
      await _pumpBar(tester, game, JokerFx(), (_) {});
      BoxDecoration boxOf(String label) => tester
          .widget<Container>(find.ancestor(of: find.text(label), matching: find.byType(Container)).first)
          .decoration! as BoxDecoration;
      final owned = boxOf('ACTEUR'), empty = boxOf('PERSONNAGE');
      expect(owned.border!.top.width, greaterThan(empty.border!.top.width));
      expect(empty.color!.opacity, greaterThan(0));
      expect(empty.color!.opacity, lessThan(owned.color!.opacity));
      final emptyLabel = tester.widget<Text>(find.text('PERSONNAGE'));
      expect(emptyLabel.style!.color!.opacity, lessThan(1));
      final expected = jokerColor(
          JokerKind.character, AppColors(game.settings.isLightTheme, colorblind: game.settings.colorblindMode));
      expect(emptyLabel.style!.color!.withOpacity(1), expected.withOpacity(1));
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('joker rouge épuisé sur un nom orange : reste touchable (pub garantie)', (tester) async {
      final game = _gameOnLevel(1, 10); // STAR WARS : un nom orange
      final events = <String>[];
      await _pumpBar(tester, game, JokerFx(), events.add);
      expect(find.text('🎬 pub → joker'), findsOneWidget);
      await tester.tap(find.text('PERSONNAGE (ROUGE)'));
      expect(events, ['red']);
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('tutoriel : pas de bouton de pub', (tester) async {
      final game = _gameOnLevel(0, 1);
      await _pumpBar(tester, game, JokerFx(), (_) {});
      expect(find.text('GAGNER UN JOKER'), findsNothing);
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('joker possédé : badge de quantité, et le toucher l\'utilise', (tester) async {
      final game = _gameOnLevel(1, 1);
      game.revealCount = 2;
      final events = <String>[];
      await _pumpBar(tester, game, JokerFx(), events.add);
      expect(find.text('2'), findsOneWidget);
      await tester.tap(find.text('RÉVÉLER'));
      await tester.pump();
      expect(events, isEmpty);
      expect(game.revealCount, 1);
      expect(find.text('1'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Révéler : la lettre n\'apparaît dans sa case qu\'à l\'impact du faisceau', (tester) async {
      final game = _gameOnLevel(1, 1);
      game.revealCount = 1;
      final fx = JokerFx();
      await _pumpBar(tester, game, fx, (_) {}, above: AnswerRow(fx: fx));
      await tester.tap(find.text('RÉVÉLER'));
      await tester.pump();
      final slot = game.guess.indexWhere((g) => g != null);
      final letter = find.descendant(of: find.byKey(fx.key('slot:$slot')), matching: find.text(game.slots[slot].char));
      expect(fx.isIncoming('slot:$slot'), isTrue);
      expect(letter, findsNothing);
      await _frames(tester, 200);
      expect(letter, findsNothing); // faisceau en vol
      await _frames(tester, 250);
      expect(fx.isIncoming('slot:$slot'), isFalse);
      expect(letter, findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Éliminer : les lettres ne s\'éteignent qu\'à l\'impact', (tester) async {
      final game = _gameOnLevel(1, 1);
      game.eliminateCount = 1;
      final fx = JokerFx();
      await _pumpBar(tester, game, fx, (_) {}, above: LetterPool(fx: fx));
      await tester.tap(find.text('ÉLIMINER'));
      await tester.pump();
      final tiles = [for (var i = 0; i < game.pool.length; i++) if (game.pool[i].eliminated) i];
      expect(tiles, isNotEmpty);
      double opacityOf(int i) => tester
          .widget<AnimatedOpacity>(find.descendant(of: find.byKey(fx.key('tile:$i')), matching: find.byType(AnimatedOpacity)))
          .opacity;
      expect(tiles.map(opacityOf), everyElement(1.0));
      await _frames(tester, 200);
      expect(tiles.map(opacityOf), everyElement(1.0)); // faisceaux en vol
      await _frames(tester, 250);
      expect(tiles.map(opacityOf), everyElement(0.15));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Personnage : le nom du pitch ne change qu\'à l\'impact', (tester) async {
      final game = _gameOnLevel(1, 1); // GLADIATOR : "le Joker" a une version personnage
      game.characterCount = 1;
      final fx = JokerFx();
      await _pumpBar(tester, game, fx, (_) {}, above: PitchCard(fx: fx));
      final before = game.displayFor('p2', game.displayedColors('p2').first);
      final after = game.displayFor('p2', NameColor.green);
      await tester.tap(find.text('PERSONNAGE'));
      await tester.pump();
      await tester.tap(find.text(before));
      await tester.pump();
      expect(game.displayedColors('p2').first, NameColor.green);
      expect(find.text(after), findsNothing);
      await _frames(tester, 200);
      expect(find.text(after), findsNothing); // faisceau en vol
      expect(find.text(before), findsOneWidget);
      await _frames(tester, 250);
      expect(find.text(after), findsOneWidget);
      expect(find.text(before), findsOneWidget); // ancienne couleur toujours affichée après le " / "
      // À l'impact, le nouveau nom s'illumine (pulsation de 0,5 s), puis s'éteint.
      double flash() {
        final box = find.byKey(const ValueKey('nameFlash:p2'));
        if (box.evaluate().isEmpty) return 0;
        return ((tester.widget<DecoratedBox>(box).decoration as BoxDecoration).color?.opacity) ?? 0;
      }
      expect(find.descendant(of: find.byKey(const ValueKey('nameFlash:p2')), matching: find.text(after)), findsOneWidget);
      expect(flash(), greaterThan(0.05));
      await _frames(tester, 600);
      expect(flash(), lessThan(0.01));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('récompense : la quantité ne change qu\'à l\'arrivée de l\'étoile', (tester) async {
      final game = _gameOnLevel(1, 1);
      final fx = JokerFx();
      await _pumpBar(tester, game, fx, (_) {});
      game.revealCount += 2;
      fx.reward(grants: const [RewardGrant(JokerKind.reveal, 2)]);
      await tester.pump();
      expect(find.text('JOKERS GAGNÉS'), findsOneWidget);
      expect(fx.pending(JokerKind.reveal), 2);
      expect(find.text('2'), findsNothing); // pas encore arrivée
      await _frames(tester, 2400);
      expect(find.text('JOKERS GAGNÉS'), findsOneWidget); // la bannière reste ~3 s
      expect(find.text('2'), findsNothing);
      await _frames(tester, 1000);
      expect(fx.pending(JokerKind.reveal), 0);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('JOKERS GAGNÉS'), findsNothing);
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    });
  });
}
