import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_settings.dart';
import '../services/game_state.dart';
import '../theme/app_theme.dart';

class AnswerRow extends StatelessWidget {
  const AnswerRow({super.key});

  bool _isLocked(GameState game, int i) {
    if (game.lockedSlots.contains(i)) return true;
    final w = game.wordRanges.indexWhere((r) => r.contains(i));
    return w != -1 && game.lockedWords.contains(w);
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final settings = context.watch<AppSettings>();
    final colors = AppColors(settings.isLightTheme);

    // Regroupe les cases par mot pour qu'un mot ne soit jamais coupé par un
    // retour à la ligne : chaque mot est un Wrap-item à part entière.
    final wordWidgets = <Widget>[];
    final wordTileCounts = <int>[];
    List<Widget> currentWord = [];

    void flushWord() {
      if (currentWord.isNotEmpty) {
        wordWidgets.add(Row(mainAxisSize: MainAxisSize.min, children: currentWord));
        wordTileCounts.add(currentWord.length);
        currentWord = [];
      }
    }

    for (var i = 0; i < game.slots.length; i++) {
      final slot = game.slots[i];
      if (slot.isSpace) { flushWord(); continue; }
      if (slot.isAuto) {
        currentWord.add(_Blank(text: slot.char, colors: colors, style: _BlankStyle.auto));
        continue;
      }
      final locked = _isLocked(game, i);
      final tileId = game.guess[i];
      final letter = tileId != null ? game.pool[tileId].letter : null;
      currentWord.add(GestureDetector(
        onTap: () => game.onBlankTap(i),
        child: _Blank(
          text: letter ?? '_',
          colors: colors,
          style: locked
              ? _BlankStyle.locked
              : (i == game.cursorIndex ? _BlankStyle.cursor : (letter != null ? _BlankStyle.filled : _BlankStyle.empty)),
        ),
      ));
    }
    flushWord();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Un mot dont les tuiles à taille normale (30px + 6px de marge)
        // dépasseraient la largeur disponible est réduit en bloc (FittedBox)
        // pour tenir sur une seule ligne sans déborder — plutôt que de le
        // laisser dépasser l'écran (bandes de "overflow" jaunes et noires).
        const tileSpan = 36.0;
        return Wrap(
          alignment: WrapAlignment.center,
          spacing: 14, runSpacing: 10,
          children: [
            for (var w = 0; w < wordWidgets.length; w++)
              if (wordTileCounts[w] * tileSpan > constraints.maxWidth)
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                  child: FittedBox(fit: BoxFit.scaleDown, child: wordWidgets[w]),
                )
              else
                wordWidgets[w],
          ],
        );
      },
    );
  }
}

enum _BlankStyle { empty, filled, cursor, locked, auto }

class _Blank extends StatelessWidget {
  final String text;
  final AppColors colors;
  final _BlankStyle style;
  const _Blank({required this.text, required this.colors, required this.style});

  @override
  Widget build(BuildContext context) {
    Color borderColor = AppColors.gold;
    Color textColor = AppColors.goldBright;
    Color? bg;
    switch (style) {
      case _BlankStyle.cursor:
        bg = AppColors.gold.withOpacity(0.22);
        break;
      case _BlankStyle.locked:
        borderColor = AppColors.green;
        textColor = AppColors.greenBright;
        break;
      case _BlankStyle.auto:
        borderColor = colors.muted;
        textColor = AppColors.goldBright;
        break;
      case _BlankStyle.empty:
        textColor = Colors.transparent;
        break;
      case _BlankStyle.filled:
        break;
    }
    return Container(
      width: 30, height: 38,
      margin: const EdgeInsets.only(right: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: borderColor, width: 3)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      ),
      child: Text(text, style: AppTextStyles.tile(size: 19, color: textColor)),
    );
  }
}
