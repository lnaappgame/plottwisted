import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cine_devinette/models/puzzle.dart';
import 'package:cine_devinette/services/ad_service.dart';
import 'package:cine_devinette/services/app_settings.dart';
import 'package:cine_devinette/services/game_state.dart';
import 'package:cine_devinette/services/save_service.dart';

GameState _state() {
  final saveService = SaveService();
  return GameState(adService: AdService(), saveService: saveService, settings: AppSettings(saveService: saveService));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('useRevealWordJoker() — pénurie de tuiles pour une lettre partagée', () {
    // Réponse synthétique à 2 mots partageant la lettre 'A' : "CAT BAT".
    // Le pool ne contient qu'une tuile par occurrence de lettre nécessaire
    // (C×1, A×2, T×2, B×1) — jamais de tuile de secours pour une lettre déjà
    // toute utilisée ailleurs. On simule ici les deux tuiles 'A' déjà
    // consommées (peu importe par quoi), pour que ni "CAT" ni "BAT" — quel
    // que soit celui tiré au hasard par le joker — ne puisse trouver de 'A'
    // libre pour sa propre case.
    late GameState game;

    setUp(() {
      game = _state();
      game.slots = 'CAT BAT'.split('').map((c) => AnswerSlot.fromChar(c)).toList();
      game.guess = List<int?>.filled(game.slots.length, null);
      game.wordRanges = [
        [0, 1, 2], // CAT
        [4, 5, 6], // BAT
      ];
      game.pool = [
        LetterTile(letter: 'C'),
        LetterTile(letter: 'A', used: true), // déjà consommée ailleurs
        LetterTile(letter: 'T'),
        LetterTile(letter: 'B'),
        LetterTile(letter: 'A', used: true), // déjà consommée ailleurs
        LetterTile(letter: 'T'),
      ];
      game.lockedWords = {};
      game.lockedSlots = {};
      game.revealWordCount = 1;
    });

    test('ne verrouille jamais un mot dont une case reste sans lettre (plus de softlock)', () {
      game.useRevealWordJoker();
      expect(game.lockedWords, isEmpty,
          reason: 'ni CAT ni BAT ne peut être entièrement révélé sans tuile A libre');
    });

    test('ne consomme pas le joker quand il ne peut pas compléter le mot', () {
      game.useRevealWordJoker();
      expect(game.revealWordCount, 1);
    });

    test('ne fait jamais pointer deux cases vers la même tuile (pas de duplication)', () {
      game.useRevealWordJoker();
      final tuilesReferencees = game.guess.whereType<int>().toList();
      expect(tuilesReferencees.toSet().length, tuilesReferencees.length);
    });

    test('remplit quand même les lettres pour lesquelles une tuile est disponible', () {
      game.useRevealWordJoker();
      // Le mot ciblé (CAT ou BAT, au hasard) doit avoir ses lettres NON-'A'
      // remplies, et sa case 'A' laissée vide plutôt que corrompue.
      final cibleCAT = game.guess[0] != null || game.guess[2] != null;
      final cibleBAT = game.guess[4] != null || game.guess[5] != null;
      expect(cibleCAT || cibleBAT, isTrue, reason: 'le joker doit avoir tenté un des deux mots');
      if (cibleCAT) {
        expect(game.guess[1], isNull); // case 'A' de CAT jamais comblée par erreur
      }
      if (cibleBAT) {
        expect(game.guess[4], isNull); // case 'A' de BAT jamais comblée par erreur
      }
    });
  });

  group('useRevealWordJoker() — réponse à un seul mot, même pénurie', () {
    late GameState game;

    setUp(() {
      // "CAT" seul (un mot) avec sa lettre 'A' déjà consommée ailleurs.
      game = _state();
      game.slots = 'CAT'.split('').map((c) => AnswerSlot.fromChar(c)).toList();
      game.guess = List<int?>.filled(game.slots.length, null);
      game.wordRanges = [
        [0, 1, 2],
      ];
      game.pool = [
        LetterTile(letter: 'C'),
        LetterTile(letter: 'A', used: true),
        LetterTile(letter: 'T'),
      ];
      game.lockedWords = {};
      game.lockedSlots = {};
      game.revealWordCount = 1;
    });

    test('ne verrouille jamais une case sans lettre disponible', () {
      // Quelle que soit la sélection aléatoire des cases à révéler, la case
      // 'A' (index 1) ne peut jamais aboutir puisqu'aucune tuile 'A' n'est
      // libre — qu'elle soit tirée ou non par le hasard, elle doit rester
      // vide et non verrouillée.
      game.useRevealWordJoker();
      expect(game.lockedSlots.contains(1), isFalse);
      expect(game.guess[1], isNull);
    });
  });

  group('onBlankTap() — curseur après suppression de lettres', () {
    late GameState game;

    setUp(() {
      game = _state();
      game.slots = 'CAT'.split('').map((c) => AnswerSlot.fromChar(c)).toList();
      game.guess = [0, 1, 2]; // les 3 cases sont remplies
      game.pool = [
        LetterTile(letter: 'C', used: true),
        LetterTile(letter: 'A', used: true),
        LetterTile(letter: 'T', used: true),
      ];
      game.wordRanges = [
        [0, 1, 2],
      ];
      game.lockedWords = {};
      game.lockedSlots = {};
    });

    test('une seule suppression : le curseur reste sur cette case', () {
      game.onBlankTap(2);
      expect(game.cursorIndex, 2);
    });

    test('deux suppressions à des positions différentes : le curseur revient à la première case vide', () {
      game.onBlankTap(2); // vide la case 2 en dernier
      game.onBlankTap(0); // vide aussi la case 0, plus tôt dans la réponse
      expect(game.cursorIndex, 0);
    });

    test("l'ordre des suppressions ne change rien : la case vide la plus à gauche gagne toujours", () {
      game.onBlankTap(0);
      game.onBlankTap(2);
      expect(game.cursorIndex, 0);
    });

    test('taper sur une case déjà vide la sélectionne explicitement, sans '
        'redirection vers la première case vide — le joueur doit pouvoir '
        'choisir n\'importe quelle case dans l\'ordre qu\'il veut', () {
      game.onBlankTap(0); // vide la case 0
      game.onBlankTap(2); // vide aussi la case 2 -> curseur revient à 0
      expect(game.cursorIndex, 0);

      game.onBlankTap(2); // la case 2 est déjà vide : sélection explicite
      expect(game.cursorIndex, 2); // pas redirigé vers la case 0
    });
  });
}
