import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Rappels locaux — jamais de serveur, purement basés sur le calendrier
/// déterministe des modes "Défi du jour" (chaque jour) et "L'énigme de la
/// semaine" (chaque lundi). Le jeu principal et le Multijoueur n'en ont pas
/// pour l'instant : les autres modes suffisent à faire revenir le joueur, et
/// pour le Multijoueur l'idée retenue ("ton temps vient d'être battu,
/// revanche ?") suppose d'enregistrer les parties, ce qui n'est pas encore
/// fait. Jamais bloquant : toute erreur (plateforme non supportée,
/// permission refusée...) est silencieusement absorbée.
class NotificationService {
  static const String _channelId = 'rappels';
  static const String _channelName = 'Rappels de jeu';
  static const String _channelDescription = "Rappels pour Défi du jour et L'énigme de la semaine";

  static const int _idDefiDuJour = 1;
  static const int _idEnigmeSemaine = 2;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  bool get _supported =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> init() async {
    if (!_supported || _initialized) return;
    try {
      tzdata.initializeTimeZones();
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();
      await _plugin.initialize(settings: const InitializationSettings(android: androidInit, iOS: iosInit));
      _initialized = true;
    } catch (_) {
      // Jamais bloquant pour le démarrage de l'app.
    }
  }

  /// Demande la permission d'envoyer des notifications (obligatoire à partir
  /// d'Android 13). Retourne `false` si refusée, non supportée, ou en cas
  /// d'erreur — l'appelant doit alors simplement s'abstenir de planifier.
  Future<bool> requestPermission() async {
    if (!_supported) return false;
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final granted = await _plugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
        return granted ?? false;
      }
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(_channelId, _channelName,
            channelDescription: _channelDescription, importance: Importance.defaultImportance),
        iOS: DarwinNotificationDetails(),
      );

  /// Planifie (ou replanifie) le rappel quotidien de Défi du jour, chaque
  /// jour à [heure]h locale. Idempotent — à rappeler à chaque démarrage de
  /// l'app plutôt que de dépendre de la persistance des alarmes après un
  /// redémarrage du téléphone (non garantie sans receiver natif dédié).
  Future<void> scheduleDailyDefiReminder({int heure = 18, String locale = 'fr'}) async {
    if (!_supported) return;
    try {
      await _plugin.zonedSchedule(
        id: _idDefiDuJour,
        title: locale == 'en' ? '🎯 Daily Challenge' : '🎯 Défi du jour',
        body: locale == 'en'
            ? "A new challenge awaits — come give it a try!"
            : "Un nouveau défi t'attend — viens le tenter !",
        scheduledDate: _prochaineOccurrence(heure: heure),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {}
  }

  /// Planifie (ou replanifie) le rappel hebdomadaire de L'énigme de la
  /// semaine, chaque lundi à [heure]h locale.
  Future<void> scheduleWeeklyEnigmeReminder({int heure = 9, String locale = 'fr'}) async {
    if (!_supported) return;
    try {
      await _plugin.zonedSchedule(
        id: _idEnigmeSemaine,
        title: locale == 'en' ? '🧩 The Weekly Puzzle has started' : "🧩 L'énigme de la semaine a commencé",
        body: locale == 'en'
            ? 'A new puzzle awaits you. Can you beat last week?'
            : 'Une nouvelle énigme vous attend. Ferez-vous mieux que la semaine dernière ?',
        scheduledDate: _prochaineOccurrence(heure: heure, jourSemaine: DateTime.monday),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (_) {}
  }

  /// Prochaine occurrence future de [heure]h locale (aujourd'hui si pas
  /// encore passée, sinon le jour suivant), optionnellement calée sur un
  /// jour de la semaine précis ([jourSemaine], 1 = lundi comme [DateTime.monday]).
  ///
  /// Construit d'abord un [DateTime] "local" au sens de Dart (donc au fuseau
  /// réel de l'appareil), puis le convertit en [tz.TZDateTime] via `.from()`
  /// qui préserve l'instant absolu — peu importe que [tz.local] corresponde
  /// ou non au vrai fuseau de l'appareil (le paquet `timezone` ne le détecte
  /// pas tout seul et vaut UTC par défaut, ce qui décalerait l'heure si on
  /// construisait directement un TZDateTime dans ce fuseau).
  tz.TZDateTime _prochaineOccurrence({required int heure, int? jourSemaine}) {
    final now = DateTime.now();
    var candidat = DateTime(now.year, now.month, now.day, heure);
    if (jourSemaine != null) {
      while (candidat.weekday != jourSemaine) {
        candidat = candidat.add(const Duration(days: 1));
      }
    }
    if (candidat.isBefore(now)) {
      candidat = candidat.add(Duration(days: jourSemaine != null ? 7 : 1));
    }
    return tz.TZDateTime.from(candidat, tz.local);
  }

}
