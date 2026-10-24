import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/daily_wheel.dart';
import '../models/joker.dart';
import '../services/app_settings.dart';
import '../services/game_state.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import 'joker_style.dart';

/// La bobine du jour : une bobine de film argentée dont les fenêtres sont
/// les cases de la roue (taille proportionnelle à leur chance). Un tour
/// gratuit par jour, puis un relancement contre une pub. À l'arrêt, un bout
/// de pellicule se déroule sous la bobine avec le gain ; la fenêtre ne peut
/// être fermée que [resultLock] après, le temps de lire ce qu'on a gagné.
class DailyWheelDialog extends StatefulWidget {
  static const spinDuration = Duration(milliseconds: 4200);
  static const resultLock = Duration(seconds: 2);
  const DailyWheelDialog({super.key});

  @override
  State<DailyWheelDialog> createState() => _DailyWheelDialogState();
}

class _DailyWheelDialogState extends State<DailyWheelDialog> with TickerProviderStateMixin {
  final Random _rng = Random();
  late final AnimationController _spin = AnimationController(vsync: this, duration: DailyWheelDialog.spinDuration);
  late final AnimationController _strip = AnimationController(vsync: this, duration: const Duration(milliseconds: 750));
  double _from = 0, _to = 0; // rotation de la bobine, en tours (sens horaire)
  int? _result;
  bool _busy = false; // pub ou rotation en cours
  bool _locked = false; // gain affiché depuis moins de resultLock
  Timer? _unlock;
  String? _error;

  double get _angle => _from + (_to - _from) * Curves.easeOutQuart.transform(_spin.value);

  @override
  void dispose() {
    _unlock?.cancel();
    _spin.dispose();
    _strip.dispose();
    super.dispose();
  }

  Future<void> _launch({required bool afterAd}) async {
    if (_busy || _locked) return;
    final game = context.read<GameState>();
    final t = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    if (afterAd) {
      final earned = await game.adService.showRewardedAdForJoker();
      if (!mounted) return;
      if (!earned) {
        setState(() {
          _busy = false;
          _error = t.commonAdUnavailable;
        });
        return;
      }
    }
    final index = game.spinWheel(afterAd: afterAd);
    if (index == null) {
      setState(() => _busy = false);
      return;
    }
    // Le repère est en haut : la case tirée doit s'y arrêter, un peu à
    // gauche ou à droite de son milieu pour que l'arrêt ait l'air naturel.
    final (start, sweep) = wheelSegmentArc(index);
    final landing = start + sweep / 2 + (_rng.nextDouble() - 0.5) * sweep * 0.6;
    final current = _angle;
    final offset = ((-landing - current) % 1 + 1) % 1;
    setState(() {
      _result = null;
      _from = current;
      _to = current + 5 + offset;
    });
    _strip.reset();
    await _spin.forward(from: 0);
    if (!mounted) return;
    final settings = context.read<AppSettings>();
    if (settings.vibrationsOn) HapticFeedback.mediumImpact();
    if (settings.sfxOn) context.read<SoundService>().playCorrect();
    setState(() {
      _busy = false;
      _locked = true;
      _result = index;
    });
    _strip.forward(from: 0);
    _unlock?.cancel();
    _unlock = Timer(DailyWheelDialog.resultLock, () {
      if (mounted) setState(() => _locked = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final settings = context.watch<AppSettings>();
    final colors = AppColors(settings.isLightTheme, colorblind: settings.colorblindMode);
    final t = AppLocalizations.of(context);
    final canClose = !_busy && !_locked;
    final freeAvailable = game.wheelFreeSpinAvailable;
    final adAvailable = game.wheelAdSpinAvailable;

    Widget buttons;
    if (_busy || _locked) {
      // Pendant la rotation puis le temps de lecture du gain : rien à toucher.
      buttons = const SizedBox(height: 48);
    } else if (freeAvailable) {
      buttons = SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          key: const ValueKey('wheelSpin'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.crimson,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: () => _launch(afterAd: false),
          child: Text(t.wheelSpin, style: AppTextStyles.display(size: 18, color: colors.cream)),
        ),
      );
    } else if (adAvailable) {
      buttons = SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          key: const ValueKey('wheelRespin'),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.goldBright),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: () => _launch(afterAd: true),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.play_circle_fill, color: AppColors.goldBright, size: 20),
              const SizedBox(width: 8),
              Text(t.wheelRespin,
                  style: AppTextStyles.body(size: 14, weight: FontWeight.w700, color: AppColors.goldBright)),
            ],
          ),
        ),
      );
    } else {
      buttons = Text(t.wheelComeBack,
          textAlign: TextAlign.center, style: AppTextStyles.body(size: 13, color: colors.muted).copyWith(height: 1.4));
    }

    return PopScope(
      canPop: canClose,
      child: Dialog(
        backgroundColor: colors.bgPanel2,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.gold.withOpacity(0.6)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t.wheelTitle,
                  textAlign: TextAlign.center, style: AppTextStyles.display(size: 22, color: AppColors.goldBright)),
              const SizedBox(height: 4),
              Text(t.wheelSubtitle, textAlign: TextAlign.center, style: AppTextStyles.body(size: 12, color: colors.muted)),
              const SizedBox(height: 14),
              Center(
                child: SizedBox(
                  width: 236,
                  height: 236,
                  child: AnimatedBuilder(
                    animation: _spin,
                    builder: (context, _) => CustomPaint(
                      painter: ReelPainter(turns: _angle, colors: colors, highlight: _spin.isAnimating ? null : _result),
                    ),
                  ),
                ),
              ),
              _ResultStrip(animation: _strip, result: _result, colors: colors),
              const SizedBox(height: 12),
              buttons,
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!,
                    textAlign: TextAlign.center, style: AppTextStyles.body(size: 12, color: AppColors.redBright)),
              ],
              const SizedBox(height: 4),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: canClose ? 1 : 0,
                child: IgnorePointer(
                  ignoring: !canClose,
                  child: TextButton(
                  key: const ValueKey('wheelClose'),
                    onPressed: canClose ? () => Navigator.of(context).pop() : null,
                    child: Text(t.commonClose, style: AppTextStyles.body(size: 13, color: colors.muted)),
                  ),
                ),
              ),
              Text(t.wheelOdds,
                  textAlign: TextAlign.center, style: AppTextStyles.body(size: 9.5, color: colors.muted.withOpacity(0.8))),
            ],
          ),
        ),
      ),
    );
  }
}

/// Le bout de pellicule qui se déroule sous la bobine avec le gain.
class _ResultStrip extends StatelessWidget {
  final Animation<double> animation;
  final int? result;
  final AppColors colors;
  const _ResultStrip({required this.animation, required this.result, required this.colors});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final segment = result == null ? null : kWheelSegments[result!];
    return SizedBox(
      height: 92,
      child: segment == null
          ? null
          : AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                final p = Curves.easeOutCubic.transform(animation.value);
                return Column(
                  children: [
                    Opacity(
                      opacity: p,
                      child: Text(t.wheelYouWin, style: AppTextStyles.display(size: 13, color: AppColors.gold)),
                    ),
                    const SizedBox(height: 4),
                    // Déroulée de gauche à droite depuis la bobine, légèrement
                    // inclinée comme une pellicule qui pend.
                    Transform.rotate(
                      angle: -0.035,
                      child: ClipRect(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          widthFactor: p.clamp(0.001, 1.0),
                          child: _FilmStrip(
                            key: const ValueKey('wheelResultStrip'),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('+${segment.jokers.length}',
                                    style: AppTextStyles.display(size: 18, color: AppColors.goldBright)),
                                const SizedBox(width: 10),
                                for (final (i, kind) in segment.jokers.indexed) ...[
                                  if (i > 0) const SizedBox(width: 8),
                                  Text(kind.icon, style: const TextStyle(fontSize: 16)),
                                  const SizedBox(width: 4),
                                  Text(jokerName(kind, t).toUpperCase(),
                                      style: AppTextStyles.body(
                                          size: segment.isJackpot ? 10 : 13,
                                          weight: FontWeight.w700,
                                          color: jokerColor(kind, colors))),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

/// Bande de pellicule : fond sombre, perforations en haut et en bas.
class _FilmStrip extends StatelessWidget {
  final Widget child;
  const _FilmStrip({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FilmStripPainter(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
        child: SizedBox(width: double.infinity, child: FittedBox(fit: BoxFit.scaleDown, child: child)),
      ),
    );
  }
}

class _FilmStripPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final band = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(3));
    canvas.drawRRect(
      band,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3A3A3E), Color(0xFF1C1C1F), Color(0xFF3A3A3E)],
        ).createShader(Offset.zero & size),
    );
    final hole = Paint()..color = const Color(0xFFDCDCDC).withOpacity(0.85);
    const w = 7.0, h = 5.0, step = 14.0;
    for (var x = 6.0; x + w < size.width; x += step) {
      canvas.drawRRect(RRect.fromLTRBR(x, 3, x + w, 3 + h, const Radius.circular(1.2)), hole);
      canvas.drawRRect(
          RRect.fromLTRBR(x, size.height - 3 - h, x + w, size.height - 3, const Radius.circular(1.2)), hole);
    }
    // Liseré des images, entre les perforations.
    final frame = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(Rect.fromLTRB(2, 11, size.width - 2, size.height - 11), frame);
  }

  @override
  bool shouldRepaint(_FilmStripPainter oldDelegate) => false;
}

/// Bobine de film argentée : disque métallique éclairé en haut à gauche
/// (l'éclairage ne tourne pas avec elle), fenêtres en secteurs laissant voir
/// la pellicule enroulée (une par case de [kWheelSegments], avec l'icône de
/// ses jokers), moyeu percé, et repère doré fixe en haut. [turns] est la
/// rotation en tours ; [highlight] fait briller la case gagnante. Sans
/// [colors], dessin simplifié sans icônes (bouton de l'accueil).
class ReelPainter extends CustomPainter {
  final double turns;
  final AppColors? colors;
  final int? highlight;
  final bool showPointer;
  const ReelPainter({this.turns = 0, this.colors, this.highlight, this.showPointer = true});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = min(size.width, size.height) / 2 * (showPointer ? 0.94 : 1.0);
    final center = showPointer ? c.translate(0, size.height / 2 - r) : c;
    final disk = Rect.fromCircle(center: center, radius: r);

    // Ombre portée et disque métallique.
    if (showPointer) {
      canvas.drawCircle(center.translate(0, 4), r, Paint()..color = Colors.black.withOpacity(0.35)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    }
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFAFAFA), Color(0xFFC9CDD1), Color(0xFF8D9399), Color(0xFFD5D8DB), Color(0xFF7C8288)],
          stops: [0, 0.3, 0.55, 0.75, 1],
        ).createShader(disk),
    );
    // Bord roulé.
    canvas.drawCircle(
        center,
        r * 0.975,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.05
          ..shader = const SweepGradient(
            colors: [Color(0xFFEDEFF1), Color(0xFF8A9096), Color(0xFFF4F5F6), Color(0xFF7A8086), Color(0xFFEDEFF1)],
          ).createShader(disk));

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(turns * 2 * pi);

    final inner = r * 0.36, outer = r * 0.86;
    for (var i = 0; i < kWheelSegments.length; i++) {
      final (start, sweep) = wheelSegmentArc(i);
      final gap = min(0.012, sweep * 0.12);
      final a0 = (start + gap) * 2 * pi - pi / 2, a1 = (start + sweep - gap) * 2 * pi - pi / 2;
      final window = Path()
        ..addArc(Rect.fromCircle(center: Offset.zero, radius: outer), a0, a1 - a0)
        ..arcTo(Rect.fromCircle(center: Offset.zero, radius: inner), a1, a0 - a1, false)
        ..close();
      // Creux : ombre interne puis pellicule enroulée (anneaux concentriques).
      canvas.drawPath(window, Paint()..color = const Color(0xFF151517));
      canvas.save();
      canvas.clipPath(window);
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = const Color(0xFF3B3B40);
      for (var rr = inner; rr < outer; rr += 2.6) {
        canvas.drawCircle(Offset.zero, rr, ring);
      }
      if (highlight == i) {
        canvas.drawPath(window, Paint()..color = AppColors.goldBright.withOpacity(0.28));
      }
      canvas.restore();
      final segment = kWheelSegments[i];
      canvas.drawPath(
        window,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = highlight == i ? 2.5 : 1.2
          ..color = highlight == i
              ? AppColors.goldBright
              : segment.isJackpot
                  ? AppColors.gold.withOpacity(0.85)
                  : Colors.white.withOpacity(0.45),
      );

      if (colors != null) {
        final mid = (start + sweep / 2) * 2 * pi - pi / 2;
        final rad = (inner + outer) / 2;
        final n = segment.jokers.length;
        final iconSize = n > 1 ? r * 0.13 : r * 0.19;
        for (var k = 0; k < n; k++) {
          // Plusieurs icônes : réparties le long du rayon de la fenêtre.
          final rk = n == 1 ? rad : inner + (outer - inner) * (k + 0.5) / n;
          final pos = Offset(cos(mid) * rk, sin(mid) * rk);
          final tp = TextPainter(
            text: TextSpan(text: segment.jokers[k].icon, style: TextStyle(fontSize: iconSize)),
            textDirection: TextDirection.ltr,
          )..layout();
          canvas.save();
          canvas.translate(pos.dx, pos.dy);
          canvas.rotate(mid + pi / 2);
          tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
          canvas.restore();
        }
      }
    }

    // Moyeu percé : un trou central et six autour.
    final hub = r * 0.27;
    canvas.drawCircle(
      Offset.zero,
      hub,
      Paint()
        ..shader = const RadialGradient(colors: [Color(0xFFF2F3F4), Color(0xFFA7ADB2)])
            .createShader(Rect.fromCircle(center: Offset.zero, radius: hub)),
    );
    canvas.drawCircle(
        Offset.zero,
        hub,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = const Color(0xFF6E747A));
    final holePaint = Paint()..color = const Color(0xFF2A2B2E);
    canvas.drawCircle(Offset.zero, hub * 0.2, holePaint);
    for (var k = 0; k < 6; k++) {
      final a = k * pi / 3;
      canvas.drawCircle(Offset(cos(a), sin(a)) * hub * 0.58, hub * 0.15, holePaint);
    }
    canvas.restore();

    if (showPointer) {
      // Repère fixe : triangle doré pointant vers la bobine.
      final tip = Offset(center.dx, center.dy - r * 0.78);
      final pointer = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(tip.dx - r * 0.1, center.dy - r - r * 0.04)
        ..lineTo(tip.dx + r * 0.1, center.dy - r - r * 0.04)
        ..close();
      canvas.drawPath(pointer.shift(const Offset(0, 2)), Paint()..color = Colors.black.withOpacity(0.4));
      canvas.drawPath(
          pointer,
          Paint()
            ..shader = const LinearGradient(colors: [AppColors.goldBright, AppColors.gold])
                .createShader(pointer.getBounds()));
      canvas.drawPath(
          pointer,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = const Color(0xFF7A5E20));
    }
  }

  @override
  bool shouldRepaint(ReelPainter oldDelegate) =>
      oldDelegate.turns != turns || oldDelegate.highlight != highlight || oldDelegate.colors?.isLight != colors?.isLight;
}

/// Jokers listés lisiblement (« Révéler, Éliminer… »), pour l'accessibilité.
String wheelPrizeLabel(int index, AppLocalizations t) =>
    kWheelSegments[index].jokers.map((JokerKind k) => jokerName(k, t)).join(', ');
