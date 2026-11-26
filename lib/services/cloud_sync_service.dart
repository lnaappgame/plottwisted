import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:google_sign_in/google_sign_in.dart';
import 'account_deletion.dart';

export 'account_deletion.dart' show AccountDeletionOutcome, AccountDeletionReport;

/// Résultat du flux "lier mon compte Google" (voir [CloudSyncService.connectGoogleAccount]).
enum AccountLinkResult {
  /// Le compte anonyme actuel vient d'être lié à ce compte Google — c'est la
  /// première fois que ce compte Google est utilisé avec l'app.
  linkedNew,

  /// Ce compte Google était déjà lié à un autre appareil : la session a basculé
  /// sur ce compte existant. L'appelant doit alors restaurer la sauvegarde
  /// cloud associée (voir [CloudSyncService.restore]).
  restoredExisting,

  /// Le joueur a annulé le sélecteur de compte Google.
  cancelled,

  error,
}

/// Sauvegarde en ligne avec un compte Google proposée dans les Paramètres :
/// Android seulement pour la sortie. Sur iPhone, la règle 4.8 d'Apple
/// imposerait de proposer aussi « Se connecter avec Apple » à côté de
/// Google : masquée en attendant que ce soit ajouté.
bool get cloudBackupAvailable => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// Sauvegarde/restauration de la progression via un compte Google lié à
/// l'identifiant Firebase anonyme existant — pour ne pas perdre sa
/// progression en changeant de téléphone ou en réinstallant l'app. Jamais
/// bloquant : toute erreur réseau laisse simplement le joueur en mode
/// local-only, comme avant cette fonctionnalité.
///
/// Nécessite, côté console Firebase (pas du code) : activer "Google" comme
/// fournisseur de connexion (Authentication → Sign-in method) et
/// redéplacer `google-services.json` une fois fait — voir le README.
class CloudSyncService {
  bool _googleInitialized = false;

  bool get _supported =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize();
    _googleInitialized = true;
  }

  Future<void> _ensureFirebaseReady() async {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  }

  /// `true` si le compte actuellement connecté est lié à une identité Google
  /// (donc que sa progression peut être restaurée sur un autre appareil).
  ///
  /// Firebase.initializeApp() se lance en tâche de fond après l'intro (voir
  /// main.dart, pour ne pas retarder le splash) : si l'écran Réglages
  /// s'ouvre avant que ça se termine, FirebaseAuth.instance lève une
  /// exception ("No Firebase App '[DEFAULT]'..."), ce qui plantait le build
  /// entier de la Dialog (écran vide). Ce getter est appelé directement
  /// depuis build(), sans try/catch possible autour — d'où ce garde-fou.
  bool get isLinked {
    if (Firebase.apps.isEmpty) return false;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    return user.providerData.any((p) => p.providerId == 'google.com');
  }

  /// L'adresse e-mail du compte Google lié, ou `null` si non lié.
  String? get linkedEmail {
    if (Firebase.apps.isEmpty) return null;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    for (final p in user.providerData) {
      if (p.providerId == 'google.com') return p.email;
    }
    return null;
  }

  /// Lance le sélecteur de compte Google, puis :
  /// - lie ce compte à l'identifiant anonyme actuel s'il est encore libre
  ///   ([AccountLinkResult.linkedNew]) ;
  /// - bascule sur le compte existant s'il était déjà lié ailleurs
  ///   ([AccountLinkResult.restoredExisting]) — l'appelant doit alors
  ///   appeler [restore] et écraser la sauvegarde locale avec son résultat.
  Future<AccountLinkResult> connectGoogleAccount() async {
    if (!_supported) return AccountLinkResult.error;
    try {
      await _ensureGoogleInitialized();
      await _ensureFirebaseReady();

      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) return AccountLinkResult.error;
      final credential = GoogleAuthProvider.credential(idToken: idToken);

      try {
        await FirebaseAuth.instance.currentUser!.linkWithCredential(credential);
        return AccountLinkResult.linkedNew;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'credential-already-in-use' || e.code == 'email-already-in-use') {
          await FirebaseAuth.instance.signInWithCredential(credential);
          return AccountLinkResult.restoredExisting;
        }
        return AccountLinkResult.error;
      }
    } on GoogleSignInException catch (e) {
      return e.code == GoogleSignInExceptionCode.canceled ? AccountLinkResult.cancelled : AccountLinkResult.error;
    } catch (_) {
      return AccountLinkResult.error;
    }
  }

  /// Sauvegarde l'intégralité des données locales fournies vers Firestore,
  /// sous le compte actuellement connecté. Retourne `true` en cas de succès.
  /// Jamais pendant la suppression du compte : la sauvegarde automatique (app
  /// mise en arrière-plan, par exemple par le sélecteur de compte Google)
  /// recréerait `backups/{uid}` juste après sa suppression.
  Future<bool> backup(Map<String, dynamic> allLocalData) async {
    if (!_supported || _deletingAccount) return false;
    try {
      await _ensureFirebaseReady();
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return false;
      await FirebaseFirestore.instance.collection('backups').doc(uid).set({
        ...allLocalData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Récupère la dernière sauvegarde connue pour le compte actuellement
  /// connecté, ou `null` si aucune (nouveau joueur, ou pas encore de backup).
  Future<Map<String, dynamic>?> restore() async {
    if (!_supported) return null;
    try {
      await _ensureFirebaseReady();
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return null;
      final doc = await FirebaseFirestore.instance.collection('backups').doc(uid).get();
      if (!doc.exists) return null;
      return doc.data();
    } catch (_) {
      return null;
    }
  }

  bool _deletingAccount = false;

  /// Suppression du compte en cours (aucune sauvegarde ne part).
  bool get deletingAccount => _deletingAccount;

  static const _deletionTimeout = Duration(seconds: 10);

  /// « Supprimer ma sauvegarde et me déconnecter » (Réglages, compte Google
  /// lié) : efface `backups/{uid}`, l'entrée du classement des joueurs
  /// ([leaveLeaderboard], le retrait existant, vrai s'il a réussi),
  /// `multiplayer_players/{uid}`, puis le compte Firebase, et enfin la
  /// connexion Google. Ordre et tolérance aux erreurs : voir
  /// [runAccountDeletion]. La partie locale n'est pas touchée.
  ///
  /// Après coup, `currentUser` vaut null : les services qui en ont besoin
  /// (classements, Multijoueur, sauvegarde) recréent un identifiant anonyme
  /// au premier appel (`signInAnonymously` quand `currentUser == null`).
  Future<AccountDeletionReport> deleteAccount({Future<bool> Function()? leaveLeaderboard}) async {
    if (!_supported || Firebase.apps.isEmpty) return const AccountDeletionReport(AccountDeletionOutcome.failed);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const AccountDeletionReport(AccountDeletionOutcome.failed);
    final uid = user.uid;
    final db = FirebaseFirestore.instance;
    _deletingAccount = true;
    try {
      return await runAccountDeletion(AccountDeletionSteps(
        deleteBackup: () => db.collection('backups').doc(uid).delete().timeout(_deletionTimeout),
        deleteLeaderboardEntries: () async {
          if (leaveLeaderboard == null) return;
          if (!await leaveLeaderboard()) throw StateError('classement des joueurs non effacé');
        },
        deleteMultiplayerProfile: () => db.collection('multiplayer_players').doc(uid).delete().timeout(_deletionTimeout),
        deleteUser: () async {
          final current = FirebaseAuth.instance.currentUser;
          // Jamais un autre compte que celui des données effacées ci-dessus.
          if (current == null || current.uid != uid) throw StateError('compte changé pendant la suppression');
          try {
            await current.delete();
            return UserDeletionStatus.done;
          } on FirebaseAuthException catch (e) {
            if (e.code == 'requires-recent-login') return UserDeletionStatus.requiresRecentLogin;
            rethrow;
          }
        },
        reauthenticate: () => _reauthenticateWithGoogle(uid),
        disconnectGoogle: () async {
          await _ensureGoogleInitialized();
          await GoogleSignIn.instance.disconnect();
        },
      ));
    } finally {
      _deletingAccount = false;
    }
  }

  /// Firebase demande une connexion récente pour supprimer le compte : le
  /// sélecteur Google s'ouvre, le joueur choisit le même compte, puis la
  /// session Firebase est reconfirmée avec ce jeton.
  Future<ReauthStatus> _reauthenticateWithGoogle(String uid) async {
    try {
      await _ensureGoogleInitialized();
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) return ReauthStatus.failed;
      final current = FirebaseAuth.instance.currentUser;
      if (current == null || current.uid != uid) return ReauthStatus.failed;
      // Un autre compte Google que celui lié : Firebase refuse (user-mismatch).
      await current.reauthenticateWithCredential(GoogleAuthProvider.credential(idToken: idToken));
      return ReauthStatus.ok;
    } on GoogleSignInException catch (e) {
      return e.code == GoogleSignInExceptionCode.canceled ? ReauthStatus.cancelled : ReauthStatus.failed;
    } catch (_) {
      return ReauthStatus.failed;
    }
  }
}
