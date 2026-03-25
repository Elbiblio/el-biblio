import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_tokens.dart';

/// A beautiful custom-painted radar/spider chart for spiritual dimensions.
class SpiritualRadarChart extends StatefulWidget {
  const SpiritualRadarChart({
    super.key,
    required this.dimensions,
    this.previousDimensions,
    this.size = 280,
    this.showLabels = true,
    this.showValues = false,
    this.animate = true,
  });

  final Map<String, double> dimensions;
  final Map<String, double>? previousDimensions;
  final double size;
  final bool showLabels;
  final bool showValues;
  final bool animate;

  @override
  State<SpiritualRadarChart> createState() => _SpiritualRadarChartState();
}

class _SpiritualRadarChartState extends State<SpiritualRadarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _RadarChartPainter(
              dimensions: widget.dimensions,
              previousDimensions: widget.previousDimensions,
              progress: _animation.value,
              primaryColor: tokens.palette.primary,
              previousColor: tokens.palette.primaryLight.withValues(alpha: 0.4),
              gridColor: tokens.palette.border,
              textColor: tokens.palette.textSecondary,
              fillColor: tokens.palette.primary.withValues(alpha: 0.15),
              previousFillColor: tokens.palette.primaryLight.withValues(alpha: 0.08),
              showLabels: widget.showLabels,
              showValues: widget.showValues,
            ),
          ),
        );
      },
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  _RadarChartPainter({
    required this.dimensions,
    this.previousDimensions,
    required this.progress,
    required this.primaryColor,
    required this.previousColor,
    required this.gridColor,
    required this.textColor,
    required this.fillColor,
    required this.previousFillColor,
    required this.showLabels,
    required this.showValues,
  });

  final Map<String, double> dimensions;
  final Map<String, double>? previousDimensions;
  final double progress;
  final Color primaryColor;
  final Color previousColor;
  final Color gridColor;
  final Color textColor;
  final Color fillColor;
  final Color previousFillColor;
  final bool showLabels;
  final bool showValues;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - (showLabels ? 40 : 10);
    final keys = dimensions.keys.toList();
    final count = keys.length;
    if (count < 3) return;

    final angleStep = (2 * pi) / count;

    // Draw grid rings
    _drawGrid(canvas, center, radius, count, angleStep);

    // Draw previous dimensions (comparison)
    if (previousDimensions != null && previousDimensions!.isNotEmpty) {
      _drawDataPolygon(
        canvas,
        center,
        radius,
        keys,
        previousDimensions!,
        angleStep,
        previousColor,
        previousFillColor,
        2.0,
      );
    }

    // Draw current dimensions
    _drawDataPolygon(
      canvas,
      center,
      radius,
      keys,
      dimensions,
      angleStep,
      primaryColor,
      fillColor,
      2.5,
    );

    // Draw data points
    _drawDataPoints(canvas, center, radius, keys, dimensions, angleStep);

    // Draw labels
    if (showLabels) {
      _drawLabels(canvas, center, radius, keys, angleStep, size);
    }
  }

  void _drawGrid(
    Canvas canvas,
    Offset center,
    double radius,
    int count,
    double angleStep,
  ) {
    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final axisPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Draw concentric polygons (5 levels)
    for (int level = 1; level <= 5; level++) {
      final levelRadius = radius * level / 5;
      final path = Path();
      for (int i = 0; i <= count; i++) {
        final angle = -pi / 2 + angleStep * (i % count);
        final x = center.dx + levelRadius * cos(angle);
        final y = center.dy + levelRadius * sin(angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // Draw axis lines
    for (int i = 0; i < count; i++) {
      final angle = -pi / 2 + angleStep * i;
      final end = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      canvas.drawLine(center, end, axisPaint);
    }
  }

  void _drawDataPolygon(
    Canvas canvas,
    Offset center,
    double radius,
    List<String> keys,
    Map<String, double> data,
    double angleStep,
    Color strokeColor,
    Color fill,
    double strokeWidth,
  ) {
    final path = Path();
    final fillPaint = Paint()
      ..color = fill
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.round;

    for (int i = 0; i <= keys.length; i++) {
      final key = keys[i % keys.length];
      final value = (data[key] ?? 0.0).clamp(0.0, 1.0) * progress;
      final angle = -pi / 2 + angleStep * (i % keys.length);
      final x = center.dx + radius * value * cos(angle);
      final y = center.dy + radius * value * sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  void _drawDataPoints(
    Canvas canvas,
    Offset center,
    double radius,
    List<String> keys,
    Map<String, double> data,
    double angleStep,
  ) {
    final dotPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    final dotBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (int i = 0; i < keys.length; i++) {
      final value = (data[keys[i]] ?? 0.0).clamp(0.0, 1.0) * progress;
      final angle = -pi / 2 + angleStep * i;
      final x = center.dx + radius * value * cos(angle);
      final y = center.dy + radius * value * sin(angle);

      canvas.drawCircle(Offset(x, y), 5, dotBorderPaint);
      canvas.drawCircle(Offset(x, y), 3.5, dotPaint);
    }
  }

  void _drawLabels(
    Canvas canvas,
    Offset center,
    double radius,
    List<String> keys,
    double angleStep,
    Size size,
  ) {
    for (int i = 0; i < keys.length; i++) {
      final angle = -pi / 2 + angleStep * i;
      final labelRadius = radius + 22;
      final x = center.dx + labelRadius * cos(angle);
      final y = center.dy + labelRadius * sin(angle);

      final label = keys[i];
      final displayLabel = label.length > 10 ? '${label.substring(0, 9)}.' : label;

      String valueStr = '';
      if (showValues) {
        final val = ((dimensions[label] ?? 0.0) * 100).round();
        valueStr = ' ($val%)';
      }

      final textSpan = TextSpan(
        text: '$displayLabel$valueStr',
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();

      final offset = Offset(
        x - textPainter.width / 2,
        y - textPainter.height / 2,
      );

      textPainter.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.dimensions != dimensions ||
        oldDelegate.previousDimensions != previousDimensions;
  }
}
