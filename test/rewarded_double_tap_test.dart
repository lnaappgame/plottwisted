// Vidéo récompensée : une seule séquence à la fois (AdService.rewardedInProgress).
// Un double toucher ne lance ni deux chargements ni deux vidéos et ne donne
// rien au second appel ; le bouton « Gagner un joker » montre un indicateur
// et ignore les touchers pendant la séquence (consentement, chargement, vidéo).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cine_devinette/services/ad_service.dart';
import 'package:cine_devinette/services/consent_flow.dart';
import 'package:cine_devinette/theme/app_theme.dart';
import 'package:cine_devinette/widgets/joker_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('double toucher pendant la séquence : le 2e appel rend la main tout de suite, sans rien lancer', () async {
    // 1re vidéo demandée avant la réponse au consentement : la séquence attend la réponse.
    final previous = ConsentGate.instance;
    final gate = ConsentGate();
    ConsentGate.instance = gate;
    addTearDown(() => ConsentGate.instance = previous);
    final answer = Completer<void>();
    final flow = consentFlow(
      gate: gate,
      settled: () async => true,
      finish: () => answer.future,
      log: (_, __) {},
      playSeconds: () => 0,
    );

    final ads = AdService();
    final first = ads.showRewardedAdForJoker();
    expect(ads.rewardedInProgress.value, isTrue, reason: 'indicateur dès le 1er toucher');

    var secondDone = false;
    bool? secondResult;
    unawaited(ads.showRewardedAdForJoker().then((r) {
      secondDone = true;
      secondResult = r;
    }));
    await Future<void>.delayed(Duration.zero);
    expect(secondDone, isTrue, reason: 'le 2e toucher n\'attend pas derrière le 1er (pas de 2e vidéo à suivre)');
    expect(secondResult, isFalse, reason: 'rien n\'est donné au 2e toucher');
    expect(ads.rewardedInProgress.value, isTrue, reason: 'la 1re séquence continue');

    answer.complete();
    await flow;
    // Pas de pub dans les tests : la 1re séquence se termine sans récompense, et libère le bouton.
    expect(await first, isFalse);
    expect(ads.rewardedInProgress.value, isFalse);

    // Séquence suivante possible.
    expect(await ads.showRewardedAdForJoker(), isFalse);
    expect(ads.rewardedInProgress.value, isFalse);
  });

  testWidgets('« Gagner un joker » : indicateur et touchers ignorés pendant la séquence', (tester) async {
    final busy = ValueNotifier<bool>(false);
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: WinJokerButton(label: 'GAGNER UN JOKER', colors: const AppColors(false), onTap: () => taps++, busy: busy),
      ),
    ));
    expect(find.byKey(const ValueKey('winJokerLoading')), findsNothing);
    await tester.tap(find.text('GAGNER UN JOKER'));
    expect(taps, 1);

    busy.value = true;
    await tester.pump();
    expect(find.byKey(const ValueKey('winJokerLoading')), findsOneWidget);
    await tester.tap(find.text('GAGNER UN JOKER'));
    await tester.tap(find.text('GAGNER UN JOKER'));
    expect(taps, 1, reason: 'aucun toucher pris pendant la vidéo ou son chargement');

    busy.value = false;
    await tester.pump();
    expect(find.byKey(const ValueKey('winJokerLoading')), findsNothing);
    await tester.tap(find.text('GAGNER UN JOKER'));
    expect(taps, 2);
  });
}
