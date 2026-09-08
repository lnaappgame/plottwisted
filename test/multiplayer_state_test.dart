import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cine_devinette/data/multiplayer_data.dart';
import 'package:cine_devinette/models/puzzle.dart';
import 'package:cine_devinette/services/app_settings.dart';
import 'package:cine_devinette/services/elo_service.dart';
import 'package:cine_devinette/services/multiplayer_matchmaking_service.dart';
import 'package:cine_devinette/services/multiplayer_state.dart';
import 'package:cine_devinette/services/save_service.dart';

final Set<String> _allIds = kMultiplayerEnigmes.map((e) => e.id).toSet();

MultiplayerState _state() {
  final saveService = SaveService();
  return MultiplayerState(
      saveService: saveService,
      matchmaking: MultiplayerMatchmakingService(),
      settings: AppSettings(saveService: saveService));
}

/// Remplit la grille avec la bonne réponse, dans l'ordre, comme le ferait un
/// joueur qui tape juste du premier coup.
void _answerCorrectly(MultiplayerState state) {
  for (var i = 0; i < state.slots.length; i++) {
    final s = state.slots[i];
    if (s.isSpace || s.isAuto) continue;
    final tile = state.pool.firstWhere((t) => !t.used && t.letter == s.char);
    state.onLetterTap(tile);
  }
}

/// Joue et gagne un match complet 2-0 le plus vite possible (répond juste à
/// chaque manche), pour tester la limite quotidienne/l'historique sans
/// attendre les temps fantômes réels.
Future<void> _gagnerMatch(MultiplayerState state) async {
  await state.startMatch();
  _answerCorrectly(state); // manche 1 : victoire (1-0)
  // La grille reste surlignée 2s, puis l'écran de résultat de manche 2s de
  // plus, avant d'enchaîner — y compris avant la manche décisive et avant
  // l'écran de résultat final (4s au total à chaque fois).
  await Future.delayed(const Duration(milliseconds: 4200));
  _answerCorrectly(state); // manche 2 : victoire (2-0), match décidé
  await Future.delayed(const Duration(milliseconds: 4200));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  test('startMatch() lance la 1ère manche avec le temps fantôme de secours '
      '(aucune vraie partie enregistrée en environnement de test)', () async {
    final state = _state();
    await state.startMatch();
    expect(state.matchActive, isTrue);
    expect(state.roundIndex, 0);
    // MultiplayerMatchmakingService n'a pas Firebase disponible en test :
    // countRunsForEnigme() renvoie toujours 0, donc toute manche utilise le
    // temps fantôme de secours (roundMaxSeconds - 5, voir kMultiplayerCalibrationMinRuns).
    expect(state.ghostSolveSeconds, state.roundMaxSeconds - 5);
    expect(state.currentEnigme, isNotNull);
    expect(state.slots, isNotEmpty);
  });

  test('pitchRevele révèle les lettres dans un ordre mélangé, pas de gauche à droite', () async {
    final state = _state();
    await state.startMatch();
    final pitch = state.currentEnigme!.pitch;
    final alnum = RegExp(r'[A-Za-z0-9]');
    final alnumPositions = [for (var i = 0; i < pitch.length; i++) if (alnum.hasMatch(pitch[i])) i];
    final totalAlnum = alnumPositions.length;
    final revealMsParChar = kMultiplayerPitchRevealMs / totalAlnum;
    final ciblePartiel = (totalAlnum / 2).floor();
    state.roundStartTime =
        DateTime.now().subtract(Duration(milliseconds: (revealMsParChar * ciblePartiel).round()));

    final revele = state.pitchRevele;
    final positionsRevelees = <int>{
      for (final i in alnumPositions)
        if (revele[i] == pitch[i]) i,
    };
    final prefixeSequentiel = alnumPositions.take(positionsRevelees.length).toSet();
    // Si l'ordre était de gauche à droite, l'ensemble des positions révélées
    // serait exactement le préfixe séquentiel du texte — ce n'est pas censé
    // être le cas avec un ordre mélangé.
    expect(positionsRevelees, isNot(equals(prefixeSequentiel)));
  });

  test('trouver la bonne réponse avant le fantôme gagne la manche', () async {
    final state = _state();
    await state.startMatch();
    _answerCorrectly(state);
    expect(state.roundResolved, isTrue);
    expect(state.roundWinner, 'joueur');
    expect(state.playerScore, 1);
    expect(state.ghostScore, 0);
  });

  test('toutes les lettres du pitch sont visibles pile à 35 secondes', () async {
    final state = _state();
    await state.startMatch();
    state.roundStartTime = DateTime.now().subtract(const Duration(seconds: 35));
    expect(state.pitchRevele, state.currentEnigme!.pitch);
  });

  test('nomAdversaireActuel vaut "Néophilis" quand le temps de secours est utilisé', () async {
    final state = _state();
    await state.startMatch();
    expect(state.nomAdversaireActuel, 'Néophilis');
  });

  test('la manche décisive surligne la grille 2s puis affiche le résultat de '
      'manche 2s avant de basculer sur le résultat final', () async {
    final state = _state();
    await state.startMatch();
    _answerCorrectly(state); // manche 1
    await Future.delayed(const Duration(milliseconds: 4200));
    _answerCorrectly(state); // manche 2, décisive (2-0)
    expect(state.roundResolved, isTrue);
    expect(state.showRoundResult, isFalse); // grille encore surlignée
    expect(state.matchOver, isFalse);
    expect(state.currentEnigme, isNotNull); // la bonne réponse reste affichable

    await Future.delayed(const Duration(milliseconds: 2100));
    expect(state.showRoundResult, isTrue); // bascule vers l'écran de résultat de manche
    expect(state.matchOver, isFalse);

    await Future.delayed(const Duration(milliseconds: 2100));
    expect(state.matchOver, isTrue); // puis bascule vers le résultat du match
  });

  test('tick() après le temps du fantôme résout la manche en sa faveur', () async {
    final state = _state();
    await state.startMatch();
    // Temps de secours = roundMaxSeconds - 5 — on simule un temps de départ
    // dans le passé, juste au-delà.
    state.roundStartTime =
        DateTime.now().subtract(Duration(milliseconds: ((state.ghostSolveSeconds! + 1) * 1000).round()));
    state.tick();
    expect(state.roundResolved, isTrue);
    expect(state.roundWinner, 'fantome');
    expect(state.ghostScore, 1);
    expect(state.playerScore, 0);
  });

  test('tick() ne résout pas la manche instantanément pendant la recherche '
      'asynchrone du fantôme (avec l\'état obsolète d\'une manche précédente '
      'encore en mémoire)', () async {
    final state = _state();
    // Simule l'état juste après une manche précédente terminée un moment
    // plus tôt : roundStartTime et ghostSolveSeconds "obsolètes" qui ne
    // doivent surtout pas être réutilisés pour la manche suivante. Chaque
    // manche passe désormais par countRunsForEnigme() (appel réseau
    // asynchrone) avant même de savoir si elle utilisera le temps de
    // secours ou une vraie recherche — la fenêtre entre la libération de
    // roundResolved et la mise à jour de roundStartTime existe donc
    // toujours, sans avoir besoin de forcer quoi que ce soit.
    state.roundStartTime = DateTime.now().subtract(const Duration(seconds: 100));
    state.ghostSolveSeconds = 10;

    final startFuture = state.startMatch(); // s'exécute jusqu'au 1er await réseau
    expect(state.roundStartTime, isNull); // sinon tick() se baserait sur l'ancien horodatage
    state.tick();
    expect(state.roundResolved, isFalse);

    await startFuture;
    expect(state.roundStartTime, isNotNull);
  });

  test('onLetterTap() ne plante pas et n\'agit pas pendant la recherche '
      'asynchrone du fantôme (même fenêtre que tick() ci-dessus)', () async {
    final state = _state();
    // Grille "obsolète" d'une manche précédente encore en mémoire pendant
    // que _startRound() cherche le prochain adversaire de façon asynchrone.
    final tuileObsolete = LetterTile(letter: 'A');
    state.roundStartTime = DateTime.now().subtract(const Duration(seconds: 100));
    state.slots = 'A'.split('').map(AnswerSlot.fromChar).toList();
    state.guess = [null];
    state.pool = [tuileObsolete];

    final startFuture = state.startMatch();
    expect(state.roundStartTime, isNull);
    // Avant le correctif, ceci déclenchait `roundStartTime!` sur null → crash.
    expect(() => state.onLetterTap(tuileObsolete), returnsNormally);
    expect(state.roundResolved, isFalse);
    expect(tuileObsolete.used, isFalse); // la tuile obsolète n'a pas été consommée

    await startFuture;
  });

  test('onBlankTap() n\'agit pas non plus pendant la recherche asynchrone du '
      'fantôme', () async {
    final state = _state();
    state.roundStartTime = DateTime.now().subtract(const Duration(seconds: 100));
    final tuileObsolete = LetterTile(letter: 'A', used: true);
    state.slots = 'A'.split('').map(AnswerSlot.fromChar).toList();
    state.guess = [0];
    state.pool = [tuileObsolete];

    final startFuture = state.startMatch();
    expect(state.roundStartTime, isNull);
    state.onBlankTap(0);
    expect(state.guess[0], 0); // pas effacé pendant la fenêtre asynchrone
    expect(tuileObsolete.used, isTrue);

    await startFuture;
  });

  group('onBlankTap() — curseur après suppression de lettres', () {
    MultiplayerState state() {
      final s = _state();
      s.roundStartTime = DateTime.now();
      s.roundResolved = false;
      s.slots = 'CAT'.split('').map(AnswerSlot.fromChar).toList();
      s.guess = [0, 1, 2];
      s.pool = [
        LetterTile(letter: 'C', used: true),
        LetterTile(letter: 'A', used: true),
        LetterTile(letter: 'T', used: true),
      ];
      return s;
    }

    test('une seule suppression : le curseur reste sur cette case', () {
      final s = state();
      s.onBlankTap(2);
      expect(s.cursorIndex, 2);
    });

    test('deux suppressions à des positions différentes : le curseur revient à la première case vide', () {
      final s = state();
      s.onBlankTap(2); // vide la case 2 en dernier
      s.onBlankTap(0); // vide aussi la case 0, plus tôt dans la réponse
      expect(s.cursorIndex, 0);
    });

    test('taper sur une case déjà vide la sélectionne explicitement, sans '
        'redirection vers la première case vide', () {
      final s = state();
      s.onBlankTap(0); // vide la case 0
      s.onBlankTap(2); // vide aussi la case 2 -> curseur revient à 0
      expect(s.cursorIndex, 0);

      s.onBlankTap(2); // la case 2 est déjà vide : sélection explicite
      expect(s.cursorIndex, 2); // pas redirigé vers la case 0
    });
  });

  test('personne ne trouve dans le temps imparti : égalité, les deux gagnent le point', () async {
    final state = _state();
    await state.startMatch();
    state.ghostSolveSeconds = null; // le fantôme ne trouve pas non plus
    state.roundStartTime =
        DateTime.now().subtract(Duration(milliseconds: ((state.roundMaxSeconds + 1) * 1000).round()));
    state.tick();
    expect(state.roundResolved, isTrue);
    expect(state.roundWinner, 'egalite');
    expect(state.playerScore, 1);
    expect(state.ghostScore, 1);
  });

  test('un match se termine dès 2 points et met à jour l\'Elo (K=40 avec le '
      'temps de secours)', () async {
    final state = _state();
    final eloDepart = state.eloRating;
    await state.startMatch();
    _answerCorrectly(state); // manche 1 gagnée
    await Future.delayed(const Duration(milliseconds: 4200)); // laisse _startRound() s'enchaîner
    expect(state.matchOver, isFalse);
    expect(state.playerScore, 1);
    _answerCorrectly(state); // manche 2 gagnée -> match plié 2-0
    expect(state.matchOver, isFalse); // la grille puis le résultat de manche restent affichés 4s
    await Future.delayed(const Duration(milliseconds: 4200));
    expect(state.matchOver, isTrue);
    expect(state.matchResult, 'victoire');
    // Temps de secours : adversaire présumé au même Elo que le joueur -> expectedScore=0.5.
    expect(state.eloRating, eloDepart + 20); // 40*(1-0.5)
    expect(state.eloAvantMatch, eloDepart);
    expect(state.eloApresMatch, state.eloRating);
  });

  test('titreActuel reflète le palier Elo courant', () {
    final state = _state();
    expect(state.titreActuel, titreForElo(state.eloRating));
  });

  test('toJson()/restore() conservent le classement', () async {
    final state = _state();
    await _gagnerMatch(state);
    expect(state.matchOver, isTrue);

    final restored = _state();
    final json = state.toJson();
    restored.eloRating = json['eloRating'] as int;
    restored.matchesPlayed = json['matchesPlayed'] as int;

    expect(restored.eloRating, state.eloRating);
    expect(restored.matchesPlayed, 1);
  });

  test('matchesRestantes diminue à chaque match et bloque au-delà de 5 par jour', () async {
    final state = _state();
    expect(state.matchesRestantes, kMultiplayerMatchesBaseParJour);
    for (var i = 0; i < kMultiplayerMatchesBaseParJour; i++) {
      await _gagnerMatch(state);
    }
    expect(state.matchesRestantes, 0);
    expect(state.matchesPlayed, kMultiplayerMatchesBaseParJour);

    final matchesAvant = state.matchesPlayed;
    await state.startMatch(); // refusé : quota du jour épuisé
    expect(state.matchesPlayed, matchesAvant);
    expect(state.matchActive, isFalse);
    // _gagnerMatch() attend ~8,4s réelles par match (2 manches x 4,2s) ; ce
    // test en enchaîne 5, largement au-delà du timeout par défaut de 30s.
  }, timeout: const Timeout(Duration(seconds: 90)));

  test('onAdMatchRewarded donne une partie de plus, jusqu\'à 5 pubs par jour', () async {
    final state = _state();
    for (var i = 0; i < kMultiplayerMatchesBaseParJour; i++) {
      await _gagnerMatch(state);
    }
    expect(state.matchesRestantes, 0);
    expect(state.peutRegarderPubMatch, isTrue);

    state.onAdMatchRewarded();
    expect(state.matchesRestantes, 1);
    expect(state.adsWatchedForMatchesToday, 1);

    for (var i = 1; i < kMultiplayerAdsMaxParJour; i++) {
      state.onAdMatchRewarded();
    }
    expect(state.adsWatchedForMatchesToday, kMultiplayerAdsMaxParJour);
    expect(state.peutRegarderPubMatch, isFalse);
    // Une 6e pub n'ajoute rien de plus.
    state.onAdMatchRewarded();
    expect(state.adsWatchedForMatchesToday, kMultiplayerAdsMaxParJour);
  }, timeout: const Timeout(Duration(seconds: 90)));

  test('historique enregistre chaque match, le plus récent en premier', () async {
    final state = _state();
    await _gagnerMatch(state);
    expect(state.historique.length, 1);
    expect(state.historique.first.resultat, 'victoire');
    expect(state.historique.first.eloApres, state.eloRating);
    expect(state.historique.first.delta, state.eloRating - state.historique.first.eloAvant);

    final premiereEntree = state.historique.first;
    await _gagnerMatch(state);
    expect(state.historique.length, 2);
    expect(state.historique.first.eloAvant, premiereEntree.eloApres);
    expect(state.historique[1], premiereEntree);
  });

  test('returnToIntro() efface le résultat du dernier match sans toucher au classement', () async {
    final state = _state();
    await _gagnerMatch(state);
    expect(state.matchOver, isTrue);
    final eloApres = state.eloRating;
    final historiqueApres = state.historique.length;

    state.returnToIntro();
    expect(state.matchOver, isFalse);
    expect(state.matchActive, isFalse);
    expect(state.eloRating, eloApres);
    expect(state.historique.length, historiqueApres);
  });

  test('_piocherEnigme() ne répète jamais une énigme avant d\'avoir tout couvert', () async {
    final state = _state();
    final derniereRestante = _allIds.first;
    state.historiquePioche = _allIds.difference({derniereRestante});
    expect(state.historiquePioche.length, _allIds.length - 1);

    await state.startMatch();

    expect(state.currentEnigme!.id, derniereRestante);
    expect(state.historiquePioche, _allIds); // le cycle est désormais complet
  });

  test('_piocherEnigme() recommence un nouveau cycle une fois le pool épuisé', () async {
    final state = _state();
    state.historiquePioche = Set<String>.from(_allIds); // cycle déjà complet

    await state.startMatch();

    // Le cycle précédent a été effacé puis une seule énigme piochée pour le
    // nouveau cycle qui démarre.
    expect(state.historiquePioche.length, 1);
    expect(_allIds.contains(state.currentEnigme!.id), isTrue);
  });

  test('historiquePioche est conservé par toJson()/restore()', () async {
    final state = _state();
    state.historiquePioche = {'mp-021', 'mp-099'};
    final json = state.toJson();

    final restored = _state();
    final histPioche = (json['historiquePioche'] as List).cast<String>().toSet();
    restored.historiquePioche = histPioche;

    expect(restored.historiquePioche, {'mp-021', 'mp-099'});
  });

  test('ensureFreshDay() remet les compteurs à zéro le lendemain (GMT)', () {
    final state = _state();
    state.matchesUsedToday = kMultiplayerMatchesBaseParJour;
    state.lastMatchDay = DateTime.now().toUtc().subtract(const Duration(days: 1));
    state.adsWatchedForMatchesToday = 3;
    state.lastMatchAdDay = DateTime.now().toUtc().subtract(const Duration(days: 1));
    state.ensureFreshDay();
    expect(state.matchesUsedToday, 0);
    expect(state.adsWatchedForMatchesToday, 0);
    expect(state.matchesRestantes, kMultiplayerMatchesBaseParJour);
  });
}
