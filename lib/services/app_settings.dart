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

/// Avatars dessinés (voir AvatarView) gagnés pendant l'event Halloween :
/// tête de citrouille au premier film trouvé, citrouille en feu pour les 10.
const kPumpkinAvatar = 'pumpkin';
const kFirePumpkinAvatar = 'pumpkin_fire';
const kEventAvatars = [kPumpkinAvatar, kFirePumpkinAvatar];

const int kPlayerIdMaxLength = 20;

/// Demandes d'avis store par installation, et écart minimal entre deux.
const kMaxReviewRequests = 2;
const kReviewRequestGap = Duration(days: 21);

class AppSettings extends ChangeNotifier {
  final SaveService saveService;
  AppSettings({required this.saveService});

  bool isLightTheme = false;
  // Accueil « Affiche » : l'écran d'accueil en jaune, comme la fiche des
  // stores (le reste du jeu garde son thème). Activé pour une nouvelle
  // installation ; une sauvegarde d'avant la 1.0.12 le garde désactivé.
  bool posterHome = true;
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
  Set<String> unlockedAvatars = {}; // avatars d'event gagnés (kEventAvatars)
  // Demande d'avis store : au plus [kMaxReviewRequests] fois par
  // installation, espacées d'au moins [kReviewRequestGap].
  int reviewRequestCount = 0;
  DateTime? lastReviewRequest;

  // Saisie des lettres dans le jeu principal, l'énigme et le multijoueur :
  // 'tiles' (tuiles mélangées, par défaut), 'azerty' ou 'qwerty' (clavier
  // à l'écran, lettres proposées en surbrillance).
  String inputMode = 'tiles';
  bool inputModeTipShown = false; // conseil « tuiles ou clavier » déjà montré (une seule fois)

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
  void togglePosterHome() { posterHome = !posterHome; notifyListeners(); }
  void toggleSfx() { sfxOn = !sfxOn; notifyListeners(); }
  void toggleVibrations() { vibrationsOn = !vibrationsOn; notifyListeners(); }
  void toggleColorblindMode() { colorblindMode = !colorblindMode; notifyListeners(); }
  void setLargeText(bool value) { largeText = value; notifyListeners(); }
  void toggleDyslexicMode() { dyslexicMode = !dyslexicMode; notifyListeners(); }
  void setAvatar(String emoji) { avatar = emoji; notifyListeners(); }

  bool isAvatarUnlocked(String id) => unlockedAvatars.contains(id);

  /// Débloque un avatar d'event ; true seulement s'il ne l'était pas encore.
  bool unlockAvatar(String id) {
    if (!unlockedAvatars.add(id)) return false;
    notifyListeners();
    return true;
  }
  void setLocale(String value) { locale = value; notifyListeners(); }
  void setInputMode(String value) { inputMode = value; notifyListeners(); }
  void markInputModeTipShown() { inputModeTipShown = true; notifyListeners(); }

  void setPlayerId(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    playerId = trimmed.length > kPlayerIdMaxLength ? trimmed.substring(0, kPlayerIdMaxLength) : trimmed;
    notifyListeners();
  }

  /// true si une demande d'avis peut partir maintenant (et la compte) : au
  /// plus [kMaxReviewRequests] par installation, espacées d'au moins
  /// [kReviewRequestGap]. Les stores filtrent aussi de leur côté (l'App
  /// Store n'affiche la fenêtre que 3 fois par an).
  bool consumeReviewRequestPending({DateTime? now}) {
    final t = now ?? DateTime.now();
    if (reviewRequestCount >= kMaxReviewRequests) return false;
    final last = lastReviewRequest;
    if (last != null && t.difference(last) < kReviewRequestGap) return false;
    reviewRequestCount++;
    lastReviewRequest = t;
    notifyListeners();
    return true;
  }

  Map<String, dynamic> toJson() => {
        'isLightTheme': isLightTheme,
        'posterHome': posterHome,
        'sfxOn': sfxOn,
        'vibrationsOn': vibrationsOn,
        'colorblindMode': colorblindMode,
        'largeText': largeText,
        'dyslexicMode': dyslexicMode,
        'locale': locale,
        'playerName': playerName,
        'playerId': playerId,
        'avatar': avatar,
        'unlockedAvatars': unlockedAvatars.toList(),
        'reviewRequestCount': reviewRequestCount,
        'lastReviewRequest': lastReviewRequest?.toIso8601String(),
        'inputMode': inputMode,
        'inputModeTipShown': inputModeTipShown,
        'firstLaunchDay': firstLaunchDay.toIso8601String(),
      };

  /// Charge les préférences sauvegardées, s'il y en a. À appeler une seule
  /// fois au démarrage, avant que l'UI ne soit affichée.
  /// Recharge l'état depuis la sauvegarde locale, après une restauration
  /// cloud : sans ça, la sauvegarde automatique à la fermeture de l'app
  /// réécrivait l'ancien état encore en mémoire par-dessus les données restaurées.
  Future<void> reloadFromSave() async {
    await restore();
    notifyListeners();
  }

  Future<void> restore() async {
    final data = await saveService.loadSettings();
    if (data == null) return;
    _restoring = true;
    isLightTheme = data['isLightTheme'] as bool? ?? isLightTheme;
    // Absent d'une sauvegarde d'avant la 1.0.12 : le joueur garde l'accueil
    // qu'il connaît.
    posterHome = data['posterHome'] as bool? ?? false;
    sfxOn = data['sfxOn'] as bool? ?? sfxOn;
    vibrationsOn = data['vibrationsOn'] as bool? ?? vibrationsOn;
    colorblindMode = data['colorblindMode'] as bool? ?? colorblindMode;
    largeText = data['largeText'] as bool? ?? largeText;
    dyslexicMode = data['dyslexicMode'] as bool? ?? dyslexicMode;
    locale = data['locale'] as String? ?? locale;
    final mode = data['inputMode'] as String?;
    inputMode = const ['tiles', 'azerty', 'qwerty'].contains(mode) ? mode! : 'tiles';
    inputModeTipShown = data['inputModeTipShown'] as bool? ?? false;
    playerName = data['playerName'] as String? ?? playerName;
    playerId = data['playerId'] as String? ?? playerId;
    avatar = data['avatar'] as String? ?? avatar;
    unlockedAvatars = ((data['unlockedAvatars'] as List?) ?? const []).whereType<String>().toSet();
    // Un avatar d'event jamais gagné (sauvegarde trafiquée, restauration
    // partielle) ne reste pas affiché.
    if (kEventAvatars.contains(avatar) && !unlockedAvatars.contains(avatar)) avatar = kAvatarEmojis.first;
    // Avant la 1.0.11 : un simple booléen, une seule demande par installation.
    reviewRequestCount =
        data['reviewRequestCount'] as int? ?? (data['reviewRequested'] == true ? 1 : reviewRequestCount);
    final lastReview = data['lastReviewRequest'] as String?;
    lastReviewRequest = lastReview == null ? null : DateTime.tryParse(lastReview);
    final fld = data['firstLaunchDay'] as String?;
    if (fld != null) {
      final parsed = DateTime.tryParse(fld);
      if (parsed != null) firstLaunchDay = parsed;
    }
    _restoring = false;
  }
}
