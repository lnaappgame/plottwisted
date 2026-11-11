import 'package:cine_devinette/services/tcf_consent.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TcfConsent.analyticsAllowedFrom', () {
    test('hors RGPD (pas de chaîne, ou gdprApplies = 0) : autorisé, comme avant', () {
      expect(TcfConsent.analyticsAllowedFrom(), isTrue);
      expect(TcfConsent.analyticsAllowedFrom(gdprApplies: 0, purposeConsents: '0000000000'), isTrue);
    });

    test('RGPD : autorisé seulement avec les finalités 1 ET 8', () {
      expect(TcfConsent.analyticsAllowedFrom(gdprApplies: 1, purposeConsents: '1111111111'), isTrue);
      expect(TcfConsent.analyticsAllowedFrom(gdprApplies: 1, purposeConsents: '1000000100'), isTrue);
      expect(TcfConsent.analyticsAllowedFrom(gdprApplies: 1, purposeConsents: '1111111011'), isFalse); // 8 refusée
      expect(TcfConsent.analyticsAllowedFrom(gdprApplies: 1, purposeConsents: '0111111111'), isFalse); // 1 refusée
    });

    test("RGPD : refus total, chaîne vide ou trop courte = pas d'Analytics", () {
      expect(TcfConsent.analyticsAllowedFrom(gdprApplies: 1, purposeConsents: '0000000000'), isFalse);
      expect(TcfConsent.analyticsAllowedFrom(gdprApplies: 1, purposeConsents: ''), isFalse);
      expect(TcfConsent.analyticsAllowedFrom(gdprApplies: 1), isFalse);
      expect(TcfConsent.analyticsAllowedFrom(gdprApplies: 1, purposeConsents: '1111111'), isFalse);
    });
  });
}
