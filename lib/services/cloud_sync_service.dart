import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:google_sign_in/google_sign_in.dart';

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
  bool get isLinked {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    return user.providerData.any((p) => p.providerId == 'google.com');
  }

  /// L'adresse e-mail du compte Google lié, ou `null` si non lié.
  String? get linkedEmail {
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
  Future<bool> backup(Map<String, dynamic> allLocalData) async {
    if (!_supported) return false;
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
}
