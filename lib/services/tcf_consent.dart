import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_android/shared_preferences_android.dart';

/// Consentement Analytics lu dans la réponse du joueur à la fenêtre RGPD
/// (UMP de Google, norme IAB TCF v2.2) — 1.0.13.
///
/// Avant : Analytics suivait `canRequestAds`, vrai dès que le popup était
/// répondu, MÊME en cas de refus. Désormais, pour un joueur soumis au RGPD
/// (`IABTCF_gdprApplies` = 1), Analytics n'est activé que s'il a accepté :
/// - la finalité 1 (stocker / lire des informations sur l'appareil) ;
/// - la finalité 8 (mesurer la performance du contenu) — la « mesure ».
/// Hors RGPD (pas de chaîne TCF, ou gdprApplies = 0) : inchangé.
///
/// UMP écrit ces clés dans les préférences par défaut de l'application
/// (Android : SharedPreferences par défaut ; iOS : NSUserDefaults standard),
/// d'où la lecture sans préfixe via [SharedPreferencesAsync].
class TcfConsent {
  TcfConsent._();

  /// Règle pure, testée : Analytics autorisé pour ces valeurs TCF ?
  @visibleForTesting
  static bool analyticsAllowedFrom({int? gdprApplies, String? purposeConsents}) {
    if (gdprApplies != 1) return true;
    final p = purposeConsents ?? '';
    bool accepte(int finalite) => p.length >= finalite && p[finalite - 1] == '1';
    return accepte(1) && accepte(8);
  }

  /// Lit les valeurs TCF stockées par UMP. En cas d'erreur de lecture pour
  /// un joueur dont on ne sait rien, on retombe sur l'ancien comportement
  /// (la décision `canRequestAds` reste le premier verrou).
  static Future<bool> analyticsAllowed() async {
    try {
      final prefs = SharedPreferencesAsync(
        options: defaultTargetPlatform == TargetPlatform.android
            ? const SharedPreferencesAsyncAndroidOptions(
                backend: SharedPreferencesAndroidBackendLibrary.SharedPreferences,
              )
            : const SharedPreferencesOptions(),
      );
      final gdprApplies = await prefs.getInt('IABTCF_gdprApplies');
      final purposes = await prefs.getString('IABTCF_PurposeConsents');
      return analyticsAllowedFrom(gdprApplies: gdprApplies, purposeConsents: purposes);
    } catch (e) {
      debugPrint('TcfConsent: $e');
      return true;
    }
  }

  /// Active ou coupe la collecte Analytics selon le consentement courant.
  /// Appelé au démarrage (après le popup) et à la fermeture du formulaire
  /// « Options de confidentialité des pubs » des Réglages.
  static Future<void> applyToAnalytics({required bool canRequestAds}) async {
    final enabled = canRequestAds && await analyticsAllowed();
    try {
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(enabled);
    } catch (_) {}
  }
}
