// Protection contre les clics en rafale (1.0.16) : après 3 clics sur des pubs
// dans la même journée, plus d'interstitielle jusqu'au lendemain ; le compteur
// est gardé d'un lancement à l'autre et repart à zéro chaque jour.
import 'package:cine_devinette/services/ad_click_guard.dart';
import 'package:cine_devinette/services/ad_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('3 clics dans la journée : les interstitielles sont bloquées jusqu\'au lendemain', () async {
    var now = DateTime(2026, 11, 27, 10);
    final guard = AdClickGuard(now: () => now);
    expect(guard.interstitialsBlocked, isFalse);
    await guard.recordClick();
    await guard.recordClick();
    expect(guard.clicksToday, 2);
    expect(guard.interstitialsBlocked, isFalse, reason: '2 clics : encore permis');
    await guard.recordClick();
    expect(guard.interstitialsBlocked, isTrue);
    // Le soir même : toujours bloqué.
    now = DateTime(2026, 11, 27, 23, 59);
    expect(guard.interstitialsBlocked, isTrue);
    // Le lendemain : compteur à zéro.
    now = DateTime(2026, 11, 28, 0, 1);
    expect(guard.clicksToday, 0);
    expect(guard.interstitialsBlocked, isFalse);
  });

  test('le compteur survit à un nouveau lancement (sinon il suffirait de relancer le jeu)', () async {
    final now = DateTime(2026, 11, 27, 18);
    final first = AdClickGuard(now: () => now);
    for (var i = 0; i < AdClickGuard.maxClicksPerDay; i++) {
      await first.recordClick();
    }
    final relaunched = AdClickGuard(now: () => now);
    await relaunched.load();
    expect(relaunched.clicksToday, 3);
    expect(relaunched.interstitialsBlocked, isTrue);
  });

  test('un compteur de la veille, relu au lancement, ne bloque rien', () async {
    final yesterday = AdClickGuard(now: () => DateTime(2026, 11, 27, 22));
    for (var i = 0; i < 5; i++) {
      await yesterday.recordClick();
    }
    final today = AdClickGuard(now: () => DateTime(2026, 11, 28, 8));
    await today.load();
    expect(today.interstitialsBlocked, isFalse);
    await today.recordClick();
    expect(today.clicksToday, 1, reason: 'le jour repart de zéro, pas de la veille');
  });

  test('valeur gardée illisible : on repart de zéro, sans planter', () async {
    SharedPreferences.setMockInitialValues({'ad_click_guard_v1': 'n\'importe quoi'});
    final guard = AdClickGuard(now: () => DateTime(2026, 11, 27));
    await guard.load();
    expect(guard.interstitialsBlocked, isFalse);
  });

  test('AdService : le plafond ne touche que l\'interstitielle, la vidéo reste demandable', () async {
    final guard = AdClickGuard(now: () => DateTime(2026, 11, 27, 12));
    for (var i = 0; i < 3; i++) {
      await guard.recordClick();
    }
    final ads = AdService(clickGuard: guard);
    // Sur l'hôte de test les pubs ne sont pas prises en charge : rien ne
    // s'affiche, mais l'appel ne plante pas et la garde reste celle du jour.
    await ads.showForcedAd();
    expect(await ads.showRewardedAdForJoker(), isFalse);
    expect(ads.clickGuard.interstitialsBlocked, isTrue);
    expect(ads.adsHeld, isFalse);
  });
}
