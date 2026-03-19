import 'package:flutter/material.dart';

class HabitGrowthVisualization extends StatefulWidget {
  const HabitGrowthVisualization({
    super.key,
    required this.progress,
    required this.isPaused,
    this.size = 120,
  });

  final double progress; // 0.0 to 1.0
  final bool isPaused;
  final double size;

  @override
  State<HabitGrowthVisualization> createState() => _HabitGrowthVisualizationState();
}

class _HabitGrowthVisualizationState extends State<HabitGrowthVisualization>
    with TickerProviderStateMixin {
  late AnimationController _growthController;
  late AnimationController _swayController;
  late Animation<double> _growthAnimation;
  late Animation<double> _swayAnimation;

  @override
  void initState() {
    super.initState();
    
    _growthController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _swayController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _growthAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _growthController,
      curve: Curves.easeOutBack,
    ));

    _swayAnimation = Tween<double>(
      begin: -0.05,
      end: 0.05,
    ).animate(CurvedAnimation(
      parent: _swayController,
      curve: Curves.easeInOut,
    ));

    _growthController.forward();
    if (!widget.isPaused) {
      _swayController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(HabitGrowthVisualization oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.progress != widget.progress) {
      _growthAnimation = Tween<double>(
        begin: _growthAnimation.value,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _growthController,
        curve: Curves.easeOutBack,
      ));
      _growthController.forward(from: 0.0);
    }
    
    if (oldWidget.isPaused != widget.isPaused) {
      if (widget.isPaused) {
        _swayController.stop();
      } else {
        _swayController.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _growthController.dispose();
    _swayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_growthAnimation, _swayAnimation]),
        builder: (context, child) {
          return Transform.rotate(
            angle: _swayAnimation.value,
            child: CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _GrowthPlantPainter(
                progress: _growthAnimation.value,
                isPaused: widget.isPaused,
                theme: theme,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GrowthPlantPainter extends CustomPainter {
  _GrowthPlantPainter({
    required this.progress,
    required this.isPaused,
    required this.theme,
  });

  final double progress;
  final bool isPaused;
  final ThemeData theme;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final paint = Paint()
      ..color = isPaused 
          ? theme.colorScheme.outline.withValues(alpha: 0.5)
          : theme.colorScheme.primary.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    
    final stemPaint = Paint()
      ..color = isPaused
          ? theme.colorScheme.outline.withValues(alpha: 0.4)
          : theme.colorScheme.primary.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    // Draw stem
    final stemHeight = size.height * 0.7 * progress;
    final stemPath = Path()
      ..moveTo(center.dx, center.dy)
      ..quadraticBezierTo(
        center.dx - 10, center.dy - stemHeight / 2,
        center.dx, center.dy - stemHeight,
      );
    canvas.drawPath(stemPath, stemPaint);

    // Draw leaves based on progress
    if (progress > 0.2) {
      _drawLeaf(canvas, center, Offset(-15, -stemHeight * 0.3), progress - 0.2, paint);
    }
    
    if (progress > 0.4) {
      _drawLeaf(canvas, center, Offset(15, -stemHeight * 0.5), progress - 0.4, paint);
    }
    
    if (progress > 0.6) {
      _drawLeaf(canvas, center, Offset(-12, -stemHeight * 0.7), progress - 0.6, paint);
    }
    
    if (progress > 0.8) {
      _drawLeaf(canvas, center, Offset(12, -stemHeight * 0.9), progress - 0.8, paint);
    }

    // Draw flower/bud at top when nearly complete
    if (progress > 0.9) {
      final flowerSize = 8.0 * (progress - 0.9) / 0.1;
      final flowerColor = isPaused
          ? theme.colorScheme.outline.withValues(alpha: 0.3)
          : theme.colorScheme.primary.withValues(alpha: 0.7);
      
      final flowerPaint = Paint()
        ..color = flowerColor
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(center.dx, center.dy - stemHeight),
        flowerSize,
        flowerPaint,
      );
    }

    // Draw pause indicator if paused
    if (isPaused) {
      final pausePaint = Paint()
        ..color = theme.colorScheme.error.withValues(alpha: 0.8)
        ..style = PaintingStyle.fill;
      
      // Draw pause symbol
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(center.dx, center.dy - stemHeight - 15),
            width: 4,
            height: 12,
          ),
          const Radius.circular(2),
        ),
        pausePaint,
      );
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(center.dx + 8, center.dy - stemHeight - 15),
            width: 4,
            height: 12,
          ),
          const Radius.circular(2),
        ),
        pausePaint,
      );
    }
  }

  void _drawLeaf(Canvas canvas, Offset base, Offset offset, double leafProgress, Paint paint) {
    final leafSize = 12.0 * leafProgress;
    final leafPath = Path()
      ..addOval(
        Rect.fromCenter(
          center: base + offset,
          width: leafSize * 1.5,
          height: leafSize,
        ),
      );
    canvas.drawPath(leafPath, paint);
  }

  @override
  bool shouldRepaint(_GrowthPlantPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isPaused != isPaused;
  }
}
