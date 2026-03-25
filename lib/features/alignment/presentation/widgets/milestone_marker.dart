import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_theme_tokens.dart';

/// 40-day journey milestone widget.
class MilestoneMarker extends StatelessWidget {
  const MilestoneMarker({
    super.key,
    required this.dayNumber,
    required this.title,
    required this.isCompleted,
    required this.isCurrent,
  });

  final int dayNumber;
  final String title;
  final bool isCompleted;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;

    return Row(
      children: [
        // Milestone circle
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? tokens.palette.primary
                : isCurrent
                    ? tokens.palette.primary.withValues(alpha: 0.2)
                    : tokens.palette.surface,
            border: Border.all(
              color: isCompleted || isCurrent
                  ? tokens.palette.primary
                  : tokens.palette.border,
              width: isCurrent ? 2 : 1,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    '$dayNumber',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isCurrent
                          ? tokens.palette.primary
                          : tokens.palette.textTertiary,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        // Milestone info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Day $dayNumber',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: tokens.palette.textTertiary,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: isCompleted || isCurrent
                      ? tokens.palette.textPrimary
                      : tokens.palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (isCompleted)
          Icon(
            LucideIcons.award,
            color: tokens.palette.primary,
            size: 20,
          ),
      ],
    );
  }
}
