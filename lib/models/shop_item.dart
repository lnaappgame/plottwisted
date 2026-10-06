/// Quantité de chaque joker accordée par un article de la boutique.
class JokerGrant {
  final int reveal;
  final int eliminate;
  final int actor;
  final int character;
  final int hint;
  final int redJoker;
  final int skip;
  const JokerGrant({
    this.reveal = 0,
    this.eliminate = 0,
    this.actor = 0,
    this.character = 0,
    this.hint = 0,
    this.redJoker = 0,
    this.skip = 0,
  });

  int get total => reveal + eliminate + actor + character + hint + redJoker + skip;

  /// Répartit [count] jokers le plus équitablement possible entre les 5 types.
  factory JokerGrant.mixed(int count) {
    final base = count ~/ 5;
    final remainder = count % 5;
    final counts = List.generate(5, (i) => base + (i < remainder ? 1 : 0));
    return JokerGrant(reveal: counts[0], eliminate: counts[1], actor: counts[2], character: counts[3], hint: counts[4]);
  }
}

/// Un article de la boutique. **Toute la configuration (quantités, durée de
/// retrait des pubs) est ici** — pour ajuster un paquet, il suffit de
/// modifier [kShopItems] ci-dessous, rien d'autre à toucher.
class ShopItem {
  final String productId; // doit correspondre à l'ID configuré dans Play Console / App Store Connect
  final String label;
  final String? subtitle;
  // Prix barré affiché à côté (effet promo) : somme des prix réels de ces
  // articles achetés séparément, donc toujours dans la devise du joueur.
  final List<String> compareAtProductIds;
  final JokerGrant jokers;
  final bool removesAdsForever;
  final int removeAdsForHours; // 0 = pas de retrait temporaire de pub

  // Équivalents anglais (périmètre bilingue V1 — voir base de données US).
  final String labelUs;
  final String? subtitleUs;

  const ShopItem({
    required this.productId,
    required this.label,
    this.subtitle,
    this.compareAtProductIds = const [],
    this.jokers = const JokerGrant(),
    this.removesAdsForever = false,
    this.removeAdsForHours = 0,
    required this.labelUs,
    this.subtitleUs,
  });

  bool get isConsumable => !removesAdsForever; // rachetable (jokers, ou retrait temporaire)

  String labelFor(String locale) => locale == 'en' ? labelUs : label;
  String? subtitleFor(String locale) => locale == 'en' ? subtitleUs : subtitle;
}

final List<ShopItem> kShopItems = [
  const ShopItem(
    productId: 'remove_ads',
    label: '🚫 Retirer les pubs',
    subtitle: 'Définitif',
    removesAdsForever: true,
    labelUs: '🚫 Remove ads',
    subtitleUs: 'Permanent',
  ),
  ShopItem(
    productId: 'jokers_pack_10',
    label: '🎁 Pack 10 jokers mixtes',
    jokers: JokerGrant.mixed(10),
    labelUs: '🎁 10 mixed jokers pack',
  ),
  ShopItem(
    productId: 'jokers_pack_30_noads',
    label: '🎁 Pack 30 jokers + sans pub',
    compareAtProductIds: ['jokers_pack_10', 'jokers_pack_10', 'jokers_pack_10', 'remove_ads'],
    jokers: JokerGrant.mixed(30),
    removesAdsForever: true,
    labelUs: '🎁 30 jokers + no ads pack',
  ),
  ShopItem(
    productId: 'jokers_pack_100_noads',
    label: '🎁 Pack 100 jokers + sans pub',
    jokers: JokerGrant.mixed(100),
    removesAdsForever: true,
    labelUs: '🎁 100 jokers + no ads pack',
  ),
  const ShopItem(
    productId: 'red_jokers_pack_3',
    label: '🔴 Pack 3 jokers rouges',
    subtitle: 'Débloque un nom orange',
    jokers: JokerGrant(redJoker: 3),
    labelUs: '🔴 3 red jokers pack',
    subtitleUs: 'Unlocks an orange name',
  ),
  const ShopItem(
    productId: 'skip_level_joker',
    label: '⏭️ Joker « Passer définitivement »',
    subtitle: 'Résout le niveau en cours à ta place',
    jokers: JokerGrant(skip: 1),
    labelUs: '⏭️ "Skip for good" joker',
    subtitleUs: 'Solves the current level for you',
  ),
];
