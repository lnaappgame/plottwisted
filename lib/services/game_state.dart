import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../data/puzzles_data.dart';
import '../models/puzzle.dart';
import 'ad_service.dart';
import 'analytics_service.dart';
import 'app_settings.dart';
import 'save_service.dart';

/// Traduit pour l'affichage un libellé de joker renvoyé par
/// [GameState.grantMinorJoker]/[GameState.grantMajorJoker] (toujours en
/// français en interne — ce sont ces valeurs précises que leurs switch
/// utilisent pour savoir quel compteur incrémenter, donc jamais changées).
String jokerLabelFor(String frLabel, String locale) {
  if (locale != 'en') return frLabel;
  const map = {
    'Révéler': 'Reveal',
    'Éliminer': 'Eliminate',
    'Personnage': 'Character',
    'Personnage (rouge)': 'Character (red)',
    'Acteur': 'Actor',
    'Indice': 'Hint',
    'Révéler un mot': 'Reveal a word',
  };
  return map[frLabel] ?? frLabel;
}

String normalize(String input) {
  const withAccents = 'ÀÂÄÉÈÊËÎÏÔÖÙÛÜÇàâäéèêëîïôöùûüç';
  const withoutAccents = 'AAAEEEEIIOOUUUCaaaeeeeiioouuuc';
  var result = input.toUpperCase();
  var withAccentsUpper = withAccents.toUpperCase();
  for (var i = 0; i < withAccentsUpper.length; i++) {
    result = result.replaceAll(withAccentsUpper[i], withoutAccents[i].toUpperCase());
  }
  return result;
}

class GameState extends ChangeNotifier {
  final AdService adService;
  final SaveService saveService;
  final AnalyticsService analytics;
  final AppSettings settings;
  final Random _rng = Random();

  GameState({required this.adService, required this.saveService, required this.settings, AnalyticsService? analytics})
      : analytics = analytics ?? AnalyticsService();

  // Langue figée au chargement de la devinette (voir loadPuzzle()) plutôt que
  // lue en direct depuis settings à chaque affichage : un changement de
  // langue en cours de niveau ne doit pas faire basculer une grille de
  // lettres déjà en cours de résolution.
  String locale = 'fr';

  // ─── Sauvegarde ───
  // Toute mutation d'état passe par notifyListeners() : on en profite pour
  // déclencher une sauvegarde débounced (au plus une écriture disque toutes
  // les 600ms), plutôt que d'ajouter un appel de sauvegarde à chaque endroit
  // qui modifie l'état.
  Timer? _saveDebounce;
  bool _restoring = false;

  @override
  void notifyListeners() {
    super.notifyListeners();
    if (_restoring) return;
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 600), flushSave);
  }

  Future<void> flushSave() async {
    _saveDebounce?.cancel();
    await saveService.save(toJson());
  }

  Map<String, dynamic> toJson() => {
        'worldIndex': worldIndex,
        'currentLevelNumber': currentLevelNumber,
        'remainingLevels': remainingLevels,
        'revealCount': revealCount,
        'eliminateCount': eliminateCount,
        'actorCount': actorCount,
        'characterCount': characterCount,
        'hintCount': hintCount,
        'revealWordCount': revealWordCount,
        'redJokerCount': redJokerCount,
        'minorMilestoneCount': minorMilestoneCount,
        'majorMilestoneCount': majorMilestoneCount,
        'colorsSeen': colorsSeen.toList(),
        'orangeIntroShown': orangeIntroShown,
        'violetIntroShown': violetIntroShown,
        'gameStarted': gameStarted,
        'isAdFree': adService.isAdFree,
        'adFreeUntil': adService.adFreeUntil?.toIso8601String(),
        'worldChoiceReserve': worldChoiceReserve,
        'worldChoiceFrontier': _worldChoiceFrontier,
        'worldChoicesExhausted': _worldChoicesExhausted,
        'worldsPlayedHistory': worldsPlayedHistory.toList(),
        'allWorldsCompleted': allWorldsCompleted,
        'allWorldsCompletedAtMax': _allWorldsCompletedAtMax,
      };

  /// Charge la sauvegarde existante, s'il y en a une. À appeler une seule
  /// fois au démarrage, avant que l'UI ne soit affichée.
  Future<void> restore() async {
    final data = await saveService.load();
    if (data == null) return;
    _restoring = true;
    worldIndex = data['worldIndex'] as int? ?? worldIndex;
    currentLevelNumber = data['currentLevelNumber'] as int? ?? currentLevelNumber;
    remainingLevels = (data['remainingLevels'] as List?)?.cast<int>() ?? remainingLevels;
    revealCount = data['revealCount'] as int? ?? revealCount;
    eliminateCount = data['eliminateCount'] as int? ?? eliminateCount;
    actorCount = data['actorCount'] as int? ?? actorCount;
    characterCount = data['characterCount'] as int? ?? characterCount;
    hintCount = data['hintCount'] as int? ?? hintCount;
    revealWordCount = data['revealWordCount'] as int? ?? revealWordCount;
    redJokerCount = data['redJokerCount'] as int? ?? redJokerCount;
    minorMilestoneCount = data['minorMilestoneCount'] as int? ?? minorMilestoneCount;
    majorMilestoneCount = data['majorMilestoneCount'] as int? ?? majorMilestoneCount;
    final savedColors = (data['colorsSeen'] as List?)?.cast<String>();
    if (savedColors != null) {
      colorsSeen
        ..clear()
        ..addAll(savedColors);
    }
    orangeIntroShown = data['orangeIntroShown'] as bool? ?? orangeIntroShown;
    violetIntroShown = data['violetIntroShown'] as bool? ?? violetIntroShown;
    gameStarted = data['gameStarted'] as bool? ?? gameStarted;
    adService.isAdFree = data['isAdFree'] as bool? ?? adService.isAdFree;
    final savedAdFreeUntil = data['adFreeUntil'] as String?;
    if (savedAdFreeUntil != null) adService.adFreeUntil = DateTime.tryParse(savedAdFreeUntil);
    worldChoiceReserve = data['worldChoiceReserve'] as int?;
    _worldChoiceFrontier = data['worldChoiceFrontier'] as int? ?? _worldChoiceFrontier;
    _worldChoicesExhausted = data['worldChoicesExhausted'] as bool? ?? _worldChoicesExhausted;
    allWorldsCompleted = data['allWorldsCompleted'] as bool? ?? allWorldsCompleted;
    _allWorldsCompletedAtMax = data['allWorldsCompletedAtMax'] as int? ?? _allWorldsCompletedAtMax;
    final savedWorldsPlayed = (data['worldsPlayedHistory'] as List?)?.cast<int>();
    if (savedWorldsPlayed != null) {
      worldsPlayedHistory = savedWorldsPlayed.toSet();
    } else if (worldIndex > 0) {
      // Sauvegarde antérieure à ce compteur : un joueur déjà avancé ne doit
      // pas se retrouver traité comme un nouveau joueur (paliers pubs
      // réduites) — on reconstitue un historique linéaire équivalent à sa
      // progression actuelle plutôt que de repartir de zéro.
      worldsPlayedHistory = List.generate(worldIndex, (i) => i + 1).toSet();
    }
    // Filet de sécurité : une sauvegarde corrompue, ou une mise à jour de
    // contenu qui renumérote/retire un monde ou réduit son nombre de
    // niveaux, ne doit jamais planter l'app au démarrage (currentWorld /
    // loadPuzzle indexent sans autre vérification) — on retombe sur le
    // tout début plutôt que de laisser worldIndex/currentLevelNumber
    // pointer dans le vide.
    final worldExiste = worldIndex == 0 || kWorlds.any((w) => w.number == worldIndex);
    final niveauxDuMonde = worldExiste ? currentWorld.puzzles.length : 0;
    if (!worldExiste || currentLevelNumber < 1 || currentLevelNumber > niveauxDuMonde) {
      worldIndex = 0;
      currentLevelNumber = 1;
      remainingLevels = List.generate(kTutorialPuzzles.length, (i) => i + 1);
    }
    // puzzleLoaded reste faux : le niveau en cours sera rechargé "propre" au
    // prochain lancement (la grille en cours de saisie n'est pas persistée).
    _restoring = false;
  }

  /// Ajoute les jokers d'un [JokerGrant] (achat boutique, récompense, etc.).
  void grantJokers({int reveal = 0, int eliminate = 0, int actor = 0, int character = 0, int hint = 0, int redJoker = 0}) {
    revealCount += reveal;
    eliminateCount += eliminate;
    actorCount += actor;
    characterCount += character;
    hintCount += hint;
    redJokerCount += redJoker;
    notifyListeners();
  }

  // ─── Navigation ───
  int worldIndex = 0;
  List<int> remainingLevels = [];
  int currentLevelNumber = 1;
  late Puzzle currentPuzzle;

  // Mondes réels (hors tutoriel) déjà joués au moins une fois — sert à faire
  // varier la fréquence des pubs forcées selon l'ancienneté du joueur (voir
  // [mustShowForcedAd]). Un Set plutôt qu'un simple compteur : robuste si un
  // monde est un jour rejouable sans compter une deuxième fois.
  Set<int> worldsPlayedHistory = {};
  int get worldsPlayedCount => worldsPlayedHistory.length;

  GameWorld get currentWorld =>
      worldIndex == 0
          ? GameWorld(number: 0, categoryLabel: 'Tutoriel', categoryLabelUs: 'Tutorial', puzzles: kTutorialPuzzles)
          // orElse en filet de sécurité : ne doit normalement jamais servir
          // (voir la validation dans restore()), mais un monde inexistant ne
          // doit jamais planter l'app plutôt que de simplement mal s'afficher.
          : kWorlds.firstWhere((w) => w.number == worldIndex, orElse: () => kWorlds.first);
  bool get inTutorial => worldIndex == 0;

  String get difficultyLabel =>
      inTutorial ? 'Tutoriel' : (kDifficultyPattern[currentLevelNumber] ?? '');
  String difficultyLabelFor(String loc) => loc == 'en'
      ? (inTutorial ? 'Tutorial' : (kDifficultyPatternUs[currentLevelNumber] ?? ''))
      : difficultyLabel;
  String get levelTitle => 'Monde ${currentWorld.number}-$currentLevelNumber';
  String levelTitleFor(String loc) =>
      loc == 'en' ? 'World ${currentWorld.number}-$currentLevelNumber' : levelTitle;

  // ─── Grille de réponse ───
  List<AnswerSlot> slots = [];
  List<int?> guess = [];
  List<LetterTile> pool = [];
  List<List<int>> wordRanges = [];
  Set<int> lockedWords = {};
  // Cases remplies par un joker (Révéler, ou Révéler un mot sur une réponse
  // à un seul mot) : verrouillées individuellement, indépendamment du
  // verrouillage par mot complet — une lettre gagnée via joker reste visible
  // jusqu'à la fin du niveau, même après une mauvaise réponse.
  Set<int> lockedSlots = {};
  int cursorIndex = -1;

  // ─── Couleurs des noms du pitch (état courant, peut changer via jokers) ───
  NameColor p1State = NameColor.red;
  NameColor p2State = NameColor.red;
  NameColor? activeNameJoker; // joker "Acteur" ou "Personnage" armé

  // ─── Jokers ───
  // Mineurs : Révéler / Éliminer / Personnage. Majeurs : Acteur / Indice /
  // Révéler un mot (paliers de récompense — voir grantMinorJoker/grantMajorJoker).
  int revealCount = 0;
  int eliminateCount = 0;
  int actorCount = 0;
  int characterCount = 0;
  int hintCount = 0;
  int revealWordCount = 0;
  bool hintRevealed = false;

  // Joker rouge : débloque un nom ORANGE en le faisant passer en rouge (les
  // jokers classiques Acteur/Personnage prennent ensuite le relais, comme
  // pour n'importe quel nom rouge). Trois façons de l'obtenir : pub garantie
  // (1 fois par niveau concerné), top 10% mondial de L'énigme de la semaine,
  // ou achat en boutique. Le violet, lui, se débloque déjà normalement avec
  // les jokers classiques — aucun traitement spécial nécessaire.
  int redJokerCount = 0;
  bool redJokerAdWatchedThisLevel = false; // remis à zéro à chaque nouveau niveau, non persisté

  int minorMilestoneCount = 0; // cycle Révéler → Éliminer → Personnage au palier niveau 5 ET fin de monde
  int majorMilestoneCount = 0; // cycle Acteur → Indice → Révéler un mot au palier fin de monde
  int adsWatchedThisLevel = 0; // 80/20 mineur/majeur la 1ère pub du niveau, 60/40 ensuite

  // ─── Pub ───
  DateTime levelStartTime = DateTime.now();
  Duration lastSolveDuration = Duration.zero;

  // ─── Tutoriel ───
  bool orangeIntroShown = false;
  bool violetIntroShown = false;
  bool orangeIntroPending = false;
  bool violetIntroPending = false;
  final Set<String> colorsSeen = {'green', 'red', 'blue'};

  // ─── Notifications ponctuelles à consommer par l'UI ───
  String? pendingMinorJokerLabel;
  String? revealedHintText; // texte de l'indice affiché en permanence sous le pitch

  // ─── Échecs / popup / inactivité ───
  int failStreak = 0;
  DateTime lastActivityTime = DateTime.now();
  bool idlePopupShown = false;
  bool adCloseExplained = false; // affiche le toast d'explication une seule fois

  void markActivity() {
    lastActivityTime = DateTime.now();
    idlePopupShown = false;
  }

  // ─── Reprise de partie ───
  // gameStarted : une partie a déjà été lancée au moins une fois (permet à
  // "JOUER" de reprendre là où le joueur en était plutôt que de repartir du
  // tutoriel à chaque retour au menu). puzzleLoaded : un puzzle est
  // actuellement chargé (permet à l'écran de jeu de savoir s'il doit
  // ré-afficher l'écran d'annonce de monde ou reprendre directement).
  bool gameStarted = false;
  bool puzzleLoaded = false;

  void enterWorld(int number) {
    gameStarted = true;
    puzzleLoaded = false;
    worldIndex = number;
    if (number != 0) worldsPlayedHistory.add(number);
    final world = currentWorld;
    remainingLevels = List.generate(world.puzzles.length, (i) => i + 1);
    currentLevelNumber = remainingLevels.first;
  }

  // ─── Choix du monde suivant ───
  // Le monde 1 est toujours imposé. Ensuite, à chaque fin de monde, le
  // joueur choisit entre le monde "en réserve" (proposé la dernière fois
  // mais pas choisi) et le monde suivant jamais encore proposé — celui-ci
  // avance de 1 à chaque choix, qu'il soit choisi ou non.
  int? worldChoiceReserve;
  int _worldChoiceFrontier = 4; // prochain monde "neuf" après le tout premier choix
  bool _worldChoicesExhausted = false;

  // Vrai une fois que le joueur a terminé le dernier niveau du dernier monde
  // disponible ; _allWorldsCompletedAtMax fige le nombre de mondes qui
  // existaient à cet instant précis. Sert à afficher la page "prochainement"
  // (voir [shouldShowComingSoonPage]) et, si une future mise à jour ajoute
  // des mondes au-delà de ce nombre, à débloquer automatiquement à la fois
  // cette page ET [worldChoiceOptions] (sinon un joueur ayant déjà tout fini
  // resterait coincé pour toujours malgré le nouveau contenu).
  bool allWorldsCompleted = false;
  int _allWorldsCompletedAtMax = 0;

  int get _maxWorldNumber => kWorlds.map((w) => w.number).fold(0, max);

  /// Vrai si le joueur a déjà fini tout le contenu disponible et qu'aucune
  /// mise à jour n'a depuis ajouté de nouveaux mondes.
  bool get shouldShowComingSoonPage => allWorldsCompleted && _maxWorldNumber <= _allWorldsCompletedAtMax;

  /// Les 1 ou 2 mondes à proposer au joueur. Vide si le contenu touche à sa
  /// fin (plus aucun monde à proposer).
  ///
  /// worldChoiceReserve == null signifie "premier choix jamais fait" : les 2
  /// mondes proposés sont alors ceux qui suivent directement le monde qu'on
  /// vient de terminer (worldIndex), et non 2/3 en dur — indispensable pour
  /// une sauvegarde existante qui atteint ce mécanisme en cours de partie
  /// (ex. monde 15 déjà en cours) plutôt que juste après le monde 1.
  List<int> get worldChoiceOptions {
    final maxN = _maxWorldNumber;
    if (_worldChoicesExhausted) {
      if (allWorldsCompleted && maxN > _allWorldsCompletedAtMax) {
        // Du nouveau contenu est arrivé depuis : on redonne une chance au
        // mécanisme de choix plutôt que de rester bloqué indéfiniment.
        _worldChoicesExhausted = false;
      } else {
        return [];
      }
    }
    if (worldChoiceReserve == null) {
      return [worldIndex + 1, worldIndex + 2].where((n) => n <= maxN).toList();
    }
    final options = <int>[];
    if (worldChoiceReserve! <= maxN) options.add(worldChoiceReserve!);
    if (_worldChoiceFrontier <= maxN && _worldChoiceFrontier != worldChoiceReserve) {
      options.add(_worldChoiceFrontier);
    }
    return options;
  }

  /// Applique le choix du joueur et démarre le monde choisi.
  void chooseNextWorld(int chosen) {
    final options = worldChoiceOptions;
    final wasBootstrap = worldChoiceReserve == null;
    final justFinished = worldIndex;
    final notChosen = options.where((w) => w != chosen).toList();
    if (notChosen.isEmpty) {
      // Il ne restait qu'un seul monde à proposer et il vient d'être choisi :
      // plus rien en réserve pour la prochaine fois.
      worldChoiceReserve = null;
      _worldChoicesExhausted = true;
    } else {
      worldChoiceReserve = notChosen.first;
    }
    if (wasBootstrap) {
      _worldChoiceFrontier = justFinished + 3; // après les 2 mondes déjà proposés
    } else {
      _worldChoiceFrontier++;
    }
    enterWorld(chosen);
  }

  /// Efface toute la progression (monde, niveau, jokers, paliers) pour
  /// repartir de zéro — action destructive déclenchée depuis les paramètres,
  /// après double confirmation côté UI.
  Future<void> resetProgress() async {
    _saveDebounce?.cancel();
    worldIndex = 0;
    remainingLevels = [];
    currentLevelNumber = 1;
    revealCount = 0;
    eliminateCount = 0;
    actorCount = 0;
    characterCount = 0;
    hintCount = 0;
    revealWordCount = 0;
    redJokerCount = 0;
    minorMilestoneCount = 0;
    majorMilestoneCount = 0;
    colorsSeen
      ..clear()
      ..addAll({'green', 'red', 'blue'});
    orangeIntroShown = false;
    violetIntroShown = false;
    gameStarted = false;
    puzzleLoaded = false;
    worldChoiceReserve = null;
    _worldChoiceFrontier = 4;
    _worldChoicesExhausted = false;
    allWorldsCompleted = false;
    _allWorldsCompletedAtMax = 0;
    worldsPlayedHistory = {};
    adsWatchedThisLevel = 0;
    await flushSave();
    notifyListeners();
  }

  void loadPuzzle() {
    puzzleLoaded = true;
    locale = settings.locale;
    final world = currentWorld;
    currentPuzzle = world.puzzles[currentLevelNumber - 1];
    p1State = currentPuzzle.p1InitialColor;
    p2State = currentPuzzle.p2InitialColor;
    activeNameJoker = null;
    lockedWords = {};
    lockedSlots = {};
    failStreak = 0;
    hintRevealed = false;
    revealedHintText = null;
    adsWatchedThisLevel = 0;
    redJokerAdWatchedThisLevel = false;
    levelStartTime = DateTime.now();
    lastActivityTime = DateTime.now();
    idlePopupShown = false;

    if (!orangeIntroShown && (p1State == NameColor.orange || p2State == NameColor.orange)) {
      orangeIntroShown = true;
      orangeIntroPending = true;
      colorsSeen.add('orange');
    }
    if (!violetIntroShown && (p1State == NameColor.violet || p2State == NameColor.violet)) {
      violetIntroShown = true;
      violetIntroPending = true;
      colorsSeen.add('violet');
    }

    final titleClean = normalize(currentPuzzle.titleFor(locale));
    slots = titleClean.split('').map((c) => AnswerSlot.fromChar(c)).toList();
    guess = List<int?>.filled(slots.length, null);

    wordRanges = [];
    List<int> current = [];
    for (var i = 0; i < slots.length; i++) {
      if (slots[i].isSpace) {
        if (current.isNotEmpty) wordRanges.add(current);
        current = [];
      } else {
        current.add(i);
      }
    }
    if (current.isNotEmpty) wordRanges.add(current);

    final correctLetters = <String>[];
    final correctDigits = <String>[];
    for (final s in slots) {
      if (s.isSpace || s.isAuto) continue;
      if (s.isDigit) correctDigits.add(s.char); else correctLetters.add(s.char);
    }
    final hasLetters = correctLetters.isNotEmpty;
    final hasDigits = correctDigits.isNotEmpty;

    final letterTiles = <String>[];
    if (hasLetters) {
      final used = correctLetters.toSet();
      final alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('').where((l) => !used.contains(l)).toList()..shuffle(_rng);
      final decoysNeeded = max(5, 16 - correctLetters.length);
      letterTiles.addAll(correctLetters);
      letterTiles.addAll(alphabet.take(decoysNeeded));
    }
    final digitTiles = <String>[];
    if (hasDigits) {
      final usedD = correctDigits.toSet();
      final digitAlphabet = '0123456789'.split('').where((d) => !usedD.contains(d)).toList()..shuffle(_rng);
      digitTiles.addAll(correctDigits);
      digitTiles.addAll(digitAlphabet.take(min(2, digitAlphabet.length)));
    }

    final all = hasLetters ? [...letterTiles, ...digitTiles] : digitTiles;
    all.shuffle(_rng);
    pool = all.map((l) => LetterTile(letter: l)).toList();

    cursorIndex = _firstEmptySlotFrom(0);
    notifyListeners();
  }

  bool consumeOrangeIntroPending() {
    if (!orangeIntroPending) return false;
    orangeIntroPending = false;
    return true;
  }

  bool consumeVioletIntroPending() {
    if (!violetIntroPending) return false;
    violetIntroPending = false;
    return true;
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

  // ─── Pitch : couleurs et interaction ───
  String displayFor(String slotKey) {
    final person = slotKey == 'p1' ? currentPuzzle.p1 : currentPuzzle.p2;
    final color = slotKey == 'p1' ? p1State : p2State;
    return person.displayFor(color, locale);
  }

  /// true si p1 ou p2 est actuellement orange — condition d'apparition du
  /// bouton "joker rouge" (débloque ce nom en le faisant passer en rouge).
  bool get currentPuzzleHasOrange => p1State == NameColor.orange || p2State == NameColor.orange;

  void selectNameJoker(NameColor color) {
    if (color == NameColor.blue && actorCount <= 0) return;
    if (color == NameColor.green && characterCount <= 0) return;
    if (color == NameColor.red && redJokerCount <= 0) return;
    markActivity(); // un joueur qui ne joue que via jokers reste actif
    activeNameJoker = activeNameJoker == color ? null : color;
    notifyListeners();
  }

  /// Retourne un message d'erreur si le clic est invalide, sinon null.
  String? onNameTap(String slotKey) {
    if (activeNameJoker == null) return "Choisis d'abord le joker Acteur ou Personnage";
    final current = slotKey == 'p1' ? p1State : p2State;
    if (current == activeNameJoker) return "Ce nom est déjà de cette couleur";
    if (activeNameJoker == NameColor.red && current != NameColor.orange) {
      return "Le joker rouge ne fonctionne que sur un nom orange";
    }
    markActivity(); // un joueur qui ne joue que via jokers reste actif
    if (slotKey == 'p1') { p1State = activeNameJoker!; } else { p2State = activeNameJoker!; }
    if (activeNameJoker == NameColor.blue) {
      actorCount--;
    } else if (activeNameJoker == NameColor.red) {
      redJokerCount--;
    } else {
      characterCount--;
    }
    activeNameJoker = null;
    if (!orangeIntroShown && (p1State == NameColor.orange || p2State == NameColor.orange)) {
      orangeIntroShown = true; colorsSeen.add('orange');
    }
    if (!violetIntroShown && (p1State == NameColor.violet || p2State == NameColor.violet)) {
      violetIntroShown = true; colorsSeen.add('violet');
    }
    notifyListeners();
    return null;
  }

  // ─── Saisie ───
  void onBlankTap(int i) {
    if (_isSlotLocked(i)) return;
    final tileId = guess[i];
    if (tileId != null) {
      // La case était remplie : le joueur l'efface. Une seule suppression,
      // le curseur reste sur cette case ; plusieurs suppressions à des
      // positions différentes, on revient à la première case vide depuis le
      // début de la réponse plutôt que de rester sur la dernière touchée.
      pool[tileId].used = false;
      guess[i] = null;
      cursorIndex = _firstEmptySlotFrom(0);
    } else {
      // La case était déjà vide : le joueur choisit explicitement où taper
      // la prochaine lettre (pas forcément la première case vide — il doit
      // pouvoir remplir n'importe quelle case dans l'ordre qu'il veut, y
      // compris pour défausser une lettre en la plaçant plus loin). On
      // respecte ce choix tel quel, sans le rediriger.
      cursorIndex = i;
    }
    markActivity();
    notifyListeners();
  }

  void onLetterTap(LetterTile tile) {
    final idx = pool.indexOf(tile);
    if (tile.used || tile.eliminated) return;
    var target = cursorIndex;
    if (target == -1 || slots[target].isSpace || guess[target] != null || _isSlotLocked(target)) {
      target = _firstEmptySlotFrom(0);
    }
    if (target == -1) return;
    guess[target] = idx;
    tile.used = true;
    cursorIndex = _firstEmptySlotFrom(target + 1);
    markActivity();
    notifyListeners();
  }

  void clearLastLetter() {
    for (var i = slots.length - 1; i >= 0; i--) {
      if (slots[i].isSpace || slots[i].isAuto || _isSlotLocked(i)) continue;
      if (guess[i] != null) {
        pool[guess[i]!].used = false;
        guess[i] = null;
        cursorIndex = i;
        markActivity();
        notifyListeners();
        return;
      }
    }
  }

  /// Résultat de la validation : "incomplete", "wrong" (au moins un mot
  /// faux), ou "solved".
  String validate() {
    markActivity();
    final allFilled = List.generate(slots.length,
        (i) => slots[i].isSpace || slots[i].isAuto || guess[i] != null).every((v) => v);
    if (!allFilled) return 'incomplete';

    for (var w = 0; w < wordRanges.length; w++) {
      if (lockedWords.contains(w)) continue;
      final range = wordRanges[w];
      final attempt = range.map((i) => slots[i].isAuto ? slots[i].char : pool[guess[i]!].letter).join();
      final correct = range.map((i) => slots[i].char).join();
      if (attempt == correct) {
        lockedWords.add(w);
        for (final i in range) {
          if (!slots[i].isAuto) pool[guess[i]!].consumed = true;
        }
      }
    }

    final allLocked = List.generate(wordRanges.length, (w) => lockedWords.contains(w)).every((v) => v);
    if (allLocked) {
      failStreak = 0;
      lastSolveDuration = DateTime.now().difference(levelStartTime);
      notifyListeners();
      analytics.logLevelCompleted(world: currentWorld.number, level: currentLevelNumber, difficulty: difficultyLabel);
      return 'solved';
    }

    for (var w = 0; w < wordRanges.length; w++) {
      if (lockedWords.contains(w)) continue;
      for (final i in wordRanges[w]) {
        // Une lettre gagnée via joker (Révéler, ou Révéler un mot sur une
        // réponse à un seul mot) reste affichée même après une mauvaise
        // réponse — seules les lettres placées par le joueur sont effacées.
        if (slots[i].isAuto || lockedSlots.contains(i)) continue;
        final tileId = guess[i];
        if (tileId != null) pool[tileId].used = false;
        guess[i] = null;
      }
    }
    cursorIndex = _firstEmptySlotFrom(0);
    failStreak++;
    notifyListeners();
    return 'wrong';
  }

  // ─── Jokers utilitaires ───
  void useRevealJoker() {
    if (revealCount <= 0) return;
    final emptyIdx = [
      for (var i = 0; i < slots.length; i++)
        if (!slots[i].isSpace && !slots[i].isAuto && guess[i] == null) i
    ];
    if (emptyIdx.isEmpty) return;
    final target = emptyIdx[_rng.nextInt(emptyIdx.length)];
    final correctChar = slots[target].char;
    final tileIdx = pool.indexWhere((t) => t.letter == correctChar && !t.used && !t.eliminated);
    if (tileIdx == -1) return;
    markActivity(); // un joueur qui ne joue que via jokers reste actif
    guess[target] = tileIdx;
    pool[tileIdx].used = true;
    lockedSlots.add(target);
    revealCount--;
    notifyListeners();
  }

  void useEliminateJoker() {
    if (eliminateCount <= 0) return;
    final correctChars = slots.where((s) => !s.isSpace).map((s) => s.char).toSet();
    final wrongTiles = <int>[];
    for (var i = 0; i < pool.length; i++) {
      final t = pool[i];
      if (!correctChars.contains(t.letter) && !t.eliminated && !t.used) wrongTiles.add(i);
    }
    if (wrongTiles.isEmpty) return; // rien à éliminer : le joker n'est pas consommé
    markActivity(); // un joueur qui ne joue que via jokers reste actif
    wrongTiles.shuffle(_rng);
    for (final i in wrongTiles.take(3)) {
      pool[i].eliminated = true;
    }
    eliminateCount--;
    notifyListeners();
  }

  /// Retourne le texte de l'indice si utilisable, sinon null.
  String? useHintJoker() {
    if (hintCount <= 0 || hintRevealed) return null;
    markActivity(); // un joueur qui ne joue que via jokers reste actif
    hintCount--;
    hintRevealed = true;
    final hint = currentPuzzle.extraHintFor(locale);
    revealedHintText = hint.isNotEmpty
        ? hint
        : (locale == 'en' ? 'No extra hint available for this puzzle.' : 'Pas de complément disponible pour cette devinette.');
    notifyListeners();
    return revealedHintText;
  }

  /// Révèle un mot entier de la réponse (jusqu'à 40% du nombre total de
  /// lettres à trouver, mot verrouillé comme s'il avait été validé). Si la
  /// réponse ne compte qu'un seul mot, révèle environ un tiers de ses
  /// lettres au hasard à la place (sans le verrouiller).
  void useRevealWordJoker() {
    if (revealWordCount <= 0) return;
    final totalLetters = slots.where((s) => !s.isSpace && !s.isAuto).length;
    if (totalLetters == 0 || wordRanges.isEmpty) return;

    if (wordRanges.length == 1) {
      // Éligible même si déjà rempli par le joueur (juste ou faux) : la
      // lettre du joueur doit être remplacée, pas seulement les cases vides.
      final revealable = wordRanges[0].where((i) => !slots[i].isAuto && !lockedSlots.contains(i)).toList();
      if (revealable.isEmpty) return;
      revealable.shuffle(_rng);
      final howMany = max(1, (revealable.length / 3).ceil());
      var uneLettreRevelee = false;
      for (final i in revealable.take(howMany)) {
        final correctChar = slots[i].char;
        if (guess[i] != null && pool[guess[i]!].letter == correctChar) {
          lockedSlots.add(i); // déjà la bonne lettre : rien à remplacer
          uneLettreRevelee = true;
          continue;
        }
        final tileIdx = pool.indexWhere((t) => t.letter == correctChar && !t.used && !t.eliminated);
        // Aucune tuile de rechange dispo (ex: le joueur a déjà placé toutes
        // les copies de cette lettre ailleurs) : on laisse la case telle
        // quelle plutôt que de libérer sa tuile actuelle sans remplaçante,
        // ce qui la ferait apparaître deux fois à la fois (case + pool).
        if (tileIdx == -1) continue;
        if (guess[i] != null) pool[guess[i]!].used = false; // libère seulement maintenant qu'un remplacement existe
        guess[i] = tileIdx;
        pool[tileIdx].used = true;
        lockedSlots.add(i);
        uneLettreRevelee = true;
      }
      if (uneLettreRevelee) {
        markActivity(); // un joueur qui ne joue que via jokers reste actif
        revealWordCount--;
      }
      notifyListeners();
      return;
    }

    final eligible = <int>[];
    for (var w = 0; w < wordRanges.length; w++) {
      if (lockedWords.contains(w)) continue;
      if (wordRanges[w].length <= totalLetters * 0.4) eligible.add(w);
    }
    int targetWord;
    if (eligible.isNotEmpty) {
      targetWord = eligible[_rng.nextInt(eligible.length)];
    } else {
      final unlocked = [for (var w = 0; w < wordRanges.length; w++) if (!lockedWords.contains(w)) w];
      if (unlocked.isEmpty) return;
      unlocked.sort((a, b) => wordRanges[a].length.compareTo(wordRanges[b].length));
      targetWord = unlocked.first;
    }

    var motEntierementRevele = true;
    for (final i in wordRanges[targetWord]) {
      if (slots[i].isAuto || lockedSlots.contains(i)) continue;
      final correctChar = slots[i].char;
      if (guess[i] != null && pool[guess[i]!].letter == correctChar) continue; // déjà la bonne lettre
      final tileIdx = pool.indexWhere((t) => t.letter == correctChar && !t.used && !t.eliminated);
      // Aucune tuile de rechange dispo (ex: le joueur a déjà placé toutes les
      // copies de cette lettre ailleurs) : on laisse la case telle quelle —
      // sans quoi on libérerait sa tuile actuelle sans remplaçante (case
      // vide + tuile pourtant affichée deux fois) — et on ne verrouille pas
      // un mot dont une case resterait vide à jamais.
      if (tileIdx == -1) {
        motEntierementRevele = false;
        continue;
      }
      if (guess[i] != null) pool[guess[i]!].used = false; // libère seulement maintenant qu'un remplacement existe
      guess[i] = tileIdx;
      pool[tileIdx].used = true;
      pool[tileIdx].consumed = true;
    }
    if (motEntierementRevele) {
      markActivity(); // un joueur qui ne joue que via jokers reste actif
      lockedWords.add(targetWord);
      revealWordCount--;
    }
    notifyListeners();
  }

  // ─── Paliers de récompense ───
  String grantMinorJoker() {
    final rotation = ['Révéler', 'Éliminer', 'Personnage'];
    final label = rotation[minorMilestoneCount % 3];
    switch (label) {
      case 'Révéler': revealCount++; break;
      case 'Éliminer': eliminateCount++; break;
      case 'Personnage': characterCount++; break;
    }
    minorMilestoneCount++;
    return label;
  }

  String grantMajorJoker() {
    final rotation = ['Acteur', 'Indice', 'Révéler un mot'];
    final label = rotation[majorMilestoneCount % 3];
    switch (label) {
      case 'Acteur': actorCount++; break;
      case 'Indice': hintCount++; break;
      case 'Révéler un mot': revealWordCount++; break;
    }
    majorMilestoneCount++;
    return label;
  }

  /// Récompense "jour 1" de L'énigme de la semaine : un joker de chacun des
  /// six types (au lieu d'une rotation), sans faire progresser les compteurs
  /// de paliers de la campagne principale.
  void grantOneOfEachJokerType() {
    revealCount++;
    eliminateCount++;
    characterCount++;
    actorCount++;
    hintCount++;
    revealWordCount++;
    notifyListeners();
  }

  /// 80% de chances de gagner un joker mineur, 20% un joker majeur pour la
  /// 1ère pub à récompense regardée sur ce niveau — 60%/40% à partir de la
  /// 2e (voir [adsWatchedThisLevel], remis à zéro à chaque nouveau niveau).
  String grantWeightedRandomJoker() {
    final minorChance = adsWatchedThisLevel == 0 ? 0.8 : 0.6;
    adsWatchedThisLevel++;
    final isMinor = _rng.nextDouble() < minorChance;
    String label;
    if (isMinor) {
      final pick = _rng.nextInt(3);
      if (pick == 0) { revealCount++; label = 'Révéler'; }
      else if (pick == 1) { eliminateCount++; label = 'Éliminer'; }
      else { characterCount++; label = 'Personnage'; }
    } else {
      final pick = _rng.nextInt(3);
      if (pick == 0) { actorCount++; label = 'Acteur'; }
      else if (pick == 1) { hintCount++; label = 'Indice'; }
      else { revealWordCount++; label = 'Révéler un mot'; }
    }
    notifyListeners();
    return label;
  }

  /// true si le bouton "regarder une pub pour un joker rouge" doit être
  /// proposé : le niveau a un nom orange, le joueur n'a aucun joker rouge en
  /// stock, et n'a pas déjà utilisé cette pub garantie sur ce niveau (limite
  /// d'une fois par niveau concerné — les autres façons d'en obtenir sont le
  /// top 10% mondial de L'énigme de la semaine et la boutique).
  bool get peutRegarderPubJokerRouge =>
      currentPuzzleHasOrange && redJokerCount <= 0 && !redJokerAdWatchedThisLevel;

  /// Pub garantie (100% de chances) pour 1 joker rouge — jamais aléatoire,
  /// contrairement à [grantWeightedRandomJoker].
  void grantRedJokerFromAd() {
    if (!peutRegarderPubJokerRouge) return;
    redJokerCount++;
    redJokerAdWatchedThisLevel = true;
    notifyListeners();
  }

  // ─── Progression entre niveaux ───
  /// true si une pub forcée doit être montrée avant le niveau suivant.
  ///
  /// La fréquence s'assouplit pour les nouveaux joueurs, le temps qu'ils
  /// découvrent le jeu, puis revient progressivement à la normale :
  ///  - 1er monde joué : aucune pub forcée (seules les pubs volontaires
  ///    restent proposées).
  ///  - 2e à 4e monde joué : pubs après les niveaux 5 et 10 seulement, jamais
  ///    pour un niveau qui a pris plus de 60s.
  ///  - 5e à 7e monde joué : pubs après les niveaux 3, 6 et 10, plus la
  ///    règle des 60s.
  ///  - 8e monde joué et au-delà : comportement standard (3, 5, 8, 10 + 60s).
  bool get mustShowForcedAd {
    if (inTutorial) return false;
    final tookTooLong = lastSolveDuration.inSeconds > 60;
    final n = worldsPlayedCount;
    if (n <= 1) {
      return false;
    } else if (n <= 4) {
      return currentLevelNumber == 5 || currentLevelNumber == 10;
    } else if (n <= 7) {
      const adAfterPositions = {3, 6, 10};
      return adAfterPositions.contains(currentLevelNumber) || tookTooLong;
    } else {
      const adAfterPositions = {3, 5, 8, 10};
      return adAfterPositions.contains(currentLevelNumber) || tookTooLong;
    }
  }

  /// Avance après une résolution réussie. Retourne un statut :
  /// "next-level", "world-choice:<worldNumber>:<majorLabel>:<minorLabel>",
  /// "all-content-complete:<worldNumber>:<majorLabel>:<minorLabel>",
  /// "tutorial-final-transition", "tutorial-complete".
  String advanceAfterSolve() {
    final solvedLevel = currentLevelNumber;
    final wasTutorial = inTutorial;
    final completedWorldNumber = worldIndex;

    if (!wasTutorial && solvedLevel == 5) pendingMinorJokerLabel = grantMinorJoker();

    // Filet de sécurité : si le joueur revient sur le tout dernier niveau
    // déjà résolu lors d'une session précédente (remainingLevels déjà vidée,
    // mais currentLevelNumber inchangé puisque rien ne le fait avancer une
    // fois le contenu épuisé — voir loadPuzzle()), removeAt(0) planterait.
    if (remainingLevels.isNotEmpty) remainingLevels.removeAt(0);

    // Le tutoriel compte désormais 4 niveaux (voir kTutorialPuzzles) : après
    // le niveau 0-3, transition vers le dernier niveau (0-4), sans indice ni
    // aide, pour tester ce que le joueur a retenu.
    if (wasTutorial && solvedLevel == 3 && remainingLevels.isNotEmpty) {
      currentLevelNumber = remainingLevels.first; // prêt pour le niveau 0-4
      return 'tutorial-final-transition';
    }
    if (wasTutorial && remainingLevels.isEmpty) {
      return 'tutorial-complete';
    }
    if (remainingLevels.isEmpty) {
      String majorLabel = '';
      String minorLabel = '';
      if (!wasTutorial) {
        majorLabel = grantMajorJoker();
        minorLabel = grantMinorJoker();
      }
      if (worldChoiceOptions.isEmpty) {
        allWorldsCompleted = true;
        _allWorldsCompletedAtMax = _maxWorldNumber;
        // Aucun appel ultérieur (loadPuzzle(), enterWorld()...) ne suivra ce
        // statut côté écran — contrairement aux autres branches, c'est donc
        // ICI qu'il faut déclencher la sauvegarde, sans quoi ce indicateur ne
        // survivrait jamais à un redémarrage de l'app.
        notifyListeners();
        analytics.logAllContentCompleted(worldCount: _allWorldsCompletedAtMax);
        return 'all-content-complete:$completedWorldNumber:$majorLabel:$minorLabel';
      }
      return 'world-choice:$completedWorldNumber:$majorLabel:$minorLabel';
    }
    currentLevelNumber = remainingLevels.first;
    return 'next-level';
  }

  /// Le joueur choisit de laisser ce niveau de côté ; il repasse en fin de file.
  void skipCurrentLevel() {
    remainingLevels.add(remainingLevels.removeAt(0));
    currentLevelNumber = remainingLevels.first;
    loadPuzzle();
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    super.dispose();
  }
}
