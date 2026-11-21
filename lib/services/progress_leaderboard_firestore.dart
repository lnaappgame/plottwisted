import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'data_retention.dart';
import 'progress_leaderboard.dart';

/// Accès Firestore du classement sur l'avancée (voir [ProgressLeaderboard]).
///
/// Un document par joueur, identifié par son UID anonyme Firebase :
/// `progress_leaderboard_{fr|en}/{uid}` = { pseudo, score, updatedAt,
/// expireAt }. Les règles (firestore.rules) n'autorisent que l'écriture de
/// son propre document, un score qui ne descend jamais, et sa suppression.
///
/// Lectures serveur uniquement (jamais le cache) et délai de 10 s : hors
/// ligne, Firestore attendrait indéfiniment.
class FirestoreProgressLeaderboardBackend implements ProgressLeaderboardBackend {
  static const _delai = Duration(seconds: 10);
  static const _server = GetOptions(source: Source.server);

  @override
  bool get supported =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String lang) => _db.collection(progressCollectionFor(lang));

  @override
  String? get uid {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null; // Firebase pas encore prêt
    }
  }

  /// UID déjà présent sur ce téléphone, sans en créer : au tout début du
  /// lancement, le compte enregistré peut ne pas être encore rechargé, d'où
  /// la première valeur de authStateChanges (null = vraiment aucun compte).
  Future<String?> _existingUid() async {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser ?? await auth.authStateChanges().first.timeout(_delai);
    return user?.uid;
  }

  /// UID anonyme, créé au besoin (écritures seulement).
  Future<String> _ensureUid() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) await auth.signInAnonymously().timeout(_delai);
    final id = auth.currentUser?.uid;
    if (id == null) throw StateError('pas d’identifiant');
    return id;
  }

  @override
  Future<bool?> fetchEnabled() async {
    if (!supported) return null;
    try {
      final snap = await _db.collection(kAppConfigCollection).doc(kAppConfigDoc).get(_server).timeout(_delai);
      // Document absent = désactivé (valeur lue, gardée en cache).
      return progressLeaderboardEnabledFrom(snap.data());
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> writeEntry({required String lang, required String pseudo, required int score}) async {
    final id = await _ensureUid();
    await _col(lang).doc(id).set({
      'pseudo': pseudo,
      'score': score,
      'updatedAt': FieldValue.serverTimestamp(),
      'expireAt': dataExpiryTimestamp(),
    }).timeout(_delai);
  }

  @override
  Future<void> deleteEntry(String lang) async {
    // Jamais d'identifiant sur ce téléphone : aucun document à supprimer.
    final id = await _existingUid();
    if (id == null) return;
    await _col(lang).doc(id).delete().timeout(_delai);
  }

  @override
  Future<({String pseudo, int score})?> fetchMine(String lang) async {
    final id = await _existingUid();
    if (id == null) return null;
    final snap = await _col(lang).doc(id).get(_server).timeout(_delai);
    final data = snap.data();
    if (data == null) return null;
    final row = _row(id, data);
    if (row.score < 1) return null;
    return (pseudo: row.pseudo, score: row.score);
  }

  ProgressRow _row(String id, Map<String, dynamic> data) {
    final pseudo = data['pseudo'];
    final score = data['score'];
    return ProgressRow(uid: id, pseudo: pseudo is String ? pseudo : '', score: score is num ? score.toInt() : 0);
  }

  @override
  Future<ProgressBoardData> fetchBoard({required String lang, required int? myScore}) async {
    final col = _col(lang);
    // Toutes les requêtes partent ensemble ; un seul index simple (score),
    // créé automatiquement par Firestore.
    final results = await Future.wait<Object?>([
      col.orderBy('score', descending: true).limit(kProgressTopCount).get(_server),
      col.count().get(),
      if (myScore != null) col.where('score', isGreaterThan: myScore).count().get(),
      if (myScore != null)
        col.where('score', isGreaterThan: myScore).orderBy('score').limit(kProgressAboveCount).get(_server),
    ]).timeout(_delai);

    final topSnap = results[0] as QuerySnapshot<Map<String, dynamic>>;
    final total = (results[1] as AggregateQuerySnapshot).count ?? 0;
    final top = rankRows([for (final d in topSnap.docs) _row(d.id, d.data())]);
    if (myScore == null) return ProgressBoardData(top: top, above: const [], total: total, myRank: null);

    final greater = (results[2] as AggregateQuerySnapshot).count ?? 0;
    final aboveSnap = results[3] as QuerySnapshot<Map<String, dynamic>>;
    // Du plus proche au plus haut : le rang de chacun vient du haut du
    // classement s'il y figure, sinon d'un comptage (au plus 3, un par score).
    final aboveAsc = [for (final d in aboveSnap.docs) _row(d.id, d.data())];
    final ranks = <int, int>{};
    for (final r in aboveAsc) {
      if (ranks.containsKey(r.score)) continue;
      final fromTop = rankFromTop(top, r.score);
      if (fromTop != null) {
        ranks[r.score] = fromTop;
      } else {
        final c = await col.where('score', isGreaterThan: r.score).count().get().timeout(_delai);
        ranks[r.score] = (c.count ?? 0) + 1;
      }
    }
    final above = [for (final r in aboveAsc.reversed) r.copyWith(rank: ranks[r.score])];
    return ProgressBoardData(top: top, above: above, total: total, myRank: greater + 1);
  }
}
