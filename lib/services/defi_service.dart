import '../data/defis_data.dart';

/// Minuit UTC du jour de [now] — ancré en GMT (pas l'heure locale) pour que
/// le défi officiel change au même instant partout dans le monde, comme
/// L'énigme de la semaine.
DateTime defiDayStart(DateTime now) {
  final u = now.toUtc();
  return DateTime.utc(u.year, u.month, u.day);
}

/// Index (dans [kDefis]) du défi officiel du jour contenant [now], pour un
/// joueur dont le tout premier lancement de l'app a eu lieu le jour
/// [epoch] — propre à CHAQUE joueur (pas une date globale partagée) : le
/// défi 1 (position 0 dans [kDefis]) tombe le jour de son 1er lancement, le
/// défi 2 le lendemain, etc. Deux joueurs installés à des jours différents
/// suivent donc la même séquence, juste décalée dans le temps.
int defiIndexFor(DateTime now, DateTime epoch) {
  final days = defiDayStart(now).difference(defiDayStart(epoch)).inDays;
  return days % kDefis.length;
}
