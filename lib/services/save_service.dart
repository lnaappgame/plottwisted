import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Sauvegarde locale de la progression (monde/niveau/jokers), pour que le
/// joueur retrouve exactement où il en était même après avoir complètement
/// fermé l'application. Ne persiste pas la grille en cours d'un puzzle
/// précis (lettres déjà placées) : à la réouverture, le niveau en cours
/// redémarre "propre", mais la progression (monde, niveau, jokers, paliers,
/// couleurs déjà rencontrées) est intacte.
class SaveService {
  static const _key = 'cine_devinette_save_v1';
  static const _settingsKey = 'cine_devinette_settings_v1';
  static const _enigmeKey = 'cine_devinette_enigme_v1';
  static const _defiKey = 'cine_devinette_defi_v1';
  static const _multiplayerKey = 'cine_devinette_multiplayer_v1';
  static const _streakKey = 'cine_devinette_streak_v1';

  Future<void> save(Map<String, dynamic> data) => _write(_key, data);
  Future<Map<String, dynamic>?> load() => _read(_key);

  Future<void> saveSettings(Map<String, dynamic> data) => _write(_settingsKey, data);
  Future<Map<String, dynamic>?> loadSettings() => _read(_settingsKey);

  Future<void> saveEnigme(Map<String, dynamic> data) => _write(_enigmeKey, data);
  Future<Map<String, dynamic>?> loadEnigme() => _read(_enigmeKey);

  Future<void> saveDefi(Map<String, dynamic> data) => _write(_defiKey, data);
  Future<Map<String, dynamic>?> loadDefi() => _read(_defiKey);

  Future<void> saveMultiplayer(Map<String, dynamic> data) => _write(_multiplayerKey, data);
  Future<Map<String, dynamic>?> loadMultiplayer() => _read(_multiplayerKey);

  Future<void> saveStreak(Map<String, dynamic> data) => _write(_streakKey, data);
  Future<Map<String, dynamic>?> loadStreak() => _read(_streakKey);

  // ─── Sauvegarde/restauration groupée (voir CloudSyncService) — un seul
  // document Firestore contenant une copie de toutes les clés locales, pour
  // retrouver sa progression sur un nouvel appareil. ───
  static const Map<String, String> _toutesLesCles = {
    'save': _key,
    'settings': _settingsKey,
    'enigme': _enigmeKey,
    'defi': _defiKey,
    'multiplayer': _multiplayerKey,
    'streak': _streakKey,
  };

  Future<Map<String, dynamic>> readAllForBackup() async {
    final result = <String, dynamic>{};
    for (final entry in _toutesLesCles.entries) {
      final data = await _read(entry.value);
      if (data != null) result[entry.key] = data;
    }
    return result;
  }

  Future<void> writeAllFromBackup(Map<String, dynamic> backup) async {
    for (final entry in _toutesLesCles.entries) {
      final data = backup[entry.key];
      if (data is Map) {
        await _write(entry.value, Map<String, dynamic>.from(data));
      }
    }
  }

  Future<void> _write(String key, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(data));
  }

  Future<Map<String, dynamic>?> _read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
