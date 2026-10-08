import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cine_devinette/data/defis_data.dart';
import 'package:cine_devinette/models/defi.dart';
import 'package:cine_devinette/models/joker.dart';
import 'package:cine_devinette/services/defi_service.dart';
import 'package:cine_devinette/services/defi_state.dart';
import 'package:cine_devinette/services/save_service.dart';

DefiState _state() => DefiState(saveService: SaveService());

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  test('defiIndexFor est déterministe pour un même jour', () {
    final epoch = DateTime.utc(2026, 1, 1);
    final a = defiIndexFor(DateTime.utc(2026, 3, 10, 5), epoch);
    final b = defiIndexFor(DateTime.utc(2026, 3, 10, 23), epoch);
    expect(a, b);
    expect(a, inInclusiveRange(0, kDefis.length - 1));
  });

  test('defiIndexFor change bien de jour en jour', () {
    final epoch = DateTime.utc(2026, 1, 1);
    final a = defiIndexFor(DateTime.utc(2026, 3, 10), epoch);
    final b = defiIndexFor(DateTime.utc(2026, 3, 11), epoch);
    expect(a == b, isFalse);
  });

  test('defiIndexFor : le défi 1 (index 0) tombe le jour de l\'ancrage personnel', () {
    final epoch = DateTime.utc(2026, 5, 4);
    expect(defiIndexFor(epoch, epoch), 0);
    expect(defiIndexFor(DateTime.utc(2026, 5, 5), epoch), 1);
  });

  test('defiIndexFor : deux joueurs installés à des jours différents suivent '
      'la même séquence, juste décalée', () {
    final epochJoueurA = DateTime.utc(2026, 1, 1);
    final epochJoueurB = DateTime.utc(2026, 6, 15); // installé 5 mois plus tard
    // Même nombre de jours écoulés depuis leur propre installation respective
    // -> même index, malgré des dates calendaires différentes.
    final indexA = defiIndexFor(DateTime.utc(2026, 1, 11), epochJoueurA); // 10 jours après
    final indexB = defiIndexFor(DateTime.utc(2026, 6, 25), epochJoueurB); // 10 jours après
    expect(indexA, indexB);
  });

  test('startDefi initialise une partie propre', () {
    final state = _state();
    state.currentIndex = 0;
    final defi = state.defiDuJour;
    state.startDefi(defi, bonus: false);
    expect(state.activeDefi, defi);
    expect(state.isBonus, isFalse);
    expect(state.solved, isFalse);
    expect(state.currentCaseIndex, 0);
    expect(state.penaltySeconds, 0);
    expect(state.displayOrder.toSet(), List.generate(defi.cases.length, (i) => i).toSet());
  });

  test('bonne réponse : flash vert immédiat, puis la case disparaît après 1s', () async {
    final state = _state();
    state.currentIndex = 0;
    final defi = state.defiDuJour;
    state.startDefi(defi, bonus: false);
    state.onCaseTapped(0);
    // Retour visuel immédiat : la case tapée est identifiée comme correcte,
    // mais pas encore masquée (elle doit rester visible pendant le flash).
    expect(state.feedbackCaseIndex, 0);
    expect(state.feedbackCorrect, isTrue);
    expect(state.revealCaseIndex, isNull);
    expect(state.isCaseHidden(0), isFalse);
    expect(state.currentCaseIndex, 1);
    expect(state.penaltySeconds, 0);

    await Future.delayed(const Duration(milliseconds: 1100));
    expect(state.isCaseHidden(0), isTrue);
    expect(state.feedbackCaseIndex, isNull);
  });

  test('mauvaise réponse : flash rouge + la bonne réponse clignote, pénalité +5s immédiate', () async {
    final state = _state();
    state.currentIndex = 0;
    final defi = state.defiDuJour;
    state.startDefi(defi, bonus: false);
    state.onCaseTapped(1); // ne correspond pas à l'indice 0
    expect(state.feedbackCaseIndex, 1);
    expect(state.feedbackCorrect, isFalse);
    expect(state.revealCaseIndex, 0); // la vraie bonne case à faire clignoter
    expect(state.isCaseHidden(1), isFalse);
    expect(state.isCaseHidden(0), isFalse);
    expect(state.currentCaseIndex, 1);
    expect(state.penaltySeconds, 5);

    await Future.delayed(const Duration(milliseconds: 1100));
    // La bonne case (jamais tapée) disparaît aussi, la mauvaise reste.
    expect(state.isCaseHidden(0), isTrue);
    expect(state.isCaseHidden(1), isFalse);
  });

  test('un nouveau tap finalise immédiatement le retour visuel précédent (pas de blocage)', () {
    final state = _state();
    state.currentIndex = 0;
    final defi = state.defiDuJour;
    state.startDefi(defi, bonus: false);
    state.onCaseTapped(0); // correct, feedback en attente
    expect(state.isCaseHidden(0), isFalse);

    state.onCaseTapped(1); // correct pour l'indice 1
    // Le tap précédent a été finalisé immédiatement, sans attendre 1s.
    expect(state.isCaseHidden(0), isTrue);
    expect(state.currentCaseIndex, 2);
  });

  test('terminer le défi calcule le temps total et retient le meilleur temps', () async {
    final state = _state();
    state.currentIndex = 0;
    final defi = state.defiDuJour;
    state.startDefi(defi, bonus: false);
    for (var i = 0; i < defi.cases.length; i++) {
      state.onCaseTapped(i); // toujours la bonne réponse
    }
    await Future.delayed(const Duration(milliseconds: 1100)); // finalise le dernier tap
    expect(state.solved, isTrue);
    expect(state.penaltySeconds, 0);
    expect(state.totalSeconds, state.realSeconds);
    expect(state.isNewBest, isTrue);
    expect(state.bestTimeFor(defi.id), state.totalSeconds);
    expect(state.playedDefiIds.contains(defi.id), isTrue);
  });

  test('rejouer avec un moins bon temps ne remplace pas le record', () async {
    final state = _state();
    state.currentIndex = 0;
    final defi = state.defiDuJour;
    state.bestTimes[defi.id] = 0; // record artificiellement imbattable
    state.startDefi(defi, bonus: false);
    for (var i = 0; i < defi.cases.length; i++) {
      state.onCaseTapped(i);
    }
    await Future.delayed(const Duration(milliseconds: 1100));
    expect(state.isNewBest, isFalse);
    expect(state.bestTimeFor(defi.id), 0);
  });

  test('deux cases avec la même réponse textuelle ne se masquent jamais ensemble', () async {
    // Identification par index (et non par texte de réponse) : même en cas
    // de doublon de contenu, résoudre une case ne doit jamais en masquer une
    // autre par erreur (ce qui rendrait la case suivante intapable).
    const defi = Defi(
      id: 'test-doublon',
      type: DefiType.film,
      commun: 'Test',
      consigne: 'Test',
      cases: [
        DefiCase(reponse: 'Même titre', indice: 'Indice A'),
        DefiCase(reponse: 'Même titre', indice: 'Indice B'),
      ],
    );
    final state = _state();
    state.startDefi(defi, bonus: false);

    state.onCaseTapped(0); // résout la case 0 (indice A)
    await Future.delayed(const Duration(milliseconds: 1100));
    expect(state.isCaseHidden(0), isTrue);
    expect(state.isCaseHidden(1), isFalse); // la case 1 reste tapable malgré le texte identique
    expect(state.solved, isFalse);

    state.onCaseTapped(1); // résout la case 1 (indice B)
    await Future.delayed(const Duration(milliseconds: 1100));
    expect(state.isCaseHidden(1), isTrue);
    expect(state.solved, isTrue);
  });

  test('piocherBonus exclut le défi du jour et les communs déjà joués', () {
    final state = _state();
    state.currentIndex = 0;
    final autresIds = kDefis.where((d) => d.id != state.defiDuJour.id).map((d) => d.id).toList();
    state.playedDefiIds = autresIds; // tout est déjà joué sauf le défi du jour
    expect(state.peutPiocherBonus, isFalse);
    expect(state.piocherBonus(), isNull);
  });

  test('toJson()/restore() conservent historique et meilleurs temps', () async {
    final state = _state();
    state.currentIndex = 2;
    state.currentDayStart = DateTime.utc(2026, 3, 10);
    state.playedDefiIds = [kDefis[0].id, kDefis[1].id];
    state.bestTimes = {kDefis[0].id: 42};

    final restored = _state();
    final json = state.toJson();
    restored.currentIndex = json['currentIndex'] as int;
    restored.currentDayStart = DateTime.parse(json['currentDayStart'] as String);
    restored.playedDefiIds = (json['playedDefiIds'] as List).cast<String>();
    restored.bestTimes = Map<String, int>.from(json['bestTimes'] as Map);

    expect(restored.playedDefiIds, state.playedDefiIds);
    expect(restored.bestTimes, state.bestTimes);
  });

  group('Bonus de jokers', () {
    // Partie complète avec [mistakes] erreurs (5 s de pénalité chacune) ;
    // renvoie les jokers demandés (true = mineur).
    Future<List<bool>> play(DefiState state, int mistakes) async {
      final asked = <bool>[];
      state.grantJoker = ({required bool minor}) {
        asked.add(minor);
        return minor ? JokerKind.reveal : JokerKind.actor;
      };
      final defi = state.defiDuJour;
      final last = defi.cases.length - 1;
      state.startDefi(defi, bonus: false);
      for (var i = 0; i < defi.cases.length; i++) {
        state.onCaseTapped(i < mistakes && i < last ? last : i);
      }
      await Future.delayed(const Duration(milliseconds: 1100)); // finalise le dernier tap
      expect(state.solved, isTrue);
      return asked;
    }

    DefiState fresh() => _state()..currentIndex = 0;

    test('sans faute et en moins de 20 s : un mineur et un majeur', () async {
      final state = fresh();
      expect(await play(state, 0), [true, false]);
      expect([for (final r in state.rewards) r.bonus], [DefiBonus.perfect, DefiBonus.under20]);
      expect(state.rewards.last.kind, JokerKind.actor);
    });

    test('4 erreurs (20 s de pénalité) : seulement le mineur des 30 s', () async {
      final state = fresh();
      expect(state.defiDuJour.cases.length, greaterThan(6));
      expect(await play(state, 4), [true]);
      expect([for (final r in state.rewards) r.bonus], [DefiBonus.under30]);
    });

    test('6 erreurs (30 s de pénalité) : aucun bonus', () async {
      final state = fresh();
      expect(await play(state, 6), isEmpty);
      expect(state.rewards, isEmpty);
    });

    test('rejouer un commun déjà joué ne rapporte rien', () async {
      final state = fresh();
      await play(state, 0);
      expect(await play(state, 0), isEmpty);
      expect(state.rewardsEligible, isFalse);
    });
  });
}
