import 'package:flutter/material.dart';
import '../models/puzzle.dart';
import '../theme/app_theme.dart';
import 'joker_fx.dart';

const _azerty = ['AZERTYUIOP', 'QSDFGHJKLM', 'WXCVBN'];
const _qwerty = ['QWERTYUIOP', 'ASDFGHJKL', 'ZXCVBNM'];
const _chiffres = '1234567890';

/// Saisie des lettres sous forme de clavier (AZERTY ou QWERTY, au choix du
/// joueur dans les Paramètres) au lieu des tuiles mélangées : les lettres
/// proposées pour ce niveau sont en surbrillance, avec le nombre
/// d'exemplaires restants s'il y en a plusieurs ; les autres touches restent
/// sombres. Même réserve de lettres que les tuiles (leurres compris) : seul
/// l'agencement change.
class LetterKeyboard extends StatelessWidget {
  final List<LetterTile> pool;

  /// 'azerty' ou 'qwerty'.
  final String layout;
  final AppColors colors;
  final void Function(LetterTile tile) onTap;

  /// Jeu principal : chaque tuile de la réserve est une cible du faisceau
  /// d'Éliminer ('tile:i'), ici rattachée à la touche de sa lettre.
  final JokerFx? fx;

  const LetterKeyboard({
    super.key,
    required this.pool,
    required this.layout,
    required this.colors,
    required this.onTap,
    this.fx,
  });

  @override
  Widget build(BuildContext context) {
    final rows = [
      if (pool.any((t) => _chiffres.contains(t.letter))) _chiffres,
      ...(layout == 'qwerty' ? _qwerty : _azerty),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      const gap = 4.0;
      // Environ 25 % plus petit que la largeur disponible (demande du 09/10).
      final keyWidth = ((constraints.maxWidth - 9 * gap) / 10 * 0.75).clamp(18.0, 33.0);
      final keyHeight = (keyWidth * 1.3).clamp(28.0, 42.0);
      return Column(
        children: [
          for (final (i, row) in rows.indexed) ...[
            if (i > 0) const SizedBox(height: gap + 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final (j, letter) in row.split('').indexed) ...[
                  if (j > 0) const SizedBox(width: gap),
                  _key(letter, keyWidth, keyHeight),
                ],
              ],
            ),
          ],
        ],
      );
    });
  }

  Widget _key(String letter, double width, double height) {
    final indices = [
      for (final (i, t) in pool.indexed)
        if (t.letter == letter) i
    ];
    // Encore tapables ; une lettre visée par le faisceau d'Éliminer ne
    // s'éteint qu'à l'impact, comme sur les tuiles.
    final tappable = [
      for (final i in indices)
        if (!pool[i].used && !pool[i].eliminated) i
    ];
    final shown = [
      for (final i in indices)
        if (!pool[i].used && (!pool[i].eliminated || (fx?.isIncoming('tile:$i') ?? false))) i
    ];
    final lit = shown.isNotEmpty;

    Widget key = Semantics(
      button: tappable.isNotEmpty,
      enabled: tappable.isNotEmpty,
      label: shown.length > 1 ? '$letter ×${shown.length}' : letter,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: tappable.isEmpty ? null : () => onTap(pool[tappable.first]),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: lit ? Color.alphaBlend(AppColors.gold.withOpacity(0.16), colors.bgPanel) : colors.bgPanel.withOpacity(0.35),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: lit ? AppColors.goldBright.withOpacity(0.85) : colors.muted.withOpacity(0.12),
              width: lit ? 1.3 : 1,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Text(letter,
                    style: AppTextStyles.tile(
                        size: (width * 0.5).clamp(11.0, 16.0),
                        color: lit ? colors.cream : colors.muted.withOpacity(0.35))),
              ),
              if (shown.length > 1)
                Positioned(
                  top: 2,
                  right: 4,
                  child: Text('${shown.length}',
                      style: AppTextStyles.body(size: 9, weight: FontWeight.w800, color: AppColors.goldBright)),
                ),
            ],
          ),
        ),
      ),
    );

    // Une touche porte la cible du faisceau de chacune de ses tuiles.
    final cibles = fx;
    if (cibles != null) {
      for (final i in indices) {
        key = KeyedSubtree(key: cibles.key('tile:$i'), child: key);
      }
    }
    return key;
  }
}
