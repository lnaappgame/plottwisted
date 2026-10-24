import 'dart:math';
import '../data/halloween_pitches_data.dart';
import '../models/joker.dart';
import '../models/puzzle.dart';
import 'app_settings.dart';
import 'game_state.dart';

/// Pitchs ouverts dès le premier jour de l'event, puis [kEventDailyBatch] de
/// plus chaque jour.
const kEventFirstBatch = 10;
const kEventDailyBatch = 2;

/// Dernier jour de l'event (inclus, heure du téléphone). Tous les pitchs sont
/// ouverts au plus tard ce jour-là, même pour un joueur arrivé tard.
final kHalloweenEventLastDay = DateTime(2026, 11, 8);

/// Un joker gagné tous les [kEventJokerEvery] pitchs trouvés.
const kEventJokerEvery = 5;

/// Les seuls jokers de l'event (pas de noms colorés dans ses pitchs) : ce
/// sont aussi ceux que rapportent ses pubs et ses paliers.
const kEventJokers = [JokerKind.reveal, JokerKind.eliminate, JokerKind.revealWord];

/// Ce qu'a rapporté un pitch trouvé, pour l'écran de victoire.
class EventSolveReward {
  final JokerKind? joker; // palier de [kEventJokerEvery] pitchs
  final bool pumpkinUnlocked; // premier pitch trouvé
  final bool finalReward; // les 30 pitchs : bonus + citrouille en feu
  const EventSolveReward({this.joker, required this.pumpkinUnlocked, required this.finalReward});
}

/// L'event Halloween : 30 films d'horreur et d'Halloween racontés du point de
/// vue de leur méchant, à trouver l'un après l'autre comme dans le jeu
/// principal (tuiles ou clavier, Révéler / Éliminer / Révéler un mot). Son
/// état est sauvegardé avec le jeu principal (voir GameState.toJson), et il
/// utilise et alimente le même stock de jokers.
class HalloweenEvent implements TitleGrid {
  final GameState game;
  HalloweenEvent(this.game);

  String? firstDay; // premier jour où le joueur a ouvert l'event (aaaa-mm-jj)
  Set<int> solved = {};

  /// Ordre de passage : « Passer, j'y reviendrai » renvoie le pitch à la fin.
  List<int> queue = List.generate(kHalloweenPitches.length, (i) => i);

  /// Grilles des pitchs commencés puis laissés (lettres posées, jokers joués),
  /// rendues quand le joueur y revient. Même format que [_gridJson].
  Map<int, Map<String, dynamic>> _savedGrids = {};
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
  int? get currentPitch => _pending.firstOrNull;

  /// Tous les pitchs ouverts sont trouvés, d'autres arrivent les jours suivants.
  bool get waitingForTomorrow => !allSolved && currentPitch == null;

  /// À appeler à l'ouverture de l'event : fixe le premier jour du joueur.
  void markVisited() {
    if (firstDay != null) return;
    firstDay = _key(_today);
    game.eventChanged();
  }

  // ─── Grille du pitch en cours ───
  int? loadedPitch;
  @override
  List<AnswerSlot> slots = [];
  @override
  List<int?> guess = [];
  @override
  List<LetterTile> pool = [];
  @override
  List<List<int>> wordRanges = [];
  @override
  Set<int> lockedWords = {};
  @override
  Set<int> lockedSlots = {};
  @override
  int cursorIndex = -1;
  final Random _rng = Random();

  /// Pitch trouvé juste avant (écran de victoire), et ce qu'il a rapporté.
  int? lastSolvedPitch;
  EventSolveReward? lastReward;

  String get _locale => game.settings.locale;

  /// Prépare la grille du pitch en cours (rien à faire si elle l'est déjà).
  /// [notify] à false depuis un initState (pas de notification en plein build).
  void loadCurrent({bool notify = true}) {
    final index = currentPitch;
    if (index == loadedPitch && (index == null || (slots.isNotEmpty && _answerMatches(index)))) return;
    _stashGrid();
    loadedPitch = index;
    if (index == null) {
      slots = [];
      guess = [];
      pool = [];
      wordRanges = [];
      lockedWords = {};
      lockedSlots = {};
      cursorIndex = -1;
      if (notify) game.eventChanged();
      return;
    }
    _buildGrid(kHalloweenPitches[index].titleFor(_locale));
    final saved = _savedGrids.remove(index);
    if (saved != null) _applyGrid(saved);
    if (notify) game.eventChanged();
  }

  // Faux après un changement de langue : la grille est refaite dans la nouvelle.
  bool _answerMatches(int index) =>
      slots.map((s) => s.char).join() == normalize(kHalloweenPitches[index].titleFor(_locale));

  void _buildGrid(String title) {
    slots = normalize(title).split('').map(AnswerSlot.fromChar).toList();
    guess = List<int?>.filled(slots.length, null);
    lockedWords = {};
    lockedSlots = {};
    wordRanges = [];
    var current = <int>[];
    for (var i = 0; i < slots.length; i++) {
      if (slots[i].isSpace) {
        if (current.isNotEmpty) wordRanges.add(current);
        current = [];
      } else {
        current.add(i);
      }
    }
    if (current.isNotEmpty) wordRanges.add(current);

    final letters = [
      for (final s in slots)
        if (!s.isSpace && !s.isAuto && !s.isDigit) s.char
    ];
    final digits = [
      for (final s in slots)
        if (s.isDigit) s.char
    ];
    final used = letters.toSet();
    final decoys = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('').where((l) => !used.contains(l)).toList()..shuffle(_rng);
    pool = ([...letters, ...decoys.take(max(5, 16 - letters.length)), ...digits]..shuffle(_rng))
        .map((l) => LetterTile(letter: l))
        .toList();
    cursorIndex = _firstEmptySlotFrom(0);
  }

  /// Garde la grille du pitch affiché quand le joueur en change.
  void _stashGrid() {
    final index = loadedPitch;
    if (index == null || solved.contains(index) || slots.isEmpty) return;
    _savedGrids[index] = _gridJson();
  }

  Map<String, dynamic> _gridJson() => {
        'answer': slots.map((s) => s.char).join(),
        'pool': [
          for (final t in pool) [t.letter, t.used, t.eliminated, t.consumed]
        ],
        'guess': guess,
        'lockedSlots': lockedSlots.toList(),
        'lockedWords': lockedWords.toList(),
      };

  void _applyGrid(Map<String, dynamic> saved) {
    // Reprise seulement si la réponse n'a pas changé (autre langue entre-temps).
    if (saved['answer'] != slots.map((s) => s.char).join()) return;
    try {
      final savedPool = [
        for (final t in saved['pool'] as List)
          LetterTile(
              letter: (t as List)[0] as String, used: t[1] as bool, eliminated: t[2] as bool, consumed: t[3] as bool)
      ];
      final savedGuess = [for (final g in saved['guess'] as List) g as int?];
      if (savedGuess.length != slots.length) return;
      if (savedGuess.any((g) => g != null && (g < 0 || g >= savedPool.length))) return;
      pool = savedPool;
      guess = savedGuess;
      lockedSlots = (saved['lockedSlots'] as List).cast<int>().toSet();
      lockedWords = (saved['lockedWords'] as List).cast<int>().toSet();
      cursorIndex = _firstEmptySlotFrom(0);
    } catch (_) {
      // Sauvegarde illisible : on garde la grille neuve.
    }
  }

  int _firstEmptySlotFrom(int start) {
    final n = slots.length;
    for (var step = 0; step < n; step++) {
      final i = (start + step) % n;
      if (!slots[i].isSpace && !slots[i].isAuto && guess[i] == null) return i;
    }
    return -1;
  }

  bool _isSlotLocked(int i) {
    if (lockedSlots.contains(i)) return true;
    final w = wordRanges.indexWhere((r) => r.contains(i));
    return w != -1 && lockedWords.contains(w);
  }

  @override
  void onBlankTap(int i) {
    if (_isSlotLocked(i)) return;
    final tileId = guess[i];
    if (tileId != null) {
      pool[tileId].used = false;
      guess[i] = null;
      cursorIndex = _firstEmptySlotFrom(0);
    } else {
      cursorIndex = i;
    }
    game.eventChanged();
  }

  @override
  void onLetterTap(LetterTile tile) {
    if (tile.used || tile.eliminated) return;
    var target = cursorIndex;
    if (target == -1 || slots[target].isSpace || guess[target] != null || _isSlotLocked(target)) {
      target = _firstEmptySlotFrom(0);
    }
    if (target == -1) return;
    guess[target] = pool.indexOf(tile);
    tile.used = true;
    cursorIndex = _firstEmptySlotFrom(target + 1);
    game.eventChanged();
  }

  void clearLastLetter() {
    for (var i = slots.length - 1; i >= 0; i--) {
      if (slots[i].isSpace || slots[i].isAuto || _isSlotLocked(i)) continue;
      if (guess[i] != null) {
        pool[guess[i]!].used = false;
        guess[i] = null;
        cursorIndex = i;
        game.eventChanged();
        return;
      }
    }
  }

  bool get _allFilled =>
      slots.isNotEmpty &&
      List.generate(slots.length, (i) => slots[i].isSpace || slots[i].isAuto || guess[i] != null).every((v) => v);

  bool get gridFull => _allFilled;

  /// 'incomplete', 'wrong' (les mots justes restent acquis, comme dans le jeu
  /// principal) ou 'solved'.
  String validate() {
    final index = loadedPitch;
    if (index == null || !_allFilled) return 'incomplete';
    for (var w = 0; w < wordRanges.length; w++) {
      if (lockedWords.contains(w)) continue;
      final range = wordRanges[w];
      final attempt = range.map((i) => slots[i].isAuto ? slots[i].char : pool[guess[i]!].letter).join();
      if (attempt == range.map((i) => slots[i].char).join()) {
        lockedWords.add(w);
        for (final i in range) {
          if (!slots[i].isAuto) pool[guess[i]!].consumed = true;
        }
      }
    }
    if (lockedWords.length == wordRanges.length) {
      lastReward = _solve(index);
      return 'solved';
    }
    for (var w = 0; w < wordRanges.length; w++) {
      if (lockedWords.contains(w)) continue;
      for (final i in wordRanges[w]) {
        if (slots[i].isAuto || lockedSlots.contains(i)) continue;
        final tileId = guess[i];
        if (tileId != null) pool[tileId].used = false;
        guess[i] = null;
      }
    }
    cursorIndex = _firstEmptySlotFrom(0);
    game.eventChanged();
    return 'wrong';
  }

  EventSolveReward _solve(int index) {
    solved.add(index);
    _savedGrids.remove(index);
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
    _stashGrid();
    loadedPitch = null;
    queue
      ..remove(index)
      ..add(index);
    loadCurrent();
    return true;
  }

  // ─── Jokers (stock du jeu principal) ───
  int countOf(JokerKind kind) => game.countOf(kind);

  void _spend(JokerKind kind) {
    switch (kind) {
      case JokerKind.reveal:
        game.revealCount--;
      case JokerKind.eliminate:
        game.eliminateCount--;
      case JokerKind.revealWord:
        game.revealWordCount--;
      default:
        break;
    }
  }

  /// Retourne la case révélée, ou null si le joker n'a pas été utilisé.
  int? useRevealJoker() {
    if (countOf(JokerKind.reveal) <= 0) return null;
    final empty = [
      for (var i = 0; i < slots.length; i++)
        if (!slots[i].isSpace && !slots[i].isAuto && guess[i] == null) i
    ];
    if (empty.isEmpty) return null;
    final target = empty[_rng.nextInt(empty.length)];
    final tileIdx = pool.indexWhere((t) => t.letter == slots[target].char && !t.used && !t.eliminated);
    if (tileIdx == -1) return null;
    guess[target] = tileIdx;
    pool[tileIdx].used = true;
    lockedSlots.add(target);
    if (cursorIndex == target) cursorIndex = _firstEmptySlotFrom(target);
    _spend(JokerKind.reveal);
    game.eventChanged();
    return target;
  }

  /// Retourne les lettres éliminées (indices dans [pool]), vide si aucune.
  List<int> useEliminateJoker() {
    if (countOf(JokerKind.eliminate) <= 0) return const [];
    final correct = slots.where((s) => !s.isSpace).map((s) => s.char).toSet();
    final wrong = [
      for (var i = 0; i < pool.length; i++)
        if (!correct.contains(pool[i].letter) && !pool[i].eliminated && !pool[i].used) i
    ];
    if (wrong.isEmpty) return const [];
    wrong.shuffle(_rng);
    final eliminated = wrong.take(3).toList();
    for (final i in eliminated) {
      pool[i].eliminated = true;
    }
    _spend(JokerKind.eliminate);
    game.eventChanged();
    return eliminated;
  }

  /// Titre d'un seul mot : « Révéler un mot » n'en dévoile qu'un tiers.
  bool get revealWordIsNerfed => wordRanges.length == 1;

  int get revealWordNerfCount {
    if (wordRanges.isEmpty) return 1;
    final n = wordRanges[0].where((i) => !slots[i].isAuto).length;
    return max(1, (n / 3).ceil());
  }

  /// Même règle que dans le jeu principal : un mot entier (au plus 40 % des
  /// lettres si possible), ou un tiers des lettres d'un titre d'un seul mot.
  /// Retourne les cases révélées, vide si le joker n'a pas été consommé.
  List<int> useRevealWordJoker() {
    if (countOf(JokerKind.revealWord) <= 0) return const [];
    final totalLetters = slots.where((s) => !s.isSpace && !s.isAuto).length;
    if (totalLetters == 0 || wordRanges.isEmpty) return const [];

    if (wordRanges.length == 1) {
      final revealable = wordRanges[0].where((i) => !slots[i].isAuto && !lockedSlots.contains(i)).toList();
      if (revealable.isEmpty) return const [];
      revealable.shuffle(_rng);
      final revealed = <int>[];
      for (final i in revealable.take(revealWordNerfCount)) {
        final correctChar = slots[i].char;
        if (guess[i] != null && pool[guess[i]!].letter == correctChar) {
          lockedSlots.add(i);
          revealed.add(i);
          continue;
        }
        final tileIdx = pool.indexWhere((t) => t.letter == correctChar && !t.used && !t.eliminated);
        if (tileIdx == -1) continue;
        if (guess[i] != null) pool[guess[i]!].used = false;
        guess[i] = tileIdx;
        pool[tileIdx].used = true;
        lockedSlots.add(i);
        revealed.add(i);
      }
      if (revealed.isNotEmpty) _spend(JokerKind.revealWord);
      cursorIndex = _firstEmptySlotFrom(0);
      game.eventChanged();
      return revealed;
    }

    final open = [
      for (var w = 0; w < wordRanges.length; w++)
        if (!lockedWords.contains(w)) w
    ];
    if (open.isEmpty) return const [];
    final eligible = open.where((w) => wordRanges[w].length <= totalLetters * 0.4).toList();
    final int target;
    if (eligible.isNotEmpty) {
      target = eligible[_rng.nextInt(eligible.length)];
    } else {
      open.sort((a, b) => wordRanges[a].length.compareTo(wordRanges[b].length));
      target = open.first;
    }
    var complete = true;
    for (final i in wordRanges[target]) {
      if (slots[i].isAuto || lockedSlots.contains(i)) continue;
      final correctChar = slots[i].char;
      if (guess[i] != null && pool[guess[i]!].letter == correctChar) continue;
      final tileIdx = pool.indexWhere((t) => t.letter == correctChar && !t.used && !t.eliminated);
      if (tileIdx == -1) {
        complete = false;
        continue;
      }
      if (guess[i] != null) pool[guess[i]!].used = false;
      guess[i] = tileIdx;
      pool[tileIdx].used = true;
      pool[tileIdx].consumed = true;
    }
    if (complete) {
      lockedWords.add(target);
      _spend(JokerKind.revealWord);
    }
    cursorIndex = _firstEmptySlotFrom(0);
    game.eventChanged();
    return complete
        ? [
            for (final i in wordRanges[target])
              if (!slots[i].isAuto) i
          ]
        : const [];
  }

  /// Pub « Gagner un joker » : un des trois jokers de l'event.
  JokerKind grantAdJoker() => game.grantRandomJokerAmong(kEventJokers);

  // ─── Sauvegarde ───
  Map<String, dynamic> toJson() {
    final grids = {for (final e in _savedGrids.entries) '${e.key}': e.value};
    final index = loadedPitch;
    if (index != null && !solved.contains(index) && slots.isNotEmpty) grids['$index'] = _gridJson();
    return {
      'mode': 'pitchs',
      'firstDay': firstDay,
      'solved': solved.toList(),
      'queue': queue,
      'grids': grids,
      'finalRewardGranted': finalRewardGranted,
    };
  }

  void restore(Object? data) {
    firstDay = null;
    solved = {};
    queue = List.generate(pitchCount, (i) => i);
    _savedGrids = {};
    finalRewardGranted = false;
    loadedPitch = null;
    slots = [];
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
    final grids = data['grids'];
    if (grids is Map) {
      for (final e in grids.entries) {
        final index = int.tryParse('${e.key}');
        if (valid(index) && e.value is Map) _savedGrids[index!] = (e.value as Map).cast<String, dynamic>();
      }
    }
  }

  void reset() => restore(null);
}
