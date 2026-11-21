import 'package:shared_preferences/shared_preferences.dart';

/// Protection contre les clics en rafale sur les pubs (1.0.16, accord de
/// Damien le 20/11).
///
/// Après [maxClicksPerDay] clics sur des pubs dans la même journée, plus
/// aucune pub plein écran (interstitielle) n'est montrée jusqu'au lendemain.
/// La vidéo avec récompense reste disponible : c'est le joueur qui la demande.
///
/// Pourquoi : le 16/11, 170 clics pour 110 interstitielles affichées en
/// France sur Android ; un clic en rafale met en danger le compte AdMob commun
/// à tous les jeux du studio.
///
/// Le compteur est gardé d'un lancement à l'autre (sinon il suffirait de
/// relancer le jeu) et repart à zéro chaque jour (jour local de l'appareil).
class AdClickGuard {
  static const maxClicksPerDay = 3;
  static const _prefsKey = 'ad_click_guard_v1';

  final DateTime Function() _now;
  SharedPreferences? _prefs;
  String _day = '';
  int _count = 0;

  AdClickGuard({DateTime Function()? now}) : _now = now ?? DateTime.now;

  static String dayKey(DateTime t) =>
      '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

  /// Relit le compteur gardé sur l'appareil. Jamais bloquant : sans lecture
  /// possible, le compteur repart de zéro.
  Future<void> load() async {
    try {
      final prefs = _prefs ??= await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;
      final parts = raw.split('|');
      if (parts.length != 2) return;
      _day = parts[0];
      _count = int.tryParse(parts[1]) ?? 0;
    } catch (_) {}
  }

  /// Clics comptés aujourd'hui (0 si le dernier compte date d'un autre jour).
  int get clicksToday => _day == dayKey(_now()) ? _count : 0;

  /// Plus d'interstitielle aujourd'hui : le plafond est atteint.
  bool get interstitialsBlocked => clicksToday >= maxClicksPerDay;

  /// Un clic sur une pub (interstitielle ou vidéo) vient d'être signalé.
  Future<void> recordClick() async {
    final today = dayKey(_now());
    if (_day != today) {
      _day = today;
      _count = 0;
    }
    _count++;
    try {
      final prefs = _prefs ??= await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, '$_day|$_count');
    } catch (_) {}
  }
}
