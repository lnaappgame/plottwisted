import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cine_devinette/data/enigmes_data.dart';
import 'package:cine_devinette/models/enigme.dart';
import 'package:cine_devinette/services/ad_service.dart';
import 'package:cine_devinette/services/app_settings.dart';
import 'package:cine_devinette/services/enigme_service.dart';
import 'package:cine_devinette/services/enigme_state.dart';
import 'package:cine_devinette/services/game_state.dart';
import 'package:cine_devinette/services/leaderboard_service.dart' show weekIdFor;
import 'package:cine_devinette/services/save_service.dart';

EnigmeState _state({int heuresEcoulees = 0, int index = 0}) {
  final saveService = SaveService();
  final state = EnigmeState(saveService: saveService, settings: AppSettings(saveService: saveService));
  state.currentIndex = index;
  state.currentWeekStart = DateTime.now().subtract(Duration(hours: heuresEcoulees));
  state.rebuildTiles();
  return state;
}

void main() {
  test('enigmeIndexFor est déterministe pour une même semaine', () {
    final a = enigmeIndexFor(DateTime(2026, 3, 10));
    final b = enigmeIndexFor(DateTime(2026, 3, 12));
    expect(a, b); // même semaine (mardi/jeudi)
    expect(a, inInclusiveRange(0, kEnigmes.length - 1));
  });

  test('enigmeIndexFor change bien de semaine en semaine', () {
    final a = enigmeIndexFor(DateTime(2026, 3, 9)); // lundi
    final b = enigmeIndexFor(DateTime(2026, 3, 16)); // lundi suivant
    expect(a == b, isFalse);
  });

  test('à 0 heure écoulée, seules les 10 lettres de départ sont révélées', () {
    final state = _state(heuresEcoulees: 0);
    // Aucun symbole distinct (comme '•') ne doit trahir où sont les lettres
    // cachées : tout le reste doit être un espace, indiscernable des vrais
    // espaces entre les mots. On ne compte que les caractères alphanumériques
    // révélés (pas la ponctuation, qui accompagne automatiquement la lettre
    // qui la précède et gonflerait sinon ce compte selon le texte tombé).
    final alnum = RegExp(r'[A-Za-z0-9]');
    final revealed = state.texteRevele.split('').where((c) => alnum.hasMatch(c)).length;
    expect(revealed, kEnigmeLettresDepart);
  });

  test('après N heures, 10 + N caractères alphanumériques sont révélés', () {
    final state = _state(heuresEcoulees: 20, index: 22); // APOCALYPSE NOW
    final revealedLetters = state.texteRevele.split('').where((c) => c != ' ').length;
    // Peut légèrement dépasser 10+N : la ponctuation apparaît automatiquement
    // dès que la lettre qui la précède est révélée (voir texteRevele).
    expect(revealedLetters, greaterThanOrEqualTo(kEnigmeLettresDepart + 20));
    expect(revealedLetters, lessThan(kEnigmeLettresDepart + 20 + 5));
  });

  test('la pub "lettre" et la pub "tentative" sont indépendantes', () {
    final state = _state(heuresEcoulees: 5, index: 78);
    final avant = state.texteRevele.split('').where((c) => c != ' ').length;
    expect(state.tentativesRestantes, 1);

    state.onAdLettreRewarded();
    final apresLettre = state.texteRevele.split('').where((c) => c != ' ').length;
    expect(apresLettre, avant + 1);
    expect(state.tentativesRestantes, 1); // inchangé : cette pub ne donne pas de tentative

    state.onAdTentativeRewarded();
    expect(state.tentativesRestantes, 2);
    final apresTentative = state.texteRevele.split('').where((c) => c != ' ').length;
    expect(apresTentative, avant + 1); // inchangé : cette pub ne révèle pas de lettre
  });

  test('l\'ordre de révélation n\'est pas l\'ordre du texte (mais reste stable)', () {
    final state = _state(heuresEcoulees: 30, index: 78); // TITANIC
    final revealed = state.texteRevele;

    // Ce à quoi ressemblerait une révélation strictement séquentielle.
    final alnum = RegExp(r'[A-Za-z0-9]');
    var n = 0;
    final totalSequentiel = kEnigmeLettresDepart + 30;
    final sequentiel = state.enigme.texte.split('').map((c) {
      if (c == ' ') return ' ';
      if (!alnum.hasMatch(c)) return c; // ponctuation simplifiée pour la comparaison
      n++;
      return n <= totalSequentiel ? c : ' ';
    }).join();

    expect(revealed == sequentiel, isFalse);

    // Mais l'ordre doit être stable (même énigme, même heures écoulées).
    final rejoue = _state(heuresEcoulees: 30, index: 78);
    expect(rejoue.texteRevele, revealed);
  });

  test('tempsAvantProchaineLettre compte jusqu\'à la prochaine heure pleine', () {
    final state = _state(heuresEcoulees: 5, index: 78);
    // On vient de démarrer une nouvelle heure il y a 0 seconde dans ce test
    // (currentWeekStart = maintenant - 5h pile), donc la prochaine lettre
    // doit arriver dans un temps proche de 1h (à quelques ms près).
    expect(state.tempsAvantProchaineLettre.inMinutes, inInclusiveRange(58, 60));
  });

  test('tempsAvantProchaineLettre est nul une fois tout révélé', () {
    final state = _state(heuresEcoulees: 24 * 7, index: 30); // JAMES BOND, tout révélé
    expect(state.tempsAvantProchaineLettre, Duration.zero);
  });

  test('le badge (année) ne se révèle qu\'une fois le texte épuisé', () {
    // APOCALYPSE NOW : 138 caractères alphanumériques + badge "1979" (4
    // chiffres), avec 10 lettres déjà acquises au départ (kEnigmeLettresDepart).
    final presqueFini = _state(heuresEcoulees: 138 - kEnigmeLettresDepart, index: 22);
    expect(presqueFini.badgeRevele, '••••');
    final unPeuPlus = _state(heuresEcoulees: 140 - kEnigmeLettresDepart, index: 22);
    expect(unPeuPlus.badgeRevele, '19••');
  });

  test('valider() : incomplet puis correct', () {
    final state = _state(heuresEcoulees: 0, index: 30); // JAMES BOND
    expect(state.valider(), 'incomplete');
    // Remplit la grille avec la bonne réponse en tapant les tuiles dans l'ordre du pool.
    final cible = state.slots.map((s) => s.isSpace ? ' ' : s.char).join();
    for (final ch in cible.split('')) {
      if (ch == ' ') continue;
      final tile = state.pool.firstWhere((t) => !t.used && t.letter == ch);
      state.onLetterTap(tile);
    }
    expect(state.valider(), 'solved');
    expect(state.solved, isTrue);
    expect(state.solvedDay, 1);
  });

  test('barème de récompense J1 = un joker de chaque type', () {
    final saveService = SaveService();
    final game = GameState(adService: AdService(), saveService: saveService, settings: AppSettings(saveService: saveService));
    final labels = appliquerRecompenseEnigme(1, game);
    expect(labels.length, 6);
    expect(game.revealCount, 1);
    expect(game.eliminateCount, 1);
    expect(game.characterCount, 1);
    expect(game.actorCount, 1);
    expect(game.hintCount, 1);
    expect(game.revealWordCount, 1);
  });

  test('valider() : une résolution archive une entrée d\'historique', () {
    final state = _state(heuresEcoulees: 0, index: 30); // JAMES BOND
    expect(state.historique, isEmpty);
    final cible = state.slots.map((s) => s.isSpace ? ' ' : s.char).join();
    for (final ch in cible.split('')) {
      if (ch == ' ') continue;
      final tile = state.pool.firstWhere((t) => !t.used && t.letter == ch);
      state.onLetterTap(tile);
    }
    state.valider();
    expect(state.historique.length, 1);
    final entry = state.historique.first;
    expect(entry.sujet, state.enigme.sujet);
    expect(entry.solvedDay, 1);
    expect(entry.rang, isNull); // pas encore connu tant que recordRang() n'a pas été appelé
    expect(entry.total, isNull);
  });

  test('recordRang() complète l\'entrée de la semaine en cours', () {
    final state = _state(heuresEcoulees: 0, index: 30);
    final cible = state.slots.map((s) => s.isSpace ? ' ' : s.char).join();
    for (final ch in cible.split('')) {
      if (ch == ' ') continue;
      final tile = state.pool.firstWhere((t) => !t.used && t.letter == ch);
      state.onLetterTap(tile);
    }
    state.valider();
    state.recordRang(rang: 3, total: 812);
    expect(state.historique.first.rang, 3);
    expect(state.historique.first.total, 812);
    expect(state.meilleurClassement?.rang, 3);
    expect(state.meilleurTemps?.solveSeconds, state.historique.first.solveSeconds);
  });

  test('meilleurClassement et meilleurTemps ignorent les entrées sans classement connu', () {
    final state = _state(heuresEcoulees: 0, index: 30);
    state.historique = [
      const EnigmeHistoryEntry(weekId: '2026-08-03', sujet: 'A', solveSeconds: 500, solvedDay: 2, rang: 10, total: 100),
      const EnigmeHistoryEntry(weekId: '2026-08-10', sujet: 'B', solveSeconds: 100, solvedDay: 1, rang: null, total: null),
      const EnigmeHistoryEntry(weekId: '2026-08-17', sujet: 'C', solveSeconds: 900, solvedDay: 3, rang: 2, total: 50),
    ];
    expect(state.meilleurClassement?.sujet, 'C'); // rang 2 < rang 10, l'entrée sans rang est ignorée
    expect(state.meilleurTemps?.sujet, 'B'); // 100s est le plus rapide, même sans classement connu
  });

  test('toJson()/restore() conservent l\'historique', () async {
    final state = _state(heuresEcoulees: 0, index: 30);
    final cible = state.slots.map((s) => s.isSpace ? ' ' : s.char).join();
    for (final ch in cible.split('')) {
      if (ch == ' ') continue;
      final tile = state.pool.firstWhere((t) => !t.used && t.letter == ch);
      state.onLetterTap(tile);
    }
    state.valider();
    state.recordRang(rang: 1, total: 5);

    final restoredSaveService = SaveService();
    final restored = EnigmeState(saveService: restoredSaveService, settings: AppSettings(saveService: restoredSaveService));
    final json = state.toJson();
    restored.currentIndex = json['currentIndex'] as int;
    restored.currentWeekStart = DateTime.parse(json['currentWeekStart'] as String);
    restored.historique = (json['historique'] as List)
        .map((e) => EnigmeHistoryEntry.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    expect(restored.historique.length, 1);
    expect(restored.historique.first.rang, 1);
    expect(restored.historique.first.sujet, state.enigme.sujet);
  });

  test('barème de récompense J7 = un seul joker mineur', () {
    final saveService = SaveService();
    final game = GameState(adService: AdService(), saveService: saveService, settings: AppSettings(saveService: saveService));
    final labels = appliquerRecompenseEnigme(7, game);
    expect(labels.length, 1);
    final totalMineurs = game.revealCount + game.eliminateCount + game.characterCount;
    final totalMajeurs = game.actorCount + game.hintCount + game.revealWordCount;
    expect(totalMineurs, 1);
    expect(totalMajeurs, 0);
  });

  group('Bilan de fin de semaine', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    setUp(() => SharedPreferences.setMockInitialValues({}));

    // État d'une semaine passée ([semainesAvant] semaines avant la semaine en cours).
    EnigmeState semainePassee({int semainesAvant = 1, bool trouvee = true, bool participe = true}) {
      final now = DateTime.now();
      final debut = enigmeWeekStart(now).subtract(Duration(days: 7 * semainesAvant));
      final saveService = SaveService();
      final state = EnigmeState(saveService: saveService, settings: AppSettings(saveService: saveService))
        ..currentIndex = enigmeIndexFor(debut)
        ..currentWeekStart = debut
        ..participated = participe
        ..solved = trouvee
        ..solvedDay = trouvee ? 2 : null
        ..solveSeconds = trouvee ? 100000 : null;
      return state;
    }

    test('première entrée de la semaine suivante : bilan de la semaine écoulée', () {
      final state = semainePassee();
      final ancienne = state.currentWeekStart!;
      state.ensureFresh();
      final bilan = state.pendingBilan!;
      expect(bilan.weekId, weekIdFor(ancienne));
      expect(bilan.solved, isTrue);
      expect(bilan.solvedDay, 2);
      expect(bilan.rewardsAlreadyGranted, isFalse);
      // La nouvelle semaine repart de zéro.
      expect(state.solved, isFalse);
      expect(state.participated, isFalse);
    });

    test('participé sans trouver : bilan sans résolution', () {
      final state = semainePassee(trouvee: false);
      state.ensureFresh();
      expect(state.pendingBilan!.solved, isFalse);
    });

    test('pas participé : pas de bilan', () {
      final state = semainePassee(trouvee: false, participe: false);
      state.ensureFresh();
      expect(state.pendingBilan, isNull);
    });

    test('une semaine sautée : pas de bilan, les jokers sont perdus', () {
      final state = semainePassee(semainesAvant: 2);
      state.ensureFresh();
      expect(state.pendingBilan, isNull);
    });

    test('résolue avec une ancienne version : les jokers ne sont pas redonnés', () {
      final state = semainePassee()
        ..rewardLabels = ['Révéler']
        ..topTenRedJokerGranted = true;
      state.ensureFresh();
      expect(state.pendingBilan!.rewardsAlreadyGranted, isTrue);
      expect(state.pendingBilan!.redJokerAlreadyGranted, isTrue);
    });

    test('bilan terminé : effacé, et le classement final remplace le provisoire', () {
      final state = semainePassee();
      state.ensureFresh(); // archive la semaine écoulée puis crée le bilan
      final weekId = state.pendingBilan!.weekId;
      state.historique.insert(0, EnigmeHistoryEntry(weekId: weekId, sujet: 'X', solveSeconds: 100000, solvedDay: 2, rang: 3, total: 4));
      state.completeBilan(rang: 7, total: 40);
      expect(state.pendingBilan, isNull);
      final entry = state.historique.firstWhere((e) => e.weekId == weekId);
      expect(entry.rang, 7);
      expect(entry.total, 40);
    });

    test('le bilan survit à une sauvegarde et un rechargement', () async {
      SharedPreferences.setMockInitialValues({});
      final state = semainePassee();
      state.ensureFresh();
      await state.flushSave();
      final reloaded = EnigmeState(saveService: state.saveService, settings: state.settings);
      await reloaded.restore();
      expect(reloaded.pendingBilan!.weekId, state.pendingBilan!.weekId);
      expect(reloaded.pendingBilan!.solved, isTrue);
    });

    test('top % et top 10 %', () {
      expect(EnigmeState.topPercent(1, 50), 2);
      expect(EnigmeState.topPercent(7, 40), 18);
      expect(EnigmeState.topPercent(40, 40), 100);
      expect(EnigmeState.isTopTen(4, 40), isTrue);
      expect(EnigmeState.isTopTen(5, 40), isFalse);
      expect(EnigmeState.isTopTen(1, 1), isTrue);
    });
  });
}
