import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cine_devinette/data/puzzles_data.dart';
import 'package:cine_devinette/l10n/app_localizations.dart';
import 'package:cine_devinette/screens/home_screen.dart';
import 'package:cine_devinette/screens/progress_leaderboard_screen.dart';
import 'package:cine_devinette/screens/settings_screen.dart';
import 'package:cine_devinette/services/ad_service.dart';
import 'package:cine_devinette/services/analytics_service.dart';
import 'package:cine_devinette/services/app_settings.dart';
import 'package:cine_devinette/services/cloud_sync_service.dart';
import 'package:cine_devinette/services/game_state.dart';
import 'package:cine_devinette/services/nickname_filter.dart';
import 'package:cine_devinette/services/progress_leaderboard.dart';
import 'package:cine_devinette/services/save_service.dart';
import 'package:cine_devinette/services/streak_state.dart';

/// Faux serveur : tout en mémoire, sans réseau.
class FakeBackend implements ProgressLeaderboardBackend {
  bool? enabledAnswer = true;
  bool failWrites = false;
  bool failDeletes = false;
  bool failReads = false;
  @override
  String? uid = 'moi';
  final List<(String lang, String pseudo, int score)> writes = [];
  final List<String> deletes = [];
  final Map<String, Map<String, ({String pseudo, int score})>> docs = {'fr': {}, 'en': {}};
  ProgressBoardData board = const ProgressBoardData(top: [], above: [], total: 0, myRank: null);
  int? lastBoardScore;

  @override
  bool get supported => true;

  @override
  Future<bool?> fetchEnabled() async => enabledAnswer;

  @override
  Future<void> writeEntry({required String lang, required String pseudo, required int score}) async {
    if (failWrites) throw Exception('hors ligne');
    writes.add((lang, pseudo, score));
    docs[lang]![uid!] = (pseudo: pseudo, score: score);
  }

  @override
  Future<void> deleteEntry(String lang) async {
    if (failDeletes) throw Exception('hors ligne');
    deletes.add(lang);
    docs[lang]!.remove(uid);
  }

  @override
  Future<({String pseudo, int score})?> fetchMine(String lang) async {
    if (failReads) throw Exception('hors ligne');
    return docs[lang]![uid];
  }

  @override
  Future<ProgressBoardData> fetchBoard({required String lang, required int? myScore}) async {
    if (failReads) throw Exception('hors ligne');
    lastBoardScore = myScore;
    return board;
  }
}

/// Mesure espionnée (aucun envoi réel).
class SpyAnalytics extends AnalyticsService {
  final List<String> events = [];
  @override
  Future<void> logLeaderboardOpen({required String rankBucket, required bool joined}) async =>
      events.add('open:$rankBucket:${joined ? 1 : 0}');
  @override
  Future<void> logLeaderboardJoin() async => events.add('join');
  @override
  Future<void> logLeaderboardLeave() async => events.add('leave');
}

class Harness {
  final FakeBackend backend = FakeBackend();
  final SpyAnalytics analytics = SpyAnalytics();
  final SaveService saveService = SaveService();
  int score = 0;
  String locale = 'fr';

  /// « Ton pseudo » de l'accueil (AppSettings.playerId), ou les vrais
  /// réglages s'ils sont donnés (tests d'écran).
  String playerId = '#123456';
  AppSettings? settings;
  DateTime now = DateTime(2026, 11, 21, 20);
  late ProgressLeaderboard lb = make();

  ProgressLeaderboard make() => ProgressLeaderboard(
        backend: backend,
        saveService: saveService,
        scoreSource: () => score,
        langSource: () => locale,
        pseudoSource: () => settings?.playerId ?? playerId,
        onPseudoChosen: (p) => settings == null ? playerId = p : settings!.setPlayerId(p),
        analytics: analytics,
        clock: () => now,
      );

  /// Interrupteur allumé, joueur inscrit sous [pseudo] avec le score [s].
  Future<void> joined({String pseudo = 'Bobdu13', int s = 3}) async {
    score = s;
    await lb.startup();
    expect(lb.enabled, isTrue);
    expect(await lb.join(pseudo), ProgressJoinResult.ok);
  }
}

/// Laisse passer les opérations réseau enchaînées (faux serveur immédiat).
Future<void> settle() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

ProgressRow row(String uid, String pseudo, int score, {int rank = 0}) =>
    ProgressRow(uid: uid, pseudo: pseudo, score: score, rank: rank);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AnalyticsService.resetForTests();
  });

  group('score = niveaux résolus', () {
    int size(int n) => n >= 1 && n <= 35 ? 10 : 0;

    test('tutoriel seul : 0', () {
      expect(
          progressScore(worldsPlayed: {}, currentWorld: 0, remainingInCurrent: 2, pendingSolve: false, worldSize: size),
          0);
    });

    test('monde 1 en cours, 3 niveaux faits (7 restants)', () {
      expect(
          progressScore(worldsPlayed: {1}, currentWorld: 1, remainingInCurrent: 7, pendingSolve: false, worldSize: size),
          3);
    });

    test('niveau trouvé mais « SUIVANT » pas encore touché : compté', () {
      expect(
          progressScore(worldsPlayed: {1}, currentWorld: 1, remainingInCurrent: 7, pendingSolve: true, worldSize: size),
          4);
    });

    test('choix des mondes : mondes finis hors ordre + monde en cours', () {
      // Mondes 1, 2, 4 finis (3 laissé en réserve), monde 5 en cours, 2 faits.
      expect(
          progressScore(
              worldsPlayed: {1, 2, 4, 5}, currentWorld: 5, remainingInCurrent: 8, pendingSolve: false, worldSize: size),
          32);
    });

    test('monde fini, choix du suivant pas encore fait : 10 niveaux', () {
      expect(
          progressScore(worldsPlayed: {1, 2}, currentWorld: 2, remainingInCurrent: 0, pendingSolve: false, worldSize: size),
          20);
    });

    test('monde inconnu de cette version ignoré, plafond 600', () {
      expect(
          progressScore(worldsPlayed: {1, 99}, currentWorld: 1, remainingInCurrent: 10, pendingSolve: false, worldSize: size),
          0);
      expect(
          progressScore(
              worldsPlayed: List.generate(80, (i) => i + 1),
              currentWorld: 80,
              remainingInCurrent: 0,
              pendingSolve: false,
              worldSize: (_) => 10),
          kProgressScoreMax);
    });

    test('calculé sur la vraie partie (GameState)', () {
      final saveService = SaveService();
      final game = GameState(adService: AdService(), saveService: saveService, settings: AppSettings(saveService: saveService));
      game.enterWorld(0);
      expect(progressScoreOf(game), 0);
      game.enterWorld(1);
      expect(progressScoreOf(game), 0);
      game.remainingLevels.removeRange(0, 4);
      expect(progressScoreOf(game), 4);
      game.remainingLevels.clear();
      game.enterWorld(3);
      game.remainingLevels.removeAt(0);
      expect(progressScoreOf(game), 11);
      expect(kWorlds.every((w) => w.puzzles.length == kLevelsPerWorld), isTrue,
          reason: '« monde-niveau » suppose 10 niveaux par monde');
    });
  });

  test('« monde-niveau » à partir du score', () {
    expect(worldLevelLabel(0), '-');
    expect(worldLevelLabel(1), '1-1');
    expect(worldLevelLabel(10), '1-10');
    expect(worldLevelLabel(11), '2-1');
    expect(worldLevelLabel(150), '15-10');
    expect(worldLevelLabel(153), '16-3');
  });

  group('écritures : une toutes les 60 s, seulement si le score monte', () {
    final t0 = DateTime(2026, 11, 21, 20);

    test('décision pure', () {
      ProgressWriteDecision d(int score, int last, DateTime? at, DateTime now) =>
          progressWriteDecision(score: score, lastSent: last, lastWriteAt: at, now: now);
      expect(d(0, 0, null, t0), ProgressWriteDecision.skip);
      expect(d(5, 5, null, t0), ProgressWriteDecision.skip);
      expect(d(4, 5, null, t0), ProgressWriteDecision.skip);
      expect(d(6, 5, null, t0), ProgressWriteDecision.now);
      expect(d(6, 5, t0, t0.add(const Duration(seconds: 30))), ProgressWriteDecision.later);
      expect(d(6, 5, t0, t0.add(const Duration(seconds: 60))), ProgressWriteDecision.now);
      // Horloge du téléphone reculée : on n'attend pas.
      expect(d(6, 5, t0, t0.subtract(const Duration(hours: 1))), ProgressWriteDecision.now);
    });

    test('service : deux niveaux en 10 s = une écriture, puis une après 60 s', () async {
      final h = Harness();
      await h.joined(s: 3);
      expect(h.backend.writes, [('fr', 'Bobdu13', 3)]);

      h.now = h.now.add(const Duration(seconds: 10));
      h.score = 4;
      h.lb.onLevelSolved();
      await settle();
      expect(h.backend.writes.length, 1, reason: 'moins de 60 s après la précédente');
      expect(h.lb.hasDeferredWrite, isTrue);

      h.now = h.now.add(const Duration(seconds: 55));
      h.score = 5;
      h.lb.onLevelSolved();
      await settle();
      expect(h.backend.writes.last, ('fr', 'Bobdu13', 5));
      expect(h.backend.writes.length, 2);
      h.lb.dispose();
    });

    test('score qui ne monte pas : aucune écriture', () async {
      final h = Harness();
      await h.joined(s: 3);
      h.now = h.now.add(const Duration(minutes: 5));
      h.lb.onLevelSolved();
      h.score = 2; // progression remise à zéro
      h.lb.onLevelSolved();
      await settle();
      expect(h.backend.writes.length, 1);
      h.lb.dispose();
    });

    test('envoi échoué rattrapé au lancement suivant', () async {
      final h = Harness();
      await h.joined(s: 3);
      h.backend.failWrites = true;
      h.now = h.now.add(const Duration(minutes: 2));
      h.score = 7;
      h.lb.onLevelSolved();
      await settle();
      expect(h.lb.lastSentScore, 3);

      // Nouveau lancement : état relu depuis le téléphone.
      h.backend.failWrites = false;
      h.now = h.now.add(const Duration(seconds: 5));
      final relance = h.make();
      await relance.restore();
      expect(relance.participating, isTrue);
      await relance.startup();
      expect(h.backend.writes.last, ('fr', 'Bobdu13', 7));
      expect(relance.lastSentScore, 7);
      h.lb.dispose();
      relance.dispose();
    });

    test('pas inscrit : rien ne part', () async {
      final h = Harness();
      h.score = 12;
      await h.lb.startup();
      h.lb.onLevelSolved();
      await settle();
      expect(h.backend.writes, isEmpty);
    });

    test('changement de langue : le document change de classement', () async {
      final h = Harness();
      await h.joined(s: 3);
      h.locale = 'en';
      h.score = 4;
      h.now = h.now.add(const Duration(minutes: 2));
      h.lb.onLevelSolved();
      await settle();
      expect(h.backend.deletes, ['fr']);
      expect(h.backend.writes.last, ('en', 'Bobdu13', 4));
      expect(h.backend.docs['fr'], isEmpty);
    });
  });

  group('interrupteur à distance', () {
    test('valeur du document', () {
      expect(progressLeaderboardEnabledFrom(null), isFalse, reason: 'document absent');
      expect(progressLeaderboardEnabledFrom({}), isFalse, reason: 'champ absent');
      expect(progressLeaderboardEnabledFrom({kProgressSwitchField: 'true'}), isFalse);
      expect(progressLeaderboardEnabledFrom({kProgressSwitchField: 1}), isFalse);
      expect(progressLeaderboardEnabledFrom({kProgressSwitchField: false}), isFalse);
      expect(progressLeaderboardEnabledFrom({kProgressSwitchField: true}), isTrue);
    });

    test('illisible ou hors ligne : cache, sinon désactivé', () {
      expect(resolveProgressLeaderboardEnabled(), isFalse);
      expect(resolveProgressLeaderboardEnabled(fetched: null, cached: true), isTrue);
      expect(resolveProgressLeaderboardEnabled(fetched: false, cached: true), isFalse);
      expect(resolveProgressLeaderboardEnabled(fetched: true, cached: false), isTrue);
    });

    test('hors ligne sans cache : désactivé, aucune écriture, inscription impossible', () async {
      final h = Harness();
      h.backend.enabledAnswer = null;
      h.score = 5;
      await h.lb.restore();
      await h.lb.startup();
      expect(h.lb.enabled, isFalse);
      expect(await h.lb.join('Bobdu13'), ProgressJoinResult.failed);
      h.lb.onLevelSolved();
      expect(await h.lb.loadBoard(), isNull);
      await settle();
      expect(h.backend.writes, isEmpty);
      expect(h.lb.participating, isFalse);
    });

    test('valeur gardée en cache pour le lancement suivant', () async {
      final h = Harness();
      await h.lb.startup();
      expect(h.lb.enabled, isTrue);
      h.backend.enabledAnswer = null; // hors ligne au lancement suivant
      final relance = h.make();
      await relance.restore();
      expect(relance.enabled, isTrue, reason: 'avant même la lecture du serveur');
      await relance.startup();
      expect(relance.enabled, isTrue);
    });

    test('document absent : désactivé, même avec un cache allumé', () async {
      final h = Harness();
      await h.lb.startup();
      h.backend.enabledAnswer = false;
      final relance = h.make();
      await relance.restore();
      await relance.startup();
      expect(relance.enabled, isFalse);
      final encore = h.make();
      await encore.restore();
      expect(encore.enabled, isFalse);
    });

    test('éteint à distance : plus aucune écriture', () async {
      final h = Harness();
      await h.joined(s: 3);
      h.backend.enabledAnswer = false;
      await h.lb.startup();
      expect(h.lb.enabled, isFalse);
      h.now = h.now.add(const Duration(minutes: 5));
      h.score = 9;
      h.lb.onLevelSolved();
      await settle();
      expect(h.backend.writes.length, 1);
    });
  });

  group('pseudo', () {
    test('filtre du Multijoueur et longueur 1-20', () {
      expect(isProgressPseudoValid(''), isFalse);
      expect(isProgressPseudoValid('   '), isFalse);
      expect(isProgressPseudoValid('Bobdu13'), isTrue);
      expect(isProgressPseudoValid('  Bobdu13  '), isTrue);
      expect(isProgressPseudoValid('gros con'), isFalse);
      expect(isProgressPseudoValid('www.monsite.com'), isFalse);
      expect(isProgressPseudoValid('06 12 34 56 78'), isFalse);
      expect(isProgressPseudoValid('a' * 20), isTrue);
      expect(isProgressPseudoValid('a' * 21), isFalse);
      for (final p in ['Bobdu13', 'gros con', 'f.u.c.k', 'Constance']) {
        expect(isProgressPseudoValid(p), isNicknameAcceptable(p), reason: p);
      }
    });

    test('pseudo refusé : rien ne part, toujours pas inscrit', () async {
      final h = Harness();
      h.score = 4;
      await h.lb.startup();
      expect(await h.lb.join('sale con'), ProgressJoinResult.refused);
      expect(h.lb.participating, isFalse);
      expect(h.backend.writes, isEmpty);
    });

    test('pseudo affiché : filet de sécurité sur les lignes du serveur', () {
      expect(progressDisplayPseudo('Bobdu13', 'fr'), 'Bobdu13');
      expect(progressDisplayPseudo('connard', 'fr'), AppSettings.kDefaultPlayerNameFr);
      expect(progressDisplayPseudo('', 'en'), AppSettings.kDefaultPlayerNameUs);
    });

    test('pseudo prérempli : « Ton pseudo » de l’accueil, sinon « Cinéphile »', () {
      expect(suggestedProgressPseudo(playerId: '#123456', locale: 'fr'), 'Cinéphile');
      expect(suggestedProgressPseudo(playerId: '#123456', locale: 'en'), 'Cinephile');
      expect(suggestedProgressPseudo(playerId: '  ', locale: 'fr'), 'Cinéphile');
      expect(suggestedProgressPseudo(playerId: 'Bobdu13', locale: 'fr'), 'Bobdu13');
      expect(suggestedProgressPseudo(playerId: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', locale: 'fr').length,
          kProgressPseudoMaxLength);
    });

    test('pseudo publié : identifiant filtré, jamais « #123456 »', () {
      expect(progressPublishedPseudo('Bobdu13', 'fr'), 'Bobdu13');
      expect(progressPublishedPseudo('#123456', 'fr'), 'Cinéphile');
      expect(progressPublishedPseudo('#123456', 'en'), 'Cinephile');
      expect(progressPublishedPseudo('gros con', 'fr'), 'Cinéphile');
      expect(progressPublishedPseudo('www.monsite.com', 'en'), 'Cinephile');
    });

    test('pseudo choisi dans la fenêtre du classement = pseudo de l’accueil', () async {
      final h = Harness();
      await h.joined(pseudo: 'Bobdu13', s: 3);
      expect(h.playerId, 'Bobdu13');
      expect(h.lb.pseudo, 'Bobdu13');
    });

    test('« Cinéphile » accepté tel quel : l’identifiant « #123456 » ne change pas', () async {
      final h = Harness();
      await h.joined(pseudo: 'Cinéphile', s: 3);
      expect(h.backend.writes.single, ('fr', 'Cinéphile', 3));
      expect(h.playerId, '#123456');
    });

    test('pseudo changé depuis l’accueil : publié à la prochaine écriture, sans écriture en plus', () async {
      final h = Harness();
      await h.joined(pseudo: 'Bobdu13', s: 3);
      h.playerId = 'Robert'; // champ « Ton pseudo » de l'accueil
      await settle();
      expect(h.backend.writes.length, 1, reason: 'aucune écriture pour un simple changement de pseudo');
      expect(h.lb.pseudo, 'Robert');

      h.now = h.now.add(const Duration(minutes: 2));
      h.score = 4;
      h.lb.onLevelSolved();
      await settle();
      expect(h.backend.writes.last, ('fr', 'Robert', 4));

      // Refusé par le filtre : c'est le pseudo par défaut qui part.
      h.playerId = 'gros con';
      h.now = h.now.add(const Duration(minutes: 2));
      h.score = 5;
      h.lb.onLevelSolved();
      await settle();
      expect(h.backend.writes.last, ('fr', 'Cinéphile', 5));
      expect(h.backend.writes.length, 3);
    });
  });

  group('rangs', () {
    test('ex aequo : même rang', () {
      final ranked = rankRows([
        row('a', 'A', 30),
        row('b', 'B', 30),
        row('c', 'C', 20),
        row('d', 'D', 10),
        row('e', 'E', 10),
        row('f', 'F', 5),
      ]);
      expect([for (final r in ranked) r.rank], [1, 1, 3, 4, 4, 6]);
      expect(rankFromTop(ranked, 10), 4);
      expect(rankFromTop(ranked, 7), isNull);
    });

    test('tranches pour la mesure', () {
      expect(rankBucket(null), 'none');
      expect(rankBucket(1), 'top10');
      expect(rankBucket(50), 'top50');
      expect(rankBucket(51), 'top100');
      expect(rankBucket(1000), 'top1000');
      expect(rankBucket(1234), 'more');
    });

    test('noms des événements : jamais réservés', () {
      for (final name in ['leaderboard_open', 'leaderboard_join', 'leaderboard_leave']) {
        expect(AnalyticsService.isReservedName(name), isFalse, reason: name);
      }
    });
  });

  group('participation', () {
    test('inscription puis retrait : document supprimé partout, mesure', () async {
      final h = Harness();
      await h.joined(s: 3);
      expect(h.analytics.events, ['join']);
      await h.lb.leave();
      expect(h.lb.participating, isFalse);
      expect(h.lb.pendingDelete, isFalse);
      expect(h.backend.deletes.toSet(), {'fr', 'en'});
      expect(h.backend.docs['fr'], isEmpty);
      expect(h.analytics.events, ['join', 'leave']);
    });

    test('retrait hors ligne : retenté au lancement suivant', () async {
      final h = Harness();
      await h.joined(s: 3);
      h.backend.failDeletes = true;
      await h.lb.leave();
      expect(h.lb.participating, isFalse);
      expect(h.lb.pendingDelete, isTrue);
      h.backend.failDeletes = false;
      final relance = h.make();
      await relance.restore();
      await relance.startup();
      expect(relance.pendingDelete, isFalse);
      expect(h.backend.docs['fr'], isEmpty);
    });

    test('inscription avec 0 niveau : rien ne part avant le premier niveau', () async {
      final h = Harness();
      await h.joined(s: 0);
      expect(h.backend.writes, isEmpty);
      h.score = 1;
      h.lb.onLevelSolved();
      await settle();
      expect(h.backend.writes, [('fr', 'Bobdu13', 1)]);
    });

    test('inscription hors ligne : refusée proprement', () async {
      final h = Harness();
      h.score = 3;
      await h.lb.startup();
      h.backend.failWrites = true;
      expect(await h.lb.join('Bobdu13'), ProgressJoinResult.failed);
      expect(h.lb.participating, isFalse);
    });

    test('changement de pseudo dans le classement : même score, réécrit, accueil aussi', () async {
      final h = Harness();
      await h.joined(s: 3);
      expect(await h.lb.join('Robert'), ProgressJoinResult.ok);
      expect(h.backend.writes.last, ('fr', 'Robert', 3));
      expect(h.playerId, 'Robert');
      expect(h.analytics.events, ['join'], reason: 'un changement de pseudo n’est pas une inscription');
    });

    test('inscription échouée : le pseudo de l’accueil ne change pas', () async {
      final h = Harness();
      h.score = 3;
      await h.lb.startup();
      h.backend.failWrites = true;
      expect(await h.lb.join('Bobdu13'), ProgressJoinResult.failed);
      expect(h.playerId, '#123456');
    });

    test('document retrouvé en ligne (réinstallation) : repris', () async {
      final h = Harness();
      h.backend.docs['fr']!['moi'] = (pseudo: 'Ancien', score: 40);
      h.playerId = 'Ancien';
      h.score = 2;
      await h.lb.startup();
      final view = await h.lb.loadBoard();
      expect(view, isNotNull);
      expect(h.lb.participating, isTrue);
      expect(h.backend.lastBoardScore, 40);
      expect(h.backend.writes, isEmpty, reason: 'score local plus bas : rien ne part');
    });

    test('retrait possible interrupteur éteint', () async {
      final h = Harness();
      await h.joined(s: 3);
      h.backend.enabledAnswer = false;
      await h.lb.startup();
      expect(h.lb.enabled, isFalse);
      expect(h.lb.participating, isTrue);
      await h.lb.leave();
      expect(h.lb.participating, isFalse);
      expect(h.backend.deletes.toSet(), {'fr', 'en'});
      expect(h.backend.docs['fr'], isEmpty);
    });

    test('vue : joueur non inscrit compté dans le total, sa ligne marquée', () async {
      final h = Harness();
      h.score = 25;
      h.backend.board = ProgressBoardData(
        top: rankRows([row('x', 'Alice', 60), row('y', 'Bob', 30)]),
        above: [row('y', 'Bob', 30, rank: 2)],
        total: 2,
        myRank: 3,
      );
      await h.lb.startup();
      final view = (await h.lb.loadBoard())!;
      expect(view.joined, isFalse);
      expect(view.myRank, 3);
      expect(view.total, 3);
      expect(view.top.any((r) => r.isMe), isFalse);
      expect(h.analytics.events.last, 'open:top10:0');
    });

    test('vue : joueur inscrit repéré dans le top', () async {
      final h = Harness();
      await h.joined(s: 30);
      h.backend.board = ProgressBoardData(
        top: rankRows([row('x', 'Alice', 60), row('moi', 'Bobdu13', 30)]),
        above: [row('x', 'Alice', 60, rank: 1)],
        total: 2,
        myRank: 2,
      );
      final view = (await h.lb.loadBoard())!;
      expect(view.total, 2);
      expect(view.top.where((r) => r.isMe).single.pseudo, 'Bobdu13');
      expect(h.analytics.events.last, 'open:top10:1');
    });

    test('hors ligne à l’ouverture : null, mesuré « offline »', () async {
      final h = Harness();
      await h.lb.startup();
      h.backend.failReads = true;
      expect(await h.lb.loadBoard(), isNull);
      expect(h.analytics.events.last, 'open:offline:0');
    });
  });

  group('écrans', () {
    Future<Harness> pumpBoard(WidgetTester tester,
        {required String locale, bool joined = false, bool introSeen = true, Size size = const Size(360, 640)}) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final h = Harness()..locale = locale;
      h.score = 153;
      h.backend.board = ProgressBoardData(
        top: rankRows([
          for (var i = 0; i < 50; i++) row('u$i', 'Joueur$i', 300 - i * 2),
        ]),
        above: [row('a1', 'Alice', 160, rank: 120), row('a2', 'Bobdu13', 156, rank: 121), row('a3', 'Chloé', 154, rank: 122)],
        // Inscrit, le joueur est déjà compté par le serveur ; sinon il est
        // ajouté au total affiché.
        total: joined ? 4567 : 4566,
        myRank: 123,
      );
      final settings = AppSettings(saveService: h.saveService)..locale = locale;
      h.settings = settings;
      await h.lb.startup();
      if (joined) await h.lb.join('Moi');
      if (introSeen) h.lb.markIntroSeen();
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider<ProgressLeaderboard>.value(value: h.lb),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale(locale),
          home: const ProgressLeaderboardScreen(),
        ),
      ));
      // Chargement (faux serveur immédiat) : quelques images suffisent, sans
      // jamais attendre la fin d'un flux ni l'arrêt de l'indicateur.
      for (var i = 0; i < 5; i++) {
        await tester.pump();
      }
      return h;
    }

    testWidgets('classement : top 50, 3 joueurs au-dessus, ma ligne et « 123e sur 4 567 »', (tester) async {
      final h = await pumpBoard(tester, locale: 'fr', joined: true);
      expect(tester.takeException(), isNull);
      expect(find.text('Joueur0'), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Chloé'), findsOneWidget);
      expect(find.text('16-3'), findsOneWidget, reason: 'ma ligne : 153 niveaux');
      expect(find.text('Moi'), findsOneWidget, reason: 'mon pseudo = celui de l’accueil');
      expect(h.settings!.playerId, 'Moi');
      final rankText = tester.widget<Text>(find.byKey(const ValueKey('lbRankOf'))).data!;
      expect(rankText, startsWith('123e sur 4'));
      expect(rankText.replaceAll(RegExp(r'\s'), ''), '123esur4567');
      expect(find.byKey(const ValueKey('lbLeave')), findsOneWidget);
      expect(find.byKey(const ValueKey('lbJoinButton')), findsNothing);
    });

    testWidgets('anglais, petit écran : pas de débordement', (tester) async {
      await pumpBoard(tester, locale: 'en', size: const Size(320, 568));
      expect(tester.takeException(), isNull);
      expect(find.text('#123 of 4,567'), findsOneWidget, reason: 'non inscrit : compté dans le total');
      expect(find.byKey(const ValueKey('lbJoinButton')), findsOneWidget);
    });

    testWidgets('première ouverture : proposition d’apparaître, pseudo refusé puis « Pas maintenant »',
        (tester) async {
      final h = await pumpBoard(tester, locale: 'fr', introSeen: false);
      expect(find.byType(ProgressPseudoDialog), findsOneWidget);
      expect(h.lb.introSeen, isTrue);
      final field = tester.widget<TextField>(find.byKey(const ValueKey('lbPseudoField')));
      expect(field.controller!.text, 'Cinéphile', reason: 'identifiant jamais personnalisé');
      await tester.enterText(find.byKey(const ValueKey('lbPseudoField')), 'gros con');
      await tester.ensureVisible(find.byKey(const ValueKey('lbPseudoConfirm')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('lbPseudoConfirm')));
      await tester.pump();
      expect(find.byKey(const ValueKey('lbPseudoError')), findsOneWidget);
      expect(h.backend.writes, isEmpty);
      await tester.ensureVisible(find.byKey(const ValueKey('lbPseudoCancel')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('lbPseudoCancel')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(ProgressPseudoDialog), findsNothing);
      expect(h.lb.participating, isFalse);
    });

    Future<void> pumpHome(WidgetTester tester, ProgressLeaderboard lb) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final saveService = SaveService();
      final settings = AppSettings(saveService: saveService)..posterHome = true;
      final game = GameState(adService: AdService(), saveService: saveService, settings: settings)
        ..clock = () => DateTime(2026, 11, 20);
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: StreakState(saveService: saveService)),
          ChangeNotifierProvider.value(value: game),
          ChangeNotifierProvider<ProgressLeaderboard>.value(value: lb),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: HomeScreen(onPlay: () {}),
        ),
      ));
      await tester.pump();
    }

    Future<Harness> pumpSettings(WidgetTester tester, {required bool joined}) async {
      await tester.binding.setSurfaceSize(const Size(400, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final h = Harness();
      final settings = AppSettings(saveService: h.saveService);
      h.settings = settings;
      h.score = 3;
      await h.lb.startup();
      if (joined) expect(await h.lb.join('Bobdu13'), ProgressJoinResult.ok);
      // Puis l'interrupteur est éteint à distance.
      h.backend.enabledAnswer = false;
      await h.lb.startup();
      expect(h.lb.enabled, isFalse);
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(
              value: GameState(adService: AdService(), saveService: h.saveService, settings: settings)),
          Provider.value(value: h.saveService),
          Provider.value(value: CloudSyncService()),
          ChangeNotifierProvider<ProgressLeaderboard>.value(value: h.lb),
        ],
        child: const MaterialApp(
          locale: Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SettingsScreen()),
        ),
      ));
      await tester.pump();
      return h;
    }

    testWidgets('Réglages, interrupteur éteint : « Me retirer du classement » reste possible', (tester) async {
      final h = await pumpSettings(tester, joined: true);
      final button = find.byKey(const ValueKey('settingsLeaveLeaderboard'));
      expect(button, findsOneWidget);
      await tester.ensureVisible(button);
      await tester.pump();
      await tester.tap(button);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(const ValueKey('lbLeaveConfirm')));
      for (var i = 0; i < 5; i++) {
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 300));
      expect(h.lb.participating, isFalse);
      expect(h.backend.deletes.toSet(), {'fr', 'en'});
      expect(h.backend.docs['fr'], isEmpty);
      expect(find.byKey(const ValueKey('settingsLeaveLeaderboard')), findsNothing);
      // Le message « C'est fait » s'efface tout seul.
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('Réglages, interrupteur éteint, jamais inscrit : rien ne s’affiche', (tester) async {
      await pumpSettings(tester, joined: false);
      expect(find.byKey(const ValueKey('settingsLeaveLeaderboard')), findsNothing);
      expect(find.text('Me retirer du classement'), findsNothing);
    });

    testWidgets('accueil : trophée seulement si l’interrupteur est allumé', (tester) async {
      final eteint = Harness();
      eteint.backend.enabledAnswer = false;
      await eteint.lb.startup();
      await pumpHome(tester, eteint.lb);
      expect(find.byKey(const ValueKey('homeLeaderboardButton')), findsNothing);

      final allume = Harness();
      await allume.lb.startup();
      await pumpHome(tester, allume.lb);
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('homeLeaderboardButton')), findsOneWidget);
    });
  });
}
