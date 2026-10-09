import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../data/enigmes_data.dart';
import '../models/enigme.dart';
import '../models/puzzle.dart';
import 'analytics_service.dart';
import 'app_settings.dart';
import 'enigme_service.dart';
import 'game_state.dart' show normalize;
import 'leaderboard_service.dart' show weekIdFor;
import 'save_service.dart';

const int kEnigmeDecoyCount = 10;
const int kEnigmeAttemptsBaseParJour = 1;
const int kEnigmeAdsMaxParJour = 5;
const int kEnigmeLettresDepart = 10; // déjà révélées dès lundi 00h00 GMT

/// État du mode "L'énigme de la semaine" : révélation du texte 1 caractère
/// par heure (dans un ordre mélangé, pas celui du texte), grille de tuiles
/// pour deviner le sujet (identique au jeu principal mais sans jokers
/// utilisables), tentatives limitées, et deux pubs distinctes (une pour
/// révéler une lettre, une pour gagner une tentative). Séparé de
/// [GameState] car son cycle de vie (hebdomadaire, ancré sur GMT) et ses
/// règles diffèrent entièrement de la campagne.
class EnigmeState extends ChangeNotifier {
  final SaveService saveService;
  final AnalyticsService analytics;
  final AppSettings settings;
  final Random _rng = Random();
  EnigmeState({required this.saveService, required this.settings, AnalyticsService? analytics})
      : analytics = analytics ?? AnalyticsService() {
    settings.addListener(_onSettingsChanged);
  }

  // Langue de l'énigme affichée. Elle suit le réglage dès qu'il change : la
  // garder figée donnait un écran anglais avec une énigme en français. Le
  // nombre de lettres dévoilées dépend du temps écoulé, pas de la langue.
  String locale = 'fr';

  void _onSettingsChanged() {
    if (settings.locale == locale) return;
    if (slots.isEmpty) {
      locale = settings.locale;
      return;
    }
    final memeReponse = normalize(enigme.sujetFor(locale)) == normalize(enigme.sujetFor(settings.locale));
    if (memeReponse) {
      locale = settings.locale; // grille commencée conservée
    } else {
      rebuildTiles(); // réponse différente : nouvelle grille dans la nouvelle langue
    }
    notifyListeners();
  }

  @override
  void dispose() {
    settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

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
    await saveService.saveEnigme(toJson());
  }

  // ─── Identité de la semaine en cours (ancrée GMT, voir enigmeWeekStart) ───
  int currentIndex = -1;
  DateTime? currentWeekStart;

  Enigme get enigme => kEnigmes[currentIndex.clamp(0, kEnigmes.length - 1)];

  // ─── Pubs et tentatives — deux pubs indépendantes, chacune plafonnée à
  // 5 par jour (GMT) ───
  int extraLettersFromAds = 0; // cumulé sur toute la semaine
  int adsWatchedForLettersToday = 0;
  DateTime? lastLetterAdDay;

  int adsWatchedForAttemptsToday = 0;
  DateTime? lastAttemptAdDay;

  int attemptsUsedToday = 0; // remis à zéro chaque jour (GMT)
  DateTime? lastAttemptDay;

  // ─── Résolution ───
  bool solved = false;
  int? solvedDay; // jour 1 à 7 de la résolution réussie
  int? solveSeconds; // durée écoulée depuis le début de semaine
  List<String> rewardLabels = [];
  // true dès qu'un Joker Rouge a été accordé pour le classement de cette
  // semaine (top 10% mondial) — empêche d'en regagner un à chaque réouverture
  // du panneau "résolu" tant que la semaine n'a pas changé.
  bool topTenRedJokerGranted = false;

  // Au moins une tentative cette semaine (trouvée ou non) : donne droit au
  // bilan de fin de semaine.
  bool participated = false;

  // Temps de résolution bien enregistré dans le classement en ligne. Sinon
  // (hors ligne, panne), il est renvoyé à la prochaine ouverture de l'écran.
  bool scoreSubmitted = false;

  /// Bilan de la semaine précédente, à afficher (puis remettre les jokers)
  /// à la première entrée de la semaine. Null s'il n'y en a pas.
  EnigmeBilan? pendingBilan;

  /// Jokers à recevoir au bilan selon le jour de résolution (1 à 7).
  static int rewardDayFor(int? day) => (day ?? 7).clamp(1, 7);

  /// Rang qualifiant pour le joker rouge : top 10 % du classement final.
  static bool isTopTen(int rang, int total) => total > 0 && rang <= (total * 0.10).ceil();

  /// Pourcentage affiché (« top X % ») : jamais 0, arrondi au supérieur.
  static int topPercent(int rang, int total) => total <= 0 ? 100 : max(1, (rang * 100 / total).ceil());

  // ─── Historique local ("Hall of Fame" personnel) — une entrée par semaine
  // résolue, la plus récente en premier. Conservé même après le changement
  // de semaine (contrairement au reste de l'état, remis à zéro par
  // [ensureFresh]). Plafonné pour ne pas grossir indéfiniment. ───
  static const int _historiqueMax = 52; // ~1 an
  List<EnigmeHistoryEntry> historique = [];

  /// Meilleur classement en proportion du nombre de joueurs (« top X % »),
  /// plus parlant qu'un rang brut d'une semaine à l'autre.
  EnigmeHistoryEntry? get meilleurClassement {
    EnigmeHistoryEntry? best;
    for (final e in historique) {
      if (e.rang == null || e.total == null || e.total! <= 0) continue;
      if (best == null || e.rang! / e.total! < best.rang! / best.total!) best = e;
    }
    return best;
  }

  EnigmeHistoryEntry? get meilleurTemps {
    EnigmeHistoryEntry? best;
    for (final e in historique) {
      if (best == null || e.solveSeconds < best.solveSeconds) best = e;
    }
    return best;
  }

  /// Archive le résultat de la semaine en cours dans l'historique local — no-op
  /// si déjà résolu et déjà archivé, pour ne jamais écraser un classement déjà
  /// connu (voir [recordRang]). Appelé à la fois sur une résolution fraîche
  /// (valider()) et à chaque ouverture de l'écran (ensureFresh()), ce qui
  /// rattrape aussi les résolutions faites avant l'ajout de cette fonctionnalité.
  void _archiverResultat() {
    final weekStart = currentWeekStart;
    if (weekStart == null || !solved || solveSeconds == null || solvedDay == null) return;
    final weekId = weekIdFor(weekStart);
    if (historique.any((e) => e.weekId == weekId)) return;
    historique.insert(
      0,
      EnigmeHistoryEntry(
        weekId: weekId,
        sujet: enigme.sujetFor(locale),
        solveSeconds: solveSeconds!,
        solvedDay: solvedDay!,
      ),
    );
    if (historique.length > _historiqueMax) {
      historique.removeRange(_historiqueMax, historique.length);
    }
  }

  /// Complète l'entrée d'historique de la semaine en cours avec le
  /// classement Firestore une fois connu (appelé depuis l'écran, après
  /// [LeaderboardService.fetchRank]) — le classement définitif n'est jamais
  /// garanti tant que la semaine n'est pas terminée, mais on garde la
  /// dernière valeur consultée.
  void recordRang({required int rang, required int total}) {
    final weekStart = currentWeekStart;
    if (weekStart == null) return;
    final weekId = weekIdFor(weekStart);
    final i = historique.indexWhere((e) => e.weekId == weekId);
    if (i == -1) return;
    historique[i] = historique[i].copyWith(rang: rang, total: total);
    notifyListeners();
  }

  // ─── Grille de tuiles ───
  List<AnswerSlot> slots = [];
  List<int?> guess = [];
  List<LetterTile> pool = [];
  int cursorIndex = -1;

  /// À appeler à chaque ouverture de l'écran : détecte un changement de
  /// semaine (réinitialise tout) ou de jour GMT (remet les compteurs
  /// quotidiens à zéro), et construit la grille si nécessaire.
  void ensureFresh() {
    final now = DateTime.now();
    final weekStart = enigmeWeekStart(now);
    final idx = enigmeIndexFor(now);
    final weekChanged = currentIndex != idx || currentWeekStart != weekStart;
    if (weekChanged) {
      // Bilan de la semaine qui se termine, seulement si le joueur revient
      // pendant la semaine qui suit (sinon les jokers sont perdus).
      final previousStart = currentWeekStart;
      final followingWeek = previousStart != null && weekStart.difference(previousStart).inDays == 7;
      pendingBilan = followingWeek && (participated || solved)
          ? EnigmeBilan(
              weekId: weekIdFor(previousStart),
              enigmeIndex: currentIndex,
              solved: solved,
              solveSeconds: solveSeconds,
              solvedDay: solvedDay,
              scoreSubmitted: scoreSubmitted,
              rewardsAlreadyGranted: rewardLabels.isNotEmpty,
              redJokerAlreadyGranted: topTenRedJokerGranted,
            )
          : null;
      participated = false;
      scoreSubmitted = false;
      currentIndex = idx;
      currentWeekStart = weekStart;
      extraLettersFromAds = 0;
      adsWatchedForLettersToday = 0;
      lastLetterAdDay = null;
      adsWatchedForAttemptsToday = 0;
      lastAttemptAdDay = null;
      attemptsUsedToday = 0;
      lastAttemptDay = null;
      solved = false;
      solvedDay = null;
      solveSeconds = null;
      rewardLabels = [];
      topTenRedJokerGranted = false;
      _ordreRevelationForIndex = -1;
    } else {
      _rolloverDayIfNeeded(now);
    }
    if (weekChanged || slots.isEmpty) rebuildTiles();
    _archiverResultat();
    notifyListeners();
  }

  void _rolloverDayIfNeeded(DateTime now) {
    final today = _utcDate(now);
    if (lastAttemptDay == null || !_sameDay(lastAttemptDay!, today)) {
      attemptsUsedToday = 0;
    }
    if (lastLetterAdDay == null || !_sameDay(lastLetterAdDay!, today)) {
      adsWatchedForLettersToday = 0;
    }
    if (lastAttemptAdDay == null || !_sameDay(lastAttemptAdDay!, today)) {
      adsWatchedForAttemptsToday = 0;
    }
  }

  /// Minuit UTC du jour de [now] — les journées de ce mode (tentatives, pubs)
  /// sont comptées en GMT, comme la semaine elle-même.
  DateTime _utcDate(DateTime now) {
    final u = now.toUtc();
    return DateTime.utc(u.year, u.month, u.day);
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  /// Construit la grille de tuiles pour l'énigme courante ([currentIndex]).
  /// Public pour permettre aux tests de forcer une énigme précise.
  void rebuildTiles() {
    locale = settings.locale;
    final sujetClean = normalize(enigme.sujetFor(locale));
    slots = sujetClean.split('').map(AnswerSlot.fromChar).toList();
    guess = List<int?>.filled(slots.length, null);
    cursorIndex = _firstEmptySlotFrom(0);

    final correctLetters = <String>[];
    for (final s in slots) {
      if (s.isSpace || s.isAuto) continue;
      correctLetters.add(s.char);
    }
    final used = correctLetters.toSet();
    final alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('').where((l) => !used.contains(l)).toList()..shuffle(_rng);
    final tiles = [...correctLetters, ...alphabet.take(kEnigmeDecoyCount)];
    tiles.shuffle(_rng);
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

  // ─── Révélation horaire du texte (1 caractère par heure, dans un ordre
  // mélangé mais identique pour tous les joueurs) ───

  int get heuresEcoulees {
    if (currentWeekStart == null) return 0;
    return DateTime.now().difference(currentWeekStart!).inHours.clamp(0, 24 * 7);
  }

  /// Jour en cours (1 à 7) depuis le début de la semaine de cette énigme.
  int get jourEnCours => (heuresEcoulees ~/ 24) + 1;

  /// Temps restant avant que l'horloge naturelle (1 lettre/heure) ne
  /// révèle une unité de plus — nul si tout est déjà révélé (texte + badge).
  Duration get tempsAvantProchaineLettre {
    if (currentWeekStart == null || _uniteRevelees >= _totalUnites) return Duration.zero;
    final prochaine = currentWeekStart!.add(Duration(hours: heuresEcoulees + 1));
    final diff = prochaine.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  static final _alnum = RegExp(r'[A-Za-z0-9]');

  int get _texteUnites => enigme.texteFor(locale).split('').where((c) => _alnum.hasMatch(c)).length;

  int get _totalUnites => _texteUnites + (enigme.badgeSupplementaire?.length ?? 0);

  int get _uniteRevelees =>
      (kEnigmeLettresDepart + heuresEcoulees + extraLettersFromAds).clamp(0, _totalUnites);

  // Ordre (mélangé) des positions de caractères alphanumériques du texte à
  // révéler — figé par énigme via un seed basé sur son index dans la liste
  // (jamais sur l'horloge ni sur hashCode, pour rester identique à tout
  // jamais pour tous les joueurs, quelle que soit la plateforme).
  List<int> _ordreRevelationCache = [];
  int _ordreRevelationForIndex = -1;

  List<int> get _ordreRevelation {
    if (_ordreRevelationForIndex != currentIndex) {
      final positions = <int>[];
      final chars = enigme.texteFor(locale).split('');
      for (var i = 0; i < chars.length; i++) {
        if (_alnum.hasMatch(chars[i])) positions.add(i);
      }
      positions.shuffle(Random(currentIndex * 7919 + 11));
      _ordreRevelationCache = positions;
      _ordreRevelationForIndex = currentIndex;
    }
    return _ordreRevelationCache;
  }

  int? _dernierePositionAlnumAvant(List<String> chars, int from) {
    for (var i = from - 1; i >= 0; i--) {
      if (_alnum.hasMatch(chars[i])) return i;
    }
    return null;
  }

  /// Le texte tel qu'il doit être affiché à l'instant présent : les
  /// caractères non encore révélés (selon [_ordreRevelation], pas l'ordre du
  /// texte) sont remplacés par un espace — volontairement identique à un
  /// vrai espace de mot, pour que le joueur ne puisse pas deviner où les
  /// mots commencent ou finissent avant d'avoir vraiment révélé leurs
  /// lettres. La ponctuation apparaît automatiquement avec la lettre qui la
  /// précède immédiatement dans le texte.
  String get texteRevele {
    final chars = enigme.texteFor(locale).split('');
    final revealedPositions = _ordreRevelation.take(_uniteRevelees).toSet();
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

  /// Le badge (année de sortie ou âge) tel qu'il doit être affiché : révélé
  /// chiffre par chiffre (dans l'ordre) une fois le texte principal
  /// entièrement sorti.
  String? get badgeRevele {
    final badge = enigme.badgeSupplementaire;
    if (badge == null) return null;
    final badgeUnites = (_uniteRevelees - _texteUnites).clamp(0, badge.length);
    return List.generate(badge.length, (i) => i < badgeUnites ? badge[i] : '•').join();
  }

  // ─── Tentatives et pubs ───

  int get tentativesRestantes => (kEnigmeAttemptsBaseParJour + adsWatchedForAttemptsToday - attemptsUsedToday)
      .clamp(0, kEnigmeAttemptsBaseParJour + kEnigmeAdsMaxParJour);

  bool get peutRegarderPubLettre =>
      !solved && adsWatchedForLettersToday < kEnigmeAdsMaxParJour && _uniteRevelees < _totalUnites;

  bool get peutRegarderPubTentative => !solved && adsWatchedForAttemptsToday < kEnigmeAdsMaxParJour;

  /// Pub "+1 lettre" : révèle une lettre de plus, cumulée sur la semaine.
  void onAdLettreRewarded() {
    if (!peutRegarderPubLettre) return;
    final now = DateTime.now();
    _rolloverDayIfNeeded(now);
    extraLettersFromAds = (extraLettersFromAds + 1).clamp(0, _totalUnites);
    adsWatchedForLettersToday++;
    lastLetterAdDay = _utcDate(now);
    notifyListeners();
  }

  /// Pub "+1 tentative" : donne une tentative supplémentaire pour aujourd'hui.
  void onAdTentativeRewarded() {
    if (!peutRegarderPubTentative) return;
    final now = DateTime.now();
    _rolloverDayIfNeeded(now);
    adsWatchedForAttemptsToday++;
    lastAttemptAdDay = _utcDate(now);
    notifyListeners();
  }

  // ─── Grille de tuiles ───

  void onLetterTap(LetterTile tile) {
    if (solved || tentativesRestantes <= 0 || tile.used) return;
    var target = cursorIndex;
    if (target == -1 || slots[target].isSpace || guess[target] != null) {
      target = _firstEmptySlotFrom(0);
    }
    if (target == -1) return;
    guess[target] = pool.indexOf(tile);
    tile.used = true;
    cursorIndex = _firstEmptySlotFrom(target + 1);
    notifyListeners();
  }

  void onBlankTap(int i) {
    if (solved) return;
    final tileId = guess[i];
    if (tileId != null) {
      pool[tileId].used = false;
      guess[i] = null;
    }
    cursorIndex = i;
    notifyListeners();
  }

  void _clearGuess() {
    for (var i = 0; i < slots.length; i++) {
      final tileId = guess[i];
      if (tileId != null) pool[tileId].used = false;
      guess[i] = null;
    }
    cursorIndex = _firstEmptySlotFrom(0);
  }

  /// Efface la grille en cours (bouton "Effacer" côté UI).
  void clearGuess() {
    if (solved) return;
    _clearGuess();
    notifyListeners();
  }

  /// Résultat : "incomplete", "no-attempts", "wrong" ou "solved".
  String valider() {
    if (solved) return 'solved';
    final now = DateTime.now();
    _rolloverDayIfNeeded(now);
    if (tentativesRestantes <= 0) return 'no-attempts';

    final allFilled =
        List.generate(slots.length, (i) => slots[i].isSpace || slots[i].isAuto || guess[i] != null).every((v) => v);
    if (!allFilled) return 'incomplete';

    attemptsUsedToday++;
    participated = true;
    lastAttemptDay = _utcDate(now);

    final attempt = List.generate(slots.length, (i) {
      final s = slots[i];
      if (s.isSpace) return ' ';
      if (s.isAuto) return s.char;
      return pool[guess[i]!].letter;
    }).join();
    final correct = slots.map((s) => s.char).join();

    if (attempt == correct) {
      solved = true;
      solvedDay = jourEnCours.clamp(1, 7);
      solveSeconds = DateTime.now().difference(currentWeekStart!).inSeconds;
      _archiverResultat();
      notifyListeners();
      analytics.logEnigmeSolved(day: solvedDay!);
      return 'solved';
    }

    _clearGuess();
    notifyListeners();
    return 'wrong';
  }

  void setRewardLabels(List<String> labels) {
    rewardLabels = labels;
    notifyListeners();
  }

  void markTopTenRedJokerGranted() {
    topTenRedJokerGranted = true;
    notifyListeners();
  }

  void markScoreSubmitted() {
    if (scoreSubmitted) return;
    scoreSubmitted = true;
    notifyListeners();
  }

  /// Score de la semaine écoulée enfin parti (renvoyé au moment du bilan).
  void markBilanScoreSubmitted() {
    final bilan = pendingBilan;
    if (bilan == null || bilan.scoreSubmitted) return;
    pendingBilan = EnigmeBilan.fromJson({...bilan.toJson(), 'scoreSubmitted': true});
    notifyListeners();
  }

  /// Bilan affiché et jokers remis : on l'efface (une seule fois), et le
  /// classement final remplace le classement provisoire dans l'historique.
  void completeBilan({int? rang, int? total}) {
    final bilan = pendingBilan;
    if (bilan == null) return;
    pendingBilan = null;
    if (rang != null && total != null) {
      final i = historique.indexWhere((e) => e.weekId == bilan.weekId);
      if (i != -1) historique[i] = historique[i].copyWith(rang: rang, total: total);
    }
    notifyListeners();
    flushSave(); // tout de suite : les jokers ne doivent jamais être remis deux fois
  }

  // ─── Persistance (uniquement l'état "méta" : la grille en cours n'est
  // pas conservée, comme pour le jeu principal) ───

  Map<String, dynamic> toJson() => {
        'currentIndex': currentIndex,
        'currentWeekStart': currentWeekStart?.toIso8601String(),
        'extraLettersFromAds': extraLettersFromAds,
        'adsWatchedForLettersToday': adsWatchedForLettersToday,
        'lastLetterAdDay': lastLetterAdDay?.toIso8601String(),
        'adsWatchedForAttemptsToday': adsWatchedForAttemptsToday,
        'lastAttemptAdDay': lastAttemptAdDay?.toIso8601String(),
        'attemptsUsedToday': attemptsUsedToday,
        'lastAttemptDay': lastAttemptDay?.toIso8601String(),
        'solved': solved,
        'solvedDay': solvedDay,
        'solveSeconds': solveSeconds,
        'rewardLabels': rewardLabels,
        'topTenRedJokerGranted': topTenRedJokerGranted,
        'participated': participated,
        'scoreSubmitted': scoreSubmitted,
        'pendingBilan': pendingBilan?.toJson(),
        'historique': historique.map((e) => e.toJson()).toList(),
      };

  /// Recharge l'état depuis la sauvegarde locale, après une restauration
  /// cloud : sans ça, la sauvegarde automatique à la fermeture de l'app
  /// réécrivait l'ancien état encore en mémoire par-dessus les données restaurées.
  Future<void> reloadFromSave() async {
    _saveDebounce?.cancel(); // une sauvegarde déjà programmée écrirait l'ancien état
    await restore();
    notifyListeners();
  }

  Future<void> restore() async {
    final data = await saveService.loadEnigme();
    if (data == null) return;
    _restoring = true;
    currentIndex = data['currentIndex'] as int? ?? -1;
    final ws = data['currentWeekStart'] as String?;
    currentWeekStart = ws != null ? DateTime.tryParse(ws) : null;
    extraLettersFromAds = data['extraLettersFromAds'] as int? ?? 0;
    adsWatchedForLettersToday = data['adsWatchedForLettersToday'] as int? ?? 0;
    final llad = data['lastLetterAdDay'] as String?;
    lastLetterAdDay = llad != null ? DateTime.tryParse(llad) : null;
    adsWatchedForAttemptsToday = data['adsWatchedForAttemptsToday'] as int? ?? 0;
    final laad = data['lastAttemptAdDay'] as String?;
    lastAttemptAdDay = laad != null ? DateTime.tryParse(laad) : null;
    attemptsUsedToday = data['attemptsUsedToday'] as int? ?? 0;
    final lat = data['lastAttemptDay'] as String?;
    lastAttemptDay = lat != null ? DateTime.tryParse(lat) : null;
    solved = data['solved'] as bool? ?? false;
    solvedDay = data['solvedDay'] as int?;
    solveSeconds = data['solveSeconds'] as int?;
    rewardLabels = (data['rewardLabels'] as List?)?.cast<String>() ?? [];
    topTenRedJokerGranted = data['topTenRedJokerGranted'] as bool? ?? false;
    participated = data['participated'] as bool? ?? false;
    scoreSubmitted = data['scoreSubmitted'] as bool? ?? false;
    final bilan = data['pendingBilan'];
    pendingBilan = bilan is Map ? EnigmeBilan.fromJson(Map<String, dynamic>.from(bilan)) : null;
    historique = (data['historique'] as List?)
            ?.map((e) => EnigmeHistoryEntry.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        [];
    _restoring = false;
  }
}
