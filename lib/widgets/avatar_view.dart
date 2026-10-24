import 'dart:math';
import 'package:flutter/material.dart';
import '../services/app_settings.dart';

/// Avatar du joueur dans un rond : un emoji, ou l'un des avatars dessinés
/// de l'event Halloween (tête de citrouille, citrouille en feu animée).
class AvatarView extends StatelessWidget {
  final String avatar;
  final double radius;
  final Color background;
  const AvatarView({super.key, required this.avatar, required this.radius, required this.background});

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    if (avatar == kPumpkinAvatar || avatar == kFirePumpkinAvatar) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: avatar == kFirePumpkinAvatar ? const Color(0xFF1B1326) : background, shape: BoxShape.circle),
        padding: EdgeInsets.all(radius * 0.12),
        child: avatar == kFirePumpkinAvatar ? const FirePumpkin() : const CustomPaint(painter: PumpkinPainter()),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: background,
      child: Text(avatar, style: TextStyle(fontSize: radius * 0.95)),
    );
  }
}

/// Tête de citrouille sculptée, éclairée de l'intérieur. [glow] (0 à 1)
/// avive la lueur des yeux et de la bouche.
class PumpkinPainter extends CustomPainter {
  final double glow;
  const PumpkinPainter({this.glow = 0.6});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final c = Offset(w / 2, h * 0.56);
    final body = Rect.fromCenter(center: c, width: w * 0.92, height: h * 0.74);

    // Côtes de la citrouille : trois ovales qui se chevauchent.
    final skin = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.3, -0.4),
        colors: [Color(0xFFFFB347), Color(0xFFF28C28), Color(0xFFB4561A)],
        stops: [0, 0.55, 1],
      ).createShader(body);
    for (final dx in [-0.22, 0.22, 0.0]) {
      canvas.drawOval(
        Rect.fromCenter(center: c.translate(w * dx, 0), width: body.width * 0.62, height: body.height),
        skin,
      );
    }
    final rib = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.02
      ..color = const Color(0xFF9A4512).withOpacity(0.55);
    for (final dx in [-0.13, 0.13]) {
      canvas.drawArc(Rect.fromCenter(center: c.translate(w * dx, 0), width: body.width * 0.36, height: body.height * 0.96),
          -pi / 2 - 1.1, 2.2, false, rib);
    }
    // Queue.
    final stem = Path()
      ..moveTo(w * 0.47, h * 0.22)
      ..quadraticBezierTo(w * 0.5, h * 0.06, w * 0.6, h * 0.04)
      ..lineTo(w * 0.62, h * 0.09)
      ..quadraticBezierTo(w * 0.56, h * 0.12, w * 0.55, h * 0.23)
      ..close();
    canvas.drawPath(stem, Paint()..color = const Color(0xFF4E7A32));

    // Visage sculpté : lueur jaune, plus vive avec [glow].
    final light = Color.lerp(const Color(0xFFFFC94A), const Color(0xFFFFF3B0), glow)!;
    final face = Paint()..color = light;
    final eyeL = Path()
      ..moveTo(w * 0.24, h * 0.50)
      ..lineTo(w * 0.33, h * 0.34)
      ..lineTo(w * 0.42, h * 0.50)
      ..close();
    final eyeR = Path()
      ..moveTo(w * 0.58, h * 0.50)
      ..lineTo(w * 0.67, h * 0.34)
      ..lineTo(w * 0.76, h * 0.50)
      ..close();
    final mouth = Path()
      ..moveTo(w * 0.22, h * 0.62)
      ..quadraticBezierTo(w * 0.5, h * 0.92, w * 0.78, h * 0.62)
      ..lineTo(w * 0.68, h * 0.66)
      ..lineTo(w * 0.62, h * 0.62)
      ..lineTo(w * 0.56, h * 0.68)
      ..lineTo(w * 0.5, h * 0.63)
      ..lineTo(w * 0.44, h * 0.68)
      ..lineTo(w * 0.38, h * 0.62)
      ..lineTo(w * 0.32, h * 0.66)
      ..close();
    final halo = Paint()
      ..color = light.withOpacity(0.5 * glow)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.04);
    for (final p in [eyeL, eyeR, mouth]) {
      canvas.drawPath(p, halo);
      canvas.drawPath(p, face);
    }
  }

  @override
  bool shouldRepaint(PumpkinPainter oldDelegate) => oldDelegate.glow != glow;
}

/// Citrouille en feu : des flammes démoniaques sortent des yeux, la lueur
/// intérieure vacille.
class FirePumpkin extends StatefulWidget {
  const FirePumpkin({super.key});

  @override
  State<FirePumpkin> createState() => _FirePumpkinState();
}

class _FirePumpkinState extends State<FirePumpkin> with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
    ..repeat();

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (context, _) {
        final v = _t.value;
        final flicker = 0.75 + 0.25 * sin(v * 2 * pi * 3);
        return CustomPaint(
          painter: PumpkinPainter(glow: flicker),
          foregroundPainter: _EyeFlamesPainter(v),
        );
      },
    );
  }
}

class _EyeFlamesPainter extends CustomPainter {
  final double t;
  const _EyeFlamesPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    for (final (i, eyeX) in [0.33, 0.67].indexed) {
      for (var k = 0; k < 3; k++) {
        final phase = (t + k / 3 + i * 0.17) % 1.0;
        final height = h * (0.22 + 0.12 * sin((phase + k) * pi));
        final sway = sin((phase * 2 + k) * pi) * w * 0.035;
        final base = Offset(w * eyeX + (k - 1) * w * 0.035, h * 0.43);
        final tip = base.translate(sway, -height);
        final flame = Path()
          ..moveTo(base.dx - w * 0.05, base.dy)
          ..quadraticBezierTo(base.dx - w * 0.06, base.dy - height * 0.5, tip.dx, tip.dy)
          ..quadraticBezierTo(base.dx + w * 0.06, base.dy - height * 0.5, base.dx + w * 0.05, base.dy)
          ..close();
        final alpha = (1 - phase * 0.6).clamp(0.0, 1.0);
        canvas.drawPath(
          flame,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                const Color(0xFFFFF3B0).withOpacity(alpha),
                const Color(0xFFFF7A1A).withOpacity(alpha),
                const Color(0xFFC81E1E).withOpacity(alpha * 0.85),
              ],
            ).createShader(flame.getBounds()),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_EyeFlamesPainter oldDelegate) => oldDelegate.t != t;
}
