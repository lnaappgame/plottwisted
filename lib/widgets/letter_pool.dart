import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/puzzle.dart';
import '../services/app_settings.dart';
import '../services/game_state.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import 'joker_fx.dart';
import 'letter_keyboard.dart';

class LetterPool extends StatelessWidget {
  final JokerFx? fx;
  /// Appelé après chaque lettre placée (conseil sur le mode de saisie, voir GameScreen).
  final VoidCallback? onTileTapped;
  const LetterPool({super.key, this.fx, this.onTileTapped});

  @override
  Widget build(BuildContext context) {
    final fx = this.fx;
    if (fx == null) return _build(context);
    return ListenableBuilder(listenable: fx, builder: (context, _) => _build(context));
  }

  Widget _build(BuildContext context) {
    final game = context.watch<GameState>();
    final settings = context.watch<AppSettings>();
    final sound = context.read<SoundService>();
    final colors = AppColors(settings.isLightTheme);

    if (settings.inputMode != 'tiles') {
      return LetterKeyboard(
        pool: game.pool,
        layout: settings.inputMode,
        colors: colors,
        fx: fx,
        onTap: (tile) {
          if (settings.vibrationsOn) HapticFeedback.lightImpact();
          if (settings.sfxOn) sound.playTap();
          game.onLetterTap(tile);
          onTileTapped?.call();
        },
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (index, tile) in game.pool.indexed) _tile(context, game, settings, sound, colors, index, tile),
      ],
    );
  }

  Widget _tile(BuildContext context, GameState game, AppSettings settings, SoundService sound, AppColors colors,
      int index, LetterTile tile) {
    // Lettre visée par le faisceau d'Éliminer : ne s'éteint qu'à l'impact.
    final eliminated = tile.eliminated && !(fx?.isIncoming('tile:$index') ?? false);
    final disabled = tile.used || tile.eliminated;
    return GestureDetector(
      key: fx?.key('tile:$index'),
      onTap: disabled
          ? null
          : () {
              if (settings.vibrationsOn) HapticFeedback.lightImpact();
              if (settings.sfxOn) sound.playTap();
              game.onLetterTap(tile);
              onTileTapped?.call();
            },
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: tile.used ? 0 : (eliminated ? 0.15 : 1),
        child: Container(
          width: 38,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.bgPanel,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.gold.withOpacity(0.35)),
          ),
          child: Text(tile.letter, style: AppTextStyles.tile(size: 17, color: colors.cream)),
        ),
      ),
    );
  }
}
