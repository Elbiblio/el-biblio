import 'package:flutter/material.dart';

class JourneyPathConnector extends StatelessWidget {
  final bool isCompleted;
  final bool isLeft;

  const JourneyPathConnector({
    super.key,
    required this.isCompleted,
    required this.isLeft,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isCompleted
        ? const Color(0xFF5e7153)
        : (isDark ? Colors.grey.shade700 : Colors.grey.shade300);

    return SizedBox(
      height: 32,
      child: CustomPaint(
        size: const Size(double.infinity, 32),
        painter: _ConnectorPainter(
          color: activeColor,
          isCompleted: isCompleted,
          isLeft: isLeft,
        ),
      ),
    );
  }
}

class _ConnectorPainter extends CustomPainter {
  final Color color;
  final bool isCompleted;
  final bool isLeft;

  _ConnectorPainter({
    required this.color,
    required this.isCompleted,
    required this.isLeft,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (!isCompleted) {
      paint.strokeWidth = 1.5;
      const dashWidth = 6.0;
      const dashSpace = 4.0;
      double startY = 0;
      final x = size.width / 2;
      while (startY < size.height) {
        canvas.drawLine(
          Offset(x, startY),
          Offset(x, (startY + dashWidth).clamp(0, size.height)),
          paint,
        );
        startY += dashWidth + dashSpace;
      }
    } else {
      final path = Path();
      final midX = size.width / 2;
      path.moveTo(midX, 0);
      path.lineTo(midX, size.height);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectorPainter old) =>
      old.color != color || old.isCompleted != isCompleted;
}
