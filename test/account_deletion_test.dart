// Suppression du compte (Réglages, règle Google Play, 1.0.16) : ordre des
// étapes, tolérance des suppressions Firestore, compte jamais sauté, nouvelle
// authentification Google quand Firebase la demande. Voir
// lib/services/account_deletion.dart.
import 'package:flutter_test/flutter_test.dart';

import 'package:cine_devinette/services/account_deletion.dart';

/// Fausses étapes : notent l'ordre d'appel, échouent sur demande.
class _Steps {
  final List<String> calls = [];
  final Set<String> failing = {};

  /// Réponses successives de `currentUser.delete()` (la dernière se répète).
  List<UserDeletionStatus> userAnswers = [UserDeletionStatus.done];
  Object? userError;
  ReauthStatus reauthAnswer = ReauthStatus.ok;
  bool reauthThrows = false;
  bool disconnectThrows = false;
  int _userCalls = 0;

  Future<void> _firestore(String name) async {
    calls.add(name);
    if (failing.contains(name)) throw Exception('permission-denied');
  }

  AccountDeletionSteps build() => AccountDeletionSteps(
        deleteBackup: () => _firestore('backups'),
        deleteLeaderboardEntries: () => _firestore('progress_leaderboard'),
        deleteMultiplayerProfile: () => _firestore('multiplayer_players'),
        deleteUser: () async {
          calls.add('user');
          if (userError != null) throw userError!;
          final i = _userCalls < userAnswers.length ? _userCalls : userAnswers.length - 1;
          _userCalls++;
          return userAnswers[i];
        },
        reauthenticate: () async {
          calls.add('reauth');
          if (reauthThrows) throw Exception('sélecteur Google en erreur');
          return reauthAnswer;
        },
        disconnectGoogle: () async {
          calls.add('disconnect');
          if (disconnectThrows) throw Exception('disconnect');
        },
      );
}

void main() {
  test('ordre imposé : sauvegarde, classement, Multijoueur, compte, puis Google', () async {
    final s = _Steps();
    final report = await runAccountDeletion(s.build());
    expect(s.calls, ['backups', 'progress_leaderboard', 'multiplayer_players', 'user', 'disconnect']);
    expect(report.outcome, AccountDeletionOutcome.deleted);
    expect(report.leftovers, isEmpty);
    expect(report.accountDeleted, isTrue);
  });

  test('suppressions Firestore refusées ou absentes : la suite continue, le compte est supprimé', () async {
    final s = _Steps()..failing.addAll({'backups', 'multiplayer_players'});
    final report = await runAccountDeletion(s.build());
    expect(s.calls, ['backups', 'progress_leaderboard', 'multiplayer_players', 'user', 'disconnect']);
    expect(report.outcome, AccountDeletionOutcome.deletedWithLeftovers);
    expect(report.leftovers, [kDeletionStepBackup, kDeletionStepMultiplayer]);
    expect(report.accountDeleted, isTrue);
  });

  test('toutes les suppressions Firestore en échec : le compte n\'est jamais sauté', () async {
    final s = _Steps()..failing.addAll({'backups', 'progress_leaderboard', 'multiplayer_players'});
    final report = await runAccountDeletion(s.build());
    expect(s.calls, contains('user'));
    expect(report.outcome, AccountDeletionOutcome.deletedWithLeftovers);
    expect(report.leftovers, [kDeletionStepBackup, kDeletionStepLeaderboard, kDeletionStepMultiplayer]);
  });

  test('connexion récente requise : Google reconfirme, puis le compte est supprimé', () async {
    final s = _Steps()..userAnswers = [UserDeletionStatus.requiresRecentLogin, UserDeletionStatus.done];
    final report = await runAccountDeletion(s.build());
    expect(s.calls,
        ['backups', 'progress_leaderboard', 'multiplayer_players', 'user', 'reauth', 'user', 'disconnect']);
    expect(report.outcome, AccountDeletionOutcome.deleted);
  });

  test('connexion récente requise, sélecteur Google annulé : compte gardé, Google pas déconnecté', () async {
    final s = _Steps()
      ..userAnswers = [UserDeletionStatus.requiresRecentLogin]
      ..reauthAnswer = ReauthStatus.cancelled;
    final report = await runAccountDeletion(s.build());
    expect(s.calls.where((c) => c == 'user'), hasLength(1));
    expect(s.calls, isNot(contains('disconnect')));
    expect(report.outcome, AccountDeletionOutcome.needsRecentLogin);
    expect(report.accountDeleted, isFalse);
  });

  test('connexion récente requise, autre compte Google ou erreur : le joueur est prévenu', () async {
    for (final s in [
      _Steps()
        ..userAnswers = [UserDeletionStatus.requiresRecentLogin]
        ..reauthAnswer = ReauthStatus.failed,
      _Steps()
        ..userAnswers = [UserDeletionStatus.requiresRecentLogin]
        ..reauthThrows = true,
    ]) {
      final report = await runAccountDeletion(s.build());
      expect(report.outcome, AccountDeletionOutcome.needsRecentLogin);
      expect(s.calls, isNot(contains('disconnect')));
    }
  });

  test('reconfirmé mais Firebase redemande une connexion récente : prévenu, pas de boucle', () async {
    final s = _Steps()..userAnswers = [UserDeletionStatus.requiresRecentLogin];
    final report = await runAccountDeletion(s.build());
    expect(s.calls.where((c) => c == 'reauth'), hasLength(1));
    expect(s.calls.where((c) => c == 'user'), hasLength(2));
    expect(report.outcome, AccountDeletionOutcome.needsRecentLogin);
  });

  test('compte impossible à supprimer (hors ligne) : échec, Google pas déconnecté', () async {
    final s = _Steps()..userError = Exception('network-request-failed');
    final report = await runAccountDeletion(s.build());
    expect(report.outcome, AccountDeletionOutcome.failed);
    expect(report.accountDeleted, isFalse);
    expect(s.calls, isNot(contains('disconnect')));
  });

  test('déconnexion Google en erreur : le compte reste supprimé', () async {
    final s = _Steps()..disconnectThrows = true;
    final report = await runAccountDeletion(s.build());
    expect(report.outcome, AccountDeletionOutcome.deleted);
  });
}
