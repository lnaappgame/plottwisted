import 'dart:math';

const int kEloDepart = 2000;
const int kEloPlancher = 250;
const int kEloPlafond = 5000;

/// Titres honorifiques, par tranches de 100 points de 250 à 5000 — le titre
/// affiché est celui du seuil le plus haut atteint. 3ᵉ élément = équivalent
/// anglais (périmètre bilingue V1 — voir base de données US, feuille
/// "Titres honorifiques", pas de marqueur V1 donc tout est importé).
const List<(int, String, String)> kTitresHonorifiques = [
  (250, 'Stagiaire café du plateau, en passe de se faire virer', 'Coffee-run intern, about to get fired'),
  (300, 'Porteur de câbles', 'Cable wrangler'),
  (400, 'Stagiaire régie', 'Production office intern'),
  (500, 'Assistant clapman', 'Assistant clapper loader'),
  (600, 'Apprenti clapman', 'Clapper loader'),
  (700, 'Stagiaire maquillage', 'Makeup trainee'),
  (800, 'Assistant coiffure', 'Hair assistant'),
  (900, 'Stagiaire costumes', 'Wardrobe intern'),
  (1000, 'Assistant accessoiriste', 'Assistant props master'),
  (1100, 'Régisseur adjoint', 'Assistant location manager'),
  (1200, 'Perchman débutant', 'Junior boom operator'),
  (1300, 'Ingénieur du son junior', 'Junior sound engineer'),
  (1400, 'Stagiaire scripte', 'Script trainee'),
  (1500, 'Scripte de plateau', 'Script supervisor'),
  (1600, 'Assistant décorateur', 'Assistant set decorator'),
  (1700, 'Chef costumier', 'Costume supervisor'),
  (1800, 'Second assistant réalisateur', 'Second assistant director'),
  (1900, 'Premier assistant réalisateur', 'First assistant director'),
  (2000, 'Chef machiniste', 'Head grip'),
  (2100, 'Chef électricien', 'Gaffer'),
  (2200, 'Cadreur', 'Camera operator'),
  (2300, 'Nommé au césar du meilleur espoir', 'Golden Globe New Star nominee'),
  (2400, 'Assistant monteur', 'Assistant editor'),
  (2500, 'Étalonneur', 'Colorist'),
  (2600, 'Monteur émérite', 'Celebrated film editor'),
  (2700, 'Chef opérateur son', 'Sound mixer'),
  (2800, 'Compositeur de la bande originale', 'Film composer'),
  (2900, 'Second rôle remarqué', 'Breakout supporting actor'),
  (3000, 'Producteur associé', 'Associate producer'),
  (3100, 'Premier rôle secondaire', 'Featured co-star'),
  (3200, 'Tête d\'affiche', 'Marquee name'),
  (3300, 'Vedette bankable', 'Bankable star'),
  (3400, 'Directeur de la photographie primé', 'Award-winning cinematographer'),
  (3500, 'Scénariste primé', 'Celebrated screenwriter'),
  (3600, 'Réalisateur prometteur', 'Up-and-coming director'),
  (3700, 'Réalisateur à succès', 'Box office director'),
  (3800, 'Producteur exécutif', 'Executive producer'),
  (3900, 'Nommé aux César', 'SAG Award nominee'),
  (4000, 'Second couteau récompensé', 'Celebrated supporting actor'),
  (4100, 'Étoile montante', 'Rising star'),
  (4200, 'Grand prix du jury à Cannes', 'Sundance Grand Jury Prize winner'),
  (4300, 'Triple nomination aux BAFTA', 'Triple BAFTA nominee'),
  (4400, 'Réalisateur culte', 'Cult director'),
  (4500, 'Nommé aux Oscars', 'Oscar nominee'),
  (4600, 'Lauréat du Festival de Cannes', 'Cannes Film Festival winner'),
  (4700, 'Césarisé', 'SAG Award winner'),
  (4800, 'Multi-oscarisé', 'Multiple Academy Award winner'),
  (4900, 'Palme d\'or de la rapidité', 'Speed-run Palme d\'Or'),
  (5000, 'Légende du septième art', 'Legend of the Silver Screen'),
];

/// Le titre honorifique correspondant à [elo] — celui du seuil le plus haut
/// atteint (jamais rien en dessous de 250, le plancher Elo).
String titreForElo(int elo, [String locale = 'fr']) {
  var titre = locale == 'en' ? kTitresHonorifiques.first.$3 : kTitresHonorifiques.first.$2;
  for (final (seuil, nomFr, nomUs) in kTitresHonorifiques) {
    if (elo >= seuil) titre = locale == 'en' ? nomUs : nomFr;
  }
  return titre;
}

/// K-factor inspiré du système Elo des échecs (FIDE) : élevé pendant la
/// calibration pour converger vite vers le vrai niveau, puis de plus en plus
/// bas à mesure que l'Elo grimpe, pour stabiliser le haut du classement.
int kFactorFor({required bool isCalibration, required int elo}) {
  if (isCalibration) return 40;
  if (elo >= 4500) return 5;
  if (elo >= 4000) return 10;
  return 20;
}

/// Score espéré (formule Elo standard) : probabilité de victoire de
/// [rating] face à [adversaire].
double expectedScore(double rating, double adversaire) {
  return 1 / (1 + pow(10, (adversaire - rating) / 400));
}

/// Nouveau score Elo après un match. [scoreReel] = 1 (victoire), 0.5 (nul),
/// 0 (défaite). [eloAdversaireMoyen] est la moyenne des Elo des fantômes
/// affrontés sur les manches du match (un fantôme différent par manche —
/// il n'y a donc pas un adversaire unique à comparer, on moyenne).
/// Toujours borné entre [kEloPlancher] et [kEloPlafond].
int nouvelElo({
  required int eloJoueur,
  required double eloAdversaireMoyen,
  required double scoreReel,
  required int kFactor,
}) {
  final delta = kFactor * (scoreReel - expectedScore(eloJoueur.toDouble(), eloAdversaireMoyen));
  var deltaArrondi = delta.round();
  // Même face à un très gros écart de classement, une victoire ne doit
  // jamais rapporter 0 point (ni une défaite n'en coûter 0) — garantit au
  // moins ±1 dès que le résultat n'est pas un match nul (scoreReel == 0.5,
  // seul cas où 0 point est un résultat légitime).
  if (scoreReel != 0.5 && deltaArrondi == 0) {
    deltaArrondi = scoreReel > 0.5 ? 1 : -1;
  }
  final resultat = eloJoueur + deltaArrondi;
  return resultat.clamp(kEloPlancher, kEloPlafond);
}
