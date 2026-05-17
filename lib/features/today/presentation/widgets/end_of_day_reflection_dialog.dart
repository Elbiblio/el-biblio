import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/app_providers.dart';
import '../../domain/models/daily_anchors.dart';

enum ReflectionReason {
  busy('Busy - things came up', Icons.schedule, Colors.orange),
  emergency('Emergency', Icons.warning_rounded, Colors.red),
  completedSome(
    'I completed some, just didn\'t check in',
    Icons.check_circle_outline,
    Colors.green,
  );

  const ReflectionReason(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

class EndOfDayReflectionDialog extends ConsumerStatefulWidget {
  const EndOfDayReflectionDialog({super.key});

  @override
  ConsumerState<EndOfDayReflectionDialog> createState() =>
      _EndOfDayReflectionDialogState();
}

class _EndOfDayReflectionDialogState
    extends ConsumerState<EndOfDayReflectionDialog> {
  ReflectionReason? _selectedReason;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: theme.colorScheme.surface,
      insetPadding: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer.withValues(
                      alpha: 0.3,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.psychology_rounded,
                    color: theme.colorScheme.tertiary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gentle Reflection',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "It's okay that today didn't go as planned",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
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

            // Question
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.help_outline_rounded,
                    color: theme.colorScheme.primary,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Why weren\'t you able to complete your activities today?',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Be honest with yourself. A clearer next step can meet you here.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Reason options
            ...ReflectionReason.values.map(
              (reason) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedReason = reason;
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _selectedReason == reason
                              ? reason.color.withValues(alpha: 0.8)
                              : theme.colorScheme.outline.withValues(
                                  alpha: 0.2,
                                ),
                          width: _selectedReason == reason ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        color: _selectedReason == reason
                            ? reason.color.withValues(alpha: 0.1)
                            : theme.colorScheme.surface,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: reason.color.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              reason.icon,
                              color: reason.color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              reason.label,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: _selectedReason == reason
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: _selectedReason == reason
                                    ? reason.color
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (_selectedReason == reason)
                            Icon(
                              Icons.check_circle,
                              color: reason.color,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            if (_selectedReason != null) ...[
              // Primary action based on selection
              FilledButton(
                onPressed: () => _handleReasonSelection(_selectedReason!),
                style: FilledButton.styleFrom(
                  backgroundColor: _selectedReason!.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(_getActionButtonText(_selectedReason!)),
              ),
              const SizedBox(height: 12),
            ],

            // Secondary action
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Maybe Later'),
            ),
          ],
        ),
      ),
    );
  }

  String _getActionButtonText(ReflectionReason reason) {
    switch (reason) {
      case ReflectionReason.busy:
        return 'Journal About Today';
      case ReflectionReason.emergency:
        return 'Journal About Today';
      case ReflectionReason.completedSome:
        return 'Mark What I Completed';
    }
  }

  void _handleReasonSelection(ReflectionReason reason) {
    Navigator.of(context).pop();

    switch (reason) {
      case ReflectionReason.busy:
      case ReflectionReason.emergency:
        // Navigate to journal with pre-filled content about being busy/emergency
        _navigateToJournal(reason);
        break;
      case ReflectionReason.completedSome:
        // Show dialog to mark which activities were actually completed
        _showActivitySelectionDialog();
        break;
    }
  }

  void _navigateToJournal(ReflectionReason reason) {
    final title = reason == ReflectionReason.busy
        ? 'A Busy Day'
        : 'An Emergency Day';

    final content = reason == ReflectionReason.busy
        ? '''Today was unexpectedly busy. Things came up that I didn't anticipate, and I wasn't able to complete my usual spiritual practices.

What happened:
• 

How I feel about it:
• 

What I learned:
• 

Tomorrow I will:
• '''
        : '''Today faced an emergency situation that required my full attention. My spiritual practices had to take a backseat as I dealt with this unexpected challenge.

What happened:
• 

How I'm processing this:
• 

What I need right now:
• 

When I'm ready, I will:
• ''';

    context.push(
      '/journal/new',
      extra: {'initialTitle': title, 'initialText': content},
    );
  }

  void _showActivitySelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => const ActivitySelectionDialog(),
    );
  }
}

class ActivitySelectionDialog extends ConsumerStatefulWidget {
  const ActivitySelectionDialog({super.key});

  @override
  ConsumerState<ActivitySelectionDialog> createState() =>
      _ActivitySelectionDialogState();
}

class _ActivitySelectionDialogState
    extends ConsumerState<ActivitySelectionDialog> {
  final Map<String, bool> _selectedActivities = {
    'coreVirtue': false,
    'habit': false,
    'energyAction': false,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final anchors = ref.watch(dailyAnchorsProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: theme.colorScheme.surface,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Great! What did you complete?',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Mark what really happened today.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
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

              // Activity checkboxes
              _buildActivityCheckbox(
                'Morning Virtue',
                anchors.coreVirtue.type.title,
                'coreVirtue',
                Icons.self_improvement,
              ),
              const SizedBox(height: 12),
              _buildActivityCheckbox(
                'Midday Habit',
                anchors.habit.displayTitle,
                'habit',
                _getHabitIcon(anchors.habit.type),
              ),
              const SizedBox(height: 12),
              _buildActivityCheckbox(
                'Evening Energy',
                anchors.energyAction.title,
                'energyAction',
                Icons.directions_run,
              ),

              const SizedBox(height: 16),

              // Action buttons
              FilledButton(
                onPressed:
                    _selectedActivities.values.any((selected) => selected)
                    ? _awardPointsAndComplete
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Mark Done'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCheckbox(
    String timeSlot,
    String title,
    String key,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final isSelected = _selectedActivities[key] ?? false;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedActivities[key] = !isSelected;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? Colors.green.withValues(alpha: 0.8)
                  : theme.colorScheme.outline.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            color: isSelected
                ? Colors.green.withValues(alpha: 0.1)
                : theme.colorScheme.surface,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.green.withValues(alpha: 0.2)
                      : theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.3,
                        ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.green : theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      timeSlot,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSelected
                            ? Colors.green
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Checkbox(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    _selectedActivities[key] = value ?? false;
                  });
                },
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _calculateSelectedPoints() {
    int points = 0;
    if (_selectedActivities['coreVirtue'] == true) points += 3;
    if (_selectedActivities['habit'] == true) points += 4;
    if (_selectedActivities['energyAction'] == true) points += 5;
    return points;
  }

  void _awardPointsAndComplete() async {
    final notifier = ref.read(dailyAnchorsProvider.notifier);

    // Mark selected activities as completed
    if (_selectedActivities['coreVirtue'] == true) {
      await notifier.markAnchorDone(AnchorType.coreVirtue, completed: true);
    }
    if (_selectedActivities['habit'] == true) {
      await notifier.markAnchorDone(AnchorType.habit, completed: true);
    }
    if (_selectedActivities['energyAction'] == true) {
      await notifier.markAnchorDone(AnchorType.energyAction, completed: true);
    }

    if (mounted) {
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Great work! ${_calculateSelectedPoints()} integrity points awarded!',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
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
