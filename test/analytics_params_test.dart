// Paramètres envoyés à Firebase Analytics : seulement du texte ou des
// nombres. Un booléen (ancien `bonus` de defi_completed) est refusé par le
// plugin (assertion en debug) : chaque drapeau part en 1 ou 0.
import 'package:flutter_test/flutter_test.dart';

import 'package:cine_devinette/services/analytics_service.dart';

void main() {
  late Map<String, Map<String, Object>> sent;
  final service = AnalyticsService();

  setUp(() {
    AnalyticsService.resetForTests();
    AnalyticsService.supportedOverride = true;
    AnalyticsService.consentDecided(true);
    sent = {};
    AnalyticsService.sender = (name, params) async => sent[name] = params;
  });
  tearDown(AnalyticsService.resetForTests);

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('defi_completed : bonus envoyé en 1 ou 0, jamais en booléen', () async {
    await service.logDefiCompleted(bonus: true, seconds: 42);
    await settle();
    expect(sent['defi_completed'], {'bonus': 1, 'seconds': 42});

    await service.logDefiCompleted(bonus: false, seconds: 7);
    await settle();
    expect(sent['defi_completed'], {'bonus': 0, 'seconds': 7});
  });

  test('aucun événement n\'envoie de booléen (texte ou nombre seulement)', () async {
    for (final flag in [true, false]) {
      await service.logLevelCompleted(world: 1, level: 2, difficulty: 'easy');
      await service.logSkipJokerUsed(world: 1, level: 2);
      await service.logDefiCompleted(bonus: flag, seconds: 3);
      await service.logEnigmeSolved(day: 2);
      await service.logMultiplayerMatchResult(result: 'win', eloApres: 1200);
      await service.logAdWatched(type: 'rewarded');
      await service.logAllContentCompleted(worldCount: 35);
      await service.logPurchase(productId: 'remove_ads');
      await service.logHalloweenPitchSolved(pitch: 3, solved: 4);
      await service.logAdventCaseSolved(day: 5, onTime: flag);
      await service.logWheelSpin(afterAd: flag, segment: 2);
      await service.logTutorialBegin();
      await service.logTutorialStep(step: 1, stepName: 'launch');
      await service.logTutorialComplete(seconds: 90);
      await service.logTutorialSkip(seconds: 10);
      await service.logLevelStart(world: 1, level: 1);
      await service.logLevelAbandon(world: 1, level: 1, seconds: 5, reason: 'postpone');
      await service.logConsentPrompt(trigger: 'video', seconds: 30);
      await service.logLeaderboardOpen(rankBucket: 'top10', joined: flag);
      await service.logLeaderboardJoin();
      await service.logLeaderboardLeave();
      await settle();

      expect(sent.length, 21, reason: 'tous les événements sont partis');
      for (final MapEntry(key: name, value: params) in sent.entries) {
        for (final MapEntry(key: key, value: value) in params.entries) {
          expect(value is String || value is num, isTrue, reason: '$name.$key = $value (${value.runtimeType})');
        }
      }
      expect(sent['defi_completed']!['bonus'], flag ? 1 : 0);
      expect(sent[kAdventCaseSolvedEvent]!['on_time'], flag ? 1 : 0);
      expect(sent['wheel_spin']!['after_ad'], flag ? 1 : 0);
      expect(sent['leaderboard_open']!['joined'], flag ? 1 : 0);
    }
  });
}
