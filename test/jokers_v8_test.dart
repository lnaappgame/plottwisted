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
import 'package:cine_devinette/widgets/answer_row.dart';
import 'package:cine_devinette/widgets/joker_bar.dart';
import 'package:cine_devinette/widgets/joker_fx.dart';
import 'package:cine_devinette/widgets/letter_pool.dart';
import 'package:cine_devinette/widgets/pitch_card.dart';

GameState _gameOnLevel(int world, int level) {
  final saveService = SaveService();
  final game = GameState(adService: AdService(), saveService: saveService, settings: AppSettings(saveService: saveService));
  game.enterWorld(world);
  game.currentLevelNumber = level;
  game.loadPuzzle();
  return game;
}

Future<void> _pumpBar(WidgetTester tester, GameState game, JokerFx fx, void Function(JokerKind) onRequest,
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
              Align(alignment: Alignment.bottomCenter, child: JokerBar(fx: fx, onRequestJoker: onRequest)),
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

  group('Pub depuis un joker épuisé', () {
    test('joker mineur : +2, joker majeur : +1', () {
      final game = _gameOnLevel(1, 1);
      expect(game.grantJokerFromAd(JokerKind.reveal), 2);
      expect(game.grantJokerFromAd(JokerKind.eliminate), 2);
      expect(game.grantJokerFromAd(JokerKind.character), 2);
      expect(game.grantJokerFromAd(JokerKind.actor), 1);
      expect(game.grantJokerFromAd(JokerKind.hint), 1);
      expect(game.grantJokerFromAd(JokerKind.revealWord), 1);
      expect(game.revealCount, 2);
      expect(game.characterCount, 2);
      expect(game.actorCount, 1);
      expect(game.revealWordCount, 1);
    });

    test('joker rouge : seulement sur un nom orange, une fois par niveau', () {
      final game = _gameOnLevel(1, 10); // STAR WARS : un nom orange
      expect(game.grantJokerFromAd(JokerKind.red), 1);
      expect(game.redJokerCount, 1);
      game.redJokerCount = 0;
      expect(game.grantJokerFromAd(JokerKind.red), 0);
    });

    test('pas de pub pendant le tutoriel', () {
      final game = _gameOnLevel(0, 1);
      expect(game.grantJokerFromAd(JokerKind.reveal), 0);
      expect(game.revealCount, 0);
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
    testWidgets('joker épuisé : le toucher demande pub ou boutique', (tester) async {
      final game = _gameOnLevel(1, 1);
      JokerKind? requested;
      await _pumpBar(tester, game, JokerFx(), (k) => requested = k);
      expect(find.text('+ obtenir'), findsWidgets);
      await tester.tap(find.text('RÉVÉLER'));
      expect(requested, JokerKind.reveal);
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('joker possédé : badge de quantité, et le toucher l\'utilise', (tester) async {
      final game = _gameOnLevel(1, 1);
      game.revealCount = 2;
      JokerKind? requested;
      await _pumpBar(tester, game, JokerFx(), (k) => requested = k);
      expect(find.text('2'), findsOneWidget);
      await tester.tap(find.text('RÉVÉLER'));
      await tester.pump();
      expect(requested, isNull);
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
      game.grantJokerFromAd(JokerKind.reveal);
      fx.reward(grants: const [RewardGrant(JokerKind.reveal, 2)]);
      await tester.pump();
      expect(find.text('JOKERS GAGNÉS'), findsOneWidget);
      expect(fx.pending(JokerKind.reveal), 2);
      expect(find.text('2'), findsNothing); // pas encore arrivée
      await _frames(tester, 1500);
      expect(find.text('JOKERS GAGNÉS'), findsOneWidget); // la bannière reste ~2 s
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
