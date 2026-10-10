import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cine_devinette/data/puzzles_data.dart';
import 'package:cine_devinette/l10n/app_localizations.dart';
import 'package:cine_devinette/services/ad_service.dart';
import 'package:cine_devinette/services/app_settings.dart';
import 'package:cine_devinette/services/game_state.dart';
import 'package:cine_devinette/services/save_service.dart';
import 'package:cine_devinette/services/sound_service.dart';
import 'package:cine_devinette/widgets/joker_bar.dart';
import 'package:cine_devinette/widgets/joker_fx.dart';

GameState _game() {
  final saveService = SaveService();
  return GameState(adService: AdService(), saveService: saveService, settings: AppSettings(saveService: saveService));
}

/// Ouvre le premier niveau dont le titre (FR) compte un seul mot, ou plusieurs.
void _openLevel(GameState game, {required bool oneWord}) {
  for (final world in kWorlds) {
    for (final (i, puzzle) in world.puzzles.indexed) {
      if (!puzzle.title.contains(' ') != oneWord) continue;
      game.enterWorld(world.number);
      game.currentLevelNumber = i + 1;
      game.loadPuzzle();
      return;
    }
  }
}

Future<void> _pumpBar(WidgetTester tester, GameState game, Future<bool> Function() confirm) async {
  await tester.pumpWidget(MultiProvider(
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
        body: JokerBar(
          fx: JokerFx(),
          onWatchAdForJoker: () {},
          onRedJokerEmpty: () {},
          confirmRevealWordNerf: confirm,
        ),
      ),
    ),
  ));
  await tester.pump();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Conseil « tuiles ou clavier »', () {
    test('pas pendant les niveaux 1 à 3 du tutoriel, oui à partir du niveau 4', () {
      final game = _game()..enterWorld(0);
      for (final niveau in [1, 2, 3]) {
        game.currentLevelNumber = niveau;
        expect(game.inputModeTipDue, isFalse, reason: 'niveau $niveau');
      }
      game.currentLevelNumber = 4;
      expect(game.inputModeTipDue, isTrue);
    });

    test('tutoriel sauté (1-1) ou joueur déjà plus loin : oui, une seule fois', () {
      final game = _game()..enterWorld(1);
      game.currentLevelNumber = 1;
      expect(game.inputModeTipDue, isTrue);
      game.enterWorld(7);
      expect(game.inputModeTipDue, isTrue);
      game.settings.markInputModeTipShown();
      expect(game.inputModeTipDue, isFalse);
    });

    test('le conseil déjà vu est retenu après redémarrage', () async {
      final saveService = SaveService();
      final settings = AppSettings(saveService: saveService)..markInputModeTipShown();
      await saveService.saveSettings(settings.toJson());
      final reloaded = AppSettings(saveService: saveService);
      await reloaded.restore();
      expect(reloaded.inputModeTipShown, isTrue);
    });
  });

  group('« Révéler un mot » sur un titre d\'un seul mot', () {
    test('un seul mot : réduit à un tiers des lettres ; plusieurs mots : non', () {
      final game = _game();
      _openLevel(game, oneWord: true);
      expect(game.revealWordIsNerfed, isTrue);
      final lettres = game.slots.where((s) => !s.isSpace && !s.isAuto).length;
      expect(game.revealWordNerfCount, (lettres / 3).ceil());
      _openLevel(game, oneWord: false);
      expect(game.revealWordIsNerfed, isFalse);
    });

    testWidgets('première fois : on demande ; « Annuler » garde le joker', (tester) async {
      final game = _game();
      _openLevel(game, oneWord: true);
      game.revealWordCount = 1;
      var asked = 0;
      await _pumpBar(tester, game, () async {
        asked++;
        game.markRevealWordNerfExplained(); // comme le pop-up de l'écran de jeu
        return false;
      });
      await tester.tap(find.text('RÉVÉLER UN MOT'));
      await tester.pump();
      expect(asked, 1);
      expect(game.revealWordCount, 1);
      // Fois suivante : plus de question, le joker est utilisé.
      await tester.tap(find.text('RÉVÉLER UN MOT'));
      await tester.pump();
      expect(asked, 1);
      expect(game.revealWordCount, 0);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('« Utiliser quand même » utilise le joker', (tester) async {
      final game = _game();
      _openLevel(game, oneWord: true);
      game.revealWordCount = 1;
      await _pumpBar(tester, game, () async => true);
      await tester.tap(find.text('RÉVÉLER UN MOT'));
      await tester.pump();
      expect(game.revealWordCount, 0);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('titre en plusieurs mots : jamais de question', (tester) async {
      final game = _game();
      _openLevel(game, oneWord: false);
      game.revealWordCount = 1;
      var asked = 0;
      await _pumpBar(tester, game, () async {
        asked++;
        return true;
      });
      await tester.tap(find.text('RÉVÉLER UN MOT'));
      await tester.pump();
      expect(asked, 0);
      expect(game.revealWordCount, 0);
      await tester.pump(const Duration(seconds: 2));
    });
  });
}
