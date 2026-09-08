import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/puzzle.dart';
import '../services/app_settings.dart';
import '../services/game_state.dart';
import '../theme/app_theme.dart';

class JokerBar extends StatelessWidget {
  final void Function(String message) onToast;
  final VoidCallback onWatchAdForJoker;
  final VoidCallback onWatchAdForRedJoker;
  const JokerBar({
    super.key,
    required this.onToast,
    required this.onWatchAdForJoker,
    required this.onWatchAdForRedJoker,
  });

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final settings = context.watch<AppSettings>();
    final colors = AppColors(settings.isLightTheme);
    final t = AppLocalizations.of(context);

    return Column(
      children: [
        Wrap(
          spacing: 8, runSpacing: 8,
          children: [
            _JokerButton(
              label: t.jokerReveal, icon: '💡', count: game.revealCount, colors: colors,
              onTap: () => game.useRevealJoker(),
            ),
            _JokerButton(
              label: t.jokerEliminate, icon: '✂️', count: game.eliminateCount, colors: colors,
              onTap: () => game.useEliminateJoker(),
            ),
            _JokerButton(
              label: t.jokerActor, icon: '🔵', count: game.actorCount, colors: colors,
              active: game.activeNameJoker == NameColor.blue,
              onTap: () => game.selectNameJoker(NameColor.blue),
            ),
            _JokerButton(
              label: t.jokerCharacter, icon: '🟢', count: game.characterCount, colors: colors,
              active: game.activeNameJoker == NameColor.green,
              onTap: () => game.selectNameJoker(NameColor.green),
            ),
            _JokerButton(
              label: t.jokerHint, icon: '🎬', count: game.hintCount, colors: colors,
              disabled: game.hintRevealed,
              subtitleOverride: game.hintRevealed ? t.jokerHintUsedSubtitle : null,
              onTap: () => game.useHintJoker(),
            ),
            _JokerButton(
              label: t.jokerRevealWord, icon: '📖', count: game.revealWordCount, colors: colors,
              onTap: () => game.useRevealWordJoker(),
            ),
            if (game.currentPuzzleHasOrange) _buildRedJokerButton(context, game, colors),
            if (!game.inTutorial)
              _JokerButton(
                label: t.jokerWinOne, icon: '🎬▶️', count: null, colors: colors, fullWidth: true,
                onTap: onWatchAdForJoker,
              ),
          ],
        ),
      ],
    );
  }

  /// Nom orange : verrouillé tant qu'aucun joker rouge n'est en stock. Le
  /// bouton bascule automatiquement entre "utiliser" (stock > 0) et "pub
  /// garantie" (stock à 0, encore disponible ce niveau-ci) ou un état
  /// bloqué expliquant les autres façons d'en obtenir.
  Widget _buildRedJokerButton(BuildContext context, GameState game, AppColors colors) {
    final t = AppLocalizations.of(context);
    if (game.redJokerCount > 0) {
      return _JokerButton(
        label: t.jokerRedCharacter, icon: '🔴', count: game.redJokerCount, colors: colors,
        accentColor: AppColors.crimsonBright,
        active: game.activeNameJoker == NameColor.red,
        onTap: () => game.selectNameJoker(NameColor.red),
      );
    }
    if (game.peutRegarderPubJokerRouge) {
      return _JokerButton(
        label: t.jokerRedCharacter, icon: '🔴', count: null, colors: colors,
        accentColor: AppColors.crimsonBright,
        subtitleOverride: t.jokerAdUnlockSubtitle,
        onTap: onWatchAdForRedJoker,
      );
    }
    // Volontairement pas "disabled" : le bouton doit rester tapable pour
    // expliquer au joueur les deux autres façons d'obtenir un joker rouge.
    return _JokerButton(
      label: t.jokerRedCharacter, icon: '🔴', count: null, colors: colors,
      accentColor: AppColors.crimsonBright,
      subtitleOverride: t.jokerLockedSubtitle,
      onTap: () => onToast(t.jokerRedLockedToast),
    );
  }
}

class _JokerButton extends StatelessWidget {
  final String label;
  final String icon;
  final int? count;
  final bool active;
  final bool disabled;
  final bool fullWidth;
  final AppColors colors;
  final VoidCallback onTap;
  final String? subtitleOverride;
  final Color? accentColor; // remplace le doré par défaut (ex. rouge pour le joker rouge)

  const _JokerButton({
    required this.label, required this.icon, required this.count, required this.colors,
    required this.onTap, this.active = false, this.disabled = false, this.fullWidth = false,
    this.subtitleOverride, this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? AppColors.gold;
    final isDisabled = disabled || (count != null && count! <= 0);
    final subtitle = subtitleOverride ?? (count == null ? icon : (count! > 0 ? '$count $icon' : icon));
    return SizedBox(
      width: fullWidth ? 320 : 100,
      child: Opacity(
        opacity: isDisabled ? 0.35 : 1,
        child: GestureDetector(
          onTap: isDisabled ? null : onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(
              color: active ? accent : colors.bgPanel,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: active ? accent : accent.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: AppTextStyles.body(size: 11, weight: FontWeight.w700,
                          color: active ? const Color(0xFF1A1410) : (accentColor ?? AppColors.goldBright))),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.body(size: 10, color: active ? const Color(0xFF4A3C1F) : colors.muted)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
