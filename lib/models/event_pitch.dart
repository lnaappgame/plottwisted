/// Un pitch d'event (Halloween, calendrier de l'Avent) : un film raconté par
/// un narrateur, à retrouver avec les seules lettres et trois jokers. Pas de
/// noms colorés ici.
class EventPitch {
  final String titleFr;
  final String titleEn;
  final String year;
  final String pitchFr;
  final String pitchEn;

  const EventPitch({
    required this.titleFr,
    required this.titleEn,
    required this.year,
    required this.pitchFr,
    required this.pitchEn,
  });

  String titleFor(String locale) => locale == 'en' ? titleEn : titleFr;
  String pitchFor(String locale) => locale == 'en' ? pitchEn : pitchFr;
}
