/// Un grand événement du monde du cinéma (cérémonie de récompenses), avec sa
/// date réelle confirmée — pas une date approximative, seulement des dates
/// officiellement annoncées. Liste à étendre au fil des annonces futures
/// (ex. Razzies, dont la date 2027 n'était pas encore fixée au moment de
/// l'écriture).
class CinemaEvent {
  final DateTime date; // UTC, jour seul (pas d'heure)
  final String label;
  final String emoji;
  const CinemaEvent({required this.date, required this.label, required this.emoji});
}

final List<CinemaEvent> kCinemaEvents = [
  CinemaEvent(date: DateTime.utc(2027, 1, 10), label: 'Golden Globes', emoji: '🌐'),
  CinemaEvent(date: DateTime.utc(2027, 2, 21), label: 'BAFTA', emoji: '🎭'),
  CinemaEvent(date: DateTime.utc(2027, 2, 25), label: 'César', emoji: '🇫🇷'),
  CinemaEvent(date: DateTime.utc(2027, 3, 14), label: 'Oscars', emoji: '🏆'),
  CinemaEvent(date: DateTime.utc(2028, 3, 5), label: 'Oscars', emoji: '🏆'),
];
