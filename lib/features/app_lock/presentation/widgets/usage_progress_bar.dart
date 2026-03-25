import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme_tokens.dart';

class UsageProgressBar extends StatelessWidget {
  const UsageProgressBar({
    super.key,
    required this.percentage,
    this.size = 56,
    this.strokeWidth = 5,
    this.showLabel = true,
  });

  final double percentage;
  final double size;
  final double strokeWidth;
  final bool showLabel;

  Color _colorForPercentage(AppColorPalette palette) {
    if (percentage >= 1.0) return palette.error;
    if (percentage >= 0.8) return const Color(0xFFE8A838);
    return palette.success;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: percentage),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return CustomPaint(
                painter: _CircularProgressPainter(
                  progress: value,
                  activeColor: _colorForPercentage(tokens.palette),
                  trackColor:
                      tokens.palette.border.withValues(alpha: 0.3),
                  strokeWidth: strokeWidth,
                ),
              );
            },
          ),
          if (showLabel)
            Center(
              child: Text(
                '${(percentage * 100).toInt()}%',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: size * 0.2,
                      color: _colorForPercentage(tokens.palette),
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  _CircularProgressPainter({
    required this.progress,
    required this.activeColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color activeColor;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Active arc
    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor;
  }
}

class LinearUsageBar extends StatelessWidget {
  const LinearUsageBar({
    super.key,
    required this.percentage,
    this.height = 8,
    this.color,
  });

  final double percentage;
  final double height;
  final Color? color;

  Color _colorForPercentage(AppColorPalette palette) {
    if (percentage >= 1.0) return palette.error;
    if (percentage >= 0.8) return const Color(0xFFE8A838);
    return palette.success;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final barColor = color ?? _colorForPercentage(tokens.palette);

    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: percentage),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return LinearProgressIndicator(
              value: value,
              backgroundColor:
                  tokens.palette.border.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            );
          },
        ),
      ),
    );
  }
}
