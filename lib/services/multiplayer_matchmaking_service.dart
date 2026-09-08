import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// Un enregistrement de partie fantôme trouvé pour une énigme donnée.
class GhostRun {
  final double eloAtTimeOfPlay;
  final double? solveSeconds; // null = le fantôme n'a pas trouvé dans les 60s
  final String nomJoueur;
  const GhostRun({required this.eloAtTimeOfPlay, this.solveSeconds, required this.nomJoueur});
}

/// Nombre minimum de joueurs enregistrés dans `multiplayer_players` avant
/// qu'un pourcentage mondial ait un sens statistique — en dessous, un joueur
/// isolé se retrouverait toujours à "top 1%" ou "top 100%", ce qui n'apporte
/// rien et pourrait induire en erreur.
const int kMultiplayerTopPercentMinJoueurs = 20;

/// Recherche et enregistrement des parties fantômes du mode Multijoueur.
/// Chaque énigme réellement jouée par un joueur s'enregistre indépendamment
/// dans
/// `multiplayer_runs/{enigmeId}/runs/{autoId}` — le matching se fait manche
/// par manche, jamais au niveau du match entier (voir docs/multijoueur-elo-spec.md).
/// Aucune vérification serveur du temps de réponse : comme L'énigme de la
/// semaine et Défi du jour, on fait confiance au joueur.
class MultiplayerMatchmakingService {
  FirebaseFirestore? _db;
  final Random _rng = Random();

  bool get _supported =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _ensureReady() async {
    if (!_supported) return;
    _db ??= FirebaseFirestore.instance;
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  }

  /// Cherche un fantôme pour [enigmeId] à un Elo proche de [elo] — fourchette
  /// ± 50, élargie par paliers de 50 en boucle jusqu'à en trouver un.
  /// Plafonnée à ± 2000 (40 paliers) pour éviter une boucle infinie si cette
  /// énigme précise n'a encore jamais été jouée en dehors de la calibration
  /// (cas limite documenté) — retourne alors `null`, à l'appelant de gérer
  /// ce cas (ex. piocher une autre énigme du pool).
  Future<GhostRun?> fetchGhost({required String enigmeId, required int elo, String locale = 'fr'}) async {
    try {
      await _ensureReady();
      final db = _db;
      if (db == null) return null;
      final runs = db.collection('multiplayer_runs').doc(enigmeId).collection('runs');

      for (var range = 50; range <= 2000; range += 50) {
        final snap = await runs
            .where('eloAtTimeOfPlay', isGreaterThanOrEqualTo: elo - range)
            .where('eloAtTimeOfPlay', isLessThanOrEqualTo: elo + range)
            .limit(10)
            .get();
        if (snap.docs.isEmpty) continue;
        final chosen = snap.docs[_rng.nextInt(snap.docs.length)];
        final data = chosen.data();
        return GhostRun(
          eloAtTimeOfPlay: (data['eloAtTimeOfPlay'] as num).toDouble(),
          solveSeconds: (data['solveSeconds'] as num?)?.toDouble(),
          nomJoueur: data['nomJoueur'] as String? ?? (locale == 'en' ? 'Anonymous player' : 'Joueur anonyme'),
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Enregistre la performance du joueur sur cette énigme — toujours, même
  /// quand cette manche a elle-même utilisé le temps fantôme de secours
  /// (sinon une énigme sous le seuil de [countRunsForEnigme] ne
  /// l'atteindrait jamais). [solveSeconds] = null si le joueur n'a pas
  /// trouvé dans les 60 secondes. [nomJoueur] est celui qui sera affiché aux
  /// futurs adversaires qui tomberont sur cet enregistrement.
  Future<void> recordRun({
    required String enigmeId,
    required int elo,
    required double? solveSeconds,
    required String nomJoueur,
  }) async {
    try {
      await _ensureReady();
      final db = _db;
      if (db == null) return;
      await db.collection('multiplayer_runs').doc(enigmeId).collection('runs').add({
        'eloAtTimeOfPlay': elo,
        'solveSeconds': solveSeconds,
        'nomJoueur': nomJoueur,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Jamais bloquant pour le joueur.
    }
  }

  /// Nombre de vraies parties déjà enregistrées pour [enigmeId] précisément
  /// (pas toutes énigmes confondues) — sert à décider si cette énigme a
  /// assez de recul pour un vrai matching par Elo, ou si elle doit encore
  /// utiliser le temps fantôme fixe de secours (voir
  /// kMultiplayerCalibrationMinRuns dans multiplayer_state.dart).
  Future<int> countRunsForEnigme(String enigmeId) async {
    try {
      await _ensureReady();
      final db = _db;
      if (db == null) return 0;
      final snap = await db.collection('multiplayer_runs').doc(enigmeId).collection('runs').count().get();
      return snap.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Met à jour le classement Elo courant du joueur dans
  /// `multiplayer_players/{uid}` — un document par joueur (contrairement à
  /// `multiplayer_runs`, qui accumule un enregistrement par manche). Sert
  /// uniquement au calcul du pourcentage mondial ([fetchTopPercent]), jamais
  /// au matching des fantômes. Jamais bloquant pour le joueur.
  Future<void> updatePlayerElo({required int elo}) async {
    try {
      await _ensureReady();
      final db = _db;
      if (db == null) return;
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      await db.collection('multiplayer_players').doc(uid).set({
        'elo': elo,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  /// Pourcentage mondial approximatif ("tu es dans le top X %") : proportion
  /// de joueurs enregistrés dont l'Elo est strictement inférieur au sien.
  /// Retourne `null` tant que le pool de joueurs enregistrés est trop petit
  /// pour que le chiffre soit significatif (voir
  /// [kMultiplayerTopPercentMinJoueurs]), ou en cas d'erreur/plateforme non
  /// supportée.
  Future<double?> fetchTopPercent({required int elo}) async {
    try {
      await _ensureReady();
      final db = _db;
      if (db == null) return null;
      final joueurs = db.collection('multiplayer_players');
      final totalSnap = await joueurs.count().get();
      final total = totalSnap.count ?? 0;
      if (total < kMultiplayerTopPercentMinJoueurs) return null;
      final belowSnap = await joueurs.where('elo', isLessThan: elo).count().get();
      final below = belowSnap.count ?? 0;
      return (100 - (below / total * 100)).clamp(0, 100);
    } catch (_) {
      return null;
    }
  }
}
