import '../data/enigmes_data.dart';
import 'game_state.dart';

/// Référence (lundi 00:00 GMT) de la semaine contenant [now] — ancrée en
/// UTC (et non l'heure locale du joueur) pour que la semaine commence et se
/// termine au même instant partout dans le monde : lundi 00h00 GMT à
/// dimanche 23h59 GMT.
DateTime enigmeWeekStart(DateTime now) {
  final u = now.toUtc();
  final d = DateTime.utc(u.year, u.month, u.day);
  return d.subtract(Duration(days: d.weekday - 1));
}

/// Index (dans [kEnigmes]) de l'énigme de la semaine contenant [now] —
/// déterministe et identique pour tous les joueurs, sans backend : basé sur
/// le nombre de semaines écoulées depuis une date de référence fixe (UTC).
int enigmeIndexFor(DateTime now) {
  final epoch = DateTime.utc(2024, 1, 1);
  final weeks = enigmeWeekStart(now).difference(enigmeWeekStart(epoch)).inDays ~/ 7;
  return weeks % kEnigmes.length;
}

/// Barème de récompense en jokers de L'énigme de la semaine selon le jour
/// (1 à 7) de résolution réussie — accorde les jokers sur [game] et retourne
/// leurs libellés pour l'affichage.
///
/// J1 = un joker de chaque type, J2 = 2 majeurs + 2 mineurs, J3 = 2M + 1m,
/// J4 = 1M + 2m, J5 = 1 majeur, J6 = 2 mineurs, J7 = 1 mineur.
List<String> appliquerRecompenseEnigme(int jour, GameState game) {
  final labels = <String>[];
  switch (jour.clamp(1, 7)) {
    case 1:
      game.grantOneOfEachJokerType();
      labels.addAll(['Révéler', 'Éliminer', 'Personnage', 'Acteur', 'Indice', 'Révéler un mot']);
      break;
    case 2:
      labels.add(game.grantMajorJoker());
      labels.add(game.grantMajorJoker());
      labels.add(game.grantMinorJoker());
      labels.add(game.grantMinorJoker());
      game.notifyListeners();
      break;
    case 3:
      labels.add(game.grantMajorJoker());
      labels.add(game.grantMajorJoker());
      labels.add(game.grantMinorJoker());
      game.notifyListeners();
      break;
    case 4:
      labels.add(game.grantMajorJoker());
      labels.add(game.grantMinorJoker());
      labels.add(game.grantMinorJoker());
      game.notifyListeners();
      break;
    case 5:
      labels.add(game.grantMajorJoker());
      game.notifyListeners();
      break;
    case 6:
      labels.add(game.grantMinorJoker());
      labels.add(game.grantMinorJoker());
      game.notifyListeners();
      break;
    case 7:
      labels.add(game.grantMinorJoker());
      game.notifyListeners();
      break;
  }
  return labels;
}
