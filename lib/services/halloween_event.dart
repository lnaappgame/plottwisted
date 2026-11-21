import 'dart:math';
import '../data/halloween_pitches_data.dart';
import '../models/joker.dart';
import 'app_settings.dart';
import 'event_grid.dart';
import 'game_state.dart';

export 'event_grid.dart' show kEventJokers;

/// Pitchs ouverts dès le premier jour de l'event, puis [kEventDailyBatch] de
/// plus chaque jour.
const kEventFirstBatch = 10;
const kEventDailyBatch = 2;

/// Dernier jour de l'event (inclus, heure du téléphone). Tous les pitchs sont
/// ouverts au plus tard ce jour-là, même pour un joueur arrivé tard.
final kHalloweenEventLastDay = DateTime(2026, 11, 8);

/// Un joker gagné tous les [kEventJokerEvery] pitchs trouvés.
const kEventJokerEvery = 5;

/// Ce qu'a rapporté un pitch trouvé, pour l'écran de victoire.
class EventSolveReward {
  final JokerKind? joker; // palier de [kEventJokerEvery] pitchs
  final bool pumpkinUnlocked; // premier pitch trouvé
  final bool finalReward; // les 30 pitchs : bonus + citrouille en feu
  const EventSolveReward({this.joker, required this.pumpkinUnlocked, required this.finalReward});
}

/// L'event Halloween : 30 films d'horreur et d'Halloween racontés du point de
/// vue de leur méchant, à trouver l'un après l'autre comme dans le jeu
/// principal (la grille et les jokers viennent de [EventGrid]). Son état est
/// sauvegardé avec le jeu principal (voir GameState.toJson), et il utilise et
/// alimente le même stock de jokers.
class HalloweenEvent with EventGrid {
  @override
  final GameState game;
  HalloweenEvent(this.game);

  String? firstDay; // premier jour où le joueur a ouvert l'event (aaaa-mm-jj)
  Set<int> solved = {};

  /// Ordre de passage : « Passer, j'y reviendrai » renvoie le pitch à la fin.
  List<int> queue = List.generate(kHalloweenPitches.length, (i) => i);

  bool finalRewardGranted = false;

  int get pitchCount => kHalloweenPitches.length;

  DateTime get _today {
    final d = game.clock();
    return DateTime(d.year, d.month, d.day);
  }

  static String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static int _daysBetween(DateTime a, DateTime b) => (b.difference(a).inHours / 24).round();

  /// L'event est-il encore ouvert aujourd'hui ?
  bool get isActive => !_today.isAfter(kHalloweenEventLastDay);

  /// Pitchs jouables aujourd'hui : 10 le premier jour, puis 2 de plus chaque
  /// jour ; tout est ouvert au plus tard le dernier jour de l'event.
  int get availableCount {
    final today = _today;
    final first = firstDay == null ? today : DateTime.tryParse(firstDay!) ?? today;
    final byPlayer = kEventFirstBatch + kEventDailyBatch * max(0, _daysBetween(first, today));
    final byDeadline = pitchCount - kEventDailyBatch * max(0, _daysBetween(today, kHalloweenEventLastDay));
    return max(byPlayer, byDeadline).clamp(kEventFirstBatch, pitchCount).toInt();
  }

  bool isAvailable(int index) => index < availableCount;

  int get solvedCount => solved.length;
  bool get allSolved => solvedCount >= pitchCount;

  /// Pitchs ouverts et pas encore trouvés, dans l'ordre de passage.
  List<int> get _pending => [
        for (final i in queue)
          if (!solved.contains(i) && isAvailable(i)) i
      ];

  int get toPlayCount => _pending.length;

  /// Le pitch à jouer maintenant, ou null (tout est trouvé pour aujourd'hui).
  @override
  int? get currentPitch => _pending.firstOrNull;

  /// Tous les pitchs ouverts sont trouvés, d'autres arrivent les jours suivants.
  bool get waitingForTomorrow => !allSolved && currentPitch == null;

  /// À appeler à l'ouverture de l'event : fixe le premier jour du joueur.
  void markVisited() {
    if (firstDay != null) return;
    firstDay = _key(_today);
    game.eventChanged();
  }

  @override
  String gridTitle(int index, String locale) => kHalloweenPitches[index].titleFor(locale);

  @override
  bool isPitchSolved(int index) => solved.contains(index);

  /// Pitch trouvé juste avant (écran de victoire), et ce qu'il a rapporté.
  int? lastSolvedPitch;
  EventSolveReward? lastReward;

  @override
  void onPitchSolved(int index) => lastReward = _solve(index);

  EventSolveReward _solve(int index) {
    solved.add(index);
    lastSolvedPitch = index;
    // Avatar des participants : débloqué au premier pitch trouvé.
    final pumpkinUnlocked = game.settings.unlockAvatar(kPumpkinAvatar);
    JokerKind? joker;
    if (solvedCount % kEventJokerEvery == 0) joker = game.grantRandomJokerAmong(kEventJokers);
    var finalReward = false;
    if (allSolved && !finalRewardGranted) {
      finalRewardGranted = true;
      finalReward = true;
      game.grantOneOfEachJokerType();
      game.grantJokers(redJoker: 1);
      game.settings.unlockAvatar(kFirePumpkinAvatar);
    }
    game.analytics.logHalloweenPitchSolved(pitch: index, solved: solvedCount);
    game.eventChanged();
    return EventSolveReward(joker: joker, pumpkinUnlocked: pumpkinUnlocked, finalReward: finalReward);
  }

  /// « Passer, j'y reviendrai » : le pitch repart en fin de file avec sa
  /// grille (lettres et jokers joués). Impossible s'il est le seul ouvert.
  bool get canSkip => _pending.length > 1;

  bool skipCurrent() {
    final index = currentPitch;
    if (index == null || !canSkip) return false;
    stashGrid();
    loadedPitch = null;
    queue
      ..remove(index)
      ..add(index);
    loadCurrent();
    return true;
  }

  // ─── Sauvegarde ───
  Map<String, dynamic> toJson() => {
        'mode': 'pitchs',
        'firstDay': firstDay,
        'solved': solved.toList(),
        'queue': queue,
        'grids': gridsToJson(),
        'finalRewardGranted': finalRewardGranted,
      };

  void restore(Object? data) {
    firstDay = null;
    solved = {};
    queue = List.generate(pitchCount, (i) => i);
    finalRewardGranted = false;
    resetGrids();
    lastSolvedPitch = null;
    lastReward = null;
    // Les sauvegardes de la version « questions » (jamais publiée) sont ignorées.
    if (data is! Map || data['mode'] != 'pitchs') return;
    firstDay = data['firstDay'] as String?;
    finalRewardGranted = data['finalRewardGranted'] as bool? ?? false;
    bool valid(Object? i) => i is int && i >= 0 && i < pitchCount;
    solved = {...?(data['solved'] as List?)?.where(valid).cast<int>()};
    final savedQueue = [...?(data['queue'] as List?)?.where(valid).cast<int>()];
    // File complétée par les pitchs absents (contenu ajouté par une mise à jour).
    queue = [
      ...savedQueue.toSet(),
      for (var i = 0; i < pitchCount; i++)
        if (!savedQueue.contains(i)) i
    ];
    restoreGrids(data['grids'], valid);
  }

  void reset() => restore(null);
}
