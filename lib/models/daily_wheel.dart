import 'joker.dart';

/// Une case de la bobine du jour : les jokers qu'elle donne (un de chaque
/// type listé) et sa probabilité en pourcentage.
class WheelSegment {
  final List<JokerKind> jokers;
  final int percent;
  const WheelSegment(this.jokers, this.percent);

  bool get isJackpot => jokers.length > 1;
}

/// Les 8 cases, dans l'ordre où elles sont dessinées sur la bobine (sens des
/// aiguilles d'une montre depuis le haut). Chaque joker mineur 15 %, chaque
/// majeur 10 %, les 3 mineurs d'un coup 15 %, les 3 majeurs d'un coup 10 %.
/// Pas de joker rouge : il s'obtient seulement en boutique ou par le
/// classement mondial de L'énigme de la semaine (et sa pub dédiée).
/// La taille de chaque case sur la bobine est proportionnelle à sa chance.
const kWheelSegments = [
  WheelSegment([JokerKind.reveal], 15),
  WheelSegment([JokerKind.actor], 10),
  WheelSegment([JokerKind.eliminate], 15),
  WheelSegment([JokerKind.hint], 10),
  WheelSegment([JokerKind.reveal, JokerKind.eliminate, JokerKind.character], 15),
  WheelSegment([JokerKind.character], 15),
  WheelSegment([JokerKind.revealWord], 10),
  WheelSegment([JokerKind.actor, JokerKind.hint, JokerKind.revealWord], 10),
];

/// Case tirée pour un nombre [roll] uniformément réparti dans [0, 1).
int wheelSegmentFor(double roll) {
  var threshold = 0.0;
  for (var i = 0; i < kWheelSegments.length; i++) {
    threshold += kWheelSegments[i].percent / 100;
    if (roll < threshold) return i;
  }
  return kWheelSegments.length - 1;
}

/// Angle de départ et largeur (en fractions de tour) de la case [index].
(double start, double sweep) wheelSegmentArc(int index) {
  var start = 0.0;
  for (var i = 0; i < index; i++) {
    start += kWheelSegments[i].percent / 100;
  }
  return (start, kWheelSegments[index].percent / 100);
}
