import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../domain/models/jesus_journey_event.dart';
import '../../domain/models/journey_progress.dart';

/// Maps icon name strings from the catalog to actual Lucide icons.
IconData _resolveIcon(String name) {
  final map = <String, IconData>{
    'scroll_text': LucideIcons.scrollText,
    'sparkles': LucideIcons.sparkles,
    'baby': LucideIcons.baby,
    'star': LucideIcons.star,
    'route': LucideIcons.navigation,
    'book_open': LucideIcons.bookOpen,
    'droplets': LucideIcons.droplets,
    'shield': LucideIcons.shield,
    'users': LucideIcons.users,
    'wine': LucideIcons.wine,
    'mountain': LucideIcons.mountain,
    'heart_handshake': LucideIcons.heartHandshake,
    'cloud_lightning': LucideIcons.cloudLightning,
    'wheat': LucideIcons.wheat,
    'waves': LucideIcons.waves,
    'sun': LucideIcons.sun,
    'hand_helping': LucideIcons.helpingHand,
    'sunrise': LucideIcons.sunrise,
    'heart': LucideIcons.heart,
    'tree_pine': LucideIcons.treePine,
    'palm_tree': LucideIcons.palmtree,
    'flame': LucideIcons.flame,
    'utensils': LucideIcons.utensils,
    'moon': LucideIcons.moon,
    'scale': LucideIcons.scale,
    'cross': LucideIcons.cross,
    'landmark': LucideIcons.landmark,
    'sun_rise': LucideIcons.sunrise,
    'users_round': LucideIcons.users,
    'cloud': LucideIcons.cloud,
  };
  return map[name] ?? LucideIcons.circle;
}

enum NodeState { completed, current, locked }

class JourneyPathNode extends StatelessWidget {
  final JesusJourneyEvent event;
  final NodeState nodeState;
  final EventResult? result;
  final VoidCallback? onTap;
  final bool isLeft;

  const JourneyPathNode({
    super.key,
    required this.event,
    required this.nodeState,
    this.result,
    this.onTap,
    this.isLeft = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLocked = nodeState == NodeState.locked;
    final isCurrent = nodeState == NodeState.current;
    final isCompleted = nodeState == NodeState.completed;

    final color = isLocked
        ? (isDark ? Colors.grey.shade700 : Colors.grey.shade400)
        : event.themeColor;

    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: Row(
        mainAxisAlignment:
            isLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (!isLeft) const Spacer(),
          if (!isLeft) _buildLabel(context, color, isDark, isLocked, isCurrent),
          if (!isLeft) const SizedBox(width: 12),
          _buildCircle(color, isDark, isLocked, isCurrent, isCompleted),
          if (isLeft) const SizedBox(width: 12),
          if (isLeft) _buildLabel(context, color, isDark, isLocked, isCurrent),
          if (isLeft) const Spacer(),
        ],
      ),
    );
  }

  Widget _buildCircle(
    Color color,
    bool isDark,
    bool isLocked,
    bool isCurrent,
    bool isCompleted,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: isCurrent ? 56 : 48,
      height: isCurrent ? 56 : 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isLocked
            ? (isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200)
            : color.withValues(alpha: isCompleted ? 1.0 : 0.15),
        border: Border.all(
          color: isLocked ? Colors.grey.shade500 : color,
          width: isCurrent ? 3 : 2,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Center(
        child: isCompleted
            ? const Icon(Icons.check, color: Colors.white, size: 22)
            : Icon(
                _resolveIcon(event.iconName),
                color: isLocked ? Colors.grey : color,
                size: 22,
              ),
      ),
    );
  }

  Widget _buildLabel(
    BuildContext context,
    Color color,
    bool isDark,
    bool isLocked,
    bool isCurrent,
  ) {
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment:
            isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Text(
            event.title,
            style: TextStyle(
              fontSize: isCurrent ? 15 : 13,
              fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
              color: isLocked
                  ? (isDark ? Colors.grey.shade600 : Colors.grey.shade500)
                  : (isDark ? Colors.white : Colors.black87),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            event.subtitle,
            style: TextStyle(
              fontSize: 11,
              color: isLocked
                  ? Colors.grey
                  : (isDark ? Colors.white54 : Colors.black45),
            ),
          ),
          if (result != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return Icon(
                  i < result!.correctAnswers
                      ? Icons.star
                      : Icons.star_border,
                  size: 14,
                  color: i < result!.correctAnswers
                      ? Colors.amber
                      : Colors.grey,
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}
