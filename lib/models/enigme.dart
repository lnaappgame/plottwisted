/// Catégorie d'une énigme hebdomadaire, affichée en haut de l'écran.
enum EnigmeCategorie { film, acteur, personnage }

/// Une énigme du mode "L'énigme de la semaine" : un texte descriptif
/// (160-180 caractères) à révéler progressivement, dont le sujet (titre de
/// film, nom d'acteur ou de personnage) est à deviner via la grille de
/// tuiles — comme le jeu principal, mais sans pitch coloré ni jokers
/// utilisables.
class Enigme {
  final EnigmeCategorie categorie;
  final String sujet; // réponse à deviner, ex. "TITANIC"
  final String texte; // texte descriptif progressivement révélé
  final String? anneeSortie; // Film uniquement, ex. "1997" — pas de version US, ne change pas de langue
  final DateTime? dateNaissance; // Acteur uniquement

  // Équivalents anglais (périmètre bilingue V1 — voir base de données US).
  final String sujetUs;
  final String texteUs;

  const Enigme({
    required this.categorie,
    required this.sujet,
    required this.texte,
    this.anneeSortie,
    this.dateNaissance,
    this.sujetUs = '',
    this.texteUs = '',
  });

  String sujetFor(String locale) => locale == 'en' ? sujetUs : sujet;
  String texteFor(String locale) => locale == 'en' ? texteUs : texte;

  String categorieLabelFor(String locale) => locale == 'en'
      ? switch (categorie) {
          EnigmeCategorie.film => 'Movie',
          EnigmeCategorie.acteur => 'Actor',
          EnigmeCategorie.personnage => 'Character',
        }
      : switch (categorie) {
          EnigmeCategorie.film => 'Film',
          EnigmeCategorie.acteur => 'Acteur',
          EnigmeCategorie.personnage => 'Personnage',
        };

  String get categorieLabel => categorieLabelFor('fr');

  /// Donnée numérique supplémentaire à révéler en plus du texte : l'année
  /// de sortie pour un Film, l'âge (calculé dynamiquement, jamais stocké en
  /// dur) pour un Acteur, rien pour un Personnage.
  String? get badgeSupplementaire {
    switch (categorie) {
      case EnigmeCategorie.film:
        return anneeSortie;
      case EnigmeCategorie.acteur:
        final naissance = dateNaissance;
        if (naissance == null) return null;
        final now = DateTime.now().toUtc();
        var age = now.year - naissance.year;
        if (now.month < naissance.month || (now.month == naissance.month && now.day < naissance.day)) {
          age--;
        }
        return age.toString();
      case EnigmeCategorie.personnage:
        return null;
    }
  }
}

/// Un résultat archivé de "L'énigme de la semaine", conservé localement sur
/// l'appareil pour l'écran "Historique" (dernières semaines + meilleur
/// classement + meilleur temps). [rang]/[total] restent nuls tant que le
/// classement Firestore n'a pas encore été récupéré au moins une fois.
class EnigmeHistoryEntry {
  final String weekId; // lundi 00h00 GMT de la semaine, ex. "2026-08-17"
  final String sujet;
  final int solveSeconds;
  final int solvedDay;
  final int? rang;
  final int? total;

  const EnigmeHistoryEntry({
    required this.weekId,
    required this.sujet,
    required this.solveSeconds,
    required this.solvedDay,
    this.rang,
    this.total,
  });

  EnigmeHistoryEntry copyWith({int? rang, int? total}) => EnigmeHistoryEntry(
        weekId: weekId,
        sujet: sujet,
        solveSeconds: solveSeconds,
        solvedDay: solvedDay,
        rang: rang ?? this.rang,
        total: total ?? this.total,
      );

  Map<String, dynamic> toJson() => {
        'weekId': weekId,
        'sujet': sujet,
        'solveSeconds': solveSeconds,
        'solvedDay': solvedDay,
        'rang': rang,
        'total': total,
      };

  factory EnigmeHistoryEntry.fromJson(Map<String, dynamic> json) => EnigmeHistoryEntry(
        weekId: json['weekId'] as String,
        sujet: json['sujet'] as String,
        solveSeconds: json['solveSeconds'] as int,
        solvedDay: json['solvedDay'] as int,
        rang: json['rang'] as int?,
        total: json['total'] as int?,
      );
}

/// Résultat de la semaine écoulée, en attente du bilan affiché à la
/// première entrée de la semaine suivante dans L'énigme de la semaine : les
/// jokers et le joker rouge du top 10 % ne sont remis qu'à ce moment-là, sur
/// le classement final. Perdu si le joueur ne revient pas pendant la semaine
/// suivante.
class EnigmeBilan {
  final String weekId;
  final int enigmeIndex;
  final bool solved;
  final int? solveSeconds;
  final int? solvedDay;
  final bool scoreSubmitted;
  // Semaine résolue avec une version qui donnait les jokers à la résolution :
  // le bilan ne doit pas les redonner.
  final bool rewardsAlreadyGranted;
  final bool redJokerAlreadyGranted;

  const EnigmeBilan({
    required this.weekId,
    required this.enigmeIndex,
    required this.solved,
    this.solveSeconds,
    this.solvedDay,
    this.scoreSubmitted = false,
    this.rewardsAlreadyGranted = false,
    this.redJokerAlreadyGranted = false,
  });

  Map<String, dynamic> toJson() => {
        'weekId': weekId,
        'enigmeIndex': enigmeIndex,
        'solved': solved,
        'solveSeconds': solveSeconds,
        'solvedDay': solvedDay,
        'scoreSubmitted': scoreSubmitted,
        'rewardsAlreadyGranted': rewardsAlreadyGranted,
        'redJokerAlreadyGranted': redJokerAlreadyGranted,
      };

  factory EnigmeBilan.fromJson(Map<String, dynamic> json) => EnigmeBilan(
        weekId: json['weekId'] as String,
        enigmeIndex: json['enigmeIndex'] as int,
        solved: json['solved'] as bool? ?? false,
        solveSeconds: json['solveSeconds'] as int?,
        solvedDay: json['solvedDay'] as int?,
        scoreSubmitted: json['scoreSubmitted'] as bool? ?? false,
        rewardsAlreadyGranted: json['rewardsAlreadyGranted'] as bool? ?? false,
        redJokerAlreadyGranted: json['redJokerAlreadyGranted'] as bool? ?? false,
      );
}
