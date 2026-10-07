import 'package:flutter/foundation.dart';
import '../data/cinema_events_data.dart';
import 'save_service.dart';

/// Longueur du cycle du calendrier de série — se répète indéfiniment (jour
/// 29 redevient jour 1 avec les mêmes récompenses, etc.).
const int kStreakCycleLength = 28;

/// Paliers "bonus majeur" (jours du cycle avec une action significative —
/// niveau, défi, énigme ou match multijoueur terminé) et le libellé de la
/// récompense accordée à chacun. Le dernier jour du cycle (28) marque un
/// cycle complet et rapporte le bonus majeur habituel multiplié par 3.
/// Tous les autres jours du cycle rapportent un bonus mineur (voir
/// [onDailyReward]).
const List<int> kStreakPaliers = [3, 7, 14, 28];

/// Calendrier de série (bouton 📅, écran, célébrations) et ses récompenses :
/// désactivés le temps de les repenser (2026-10-07). Le compteur de série
/// continue de tourner ; repasser à `true` pour tout réactiver.
const bool kStreakCalendarEnabled = false;

/// Suivi de la série de jours consécutifs joués — indépendant du contenu
/// (jeu principal, Défi du jour, L'énigme de la semaine, Multijoueur
/// comptent tous pour la même série). Ne connaît rien des jokers : la
/// remise de récompense se fait via [onMilestoneReached] (jours palier),
/// [onDailyReward] (tous les autres jours) et [onCinemaEventReached] (bonus
/// cumulé les jours de grands événements du cinéma), câblés une fois au
/// démarrage (main.dart) vers `GameState.grantJokers`, pour éviter toute dépendance
/// croisée entre les services.
class StreakState extends ChangeNotifier {
  final SaveService saveService;
  StreakState({required this.saveService});

  /// Appelé avec le palier atteint (3, 7, 14 ou 28) juste après
  /// [recordAction] quand la série vient d'atteindre l'un de [kStreakPaliers]
  /// (position dans le cycle courant — voir [jourDuCycle]).
  void Function(int palier)? onMilestoneReached;

  /// Appelé avec le jour du cycle (1 à 28) juste après [recordAction], pour
  /// tout jour qui N'est PAS un palier de [kStreakPaliers] — le bonus
  /// mineur du jour, distinct du bonus majeur des paliers.
  void Function(int jourDuCycle)? onDailyReward;

  /// Appelé en plus (jamais à la place) de [onMilestoneReached]/[onDailyReward]
  /// quand le jour réel du calendrier tombe sur un grand événement du
  /// cinéma (voir [kCinemaEvents]) — un bonus supplémentaire, cumulé avec
  /// celui du jour.
  void Function(CinemaEvent event)? onCinemaEventReached;

  int currentStreak = 0;
  DateTime? lastActionDay;

  /// Position (1 à [kStreakCycleLength]) dans le cycle courant du calendrier
  /// — [currentStreak] continue de grimper sans fin, mais le calendrier et
  /// les récompenses se répètent tous les 28 jours.
  int get jourDuCycle => currentStreak == 0 ? 0 : ((currentStreak - 1) % kStreakCycleLength) + 1;

  /// Jour réel (UTC) où le cycle courant a commencé (jour 1) — `null` tant
  /// qu'aucune série n'est en cours. Sert à projeter la date réelle de
  /// n'importe quel jour du cycle (passé ou, en supposant une série
  /// ininterrompue, à venir) — voir [dateForJourDuCycle].
  DateTime? get cycleStartDay =>
      lastActionDay == null || currentStreak == 0 ? null : lastActionDay!.subtract(Duration(days: jourDuCycle - 1));

  /// Date réelle (UTC) projetée pour le jour [jour] (1 à 28) du cycle
  /// courant — en supposant que la série se poursuit sans interruption
  /// jusque-là. `null` tant qu'aucune série n'est en cours.
  DateTime? dateForJourDuCycle(int jour) {
    final start = cycleStartDay;
    if (start == null) return null;
    return start.add(Duration(days: jour - 1));
  }

  /// Dernier palier atteint et pas encore affiché au joueur (voir
  /// HomeScreen) — distinct de [onMilestoneReached], qui sert uniquement à
  /// la remise de la récompense.
  int? pendingCelebration;

  bool _restoring = false;

  @override
  void notifyListeners() {
    super.notifyListeners();
    if (!_restoring) saveService.saveStreak(toJson());
  }

  DateTime _utcDate(DateTime now) {
    final u = now.toUtc();
    return DateTime.utc(u.year, u.month, u.day);
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  /// À appeler dès qu'une action significative vient d'être accomplie
  /// (niveau/défi/énigme/match terminé). Incrémente la série si c'est le
  /// jour consécutif suivant, la réinitialise à 1 si un jour a été sauté,
  /// ne fait rien si une action a déjà été comptée aujourd'hui (une seule
  /// incrémentation par jour, quel que soit le nombre d'actions).
  void recordAction() {
    final today = _utcDate(DateTime.now());
    if (lastActionDay != null && _sameDay(lastActionDay!, today)) return;

    final hier = today.subtract(const Duration(days: 1));
    currentStreak = (lastActionDay != null && _sameDay(lastActionDay!, hier)) ? currentStreak + 1 : 1;
    lastActionDay = today;

    final jour = jourDuCycle;
    if (kStreakPaliers.contains(jour)) {
      pendingCelebration = jour;
      onMilestoneReached?.call(jour);
    } else {
      onDailyReward?.call(jour);
    }
    for (final event in kCinemaEvents) {
      if (_sameDay(event.date, today)) {
        onCinemaEventReached?.call(event);
        break; // jamais deux événements le même jour dans la liste actuelle
      }
    }
    notifyListeners();
  }

  /// À appeler une fois la célébration affichée côté écran, pour ne pas la
  /// remontrer à chaque ouverture.
  void acknowledgeCelebration() {
    if (pendingCelebration == null) return;
    pendingCelebration = null;
    notifyListeners();
  }

  Map<String, dynamic> toJson() => {
        'currentStreak': currentStreak,
        'lastActionDay': lastActionDay?.toIso8601String(),
      };

  Future<void> restore() async {
    final data = await saveService.loadStreak();
    if (data == null) return;
    _restoring = true;
    currentStreak = data['currentStreak'] as int? ?? 0;
    final lad = data['lastActionDay'] as String?;
    lastActionDay = lad != null ? DateTime.tryParse(lad) : null;
    _restoring = false;
  }
}
