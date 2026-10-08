import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/joker.dart';
import '../models/puzzle.dart';
import '../services/app_settings.dart';
import '../services/game_state.dart';
import '../theme/app_theme.dart';
import 'joker_fx.dart';
import 'joker_style.dart';

Color _difficultyBorderColor(String label) {
  switch (label) {
    case 'Facile':
      return AppColors.greenBright;
    case 'Moyen':
      return AppColors.orangeBright;
    case 'Difficile':
      return AppColors.redBright;
    case 'Extrême':
      return AppColors.redBright;
    default:
      return AppColors.gold; // Tutoriel : neutre
  }
}

class PitchCard extends StatefulWidget {
  final JokerFx? fx;
  const PitchCard({super.key, this.fx});

  @override
  State<PitchCard> createState() => _PitchCardState();
}

class _PitchCardState extends State<PitchCard> with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;
  String? _lastLevelKey;
  // Couleurs affichées par nom : figées pendant le vol du faisceau d'un joker
  // Acteur/Personnage (l'état du jeu a déjà changé, l'affichage suit à l'impact).
  final Map<String, List<NameColor>> _shownNames = {};
  // À l'impact du faisceau, le nouveau nom s'illumine le temps d'une
  // pulsation de 0,5 s, pour montrer au joueur ce qui vient d'apparaître.
  late final AnimationController _landFlash =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  String? _flashSlot;
  final Set<String> _wasIncoming = {};

  @override
  void initState() {
    super.initState();
    widget.fx?.addListener(_onFx);
    // Cycle en boucle : pulsation de 1,4 s (420 ms montée, 980 ms descente)
    // puis 3 s de repos — les poids sont ces durées en millisecondes.
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 4400));
    _pulseAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 420),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 980),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 3000),
    ]).animate(_pulseController);
  }

  @override
  void didUpdateWidget(PitchCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fx != widget.fx) {
      oldWidget.fx?.removeListener(_onFx);
      widget.fx?.addListener(_onFx);
    }
  }

  @override
  void dispose() {
    widget.fx?.removeListener(_onFx);
    _pulseController.dispose();
    _landFlash.dispose();
    super.dispose();
  }

  void _onFx() {
    if (!mounted) return;
    for (final slot in const ['p1', 'p2']) {
      final incoming = _incoming('name:$slot');
      if (_wasIncoming.contains(slot) && !incoming) {
        _flashSlot = slot; // le faisceau vient d'arriver sur ce nom
        _landFlash.forward(from: 0);
      }
      incoming ? _wasIncoming.add(slot) : _wasIncoming.remove(slot);
    }
    setState(() {});
  }

  /// Surbrillance d'impact autour du nouveau nom : fond et halo de sa couleur
  /// plus léger grossissement, en dessin seulement (le texte ne bouge pas).
  Widget _landingFlash(String slot, Color color, Widget child) {
    if (slot != _flashSlot) return child;
    return AnimatedBuilder(
      animation: _landFlash,
      builder: (context, child) {
        final v = sin(pi * _landFlash.value).clamp(0.0, 1.0);
        return Transform.scale(
          scale: 1 + 0.08 * v,
          child: DecoratedBox(
            key: ValueKey('nameFlash:$slot'),
            decoration: BoxDecoration(
              color: color.withOpacity(0.35 * v),
              borderRadius: BorderRadius.circular(4),
              boxShadow: v > 0 ? [BoxShadow(color: color.withOpacity(0.6 * v), blurRadius: 12 * v)] : null,
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  bool _incoming(String id) => widget.fx?.isIncoming(id) ?? false;

  /// Masque [child] tant que le faisceau du joker visant [id] n'est pas arrivé.
  Widget _awaitBeam(String id, Widget child) {
    if (widget.fx == null) return child;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: _incoming(id) ? 0 : 1,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();

    // Le cycle de pulsation repart de zéro à chaque nouveau niveau, pour que
    // la première pulsation tombe dès l'arrivée sur le pitch.
    final levelKey = '${game.currentWorld.number}-${game.currentLevelNumber}';
    if (levelKey != _lastLevelKey) {
      _lastLevelKey = levelKey;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _pulseController
            ..value = 0
            ..repeat();
        }
      });
    }

    final settings = context.watch<AppSettings>();
    final colors = AppColors(settings.isLightTheme, colorblind: settings.colorblindMode);
    final puzzle = game.currentPuzzle;

    final spans = <InlineSpan>[];
    var remaining = puzzle.pitchTemplateFor(game.locale);
    final tokens = [
      ('{p1}', 'p1'),
      if (puzzle.hasP2) ('{p2}', 'p2'),
    ];

    WidgetSpan nameSpan(String slot, NameColor nameColor, bool armed, {bool isTarget = false}) {
      final text = game.displayFor(slot, nameColor);
      final color = colors.forNameColor(nameColor);
      final label = settings.colorblindMode ? '${AppColors.symbolForNameColor(nameColor)} $text' : text;
      return WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: GestureDetector(
          onTap: () {
            final armedColor = game.activeNameJoker;
            final err = game.onNameTap(slot);
            final kind = armedColor == null ? null : JokerKind.fromNameColor(armedColor);
            if (err == null && kind != null) widget.fx?.beam(kind, jokerColor(kind, colors), ['name:$slot']);
            if (err != null && context.mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(err), duration: const Duration(seconds: 2)));
            }
          },
          child: _landingFlash(
            isTarget ? slot : '',
            color,
            Container(
              key: isTarget ? widget.fx?.key('name:$slot') : null,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: armed ? color.withOpacity(0.18) : null,
                borderRadius: BorderRadius.circular(3),
              ),
              // Vrai soulignement de texte plutôt qu'une bordure de Container :
              // une bordure peut s'étirer jusqu'au bout de la ligne quand ce
              // span tombe en fin de ligne (constaté sur OnePlus) — la
              // décoration de texte, elle, colle toujours exactement à la
              // largeur réelle du mot.
              child: Text(
                label,
                style: AppTextStyles.body(size: 16, weight: FontWeight.w700, color: color).copyWith(
                  decoration: TextDecoration.underline,
                  decorationColor: color,
                  decorationThickness: 2,
                ),
              ),
            ),
          ),
        ),
      );
    }

    while (remaining.isNotEmpty) {
      int? nextIdx;
      String? matchToken, matchSlot;
      for (final t in tokens) {
        final idx = remaining.indexOf(t.$1);
        if (idx != -1 && (nextIdx == null || idx < nextIdx)) {
          nextIdx = idx;
          matchToken = t.$1;
          matchSlot = t.$2;
        }
      }
      if (nextIdx == null) {
        spans.add(TextSpan(text: remaining));
        break;
      }
      if (nextIdx > 0) spans.add(TextSpan(text: remaining.substring(0, nextIdx)));
      final cached = _shownNames[matchSlot!];
      final shown = _incoming('name:$matchSlot') && cached != null
          ? cached
          : (_shownNames[matchSlot] = game.displayedColors(matchSlot));
      final armed = game.activeNameJoker != null && game.activeNameJoker != shown.first;
      for (var k = 0; k < shown.length; k++) {
        if (k > 0) spans.add(TextSpan(text: ' / ', style: TextStyle(color: colors.muted)));
        spans.add(nameSpan(matchSlot, shown[k], armed, isTarget: k == 0));
      }
      remaining = remaining.substring(nextIdx + matchToken!.length);
    }

    final difficulty = game.difficultyLabel;
    final borderColor = _difficultyBorderColor(difficulty);
    final isExtreme = difficulty == 'Extrême';

    final card = AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        final pulse = _pulseAnim.value;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [colors.bgPanel2, colors.bgPanel]),
            borderRadius: BorderRadius.circular(14),
            // Épaisseur de bordure fixe : la faire varier rétrécit la zone de
            // texte et fait passer des mots à la ligne à chaque pulsation.
            // L'épaississement est dessiné par une ombre pleine, hors mise en page.
            border: Border.all(color: borderColor.withOpacity(0.7 + 0.3 * pulse), width: 1.5),
            boxShadow: pulse == 0
                ? null
                : [
                    BoxShadow(color: borderColor.withOpacity(pulse), spreadRadius: 1.5 * pulse),
                    BoxShadow(
                        color: borderColor.withOpacity(0.55 * pulse),
                        blurRadius: 6 + 18 * pulse,
                        spreadRadius: 1 + 2 * pulse)
                  ],
          ),
          child: child,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('PITCH', style: AppTextStyles.display(size: 14, color: AppColors.gold)),
              Text(puzzle.year, style: AppTextStyles.body(size: 12, color: colors.muted)),
            ],
          ),
          const SizedBox(height: 8),
          RichText(
              text: TextSpan(
                  style: AppTextStyles.body(size: 16, color: colors.cream).copyWith(height: 1.55), children: spans)),
          if (game.activeNameJoker != null) ...[
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context).pitchDifferentColorHint,
                style: AppTextStyles.body(size: 11, color: colors.muted)),
          ],
          if (game.revealedHintText != null) ...[
            Container(
              key: widget.fx?.key('hint'),
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.gold.withOpacity(0.3), width: 1)),
              ),
              child: _awaitBeam(
                'hint',
                Text('🎬 ${game.revealedHintText}',
                    style: AppTextStyles.body(size: 16, color: AppColors.goldBright).copyWith(height: 1.55)),
              ),
            ),
          ],
        ],
      ),
    );

    return isExtreme ? _FlameBorder(child: card) : card;
  }
}

/// Petites flammes qui vacillent le long du bas du cadre, pour les
/// devinettes de difficulté "Extrême".
class _FlameBorder extends StatefulWidget {
  final Widget child;
  const _FlameBorder({required this.child});

  @override
  State<_FlameBorder> createState() => _FlameBorderState();
}

class _FlameBorderState extends State<_FlameBorder> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        Positioned(
          left: 8,
          right: 8,
          bottom: -9,
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (i) {
                    final t = (_controller.value + i * 0.17) % 1.0;
                    final wobble = (t - 0.5).abs() * 2; // 0 au centre du cycle, 1 aux extrémités
                    final scale = 0.8 + 0.35 * (1 - wobble);
                    return Transform.translate(
                      offset: Offset(0, -3 * (1 - wobble)),
                      child: Transform.scale(scale: scale, child: const Text('🔥', style: TextStyle(fontSize: 13))),
                    );
                  }),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
