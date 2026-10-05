import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// Fine enveloppe autour de Firebase Analytics — jamais bloquant, jamais
/// d'exception remontée à l'appelant (même philosophie que les autres
/// services réseau de l'app : Firestore, matchmaking...). Sert uniquement à
/// comprendre la rétention et le tunnel de conversion une fois en
/// production ; aucune décision de gameplay n'en dépend jamais.
///
/// Le geste RGPD lui-même (activer/couper la collecte selon le consentement)
/// vit dans main.dart, pas ici : `logEvent` appelé pendant que la collecte
/// est coupée est un no-op silencieux côté SDK Firebase, donc cette classe
/// n'a pas besoin de connaître l'état du consentement.
class AnalyticsService {
  bool get _supported =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> logLevelCompleted({required int world, required int level, required String difficulty}) =>
      _log('level_completed', {'world': world, 'level': level, 'difficulty': difficulty});

  Future<void> logSkipJokerUsed({required int world, required int level}) =>
      _log('skip_joker_used', {'world': world, 'level': level});

  Future<void> logDefiCompleted({required bool bonus, required int seconds}) =>
      _log('defi_completed', {'bonus': bonus, 'seconds': seconds});

  Future<void> logEnigmeSolved({required int day}) => _log('enigme_solved', {'day': day});

  Future<void> logMultiplayerMatchResult({required String result, required int eloApres}) =>
      _log('multiplayer_match_result', {'result': result, 'elo_apres': eloApres});

  Future<void> logAdWatched({required String type}) => _log('ad_watched', {'type': type});

  /// Le joueur vient de terminer le tout dernier niveau du tout dernier
  /// monde disponible (Jeu principal) — pas de nouveau contenu à proposer
  /// tant qu'une mise à jour n'en ajoute pas. [worldCount] = nombre de
  /// mondes qui existaient à cet instant, pour distinguer plus tard les
  /// joueurs ayant fini un catalogue étendu de ceux ayant fini l'actuel.
  Future<void> logAllContentCompleted({required int worldCount}) =>
      _log('all_content_completed', {'world_count': worldCount});

  Future<void> logPurchase({required String productId}) => _log('purchase_completed', {'product_id': productId});

  Future<void> _log(String name, Map<String, Object> params) async {
    if (!_supported) return;
    try {
      await FirebaseAnalytics.instance.logEvent(name: name, parameters: params);
    } catch (_) {}
  }
}
