import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/joker.dart';
import '../services/app_settings.dart';
import '../services/game_state.dart';
import '../theme/app_theme.dart';
import 'joker_fx.dart';
import 'joker_style.dart';

class JokerBar extends StatelessWidget {
  /// Bouton « Gagner un joker » : une pub pour un joker tiré au hasard.
  final VoidCallback onWatchAdForJoker;

  /// Joker rouge épuisé touché (nom orange à débloquer) : pub garantie si
  /// elle est encore disponible sur ce niveau, sinon explication.
  final VoidCallback onRedJokerEmpty;
  final JokerFx? fx;
  const JokerBar({super.key, required this.onWatchAdForJoker, required this.onRedJokerEmpty, this.fx});

  @override
  Widget build(BuildContext context) {
    final fx = this.fx;
    if (fx == null) return _buildBar(context);
    return ListenableBuilder(listenable: fx, builder: (context, _) => _buildBar(context));
  }

  Widget _buildBar(BuildContext context) {
    final game = context.watch<GameState>();
    final settings = context.watch<AppSettings>();
    final colors = AppColors(settings.isLightTheme, colorblind: settings.colorblindMode);
    final t = AppLocalizations.of(context);
    final kinds = [
      JokerKind.reveal,
      JokerKind.eliminate,
      JokerKind.actor,
      JokerKind.character,
      JokerKind.hint,
      JokerKind.revealWord,
      if (game.currentPuzzleHasOrange) JokerKind.red,
    ];

    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 14,
          children: [
            for (final kind in kinds) _button(context, game, colors, t, kind),
          ],
        ),
        if (!game.inTutorial) ...[
          const SizedBox(height: 14),
          _WinJokerButton(label: t.jokerWinOne, colors: colors, onTap: onWatchAdForJoker),
        ],
      ],
    );
  }

  Widget _button(BuildContext context, GameState game, AppColors colors, AppLocalizations t, JokerKind kind) {
    final shown = max(0, game.countOf(kind) - (fx?.pending(kind) ?? 0));
    final color = jokerColor(kind, colors);
    final hintUsed = kind == JokerKind.hint && game.hintRevealed;
    // Joker rouge épuisé : reste touchable pour sa pub garantie (ou pour
    // expliquer comment en obtenir) ; les autres jokers à 0 sont éteints.
    final redEmpty = kind == JokerKind.red && shown == 0;
    String? subtitle;
    if (hintUsed) {
      subtitle = t.jokerHintUsedSubtitle;
    } else if (redEmpty) {
      subtitle = game.peutRegarderPubJokerRouge && !game.inTutorial ? t.jokerAdUnlockSubtitle : t.jokerLockedSubtitle;
    }
    return _JokerButton(
      key: fx?.key('joker:${kind.name}'),
      label: jokerName(kind, t),
      icon: kind.icon,
      count: shown,
      color: color,
      colors: colors,
      active: kind.nameColor != null && game.activeNameJoker == kind.nameColor,
      disabled: hintUsed,
      tappable: shown > 0 || redEmpty,
      subtitle: subtitle,
      onTap: () => _onTap(game, kind, shown, color),
    );
  }

  void _onTap(GameState game, JokerKind kind, int shown, Color color) {
    if (shown <= 0) {
      if (kind == JokerKind.red) onRedJokerEmpty();
      return;
    }
    switch (kind) {
      case JokerKind.reveal:
        final slot = game.useRevealJoker();
        if (slot != null) fx?.beam(kind, color, ['slot:$slot']);
      case JokerKind.eliminate:
        final tiles = game.useEliminateJoker();
        fx?.beam(kind, color, [for (final i in tiles) 'tile:$i']);
      case JokerKind.hint:
        if (game.useHintJoker() != null) fx?.beam(kind, color, ['hint']);
      case JokerKind.revealWord:
        final slots = game.useRevealWordJoker();
        fx?.beam(kind, color, [for (final i in slots) 'slot:$i']);
      case JokerKind.actor:
      case JokerKind.character:
      case JokerKind.red:
        // Joker à deux touches : le faisceau part au moment où le joueur
        // touche le nom à changer (voir PitchCard).
        game.selectNameJoker(kind.nameColor!);
    }
  }
}

class _WinJokerButton extends StatelessWidget {
  final String label;
  final AppColors colors;
  final VoidCallback onTap;
  const _WinJokerButton({required this.label, required this.colors, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 324),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: AppColors.gold.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.gold.withOpacity(0.7), width: 1.4),
          ),
          child: Column(
            children: [
              Text(label, style: AppTextStyles.body(size: 12, weight: FontWeight.w700, color: AppColors.goldBright)),
              const SizedBox(height: 2),
              Text('🎬▶️', style: AppTextStyles.body(size: 10, color: colors.muted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _JokerButton extends StatefulWidget {
  final String label;
  final String icon;
  final int count;
  final Color color;
  final AppColors colors;
  final bool active;
  final bool disabled;
  final bool tappable;
  final String? subtitle;
  final VoidCallback onTap;

  const _JokerButton({
    super.key,
    required this.label,
    required this.icon,
    required this.count,
    required this.color,
    required this.colors,
    required this.active,
    required this.disabled,
    required this.tappable,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_JokerButton> createState() => _JokerButtonState();
}

class _JokerButtonState extends State<_JokerButton> with TickerProviderStateMixin {
  late final AnimationController _flash = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
  late final AnimationController _bump = AnimationController(vsync: this, duration: const Duration(milliseconds: 340));

  @override
  void didUpdateWidget(covariant _JokerButton old) {
    super.didUpdateWidget(old);
    if (widget.count > old.count) _bump.forward(from: 0);
  }

  @override
  void dispose() {
    _flash.dispose();
    _bump.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.count > 0) _flash.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final accent = widget.color;
    final owned = widget.count > 0 && !widget.disabled;
    // À 0, le joker garde sa couleur (le joueur y retrouve celle du nom qu'il
    // donne), en plus pâle et sans la bordure épaisse d'un joker en stock.
    final background = widget.active ? accent : accent.withOpacity(owned ? 0.14 : 0.05);
    final border = accent.withOpacity(widget.active || owned ? 0.85 : 0.25);
    final labelColor = widget.active ? onJokerColor(accent) : accent.withOpacity(owned ? 1 : 0.5);
    final enabled = widget.tappable && !widget.disabled;

    return Semantics(
      button: enabled,
      enabled: enabled,
      label: '${widget.label}, ${widget.count}',
      child: Opacity(
        opacity: widget.disabled ? 0.35 : 1,
        child: GestureDetector(
          onTap: enabled ? _handleTap : null,
          child: AnimatedBuilder(
            animation: Listenable.merge([_flash, _bump]),
            builder: (context, _) {
              final glow = _flash.isAnimating ? 1 - _flash.value : 0.0;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 100,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                    decoration: BoxDecoration(
                      color: Color.lerp(background, accent.withOpacity(0.45), glow),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: border, width: owned || widget.active ? 1.4 : 1),
                      boxShadow: glow > 0
                          ? [
                              BoxShadow(
                                  color: accent.withOpacity(0.7 * glow), blurRadius: 16 * glow, spreadRadius: 2 * glow)
                            ]
                          : null,
                    ),
                    child: Column(
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(widget.label,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              style: AppTextStyles.body(size: 11, weight: FontWeight.w700, color: labelColor)),
                        ),
                        const SizedBox(height: 2),
                        Opacity(
                          opacity: owned || widget.active || widget.subtitle != null ? 1 : 0.5,
                          child: Text(
                            widget.subtitle ?? widget.icon,
                            style: AppTextStyles.body(
                              size: 10,
                              weight: widget.subtitle != null && widget.count == 0 ? FontWeight.w600 : FontWeight.w400,
                              color: widget.active ? onJokerColor(accent) : colors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (owned)
                    Positioned(
                      top: -9,
                      right: -7,
                      child: Transform.scale(
                        scale: 1 + 0.4 * sin(pi * _bump.value),
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 22),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(color: colors.bgDeep, width: 2),
                          ),
                          child: Text('${widget.count}',
                              textAlign: TextAlign.center,
                              style:
                                  AppTextStyles.body(size: 12, weight: FontWeight.w800, color: onJokerColor(accent))),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
