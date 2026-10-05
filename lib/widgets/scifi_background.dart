import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Fond animé de l'accueil, façon science-fiction : champ d'étoiles qui
/// dérive lentement, anneaux orbitaux et grille d'horizon, très discrets
/// pour ne jamais gêner la lecture. Figé si l'appareil demande de réduire
/// les animations.
class SciFiBackground extends StatefulWidget {
  final Color baseColor;
  const SciFiBackground({super.key, required this.baseColor});

  @override
  State<SciFiBackground> createState() => _SciFiBackgroundState();
}

class _SciFiBackgroundState extends State<SciFiBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 60));
  final List<_Star> _stars = _Star.generate(80);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _SciFiPainter(animation: _c, stars: _stars, baseColor: widget.baseColor),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _Star {
  final double x, y, depth, phase;
  const _Star(this.x, this.y, this.depth, this.phase);

  static List<_Star> generate(int count) {
    final rng = Random(42);
    return List.generate(count,
        (_) => _Star(rng.nextDouble(), rng.nextDouble(), 0.3 + rng.nextDouble() * 0.7, rng.nextDouble() * 2 * pi));
  }
}

class _SciFiPainter extends CustomPainter {
  final Animation<double> animation;
  final List<_Star> stars;
  final Color baseColor;
  _SciFiPainter({required this.animation, required this.stars, required this.baseColor}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value; // 0 → 1 sur 60 s
    canvas.drawRect(Offset.zero & size, Paint()..color = baseColor);

    _paintHorizonGrid(canvas, size, t);
    _paintRings(canvas, size, t);
    _paintStars(canvas, size, t);
  }

  void _paintStars(Canvas canvas, Size size, double t) {
    final paint = Paint();
    for (final s in stars) {
      // Dérive lente vers le bas, plus rapide pour les étoiles "proches".
      final y = ((s.y + t * 0.35 * s.depth) % 1.0) * size.height;
      final x = s.x * size.width;
      final twinkle = 0.5 + 0.5 * sin(t * 2 * pi * 12 * s.depth + s.phase);
      paint.color = AppColors.goldBright.withOpacity(0.08 + 0.32 * s.depth * twinkle);
      canvas.drawCircle(Offset(x, y), 0.6 + 1.1 * s.depth, paint);
    }
  }

  void _paintRings(Canvas canvas, Size size, double t) {
    final center = Offset(size.width / 2, size.height * 0.36);
    final base = min(size.width, size.height);
    const rings = [(0.30, 1.0, 0.10), (0.42, -0.6, 0.07), (0.55, 0.35, 0.05)];
    for (final (radiusFactor, speed, opacity) in rings) {
      final radius = base * radiusFactor;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppColors.gold.withOpacity(opacity);
      // Anneau en pointillés qui tourne lentement sur lui-même.
      const dashes = 36;
      final rotation = t * 2 * pi * speed;
      for (var i = 0; i < dashes; i++) {
        if (i % 3 == 0) continue;
        final start = rotation + i * 2 * pi / dashes;
        canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, 2 * pi / dashes * 0.7, false, paint);
      }
      // Petit satellite lumineux en orbite.
      final angle = rotation * 1.5;
      canvas.drawCircle(
        center + Offset(cos(angle), sin(angle)) * radius,
        2,
        Paint()..color = AppColors.goldBright.withOpacity(opacity * 3),
      );
    }
  }

  void _paintHorizonGrid(Canvas canvas, Size size, double t) {
    final horizon = size.height * 0.62;
    final paint = Paint()
      ..strokeWidth = 1
      ..color = AppColors.gold.withOpacity(0.06);
    // Lignes de fuite.
    final vanishing = Offset(size.width / 2, horizon);
    for (var i = -8; i <= 8; i++) {
      canvas.drawLine(vanishing, Offset(size.width / 2 + i * size.width / 6, size.height), paint);
    }
    // Lignes horizontales qui défilent vers le bas, de plus en plus espacées.
    const lines = 9;
    for (var i = 0; i < lines; i++) {
      final p = ((i + (t * 30) % 1.0) / lines);
      final y = horizon + (size.height - horizon) * p * p;
      paint.color = AppColors.gold.withOpacity(0.02 + 0.08 * p);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SciFiPainter oldDelegate) =>
      oldDelegate.baseColor != baseColor || oldDelegate.stars != stars;
}
