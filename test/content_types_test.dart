import 'package:flutter_test/flutter_test.dart';

import 'package:cine_devinette/data/defis_data.dart';
import 'package:cine_devinette/data/multiplayer_data.dart';
import 'package:cine_devinette/models/defi.dart';
import 'package:cine_devinette/models/multiplayer.dart';

MultiplayerType _mp(String reponse) =>
    kMultiplayerEnigmes.firstWhere((e) => e.reponse.toUpperCase() == reponse.toUpperCase()).type;

DefiType _defi(String id) => kDefis.firstWhere((d) => d.id == id).type;

void main() {
  test('multijoueur : le type affiché correspond à la réponse', () {
    expect(_mp('Meryl Streep'), MultiplayerType.actrice);
    expect(_mp('Morgan Freeman'), MultiplayerType.acteur);
    expect(_mp('Greta Gerwig'), MultiplayerType.realisatrice);
    expect(_mp('Steven Spielberg'), MultiplayerType.realisateur);
    expect(_mp('Jack Sparrow'), MultiplayerType.personnage);
    expect(_mp('Titanic'), MultiplayerType.film);
    expect(multiplayerTypeLabel(MultiplayerType.actrice), 'Actrice');
    expect(multiplayerTypeLabel(MultiplayerType.actrice, 'en'), 'Actress');
  });

  test('multijoueur : plus aucune actrice ni cinéaste rangé dans « Film »', () {
    for (final e in kMultiplayerEnigmes.where((e) => e.type == MultiplayerType.film)) {
      expect(e.pitch.startsWith('Cette actrice') || e.pitch.startsWith('Ce cinéaste'), isFalse, reason: e.reponse);
    }
  });

  test('défi du jour : actrices et réalisateurs ne sont plus « Personnage »', () {
    expect(_defi('george-miller'), DefiType.realisateur);
    expect(_defi('penelope-cruz'), DefiType.actrice);
    expect(_defi('ava-duvernay'), DefiType.realisatrice);
    expect(_defi('batman'), DefiType.personnage);
    expect(defiTypeLabel(DefiType.realisatrice), 'Réalisatrice');
    expect(defiTypeLabel(DefiType.realisatrice, 'en'), 'Director');
    expect(multiplayerTypeFromLabel('Actrice'), MultiplayerType.actrice);
  });
}
