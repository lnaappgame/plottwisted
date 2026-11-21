import '../data/advent_data.dart';
import '../models/joker.dart';
import 'app_settings.dart';
import 'event_grid.dart';
import 'game_state.dart';

/// Année du calendrier : une sauvegarde d'une autre année est ignorée.
const kAdventYear = 2026;

/// Jour de la case 1 (heure du téléphone). La case N s'ouvre le N décembre à
/// minuit ; la case bonus (25) le 25.
final kAdventFirstDay = DateTime(kAdventYear, 12, 1);

/// Dernier jour (inclus) où le calendrier reste ouvert : les cases manquées
/// se rattrapent jusque-là, sans le joker du jour.
final kAdventLastDay = DateTime(kAdventYear + 1, 1, 3);

/// Heure du rappel local « La case du jour est ouverte ».
const kAdventReminderHour = 18;

/// Le gros lot des 25 cases : 5 jokers.
const kAdventFinalJokers = [
  JokerKind.reveal,
  JokerKind.eliminate,
  JokerKind.revealWord,
  JokerKind.hint,
  JokerKind.actor,
];

/// Ce qu'a rapporté une case trouvée, pour l'écran de victoire.
class AdventSolveReward {
  final int day;
  final bool onTime; // trouvée le jour même
  final JokerKind? dayJoker; // le joker du jour (seulement le jour même)
  final bool hatUnlocked; // première case trouvée : bonnet de Noël
  final bool finalReward; // les 25 cases : gros lot + avatar final
  const AdventSolveReward(
      {required this.day, required this.onTime, this.dayJoker, required this.hatUnlocked, required this.finalReward});
}

/// Le calendrier de l'Avent ciné : une case par jour du 1er au 24 décembre,
/// plus une case bonus le 25, chacune un film de Noël raconté par le Père
/// Noël (voir kAdventPitches). Une case s'ouvre selon la date du téléphone,
/// jamais en avance ; une case manquée reste jouable jusqu'au
/// [kAdventLastDay], mais le joker du jour n'est donné que si la case est
/// trouvée le jour même. La grille et les jokers sont ceux de [EventGrid]
/// (même stock que le jeu principal) ; l'état est sauvegardé avec le jeu
/// principal (voir GameState.toJson).
class AdventCalendar with EventGrid {
  @override
  final GameState game;
  AdventCalendar(this.game);

  /// Cases trouvées (numéros de jour, de 1 à 25).
  Set<int> solved = {};

  /// Cases trouvées le jour même (joker du jour donné).
  Set<int> solvedOnTime = {};

  bool finalRewardGranted = false;

  /// Case ouverte à l'écran (voir [open]).
  int? selectedDay;

  /// Case trouvée juste avant (écran de victoire), et ce qu'elle a rapporté.
  int? lastSolvedDay;
  AdventSolveReward? lastReward;

  /// Appelé quand une case est trouvée le jour même : main.dart y annule le
  /// rappel de 18 h devenu inutile.
  void Function(int day)? onSolvedOnTime;

  int get caseCount => kAdventPitches.length;

  DateTime get _today {
    final d = game.clock();
    return DateTime(d.year, d.month, d.day);
  }

  static int _daysBetween(DateTime a, DateTime b) => (b.difference(a).inHours / 24).round();

  /// Date d'ouverture de la case [day].
  static DateTime dateOf(int day) => DateTime(kAdventYear, 12, day);

  /// Le calendrier est ouvert (entrée de l'accueil visible) du 1er décembre
  /// au [kAdventLastDay] inclus.
  bool get isActive => !_today.isBefore(kAdventFirstDay) && !_today.isAfter(kAdventLastDay);

  bool get isOver => _today.isAfter(kAdventLastDay);

  /// Cases ouvertes par la date : 0 avant le 1er décembre, N le N décembre,
  /// toutes à partir du 25.
  int get openedCount => (_daysBetween(kAdventFirstDay, _today) + 1).clamp(0, caseCount).toInt();

  /// La case du jour (1 à 25), ou null hors du 1er au 25 décembre.
  int? get todayCase {
    final n = _daysBetween(kAdventFirstDay, _today) + 1;
    return n >= 1 && n <= caseCount ? n : null;
  }

  bool isOpen(int day) => day >= 1 && day <= openedCount;
  bool isSolved(int day) => solved.contains(day);
  bool isToday(int day) => todayCase == day;

  /// Case jouable maintenant : ouverte par la date, pas encore trouvée, et
  /// calendrier pas encore fermé.
  bool isPlayable(int day) => isActive && isOpen(day) && !isSolved(day);

  int get solvedCount => solved.length;
  bool get allSolved => solvedCount >= caseCount;

  /// Cases ouvertes pas encore trouvées (pastille de l'accueil).
  int get toPlayCount => [for (var d = 1; d <= caseCount; d++) d].where(isPlayable).length;

  /// La case à proposer ensuite : celle du jour si elle reste à trouver,
  /// sinon la plus ancienne case manquée ; null si le joueur est à jour.
  int? get suggestedDay {
    final today = todayCase;
    if (today != null && isPlayable(today)) return today;
    for (var d = 1; d <= caseCount; d++) {
      if (isPlayable(d)) return d;
    }
    return null;
  }

  /// Toutes les cases ouvertes sont trouvées, d'autres s'ouvrent les jours suivants.
  bool get waitingForTomorrow => isActive && !allSolved && suggestedDay == null;

  /// Ouvre la case [day] à l'écran (sa grille est reprise si elle avait été
  /// commencée). Faux si elle n'est pas jouable (pas encore ouverte, déjà
  /// trouvée, calendrier fermé).
  bool open(int day, {bool notify = true}) {
    if (!isPlayable(day)) return false;
    selectedDay = day;
    loadCurrent(notify: notify);
    return true;
  }

  // ─── EventGrid : index = jour - 1 ───
  @override
  int? get currentPitch {
    final day = selectedDay;
    return day != null && isPlayable(day) ? day - 1 : null;
  }

  @override
  String gridTitle(int index, String locale) => kAdventPitches[index].titleFor(locale);

  @override
  bool isPitchSolved(int index) => solved.contains(index + 1);

  /// Le jour de la case affichée par la grille.
  int? get loadedDay => loadedPitch == null ? null : loadedPitch! + 1;

  @override
  void onPitchSolved(int index) => lastReward = _solve(index + 1);

  AdventSolveReward _solve(int day) {
    solved.add(day);
    lastSolvedDay = day;
    final onTime = isToday(day);
    JokerKind? dayJoker;
    if (onTime) {
      solvedOnTime.add(day);
      dayJoker = game.grantRandomJokerAmong(kEventJokers);
      onSolvedOnTime?.call(day);
    }
    // Avatar des participants : débloqué à la première case trouvée.
    final hatUnlocked = game.settings.unlockAvatar(kSantaHatAvatar);
    // Le gros lot va avec la case 25, mais demande les 24 autres : il tombe
    // quand la dernière des 25 est trouvée (la 25 ou une case rattrapée).
    var finalReward = false;
    if (allSolved && !finalRewardGranted) {
      finalRewardGranted = true;
      finalReward = true;
      game.grantJokerKinds(kAdventFinalJokers);
      game.settings.unlockAvatar(kSnowHatAvatar);
    }
    game.analytics.logAdventCaseSolved(day: day, onTime: onTime);
    game.eventChanged();
    return AdventSolveReward(
        day: day, onTime: onTime, dayJoker: dayJoker, hatUnlocked: hatUnlocked, finalReward: finalReward);
  }

  /// Rappels de [kAdventReminderHour] h encore à venir, par jour : un par
  /// case qui ne s'est pas encore ouverte ou qui reste à trouver.
  Map<int, DateTime> reminderTimes() {
    final now = game.clock();
    return {
      for (var day = 1; day <= caseCount; day++)
        if (!isSolved(day) && dateOf(day).add(const Duration(hours: kAdventReminderHour)).isAfter(now))
          day: DateTime(kAdventYear, 12, day, kAdventReminderHour),
    };
  }

  // ─── Sauvegarde ───
  Map<String, dynamic> toJson() => {
        'year': kAdventYear,
        'solved': solved.toList(),
        'onTime': solvedOnTime.toList(),
        'grids': gridsToJson(),
        'finalRewardGranted': finalRewardGranted,
      };

  void restore(Object? data) {
    solved = {};
    solvedOnTime = {};
    finalRewardGranted = false;
    selectedDay = null;
    lastSolvedDay = null;
    lastReward = null;
    resetGrids();
    if (data is! Map || data['year'] != kAdventYear) return;
    bool validDay(Object? d) => d is int && d >= 1 && d <= caseCount;
    solved = {...?(data['solved'] as List?)?.where(validDay).cast<int>()};
    solvedOnTime = {...?(data['onTime'] as List?)?.where(validDay).cast<int>()}.intersection(solved);
    finalRewardGranted = data['finalRewardGranted'] as bool? ?? false;
    restoreGrids(data['grids'], (i) => i is int && i >= 0 && i < caseCount);
  }

  void reset() => restore(null);
}
