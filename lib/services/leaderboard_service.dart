import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// Identifiant de semaine stable (YYYY-MM-DD, correspondant au lundi 00h00
/// GMT) utilisé comme clé de document dans Firestore.
String weekIdFor(DateTime weekStartUtc) => weekStartUtc.toIso8601String().split('T').first;

class LeaderboardResult {
  final int rang;
  final int total;
  const LeaderboardResult({required this.rang, required this.total});
}

/// Classement au temps de "L'énigme de la semaine" — anonyme (aucun compte,
/// aucun nom joueur transmis), stocké dans Firestore sous
/// `enigme_leaderboard/{weekId}/scores/{uid anonyme}`.
///
/// Toute erreur réseau ou d'indisponibilité de Firebase est avalée et
/// retourne simplement `null` : le classement est une fonctionnalité de
/// confort, jamais bloquante pour jouer.
class LeaderboardService {
  FirebaseFirestore? _db;
  bool get _supported =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _ensureReady() async {
    if (!_supported) return;
    _db ??= FirebaseFirestore.instance;
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  }

  /// Enregistre le temps de résolution du joueur pour la semaine [weekId].
  /// Un joueur ne peut écrire que son propre document (voir règles de
  /// sécurité Firestore), identifié par son UID anonyme.
  Future<void> submitScore({
    required String weekId,
    required int solveSeconds,
    required int solvedDay,
  }) async {
    try {
      await _ensureReady();
      final db = _db;
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (db == null || uid == null) return;
      await db
          .collection('enigme_leaderboard')
          .doc(weekId)
          .collection('scores')
          .doc(uid)
          .set({
        'solveSeconds': solveSeconds,
        'solvedDay': solvedDay,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Le classement n'est jamais bloquant : on ignore silencieusement.
    }
  }

  /// Calcule le rang du joueur (1 = le plus rapide) et le nombre total de
  /// joueurs ayant résolu cette énigme cette semaine-là. Retourne `null` si
  /// indisponible (hors-ligne, erreur, plateforme non supportée...).
  Future<LeaderboardResult?> fetchRank({
    required String weekId,
    required int solveSeconds,
  }) async {
    try {
      await _ensureReady();
      final db = _db;
      if (db == null) return null;
      final scores = db.collection('enigme_leaderboard').doc(weekId).collection('scores');
      final totalSnap = await scores.count().get();
      final total = totalSnap.count ?? 0;
      final meilleursSnap = await scores.where('solveSeconds', isLessThan: solveSeconds).count().get();
      final rang = (meilleursSnap.count ?? 0) + 1;
      return LeaderboardResult(rang: rang, total: total);
    } catch (_) {
      return null;
    }
  }
}
