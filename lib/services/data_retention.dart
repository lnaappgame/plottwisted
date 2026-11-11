import 'package:cloud_firestore/cloud_firestore.dart';

/// Durée de conservation des données publiques en ligne (scores de
/// L'énigme de la semaine, manches Multijoueur, Elo) : 24 mois, comme
/// annoncé dans la politique de confidentialité (§ 2.3 et 6) et les CGU
/// (art. 9).
///
/// Chaque écriture porte un champ `expireAt` ; une règle TTL Firestore
/// (console Firebase → Firestore → TTL, sur les groupes de collections
/// `scores`, `runs` et `multiplayer_players`, champ `expireAt`) supprime
/// ensuite le document automatiquement. Les documents écrits avant la
/// 1.0.13 n'ont pas ce champ : à compléter par un script ponctuel avant
/// octobre 2028 (les plus anciens datent d'octobre 2026).
const Duration kDataRetention = Duration(days: 730);

/// Date d'expiration d'un document écrit maintenant.
Timestamp dataExpiryTimestamp({DateTime? now}) =>
    Timestamp.fromDate((now ?? DateTime.now()).add(kDataRetention));
