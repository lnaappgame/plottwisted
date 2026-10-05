import 'package:audioplayers/audioplayers.dart';

/// Effets sonores courts (tap lettre, bonne/mauvaise réponse). Chaque appel
/// utilise un lecteur jetable pour ne pas couper le son précédent en cas de
/// déclenchements rapprochés (ex. saisie rapide de plusieurs lettres).
class SoundService {
  Future<void> playTap() => _play('sounds/tap.wav');
  Future<void> playCorrect() => _play('sounds/correct.wav');
  Future<void> playWrong() => _play('sounds/wrong.wav');

  // Lecteur dédié et réutilisé, en mode faible latence : le son doit tomber
  // pile au moment où la latte du clap se referme à l'écran.
  AudioPlayer? _clapPlayer;

  Future<void> playClap() async {
    final player = _clapPlayer ??= AudioPlayer();
    try {
      await player.stop();
      await player.play(AssetSource('sounds/clap.wav'), mode: PlayerMode.lowLatency);
    } catch (_) {
      // Lecture best-effort, comme les autres effets.
    }
  }

  Future<void> _play(String asset) async {
    final player = AudioPlayer();
    try {
      await player.play(AssetSource(asset));
      player.onPlayerComplete.first.then((_) => player.dispose());
    } catch (_) {
      // Lecture best-effort : ignore (ex. autoplay bloqué par le navigateur).
      player.dispose();
    }
  }
}
