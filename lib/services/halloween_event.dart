import 'dart:math';
import '../data/halloween_event_data.dart';
import '../models/joker.dart';
import '../models/puzzle.dart';
import 'app_settings.dart';
import 'game_state.dart';

/// Films disponibles dès le premier jour de l'event ; ensuite un de plus par jour.
const kEventFirstBatch = 5;

/// Dernier jour de l'event (inclus, heure du téléphone). Tous les films sont
/// ouverts au plus tard ce jour-là, même pour un joueur arrivé tard.
final kHalloweenEventLastDay = DateTime(2026, 11, 8);

/// Avancement d'un film de l'event.
class EventFilmProgress {
  /// Choix du joueur pour chaque question, en index dans les choix tels
  /// qu'écrits dans les données (0 = bonne réponse) ; null = pas encore répondu.
  List<int?> answers;

  /// Questions ratées dont l'indice a été dévoilé grâce à une pub.
  Set<int> adRevealed;
  bool solved;

  EventFilmProgress({List<int?>? answers, Set<int>? adRevealed, this.solved = false})
      : answers = answers ?? List<int?>.filled(4, null),
        adRevealed = adRevealed ?? {};

  Map<String, dynamic> toJson() => {'answers': answers, 'adRevealed': adRevealed.toList(), 'solved': solved};

  factory EventFilmProgress.fromJson(Map<String, dynamic> json) {
    final raw = (json['answers'] as List?) ?? const [];
    final answers = List<int?>.generate(4, (i) => i < raw.length ? raw[i] as int? : null);
    return EventFilmProgress(
      answers: answers,
      adRevealed: ((json['adRevealed'] as List?) ?? const []).cast<int>().toSet(),
      solved: json['solved'] as bool? ?? false,
    );
  }
}

/// Ce qu'a rapporté un film trouvé, pour l'écran de victoire.
class EventSolveReward {
  final JokerKind joker;
  final bool pumpkinUnlocked;
  final bool finalReward; // les 10 films trouvés : bonus + citrouille en feu
  const EventSolveReward({required this.joker, required this.pumpkinUnlocked, required this.finalReward});
}

/// L'event Halloween : 10 films à trouver, chacun derrière 4 questions de
/// culture générale (QCM) dont les bonnes réponses servent d'indices. Son
/// état est sauvegardé avec le jeu principal (voir GameState.toJson), et les
/// jokers gagnés vont dans le stock du jeu principal.
class HalloweenEvent {
  final GameState game;
  HalloweenEvent(this.game);

  String? firstDay; // premier jour où le joueur a ouvert l'event (aaaa-mm-jj)
  Map<int, EventFilmProgress> progress = {};
  bool finalRewardGranted = false;

  int get filmCount => kHalloweenFilms.length;

  DateTime get _today {
    final d = game.clock();
    return DateTime(d.year, d.month, d.day);
  }

  static String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static int _daysBetween(DateTime a, DateTime b) => (b.difference(a).inHours / 24).round();

  /// L'event est-il encore ouvert aujourd'hui ?
  bool get isActive => !_today.isAfter(kHalloweenEventLastDay);

  /// Films jouables aujourd'hui : 5 le premier jour, puis un de plus chaque
  /// jour ; tout est ouvert au plus tard le dernier jour de l'event.
  int get availableCount {
    final today = _today;
    final first = firstDay == null ? today : DateTime.tryParse(firstDay!) ?? today;
    final byPlayer = kEventFirstBatch + max(0, _daysBetween(first, today));
    final byDeadline = filmCount - max(0, _daysBetween(today, kHalloweenEventLastDay));
    return max(byPlayer, byDeadline).clamp(kEventFirstBatch, filmCount).toInt();
  }

  /// Jours avant que le film [index] soit jouable (0 = déjà jouable).
  int daysUntilAvailable(int index) => max(0, index + 1 - availableCount);

  bool isAvailable(int index) => index < availableCount;

  int get solvedCount => progress.values.where((p) => p.solved).length;
  bool get allSolved => solvedCount >= filmCount;

  /// Des films restent à débloquer les jours suivants.
  bool get moreToCome => availableCount < filmCount;

  /// Le joueur a fini tous les films ouverts aujourd'hui, mais pas l'event.
  bool get waitingForTomorrow =>
      moreToCome && List.generate(availableCount, (i) => progressOf(i).solved).every((s) => s);

  /// À appeler à l'ouverture de l'event : fixe le premier jour du joueur.
  void markVisited() {
    if (firstDay != null) return;
    firstDay = _key(_today);
    game.eventChanged();
  }

  EventFilmProgress progressOf(int index) => progress.putIfAbsent(index, EventFilmProgress.new);

  int answeredCount(int index) => progressOf(index).answers.where((a) => a != null).length;
  bool questionsDone(int index) => answeredCount(index) >= 4;

  /// Ordre d'affichage des 6 choix d'une question : mélangé, mais toujours le
  /// même pour ce film et cette question (aucun saut si on revient).
  List<int> choiceOrder(int index, int question) {
    final order = List<int>.generate(kHalloweenFilms[index].questions[question].choicesFr.length, (i) => i);
    order.shuffle(Random(2026 + index * 31 + question * 7));
    return order;
  }

  /// Enregistre le choix ([choice] = index dans les données) ; true si juste.
  bool answer(int index, int question, int choice) {
    final p = progressOf(index);
    if (p.answers[question] == null) {
      p.answers[question] = choice;
      game.eventChanged();
    }
    return p.answers[question] == 0;
  }

  bool clueFound(int index, int question) {
    final p = progressOf(index);
    return p.answers[question] == 0 || p.adRevealed.contains(question);
  }

  bool answeredRight(int index, int question) => progressOf(index).answers[question] == 0;

  /// Question ratée la plus simple, dont une pub peut dévoiler l'indice.
  int? nextClueToReveal(int index) {
    for (var q = 0; q < 4; q++) {
      if (!clueFound(index, q)) return q;
    }
    return null;
  }

  int hiddenClueCount(int index) => List.generate(4, (q) => clueFound(index, q)).where((f) => !f).length;

  /// Après une pub regardée en entier : dévoile l'indice raté le plus simple.
  void revealClue(int index) {
    final q = nextClueToReveal(index);
    if (q == null) return;
    progressOf(index).adRevealed.add(q);
    game.eventChanged();
  }

  bool perfect(int index) => progressOf(index).answers.every((a) => a == 0);

  // ─── Grille du titre (non sauvegardée : refaite à chaque ouverture) ───
  int? guessingFilm;
  List<AnswerSlot> slots = [];
  List<int?> guess = [];
  List<LetterTile> pool = [];
  int cursorIndex = -1;
  final Random _rng = Random();

  void startGuess(int index) {
    guessingFilm = index;
    final title = normalize(kHalloweenFilms[index].titleFor(game.settings.locale));
    slots = title.split('').map(AnswerSlot.fromChar).toList();
    guess = List<int?>.filled(slots.length, null);
    final letters = [
      for (final s in slots)
        if (!s.isSpace && !s.isAuto) s.char
    ];
    final used = letters.toSet();
    final decoys = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('').where((l) => !used.contains(l)).toList()..shuffle(_rng);
    pool = ([...letters, ...decoys.take(max(5, 16 - letters.length))]..shuffle(_rng))
        .map((l) => LetterTile(letter: l))
        .toList();
    cursorIndex = _firstEmptySlotFrom(0);
    game.eventChanged();
  }

  int _firstEmptySlotFrom(int start) {
    final n = slots.length;
    for (var step = 0; step < n; step++) {
      final i = (start + step) % n;
      if (!slots[i].isSpace && !slots[i].isAuto && guess[i] == null) return i;
    }
    return -1;
  }

  void onLetterTap(LetterTile tile) {
    if (tile.used) return;
    var target = cursorIndex;
    if (target == -1 || slots[target].isSpace || slots[target].isAuto || guess[target] != null) {
      target = _firstEmptySlotFrom(0);
    }
    if (target == -1) return;
    guess[target] = pool.indexOf(tile);
    tile.used = true;
    cursorIndex = _firstEmptySlotFrom(target + 1);
    game.eventChanged();
  }

  void onBlankTap(int i) {
    final tileId = guess[i];
    if (tileId != null) {
      pool[tileId].used = false;
      guess[i] = null;
    }
    cursorIndex = i;
    game.eventChanged();
  }

  void clearGuess() {
    for (var i = 0; i < slots.length; i++) {
      final tileId = guess[i];
      if (tileId != null) pool[tileId].used = false;
      guess[i] = null;
    }
    cursorIndex = _firstEmptySlotFrom(0);
    game.eventChanged();
  }

  bool get gridFull =>
      slots.isNotEmpty && List.generate(slots.length, (i) => slots[i].isSpace || slots[i].isAuto || guess[i] != null).every((v) => v);

  /// 'incomplete', 'wrong' (grille vidée) ou 'solved'.
  String validate() {
    final index = guessingFilm;
    if (index == null) return 'incomplete';
    if (!gridFull) return 'incomplete';
    final attempt = List.generate(slots.length, (i) {
      final s = slots[i];
      if (s.isSpace || s.isAuto) return s.char;
      return pool[guess[i]!].letter;
    }).join();
    if (attempt != slots.map((s) => s.char).join()) {
      clearGuess();
      return 'wrong';
    }
    lastReward = _solve(index);
    return 'solved';
  }

  EventSolveReward? lastReward;

  EventSolveReward _solve(int index) {
    final p = progressOf(index);
    p.solved = true;
    final joker = game.grantRandomJoker(minor: !perfect(index));
    // Avatar des participants : débloqué au premier film trouvé.
    final pumpkinUnlocked = game.settings.unlockAvatar(kPumpkinAvatar);
    var finalReward = false;
    if (allSolved && !finalRewardGranted) {
      finalRewardGranted = true;
      finalReward = true;
      game.grantOneOfEachJokerType();
      game.grantJokers(redJoker: 1);
      game.settings.unlockAvatar(kFirePumpkinAvatar);
    }
    game.analytics.logHalloweenFilmSolved(film: index, perfect: perfect(index), adClues: p.adRevealed.length);
    game.eventChanged();
    return EventSolveReward(joker: joker, pumpkinUnlocked: pumpkinUnlocked, finalReward: finalReward);
  }

  Map<String, dynamic> toJson() => {
        'firstDay': firstDay,
        'progress': {for (final e in progress.entries) '${e.key}': e.value.toJson()},
        'finalRewardGranted': finalRewardGranted,
      };

  void restore(Object? data) {
    firstDay = null;
    progress = {};
    finalRewardGranted = false;
    if (data is! Map) return;
    firstDay = data['firstDay'] as String?;
    finalRewardGranted = data['finalRewardGranted'] as bool? ?? false;
    final raw = data['progress'];
    if (raw is Map) {
      for (final e in raw.entries) {
        final index = int.tryParse('${e.key}');
        if (index == null || index < 0 || index >= filmCount || e.value is! Map) continue;
        progress[index] = EventFilmProgress.fromJson((e.value as Map).cast<String, dynamic>());
      }
    }
  }

  void reset() {
    restore(null);
    guessingFilm = null;
  }
}
