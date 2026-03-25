import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_theme_tokens.dart';
import '../../domain/models/habit_assessment.dart';

class HabitStreakCard extends StatelessWidget {
  const HabitStreakCard({
    super.key,
    required this.habit,
    this.onCheckIn,
    this.onTap,
  });

  final HabitItem habit;
  final VoidCallback? onCheckIn;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDay = habit.lastCheckIn != null
        ? DateTime(
            habit.lastCheckIn!.year,
            habit.lastCheckIn!.month,
            habit.lastCheckIn!.day,
          )
        : null;
    final checkedInToday = lastDay == today;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: tokens.palette.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.palette.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Category icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: habit.category.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    habit.category.icon,
                    color: habit.category.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Habit info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              habit.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: tokens.palette.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (habit.isBadHabit) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: tokens.palette.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Conquer',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: tokens.palette.error,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.flame,
                            size: 12,
                            color: habit.currentStreak > 0
                                ? const Color(0xFFFF6B35)
                                : tokens.palette.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            habit.isBadHabit
                                ? '${habit.daysSinceLastOccurrence}d free'
                                : '${habit.currentStreak}d streak',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: tokens.palette.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: habit.category.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              habit.category.label,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: habit.category.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Check-in button
                GestureDetector(
                  onTap: checkedInToday ? null : onCheckIn,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: checkedInToday
                          ? tokens.palette.success
                          : tokens.palette.surface,
                      border: Border.all(
                        color: checkedInToday
                            ? tokens.palette.success
                            : tokens.palette.border,
                      ),
                    ),
                    child: Icon(
                      checkedInToday ? Icons.check : Icons.add,
                      size: 18,
                      color: checkedInToday
                          ? Colors.white
                          : tokens.palette.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
