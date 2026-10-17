import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform, debugPrint;

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
  /// sécurité Firestore), identifié par son UID anonyme. Retourne `true` si
  /// le score est bien dans le classement (envoyé maintenant ou déjà là),
  /// `false` s'il faudra réessayer (hors ligne, panne).
  Future<bool> submitScore({
    required String weekId,
    required int solveSeconds,
    required int solvedDay,
  }) async {
    const delai = Duration(seconds: 10);
    try {
      await _ensureReady();
      final db = _db;
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (db == null || uid == null) return false;
      final ref = db.collection('enigme_leaderboard').doc(weekId).collection('scores').doc(uid);
      // Déjà enregistré (envoi précédent dont la confirmation s'est perdue) :
      // les règles interdisent de le réécrire. Lecture serveur uniquement :
      // hors ligne, elle échoue tout de suite au lieu de lire le cache.
      final existing = await ref.get(const GetOptions(source: Source.server)).timeout(delai);
      if (existing.exists) return true;
      // Hors ligne, Firestore garde l'écriture en attente sans jamais
      // répondre : le délai évite d'attendre indéfiniment.
      await ref.set({
        'solveSeconds': solveSeconds,
        'solvedDay': solvedDay,
        'timestamp': FieldValue.serverTimestamp(),
      }).timeout(delai);
      return true;
    } catch (_) {
      // Le classement n'est jamais bloquant : on réessaiera plus tard.
      return false;
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
      // Le total de la semaine est gardé une heure : chaque comptage coûte
      // 1 lecture par tranche de 1 000 joueurs, et ce rang est relu à chaque
      // ouverture de l'énigme résolue.
      final now = DateTime.now();
      final cached = _totals[weekId];
      var total = cached?.$1;
      if (total == null || now.difference(cached!.$2) > const Duration(hours: 1)) {
        final totalSnap = await scores.count().get();
        total = totalSnap.count ?? 0;
        _totals[weekId] = (total, now);
      }
      final meilleursSnap = await scores.where('solveSeconds', isLessThan: solveSeconds).count().get();
      final rang = (meilleursSnap.count ?? 0) + 1;
      // Un total gardé peut dater un peu : jamais moins de joueurs que le rang.
      return LeaderboardResult(rang: rang, total: total < rang ? rang : total);
    } catch (e) {
      debugPrint('fetchRank: $e');
      return null;
    }
  }

  final Map<String, (int, DateTime)> _totals = {};
}
