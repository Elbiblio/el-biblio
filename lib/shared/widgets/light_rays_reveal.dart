import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_animations.dart';

/// Wraps a child (typically a truth-revealing text) with a soft sunburst of
/// animated light rays that fade in behind it and rotate slowly.
///
/// Tuned for sacred / awe moments — not decorative. Use sparingly on the
/// handful of text lines that carry the emotional weight of a screen.
class LightRaysReveal extends StatefulWidget {
  const LightRaysReveal({
    super.key,
    required this.child,
    this.rayCount = 10,
    this.rayColor,
    this.maxOpacity = 0.55,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 1600),
    this.rotate = true,
    this.expandBeyond = 60,
  });

  final Widget child;
  final int rayCount;
  final Color? rayColor;
  final double maxOpacity;
  final Duration delay;
  final Duration duration;
  final bool rotate;

  /// How many logical pixels the rays extend beyond the child's bounds.
  final double expandBeyond;

  @override
  State<LightRaysReveal> createState() => _LightRaysRevealState();
}

class _LightRaysRevealState extends State<LightRaysReveal>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _spinController;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    );

    _fade = CurvedAnimation(
      parent: _fadeController,
      curve: AppAnimations.fadeCurve,
    );
    _scale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: AppAnimations.defaultCurve,
      ),
    );

    Future.delayed(widget.delay, () {
      if (!mounted) return;
      _fadeController.forward();
      final reducedMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (widget.rotate && !reducedMotion) _spinController.repeat();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.rayColor ??
        Theme.of(context).colorScheme.primary.withValues(alpha: 1.0);
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return AnimatedBuilder(
      animation: Listenable.merge([_fadeController, _spinController]),
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Transform.scale(
                    scale: _scale.value,
                    child: Opacity(
                      opacity: _fade.value * widget.maxOpacity,
                      child: CustomPaint(
                        painter: _LightRaysPainter(
                          color: color,
                          rayCount: widget.rayCount,
                          rotation: reducedMotion
                              ? 0
                              : _spinController.value * 2 * math.pi,
                          expand: widget.expandBeyond,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            child!,
          ],
        );
      },
      child: widget.child,
    );
  }
}

class _LightRaysPainter extends CustomPainter {
  _LightRaysPainter({
    required this.color,
    required this.rayCount,
    required this.rotation,
    required this.expand,
  });

  final Color color;
  final int rayCount;
  final double rotation;
  final double expand;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.max(size.width, size.height) / 2 + expand;

    // Halo — soft radial glow seating the rays.
    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.35),
          color.withValues(alpha: 0.08),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, haloPaint);

    // Individual rays — thin triangular wedges with a linear gradient so
    // each ray feels like it tapers into the distance.
    final rayWidth = (2 * math.pi) / (rayCount * 3.2);
    for (var i = 0; i < rayCount; i++) {
      final theta = rotation + (i * 2 * math.pi / rayCount);
      final tip = Offset(
        center.dx + math.cos(theta) * radius,
        center.dy + math.sin(theta) * radius,
      );
      final left = Offset(
        center.dx + math.cos(theta - rayWidth) * (radius * 0.25),
        center.dy + math.sin(theta - rayWidth) * (radius * 0.25),
      );
      final right = Offset(
        center.dx + math.cos(theta + rayWidth) * (radius * 0.25),
        center.dy + math.sin(theta + rayWidth) * (radius * 0.25),
      );

      final path = Path()
        ..moveTo(left.dx, left.dy)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(right.dx, right.dy)
        ..close();

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color.withValues(alpha: 0.55), color.withValues(alpha: 0.0)],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LightRaysPainter old) =>
      old.rotation != rotation ||
      old.color != color ||
      old.rayCount != rayCount ||
      old.expand != expand;
}
