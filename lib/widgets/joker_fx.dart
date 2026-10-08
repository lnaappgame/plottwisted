import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/joker.dart';
import '../services/app_settings.dart';
import '../theme/app_theme.dart';
import 'joker_style.dart';

class RewardGrant {
  final JokerKind kind;
  final int amount;
  const RewardGrant(this.kind, this.amount);
}

/// Effets visuels des jokers sur l'écran de jeu : faisceau à l'utilisation,
/// bannière puis étoiles quand on en gagne. Les widgets ciblables (boutons
/// de joker, cases, lettres, noms du pitch) s'enregistrent via [key].
class JokerFx extends ChangeNotifier {
  static const beamTravelMs = 350.0;
  static const beamBurstMs = 120.0;
  static const starTravelMs = 650.0;
  static const _starLaunchMs = 1600.0;
  static const _bannerEndMs = 2000.0;
  static const _reducedBannerMs = 2000.0;

  final GlobalKey _layerKey = GlobalKey(debugLabel: 'fx:layer');
  final Map<String, GlobalKey> _keys = {};
  final List<_Flight> _flights = [];
  final List<_Reward> _queue = [];
  _Reward? _banner;
  final Map<JokerKind, int> _pending = {};
  final Map<String, int> _incoming = {};
  VoidCallback? _wake;

  /// Animations réduites (réglage d'accessibilité du téléphone).
  bool reduceMotion = false;

  GlobalKey key(String id) => _keys.putIfAbsent(id, () => GlobalKey(debugLabel: 'fx:$id'));

  /// Jokers gagnés dont l'étoile n'est pas encore arrivée : le bouton les
  /// affiche seulement à l'arrivée.
  int pending(JokerKind kind) => _pending[kind] ?? 0;

  /// Cible qu'un faisceau n'a pas encore atteinte : elle garde son ancien
  /// aspect (case vide, lettre encore là, indice caché) jusqu'à l'impact.
  bool isIncoming(String id) => _incoming.containsKey(id);

  // Horloge des effets (ms), avancée par le Ticker du calque : elle suit le
  // temps des animations Flutter (y compris le temps simulé des tests).
  double _now = 0;

  Rect? _rectOf(String id) {
    final layer = _layerKey.currentContext?.findRenderObject();
    final target = _keys[id]?.currentContext?.findRenderObject();
    if (layer is! RenderBox || target is! RenderBox || !layer.hasSize || !target.hasSize) return null;
    return layer.globalToLocal(target.localToGlobal(Offset.zero)) & target.size;
  }

  /// Faisceau de la couleur du joker, de son bouton vers chaque cible.
  void beam(JokerKind kind, Color color, List<String> targetIds) {
    if (reduceMotion || targetIds.isEmpty) return;
    final ids = targetIds.take(12).toList();
    for (final id in ids) {
      _incoming[id] = (_incoming[id] ?? 0) + 1;
    }
    notifyListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final from = _rectOf('joker:${kind.name}');
      var i = 0;
      for (final id in ids) {
        final to = from == null ? null : _rectOf(id);
        if (to == null) {
          _land(id);
          continue;
        }
        _flights.add(_Flight(
          star: false,
          color: color,
          from: from!.center,
          to: to.center,
          bend: i.isEven ? 1 : -1,
          onArrive: () => _land(id),
        ));
        i++;
      }
      if (i > 0) _wake?.call();
    });
  }

  void _land(String id) {
    final left = (_incoming[id] ?? 0) - 1;
    if (left > 0) {
      _incoming[id] = left;
    } else {
      _incoming.remove(id);
    }
    notifyListeners();
  }

  /// Bannière "joker(s) gagné(s)", puis une étoile par joker vers son bouton.
  void reward({String? eyebrow, required List<RewardGrant> grants}) {
    final kept = grants.where((g) => g.amount > 0).toList();
    if (kept.isEmpty) return;
    for (final g in kept) {
      _pending[g.kind] = pending(g.kind) + g.amount;
    }
    notifyListeners();
    _queue.add(_Reward(eyebrow, kept));
    if (_banner == null) _nextBanner();
  }

  void _nextBanner() {
    _banner = _queue.isEmpty ? null : _queue.removeAt(0);
    _wake?.call();
  }

  void _settle(JokerKind kind, int amount) {
    final left = pending(kind) - amount;
    if (left > 0) {
      _pending[kind] = left;
    } else {
      _pending.remove(kind);
    }
    notifyListeners();
  }

  void _launchStars(_Reward reward) {
    for (var i = 0; i < reward.grants.length; i++) {
      final g = reward.grants[i];
      final from = _rectOf('chip:$i');
      final to = _rectOf('joker:${g.kind.name}');
      if (from == null || to == null) {
        _settle(g.kind, g.amount);
        continue;
      }
      _flights.add(_Flight(
        star: true,
        color: reward.colors[i] ?? AppColors.goldBright,
        from: from.center,
        to: to.center,
        bend: i.isEven ? 1 : -1,
        onArrive: () => _settle(g.kind, g.amount),
      ));
    }
  }

  /// Avance l'animation ; faux quand plus rien n'est en cours.
  bool _advance(double now) {
    _now = now;
    // L'impact (faisceau) ou l'arrivée (étoile) déclenche le changement visible ;
    // la gerbe du faisceau continue ensuite un court instant.
    for (final f in List.of(_flights)) {
      final t = now - (f.start ??= now);
      if (!f.arrived && t >= (f.star ? starTravelMs : beamTravelMs)) {
        f.arrived = true;
        f.onArrive?.call();
      }
    }
    _flights.removeWhere((f) => now - f.start! >= (f.star ? starTravelMs : beamTravelMs + beamBurstMs));
    final banner = _banner;
    if (banner != null) {
      final t = now - (banner.start ??= now);
      if (reduceMotion) {
        if (t >= _reducedBannerMs) {
          for (final g in banner.grants) {
            _settle(g.kind, g.amount);
          }
          _nextBanner();
        }
      } else {
        if (!banner.launched && t >= _starLaunchMs) {
          banner.launched = true;
          _launchStars(banner);
        }
        if (t >= _bannerEndMs) _nextBanner();
      }
    }
    return _flights.isNotEmpty || _banner != null;
  }

  @override
  void dispose() {
    _wake = null;
    super.dispose();
  }
}

class _Reward {
  final String? eyebrow;
  final List<RewardGrant> grants;
  final List<Color?> colors;
  double? start;
  bool launched = false;
  _Reward(this.eyebrow, this.grants) : colors = List.filled(grants.length, null);
}

class _Flight {
  final bool star;
  final Color color;
  final Offset from;
  final Offset to;
  double? start;
  bool arrived = false;
  final int bend;
  final VoidCallback? onArrive;
  _Flight({
    required this.star,
    required this.color,
    required this.from,
    required this.to,
    required this.bend,
    this.onArrive,
  });

  Offset get _control {
    final d = to - from;
    final len = d.distance;
    if (len == 0) return from;
    final perp = Offset(-d.dy, d.dx) / len;
    return (from + to) / 2 + perp * (len * 0.22 * bend);
  }

  Offset at(double t) {
    final c = _control;
    final u = 1 - t;
    return from * (u * u) + c * (2 * u * t) + to * (t * t);
  }
}

/// Calque posé au-dessus du plateau de jeu (ne capte aucun toucher).
class JokerFxLayer extends StatefulWidget {
  final JokerFx fx;
  const JokerFxLayer({super.key, required this.fx});

  @override
  State<JokerFxLayer> createState() => _JokerFxLayerState();
}

class _JokerFxLayerState extends State<JokerFxLayer> with SingleTickerProviderStateMixin {
  double _base = 0;
  late final Ticker _ticker = createTicker((elapsed) {
    final now = _base + elapsed.inMicroseconds / 1000.0;
    final active = widget.fx._advance(now);
    if (mounted) setState(() {});
    if (!active) {
      _base = now;
      _ticker.stop();
    }
  });

  @override
  void initState() {
    super.initState();
    widget.fx._wake = _wake;
  }

  void _wake() {
    if (mounted && !_ticker.isActive) _ticker.start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.fx.reduceMotion = MediaQuery.of(context).disableAnimations;
  }

  @override
  void dispose() {
    if (widget.fx._wake == _wake) widget.fx._wake = null;
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fx = widget.fx;
    final banner = fx._banner;
    return IgnorePointer(
      child: SizedBox.expand(
        key: fx._layerKey,
        child: Stack(
          children: [
            if (banner != null) _RewardBanner(fx: fx, reward: banner, now: fx._now),
            Positioned.fill(child: CustomPaint(painter: _FlightPainter(List.of(fx._flights), fx._now))),
          ],
        ),
      ),
    );
  }
}

class _RewardBanner extends StatelessWidget {
  final JokerFx fx;
  final _Reward reward;
  final double now;
  const _RewardBanner({required this.fx, required this.reward, required this.now});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final settings = context.watch<AppSettings>();
    final colors = AppColors(settings.isLightTheme, colorblind: settings.colorblindMode);
    final elapsed = now - (reward.start ?? now);
    final appear = Curves.easeOutBack.transform((elapsed / 220).clamp(0.0, 1.0));
    final fadeOut = fx.reduceMotion
        ? 1.0
        : 1 - ((elapsed - JokerFx._starLaunchMs) / (JokerFx._bannerEndMs - JokerFx._starLaunchMs)).clamp(0.0, 1.0);
    final total = reward.grants.fold<int>(0, (s, g) => s + g.amount);

    return Align(
      alignment: const Alignment(0, -0.45),
      child: Opacity(
        opacity: (appear.clamp(0.0, 1.0) * fadeOut).clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 0.85 + 0.15 * appear,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 320),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
            decoration: BoxDecoration(
              color: colors.bgPanel2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.gold.withOpacity(0.7), width: 1.2),
              boxShadow: [BoxShadow(color: AppColors.gold.withOpacity(0.28), blurRadius: 22, spreadRadius: 1)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (reward.eyebrow != null) ...[
                  Text(reward.eyebrow!,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body(size: 12, weight: FontWeight.w700, color: colors.cream)),
                  const SizedBox(height: 4),
                ],
                Text(total > 1 ? t.gameJokersWon : t.gameJokerWon,
                    style: AppTextStyles.body(size: 11, weight: FontWeight.w700, color: AppColors.gold)
                        .copyWith(letterSpacing: 2)),
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < reward.grants.length; i++) _chip(colors, i, reward.grants[i], t),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(AppColors colors, int i, RewardGrant g, AppLocalizations t) {
    final color = jokerColor(g.kind, colors);
    reward.colors[i] = color;
    return Container(
      key: fx.key('chip:$i'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.85)),
      ),
      child: Text(
        '${g.kind.icon} ${jokerName(g.kind, t)}${g.amount > 1 ? '  ×${g.amount}' : ''}',
        style: AppTextStyles.body(size: 13, weight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _FlightPainter extends CustomPainter {
  final List<_Flight> flights;
  final double now;
  _FlightPainter(this.flights, this.now);

  @override
  void paint(Canvas canvas, Size size) {
    for (final f in flights) {
      final elapsed = now - (f.start ?? now);
      if (f.star) {
        _paintStar(canvas, f, (elapsed / JokerFx.starTravelMs).clamp(0.0, 1.0));
      } else {
        _paintBeam(canvas, f, elapsed);
      }
    }
  }

  // Pas de MaskFilter.blur : sur téléphone, le flou coûte une passe hors écran
  // par tracé (et fige l'écran ~300 ms à sa première utilisation). Les halos
  // sont des dégradés radiaux et la traînée des traits superposés.

  /// Halo doux : dégradé radial de [color] vers le transparent.
  void _halo(Canvas canvas, Offset c, double radius, Color color, double opacity) {
    if (radius <= 0 || opacity <= 0) return;
    canvas.drawCircle(
      c,
      radius,
      Paint()
        ..shader = RadialGradient(colors: [color.withOpacity(opacity), color.withOpacity(0)])
            .createShader(Rect.fromCircle(center: c, radius: radius)),
    );
  }

  void _trail(Canvas canvas, _Flight f, double head, double length, double width) {
    const segments = 14;
    final tail = max(0.0, head - length);
    final outer = Paint()..strokeCap = StrokeCap.round;
    final inner = Paint()..strokeCap = StrokeCap.round;
    final core = Paint()..strokeCap = StrokeCap.round;
    for (var k = 0; k < segments; k++) {
      final a = f.at(tail + (head - tail) * k / segments);
      final b = f.at(tail + (head - tail) * (k + 1) / segments);
      final w = (k + 1) / segments;
      outer
        ..color = f.color.withOpacity(0.12 * w)
        ..strokeWidth = width * 3.4 * w;
      inner
        ..color = f.color.withOpacity(0.28 * w)
        ..strokeWidth = width * 2 * w;
      core
        ..color = f.color.withOpacity(0.95 * w)
        ..strokeWidth = width * w;
      canvas.drawLine(a, b, outer);
      canvas.drawLine(a, b, inner);
      canvas.drawLine(a, b, core);
    }
  }

  void _paintBeam(Canvas canvas, _Flight f, double elapsed) {
    // Départ immédiat (tir), léger ralenti avant l'impact.
    final p = Curves.easeOutSine.transform((elapsed / JokerFx.beamTravelMs).clamp(0.0, 1.0));
    if (elapsed < JokerFx.beamTravelMs) {
      _trail(canvas, f, p, 0.35, 3.2);
      final head = f.at(p);
      _halo(canvas, head, 14, f.color, 0.7);
      canvas.drawCircle(head, 3, Paint()..color = Colors.white.withOpacity(0.95));
    } else {
      final q = ((elapsed - JokerFx.beamTravelMs) / JokerFx.beamBurstMs).clamp(0.0, 1.0);
      canvas.drawCircle(
          f.to,
          6 + 16 * q,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5 * (1 - q)
            ..color = f.color.withOpacity(0.9 * (1 - q)));
      _halo(canvas, f.to, 16 * (1 - q), f.color, 0.5 * (1 - q));
    }
  }

  void _paintStar(Canvas canvas, _Flight f, double t) {
    final p = Curves.easeInOutCubic.transform(t);
    _trail(canvas, f, p, 0.25, 2.4);
    final c = f.at(p);
    final r = 7 + 4 * sin(pi * t);
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final angle = pi / 4 * i + t * pi * 1.5;
      final radius = i.isEven ? r : r * 0.38;
      final pt = c + Offset(cos(angle), sin(angle)) * radius;
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    _halo(canvas, c, r * 2.4, f.color, 0.6);
    canvas.drawPath(path, Paint()..color = f.color);
    canvas.drawCircle(c, r * 0.28, Paint()..color = Colors.white.withOpacity(0.9));
  }

  @override
  bool shouldRepaint(covariant _FlightPainter old) => true;
}
