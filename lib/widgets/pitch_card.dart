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
  // Ponctuation (ou « 's » anglais) collée juste après un nom du pitch.
  static final _gluedPunctuation = RegExp(r'''^(?:['’]s|[.,;:!?…)»”"])+''');

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

  // Info-bulle au-dessus d'un nom touché sans joker armé : rappelle ce que
  // veut dire sa couleur. Toucher à nouveau le nom (ou n'importe où ailleurs)
  // la referme.
  final OverlayPortalController _info = OverlayPortalController();
  final Object _infoGroup = Object();
  final Map<String, GlobalKey> _nameKeys = {};
  String? _infoId; // 'p1:0'... : nom concerné et rang de la couleur affichée
  NameColor? _infoColor;
  Rect? _infoRect; // position du nom dans le repère de l'Overlay

  void _toggleInfo(String id, NameColor color) {
    if (_infoId == id) {
      _hideInfo();
      return;
    }
    final box = _nameKeys[id]?.currentContext?.findRenderObject() as RenderBox?;
    final overlayBox = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || overlayBox == null) return;
    final topLeft = box.localToGlobal(Offset.zero, ancestor: overlayBox);
    setState(() {
      _infoId = id;
      _infoColor = color;
      _infoRect = topLeft & box.size;
    });
    _info.show();
  }

  void _hideInfo() {
    if (_infoId == null || !mounted) return;
    _info.hide();
    setState(() => _infoId = null);
  }

  Widget _infoBubble(BuildContext context) {
    final rect = _infoRect, color = _infoColor;
    if (_infoId == null || rect == null || color == null) return const SizedBox.shrink();
    final settings = context.read<AppSettings>();
    final colors = AppColors(settings.isLightTheme, colorblind: settings.colorblindMode);
    final t = AppLocalizations.of(context);
    final text = switch (color) {
      NameColor.green => t.nameInfoGreen,
      NameColor.red => t.nameInfoRed,
      NameColor.blue => t.nameInfoBlue,
      NameColor.orange => t.nameInfoOrange,
      NameColor.violet => t.nameInfoViolet,
    };
    final c = colors.forNameColor(color);
    return CustomSingleChildLayout(
      delegate: _InfoBubbleLayout(rect),
      child: TapRegion(
        groupId: _infoGroup,
        onTapOutside: (_) => _hideInfo(),
        child: GestureDetector(
          onTap: _hideInfo,
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              key: const ValueKey('nameInfoBubble'),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.bgPanel2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: c, width: 1.5),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(text,
                        style: AppTextStyles.body(size: 13, weight: FontWeight.w600, color: colors.cream)
                            .copyWith(height: 1.3)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

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
          _hideInfo();
        }
      });
    }
    // Un joker de nom armé : le toucher d'un nom sert à le jouer, plus à
    // afficher l'info-bulle.
    if (game.activeNameJoker != null && _infoId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _hideInfo());
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

    WidgetSpan nameSpan(String slot, NameColor nameColor, bool armed,
        {bool isTarget = false, String suffix = '', required String infoId}) {
      final text = game.displayFor(slot, nameColor);
      final color = colors.forNameColor(nameColor);
      final label = settings.colorblindMode ? '${AppColors.symbolForNameColor(nameColor)} $text' : text;
      final name = GestureDetector(
        key: _nameKeys.putIfAbsent(infoId, GlobalKey.new),
        onTap: () {
          if (game.activeNameJoker == null) {
            _toggleInfo(infoId, nameColor);
            return;
          }
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
      );
      // Même groupe que l'info-bulle : toucher le nom n'est pas un toucher
      // « ailleurs », c'est son onTap qui ouvre ou ferme la bulle.
      final tappable = TapRegion(groupId: _infoGroup, child: name);
      return WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        // La ponctuation collée au nom (« The Dude. ») reste avec lui : sinon
        // le point pouvait passer seul en début de ligne suivante.
        child: suffix.isEmpty
            ? tappable
            : Row(mainAxisSize: MainAxisSize.min, children: [
                Flexible(child: tappable), // un nom plus large que la ligne peut encore passer à la ligne
                Text(suffix, style: AppTextStyles.body(size: 16, color: colors.cream)),
              ]),
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
      remaining = remaining.substring(nextIdx + matchToken!.length);
      final suffix = _gluedPunctuation.firstMatch(remaining)?.group(0) ?? '';
      remaining = remaining.substring(suffix.length);
      for (var k = 0; k < shown.length; k++) {
        if (k > 0) spans.add(TextSpan(text: ' / ', style: TextStyle(color: colors.muted)));
        spans.add(nameSpan(matchSlot, shown[k], armed,
            isTarget: k == 0, suffix: k == shown.length - 1 ? suffix : '', infoId: '$matchSlot:$k'));
      }
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: AppTextStyles.body(size: 12, color: colors.muted).copyWith(height: 1.35),
                    children: [
                      TextSpan(
                          text: game.levelTitleFor(game.locale),
                          style: AppTextStyles.display(size: 14, color: AppColors.gold)),
                      TextSpan(text: '  ·  ${game.currentWorld.categoryLabelFor(game.locale)}'),
                      if (!game.inTutorial) ...[
                        const TextSpan(text: '  ·  '),
                        TextSpan(
                          text: game.difficultyLabelFor(game.locale),
                          style: TextStyle(
                              color: colors.forDifficultyLabel(game.difficultyLabel), fontWeight: FontWeight.w700),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
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

    return OverlayPortal(
      controller: _info,
      overlayChildBuilder: _infoBubble,
      child: isExtreme ? _FlameBorder(child: card) : card,
    );
  }
}

/// Place l'info-bulle centrée au-dessus du nom touché (en dessous s'il n'y a
/// pas la place), sans jamais dépasser des bords de l'écran.
class _InfoBubbleLayout extends SingleChildLayoutDelegate {
  final Rect anchor;
  const _InfoBubbleLayout(this.anchor);

  static const _margin = 12.0;
  static const _gap = 6.0;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(maxWidth: min(260, constraints.maxWidth - 2 * _margin));

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final x = (anchor.center.dx - childSize.width / 2)
        .clamp(_margin, max(_margin, size.width - childSize.width - _margin))
        .toDouble();
    final aboveY = anchor.top - childSize.height - _gap;
    final y = aboveY >= _margin ? aboveY : anchor.bottom + _gap;
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_InfoBubbleLayout oldDelegate) => oldDelegate.anchor != anchor;
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
