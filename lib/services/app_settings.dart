import 'dart:math';
import 'package:flutter/foundation.dart';
import 'save_service.dart';

const List<String> kAvatarEmojis = [
  '🎬','🕵️','🤠','🕴️','🧙','🥊','🦸','🤖','🏴‍☠️','👽',
  '🧛','🥷','⚔️','🚀','🎭','🎩','🏹','🛸','🐺','🔫',
  '💂','🧝','🎸','🏍️','🛡️','👑','🦹','🎯','🧨','🌟',
];
// Archétypes originaux (détective, cow-boy, astronaute...), jamais de
// personnage protégé ni d'acteur reconnaissable — voir la planche pixel-art
// fournie à part pour la version dessinée de ces avatars.

const int kPlayerIdMaxLength = 20;

class AppSettings extends ChangeNotifier {
  final SaveService saveService;
  AppSettings({required this.saveService});

  bool isLightTheme = false;
  bool sfxOn = true;
  bool vibrationsOn = true;
  bool colorblindMode = false; // palette accessible + repères en formes, pas seulement en couleur
  bool largeText = false; // taille des caractères : petit (faux) / grand (vrai)
  bool dyslexicMode = false; // police pensée pour faciliter la lecture (Lexend)
  // Langue de l'interface ET du contenu des modes de jeu (devinettes,
  // énigmes, défis, multijoueur) — 'fr' ou 'en'. Le contenu n'est bilingue
  // que sur le périmètre "V1" (voir project_us_localization en mémoire) :
  // le reste du catalogue reste FR uniquement en attendant une traduction
  // future.
  String locale = 'fr';
  static const String kDefaultPlayerNameFr = 'Cinéphile';
  static const String kDefaultPlayerNameUs = 'Cinephile';
  String playerName = kDefaultPlayerNameFr;
  String playerId = _genererPlayerId();
  String avatar = kAvatarEmojis.first;
  bool reviewRequested = false; // demande d'avis store : une seule fois par installation

  /// [playerName] tel qu'affiché à l'écran : si le joueur n'a jamais
  /// personnalisé son pseudo (toujours la valeur par défaut FR d'origine),
  /// on l'affiche dans la langue courante plutôt que de rester figé en
  /// français — un pseudo réellement choisi par le joueur, lui, ne change
  /// jamais de langue.
  String get displayPlayerName =>
      playerName == kDefaultPlayerNameFr && locale == 'en' ? kDefaultPlayerNameUs : playerName;

  // Jour (UTC) du tout premier lancement de l'app sur cet appareil — sert
  // d'ancrage personnel à la rotation de Défi du jour (voir defiIndexFor()
  // dans defi_service.dart), pour que le défi 1 tombe le jour de CE
  // lancement plutôt qu'une date globale partagée entre tous les joueurs.
  // Comme playerId, la valeur par défaut capture "maintenant" à la
  // construction ; si une sauvegarde existe déjà, restore() la remplace par
  // la vraie date d'origine plutôt que de la réinitialiser à chaque lancement.
  DateTime firstLaunchDay = _utcToday();

  // Identifiant façon "tag joueur" généré une fois à l'installation, puis
  // conservé tel quel via toJson/restore (sinon il changerait à chaque
  // redémarrage, avant même le premier restore()).
  static String _genererPlayerId() => '#${100000 + Random().nextInt(900000)}';

  static DateTime _utcToday() {
    final u = DateTime.now().toUtc();
    return DateTime.utc(u.year, u.month, u.day);
  }

  bool _restoring = false;

  @override
  void notifyListeners() {
    super.notifyListeners();
    if (!_restoring) saveService.saveSettings(toJson());
  }

  void toggleTheme() { isLightTheme = !isLightTheme; notifyListeners(); }
  void toggleSfx() { sfxOn = !sfxOn; notifyListeners(); }
  void toggleVibrations() { vibrationsOn = !vibrationsOn; notifyListeners(); }
  void toggleColorblindMode() { colorblindMode = !colorblindMode; notifyListeners(); }
  void setLargeText(bool value) { largeText = value; notifyListeners(); }
  void toggleDyslexicMode() { dyslexicMode = !dyslexicMode; notifyListeners(); }
  void setAvatar(String emoji) { avatar = emoji; notifyListeners(); }
  void setLocale(String value) { locale = value; notifyListeners(); }

  void setPlayerId(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    playerId = trimmed.length > kPlayerIdMaxLength ? trimmed.substring(0, kPlayerIdMaxLength) : trimmed;
    notifyListeners();
  }

  /// true la toute première fois qu'on l'appelle (et seulement alors) — pour
  /// ne déclencher la demande d'avis qu'une fois par installation.
  bool consumeReviewRequestPending() {
    if (reviewRequested) return false;
    reviewRequested = true;
    notifyListeners();
    return true;
  }

  Map<String, dynamic> toJson() => {
        'isLightTheme': isLightTheme,
        'sfxOn': sfxOn,
        'vibrationsOn': vibrationsOn,
        'colorblindMode': colorblindMode,
        'largeText': largeText,
        'dyslexicMode': dyslexicMode,
        'locale': locale,
        'playerName': playerName,
        'playerId': playerId,
        'avatar': avatar,
        'reviewRequested': reviewRequested,
        'firstLaunchDay': firstLaunchDay.toIso8601String(),
      };

  /// Charge les préférences sauvegardées, s'il y en a. À appeler une seule
  /// fois au démarrage, avant que l'UI ne soit affichée.
  Future<void> restore() async {
    final data = await saveService.loadSettings();
    if (data == null) return;
    _restoring = true;
    isLightTheme = data['isLightTheme'] as bool? ?? isLightTheme;
    sfxOn = data['sfxOn'] as bool? ?? sfxOn;
    vibrationsOn = data['vibrationsOn'] as bool? ?? vibrationsOn;
    colorblindMode = data['colorblindMode'] as bool? ?? colorblindMode;
    largeText = data['largeText'] as bool? ?? largeText;
    dyslexicMode = data['dyslexicMode'] as bool? ?? dyslexicMode;
    locale = data['locale'] as String? ?? locale;
    playerName = data['playerName'] as String? ?? playerName;
    playerId = data['playerId'] as String? ?? playerId;
    avatar = data['avatar'] as String? ?? avatar;
    reviewRequested = data['reviewRequested'] as bool? ?? reviewRequested;
    final fld = data['firstLaunchDay'] as String?;
    if (fld != null) {
      final parsed = DateTime.tryParse(fld);
      if (parsed != null) firstLaunchDay = parsed;
    }
    _restoring = false;
  }
}
