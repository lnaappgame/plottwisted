import 'dart:math';
import '../data/advent_data.dart';
import '../models/joker.dart';
import 'app_settings.dart';
import 'event_grid.dart' show kEventJokers;
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

/// Le seul joker d'une case, « Retirer un piège » : il dépense un joker
/// Révéler (celui qui révélait une lettre quand les cases se jouaient avec
/// des tuiles), pris dans le stock du jeu principal.
const kAdventTrapJoker = JokerKind.reveal;

/// Identifiant du bon titre parmi les réponses d'une case (les pièges sont
/// numérotés de 0 à 2, comme dans EventPitch.trapsFr / trapsEn).
const kAdventAnswerId = -1;

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

/// Ce que donne une réponse touchée dans une case.
enum AdventAnswer {
  /// Le bon titre : la case est trouvée.
  solved,

  /// Un piège : il est barré (« Piège ! ») et le joueur peut retenter.
  trap,

  /// Rien : réponse déjà barrée ou retirée, case déjà trouvée.
  ignored,
}

/// Une des 4 réponses d'une case, dans l'ordre d'affichage.
class AdventChoice {
  /// [kAdventAnswerId] pour le bon titre, sinon le numéro du piège (0 à 2).
  final int id;
  final String title;

  /// Piège déjà touché : barré, avec « Piège ! ».
  final bool hit;

  /// Piège retiré par le joker « Retirer un piège ».
  final bool removed;

  const AdventChoice({required this.id, required this.title, this.hit = false, this.removed = false});

  bool get isAnswer => id == kAdventAnswerId;

  /// Encore touchable.
  bool get playable => !hit && !removed;
}

/// Une case commencée : les pièges touchés (dans l'ordre, pour le partage),
/// ceux retirés par le joker, et les jokers joués.
class _CaseProgress {
  final List<int> hits;
  final Set<int> removed;
  final List<JokerKind> jokers;
  _CaseProgress() : hits = [], removed = {}, jokers = [];

  bool get isEmpty => hits.isEmpty && removed.isEmpty && jokers.isEmpty;

  Map<String, dynamic> toJson() => {
        'hits': hits,
        'removed': removed.toList(),
        'jokers': [for (final k in jokers) k.name],
      };

  /// Relit [toJson] ; null si illisible. Les pièges hors de 0..[trapCount]-1
  /// et les jokers inconnus sont écartés.
  static _CaseProgress? fromJson(Object? data, int trapCount) {
    if (data is! Map) return null;
    List<Object?> list(Object? v) => v is List ? v : const [];
    bool valid(Object? i) => i is int && i >= 0 && i < trapCount;
    final p = _CaseProgress();
    for (final i in list(data['hits'])) {
      if (valid(i) && !p.hits.contains(i)) p.hits.add(i as int);
    }
    for (final i in list(data['removed'])) {
      if (valid(i) && !p.hits.contains(i)) p.removed.add(i as int);
    }
    final byName = JokerKind.values.asNameMap();
    for (final n in list(data['jokers'])) {
      if (byName[n] case final kind?) p.jokers.add(kind);
    }
    return p;
  }
}

/// Le calendrier de l'Avent ciné : une case par jour du 1er au 24 décembre,
/// plus une case bonus le 25, chacune un film de Noël raconté par le Père
/// Noël (voir kAdventPitches). Une case s'ouvre selon la date du téléphone,
/// jamais en avance ; une case manquée reste jouable jusqu'au
/// [kAdventLastDay], mais le joker du jour n'est donné que si la case est
/// trouvée le jour même.
///
/// Une case se joue en QCM : le pitch, puis 4 titres, le bon et 3 pièges
/// ([choicesOf]). Un piège touché est barré et le joueur retente ; la case
/// est trouvée au bon titre. Le joker « Retirer un piège » ([removeTrap])
/// dépense un joker du stock du jeu principal. L'état est sauvegardé avec le
/// jeu principal (voir GameState.toJson).
class AdventCalendar {
  final GameState game;
  AdventCalendar(this.game);

  /// Cases trouvées (numéros de jour, de 1 à 25).
  Set<int> solved = {};

  /// Cases trouvées le jour même (joker du jour donné).
  Set<int> solvedOnTime = {};

  bool finalRewardGranted = false;

  /// Case ouverte à l'écran (voir [open]) ; elle le reste une fois trouvée,
  /// pour l'écran de victoire.
  int? selectedDay;

  /// Case trouvée juste avant (écran de victoire), et ce qu'elle a rapporté.
  int? lastSolvedDay;
  AdventSolveReward? lastReward;

  /// Appelé quand une case est trouvée le jour même : main.dart y annule le
  /// rappel de 18 h devenu inutile.
  void Function(int day)? onSolvedOnTime;

  /// Cases commencées, par jour. Celle trouvée juste avant y reste jusqu'à
  /// l'ouverture d'une autre case (lignes du partage).
  Map<int, _CaseProgress> _progress = {};

  /// Temps passé sur la case trouvée juste avant (partage).
  Duration lastSolveDuration = Duration.zero;
  DateTime _caseStart = DateTime.now();
  final Random _rng = Random();

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

  /// Ouvre la case [day] à l'écran (pièges touchés et retirés repris si elle
  /// avait été commencée). Faux si elle n'est pas jouable (pas encore
  /// ouverte, déjà trouvée, calendrier fermé). [notify] à false depuis un
  /// initState (pas de notification en plein build).
  bool open(int day, {bool notify = true}) {
    if (!isPlayable(day)) return false;
    if (day != selectedDay) {
      // Une case trouvée n'a plus besoin de ses lignes de partage.
      _progress.removeWhere((d, _) => isSolved(d));
      _caseStart = game.clock();
    }
    selectedDay = day;
    if (notify) game.eventChanged();
    return true;
  }

  // ─── QCM ───

  /// Ordre d'affichage des réponses de la case [day] : [kAdventAnswerId] et
  /// les pièges, mélangés, mais toujours dans le même ordre pour une même
  /// case, dans les deux langues. Petit générateur maison (Park et Miller)
  /// plutôt que Random, dont la suite pour une graine donnée n'est pas
  /// garantie d'une version de Dart à l'autre.
  static List<int> choiceOrder(int day) {
    const modulus = 2147483647;
    final pitch = kAdventPitches[day - 1];
    final trapCount = min(pitch.trapsFr.length, pitch.trapsEn.length);
    final order = [kAdventAnswerId, for (var i = 0; i < trapCount; i++) i];
    var seed = (day * 9973 + 20) % modulus;
    if (seed == 0) seed = 1;
    for (var i = order.length - 1; i > 0; i--) {
      seed = seed * 48271 % modulus;
      final j = seed % (i + 1);
      final swap = order[i];
      order[i] = order[j];
      order[j] = swap;
    }
    return order;
  }

  /// Les réponses de la case [day] dans [locale] (titre FR en français, EN
  /// sinon), dans l'ordre d'affichage, avec les pièges déjà touchés ou retirés.
  List<AdventChoice> choicesOf(int day, String locale) {
    final pitch = kAdventPitches[day - 1];
    final traps = pitch.trapsFor(locale);
    final progress = _progress[day];
    return [
      for (final id in choiceOrder(day))
        AdventChoice(
          id: id,
          title: id == kAdventAnswerId ? pitch.titleFor(locale) : traps[id],
          hit: progress?.hits.contains(id) ?? false,
          removed: progress?.removed.contains(id) ?? false,
        ),
    ];
  }

  /// Pièges encore en jeu dans la case [day] (ni touchés ni retirés).
  List<int> _trapsLeft(int day) {
    final progress = _progress[day];
    bool inPlay(int id) =>
        id != kAdventAnswerId && !(progress?.hits.contains(id) ?? false) && !(progress?.removed.contains(id) ?? false);
    return choiceOrder(day).where(inPlay).toList();
  }

  /// Il reste au moins un piège à retirer dans la case affichée.
  bool get hasTrapLeft {
    final day = selectedDay;
    return day != null && !isSolved(day) && _trapsLeft(day).isNotEmpty;
  }

  /// Le joueur touche la réponse [id] de la case affichée : le bon titre
  /// trouve la case, un piège est barré (le joueur peut retenter).
  AdventAnswer choose(int id) {
    final day = selectedDay;
    if (day == null || isSolved(day)) return AdventAnswer.ignored;
    if (id == kAdventAnswerId) {
      lastReward = _solve(day);
      return AdventAnswer.solved;
    }
    if (!_trapsLeft(day).contains(id)) return AdventAnswer.ignored;
    _progress.putIfAbsent(day, _CaseProgress.new).hits.add(id);
    game.eventChanged();
    return AdventAnswer.trap;
  }

  /// Joker « Retirer un piège » : un piège encore en jeu, tiré au hasard,
  /// disparaît, contre un joker [kAdventTrapJoker]. Retourne le piège
  /// retiré, ou null si le joker n'a pas été dépensé (plus de joker, plus de
  /// piège, case déjà trouvée).
  int? removeTrap() {
    final day = selectedDay;
    if (day == null || isSolved(day) || game.countOf(kAdventTrapJoker) <= 0) return null;
    final left = _trapsLeft(day);
    if (left.isEmpty) return null;
    final trap = left[_rng.nextInt(left.length)];
    final progress = _progress.putIfAbsent(day, _CaseProgress.new);
    progress.removed.add(trap);
    progress.jokers.add(kAdventTrapJoker);
    game.revealCount--; // kAdventTrapJoker
    game.eventChanged();
    return trap;
  }

  /// Pub « Gagner un joker » d'une case : le joker qu'on y joue.
  JokerKind grantAdJoker() {
    game.grantJokerKinds(const [kAdventTrapJoker]);
    return kAdventTrapJoker;
  }

  /// Partage façon Wordle de la case affichée : une ligne par réponse
  /// touchée, 🟥 pour un piège, 🟩 pour le bon titre.
  List<List<bool>> get attemptRows {
    final day = selectedDay;
    if (day == null) return const [];
    return [
      for (final _ in _progress[day]?.hits ?? const <int>[]) [false],
      if (isSolved(day)) [true],
    ];
  }

  /// Jokers joués sur la case affichée (partage).
  List<JokerKind> get jokersUsed => List.unmodifiable(_progress[selectedDay]?.jokers ?? const <JokerKind>[]);

  AdventSolveReward _solve(int day) {
    solved.add(day);
    lastSolvedDay = day;
    lastSolveDuration = game.clock().difference(_caseStart);
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
        // Cases commencées pas encore trouvées. Les grilles de lettres des
        // premières versions (clé 'grids') ne sont plus lues.
        'cases': {
          for (final e in _progress.entries)
            if (!isSolved(e.key) && !e.value.isEmpty) '${e.key}': e.value.toJson()
        },
        'finalRewardGranted': finalRewardGranted,
      };

  void restore(Object? data) {
    solved = {};
    solvedOnTime = {};
    finalRewardGranted = false;
    selectedDay = null;
    lastSolvedDay = null;
    lastReward = null;
    lastSolveDuration = Duration.zero;
    _progress = {};
    if (data is! Map || data['year'] != kAdventYear) return;
    bool validDay(Object? d) => d is int && d >= 1 && d <= caseCount;
    solved = {...?(data['solved'] as List?)?.where(validDay).cast<int>()};
    solvedOnTime = {...?(data['onTime'] as List?)?.where(validDay).cast<int>()}.intersection(solved);
    finalRewardGranted = data['finalRewardGranted'] as bool? ?? false;
    final cases = data['cases'];
    if (cases is Map) {
      for (final e in cases.entries) {
        final day = int.tryParse('${e.key}');
        if (!validDay(day) || solved.contains(day)) continue;
        final progress = _CaseProgress.fromJson(e.value, kAdventPitches[day! - 1].trapsFr.length);
        if (progress != null && !progress.isEmpty) _progress[day] = progress;
      }
    }
  }

  void reset() => restore(null);
}
