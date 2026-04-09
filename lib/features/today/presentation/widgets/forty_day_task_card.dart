import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/app_providers.dart';
import '../../../alignment/domain/models/forty_day_goal.dart';

/// Compact card showing today's 40-day goal task on the Today screen.
///
/// Displays the daily task with a completion button and progress indicator.
/// Only visible when the user has an active 40-day goal.
class FortyDayTaskCard extends ConsumerWidget {
  const FortyDayTaskCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fortyDayState = ref.watch(fortyDayProvider);

    if (!fortyDayState.hasActiveGoal) {
      return const SizedBox.shrink();
    }

    final goal = fortyDayState.activeGoal!;
    final todayTask = goal.todayTask;
    final isCompletedToday = goal.isDayCompleted(goal.currentDay);

    if (todayTask == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompletedToday
            ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.3)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompletedToday
              ? theme.colorScheme.secondary.withValues(alpha: 0.3)
              : theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                isCompletedToday ? Icons.check_circle : Icons.local_fire_department_rounded,
                size: 18,
                color: isCompletedToday
                    ? theme.colorScheme.secondary
                    : theme.colorScheme.tertiary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  goal.title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isCompletedToday
                        ? theme.colorScheme.secondary
                        : theme.colorScheme.tertiary,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Day ${goal.currentDay}/40',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.tertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Today's task
          Text(
            todayTask.title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (todayTask.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              todayTask.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // Scripture reference (clickable)
          if (todayTask.relatedVerse.isNotEmpty) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _navigateToBible(context, todayTask.relatedVerse),
              child: Row(
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    todayTask.relatedVerse,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: theme.colorScheme.primary.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Action row
          if (isCompletedToday)
            Row(
              children: [
                Icon(Icons.check_circle, color: theme.colorScheme.secondary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Day ${goal.currentDay} complete',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _completeDay(ref, goal),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Complete'),
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.tertiary,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () => context.push('/alignment/forty-day-progress'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Details'),
                ),
              ],
            ),

          // Progress bar
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: 4,
              backgroundColor: theme.colorScheme.tertiary.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(
                isCompletedToday
                    ? theme.colorScheme.secondary
                    : theme.colorScheme.tertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _completeDay(WidgetRef ref, FortyDayGoal goal) {
    ref.read(fortyDayProvider.notifier).completeDay(dayNumber: goal.currentDay);
  }

  void _navigateToBible(BuildContext context, String reference) {
    // Parse reference like "Genesis 1:1" or "Psalm 23"
    final parts = reference.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) return;

    String bookName = '';
    int? chapter;
    int? verse;

    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (RegExp(r'^\d+').hasMatch(part) && i > 0) {
        final cv = part.split(':');
        chapter = int.tryParse(cv[0]);
        if (cv.length > 1) {
          verse = int.tryParse(cv[1].split('-')[0]);
        }
        break;
      } else {
        if (bookName.isNotEmpty) bookName += ' ';
        bookName += part;
      }
    }

    if (bookName.isEmpty || chapter == null) return;

    final encoded = Uri.encodeComponent(bookName);
    var url = '/bible/reader?book=$encoded&chapter=$chapter';
    if (verse != null) url += '&verse=$verse';
    context.push(url);
  }
}
