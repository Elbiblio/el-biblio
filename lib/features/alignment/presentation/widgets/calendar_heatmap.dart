import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_tokens.dart';
import '../../domain/models/forty_day_goal.dart';

/// A 40-day calendar heat map similar to GitHub contributions.
class CalendarHeatmap extends StatelessWidget {
  const CalendarHeatmap({
    super.key,
    required this.completions,
    required this.startDate,
    this.currentDay = 1,
    this.onDayTap,
  });

  final Map<int, DayCompletion> completions;
  final DateTime startDate;
  final int currentDay;
  final void Function(int day)? onDayTap;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final milestones = {7, 14, 21, 30, 40};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Calendar grid: 8 columns x 5 rows
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 8,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1,
          ),
          itemCount: 40,
          itemBuilder: (context, index) {
            final day = index + 1;
            final isCompleted = completions.containsKey(day);
            final isCurrent = day == currentDay;
            final isFuture = day > currentDay;
            final isMilestone = milestones.contains(day);
            final rating = completions[day]?.rating ?? 0;

            Color cellColor;
            if (isCompleted) {
              // Intensity based on rating (1-5)
              final intensity = (rating / 5.0).clamp(0.2, 1.0);
              cellColor = tokens.palette.primary.withValues(alpha: intensity);
            } else if (isCurrent) {
              cellColor = tokens.palette.primary.withValues(alpha: 0.2);
            } else if (isFuture) {
              cellColor = tokens.palette.surface;
            } else {
              // Missed day
              cellColor = tokens.palette.error.withValues(alpha: 0.15);
            }

            return GestureDetector(
              onTap: onDayTap != null ? () => onDayTap!(day) : null,
              child: Container(
                decoration: BoxDecoration(
                  color: cellColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isCurrent
                        ? tokens.palette.primary
                        : isMilestone
                            ? tokens.palette.primary.withValues(alpha: 0.4)
                            : tokens.palette.border.withValues(alpha: 0.3),
                    width: isCurrent ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              isMilestone ? FontWeight.bold : FontWeight.w500,
                          color: isCompleted
                              ? Colors.white
                              : isCurrent
                                  ? tokens.palette.primary
                                  : isFuture
                                      ? tokens.palette.textTertiary
                                      : tokens.palette.textSecondary,
                        ),
                      ),
                      if (isCompleted)
                        Icon(
                          Icons.check,
                          size: 8,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendItem(
              color: tokens.palette.surface,
              label: 'Upcoming',
              borderColor: tokens.palette.border,
            ),
            const SizedBox(width: 12),
            _LegendItem(
              color: tokens.palette.primary.withValues(alpha: 0.3),
              label: 'Low',
            ),
            const SizedBox(width: 12),
            _LegendItem(
              color: tokens.palette.primary.withValues(alpha: 0.6),
              label: 'Medium',
            ),
            const SizedBox(width: 12),
            _LegendItem(
              color: tokens.palette.primary,
              label: 'High',
            ),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    this.borderColor,
  });

  final Color color;
  final String label;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: borderColor != null ? Border.all(color: borderColor!) : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: Theme.of(context).tokens.palette.textTertiary,
          ),
        ),
      ],
    );
  }
}
