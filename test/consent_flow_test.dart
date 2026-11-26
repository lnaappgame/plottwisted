// Règle C7 (1.0.16) : déclencheurs de la fenêtre de consentement et mise en
// mémoire des événements d'avant la réponse. Modèle : le Clos (3845025, d17a7b3).
import 'package:cine_devinette/services/analytics_service.dart';
import 'package:cine_devinette/services/consent_flow.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('déclencheurs (consentFlow)', () {
    late ConsentGate gate;
    late List<(String, int)> prompts;
    late int opened;
    var seconds = 0;

    setUp(() {
      gate = ConsentGate();
      prompts = [];
      opened = 0;
      seconds = 0;
    });

    Future<void> run({
      required bool settled,
      bool alreadySucceeded = false,
      Duration pollEvery = const Duration(milliseconds: 5),
      int fallbackSeconds = 180,
    }) =>
        consentFlow(
          gate: gate,
          settled: () async => settled,
          finish: () async => opened++,
          log: (t, s) => prompts.add((t, s)),
          playSeconds: () => seconds,
          alreadySucceeded: alreadySucceeded,
          fallbackSeconds: fallbackSeconds,
          pollEvery: pollEvery,
        );

    test('statut déjà réglé : tout démarre tout de suite, sans attendre une réussite', () async {
      await run(settled: true);
      expect(prompts, [(kConsentAlreadySet, 0)]);
      expect(opened, 1);
      expect(gate.waiting, isFalse);
    });

    test('statut non réglé : la fenêtre attend, puis s\'ouvre à la 1re réussite', () async {
      final flow = run(settled: false);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(opened, 0, reason: 'rien ne s\'ouvre avant la réussite');
      expect(gate.waiting, isTrue);
      seconds = 42;
      gate.firstSuccess();
      await flow;
      expect(prompts, [(kConsentFirstSuccess, 42)]);
      expect(opened, 1);
      expect(gate.waiting, isFalse);
    });

    test('la 1re vidéo demandée ouvre la fenêtre, et la vidéo attend la réponse', () async {
      final flow = run(settled: false);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(gate.waiting, isTrue);
      gate.askNow();
      await gate.decided;
      await flow;
      expect(prompts.single.$1, kConsentVideo);
      expect(opened, 1);
    });

    test('secours : après consent_fallback_seconds de jeu au premier plan', () async {
      final flow = run(settled: false, fallbackSeconds: 180);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(opened, 0);
      seconds = 179;
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(opened, 0, reason: '179 s de jeu : pas encore');
      seconds = 180;
      await flow;
      expect(prompts, [(kConsentFallback, 180)]);
      expect(opened, 1);
    });

    test('joueur qui a déjà réussi une énigme : fenêtre tout de suite', () async {
      await run(settled: false, alreadySucceeded: true);
      expect(prompts.single.$1, kConsentFirstSuccess);
      expect(opened, 1);
    });

    test('lecture du statut qui plante : même chemin que « non réglé », jamais bloquant', () async {
      final flow = consentFlow(
        gate: gate,
        settled: () => Future<bool>.error(StateError('UMP')),
        finish: () async => opened++,
        log: (t, s) => prompts.add((t, s)),
        playSeconds: () => seconds,
        alreadySucceeded: true,
      );
      await flow;
      expect(opened, 1);
      expect(gate.decidedAlready, isTrue);
    });
  });

  group('événements avant la réponse (AnalyticsService)', () {
    late List<String> sent;
    final service = AnalyticsService();

    setUp(() {
      AnalyticsService.resetForTests();
      AnalyticsService.supportedOverride = true;
      sent = [];
      AnalyticsService.sender = (name, params) async => sent.add(name);
    });
    tearDown(AnalyticsService.resetForTests);

    Future<void> settle() => Future<void>.delayed(Duration.zero);

    test('avant la réponse : rien ne part, tout attend en mémoire', () async {
      await service.logTutorialBegin();
      await service.logLevelStart(world: 0, level: 1);
      await settle();
      expect(sent, isEmpty);
      expect(AnalyticsService.waitingCount, 2);
    });

    test('accord : tout part, dans l\'ordre, une seule fois ; les suivants partent directement', () async {
      await service.logTutorialBegin();
      await service.logTutorialStep(step: 1, stepName: 'launch');
      await service.logConsentPrompt(trigger: kConsentFirstSuccess, seconds: 30);
      AnalyticsService.consentDecided(true);
      await settle();
      expect(sent, ['tutorial_begin', 'tutorial_step', 'consent_prompt']);
      expect(AnalyticsService.waitingCount, 0);
      await service.logLevelStart(world: 0, level: 2);
      await settle();
      expect(sent.last, 'level_start');
      AnalyticsService.consentDecided(true);
      await settle();
      expect(sent.length, 4, reason: 'pas de renvoi');
    });

    test('refus : ce qui attendait est effacé, rien ne part, avant comme après', () async {
      await service.logTutorialBegin();
      AnalyticsService.consentDecided(false);
      await settle();
      expect(sent, isEmpty);
      expect(AnalyticsService.waitingCount, 0);
      await service.logLevelStart(world: 1, level: 1);
      await settle();
      expect(sent, isEmpty);
    });

    test('200 événements au plus en mémoire', () async {
      for (var i = 0; i < 250; i++) {
        await service.logLevelStart(world: 1, level: i);
      }
      expect(AnalyticsService.waitingCount, AnalyticsService.maxBeforeConsent);
      AnalyticsService.consentDecided(true);
      await settle();
      expect(sent.length, 200);
    });

    test('jamais un nom réservé de Firebase', () {
      for (final reserved in ['session_start', 'first_open', 'app_update', 'user_engagement', 'screen_view']) {
        expect(AnalyticsService.isReservedName(reserved), isTrue, reason: reserved);
      }
      expect(AnalyticsService.isReservedName('firebase_x'), isTrue);
      expect(AnalyticsService.isReservedName('ga_x'), isTrue);
      // Les noms de la 1.0.16 sont tous permis.
      for (final ok in [
        'tutorial_begin',
        'tutorial_step',
        'tutorial_complete',
        'tutorial_skip',
        'level_start',
        'level_abandon',
        'consent_prompt',
      ]) {
        expect(AnalyticsService.isReservedName(ok), isFalse, reason: ok);
      }
    });

    test('un nom réservé n\'est jamais mis en mémoire ni envoyé', () async {
      AnalyticsService.consentDecided(true);
      // Aucune méthode publique n'émet un nom réservé : on vérifie la règle.
      expect(AnalyticsService.isReservedName('ump_error'), isFalse);
      await service.logTutorialBegin();
      await settle();
      expect(sent.where(AnalyticsService.isReservedName), isEmpty);
    });
  });
}
