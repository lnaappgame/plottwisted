/// Catégorie d'un "commun" du mode Défi du jour.
enum DefiType { personnage, acteur, realisateur, film }

String defiTypeLabel(DefiType t, [String locale = 'fr']) => locale == 'en'
    ? switch (t) {
        DefiType.personnage => 'Character',
        DefiType.acteur => 'Actor',
        DefiType.realisateur => 'Director',
        DefiType.film => 'Movie',
      }
    : switch (t) {
        DefiType.personnage => 'Personnage',
        DefiType.acteur => 'Acteur',
        DefiType.realisateur => 'Réalisateur',
        DefiType.film => 'Film',
      };

/// Une case-réponse du Défi du jour, associée à un indice dédié — révélé une
/// seule fois, dans l'ordre de la liste [Defi.cases].
class DefiCase {
  final String reponse;
  final String indice;
  // Équivalents anglais (périmètre bilingue V1 — voir base de données US).
  final String reponseUs;
  final String indiceUs;

  const DefiCase({
    required this.reponse,
    required this.indice,
    this.reponseUs = '',
    this.indiceUs = '',
  });

  String reponseFor(String locale) => locale == 'en' ? reponseUs : reponse;
  String indiceFor(String locale) => locale == 'en' ? indiceUs : indice;
}

/// Un "commun" complet du Défi du jour (ex. "Batman", "Jean-Paul Belmondo") :
/// un thème partagé par toutes ses cases-réponses, chacune associée à un
/// indice qui lui est propre.
class Defi {
  final String id; // slug stable, ex. "batman" — sert de clé Firestore/locale
  final DefiType type;
  final String commun;
  final String consigne;
  final List<DefiCase> cases; // dans l'ordre de révélation des indices

  // Équivalents anglais (périmètre bilingue V1 — voir base de données US).
  final String communUs;
  final String consigneUs;

  const Defi({
    required this.id,
    required this.type,
    required this.commun,
    required this.consigne,
    required this.cases,
    this.communUs = '',
    this.consigneUs = '',
  });

  String get typeLabel => defiTypeLabel(type);
  String typeLabelFor(String locale) => defiTypeLabel(type, locale);
  String communFor(String locale) => locale == 'en' ? communUs : commun;
  String consigneFor(String locale) => locale == 'en' ? consigneUs : consigne;
}
