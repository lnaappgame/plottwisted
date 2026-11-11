import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cine_devinette/data/puzzles_data.dart';
import 'package:cine_devinette/models/puzzle.dart';
import 'package:cine_devinette/services/ad_service.dart';
import 'package:cine_devinette/services/app_settings.dart';
import 'package:cine_devinette/services/game_state.dart';
import 'package:cine_devinette/services/save_service.dart';
import 'package:cine_devinette/widgets/answer_row.dart';

// Monde « Enfants stars » : le joueur trouve le film ET le nom de l'enfant
// star. La grille est construite sur « titre · nom ».

GameState _newGame() {
  final saveService = SaveService();
  final settings = AppSettings(saveService: saveService)
    ..sfxOn = false
    ..vibrationsOn = false;
  return GameState(adService: AdService(), saveService: saveService, settings: settings);
}

GameWorld get _extraWorld => kWorlds.firstWhere((w) => w.puzzles.any((p) => p.extraAnswer.isNotEmpty));

void _open(GameState game, GameWorld world, int level) {
  game.enterWorld(world.number);
  game.currentLevelNumber = level;
  game.loadPuzzle();
}

String _answer(GameState game) => game.slots.map((s) => s.char).join();

/// Place les bonnes lettres dans le mot [w] (ou de mauvaises si [wrong]).
void _fillWord(GameState game, int w, {bool wrong = false}) {
  for (final i in game.wordRanges[w]) {
    if (game.slots[i].isAuto || game.guess[i] != null) continue;
    final idx = game.pool.indexWhere((t) => !t.used && !t.eliminated && (t.letter == game.slots[i].char) != wrong);
    expect(idx, isNot(-1), reason: 'pas de tuile pour la case $i');
    game.guess[i] = idx;
    game.pool[idx].used = true;
  }
}

List<int> _punctuationWords(GameState game) => [
      for (var w = 0; w < game.wordRanges.length; w++)
        if (game.wordRanges[w].every((i) => game.slots[i].isAuto)) w
    ];

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('answerFor : le titre seul, ou « titre · réponse bonus »', () {
    const p = PersonRef(real: 'x', actor: 'y');
    const plain = Puzzle(
        title: 'ROCKY', titleUs: 'ROCKY', year: '1977', pitchTemplate: '{p1}', p1: p, p2: p,
        p1InitialColor: NameColor.green, p2InitialColor: NameColor.green);
    expect(plain.answerFor('fr'), 'ROCKY');
    expect(plain.answerFor('en'), 'ROCKY');

    const extra = Puzzle(
        title: 'LÉON', titleUs: 'THE PROFESSIONAL', year: '1994', pitchTemplate: '{p1}', p1: p, p2: p,
        p1InitialColor: NameColor.red, p2InitialColor: NameColor.red,
        extraAnswer: 'NATALIE PORTMAN', extraAnswerUs: 'NATALIE PORTMAN');
    expect(extra.answerFor('fr'), 'LÉON · NATALIE PORTMAN');
    expect(extra.answerFor('en'), 'THE PROFESSIONAL · NATALIE PORTMAN');
    expect(extra.titleFor('fr'), 'LÉON', reason: 'le titre reste celui du film seul');
  });

  test('un seul monde a une réponse bonus : ses 10 niveaux, avec le libellé du monde', () {
    final worlds = kWorlds.where((w) => w.puzzles.any((p) => p.extraAnswer.isNotEmpty)).toList();
    expect(worlds, hasLength(1));
    final world = worlds.single;
    expect(world.extraLabel, isNotEmpty);
    expect(world.extraLabelUs, isNotEmpty);
    expect(world.extraRuleFor('fr'), contains(world.extraLabel));
    expect(world.extraRuleFor('en'), contains(world.extraLabelUs));
    for (final p in world.puzzles) {
      expect(p.extraAnswer, isNotEmpty, reason: p.title);
      expect(p.extraAnswerUs, isNotEmpty, reason: p.title);
      expect(p.title, isNot(contains(kAnswerSeparator)));
      expect(p.titleUs, isNot(contains(kAnswerSeparator)));
    }
    // Aucun titre du jeu ne contient le séparateur.
    for (final w in kWorlds) {
      for (final p in w.puzzles) {
        expect('${p.title}${p.titleUs}${p.extraAnswer}${p.extraAnswerUs}', isNot(contains(kAnswerSeparator)));
      }
    }
  });

  test('réponse bonus = nom de l\'acteur d\'un des deux personnages, jamais affiché en bleu au départ', () {
    String norm(String s) => normalize(s).replaceAll(RegExp(r'[^A-Z0-9]'), '');
    for (final p in _extraWorld.puzzles) {
      for (final loc in ['fr', 'en']) {
        final extra = norm(p.extraAnswerFor(loc));
        final isP1 = norm(p.p1.actorFor(loc)) == extra;
        final isP2 = norm(p.p2.actorFor(loc)) == extra;
        expect(isP1 || isP2, isTrue, reason: '${p.titleFor(loc)} ($loc) : ${p.extraAnswerFor(loc)} n\'est l\'acteur d\'aucun nom');
        final person = isP1 ? p.p1 : p.p2;
        final color = isP1 ? p.p1InitialColor : p.p2InitialColor;
        expect(color, isNot(NameColor.blue), reason: p.titleFor(loc));
        // Champ de la couleur de départ rempli : sinon le jeu se replie sur
        // le bleu et affiche l'acteur, donc la réponse.
        expect(person.displayFor(color, loc).trim(), isNotEmpty, reason: p.titleFor(loc));
      }
    }
  });

  test('la grille porte le titre puis le nom ; le séparateur est verrouillé d\'office', () {
    final game = _newGame();
    _open(game, _extraWorld, 1);
    final puzzle = game.currentPuzzle;
    expect(_answer(game), normalize(puzzle.answerFor('fr')));
    expect(_answer(game), contains(' $kAnswerSeparator '));

    final punctuation = _punctuationWords(game);
    expect(punctuation, isNotEmpty);
    expect(game.lockedWords, punctuation.toSet());
    expect(game.extraAnswerCaption, _extraWorld.extraLabel);
  });

  test('le film trouvé se verrouille même si le nom est faux, et la ligne de tentative ignore le séparateur', () {
    final game = _newGame();
    _open(game, _extraWorld, 1);
    final sep = game.slots.indexWhere((s) => s.char == kAnswerSeparator);
    final filmWords = [
      for (var w = 0; w < game.wordRanges.length; w++)
        if (game.wordRanges[w].last < sep) w
    ];
    final nameWords = [
      for (var w = 0; w < game.wordRanges.length; w++)
        if (game.wordRanges[w].first > sep) w
    ];
    for (final w in filmWords) {
      _fillWord(game, w);
    }
    for (final w in nameWords) {
      _fillWord(game, w, wrong: true);
    }

    expect(game.validate(), 'wrong');
    expect(game.lockedWords.containsAll(filmWords), isTrue);
    expect(game.lockedWords.intersection(nameWords.toSet()), isEmpty);
    expect(game.attemptRows.single, hasLength(filmWords.length + nameWords.length));
    expect(game.attemptRows.single, [...filmWords.map((_) => true), ...nameWords.map((_) => false)]);

    for (final w in nameWords) {
      _fillWord(game, w);
    }
    expect(game.validate(), 'solved');
  });

  test('le joker « Révéler un mot » ne se dépense jamais sur le séparateur', () {
    for (var run = 0; run < 40; run++) {
      final game = _newGame();
      _open(game, _extraWorld, 1 + run % 10);
      game.revealWordCount = 1;
      final before = Set.of(game.lockedWords);
      final revealed = game.useRevealWordJoker();
      expect(revealed, isNotEmpty, reason: 'joker dépensé sans rien révéler (tirage $run)');
      expect(game.revealWordCount, 0);
      final newlyLocked = game.lockedWords.difference(before);
      for (final w in newlyLocked) {
        expect(game.wordRanges[w].any((i) => !game.slots[i].isAuto), isTrue);
      }
    }
  });

  test('titres existants avec un signe isolé (« P.S. : I LOVE YOU ») : le joker révèle un vrai mot', () {
    GameWorld? world;
    int? level;
    for (final w in kWorlds) {
      final i = w.puzzles.indexWhere((p) => p.title.contains(' : ') && p.extraAnswer.isEmpty);
      if (i != -1) {
        world = w;
        level = i + 1;
        break;
      }
    }
    expect(world, isNotNull, reason: 'plus aucun titre avec « : » isolé : test à adapter');
    for (var run = 0; run < 40; run++) {
      final game = _newGame();
      _open(game, world!, level!);
      expect(game.lockedWords, _punctuationWords(game).toSet());
      game.revealWordCount = 1;
      expect(game.useRevealWordJoker(), isNotEmpty, reason: 'tirage $run');
    }
  });

  test('sauvegarde d\'avant la mise à jour (séparateur non verrouillé) : reprise sans décalage', () async {
    final saveService = SaveService();
    AppSettings settings() => AppSettings(saveService: saveService)
      ..sfxOn = false
      ..vibrationsOn = false;
    final world = kWorlds.firstWhere((w) => w.puzzles.any((p) => p.title.contains(' : ') && p.extraAnswer.isEmpty));
    final level = world.puzzles.indexWhere((p) => p.title.contains(' : ')) + 1;

    final seed = GameState(adService: AdService(), saveService: saveService, settings: settings());
    _open(seed, world, level);
    _fillWord(seed, 0);
    for (var w = 1; w < seed.wordRanges.length; w++) {
      _fillWord(seed, w, wrong: true);
    }
    expect(seed.validate(), 'wrong');
    await seed.flushSave();
    final save = seed.toJson();
    // Une ancienne version n'avait verrouillé que le premier mot.
    (save['level'] as Map)['lockedWords'] = [0];
    await saveService.save(save);

    final game = GameState(adService: AdService(), saveService: saveService, settings: settings());
    await game.restore();
    game.loadPuzzle();
    expect(game.lockedWords, {0, ..._punctuationWords(game)});
  });

  test('changer de langue sur un niveau à réponse bonus : nouvelle grille quand la réponse change', () {
    final game = _newGame();
    final world = _extraWorld;
    final level = world.puzzles.indexWhere((p) => normalize(p.answerFor('fr')) != normalize(p.answerFor('en'))) + 1;
    expect(level, greaterThan(0));
    _open(game, world, level);
    game.settings.setLocale('en');
    expect(game.locale, 'en');
    expect(_answer(game), normalize(game.currentPuzzle.answerFor('en')));
    expect(game.lockedWords, _punctuationWords(game).toSet());
    expect(game.extraAnswerCaption, world.extraLabelUs);
  });

  group('affichage sur petit téléphone (320 px de large)', () {
    Future<void> pump(WidgetTester tester, GameWorld world, int level, String locale, {double scale = 1.0}) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final saveService = SaveService();
      final settings = AppSettings(saveService: saveService)
        ..sfxOn = false
        ..vibrationsOn = false;
      if (locale == 'en') settings.setLocale('en');
      final game = GameState(adService: AdService(), saveService: saveService, settings: settings);
      _open(game, world, level);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: settings),
            ChangeNotifierProvider.value(value: game),
          ],
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: const Scaffold(
              body: SingleChildScrollView(child: Padding(padding: EdgeInsets.all(12), child: AnswerRow())),
            ),
          ),
        ),
      );
      await tester.pump();
      // Laisse partir la sauvegarde différée (600 ms) déclenchée par loadPuzzle.
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets('la légende « + l\'enfant star » sépare le film du nom', (tester) async {
      final world = _extraWorld;
      await pump(tester, world, 1, 'fr');
      expect(tester.takeException(), isNull);
      final caption = find.byKey(const ValueKey('extra-answer-caption'));
      expect(caption, findsOneWidget);
      expect(tester.widget<Text>(caption).data, '+ ${world.extraLabel}');
      // Le nom commence sous la légende, le film est au-dessus.
      final captionY = tester.getCenter(caption).dy;
      final tiles = find.byType(GestureDetector);
      expect(tester.getCenter(tiles.first).dy, lessThan(captionY));
      expect(tester.getCenter(tiles.last).dy, greaterThan(captionY));
      // Le séparateur n'est pas affiché comme une case.
      expect(find.text(kAnswerSeparator), findsNothing);
    });

    testWidgets('les 10 niveaux tiennent, en français et en anglais, texte normal et agrandi', (tester) async {
      final world = _extraWorld;
      for (final locale in ['fr', 'en']) {
        for (final scale in [1.0, 1.3]) {
          for (var level = 1; level <= world.puzzles.length; level++) {
            await pump(tester, world, level, locale, scale: scale);
            expect(tester.takeException(), isNull,
                reason: '${world.puzzles[level - 1].answerFor(locale)} ($locale, x$scale)');
            final size = tester.getSize(find.byType(AnswerRow));
            expect(size.width, lessThanOrEqualTo(320 - 24 + 0.01));
          }
        }
      }
    });
  });
}
