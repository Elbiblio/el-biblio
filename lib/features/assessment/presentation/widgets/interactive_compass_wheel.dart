import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../domain/models/archetype.dart';

class InteractiveCompassWheel extends StatefulWidget {
  const InteractiveCompassWheel({
    super.key,
    required this.onArchetypeSelected,
    required this.selectedArchetypes,
  });

  final Function(Archetype archetype) onArchetypeSelected;
  final List<Archetype> selectedArchetypes;

  @override
  State<InteractiveCompassWheel> createState() =>
      _InteractiveCompassWheelState();
}

class _InteractiveCompassWheelState extends State<InteractiveCompassWheel> {
  Archetype? _hoveredArchetype;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 300,
      child: GestureDetector(
        onTapUp: _handleTap,
        onPanUpdate: (details) => _handleHover(details.localPosition),
        child: CustomPaint(
          painter: _CompassPainter(
            hoveredArchetype: _hoveredArchetype,
            selectedArchetypes: widget.selectedArchetypes,
          ),
          child: Center(
            child: _buildCenterContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterContent() {
    if (_hoveredArchetype != null) {
      return Container(
        width: 120,
        height: 120,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                _hoveredArchetype!.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3830),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                _hoveredArchetype!.identity,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF6F756A),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: 120,
      height: 120,
      padding: const EdgeInsets.all(16),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.explore_rounded,
            color: Color(0xFFF4B925),
            size: 32,
          ),
          SizedBox(height: 4),
          Flexible(
            child: Text(
              'Tap to select',
              style: TextStyle(
                fontSize: 9,
                color: Color(0xFF6F756A),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _handleTap(TapUpDetails details) {
    final archetype = _getArchetypeAtPosition(details.localPosition);
    if (archetype != null) {
      widget.onArchetypeSelected(archetype);
    }
  }

  void _handleHover(Offset position) {
    final archetype = _getArchetypeAtPosition(position);
    if (archetype != _hoveredArchetype) {
      setState(() {
        _hoveredArchetype = archetype;
      });
    }
  }

  Archetype? _getArchetypeAtPosition(Offset position) {
    const center = Offset(150, 150);
    final distance = (position - center).distance;

    // Check if within the wheel radius (excluding center area)
    if (distance < 40 || distance > 140) return null;

    // Calculate angle
    final angle =
        (math.atan2(position.dy - center.dy, position.dx - center.dx) +
                math.pi / 2) %
            (2 * math.pi);
    final normalizedAngle = angle < 0 ? angle + 2 * math.pi : angle;

    // Calculate segment index
    final segmentAngle = (2 * math.pi) / Archetype.allArchetypes.length;
    final segmentIndex = (normalizedAngle / segmentAngle).floor();

    if (segmentIndex >= 0 && segmentIndex < Archetype.allArchetypes.length) {
      return Archetype.allArchetypes[segmentIndex];
    }

    return null;
  }
}

class _CompassPainter extends CustomPainter {
  const _CompassPainter({
    this.hoveredArchetype,
    required this.selectedArchetypes,
  });

  final Archetype? hoveredArchetype;
  final List<Archetype> selectedArchetypes;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2 - 10;
    const innerRadius = 40.0;

    final segmentAngle = (2 * math.pi) / Archetype.allArchetypes.length;

    // Draw segments
    for (int i = 0; i < Archetype.allArchetypes.length; i++) {
      final archetype = Archetype.allArchetypes[i];
      final startAngle = i * segmentAngle - math.pi / 2;
      final endAngle = startAngle + segmentAngle;

      final isSelected = selectedArchetypes.contains(archetype);
      final isHovered = hoveredArchetype == archetype;

      // Draw segment
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = _getSegmentColor(archetype, isSelected, isHovered);

      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: outerRadius),
          startAngle,
          segmentAngle,
          false,
        )
        ..arcTo(
          Rect.fromCircle(center: center, radius: innerRadius),
          endAngle,
          -segmentAngle,
          false,
        )
        ..close();

      canvas.drawPath(path, paint);

      // Draw border
      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = Colors.white.withValues(alpha: 0.3);

      canvas.drawPath(path, borderPaint);

      // Draw label
      final labelAngle = startAngle + segmentAngle / 2;
      // Position the label slightly closer to the outer edge for better readability
      final labelRadius = innerRadius + (outerRadius - innerRadius) * 0.6;
      final labelX = center.dx + labelRadius * math.cos(labelAngle);
      final labelY = center.dy + labelRadius * math.sin(labelAngle);

      // Calculate rotation so text radiates outward from center
      // Adding pi/2 makes text perpendicular to the radius line (along the arc)
      // Adding another pi/2 (total pi) makes it radiate outward
      double textRotation = labelAngle;

      // Flip text if it's on the left side of the wheel to keep it readable (right-side up)
      if (labelAngle > math.pi / 2 && labelAngle < 3 * math.pi / 2) {
        textRotation += math.pi;
      }

      _drawRotatedText(
        canvas,
        archetype.name,
        Offset(labelX, labelY),
        textRotation,
        isSelected || isHovered,
      );
    }

    // Draw outer border
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = const Color(0xFFF4B925).withValues(alpha: 0.3);

    canvas.drawCircle(center, outerRadius, borderPaint);
    canvas.drawCircle(center, innerRadius, borderPaint);
  }

  Color _getSegmentColor(Archetype archetype, bool isSelected, bool isHovered) {
    final index = Archetype.allArchetypes.indexOf(archetype);
    final baseColor =
        Archetype.segmentColors[index % Archetype.segmentColors.length];

    if (isSelected) {
      return const Color(0xFFF4B925).withValues(alpha: 0.8);
    }

    if (isHovered) {
      return const Color(0xFFF4B925).withValues(alpha: 0.6);
    }

    // Parse hex color
    final colorValue = int.parse(baseColor.replaceFirst('#', '0xFF'));
    final color = Color(colorValue);

    return color.withValues(alpha: 0.7);
  }

  void _drawRotatedText(Canvas canvas, String text, Offset position,
      double angle, bool isHighlighted) {
    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(angle);

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: isHighlighted
              ? const Color(0xFF2C3830)
              : const Color(0xFF2C3830).withValues(alpha: 0.8),
          fontSize: isHighlighted ? 12 : 10,
          fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! _CompassPainter ||
        oldDelegate.hoveredArchetype != hoveredArchetype ||
        oldDelegate.selectedArchetypes != selectedArchetypes;
  }
}
