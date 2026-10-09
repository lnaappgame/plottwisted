/// Catégorie d'une énigme du mode Multijoueur.
enum MultiplayerType { film, personnage, acteur, actrice, realisateur, realisatrice, personnalite, serie }

MultiplayerType multiplayerTypeFromLabel(String label) {
  switch (label.trim().toLowerCase()) {
    case 'film':
      return MultiplayerType.film;
    case 'actrice':
      return MultiplayerType.actrice;
    case 'réalisatrice':
    case 'realisatrice':
      return MultiplayerType.realisatrice;
    case 'acteur':
      return MultiplayerType.acteur;
    case 'réalisateur':
    case 'realisateur':
      return MultiplayerType.realisateur;
    case 'personnalité':
    case 'personnalite':
      return MultiplayerType.personnalite;
    case 'série':
    case 'serie':
      return MultiplayerType.serie;
    default:
      return MultiplayerType.personnage;
  }
}

/// Libellé affiché en jeu pour la catégorie d'une énigme Multijoueur (ce que
/// le joueur doit deviner) — même principe que [defiTypeLabel].
String multiplayerTypeLabel(MultiplayerType t, [String locale = 'fr']) => locale == 'en'
    ? switch (t) {
        MultiplayerType.film => 'Movie',
        MultiplayerType.personnage => 'Character',
        MultiplayerType.acteur => 'Actor',
        MultiplayerType.actrice => 'Actress',
        MultiplayerType.realisateur => 'Director',
        MultiplayerType.realisatrice => 'Director',
        MultiplayerType.personnalite => 'Public figure',
        MultiplayerType.serie => 'TV Show',
      }
    : switch (t) {
        MultiplayerType.film => 'Film',
        MultiplayerType.personnage => 'Personnage',
        MultiplayerType.acteur => 'Acteur',
        MultiplayerType.actrice => 'Actrice',
        MultiplayerType.realisateur => 'Réalisateur',
        MultiplayerType.realisatrice => 'Réalisatrice',
        MultiplayerType.personnalite => 'Personnalité',
        MultiplayerType.serie => 'Série',
      };

/// Une énigme du mode Multijoueur : un pitch révélé lettre par lettre (en
/// 35 secondes pile, quelle que soit sa longueur) et une réponse à deviner
/// via la grille de tuiles, comme les autres modes.
class MultiplayerEnigme {
  final String id;
  final MultiplayerType type;
  final String pitch;
  final String reponse;

  // Équivalents anglais (périmètre bilingue V1 — voir base de données US).
  final String pitchUs;
  final String reponseUs;

  const MultiplayerEnigme({
    required this.id,
    required this.type,
    required this.pitch,
    required this.reponse,
    this.pitchUs = '',
    this.reponseUs = '',
  });

  String pitchFor(String locale) => locale == 'en' ? pitchUs : pitch;
  String reponseFor(String locale) => locale == 'en' ? reponseUs : reponse;
  String typeLabelFor(String locale) => multiplayerTypeLabel(type, locale);
}

/// Une entrée de l'historique local des matchs Multijoueur (les 10
/// dernières, la plus récente en premier) — juste le résultat et
/// l'évolution du classement Elo, sans le détail des manches.
class MultiplayerMatchHistoryEntry {
  final String resultat; // 'victoire' | 'defaite' | 'nul'
  final int eloAvant;
  final int eloApres;
  final DateTime date;

  const MultiplayerMatchHistoryEntry({
    required this.resultat,
    required this.eloAvant,
    required this.eloApres,
    required this.date,
  });

  int get delta => eloApres - eloAvant;

  Map<String, dynamic> toJson() => {
        'resultat': resultat,
        'eloAvant': eloAvant,
        'eloApres': eloApres,
        'date': date.toIso8601String(),
      };

  factory MultiplayerMatchHistoryEntry.fromJson(Map<String, dynamic> json) => MultiplayerMatchHistoryEntry(
        resultat: json['resultat'] as String,
        eloAvant: json['eloAvant'] as int,
        eloApres: json['eloApres'] as int,
        date: DateTime.parse(json['date'] as String),
      );
}
