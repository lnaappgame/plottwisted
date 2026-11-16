import 'dart:math';
import 'package:flutter/foundation.dart' show protected;
import '../models/joker.dart';
import '../models/puzzle.dart';
import 'game_state.dart';

/// Les seuls jokers des events (pas de noms colorés dans leurs pitchs) : ce
/// sont aussi ceux que rapportent leurs pubs et leurs récompenses.
const kEventJokers = [JokerKind.reveal, JokerKind.eliminate, JokerKind.revealWord];

/// La grille de titre des events (Halloween, calendrier de l'Avent), jouée
/// comme dans le jeu principal : tuiles ou clavier, mots justes gardés après
/// une erreur, jokers Révéler / Éliminer / Révéler un mot puisés dans le
/// stock du jeu principal. Chaque event dit quel pitch afficher
/// ([currentPitch]), son titre ([gridTitle]) et ce que rapporte un pitch
/// trouvé ([onPitchSolved]).
mixin EventGrid implements TitleGrid {
  GameState get game;

  /// Titre du pitch [index] dans la langue [locale] (la réponse à trouver).
  String gridTitle(int index, String locale);

  /// Le pitch à afficher maintenant, ou null s'il n'y en a pas.
  int? get currentPitch;

  bool isPitchSolved(int index);

  /// Le pitch [index] vient d'être trouvé (déjà retiré des grilles gardées).
  @protected
  void onPitchSolved(int index);

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

  /// Partage façon Wordle : une ligne par validation (mot juste ou non) et
  /// les jokers joués sur le pitch, comme dans le jeu principal.
  List<List<bool>> attemptRows = [];
  List<JokerKind> jokersUsed = [];
  DateTime _pitchStart = DateTime.now();
  Duration lastSolveDuration = Duration.zero;

  /// Grilles des pitchs commencés puis laissés (lettres posées, jokers joués),
  /// rendues quand le joueur y revient. Même format que [_gridJson].
  Map<int, Map<String, dynamic>> _savedGrids = {};

  String get _locale => game.settings.locale;

  /// Prépare la grille du pitch en cours (rien à faire si elle l'est déjà).
  /// [notify] à false depuis un initState (pas de notification en plein build).
  void loadCurrent({bool notify = true}) {
    final index = currentPitch;
    if (index == loadedPitch && (index == null || (slots.isNotEmpty && _answerMatches(index)))) return;
    stashGrid();
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
    _buildGrid(gridTitle(index, _locale));
    final saved = _savedGrids.remove(index);
    if (saved != null) _applyGrid(saved);
    if (notify) game.eventChanged();
  }

  // Faux après un changement de langue : la grille est refaite dans la nouvelle.
  bool _answerMatches(int index) => slots.map((s) => s.char).join() == normalize(gridTitle(index, _locale));

  void _buildGrid(String title) {
    slots = normalize(title).split('').map(AnswerSlot.fromChar).toList();
    guess = List<int?>.filled(slots.length, null);
    lockedSlots = {};
    attemptRows = [];
    jokersUsed = [];
    _pitchStart = game.clock();
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
    lockedWords = _punctuationOnlyWords();

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
    // Chiffres : ceux du titre et deux leurres, comme dans le jeu principal.
    final usedDigits = digits.toSet();
    final digitDecoys = digits.isEmpty
        ? const <String>[]
        : ('0123456789'.split('').where((d) => !usedDigits.contains(d)).toList()..shuffle(_rng));
    pool = ([
      ...letters,
      ...decoys.take(max(5, 16 - letters.length)),
      ...digits,
      ...digitDecoys.take(2),
    ]..shuffle(_rng))
        .map((l) => LetterTile(letter: l))
        .toList();
    cursorIndex = _firstEmptySlotFrom(0);
  }

  /// Les « mots » faits seulement de ponctuation (« : » de « Mission : Noël »,
  /// « ! » de « Maman, j'ai raté l'avion ! ») : rien à y trouver. Verrouillés
  /// dès le départ, pour que « Révéler un mot » ne se dépense jamais dessus,
  /// et absents des lignes de tentative partagées.
  Set<int> _punctuationOnlyWords() => {
        for (var w = 0; w < wordRanges.length; w++)
          if (wordRanges[w].every((i) => slots[i].isAuto)) w
      };

  /// Garde la grille du pitch affiché quand le joueur en change.
  @protected
  void stashGrid() {
    final index = loadedPitch;
    if (index == null || isPitchSolved(index) || slots.isEmpty) return;
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
        'attempts': attemptRows,
        'jokersUsed': [for (final k in jokersUsed) k.name],
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
      lockedWords = {...(saved['lockedWords'] as List).cast<int>(), ..._punctuationOnlyWords()};
      attemptRows = [
        for (final row in (saved['attempts'] as List?) ?? const []) [for (final ok in row as List) ok == true]
      ];
      final byName = JokerKind.values.asNameMap();
      jokersUsed = [
        for (final n in (saved['jokersUsed'] as List?) ?? const [])
          if (byName[n] case final kind?) kind
      ];
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
    final punctuation = _punctuationOnlyWords();
    attemptRows.add([
      for (var w = 0; w < wordRanges.length; w++)
        if (!punctuation.contains(w)) lockedWords.contains(w)
    ]);
    if (lockedWords.length == wordRanges.length) {
      lastSolveDuration = game.clock().difference(_pitchStart);
      _savedGrids.remove(index);
      onPitchSolved(index);
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

  // ─── Jokers (stock du jeu principal) ───
  int countOf(JokerKind kind) => game.countOf(kind);

  void _spend(JokerKind kind) {
    jokersUsed.add(kind);
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

  /// Les mots à trouver (sans les mots faits seulement de ponctuation).
  List<int> get _letterWords => [
        for (var w = 0; w < wordRanges.length; w++)
          if (!wordRanges[w].every((i) => slots[i].isAuto)) w
      ];

  /// Titre d'un seul mot : « Révéler un mot » n'en dévoile qu'un tiers.
  bool get revealWordIsNerfed => _letterWords.length == 1;

  int get revealWordNerfCount {
    final words = _letterWords;
    if (words.isEmpty) return 1;
    final n = wordRanges[words.first].where((i) => !slots[i].isAuto).length;
    return max(1, (n / 3).ceil());
  }

  /// Même règle que dans le jeu principal : un mot entier (au plus 40 % des
  /// lettres si possible), ou un tiers des lettres d'un titre d'un seul mot.
  /// Retourne les cases révélées, vide si le joker n'a pas été consommé.
  List<int> useRevealWordJoker() {
    if (countOf(JokerKind.revealWord) <= 0) return const [];
    final totalLetters = slots.where((s) => !s.isSpace && !s.isAuto).length;
    final words = _letterWords;
    if (totalLetters == 0 || words.isEmpty) return const [];

    if (words.length == 1) {
      final revealable = wordRanges[words.first].where((i) => !slots[i].isAuto && !lockedSlots.contains(i)).toList();
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
      for (final w in words)
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

  /// Pub « Gagner un joker » : un des trois jokers des events.
  JokerKind grantAdJoker() => game.grantRandomJokerAmong(kEventJokers);

  // ─── Sauvegarde des grilles ───

  /// Les grilles commencées (celle affichée comprise), par index de pitch.
  Map<String, dynamic> gridsToJson() {
    final grids = <String, dynamic>{for (final e in _savedGrids.entries) '${e.key}': e.value};
    final index = loadedPitch;
    if (index != null && !isPitchSolved(index) && slots.isNotEmpty) grids['$index'] = _gridJson();
    return grids;
  }

  /// Vide la grille affichée et les grilles gardées.
  void resetGrids() {
    _savedGrids = {};
    loadedPitch = null;
    slots = [];
  }

  /// Relit les grilles de [gridsToJson] ; [valid] écarte les index inconnus.
  void restoreGrids(Object? grids, bool Function(Object? index) valid) {
    if (grids is! Map) return;
    for (final e in grids.entries) {
      final index = int.tryParse('${e.key}');
      if (valid(index) && e.value is Map) _savedGrids[index!] = (e.value as Map).cast<String, dynamic>();
    }
  }
}
