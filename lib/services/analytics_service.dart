import 'dart:async';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform, visibleForTesting;

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
/// Nom de l'événement d'une case du calendrier de l'Avent trouvée (jamais un
/// nom réservé par Firebase : voir test/advent_calendar_test.dart).
const kAdventCaseSolvedEvent = 'advent_case_solved';

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

  /// Un pitch de l'event Halloween trouvé ([pitch] = index de 0 à 29, [solved] = total trouvé).
  Future<void> logHalloweenPitchSolved({required int pitch, required int solved}) =>
      _log('halloween_pitch_solved', {'pitch': pitch, 'solved': solved});

  /// Une case du calendrier de l'Avent trouvée : [day] = numéro de la case (1
  /// à 25), [onTime] = trouvée le jour même (1) ou rattrapée plus tard (0).
  Future<void> logAdventCaseSolved({required int day, required bool onTime}) =>
      _log(kAdventCaseSolvedEvent, {'day': day, 'on_time': onTime ? 1 : 0});

  /// Un tour de la bobine du jour : [segment] = index dans kWheelSegments.
  Future<void> logWheelSpin({required bool afterAd, required int segment}) =>
      _log('wheel_spin', {'after_ad': afterAd ? 1 : 0, 'segment': segment});

  // ─── Mesure du premier lancement et du consentement (1.0.16, B4) ───

  /// Début du premier lancement (tutoriel).
  Future<void> logTutorialBegin() => _log('tutorial_begin', {});

  /// Une étape du premier lancement franchie ([step] à partir de 1).
  Future<void> logTutorialStep({required int step, required String stepName}) =>
      _log('tutorial_step', {'step': step, 'step_name': stepName});

  /// Fin du tutoriel ; [seconds] = temps de jeu au premier plan.
  Future<void> logTutorialComplete({required int seconds}) => _log('tutorial_complete', {'seconds': seconds});

  /// Le joueur sort du tutoriel avec « J'ai déjà joué ».
  Future<void> logTutorialSkip({required int seconds}) => _log('tutorial_skip', {'seconds': seconds});

  /// Un niveau commence (monde 0 = tutoriel).
  Future<void> logLevelStart({required int world, required int level}) =>
      _log('level_start', {'world': world, 'level': level});

  /// Un niveau est laissé sans être résolu : [reason] = `postpone` (« Passer,
  /// revenir plus tard ») ou `skip_tutorial` (« J'ai déjà joué »).
  Future<void> logLevelAbandon({required int world, required int level, required int seconds, required String reason}) =>
      _log('level_abandon', {'world': world, 'level': level, 'seconds': seconds, 'reason': reason});

  /// Ouverture (ou lecture sans fenêtre) du consentement : [trigger] =
  /// `already_set`, `first_success`, `video` ou `fallback` (règle C7).
  Future<void> logConsentPrompt({required String trigger, required int seconds}) =>
      _log('consent_prompt', {'trigger': trigger, 'seconds': seconds});

  // ─── Classement sur l'avancée (1.0.16) ───

  /// Écran du classement ouvert : [rankBucket] = tranche du rang affiché
  /// (`top10`, `top50`, `top100`, `top1000`, `more`, `none` sans niveau
  /// résolu, `offline` si indisponible) ; [joined] = le joueur y apparaît.
  /// Jamais le rang exact ni le pseudo.
  Future<void> logLeaderboardOpen({required String rankBucket, required bool joined}) =>
      _log('leaderboard_open', {'rank_bucket': rankBucket, 'joined': joined ? 1 : 0});

  /// Le joueur choisit d'apparaître dans le classement.
  Future<void> logLeaderboardJoin() => _log('leaderboard_join', {});

  /// Le joueur se retire du classement.
  Future<void> logLeaderboardLeave() => _log('leaderboard_leave', {});

  // ─── Envoi, avec mise en mémoire avant la réponse au consentement ───

  /// Événements d'avant la réponse au consentement : gardés en mémoire sur le
  /// téléphone, rien ne part. Après l'accord ils partent (une fois) ; après un
  /// refus ils sont effacés.
  static final List<(String, Map<String, Object>)> _beforeConsent = [];
  static bool _consentDecided = false;
  static bool _analyticsAllowed = false;

  /// Au plus 200 événements en attente (les suivants sont ignorés).
  static const maxBeforeConsent = 200;

  /// Nombre d'événements en attente de la réponse (tests).
  @visibleForTesting
  static int get waitingCount => _beforeConsent.length;

  /// Envoi réel d'un événement à Firebase (remplacé dans les tests).
  @visibleForTesting
  static Future<void> Function(String name, Map<String, Object> parameters) sender =
      (name, parameters) => FirebaseAnalytics.instance.logEvent(name: name, parameters: parameters);

  /// Force la prise en charge de la plateforme (tests, hôte sans Firebase).
  @visibleForTesting
  static bool? supportedOverride;

  @visibleForTesting
  static void resetForTests() {
    _beforeConsent.clear();
    _consentDecided = false;
    _analyticsAllowed = false;
    supportedOverride = null;
  }

  /// Noms réservés par Firebase : jamais envoyés (un `logEvent` avec l'un
  /// d'eux est rejeté, et `session_start` a déjà fait planter un jeu du studio).
  static bool isReservedName(String name) {
    const reserved = {
      'ad_activeview', 'ad_click', 'ad_exposure', 'ad_impression', 'ad_query', 'adunit_exposure', //
      'app_background', 'app_clear_data', 'app_exception', 'app_remove', 'app_store_refund', //
      'app_store_subscription_cancel', 'app_store_subscription_convert', 'app_store_subscription_renew', //
      'app_update', 'app_upgrade', 'dynamic_link_app_open', 'dynamic_link_first_open', 'error', 'first_open', //
      'first_visit', 'in_app_purchase', 'notification_dismiss', 'notification_foreground', 'notification_open', //
      'notification_receive', 'os_update', 'screen_view', 'session_start', 'user_engagement', //
    };
    return reserved.contains(name) ||
        name.startsWith('firebase_') ||
        name.startsWith('google_') ||
        name.startsWith('ga_');
  }

  /// La réponse au consentement est connue : ce qui attendait part si la
  /// mesure est permise, sinon c'est effacé. Les changements suivants
  /// (« Options de confidentialité des pubs ») passent aussi par ici.
  static void consentDecided(bool analyticsOn) {
    _consentDecided = true;
    _analyticsAllowed = analyticsOn;
    final waiting = List.of(_beforeConsent);
    _beforeConsent.clear();
    if (!analyticsOn) return;
    for (final (name, params) in waiting) {
      _send(name, params);
    }
  }

  static void _send(String name, Map<String, Object> params) {
    try {
      unawaited(sender(name, params).catchError((Object _) {}));
    } catch (_) {}
  }

  Future<void> _log(String name, Map<String, Object> params) async {
    if (!(supportedOverride ?? _supported)) return;
    if (isReservedName(name)) return;
    if (!_consentDecided) {
      if (_beforeConsent.length < maxBeforeConsent) _beforeConsent.add((name, params));
      return;
    }
    if (!_analyticsAllowed) return;
    _send(name, params);
  }
}
