import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/app_providers.dart';
import '../../domain/models/daily_anchors.dart';
import 'enhanced_anchor_card.dart';

class DailyCheckInDialog extends ConsumerWidget {
  const DailyCheckInDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final anchors = ref.watch(dailyAnchorsProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Theme.of(context).colorScheme.surface,
      insetPadding: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Check-in',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Review your anchors today',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    EnhancedAnchorCard(
                      title: anchors.coreVirtue.type.title,
                      description: anchors.coreVirtue.focusPrompt,
                      completed: anchors.coreVirtue.isCompleted,
                      progress: anchors.coreVirtue.isCompleted ? 1.0 : 0.0,
                      timeSlot: 'Morning',
                      duration: '5 min',
                      icon: _getVirtueIcon(anchors.coreVirtue.type),
                      onToggle: () => ref
                          .read(dailyAnchorsProvider.notifier)
                          .markAnchorDone(AnchorType.coreVirtue, completed: !anchors.coreVirtue.isCompleted),
                    ),
                    const SizedBox(height: 12),
                    EnhancedAnchorCard(
                      title: anchors.habit.title,
                      description: anchors.habit.description,
                      completed: anchors.habit.isCompleted,
                      progress: anchors.habit.isCompleted ? 1.0 : 0.0,
                      timeSlot: 'Midday',
                      duration: '${anchors.habit.durationMinutes} min',
                      icon: _getHabitIcon(anchors.habit.type),
                      onToggle: () => ref
                          .read(dailyAnchorsProvider.notifier)
                          .markAnchorDone(AnchorType.habit, completed: !anchors.habit.isCompleted),
                    ),
                    const SizedBox(height: 12),
                    EnhancedAnchorCard(
                      title: anchors.energyAction.title,
                      description: anchors.energyAction.description,
                      completed: anchors.energyAction.isCompleted,
                      progress: anchors.energyAction.isCompleted ? 1.0 : 0.0,
                      timeSlot: 'Evening',
                      duration: '${anchors.energyAction.durationMinutes} min',
                      icon: Icons.directions_run,
                      onToggle: () => ref
                          .read(dailyAnchorsProvider.notifier)
                          .markAnchorDone(AnchorType.energyAction, completed: !anchors.energyAction.isCompleted),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (anchors.isCompleted)
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showCelebration(context, anchors.integrityPoints);
                },
                child: const Text('Complete Day'),
              )
            else
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Continue Later'),
              ),
          ],
        ),
      ),
    );
  }

  void _showCelebration(BuildContext context, int points) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CelebrationDialog(points: points),
    );
  }

  IconData _getVirtueIcon(VirtueType virtue) {
    switch (virtue) {
      case VirtueType.humility:
        return Icons.self_improvement;
      case VirtueType.love:
        return Icons.favorite;
      case VirtueType.faith:
        return Icons.lightbulb;
      case VirtueType.knowledge:
        return Icons.school;
    }
  }

  IconData _getHabitIcon(HabitType habit) {
    switch (habit) {
      case HabitType.prayer:
        return Icons.church;
      case HabitType.reflection:
        return Icons.psychology;
      case HabitType.scripture:
        return Icons.menu_book;
      case HabitType.service:
        return Icons.volunteer_activism;
      case HabitType.movement:
        return Icons.directions_walk;
    }
  }
}

class _CelebrationDialog extends StatelessWidget {
  const _CelebrationDialog({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.star_rounded,
                  size: 64,
                  color: Colors.amber,
                ),
                const SizedBox(height: 24),
                Text(
                  'Day Complete!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '+$points Integrity Points',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rest well tonight.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
