import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'advent_calendar.dart';

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

  /// Rappels du calendrier de l'Avent : un par case, id = base + jour.
  static const int _idAventBase = 100;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  bool get _supported =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> init() async {
    if (!_supported || _initialized) return;
    try {
      tzdata.initializeTimeZones();
      // Silhouette blanche (res/drawable/ic_stat_clap.xml), jamais l'icône en
      // couleur du jeu : Android la peint en rond blanc dans le volet.
      const androidInit = AndroidInitializationSettings('ic_stat_clap');
      const iosInit = DarwinInitializationSettings();
      await _plugin.initialize(settings: const InitializationSettings(android: androidInit, iOS: iosInit));
      _initialized = true;
    } catch (_) {
      // Jamais bloquant pour le démarrage de l'app.
    }
  }

  /// Demande la permission, puis planifie tous les rappels (Défi du jour,
  /// énigme de la semaine, cases de l'Avent). Au lancement pour un joueur
  /// existant ; à la fin du tutoriel pour un nouveau joueur (1.0.16 : jamais
  /// de demande système pendant la prise en main, c'est le rendez-vous du
  /// lendemain). Sans effet si la permission est refusée.
  Future<void> askAndSchedule({required String locale, required AdventCalendar advent}) async {
    await init();
    final granted = await requestPermission();
    if (!granted) return;
    remindersArmed = true;
    await scheduleDailyDefiReminder(locale: locale);
    await scheduleWeeklyEnigmeReminder(locale: locale);
    await scheduleAdventReminders(advent.reminderTimes(), locale: locale);
  }

  /// Vrai une fois la permission accordée et les rappels posés. Tant qu'il est
  /// faux (nouveau joueur avant la fin du tutoriel, permission refusée), la
  /// reprise ne crée aucun rappel.
  bool remindersArmed = false;

  /// Notifications encore autorisées dans les réglages du téléphone ? (Un
  /// joueur qui les a coupées ne voit jamais un rappel recréé.)
  Future<bool> notificationsEnabled() async {
    if (!_supported) return false;
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return await _plugin
                .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
                ?.areNotificationsEnabled() ??
            false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Annule un rappel par son identifiant.
  Future<void> cancelReminder(int id) async {
    if (!_supported) return;
    try {
      await _plugin.cancel(id: id);
    } catch (_) {}
  }

  /// Retour au premier plan (`AppLifecycleState.resumed`) : sur Android 11, une
  /// alarme inexacte peut partir jusqu'à 75 % du délai restant en retard (un
  /// rappel de 18 h posé à 13 h 42 peut sortir à 21 h 13 ; Android 12+ limite
  /// à 1 h). On annule puis repose les mêmes rappels (mêmes identifiants,
  /// même heure, même mode inexact) pour que le délai restant soit court.
  /// Ne fait rien si les rappels n'ont pas été armés (tutoriel en cours,
  /// permission refusée) ou si le joueur les a coupés.
  Future<void> refreshOnResume({required String locale, required AdventCalendar advent}) async {
    if (!remindersArmed) return;
    if (!await notificationsEnabled()) {
      remindersArmed = false;
      return;
    }
    final advents = advent.reminderTimes();
    await cancelReminder(_idDefiDuJour);
    await cancelReminder(_idEnigmeSemaine);
    for (final day in advents.keys) {
      await cancelReminder(_idAventBase + day);
    }
    await scheduleDailyDefiReminder(locale: locale);
    await scheduleWeeklyEnigmeReminder(locale: locale);
    await scheduleAdventReminders(advents, locale: locale);
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

  /// Planifie (ou replanifie) les rappels du calendrier de l'Avent : un
  /// rappel unique (pas de répétition) par case, à la date donnée par
  /// [times] (jour de la case → heure locale du rappel, voir
  /// AdventCalendar.reminderTimes). Appelé seulement si la permission de
  /// notifier est accordée, comme les autres rappels.
  Future<void> scheduleAdventReminders(Map<int, DateTime> times, {String locale = 'fr'}) async {
    if (!_supported) return;
    for (final e in times.entries) {
      try {
        await _plugin.zonedSchedule(
          id: _idAventBase + e.key,
          title: locale == 'en' ? '🎄 Movie Advent Calendar' : "🎄 Calendrier de l'Avent ciné",
          body: locale == 'en' ? "Today's door is open 🎄" : 'La case du jour est ouverte 🎄',
          scheduledDate: tz.TZDateTime.from(e.value, tz.local),
          notificationDetails: _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } catch (_) {}
    }
  }

  /// Annule le rappel de la case [day] (trouvée avant 18 h).
  Future<void> cancelAdventReminder(int day) async {
    if (!_supported) return;
    try {
      await _plugin.cancel(id: _idAventBase + day);
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
