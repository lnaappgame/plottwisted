import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

/// Effets sonores courts (tap lettre, bonne/mauvaise réponse).
///
/// Un petit tourniquet de lecteurs réutilisés : plusieurs sons rapprochés
/// (saisie rapide de lettres) ne se coupent pas, et le nombre de lecteurs
/// natifs reste borné. En 1.0.15, un lecteur jetable était créé à chaque son
/// et jamais libéré quand la plateforme échouait : chez un joueur, Android
/// refusait l'audio (MEDIA_ERROR_UNKNOWN -19) et chaque son laissait une
/// erreur non rattrapée, comptée comme plantage dans Crashlytics.
class SoundService {
  static const int _taille = 4;

  final List<AudioPlayer?> _lecteurs = List<AudioPlayer?>.filled(_taille, null);
  int _suivant = 0;

  Future<void> playTap() => _play('sounds/tap.wav');
  Future<void> playCorrect() => _play('sounds/correct.wav');
  Future<void> playWrong() => _play('sounds/wrong.wav');

  // Lecteur dédié et réutilisé, en mode faible latence : le son doit tomber
  // pile au moment où la latte du clap se referme à l'écran.
  AudioPlayer? _clapPlayer;

  Future<void> playClap() async {
    final player = _clapPlayer ??= _nouveauLecteur(() => _clapPlayer = null);
    try {
      await player.stop();
      await player.play(AssetSource('sounds/clap.wav'), mode: PlayerMode.lowLatency);
    } catch (_) {
      // Lecture best-effort, comme les autres effets.
    }
  }

  Future<void> _play(String asset) async {
    final i = _suivant;
    _suivant = (_suivant + 1) % _taille;
    final player = _lecteurs[i] ??= _nouveauLecteur(() => _lecteurs[i] = null);
    try {
      await player.play(AssetSource(asset));
    } catch (_) {
      // Lecture best-effort : ignore (ex. autoplay bloqué par le navigateur).
    }
  }

  /// Crée un lecteur dont les erreurs de la plateforme sont rattrapées.
  ///
  /// audioplayers remonte ces erreurs par `eventStream` ; un `.first` ou un
  /// `await` posé sur ce flux sans gestionnaire d'erreur devenait une erreur
  /// asynchrone non rattrapée. À la première erreur, le lecteur est libéré et
  /// son emplacement vidé (`oublier`) : le prochain son en recrée un propre.
  AudioPlayer _nouveauLecteur(void Function() oublier) {
    final player = AudioPlayer();
    // Le jeu ne lit jamais la position : on coupe le suivi par image, dont les
    // appels à getCurrentPosition() ne rattrapent pas les erreurs de la plateforme
    // (trouvé par le Jardin dans audioplayers 6.x).
    player.positionUpdater = null;
    player.eventStream.listen(
      (_) {},
      onError: (Object _, [StackTrace? __]) {
        oublier();
        unawaited(player.dispose().catchError((_) {}));
      },
      cancelOnError: true,
    );
    return player;
  }
}
