import 'package:flutter/widgets.dart';

/// Facteur d'agrandissement de toute l'interface sur tablette.
///
/// Le jeu est mis en page pour un téléphone en portrait (environ 430 × 860
/// points). Sur un grand écran, plutôt que d'afficher cette mise en page à
/// taille de téléphone au milieu d'un grand vide, on l'agrandit : le jeu est
/// mis en page sur un écran « virtuel » plus petit, puis dessiné à l'échelle.
/// Le facteur garde au moins 860 points de haut pour que l'écran de jeu
/// (pitch, grille, clavier, jokers, boutons) tienne sans défiler.
/// Renvoie 1 (aucun changement) sur téléphone et sur écran dépliable.
double tabletScaleFor(Size size) {
  final shortest = size.shortestSide, longest = size.longestSide;
  if (shortest < 600) return 1.0;
  final scale = [shortest / 430, longest / 860].reduce((a, b) => a < b ? a : b);
  return scale.clamp(1.0, 2.0);
}

/// Agrandit [child] d'un facteur [scale] en lui présentant un écran plus
/// petit (taille, marges système et densité de pixels ajustées), si bien que
/// le rendu reste net et que les touches tombent au bon endroit.
class TabletScale extends StatelessWidget {
  const TabletScale({super.key, required this.scale, required this.child});

  final double scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (scale <= 1.0) return child;
    final mq = MediaQuery.of(context);
    final logical = mq.size / scale;
    return FittedBox(
      fit: BoxFit.fill,
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: logical.width,
        height: logical.height,
        child: MediaQuery(
          data: mq.copyWith(
            size: logical,
            devicePixelRatio: mq.devicePixelRatio * scale,
            padding: mq.padding / scale,
            viewPadding: mq.viewPadding / scale,
            viewInsets: mq.viewInsets / scale,
            systemGestureInsets: mq.systemGestureInsets / scale,
          ),
          child: child,
        ),
      ),
    );
  }
}
