import 'puzzle.dart';

/// Les 7 jokers du jeu principal.
enum JokerKind {
  reveal('Révéler', '💡', isMinor: true),
  eliminate('Éliminer', '✂️', isMinor: true),
  actor('Acteur', '🔵', nameColor: NameColor.blue),
  character('Personnage', '🟢', isMinor: true, nameColor: NameColor.green),
  hint('Indice', '🎬'),
  revealWord('Révéler un mot', '📖'),
  red('Personnage (rouge)', '🔴', nameColor: NameColor.red);

  const JokerKind(this.frLabel, this.icon, {this.isMinor = false, this.nameColor});

  /// Libellé interne (français) renvoyé par les fonctions d'octroi de GameState.
  final String frLabel;
  final String icon;

  /// Joker "mineur" : une pub en rapporte 2 au lieu d'1.
  final bool isMinor;

  /// Couleur que ce joker donne à un nom du pitch (jokers à deux touches).
  final NameColor? nameColor;

  int get adReward => isMinor ? 2 : 1;

  static JokerKind? fromLabel(String label) {
    for (final k in values) {
      if (k.frLabel == label) return k;
    }
    return null;
  }

  static JokerKind? fromNameColor(NameColor color) {
    for (final k in values) {
      if (k.nameColor == color) return k;
    }
    return null;
  }
}
