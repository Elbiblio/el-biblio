import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/models/companion_character.dart';
import '../../domain/models/companion_mood.dart';

/// Breathing, mood-driven gradient orb. Per-character palette, no face.
///
/// This is the companion's *presence* — it lives across onboarding, chat
/// screens, and the Today bubble. Breathing rate + glow intensity is tied
/// to [mood]: idle = slow, thinking = shimmer, speaking = spring bounce.
class CompanionOrb extends StatefulWidget {
  const CompanionOrb({
    super.key,
    required this.character,
    this.mood = CompanionMood.idle,
    this.size = 96,
  });

  final CompanionCharacter character;
  final CompanionMood mood;
  final double size;

  @override
  State<CompanionOrb> createState() => _CompanionOrbState();
}

class _CompanionOrbState extends State<CompanionOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _durationForMood(widget.mood),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant CompanionOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mood != widget.mood) {
      _controller.duration = _durationForMood(widget.mood);
      _controller.repeat();
    }
  }

  Duration _durationForMood(CompanionMood mood) {
    return switch (mood) {
      CompanionMood.idle => const Duration(milliseconds: 5000),
      CompanionMood.attentive => const Duration(milliseconds: 3200),
      CompanionMood.thinking => const Duration(milliseconds: 1600),
      CompanionMood.speaking => const Duration(milliseconds: 2000),
      CompanionMood.warm => const Duration(milliseconds: 4000),
      CompanionMood.recalling => const Duration(milliseconds: 2800),
    };
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _OrbPainter(
            t: _controller.value,
            mood: widget.mood,
            stops: widget.character.gradientStops,
          ),
        );
      },
    );
  }
}

class _OrbPainter extends CustomPainter {
  _OrbPainter({required this.t, required this.mood, required this.stops});

  final double t;
  final CompanionMood mood;
  final List<Color> stops;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final breathAmp = switch (mood) {
      CompanionMood.idle => 0.03,
      CompanionMood.attentive => 0.05,
      CompanionMood.thinking => 0.08,
      CompanionMood.speaking => 0.11,
      CompanionMood.warm => 0.06,
      CompanionMood.recalling => 0.07,
    };

    final scale = 1.0 + breathAmp * math.sin(t * 2 * math.pi);
    final radius = (size.width / 2) * scale;

    final glowRadius = radius * 1.35;
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          stops.first.withValues(alpha: _glowAlpha(mood, t)),
          stops.first.withValues(alpha: 0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: glowRadius));
    canvas.drawCircle(center, glowRadius, glowPaint);

    final bodyPaint = Paint()
      ..shader = LinearGradient(
        colors: stops,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, bodyPaint);

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(
      Offset(center.dx - radius * 0.28, center.dy - radius * 0.3),
      radius * 0.22,
      highlightPaint,
    );
  }

  double _glowAlpha(CompanionMood mood, double t) {
    final base = switch (mood) {
      CompanionMood.idle => 0.12,
      CompanionMood.attentive => 0.18,
      CompanionMood.thinking => 0.28,
      CompanionMood.speaking => 0.34,
      CompanionMood.warm => 0.24,
      CompanionMood.recalling => 0.22,
    };
    final shimmer = 0.06 * math.sin(t * 2 * math.pi);
    return (base + shimmer).clamp(0.0, 1.0);
  }

  @override
  bool shouldRepaint(covariant _OrbPainter old) {
    return old.t != t || old.mood != mood || old.stops != stops;
  }
}
