import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/app_settings.dart';
import '../services/game_state.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';

class LetterPool extends StatelessWidget {
  final VoidCallback? onLetterTapped;
  const LetterPool({super.key, this.onLetterTapped});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final settings = context.watch<AppSettings>();
    final sound = context.read<SoundService>();
    final colors = AppColors(settings.isLightTheme);

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8, runSpacing: 8,
      children: game.pool.map((tile) {
        final disabled = tile.used || tile.eliminated;
        return GestureDetector(
          onTap: disabled
              ? null
              : () {
                  if (settings.vibrationsOn) HapticFeedback.lightImpact();
                  if (settings.sfxOn) sound.playTap();
                  game.onLetterTap(tile);
                  onLetterTapped?.call();
                },
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: tile.used ? 0 : (tile.eliminated ? 0.15 : 1),
            child: Container(
              width: 38, height: 44,
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
      }).toList(),
    );
  }
}
