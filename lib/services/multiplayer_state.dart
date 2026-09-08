import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../data/multiplayer_data.dart';
import '../models/multiplayer.dart';
import '../models/puzzle.dart';
import 'analytics_service.dart';
import 'app_settings.dart';
import 'elo_service.dart';
import 'game_state.dart' show normalize;
import 'multiplayer_matchmaking_service.dart';
import 'save_service.dart';
import 'streak_state.dart';

const int kMultiplayerDecoyCount = 8;
// Seuil PAR ÉNIGME (pas un total global) : tant qu'une énigme précise n'a
// pas encore ce nombre de vraies parties enregistrées, tout joueur qui la
// pioche (nouveau ou non) affronte un temps fantôme fixe plutôt qu'une
// recherche Firestore sur un échantillon trop maigre pour être fiable.
const int kMultiplayerCalibrationMinRuns = 10;
const int kMultiplayerMatchesBaseParJour = 5;
const int kMultiplayerAdsMaxParJour = 5; // 1 pub = 1 partie bonus, jusqu'à 5/jour
const int kMultiplayerHistoriqueMax = 10;
const int kMultiplayerPitchRevealMs = 35000; // toutes les lettres visibles pile à 35s

// Durée d'une manche : 45s de base + 1s par caractère (hors espaces) de la
// réponse, plafonnée à 1m15 — une réponse plus longue laisse mécaniquement
// plus de temps pour placer les lettres, sans jamais dépasser ce maximum.
const int kMultiplayerRoundBaseSeconds = 45;
const int kMultiplayerRoundMaxSeconds = 75;

/// État du mode Multijoueur : match au meilleur des 3 manches (45 à 75s selon
/// la longueur de la réponse — voir [kMultiplayerRoundBaseSeconds]) contre
/// des parties fantômes (jamais en temps réel — voir
/// docs/multijoueur-elo-spec.md). Un fantôme différent est piochée
/// indépendamment à chaque manche, à un Elo proche du joueur. Toute manche
/// dont l'énigme piochée n'a pas encore [kMultiplayerCalibrationMinRuns]
/// vraies parties enregistrées (pour CETTE énigme précisément, quel que
/// soit le joueur) utilise un temps fantôme fixe, égal au temps max de cette
/// manche moins 5s, présenté comme un adversaire normal — pas une notion de
/// "nouveau joueur".
class MultiplayerState extends ChangeNotifier {
  final SaveService saveService;
  final MultiplayerMatchmakingService matchmaking;
  final AnalyticsService analytics;
  final AppSettings settings;
  // Optionnel, câblé depuis main.dart seulement (voir DefiState.streakState).
  StreakState? streakState;
  final Random _rng = Random();
  MultiplayerState(
      {required this.saveService, required this.matchmaking, required this.settings, AnalyticsService? analytics})
      : analytics = analytics ?? AnalyticsService();

  // Langue figée au chargement de la manche (voir _startRound()), comme pour
  // GameState — un changement de langue en cours de manche ne doit pas
  // changer la longueur du pitch ni de la réponse en cours de résolution.
  String locale = 'fr';

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
    await saveService.saveMultiplayer(toJson());
  }

  // ─── Classement persisté ───
  int eloRating = kEloDepart;
  int matchesPlayed = 0;

  String get titreActuel => titreForElo(eloRating, settings.locale);

  // ─── Limite quotidienne de parties, et pubs pour en gagner davantage —
  // même principe que L'énigme de la semaine (voir
  // EnigmeState.attemptsUsedToday/adsWatchedForAttemptsToday), journées
  // comptées en GMT. ───
  int matchesUsedToday = 0;
  DateTime? lastMatchDay;
  int adsWatchedForMatchesToday = 0;
  DateTime? lastMatchAdDay;

  int get matchesRestantes => (kMultiplayerMatchesBaseParJour + adsWatchedForMatchesToday - matchesUsedToday)
      .clamp(0, kMultiplayerMatchesBaseParJour + kMultiplayerAdsMaxParJour);

  bool get peutRegarderPubMatch => adsWatchedForMatchesToday < kMultiplayerAdsMaxParJour;

  /// À appeler à l'ouverture de l'écran : remet les compteurs quotidiens à
  /// zéro si on a changé de jour (GMT) depuis la dernière partie/pub.
  void ensureFreshDay() {
    _rolloverJourSiNecessaire(DateTime.now());
  }

  /// Réaffiche l'écran d'accueil (Elo/rang/historique) sans toucher au
  /// classement ni à l'historique — à appeler à chaque ouverture fraîche de
  /// l'écran, sinon un joueur qui quitte juste après un match (bouton retour
  /// matériel, "RETOUR À L'ACCUEIL"...) retomberait indéfiniment sur l'écran
  /// de résultat du dernier match au lieu de l'accueil.
  void returnToIntro() {
    if (!matchActive && !matchOver) return;
    matchActive = false;
    matchOver = false;
    notifyListeners();
  }

  void _rolloverJourSiNecessaire(DateTime now) {
    final today = _utcDate(now);
    var changed = false;
    if (lastMatchDay == null || !_sameDay(lastMatchDay!, today)) {
      if (matchesUsedToday != 0) changed = true;
      matchesUsedToday = 0;
    }
    if (lastMatchAdDay == null || !_sameDay(lastMatchAdDay!, today)) {
      if (adsWatchedForMatchesToday != 0) changed = true;
      adsWatchedForMatchesToday = 0;
    }
    if (changed) notifyListeners();
  }

  DateTime _utcDate(DateTime now) {
    final u = now.toUtc();
    return DateTime.utc(u.year, u.month, u.day);
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  /// Pub "+1 partie" : donne une partie supplémentaire pour aujourd'hui.
  void onAdMatchRewarded() {
    // Le rollover doit précéder la vérification du quota (comme dans
    // startMatch()) — sinon un compteur d'hier resté au max bloquerait à
    // tort la récompense d'aujourd'hui tant que l'écran n'a pas été rouvert.
    final now = DateTime.now();
    _rolloverJourSiNecessaire(now);
    if (!peutRegarderPubMatch) return;
    adsWatchedForMatchesToday++;
    lastMatchAdDay = _utcDate(now);
    notifyListeners();
  }

  // ─── Historique local des matchs (les kMultiplayerHistoriqueMax derniers,
  // le plus récent en premier) — juste le résultat et l'évolution du
  // classement Elo. ───
  List<MultiplayerMatchHistoryEntry> historique = [];

  // ─── Ids des énigmes hors calibration déjà piochées depuis le début du
  // cycle courant — jamais remis à zéro sauf quand le pool entier a été
  // couvert (voir _piocherEnigme). Persisté pour tenir sur plusieurs
  // sessions, pas seulement au sein d'un match. ───
  Set<String> historiquePioche = {};

  // ─── Pourcentage mondial ("top X %"), non persisté — recalculé à chaque
  // ouverture de l'écran et après chaque match. `null` tant qu'il n'y a pas
  // assez de joueurs enregistrés pour que le chiffre soit significatif. ───
  double? topPercent;
  bool _topPercentLoading = false;

  Future<void> refreshTopPercent() async {
    if (_topPercentLoading) return;
    _topPercentLoading = true;
    final result = await matchmaking.fetchTopPercent(elo: eloRating);
    topPercent = result;
    _topPercentLoading = false;
    notifyListeners();
  }

  // ─── État du match en cours (non persisté, comme le reste du jeu) ───
  bool matchActive = false;
  bool matchOver = false;
  String? matchResult; // 'victoire' | 'defaite' | 'nul'
  int? eloAvantMatch;
  int? eloApresMatch;
  int playerScore = 0;
  int ghostScore = 0;
  int roundIndex = 0; // 0-based
  bool anyCalibrationRoundThisMatch = false;

  final List<String> _enigmesJoueesCeMatch = [];
  final List<double> _ghostElosThisMatch = [];

  /// Elo de l'adversaire pour la manche en cours (dernier ajouté à
  /// [_ghostElosThisMatch]) — utilisé par la barre de comparaison Elo de
  /// l'écran de jeu. `null` avant que la 1ère manche n'ait démarré.
  double? get eloAdversaireActuel => _ghostElosThisMatch.isEmpty ? null : _ghostElosThisMatch.last;

  MultiplayerEnigme? currentEnigme;
  double? ghostSolveSeconds; // null = le fantôme ne trouve pas dans le temps imparti
  // Durée max de la manche en cours — voir kMultiplayerRoundBaseSeconds ;
  // recalculée à chaque _startRound() selon la longueur de la réponse.
  double roundMaxSeconds = kMultiplayerRoundBaseSeconds.toDouble();
  DateTime? roundStartTime;
  bool roundResolved = false;
  String? roundWinner; // 'joueur' | 'fantome' | 'egalite'
  // true seulement une fois les 2s de surbrillance de la réponse (sur la
  // grille de tuiles) écoulées — bascule alors l'affichage vers l'écran de
  // résultat de la manche (_RoundResultView), lui-même affiché 2s.
  bool showRoundResult = false;
  String? nomAdversaireActuel;
  String? _monNom; // nom du joueur affiché aux futurs adversaires (voir recordRun)

  // ─── Grille de tuiles (comme les autres modes, sans jokers) ───
  List<AnswerSlot> slots = [];
  List<int?> guess = [];
  List<LetterTile> pool = [];
  int cursorIndex = -1;

  /// Démarre un nouveau match — à appeler à l'ouverture de l'écran ou pour
  /// rejouer. Refuse silencieusement si le quota quotidien est épuisé (le
  /// bouton correspondant est de toute façon désactivé côté écran).
  Future<void> startMatch({String? playerName}) async {
    // Un match est déjà en cours (ou en cours de lancement — cette méthode
    // attend un appel réseau avant même de démarrer la 1ère manche) : un
    // double-tap sur "Affronter un joueur" ne doit jamais lancer un second
    // match en parallèle, qui corromprait tout l'état partagé de la manche.
    if (matchActive) return;
    final now = DateTime.now();
    _rolloverJourSiNecessaire(now);
    if (matchesRestantes <= 0) return;
    matchesUsedToday++;
    lastMatchDay = _utcDate(now);
    _monNom = playerName;

    matchActive = true;
    matchOver = false;
    matchResult = null;
    playerScore = 0;
    ghostScore = 0;
    roundIndex = 0;
    anyCalibrationRoundThisMatch = false;
    _enigmesJoueesCeMatch.clear();
    _ghostElosThisMatch.clear();
    eloAvantMatch = eloRating;
    eloApresMatch = null;

    await _startRound();
  }

  Future<void> _startRound() async {
    locale = settings.locale;
    roundResolved = false;
    roundWinner = null;
    showRoundResult = false;
    // Remis à null tant que la manche n'est pas complètement prête : le
    // nombre de vraies parties de cette énigme, puis éventuellement le
    // fantôme lui-même, sont recherchés via des appels réseau asynchrones
    // (voir plus bas) — sans ce null, tick() pourrait s'exécuter pendant ce
    // court intervalle avec l'horodatage/le temps fantôme de la manche
    // PRÉCÉDENTE encore en mémoire (roundResolved venant d'être libéré juste
    // au-dessus), et résoudre la nouvelle manche instantanément en faveur du
    // fantôme.
    roundStartTime = null;

    final enigme = _piocherEnigme();
    currentEnigme = enigme;
    _enigmesJoueesCeMatch.add(enigme.id);

    final answerLen = normalize(enigme.reponseFor(locale)).replaceAll(' ', '').length;
    roundMaxSeconds = (kMultiplayerRoundBaseSeconds + answerLen).clamp(kMultiplayerRoundBaseSeconds, kMultiplayerRoundMaxSeconds).toDouble();
    final calibrationFallbackSeconds = roundMaxSeconds - 5;

    final runsCount = await matchmaking.countRunsForEnigme(enigme.id);
    if (runsCount < kMultiplayerCalibrationMinRuns) {
      anyCalibrationRoundThisMatch = true;
      ghostSolveSeconds = calibrationFallbackSeconds;
      // Pas assez de vraies parties pour cette énigme précise pour un
      // matching Elo fiable : pas de vrai Elo associé non plus, on présume
      // un niveau égal au joueur (voir docs/multijoueur-elo-spec.md).
      // Présenté sous un nom fixe plutôt que de laisser deviner qu'il
      // s'agit d'un robot.
      _ghostElosThisMatch.add(eloRating.toDouble());
      nomAdversaireActuel = 'Néophilis';
    } else {
      final ghost = await matchmaking.fetchGhost(enigmeId: enigme.id, elo: eloRating, locale: locale);
      if (ghost != null) {
        ghostSolveSeconds = ghost.solveSeconds;
        _ghostElosThisMatch.add(ghost.eloAtTimeOfPlay);
        nomAdversaireActuel = ghost.nomJoueur;
      } else {
        // Filet de sécurité résiduel : le compte est au-dessus du seuil
        // mais fetchGhost n'a rien trouvé même en élargissant beaucoup la
        // fourchette Elo (cas extrêmement rare) — même temps de secours
        // plutôt que de bloquer le joueur.
        anyCalibrationRoundThisMatch = true;
        ghostSolveSeconds = calibrationFallbackSeconds;
        _ghostElosThisMatch.add(eloRating.toDouble());
        nomAdversaireActuel = locale == 'en' ? 'Anonymous player' : 'Joueur anonyme';
      }
    }

    _rebuildTiles();
    roundStartTime = DateTime.now();
    notifyListeners();
  }

  /// Pioche une énigme au hasard, sans jamais répéter une énigme déjà
  /// tombée avant que TOUTES les autres n'aient été jouées au moins une
  /// fois (par ce joueur, tous matchs confondus — voir [historiquePioche]).
  /// Une fois le pool entier épuisé, un nouveau cycle recommence.
  MultiplayerEnigme _piocherEnigme() {
    var candidats = kMultiplayerEnigmes
        .where((e) => !historiquePioche.contains(e.id) && !_enigmesJoueesCeMatch.contains(e.id))
        .toList();
    if (candidats.isEmpty) {
      // Cycle complet : tout le pool a déjà été joué au moins une fois — on
      // repart pour un nouveau cycle, tout en respectant encore la règle
      // "jamais deux fois la même énigme au sein d'un même match".
      historiquePioche.clear();
      candidats = kMultiplayerEnigmes.where((e) => !_enigmesJoueesCeMatch.contains(e.id)).toList();
    }
    if (candidats.isEmpty) {
      // Cas limite : un match a duré plus longtemps que tout le pool
      // (contenu très réduit) — autorise la répétition au sein du match.
      candidats = kMultiplayerEnigmes;
    }
    final choisie = candidats[_rng.nextInt(candidats.length)];
    historiquePioche.add(choisie.id);
    return choisie;
  }

  void _rebuildTiles() {
    final sujetClean = normalize(currentEnigme!.reponseFor(locale));
    slots = sujetClean.split('').map(AnswerSlot.fromChar).toList();
    guess = List<int?>.filled(slots.length, null);
    cursorIndex = _firstEmptySlotFrom(0);

    final correctLetters = <String>[];
    for (final s in slots) {
      if (s.isSpace || s.isAuto) continue;
      correctLetters.add(s.char);
    }
    final used = correctLetters.toSet();
    // Les lettres-leurres sont choisies au hasard, mais la position finale
    // des tuiles dans le pool est triée par ordre alphabétique (pas
    // mélangée) pour que le joueur les retrouve plus vite.
    final alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('').where((l) => !used.contains(l)).toList()..shuffle(_rng);
    final tiles = [...correctLetters, ...alphabet.take(kMultiplayerDecoyCount)];
    tiles.sort();
    pool = tiles.map((l) => LetterTile(letter: l)).toList();
  }

  int _firstEmptySlotFrom(int start) {
    final n = slots.length;
    if (n == 0) return -1;
    for (var step = 0; step < n; step++) {
      final i = (start + step) % n;
      if (!slots[i].isSpace && !slots[i].isAuto && guess[i] == null) return i;
    }
    return -1;
  }

  static final _alnum = RegExp(r'[A-Za-z0-9]');

  // Ordre (mélangé) des positions de caractères alphanumériques du pitch à
  // révéler — même principe que L'énigme de la semaine (voir
  // EnigmeState._ordreRevelation) : figé par énigme via un seed déterministe
  // basé sur son numéro d'identifiant (jamais sur hashCode, non garanti
  // stable). Empêche le joueur de deviner la longueur des mots avant d'avoir
  // vraiment révélé leurs lettres.
  List<int> _pitchOrdreRevelationCache = [];
  String? _pitchOrdreRevelationPourId;

  List<int> get _pitchOrdreRevelation {
    final enigme = currentEnigme;
    if (enigme == null) return const [];
    if (_pitchOrdreRevelationPourId != enigme.id) {
      final positions = <int>[];
      final chars = enigme.pitchFor(locale).split('');
      for (var i = 0; i < chars.length; i++) {
        if (_alnum.hasMatch(chars[i])) positions.add(i);
      }
      final numero = int.tryParse(enigme.id.split('-').last) ?? enigme.id.length;
      positions.shuffle(Random(numero * 7919 + 11));
      _pitchOrdreRevelationCache = positions;
      _pitchOrdreRevelationPourId = enigme.id;
    }
    return _pitchOrdreRevelationCache;
  }

  int? _dernierePositionAlnumAvant(List<String> chars, int from) {
    for (var i = from - 1; i >= 0; i--) {
      if (_alnum.hasMatch(chars[i])) return i;
    }
    return null;
  }

  /// Le pitch tel qu'il doit être affiché à l'instant présent : les lettres
  /// se révèlent dans un ordre mélangé (pas de gauche à droite — pour ne pas
  /// laisser deviner la longueur des mots avant l'heure), toutes visibles
  /// pile à 35 secondes quelle que soit la longueur du pitch. La ponctuation
  /// apparaît automatiquement avec la lettre qui la précède immédiatement.
  String get pitchRevele {
    final enigme = currentEnigme;
    if (enigme == null) return '';
    final pitchLoc = enigme.pitchFor(locale);
    final chars = pitchLoc.split('');
    final ordre = _pitchOrdreRevelation;
    final totalAlnum = ordre.length;
    if (totalAlnum == 0) return pitchLoc;
    final revealMsParChar = kMultiplayerPitchRevealMs / totalAlnum;
    final unitesRevelees = (tempsEcoule.inMilliseconds / revealMsParChar).floor().clamp(0, totalAlnum);
    final revealedPositions = ordre.take(unitesRevelees).toSet();

    final buffer = StringBuffer();
    for (var i = 0; i < chars.length; i++) {
      final c = chars[i];
      if (c == ' ') {
        buffer.write(' ');
        continue;
      }
      if (_alnum.hasMatch(c)) {
        buffer.write(revealedPositions.contains(i) ? c : ' ');
      } else {
        final prev = _dernierePositionAlnumAvant(chars, i);
        final precedenteRevelee = prev != null && revealedPositions.contains(prev);
        buffer.write(precedenteRevelee ? c : ' ');
      }
    }
    return buffer.toString();
  }

  // ─── Minuteur : à appeler régulièrement (ex. toutes les 200ms) depuis
  // l'écran. Résout automatiquement la manche si le fantôme "trouve" avant
  // le joueur, ou si roundMaxSeconds s'écoule sans que personne ne trouve. ───
  void tick() {
    if (!matchActive || roundResolved || roundStartTime == null) return;
    final elapsed = DateTime.now().difference(roundStartTime!).inMilliseconds / 1000;
    final tempsAdversaire = ghostSolveSeconds;
    if (tempsAdversaire != null && tempsAdversaire < roundMaxSeconds && elapsed >= tempsAdversaire) {
      _resolveRound('fantome');
      return;
    }
    if (elapsed >= roundMaxSeconds) {
      _resolveRound(tempsAdversaire == null ? 'egalite' : 'fantome');
      return;
    }
    notifyListeners();
  }

  Duration get tempsEcoule =>
      roundStartTime == null ? Duration.zero : DateTime.now().difference(roundStartTime!);

  void onBlankTap(int i) {
    // roundStartTime == null pendant le court intervalle où _startRound()
    // recherche un adversaire de façon asynchrone (hors calibration) —
    // toucher la grille à ce moment-là agirait sur l'état encore obsolète de
    // la manche précédente (voir onLetterTap ci-dessous pour le cas qui
    // provoquait un crash).
    if (roundResolved || roundStartTime == null) return;
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
    notifyListeners();
  }

  void onLetterTap(LetterTile tile) {
    // roundStartTime == null pendant la recherche asynchrone d'adversaire
    // (hors calibration, voir _startRound()) : sans ce garde-fou, un tap
    // pile à ce moment-là pouvait déclencher `roundStartTime!` plus bas
    // alors qu'il est encore null — crash immédiat de l'app.
    if (roundResolved || tile.used || roundStartTime == null) return;
    final idx = pool.indexOf(tile);
    var target = cursorIndex;
    if (target == -1 || slots[target].isSpace || guess[target] != null) {
      target = _firstEmptySlotFrom(0);
    }
    if (target == -1) return;
    guess[target] = idx;
    tile.used = true;
    cursorIndex = _firstEmptySlotFrom(target + 1);

    final allFilled =
        List.generate(slots.length, (i) => slots[i].isSpace || slots[i].isAuto || guess[i] != null).every((v) => v);
    if (allFilled) {
      final attempt = List.generate(slots.length, (i) {
        final s = slots[i];
        if (s.isSpace) return ' ';
        if (s.isAuto) return s.char;
        return pool[guess[i]!].letter;
      }).join();
      final correct = slots.map((s) => s.char).join();
      if (attempt == correct) {
        final elapsed = DateTime.now().difference(roundStartTime!).inMilliseconds / 1000;
        _resolveRound('joueur', playerSolveSeconds: elapsed);
        return;
      }
      for (var i = 0; i < slots.length; i++) {
        final t = guess[i];
        if (t != null) pool[t].used = false;
        guess[i] = null;
      }
      cursorIndex = _firstEmptySlotFrom(0);
    }
    notifyListeners();
  }

  void _resolveRound(String winner, {double? playerSolveSeconds}) {
    if (roundResolved) return;
    roundResolved = true;
    roundWinner = winner;
    if (winner == 'joueur' || winner == 'egalite') playerScore++;
    if (winner == 'fantome' || winner == 'egalite') ghostScore++;

    final valide = playerSolveSeconds != null && playerSolveSeconds < roundMaxSeconds ? playerSolveSeconds : null;
    matchmaking.recordRun(
      enigmeId: currentEnigme!.id,
      elo: eloRating,
      solveSeconds: valide,
      nomJoueur: _monNom ?? (locale == 'en' ? 'Cinephile' : 'Cinéphile'),
    );

    notifyListeners();
    // Déroulé en deux temps de 2s chacun, jamais un saut direct : d'abord la
    // grille de tuiles reste affichée avec le mot complet surligné (vert si
    // le joueur a gagné la manche, rouge sinon), puis on bascule sur l'écran
    // de résultat de la manche — y compris pour la manche qui décide du
    // match, qui ne doit jamais sauter directement à l'écran de résultat
    // final sans montrer la réponse.
    Timer(const Duration(seconds: 2), () {
      showRoundResult = true;
      notifyListeners();
      Timer(const Duration(seconds: 2), () {
        if (playerScore >= 2 || ghostScore >= 2) {
          _finishMatch();
        } else {
          roundIndex++;
          _startRound();
        }
      });
    });
  }

  void _finishMatch() {
    matchOver = true;
    matchActive = false;
    matchesPlayed++;

    if (playerScore > ghostScore) {
      matchResult = 'victoire';
    } else if (playerScore < ghostScore) {
      matchResult = 'defaite';
    } else {
      matchResult = 'nul';
    }
    final scoreReel = matchResult == 'victoire' ? 1.0 : (matchResult == 'nul' ? 0.5 : 0.0);
    final eloAdversaireMoyen = _ghostElosThisMatch.reduce((a, b) => a + b) / _ghostElosThisMatch.length;
    final k = kFactorFor(isCalibration: anyCalibrationRoundThisMatch, elo: eloRating);
    final eloAvant = eloRating;
    eloRating = nouvelElo(eloJoueur: eloRating, eloAdversaireMoyen: eloAdversaireMoyen, scoreReel: scoreReel, kFactor: k);
    eloApresMatch = eloRating;

    historique.insert(
      0,
      MultiplayerMatchHistoryEntry(
        resultat: matchResult!,
        eloAvant: eloAvant,
        eloApres: eloRating,
        date: DateTime.now(),
      ),
    );
    if (historique.length > kMultiplayerHistoriqueMax) {
      historique.removeRange(kMultiplayerHistoriqueMax, historique.length);
    }

    matchmaking.updatePlayerElo(elo: eloRating);
    refreshTopPercent();
    analytics.logMultiplayerMatchResult(result: matchResult!, eloApres: eloRating);
    streakState?.recordAction();
    notifyListeners();
  }

  // ─── Persistance (uniquement le classement — la partie en cours n'est pas
  // conservée, comme pour le reste du jeu) ───

  Map<String, dynamic> toJson() => {
        'eloRating': eloRating,
        'matchesPlayed': matchesPlayed,
        'matchesUsedToday': matchesUsedToday,
        'lastMatchDay': lastMatchDay?.toIso8601String(),
        'adsWatchedForMatchesToday': adsWatchedForMatchesToday,
        'lastMatchAdDay': lastMatchAdDay?.toIso8601String(),
        'historique': historique.map((e) => e.toJson()).toList(),
        'historiquePioche': historiquePioche.toList(),
      };

  Future<void> restore() async {
    final data = await saveService.loadMultiplayer();
    if (data == null) return;
    _restoring = true;
    eloRating = data['eloRating'] as int? ?? kEloDepart;
    matchesPlayed = data['matchesPlayed'] as int? ?? 0;
    matchesUsedToday = data['matchesUsedToday'] as int? ?? 0;
    final lmd = data['lastMatchDay'] as String?;
    lastMatchDay = lmd != null ? DateTime.tryParse(lmd) : null;
    adsWatchedForMatchesToday = data['adsWatchedForMatchesToday'] as int? ?? 0;
    final lmad = data['lastMatchAdDay'] as String?;
    lastMatchAdDay = lmad != null ? DateTime.tryParse(lmad) : null;
    final hist = data['historique'] as List?;
    if (hist != null) {
      // Une seule entrée mal formée (schéma obsolète, écriture partielle) ne
      // doit jamais faire planter tout le restore() — appelé depuis main()
      // avant runApp(), sans aucun recours pour le joueur — donc sans
      // recours à part vider les données de l'app. On ignore juste l'entrée
      // fautive plutôt que toute la liste.
      final entriesValides = <MultiplayerMatchHistoryEntry>[];
      for (final e in hist) {
        try {
          entriesValides.add(MultiplayerMatchHistoryEntry.fromJson(e as Map<String, dynamic>));
        } catch (_) {
          continue;
        }
      }
      historique = entriesValides;
    }
    final histPioche = data['historiquePioche'] as List?;
    if (histPioche != null) {
      historiquePioche = histPioche.cast<String>().toSet();
    }
    _restoring = false;
  }
}
