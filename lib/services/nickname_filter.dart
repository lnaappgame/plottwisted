/// Filtre basique du pseudo affiché aux autres joueurs (Multijoueur).
///
/// Le pseudo reste libre et visible tel quel pour le joueur lui-même ; seul
/// ce qui part en ligne (`multiplayer_runs.nomJoueur`, montré aux futurs
/// adversaires) est remplacé par le nom par défaut s'il est jugé
/// inacceptable : insulte ou propos haineux (FR/EN, y compris en « leet »
/// 3 = e, 0 = o…), lien, adresse e-mail ou numéro de téléphone.
///
/// Volontairement basique (engagement de la politique de confidentialité,
/// 1.0.13) : pas de modération humaine, et l'on préfère laisser passer un
/// cas limite plutôt que bloquer un vrai prénom. D'où deux listes :
/// - [_motsInterdits] : comparés MOT PAR MOT (« con » bloque « gros con »
///   mais jamais « Constance » ni « Faucon ») ;
/// - [_racinesInterdites] : cherchées n'importe où, uniquement des racines
///   longues sans faux positif connu dans un prénom ou un mot courant
///   (« nique » est exclu : « technique » ; « pute » aussi : « député »).
library;

/// true si [pseudo] peut être montré aux autres joueurs.
bool isNicknameAcceptable(String pseudo) {
  final brut = pseudo.trim().toLowerCase();
  if (brut.isEmpty) return false;

  // Liens et adresses : jamais de contact ni de publicité dans un pseudo.
  if (brut.contains('http') || brut.contains('www') || brut.contains('@')) return false;
  if (RegExp(r'\.(com|fr|net|org|io|be|ch|ca|co|gg|tv|xyz|ly)\b').hasMatch(brut)) return false;
  // Numéro de téléphone (6 chiffres ou plus, espaces et points tolérés).
  if (RegExp(r'\d').allMatches(brut).length >= 6 &&
      RegExp(r'(\d[\s.\-]?){6,}').hasMatch(brut)) {
    return false;
  }

  final normalise = _normaliser(brut);
  final mots = normalise.split(RegExp(r'[^a-z]+')).where((m) => m.isNotEmpty);
  for (final mot in mots) {
    if (_motsInterdits.contains(mot)) return false;
  }
  // Racines longues, y compris collées ou masquées par des séparateurs
  // (« f.u.c.k », « sal_ope »).
  final colle = normalise.replaceAll(RegExp(r'[^a-z]'), '');
  for (final racine in _racinesInterdites) {
    if (colle.contains(racine)) return false;
  }
  return true;
}

/// Minuscules sans accents, chiffres et symboles « leet » ramenés à leur
/// lettre (0 → o, 1 → i, 3 → e, 4 → a, 5 → s, 7 → t, @ → a, $ → s).
String _normaliser(String s) {
  const accents = {
    'à': 'a', 'â': 'a', 'ä': 'a', 'á': 'a', 'ã': 'a', 'å': 'a',
    'ç': 'c',
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
    'î': 'i', 'ï': 'i', 'í': 'i', 'ì': 'i',
    'ô': 'o', 'ö': 'o', 'ó': 'o', 'ò': 'o', 'õ': 'o',
    'û': 'u', 'ü': 'u', 'ú': 'u', 'ù': 'u',
    'ÿ': 'y', 'ñ': 'n', 'œ': 'oe', 'æ': 'ae',
    '0': 'o', '1': 'i', '3': 'e', '4': 'a', '5': 's', '7': 't', r'$': 's',
  };
  final sb = StringBuffer();
  for (final ch in s.split('')) {
    sb.write(accents[ch] ?? ch);
  }
  return sb.toString();
}

const Set<String> _motsInterdits = {
  // Français
  'con', 'conne', 'connard', 'connasse', 'pute', 'putain', 'putes', 'salope',
  'salaud', 'encule', 'enculee', 'nique', 'niquer', 'ntm', 'fdp', 'tg', 'pd',
  'bite', 'chatte', 'couille', 'couilles', 'merde', 'batard', 'negre',
  'negro', 'bougnoule', 'youpin', 'pedale', 'tapette', 'gouine', 'abruti',
  'debile', 'mongol', 'triso', 'enfoire', 'branleur', 'suceuse', 'suce',
  'viol', 'violeur', 'pedo', 'pedophile', 'nazi', 'hitler', 'kkk', 'sexe',
  'porno', 'cul',
  // English
  // (« dick » absent exprès : Moby Dick, Philip K. Dick, Dick Rivers.)
  'fuck', 'fucker', 'fucking', 'shit', 'bitch', 'cunt', 'cock',
  'pussy', 'whore', 'slut', 'nigger', 'nigga', 'faggot', 'fag', 'retard',
  'rape', 'rapist', 'porn', 'sex', 'asshole', 'bastard', 'twat', 'wank',
  'wanker', 'dildo', 'penis', 'vagina', 'boobs', 'tits',
};

const List<String> _racinesInterdites = [
  'fuck', 'connard', 'connasse', 'salope', 'encul', 'enfoire', 'batard',
  'bougnoul', 'youpin', 'pedophil', 'hitler', 'nigger', 'nigga', 'faggot',
  'whore', 'bitch', 'asshole', 'motherf', 'niquetamere', 'tamerelapute',
];
