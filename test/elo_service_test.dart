import 'package:flutter_test/flutter_test.dart';

import 'package:cine_devinette/services/elo_service.dart';

void main() {
  test('titreForElo retourne le bon palier', () {
    expect(titreForElo(250), 'Stagiaire café du plateau, en passe de se faire virer');
    expect(titreForElo(2000), 'Chef machiniste');
    expect(titreForElo(2690), 'Monteur émérite'); // palier 2700 non atteint
    expect(titreForElo(5000), 'Légende du septième art');
    expect(titreForElo(4999), "Palme d'or de la rapidité");
  });

  test('kFactorFor suit les paliers échecs 40/20/10/5', () {
    expect(kFactorFor(isCalibration: true, elo: 2000), 40);
    expect(kFactorFor(isCalibration: false, elo: 2000), 20);
    expect(kFactorFor(isCalibration: false, elo: 3999), 20);
    expect(kFactorFor(isCalibration: false, elo: 4000), 10);
    expect(kFactorFor(isCalibration: false, elo: 4499), 10);
    expect(kFactorFor(isCalibration: false, elo: 4500), 5);
    expect(kFactorFor(isCalibration: false, elo: 5000), 5);
  });

  test('nouvelElo : victoire contre un adversaire de même niveau augmente le score', () {
    final resultat = nouvelElo(eloJoueur: 2000, eloAdversaireMoyen: 2000, scoreReel: 1, kFactor: 20);
    expect(resultat, 2010); // expectedScore=0.5, delta = 20*(1-0.5) = 10
  });

  test('nouvelElo : défaite contre un adversaire de même niveau diminue le score', () {
    final resultat = nouvelElo(eloJoueur: 2000, eloAdversaireMoyen: 2000, scoreReel: 0, kFactor: 20);
    expect(resultat, 1990);
  });

  test('nouvelElo : match nul contre un adversaire de même niveau ne bouge pas le score', () {
    final resultat = nouvelElo(eloJoueur: 2000, eloAdversaireMoyen: 2000, scoreReel: 0.5, kFactor: 20);
    expect(resultat, 2000);
  });

  test('nouvelElo : victoire contre un adversaire beaucoup plus fort rapporte plus', () {
    final resultat = nouvelElo(eloJoueur: 2000, eloAdversaireMoyen: 2400, scoreReel: 1, kFactor: 20);
    expect(resultat, greaterThan(2010));
  });

  test('nouvelElo ne descend jamais sous le plancher', () {
    final resultat = nouvelElo(eloJoueur: 260, eloAdversaireMoyen: 260, scoreReel: 0, kFactor: 40);
    expect(resultat, kEloPlancher);
  });

  test('nouvelElo ne dépasse jamais le plafond', () {
    final resultat = nouvelElo(eloJoueur: 4995, eloAdversaireMoyen: 4995, scoreReel: 1, kFactor: 40);
    expect(resultat, kEloPlafond);
  });

  test('nouvelElo : une victoire écrasante rapporte toujours au moins 1 point '
      '(jamais 0, même quand l\'écart de classement arrondirait le delta à 0)', () {
    // K=5 (haut de classement), adversaire ~1400 points plus faible : le
    // delta brut est proche de 0 et arrondirait naïvement à 0.
    final resultat = nouvelElo(eloJoueur: 4500, eloAdversaireMoyen: 3100, scoreReel: 1, kFactor: 5);
    expect(resultat, 4501);
  });

  test('nouvelElo : une défaite écrasante coûte toujours au moins 1 point '
      '(jamais 0)', () {
    final resultat = nouvelElo(eloJoueur: 3100, eloAdversaireMoyen: 4500, scoreReel: 0, kFactor: 5);
    expect(resultat, 3099);
  });

  test('nouvelElo : un match nul entre adversaires de même niveau reste à 0 '
      '(0 est un résultat légitime pour un nul, pas forcé à ±1)', () {
    final resultat = nouvelElo(eloJoueur: 2000, eloAdversaireMoyen: 2000, scoreReel: 0.5, kFactor: 5);
    expect(resultat, 2000);
  });
}
