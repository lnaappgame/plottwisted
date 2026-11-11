/// Les 5 couleurs possibles pour un nom masqué dans le pitch.
enum NameColor { green, blue, red, orange, violet }

NameColor colorFromString(String s) {
  switch (s) {
    case 'green': return NameColor.green;
    case 'blue': return NameColor.blue;
    case 'orange': return NameColor.orange;
    case 'violet': return NameColor.violet;
    default: return NameColor.red;
  }
}

/// Un personnage : toutes les variantes de nom possibles selon la couleur
/// affichée, plus le film d'origine du nom rouge/orange (pour l'écran de
/// révélation : "tel acteur a incarné ce rôle dans tel film").
class PersonRef {
  final String real;            // vert : vrai personnage de CE film
  final String actor;           // bleu : vrai acteur
  final String decoy;           // rouge : personnage d'un AUTRE film du même acteur
  final String decoyFilm;       // film d'origine du nom rouge (affiché à la révélation)
  final String sameRoleActor;   // orange : un AUTRE acteur ayant joué le même rôle
  final String sameRoleFilm;    // film d'origine du nom orange
  final String violet;          // violet : lien de parenté/proximité (pas un rôle)

  // Équivalents anglais — toujours renseignés pour le contenu importé (voir
  // le périmètre bilingue V1, base de données US).
  final String realUs;
  final String actorUs;
  final String decoyUs;
  final String decoyFilmUs;
  final String sameRoleActorUs;
  final String sameRoleFilmUs;
  final String violetUs;

  const PersonRef({
    required this.real,
    required this.actor,
    this.decoy = '',
    this.decoyFilm = '',
    this.sameRoleActor = '',
    this.sameRoleFilm = '',
    this.violet = '',
    this.realUs = '',
    this.actorUs = '',
    this.decoyUs = '',
    this.decoyFilmUs = '',
    this.sameRoleActorUs = '',
    this.sameRoleFilmUs = '',
    this.violetUs = '',
  });

  String displayFor(NameColor c, [String locale = 'fr']) {
    final us = locale == 'en';
    switch (c) {
      case NameColor.green: return us ? realUs : real;
      case NameColor.blue: return us ? actorUs : actor;
      case NameColor.orange: return us ? sameRoleActorUs : sameRoleActor;
      case NameColor.violet: return us ? violetUs : violet;
      case NameColor.red: return us ? decoyUs : decoy;
    }
  }

  // Accès direct par champ (plutôt que par couleur) — utile à l'écran de
  // révélation, qui affiche plusieurs champs en même temps quelle que soit
  // la couleur initiale du puzzle.
  String realFor(String locale) => locale == 'en' ? realUs : real;
  String actorFor(String locale) => locale == 'en' ? actorUs : actor;
  String decoyFor(String locale) => locale == 'en' ? decoyUs : decoy;
  String decoyFilmFor(String locale) => locale == 'en' ? decoyFilmUs : decoyFilm;
  String sameRoleActorFor(String locale) => locale == 'en' ? sameRoleActorUs : sameRoleActor;
  String sameRoleFilmFor(String locale) => locale == 'en' ? sameRoleFilmUs : sameRoleFilm;
  String violetFor(String locale) => locale == 'en' ? violetUs : violet;
}

/// Sépare le titre de la réponse bonus dans la grille (« LÉON · NATALIE
/// PORTMAN »). Jamais présent dans un titre : AnswerRow le reconnaît et
/// passe à la ligne à cet endroit au lieu d'afficher une case.
const String kAnswerSeparator = '·';

/// Une devinette complète.
class Puzzle {
  final String title;
  final String year;
  final String pitchTemplate; // contient {p1} et {p2} (ou seulement {p1} pour
                               // les devinettes à un seul personnage, ex. répliques cultes)
  final String allocineUrl;
  final String extraHint;     // texte du joker Indice
  final String revealNote;    // anecdote affichée à la révélation (séparée de l'indice)
  final NameColor p1InitialColor;
  final NameColor p2InitialColor;
  final PersonRef p1;
  final PersonRef p2;         // p2 peut être un PersonRef "vide" (real: '') si non utilisé

  // Équivalents anglais (périmètre bilingue V1 — voir base de données US).
  // `year` n'a pas d'équivalent : l'année de sortie ne change pas de langue.
  final String titleUs;
  final String pitchTemplateUs;
  final String extraHintUs;
  final String revealNoteUs;
  final String imdbUrl; // équivalent US du lien Allociné, pas de version FR

  // Réponse bonus à trouver en plus du titre (monde « Enfants stars » : le
  // nom de l'enfant star). Vide pour une devinette ordinaire.
  final String extraAnswer;
  final String extraAnswerUs;

  const Puzzle({
    required this.title,
    required this.year,
    required this.pitchTemplate,
    required this.p1,
    required this.p2,
    required this.p1InitialColor,
    required this.p2InitialColor,
    this.allocineUrl = '',
    this.extraHint = '',
    this.revealNote = '',
    this.titleUs = '',
    this.pitchTemplateUs = '',
    this.extraHintUs = '',
    this.revealNoteUs = '',
    this.imdbUrl = '',
    this.extraAnswer = '',
    this.extraAnswerUs = '',
  });

  bool get hasP2 => p2.real.isNotEmpty;

  String titleFor(String locale) => locale == 'en' ? titleUs : title;
  String extraAnswerFor(String locale) => locale == 'en' ? extraAnswerUs : extraAnswer;

  /// Ce que le joueur doit écrire dans la grille : le titre, suivi de la
  /// réponse bonus quand il y en a une.
  String answerFor(String locale) {
    final extra = extraAnswerFor(locale);
    return extra.isEmpty ? titleFor(locale) : '${titleFor(locale)} $kAnswerSeparator $extra';
  }
  String pitchTemplateFor(String locale) => locale == 'en' ? pitchTemplateUs : pitchTemplate;
  String extraHintFor(String locale) => locale == 'en' ? extraHintUs : extraHint;
  String revealNoteFor(String locale) => locale == 'en' ? revealNoteUs : revealNote;
  String linkUrlFor(String locale) => locale == 'en' ? imdbUrl : allocineUrl;
}

/// Un monde : une catégorie + 10 devinettes dans l'ordre (position 1 à 10 =
/// palier de difficulté imposé : 1,3,6,8 facile / 2,4,7,9 moyen / 5 difficile / 10 extrême).
/// Le monde 0 (tutoriel) n'a que 5 niveaux et aucun palier de difficulté.
class GameWorld {
  final int number;
  final String categoryLabel;
  final String categoryLabelUs;
  final List<Puzzle> puzzles;

  // Ce que désigne la réponse bonus des devinettes de ce monde (« l'enfant
  // star »), affiché dans la grille et à l'entrée du monde. Vide si le monde
  // n'en a pas.
  final String extraLabel;
  final String extraLabelUs;

  const GameWorld({
    required this.number,
    required this.categoryLabel,
    required this.puzzles,
    this.categoryLabelUs = '',
    this.extraLabel = '',
    this.extraLabelUs = '',
  });

  String categoryLabelFor(String locale) => locale == 'en' ? categoryLabelUs : categoryLabel;
  String extraLabelFor(String locale) => locale == 'en' ? extraLabelUs : extraLabel;

  /// La règle du monde en une ligne (« Trouve le film + l'enfant star »),
  /// vide pour un monde ordinaire.
  String extraRuleFor(String locale) {
    final label = extraLabelFor(locale);
    if (label.isEmpty) return '';
    return locale == 'en' ? 'Find the movie + $label' : 'Trouve le film + $label';
  }
}

// Palier de difficulté par position dans le monde (1 à 10) — vocabulaire fixe
// (4 valeurs), pas du contenu par ligne de la base de données : traduit ici
// directement plutôt que par un champ US par puzzle.
const Map<int, String> kDifficultyPattern = {
  1: 'Facile', 2: 'Moyen', 3: 'Facile', 4: 'Moyen', 5: 'Difficile',
  6: 'Facile', 7: 'Moyen', 8: 'Facile', 9: 'Moyen', 10: 'Extrême',
};
const Map<int, String> kDifficultyPatternUs = {
  1: 'Easy', 2: 'Medium', 3: 'Easy', 4: 'Medium', 5: 'Hard',
  6: 'Easy', 7: 'Medium', 8: 'Easy', 9: 'Medium', 10: 'Extreme',
};

/// Une case de la grille de réponse.
class AnswerSlot {
  final String char;   // caractère normalisé (majuscule, sans accent)
  final bool isSpace;
  final bool isDigit;
  final bool isAuto;    // ponctuation pure : pré-remplie, jamais à chercher

  const AnswerSlot({
    required this.char,
    required this.isSpace,
    required this.isDigit,
    required this.isAuto,
  });

  factory AnswerSlot.fromChar(String ch) {
    final isSpace = ch == ' ';
    final isDigit = RegExp(r'^[0-9]$').hasMatch(ch);
    final isLetter = RegExp(r'^[A-Z]$').hasMatch(ch);
    final isAuto = !isSpace && !isDigit && !isLetter;
    return AnswerSlot(char: ch, isSpace: isSpace, isDigit: isDigit, isAuto: isAuto);
  }
}

/// Grille d'un titre à trouver, telle que l'affichent AnswerRow et
/// LetterPool : celle du jeu principal (GameState) ou celle de l'event
/// Halloween.
abstract interface class TitleGrid {
  List<AnswerSlot> get slots;
  List<int?> get guess;
  List<LetterTile> get pool;
  List<List<int>> get wordRanges;
  Set<int> get lockedWords;
  Set<int> get lockedSlots;
  int get cursorIndex;
  void onBlankTap(int i);
  void onLetterTap(LetterTile tile);
}

/// Une tuile de la grille de lettres/chiffres à disposition du joueur.
class LetterTile {
  final String letter;
  bool used;
  bool eliminated;
  bool consumed; // définitivement acquise (mot verrouillé), ne revient jamais dans le pool

  LetterTile({
    required this.letter,
    this.used = false,
    this.eliminated = false,
    this.consumed = false,
  });
}
