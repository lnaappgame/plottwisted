import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/app_settings.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';

/// Clap de cinéma plein écran : la latte se referme avec son et vibration,
/// [onClosed] est appelé juste après l'impact (l'écran suivant s'ouvre
/// dessous), puis le clap s'efface.
class ClapperTransition {
  static bool _running = false;

  static void play(BuildContext context, VoidCallback onClosed) {
    if (_running) return;
    final settings = context.read<AppSettings>();
    final sound = context.read<SoundService>();
    void clap() {
      if (settings.sfxOn) sound.playClap();
      if (settings.vibrationsOn) HapticFeedback.mediumImpact();
    }

    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      clap();
      onClosed();
      return;
    }

    _running = true;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ClapperOverlay(
        english: settings.locale == "en",
        onClap: clap,
        onClosed: onClosed,
        onDone: () {
          entry.remove();
          _running = false;
        },
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(entry);
  }
}

class _ClapperOverlay extends StatefulWidget {
  final bool english;
  final VoidCallback onClap;
  final VoidCallback onClosed;
  final VoidCallback onDone;
  const _ClapperOverlay({required this.english, required this.onClap, required this.onClosed, required this.onDone});

  @override
  State<_ClapperOverlay> createState() => _ClapperOverlayState();
}

class _ClapperOverlayState extends State<_ClapperOverlay> with SingleTickerProviderStateMixin {
  static const _totalMs = 1050.0;
  static const _closeStartMs = 100.0;
  static const _impactMs = 360.0;
  // Le son part un peu avant l'impact visuel pour compenser la latence audio.
  static const _soundMs = 330.0;
  static const _actionMs = 430.0;
  // Sortie : le clap grossit en filant vers le haut, comme s'il sortait du cadre.
  static const _exitStartMs = 470.0;

  late final AnimationController _c;
  bool _clapped = false;
  bool _actionDone = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: Duration(milliseconds: _totalMs.toInt()))..addListener(_onTick);
    _c.forward().whenComplete(widget.onDone);
  }

  void _onTick() {
    final ms = _c.value * _totalMs;
    if (!_clapped && ms >= _soundMs) {
      _clapped = true;
      widget.onClap();
    }
    if (!_actionDone && ms >= _actionMs) {
      _actionDone = true;
      widget.onClosed();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final ms = _c.value * _totalMs;
        final size = MediaQuery.sizeOf(context);
        final fadeIn = (ms / 120).clamp(0.0, 1.0);
        final closeT = Curves.easeIn.transform(((ms - _closeStartMs) / (_impactMs - _closeStartMs)).clamp(0.0, 1.0));
        final impact = ms < _impactMs ? 0.0 : 1 - ((ms - _impactMs) / 160).clamp(0.0, 1.0);
        final exit = Curves.easeIn.transform(((ms - _exitStartMs) / (_totalMs - _exitStartMs)).clamp(0.0, 1.0));
        final boardOpacity = min(fadeIn, 1 - ((exit - 0.8) / 0.2).clamp(0.0, 1.0));
        return Material(
          type: MaterialType.transparency,
          child: AbsorbPointer(
            child: Container(
              color: Colors.black.withOpacity(0.55 * fadeIn * (1 - exit)),
              alignment: Alignment.center,
              child: Opacity(
                opacity: boardOpacity,
                child: Transform.translate(
                  offset: Offset(size.width * 0.25 * exit, -size.height * 0.75 * exit),
                  child: Transform.rotate(
                    angle: 0.3 * exit,
                    child: Transform.scale(
                      scale: 0.9 + 0.1 * fadeIn + 0.05 * impact + 2.2 * exit,
                      child: _Clapperboard(english: widget.english, stickAngle: -0.6 * (1 - closeT)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Clapperboard extends StatelessWidget {
  final bool english;
  final double stickAngle;
  const _Clapperboard({required this.english, required this.stickAngle});

  static const _width = 230.0;
  static const _stickHeight = 30.0;

  @override
  Widget build(BuildContext context) {
    final labelStyle = AppTextStyles.body(size: 10, weight: FontWeight.w700, color: const Color(0xFFECE3D2))
        .copyWith(letterSpacing: 2, decoration: TextDecoration.none);
    return SizedBox(
      width: _width,
      height: 200,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Ardoise.
          Positioned(
            left: 0,
            right: 0,
            top: _stickHeight + 4,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF15110D),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                border: Border.all(color: const Color(0xFFECE3D2), width: 2),
              ),
              child: Column(
                children: [
                  const SizedBox(height: _stickHeight + 6, width: _width, child: _Stripes()),
                  const SizedBox(height: 14),
                  Text('PLOT TWIST(ED)',
                      style: AppTextStyles.display(size: 26).copyWith(decoration: TextDecoration.none)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(english ? "SCENE  1" : "SCÈNE  1", style: labelStyle),
                      Text(english ? "TAKE  1" : "PRISE  1", style: labelStyle),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Latte mobile, articulée sur son extrémité gauche.
          Positioned(
            left: 0,
            top: 0,
            width: _width,
            height: _stickHeight,
            child: Transform.rotate(
              angle: stickAngle,
              alignment: Alignment.bottomLeft,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: const Color(0xFFECE3D2), width: 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: const _Stripes(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stripes extends StatelessWidget {
  const _Stripes();

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _StripesPainter());
}

class _StripesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF15110D));
    final light = Paint()..color = const Color(0xFFECE3D2);
    const band = 22.0;
    for (var x = -size.height; x < size.width + size.height; x += band * 2) {
      final path = Path()
        ..moveTo(x, size.height)
        ..lineTo(x + band, size.height)
        ..lineTo(x + band + size.height, 0)
        ..lineTo(x + size.height, 0)
        ..close();
      canvas.drawPath(path, light);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
