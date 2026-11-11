import 'package:cine_devinette/services/nickname_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isNicknameAcceptable', () {
    test('accepte les vrais pseudos, y compris ceux qui contiennent une racine courte', () {
      for (final ok in [
        'Cinéphile',
        'Constance',
        'Faucon42',
        'Technique',
        'Le député',
        'Hitchcock',
        'Moby Dick',
        'ConAir',
        'Scunthorpe',
        'R2D2',
        'Agent 007',
        'Amélie Poulain',
        'Tarantino_fan',
      ]) {
        expect(isNicknameAcceptable(ok), isTrue, reason: ok);
      }
    });

    test('refuse les insultes FR/EN, mot par mot', () {
      for (final ko in ['gros con', 'Connard', 'SALOPE', 'fdp', 'fuck you', 'bitch', 'Merde alors']) {
        expect(isNicknameAcceptable(ko), isFalse, reason: ko);
      }
    });

    test('refuse les variantes leet, accentuées ou masquées', () {
      for (final ko in ['c0nnard', 'f.u.c.k', 'sal_ope', 'enculé', 'b1tch', 'Fuuck'.replaceAll('uu', 'u')]) {
        expect(isNicknameAcceptable(ko), isFalse, reason: ko);
      }
    });

    test('refuse liens, e-mails et numéros de téléphone', () {
      for (final ko in ['www.monsite', 'http://x', 'moi@mail', 'promo.com', '06 12 34 56 78', '0612345678']) {
        expect(isNicknameAcceptable(ko), isFalse, reason: ko);
      }
    });

    test('refuse le vide', () {
      expect(isNicknameAcceptable('   '), isFalse);
    });
  });
}
