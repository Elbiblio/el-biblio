import 'package:flutter/material.dart';

import '../../features/commit/data/commitment_media_catalog.dart';

class JourneyProgressVisual extends StatefulWidget {
  final String category;
  final int completedDays;
  final int totalDays;
  final int currentDay;
  final double height;
  final bool showAnimation;

  const JourneyProgressVisual({
    super.key,
    required this.category,
    required this.completedDays,
    required this.totalDays,
    this.currentDay = 0,
    this.height = 200,
    this.showAnimation = true,
  });

  @override
  State<JourneyProgressVisual> createState() => _JourneyProgressVisualState();
}

class _JourneyProgressVisualState extends State<JourneyProgressVisual>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  String get _themeKey => widget.category;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _progressAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    if (widget.showAnimation) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _controller.forward());
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(JourneyProgressVisual oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.completedDays != widget.completedDays ||
        oldWidget.totalDays != widget.totalDays) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.totalDays > 0
        ? widget.completedDays / widget.totalDays
        : 0.0;
    final accent = CommitmentMediaCatalog.getMedia(_themeKey).accentColor;
    final theme = _getTheme(_themeKey);

    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        final t = _progressAnimation.value;
        return SizedBox(
          height: widget.height,
          child: CustomPaint(
            painter: _JourneyPainter(
              progress: progress * t,
              completedDays: widget.completedDays,
              totalDays: widget.totalDays,
              currentDay: widget.currentDay,
              accentColor: accent,
              theme: theme,
            ),
            child: _buildLabels(progress * t, accent),
          ),
        );
      },
    );
  }

  Widget _buildLabels(double progress, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.completedDays} of ${widget.totalDays} days',
            style: TextStyle(
              color: accent.withValues(alpha: 0.9),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            '${(progress * 100).round()}%',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 32,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }
}

_JourneyTheme _getTheme(String category) {
  switch (category) {
    case 'prayer':
      return const _JourneyTheme(
        label: 'Path of Prayer',
        iconShape: _JourneyIcon.candle,
        trailShape: _JourneyTrail.path,
        milestoneShape: _JourneyMilestone.flame,
      );
    case 'bible':
      return const _JourneyTheme(
        label: 'Scroll Unfurling',
        iconShape: _JourneyIcon.scroll,
        trailShape: _JourneyTrail.scroll,
        milestoneShape: _JourneyMilestone.star,
      );
    case 'discipline':
      return const _JourneyTheme(
        label: 'Mountain Ascent',
        iconShape: _JourneyIcon.peak,
        trailShape: _JourneyTrail.zigzag,
        milestoneShape: _JourneyMilestone.flag,
      );
    case 'service':
      return const _JourneyTheme(
        label: 'Garden Blooming',
        iconShape: _JourneyIcon.flower,
        trailShape: _JourneyTrail.vine,
        milestoneShape: _JourneyMilestone.bloom,
      );
    case 'growth':
      return const _JourneyTheme(
        label: 'Tree of Growth',
        iconShape: _JourneyIcon.leaf,
        trailShape: _JourneyTrail.branch,
        milestoneShape: _JourneyMilestone.fruit,
      );
    case 'health':
      return const _JourneyTheme(
        label: 'Sunrise Brightening',
        iconShape: _JourneyIcon.sunrise,
        trailShape: _JourneyTrail.ray,
        milestoneShape: _JourneyMilestone.radiance,
      );
    case 'faith':
      return const _JourneyTheme(
        label: 'Stars in the Sky',
        iconShape: _JourneyIcon.star,
        trailShape: _JourneyTrail.constellation,
        milestoneShape: _JourneyMilestone.constellation,
      );
    case 'relationships':
      return const _JourneyTheme(
        label: 'Tapestry Woven',
        iconShape: _JourneyIcon.heart,
        trailShape: _JourneyTrail.weave,
        milestoneShape: _JourneyMilestone.knot,
      );
    default:
      return const _JourneyTheme(
        label: 'Journey',
        iconShape: _JourneyIcon.path,
        trailShape: _JourneyTrail.path,
        milestoneShape: _JourneyMilestone.star,
      );
  }
}

enum _JourneyIcon { path, candle, scroll, peak, flower, leaf, sunrise, star, heart }

enum _JourneyTrail { path, scroll, zigzag, vine, branch, ray, constellation, weave }

enum _JourneyMilestone { flame, star, flag, bloom, fruit, radiance, constellation, knot }

class _JourneyTheme {
  final String label;
  final _JourneyIcon iconShape;
  final _JourneyTrail trailShape;
  final _JourneyMilestone milestoneShape;

  const _JourneyTheme({
    required this.label,
    required this.iconShape,
    required this.trailShape,
    required this.milestoneShape,
  });
}

class _JourneyPainter extends CustomPainter {
  final double progress;
  final int completedDays;
  final int totalDays;
  final int currentDay;
  final Color accentColor;
  final _JourneyTheme theme;

  _JourneyPainter({
    required this.progress,
    required this.completedDays,
    required this.totalDays,
    required this.currentDay,
    required this.accentColor,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawTrail(canvas, size);
    _drawMilestones(canvas, size);
  }

  void _drawBackground(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(16),
      ),
      bgPaint,
    );
  }

  void _drawTrail(Canvas canvas, Size size) {
    final trailPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final activePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final path = Path();
    final endX = size.width * 0.85;
    final startX = size.width * 0.15;
    final midY = size.height * 0.6;

    path.moveTo(startX, size.height * 0.8);
    path.cubicTo(
      startX + (endX - startX) * 0.3,
      size.height * 0.3,
      startX + (endX - startX) * 0.7,
      size.height * 0.85,
      endX,
      midY,
    );

    canvas.drawPath(path, trailPaint);

    if (progress > 0) {
      final metric = path.computeMetrics().first;
      final trimmed = metric.extractPath(0, metric.length * progress);
      canvas.drawPath(trimmed, activePaint);
    }

    final dotPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    final endPos = _getPointOnCubicBezier(
      startX, size.height * 0.8,
      startX + (endX - startX) * 0.3, size.height * 0.3,
      startX + (endX - startX) * 0.7, size.height * 0.85,
      endX, midY,
      progress.clamp(0.0, 1.0),
    );
    canvas.drawCircle(endPos, 6, dotPaint);
    canvas.drawCircle(endPos, 10, Paint()..color = accentColor.withValues(alpha: 0.3));
  }

  Offset _getPointOnCubicBezier(
    double x0, double y0,
    double x1, double y1,
    double x2, double y2,
    double x3, double y3,
    double t,
  ) {
    final mt = 1 - t;
    final mt2 = mt * mt;
    final mt3 = mt2 * mt;
    final t2 = t * t;
    final t3 = t2 * t;
    return Offset(
      mt3 * x0 + 3 * mt2 * t * x1 + 3 * mt * t2 * x2 + t3 * x3,
      mt3 * y0 + 3 * mt2 * t * y1 + 3 * mt * t2 * y2 + t3 * y3,
    );
  }

  void _drawMilestones(Canvas canvas, Size size) {
    final milestoneProgress = [0.25, 0.5, 0.75, 1.0];
    final startX = size.width * 0.15;
    final endX = size.width * 0.85;
    final midY = size.height * 0.6;

    for (final mp in milestoneProgress) {
      final pos = _getPointOnCubicBezier(
        startX, size.height * 0.8,
        startX + (endX - startX) * 0.3, size.height * 0.3,
        startX + (endX - startX) * 0.7, size.height * 0.85,
        endX, midY,
        mp,
      );

      final reached = progress >= mp;
      final paint = Paint()
        ..color = reached ? accentColor : Colors.white.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(pos, 4, paint);

      if (reached) {
        canvas.drawCircle(
          pos,
          8,
          Paint()..color = accentColor.withValues(alpha: 0.15),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_JourneyPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.completedDays != completedDays;
}
