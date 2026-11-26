import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../data/puzzles_data.dart';
import 'analytics_service.dart';
import 'app_settings.dart';
import 'game_state.dart';
import 'nickname_filter.dart';
import 'save_service.dart';

/// Classement global sur l'avancée (1.0.16) : les joueurs qui le veulent
/// apparaissent avec leur pseudo, classés par nombre de niveaux résolus.
///
/// - Facultatif : rien ne part tant que le joueur n'a pas choisi
///   d'apparaître ; il peut se retirer à tout moment (son document est
///   alors supprimé).
/// - Un classement par langue du contenu (deux collections Firestore,
///   `progress_leaderboard_fr` et `progress_leaderboard_en`) : pas d'index
///   composite, et l'on ne compare que des joueurs qui jouent les mêmes
///   réponses.
/// - Interrupteur à distance (document `app_config/public`, champ
///   `progressLeaderboardEnabled`), lu au lancement et gardé en cache.
///   Absent, illisible ou hors ligne sans cache = désactivé : rien de
///   visible, aucune écriture.
/// - Écritures sobres : à la résolution d'un niveau, au plus une toutes les
///   60 s, et seulement si le score a monté. Rattrapage au lancement.
/// - Le classement n'est lu qu'à l'ouverture de son écran (`count()` pour le
///   rang et le total, jamais d'écoute en continu).
///
/// Comme les autres services réseau du jeu : jamais bloquant, toute erreur
/// est avalée (voir [LeaderboardService]).

/// Tous les mondes ont 10 niveaux (vérifié dans kWorlds le 21/11/2026).
const int kLevelsPerWorld = 10;

/// Plafond du score, aussi vérifié par les règles Firestore (60 mondes).
const int kProgressScoreMax = 600;

/// Longueur maximale du pseudo, comme l'identifiant du profil.
const int kProgressPseudoMaxLength = 20;

/// Écart minimal entre deux écritures déclenchées par le jeu.
const Duration kProgressWriteGap = Duration(seconds: 60);

/// Taille du haut du classement, et nombre de joueurs montrés juste
/// au-dessus du joueur.
const int kProgressTopCount = 50;
const int kProgressAboveCount = 3;

/// Langues de contenu ayant chacune leur classement.
const List<String> kProgressLangs = ['fr', 'en'];

/// Document et champ de l'interrupteur à distance.
const String kAppConfigCollection = 'app_config';
const String kAppConfigDoc = 'public';
const String kProgressSwitchField = 'progressLeaderboardEnabled';

/// Langue du classement pour une langue de jeu (tout sauf l'anglais = français).
String progressLangFor(String locale) => locale == 'en' ? 'en' : 'fr';

/// Collection Firestore du classement d'une langue.
String progressCollectionFor(String lang) =>
    progressLangFor(lang) == 'en' ? 'progress_leaderboard_en' : 'progress_leaderboard_fr';

// ─── Score et « monde-niveau » ───

/// Nombre de niveaux résolus hors tutoriel, à partir de l'état réel du jeu.
///
/// La progression n'est pas linéaire : à chaque fin de monde le joueur
/// choisit entre deux mondes (l'autre reste en réserve), et un niveau peut
/// être laissé de côté (« Passer, j'y reviendrai »). On compte donc :
/// - chaque monde de [worldsPlayed] autre que le monde en cours : il a été
///   fini (on ne quitte un monde qu'après son dernier niveau) ;
/// - dans le monde en cours : ses niveaux moins ceux qui restent à faire,
///   plus le niveau qui vient d'être trouvé si « SUIVANT » n'a pas encore été
///   touché ([pendingSolve] : il est encore dans la liste des restants).
/// Le tutoriel (monde 0) ne compte pas. Un monde absent de cette version
/// (sauvegarde venue d'une version plus récente) vaut 0.
int progressScore({
  required Iterable<int> worldsPlayed,
  required int currentWorld,
  required int remainingInCurrent,
  required bool pendingSolve,
  required int Function(int world) worldSize,
}) {
  var total = 0;
  for (final w in worldsPlayed.toSet()) {
    if (w <= 0 || w == currentWorld) continue;
    total += worldSize(w);
  }
  if (currentWorld > 0) {
    final size = worldSize(currentWorld);
    final solved = size - remainingInCurrent + (pendingSolve ? 1 : 0);
    total += solved.clamp(0, size);
  }
  return total.clamp(0, kProgressScoreMax);
}

final Map<int, int> _worldSizes = {for (final w in kWorlds) w.number: w.puzzles.length};

/// [progressScore] pour la partie en cours.
int progressScoreOf(GameState game) => progressScore(
      worldsPlayed: game.worldsPlayedHistory,
      currentWorld: game.worldIndex,
      remainingInCurrent: game.remainingLevels.length,
      pendingSolve: game.hasPendingSolve,
      worldSize: (n) => _worldSizes[n] ?? 0,
    );

/// « monde-niveau » affiché pour un score : la position du dernier niveau
/// résolu si les mondes avaient été joués dans l'ordre, 10 niveaux chacun.
/// 153 → « 16-3 » (15 mondes finis + 3 niveaux du suivant), 150 → « 15-10 ».
/// Calculé depuis le score seul : deux joueurs à égalité affichent la même
/// chose, et l'affichage suit toujours l'ordre du classement (ce que ne
/// ferait pas le monde réellement en cours, à cause des mondes en réserve).
String worldLevelLabel(int score) {
  if (score <= 0) return '-';
  return '${(score - 1) ~/ kLevelsPerWorld + 1}-${(score - 1) % kLevelsPerWorld + 1}';
}

// ─── Interrupteur à distance ───

/// Valeur de l'interrupteur dans le document `app_config/public` : vrai
/// seulement si le champ existe et vaut exactement `true`.
bool progressLeaderboardEnabledFrom(Map<String, dynamic>? data) => data?[kProgressSwitchField] == true;

/// [fetched] : valeur lue au lancement (null = illisible ou hors ligne).
/// [cached] : dernière valeur lue (null = jamais lue). Sans rien : désactivé.
bool resolveProgressLeaderboardEnabled({bool? fetched, bool? cached}) => fetched ?? cached ?? false;

// ─── Écritures ───

enum ProgressWriteDecision { skip, now, later }

/// Faut-il écrire le [score] maintenant ? Jamais s'il n'a pas monté depuis le
/// dernier envoi réussi ([lastSent]) ; sinon au plus une fois toutes les
/// [gap] depuis la dernière tentative ([lastWriteAt]). Une horloge qui
/// recule (réglage du téléphone) ne bloque pas l'envoi.
ProgressWriteDecision progressWriteDecision({
  required int score,
  required int lastSent,
  required DateTime? lastWriteAt,
  required DateTime now,
  Duration gap = kProgressWriteGap,
}) {
  if (score < 1 || score <= lastSent) return ProgressWriteDecision.skip;
  if (lastWriteAt == null) return ProgressWriteDecision.now;
  final elapsed = now.difference(lastWriteAt);
  if (elapsed.isNegative || elapsed >= gap) return ProgressWriteDecision.now;
  return ProgressWriteDecision.later;
}

// ─── Pseudo ───

/// Pseudo acceptable pour le classement : 1 à 20 caractères une fois les
/// espaces de bord retirés, et accepté par le filtre du Multijoueur.
bool isProgressPseudoValid(String pseudo) {
  final p = pseudo.trim();
  if (p.isEmpty || p.length > kProgressPseudoMaxLength) return false;
  if (p.contains('\n') || p.contains('\r')) return false;
  return isNicknameAcceptable(p);
}

/// Pseudo montré pour une ligne venue du serveur : filet de sécurité si un
/// document a été écrit sans passer par le filtre du jeu.
String progressDisplayPseudo(String pseudo, String lang) {
  final p = pseudo.trim();
  if (p.isEmpty || p.length > kProgressPseudoMaxLength || !isNicknameAcceptable(p)) {
    return lang == 'en' ? AppSettings.kDefaultPlayerNameUs : AppSettings.kDefaultPlayerNameFr;
  }
  return p;
}

/// Coupe à [kProgressPseudoMaxLength] unités sans casser un émoji.
String _cutPseudo(String s) {
  final t = s.trim();
  if (t.length <= kProgressPseudoMaxLength) return t;
  final b = StringBuffer();
  for (final r in t.runes) {
    final c = String.fromCharCode(r);
    if (b.length + c.length > kProgressPseudoMaxLength) break;
    b.write(c);
  }
  return b.toString().trim();
}

// Un seul pseudo pour le joueur : « Ton pseudo » de l'accueil
// (AppSettings.playerId, « #123456 » tiré au hasard à l'installation tant
// qu'il n'a pas été personnalisé). Le classement le lit à chaque écriture ;
// le changer depuis la fenêtre du classement change celui de l'accueil.

/// Identifiant tiré au hasard à l'installation, jamais personnalisé.
bool isAutoPlayerId(String playerId) => RegExp(r'^#\d{6}$').hasMatch(playerId.trim());

/// Pseudo par défaut (celui du Multijoueur) dans la langue du classement.
String progressDefaultPseudo(String lang) =>
    progressLangFor(lang) == 'en' ? AppSettings.kDefaultPlayerNameUs : AppSettings.kDefaultPlayerNameFr;

/// Pseudo publié pour l'identifiant du joueur : l'identifiant lui-même s'il
/// a été personnalisé et passe le filtre ; sinon le pseudo par défaut (jamais
/// « #123456 », jamais un pseudo refusé).
String progressPublishedPseudo(String playerId, String lang) {
  final p = playerId.trim();
  if (isAutoPlayerId(p) || !isProgressPseudoValid(p)) return progressDefaultPseudo(lang);
  return p;
}

/// Pseudo prérempli dans la fenêtre du classement : l'identifiant de
/// l'accueil s'il a été personnalisé, sinon « Cinéphile » (« Cinephile » en
/// anglais).
String suggestedProgressPseudo({required String playerId, required String locale}) {
  final id = playerId.trim();
  if (id.isEmpty || isAutoPlayerId(id)) return progressDefaultPseudo(locale);
  return _cutPseudo(id);
}

/// Pseudo par défaut, dans l'une ou l'autre langue.
bool _isDefaultPseudo(String p) => p == AppSettings.kDefaultPlayerNameFr || p == AppSettings.kDefaultPlayerNameUs;

// ─── Lignes et rangs ───

/// Une ligne du classement : rang, pseudo, score (niveaux résolus).
class ProgressRow {
  final String uid;
  final String pseudo;
  final int score;
  final int rank;
  final bool isMe;
  const ProgressRow({required this.uid, required this.pseudo, required this.score, this.rank = 0, this.isMe = false});

  String get worldLevel => worldLevelLabel(score);

  ProgressRow copyWith({String? pseudo, int? rank, bool? isMe}) => ProgressRow(
      uid: uid, pseudo: pseudo ?? this.pseudo, score: score, rank: rank ?? this.rank, isMe: isMe ?? this.isMe);
}

/// Rangs « à égalité, même rang » (1, 1, 3...) pour des lignes triées par
/// score décroissant depuis la toute première place.
List<ProgressRow> rankRows(List<ProgressRow> sortedDesc) {
  final out = <ProgressRow>[];
  for (var i = 0; i < sortedDesc.length; i++) {
    final r = sortedDesc[i];
    final rank = i > 0 && sortedDesc[i - 1].score == r.score ? out[i - 1].rank : i + 1;
    out.add(r.copyWith(rank: rank));
  }
  return out;
}

/// Rang d'un score d'après le haut du classement, s'il y figure (le haut est
/// le début de la liste complète : la première ligne à ce score donne son rang).
int? rankFromTop(List<ProgressRow> top, int score) {
  for (final r in top) {
    if (r.score == score) return r.rank;
  }
  return null;
}

/// Tranche du rang pour la mesure (jamais le rang exact).
String rankBucket(int? rank) {
  if (rank == null || rank < 1) return 'none';
  if (rank <= 10) return 'top10';
  if (rank <= 50) return 'top50';
  if (rank <= 100) return 'top100';
  if (rank <= 1000) return 'top1000';
  return 'more';
}

/// Ce que le serveur renvoie à l'ouverture de l'écran.
class ProgressBoardData {
  /// Les [kProgressTopCount] premiers, rangs calculés.
  final List<ProgressRow> top;

  /// Les joueurs juste au-dessus du score demandé, du plus haut au plus proche.
  final List<ProgressRow> above;

  /// Joueurs inscrits dans ce classement.
  final int total;

  /// Rang du score demandé (null si aucun score demandé).
  final int? myRank;

  const ProgressBoardData({required this.top, required this.above, required this.total, required this.myRank});
}

/// Ce que l'écran affiche.
class ProgressBoardView {
  final List<ProgressRow> top;
  final List<ProgressRow> above;

  /// Rang du joueur (null tant qu'il n'a résolu aucun niveau).
  final int? myRank;
  final int myScore;

  /// Total affiché (« 123e sur 4 567 ») : le joueur y est toujours compté,
  /// même s'il n'apparaît pas (sa place est alors celle qu'il aurait).
  final int total;

  /// Le joueur apparaît dans le classement.
  final bool joined;

  const ProgressBoardView({
    required this.top,
    required this.above,
    required this.myRank,
    required this.myScore,
    required this.total,
    required this.joined,
  });
}

enum ProgressJoinResult { ok, refused, failed }

/// Accès au serveur (Firestore en vrai, faux serveur dans les tests).
/// Les écritures et lectures lèvent une exception en cas d'échec.
abstract class ProgressLeaderboardBackend {
  /// Plateforme où Firebase existe (Android, iOS).
  bool get supported;

  /// Identifiant (anonyme) du joueur, s'il en a déjà un.
  String? get uid;

  /// Interrupteur : vrai/faux s'il a pu être lu (document absent = faux),
  /// null si illisible ou hors ligne. Ne lève jamais d'exception.
  Future<bool?> fetchEnabled();

  Future<void> writeEntry({required String lang, required String pseudo, required int score});

  /// Supprime le document du joueur dans le classement de [lang] (sans
  /// erreur s'il n'existe pas).
  Future<void> deleteEntry(String lang);

  /// Le document du joueur dans [lang], ou null s'il n'existe pas.
  Future<({String pseudo, int score})?> fetchMine(String lang);

  Future<ProgressBoardData> fetchBoard({required String lang, required int? myScore});
}

/// État local du classement (participation, dernier envoi, interrupteur en
/// cache) et toutes ses écritures. Les opérations réseau passent une par une
/// (jamais deux écritures en parallèle).
class ProgressLeaderboard extends ChangeNotifier {
  final ProgressLeaderboardBackend backend;
  final SaveService saveService;
  final int Function() scoreSource;
  final String Function() langSource;

  /// « Ton pseudo » de l'accueil (AppSettings.playerId), lu à chaque écriture.
  final String Function() pseudoSource;

  /// Le joueur a choisi un pseudo dans la fenêtre du classement : il devient
  /// aussi celui de l'accueil (AppSettings.setPlayerId).
  final void Function(String pseudo)? onPseudoChosen;
  final AnalyticsService? analytics;
  final DateTime Function() clock;

  ProgressLeaderboard({
    required this.backend,
    required this.saveService,
    required this.scoreSource,
    required this.langSource,
    required this.pseudoSource,
    this.onPseudoChosen,
    this.analytics,
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now;

  bool _enabled = false;
  bool? _enabledCache;
  bool _participating = false;
  int _lastSent = 0;
  DateTime? _lastWriteAt;
  String? _docLang;
  bool _pendingDelete = false;
  bool _introSeen = false;
  Timer? _deferred;
  bool _disposed = false;

  /// Interrupteur allumé : l'entrée est visible et les écritures permises.
  bool get enabled => _enabled;

  /// Le joueur a choisi d'apparaître.
  bool get participating => _participating;

  /// Pseudo publié à la prochaine écriture : « Ton pseudo » de l'accueil
  /// passé au filtre (« Cinéphile » s'il n'a jamais été personnalisé ou
  /// s'il est refusé).
  String get pseudo => progressPublishedPseudo(pseudoSource(), progressLangFor(langSource()));

  /// La proposition d'apparaître a déjà été faite (première ouverture).
  bool get introSeen => _introSeen;

  /// Dernier score envoyé avec succès.
  int get lastSentScore => _lastSent;

  /// Retrait demandé mais pas encore confirmé par le serveur.
  bool get pendingDelete => _pendingDelete;

  /// Une écriture différée attend la fin des 60 s.
  @visibleForTesting
  bool get hasDeferredWrite => _deferred != null;

  Map<String, dynamic> toJson() => {
        'enabledCache': _enabledCache,
        'participating': _participating,
        'lastSent': _lastSent,
        'lastWriteAt': _lastWriteAt?.toIso8601String(),
        'docLang': _docLang,
        'pendingDelete': _pendingDelete,
        'introSeen': _introSeen,
      };

  /// Charge l'état local. À appeler au démarrage, avant l'affichage :
  /// l'interrupteur vaut sa dernière valeur lue tant que le serveur n'a pas
  /// répondu.
  Future<void> restore() async {
    try {
      final data = await saveService.loadProgressLeaderboard();
      if (data != null) {
        _enabledCache = data['enabledCache'] as bool?;
        _participating = data['participating'] as bool? ?? false;
        _lastSent = (data['lastSent'] as num?)?.toInt() ?? 0;
        final at = data['lastWriteAt'] as String?;
        _lastWriteAt = at == null ? null : DateTime.tryParse(at);
        _docLang = data['docLang'] as String?;
        _pendingDelete = data['pendingDelete'] as bool? ?? false;
        _introSeen = data['introSeen'] as bool? ?? false;
      }
    } catch (_) {
      // Sauvegarde illisible : jamais de plantage au lancement pour ça.
    }
    _enabled = resolveProgressLeaderboardEnabled(cached: _enabledCache);
  }

  Future<void> _save() async {
    try {
      await saveService.saveProgressLeaderboard(toJson());
    } catch (_) {}
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _chain = Future.value();

  /// Exécute [op] après les opérations déjà lancées.
  Future<T> _serial<T>(Future<T> Function() op) {
    final done = Completer<T>();
    _chain = _chain.then((_) async {
      try {
        done.complete(await op());
      } catch (e, s) {
        done.completeError(e, s);
      }
    });
    return done.future;
  }

  /// Au lancement, une fois Firebase prêt : lit l'interrupteur, termine un
  /// retrait en attente, puis rattrape un envoi qui aurait échoué.
  Future<void> startup() => _serial(() async {
        if (!backend.supported) return;
        final fetched = await backend.fetchEnabled();
        if (fetched != null && fetched != _enabledCache) {
          _enabledCache = fetched;
          await _save();
        }
        final next = resolveProgressLeaderboardEnabled(fetched: fetched, cached: _enabledCache);
        if (next != _enabled) {
          _enabled = next;
          _notify();
        }
        // Le droit à l'effacement passe avant l'interrupteur.
        if (_pendingDelete) await _deleteNow();
        if (_enabled) await _syncNow(ignoreGap: true);
      });

  /// Appelé à chaque niveau résolu (voir GameState.onLevelSolved).
  void onLevelSolved() {
    if (!_enabled || !_participating || _disposed) return;
    final decision = progressWriteDecision(
        score: min(scoreSource(), kProgressScoreMax), lastSent: _lastSent, lastWriteAt: _lastWriteAt, now: clock());
    switch (decision) {
      case ProgressWriteDecision.skip:
        return;
      case ProgressWriteDecision.now:
        _deferred?.cancel();
        _deferred = null;
        unawaited(_serial(_syncNow));
      case ProgressWriteDecision.later:
        // Un seul envoi différé à la fois : il partira avec le score du moment.
        if (_deferred != null) return;
        final wait = _lastWriteAt!.add(kProgressWriteGap).difference(clock()) + const Duration(seconds: 1);
        _deferred = Timer(wait, () {
          _deferred = null;
          if (!_disposed) unawaited(_serial(_syncNow));
        });
    }
  }

  /// Envoie le score s'il a monté (et s'il le faut, déménage le document vers
  /// le classement de la langue actuelle). Vrai si un envoi a réussi. Le
  /// pseudo envoyé est celui de l'accueil à cet instant (un changement de
  /// pseudo depuis l'accueil part donc avec l'écriture suivante, sans
  /// écriture en plus).
  Future<bool> _syncNow({bool ignoreGap = false}) async {
    if (!_enabled || !_participating) return false;
    final lang = progressLangFor(langSource());
    if (!await _moveIfLanguageChanged(lang)) return false;
    final score = min(scoreSource(), kProgressScoreMax);
    final decision = progressWriteDecision(
        score: score, lastSent: _lastSent, lastWriteAt: ignoreGap ? null : _lastWriteAt, now: clock());
    if (decision != ProgressWriteDecision.now) return false;
    return _write(lang, score, progressPublishedPseudo(pseudoSource(), lang));
  }

  /// Le joueur a changé la langue du jeu : son document quitte l'ancien
  /// classement (supprimé), le prochain envoi le crée dans le nouveau.
  Future<bool> _moveIfLanguageChanged(String lang) async {
    final old = _docLang;
    if (old == null || old == lang) return true;
    try {
      await backend.deleteEntry(old);
    } catch (_) {
      return false;
    }
    _docLang = null;
    _lastSent = 0;
    _lastWriteAt = null;
    await _save();
    return true;
  }

  Future<bool> _write(String lang, int score, String pseudo) async {
    _lastWriteAt = clock();
    try {
      await backend.writeEntry(lang: lang, pseudo: pseudo, score: score);
      _lastSent = score;
      _docLang = lang;
      await _save();
      return true;
    } catch (_) {
      await _save();
      return false;
    }
  }

  Future<bool> _deleteNow() async {
    try {
      for (final lang in kProgressLangs) {
        await backend.deleteEntry(lang);
      }
    } catch (_) {
      return false;
    }
    _pendingDelete = false;
    _docLang = null;
    _lastSent = 0;
    _lastWriteAt = null;
    await _save();
    return true;
  }

  /// Le joueur choisit d'apparaître (ou change de pseudo s'il apparaît déjà).
  /// Le pseudo est publié tout de suite, avec le score actuel (le document
  /// sera créé au premier niveau résolu si le score est encore à 0), puis
  /// devient « Ton pseudo » de l'accueil — sauf « Cinéphile » accepté tel
  /// quel alors que l'identifiant n'a jamais été personnalisé : « #123456 »
  /// reste alors l'identifiant, et « Cinéphile » le pseudo publié.
  Future<ProgressJoinResult> join(String rawPseudo) => _serial(() async {
        final p = rawPseudo.trim();
        if (!isProgressPseudoValid(p)) return ProgressJoinResult.refused;
        if (!_enabled) return ProgressJoinResult.failed;
        final firstJoin = !_participating;
        final oldPendingDelete = _pendingDelete;
        _participating = true;
        _pendingDelete = false;
        _introSeen = true;
        final lang = progressLangFor(langSource());
        var ok = await _moveIfLanguageChanged(lang);
        if (ok) {
          // Jamais moins que le dernier envoi : le score publié ne descend pas
          // (progression remise à zéro dans les réglages, par exemple).
          final score = min(max(scoreSource(), _lastSent), kProgressScoreMax);
          ok = score < 1 || await _write(lang, score, p);
        }
        if (!ok) {
          // Rien n'est publié : on revient à l'état d'avant (pseudo compris).
          _participating = !firstJoin;
          _pendingDelete = oldPendingDelete;
          await _save();
          _notify();
          return ProgressJoinResult.failed;
        }
        final keepAutoId = _isDefaultPseudo(p) && isAutoPlayerId(pseudoSource());
        if (!keepAutoId && p != pseudoSource().trim()) onPseudoChosen?.call(p);
        await _save();
        _notify();
        if (firstJoin) unawaited(analytics?.logLeaderboardJoin());
        return ProgressJoinResult.ok;
      });

  /// Le joueur se retire : son document est supprimé des deux classements.
  /// Possible même interrupteur éteint (ligne des Réglages) : le droit à
  /// l'effacement ne dépend pas de l'interrupteur. Hors ligne, la
  /// suppression est retentée au prochain lancement (et à la prochaine
  /// ouverture du classement).
  ///
  /// Aussi appelé par la suppression du compte (Réglages), même pour un
  /// joueur que le téléphone ne croit pas inscrit : un document repris après
  /// une réinstallation est effacé lui aussi. Vrai si les deux suppressions
  /// ont réussi (document absent compris). La mesure `leaderboard_leave` ne
  /// part que pour un joueur qui apparaissait.
  Future<bool> leave() => _serial(() async {
        _deferred?.cancel();
        _deferred = null;
        final wasIn = _participating;
        _participating = false;
        _pendingDelete = true;
        await _save();
        _notify();
        if (wasIn) unawaited(analytics?.logLeaderboardLeave());
        return _deleteNow();
      });

  /// La proposition de la première ouverture a été faite.
  void markIntroSeen() {
    if (_introSeen) return;
    _introSeen = true;
    unawaited(_save());
  }

  /// Lecture du classement, à l'ouverture de son écran seulement. Null si
  /// indisponible (hors ligne, interrupteur éteint...).
  Future<ProgressBoardView?> loadBoard() => _serial(() async {
        if (!_enabled) return null;
        final lang = progressLangFor(langSource());
        try {
          if (_pendingDelete) await _deleteNow();
          // Document déjà là alors que le téléphone ne le sait pas
          // (réinstallation avec un compte lié, réponse perdue) : on le reprend.
          if (!_participating && !_pendingDelete) {
            final mine = await backend.fetchMine(lang);
            if (mine != null) {
              // Le pseudo reste celui de l'accueil (restauré avec la
              // sauvegarde Google) : il repartira à la prochaine écriture.
              _participating = true;
              _lastSent = mine.score;
              _docLang = lang;
              _introSeen = true;
              await _save();
              _notify();
            }
          }
          if (_participating) await _syncNow(ignoreGap: true);
          final inBoard = _participating && _docLang == lang && _lastSent >= 1;
          final myScore = inBoard ? _lastSent : min(scoreSource(), kProgressScoreMax);
          final data = await backend.fetchBoard(lang: lang, myScore: myScore >= 1 ? myScore : null);
          final uid = backend.uid;
          final myRank = myScore >= 1 ? data.myRank : null;
          // Le joueur compte toujours dans le total, même s'il n'apparaît pas.
          final total = max(data.total + (!inBoard && myScore >= 1 ? 1 : 0), myRank ?? 0);
          // Sa propre ligne montre son pseudo actuel (changé depuis l'accueil,
          // il ne partira qu'avec l'écriture suivante).
          final view = ProgressBoardView(
            top: [
              for (final r in data.top)
                if (inBoard && uid != null && r.uid == uid)
                  r.copyWith(pseudo: pseudo, isMe: true)
                else
                  r.copyWith(pseudo: progressDisplayPseudo(r.pseudo, lang))
            ],
            above: [for (final r in data.above) r.copyWith(pseudo: progressDisplayPseudo(r.pseudo, lang))],
            myRank: myRank,
            myScore: myScore,
            total: total,
            joined: _participating,
          );
          unawaited(analytics?.logLeaderboardOpen(rankBucket: rankBucket(view.myRank), joined: _participating));
          return view;
        } catch (e) {
          debugPrint('progress leaderboard: $e');
          unawaited(analytics?.logLeaderboardOpen(rankBucket: 'offline', joined: _participating));
          return null;
        }
      });

  @override
  void dispose() {
    _disposed = true;
    _deferred?.cancel();
    _deferred = null;
    super.dispose();
  }
}
