import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Écran de lancement : lit une vidéo embarquée (le teaser "PLOT TWIST(ed)"
/// fourni directement par l'utilisateur — papier déchiré qui s'assemble,
/// titre qui se révèle) plutôt que de la recréer en direct via un
/// CustomPainter. Portage natif abandonné après plusieurs allers-retours sur
/// le cadrage/la fluidité/la fidélité des couleurs (voir mémoire projet) —
/// une vidéo pré-enregistrée garantit les trois d'un coup.
///
/// [assets/video/intro_teaser.mp4] est le fichier de référence fourni par
/// l'utilisateur, ré-encodé à 1072×1920 (au lieu de 1080×1920) : une largeur
/// non multiple de 16 force le décodeur matériel à recadrer un macrobloc de
/// bord, et le décodeur AVC matériel de cet appareil (MediaTek) corrompt
/// visiblement ce recadrage par intermittence (blocs, cadrage décalé, teintes
/// délavées) — confirmé en comparant un enregistrement d'écran de
/// l'utilisateur montrant le défaut à l'écran d'accueil. 1072 est le multiple
/// de 16 le plus proche ; la légère compression horizontale (0,74%) est
/// imperceptible. 5s, aucune piste audio, jouée intégralement du début à la
/// fin sans boucle à gérer.
class IntroTeaserScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const IntroTeaserScreen({super.key, required this.onComplete});

  @override
  State<IntroTeaserScreen> createState() => _IntroTeaserScreenState();
}

class _IntroTeaserScreenState extends State<IntroTeaserScreen> {
  // Durée fixe plutôt qu'une comparaison position>=duration : le fichier de
  // référence encode ses timestamps avec un décalage énorme (~11,5 jours,
  // vu dans les logs ExoPlayer — première frame décodée à timeUs=1e12 au
  // lieu de 0), ce qui fait que `position` dépasse trivialement `duration`
  // dès le tout premier tick et coupait la vidéo quasi instantanément. Le
  // décodage/rendu des frames lui-même n'est pas affecté, seule cette
  // comparaison l'était — un minuteur fixe est plus simple et plus robuste
  // qu'essayer de corriger l'interprétation du décalage.
  static const _kDuration = Duration(seconds: 5);

  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _done = false;
  Timer? _completeTimer;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/video/intro_teaser.mp4');
    _controller.initialize().then((_) async {
      if (!mounted) return;
      await _controller.play();
      if (!mounted) return;
      setState(() => _ready = true);
      _completeTimer = Timer(_kDuration, () {
        if (_done || !mounted) return;
        _done = true;
        _controller.pause();
        widget.onComplete();
      });
    });
  }

  @override
  void dispose() {
    _completeTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Composition du teaser déjà centrée avec une marge généreuse de tous
    // les côtés (fond dégradé sombre qui va jusqu'au quasi-noir dans les
    // coins) : pas besoin de SafeArea, et le fond de Scaffold ci-dessous est
    // calé sur cette même teinte quasi-noire pour que le lettrboxing
    // (BoxFit.contain, l'aspect ratio 1080:1920 du fichier ne correspondant
    // pas forcément à celui de l'écran) reste invisible.
    return Scaffold(
      backgroundColor: const Color(0xFF0D0E09),
      body: _ready
          ? Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
