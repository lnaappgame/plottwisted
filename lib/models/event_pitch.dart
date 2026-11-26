import '../services/game_state.dart' show normalize;

/// Un pitch d'event (Halloween, calendrier de l'Avent) : un film raconté par
/// un narrateur. À Halloween, le titre se retrouve avec les seules lettres et
/// trois jokers ; dans le calendrier de l'Avent, c'est un QCM : le bon titre
/// parmi trois pièges ([trapsFr] / [trapsEn]). Pas de noms colorés ici.
///
/// [acceptedFr] / [acceptedEn] : autres réponses valables pour le même film
/// (titre alternatif, article en plus, titre long). La grille de lettres du jeu
/// n'en tient pas compte (elle ne construit que le titre affiché) ; elles
/// servent à toute saisie libre, via [accepts].
///
/// [trapsFr] / [trapsEn] : les pièges du QCM de l'Avent, de vrais films (titre
/// officiel en France / aux États-Unis), dans le même ordre dans les deux
/// langues (`trapsFr[i]` et `trapsEn[i]` sont le même film). Vides pour
/// Halloween.
class EventPitch {
  final String titleFr;
  final String titleEn;
  final String year;
  final String pitchFr;
  final String pitchEn;
  final List<String> acceptedFr;
  final List<String> acceptedEn;
  final List<String> trapsFr;
  final List<String> trapsEn;

  const EventPitch({
    required this.titleFr,
    required this.titleEn,
    required this.year,
    required this.pitchFr,
    required this.pitchEn,
    this.acceptedFr = const [],
    this.acceptedEn = const [],
    this.trapsFr = const [],
    this.trapsEn = const [],
  });

  String titleFor(String locale) => locale == 'en' ? titleEn : titleFr;
  String pitchFor(String locale) => locale == 'en' ? pitchEn : pitchFr;
  List<String> trapsFor(String locale) => locale == 'en' ? trapsEn : trapsFr;

  /// Clé de comparaison des titres : accents, majuscules et ponctuation ignorés.
  static String titleKey(String s) => normalize(s).replaceAll(RegExp(r'[^A-Z0-9]'), '');

  /// Vrai si [answer] est le titre ou une réponse acceptée dans [locale] (accents,
  /// majuscules et ponctuation ignorés, comme la grille).
  bool accepts(String locale, String answer) {
    final target = titleKey(answer);
    final en = locale == 'en';
    return [titleFor(locale), ...(en ? acceptedEn : acceptedFr)].any((t) => titleKey(t) == target);
  }
}
