import '../services/game_state.dart' show normalize;

/// Un pitch d'event (Halloween, calendrier de l'Avent) : un film raconté par
/// un narrateur, à retrouver avec les seules lettres et trois jokers. Pas de
/// noms colorés ici.
///
/// [acceptedFr] / [acceptedEn] : autres réponses valables pour le même film
/// (titre alternatif, article en plus, titre long). La grille de lettres du jeu
/// n'en tient pas compte (elle ne construit que le titre affiché) ; elles
/// servent à toute saisie libre, via [accepts].
class EventPitch {
  final String titleFr;
  final String titleEn;
  final String year;
  final String pitchFr;
  final String pitchEn;
  final List<String> acceptedFr;
  final List<String> acceptedEn;

  const EventPitch({
    required this.titleFr,
    required this.titleEn,
    required this.year,
    required this.pitchFr,
    required this.pitchEn,
    this.acceptedFr = const [],
    this.acceptedEn = const [],
  });

  String titleFor(String locale) => locale == 'en' ? titleEn : titleFr;
  String pitchFor(String locale) => locale == 'en' ? pitchEn : pitchFr;

  /// Vrai si [answer] est le titre ou une réponse acceptée dans [locale] (accents,
  /// majuscules et ponctuation ignorés, comme la grille).
  bool accepts(String locale, String answer) {
    String key(String s) => normalize(s).replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final target = key(answer);
    final en = locale == 'en';
    return [titleFor(locale), ...(en ? acceptedEn : acceptedFr)].any((t) => key(t) == target);
  }
}
