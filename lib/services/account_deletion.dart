import 'package:flutter/foundation.dart' show debugPrint;

// Suppression du compte depuis les Réglages (règle Google Play, 1.0.16) :
// « Supprimer ma sauvegarde et me déconnecter ».
//
// La connexion Google des Réglages lie l'utilisateur Firebase anonyme à
// google.com et écrit `backups/{uid}` : pour Play, c'est une création de
// compte, qui doit pouvoir être supprimée depuis l'appli. Ordre imposé :
//  1. `backups/{uid}` ;
//  2. `progress_leaderboard_fr/{uid}` et `_en/{uid}` (retrait du classement) ;
//  3. `multiplayer_players/{uid}` (fiche Elo) ;
//  4. le compte Firebase lui-même (`currentUser.delete()`), avec une nouvelle
//     authentification Google si Firebase la demande ;
//  5. la déconnexion Google (`disconnect`).
//
// Chaque suppression Firestore tolère « document absent » et « permission
// refusée » (et toute autre erreur) sans bloquer la suite : elle est notée
// dans [AccountDeletionReport.leftovers]. La suppression du compte n'est
// jamais sautée. `enigme_leaderboard` et `multiplayer_runs` ne sont pas
// supprimables par l'appli (règles) : la page web l'explique.
//
// La partie locale reste sur le téléphone ; l'appli continue de fonctionner
// et reçoit un nouvel identifiant anonyme au prochain besoin (classements,
// Multijoueur, nouvelle sauvegarde).

enum AccountDeletionOutcome {
  /// Compte supprimé, toutes les données en ligne effacées.
  deleted,

  /// Compte supprimé, mais au moins une suppression Firestore a échoué :
  /// le joueur est renvoyé vers la page web pour finir.
  deletedWithLeftovers,

  /// Firebase demande une connexion récente et Google n'a pas reconfirmé
  /// l'identité (annulé, autre compte choisi, erreur) : compte NON supprimé.
  needsRecentLogin,

  /// Compte NON supprimé (hors ligne, erreur inattendue).
  failed,
}

/// Réponse de `currentUser.delete()`.
enum UserDeletionStatus { done, requiresRecentLogin }

/// Réponse de la nouvelle authentification Google.
enum ReauthStatus { ok, cancelled, failed }

/// Étapes nommées, dans l'ordre (pour [AccountDeletionReport.leftovers]).
const kDeletionStepBackup = 'backups';
const kDeletionStepLeaderboard = 'progress_leaderboard';
const kDeletionStepMultiplayer = 'multiplayer_players';

class AccountDeletionReport {
  final AccountDeletionOutcome outcome;

  /// Suppressions Firestore qui ont échoué (voir les constantes kDeletionStep*).
  final List<String> leftovers;

  const AccountDeletionReport(this.outcome, [this.leftovers = const []]);

  bool get accountDeleted =>
      outcome == AccountDeletionOutcome.deleted || outcome == AccountDeletionOutcome.deletedWithLeftovers;
}

/// Les opérations réelles (Firestore, Firebase Auth, Google), remplacées par
/// des fausses dans les tests.
class AccountDeletionSteps {
  final Future<void> Function() deleteBackup;
  final Future<void> Function() deleteLeaderboardEntries;
  final Future<void> Function() deleteMultiplayerProfile;

  /// Lève une exception pour toute erreur autre que « connexion récente
  /// requise » (réseau...).
  final Future<UserDeletionStatus> Function() deleteUser;
  final Future<ReauthStatus> Function() reauthenticate;
  final Future<void> Function() disconnectGoogle;

  const AccountDeletionSteps({
    required this.deleteBackup,
    required this.deleteLeaderboardEntries,
    required this.deleteMultiplayerProfile,
    required this.deleteUser,
    required this.reauthenticate,
    required this.disconnectGoogle,
  });
}

/// Enchaîne les étapes dans l'ordre imposé (voir en tête de fichier).
Future<AccountDeletionReport> runAccountDeletion(AccountDeletionSteps steps) async {
  final leftovers = <String>[];

  Future<void> tolerant(String name, Future<void> Function() op) async {
    try {
      await op();
    } catch (e) {
      debugPrint('Suppression du compte : $name non effacé ($e)');
      leftovers.add(name);
    }
  }

  await tolerant(kDeletionStepBackup, steps.deleteBackup);
  await tolerant(kDeletionStepLeaderboard, steps.deleteLeaderboardEntries);
  await tolerant(kDeletionStepMultiplayer, steps.deleteMultiplayerProfile);

  // Le compte : jamais sauté, quoi qu'il soit arrivé aux données.
  try {
    var status = await steps.deleteUser();
    if (status == UserDeletionStatus.requiresRecentLogin) {
      ReauthStatus reauth;
      try {
        reauth = await steps.reauthenticate();
      } catch (_) {
        reauth = ReauthStatus.failed;
      }
      if (reauth != ReauthStatus.ok) {
        return AccountDeletionReport(AccountDeletionOutcome.needsRecentLogin, leftovers);
      }
      status = await steps.deleteUser();
      if (status != UserDeletionStatus.done) {
        return AccountDeletionReport(AccountDeletionOutcome.needsRecentLogin, leftovers);
      }
    }
  } catch (e) {
    debugPrint('Suppression du compte : compte non supprimé ($e)');
    return AccountDeletionReport(AccountDeletionOutcome.failed, leftovers);
  }

  // Compte supprimé : la déconnexion Google est un plus, jamais un échec.
  try {
    await steps.disconnectGoogle();
  } catch (e) {
    debugPrint('Suppression du compte : déconnexion Google impossible ($e)');
  }
  return AccountDeletionReport(
    leftovers.isEmpty ? AccountDeletionOutcome.deleted : AccountDeletionOutcome.deletedWithLeftovers,
    leftovers,
  );
}
