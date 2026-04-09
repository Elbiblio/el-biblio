import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../../../mission/domain/models/mission_action.dart';
import '../../../mission/domain/models/mission_focus.dart';

/// Shows pending mission actions on the Today screen with inline completion.
///
/// Users can tick off acts directly without navigating to the Act screen.
/// Expandable drawer reveals all pending actions; collapsed shows top 2.
class MissionNextStepCard extends ConsumerStatefulWidget {
  const MissionNextStepCard({super.key});

  @override
  ConsumerState<MissionNextStepCard> createState() => _MissionNextStepCardState();
}

class _MissionNextStepCardState extends ConsumerState<MissionNextStepCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mission = ref.watch(missionProvider);
    final notifier = ref.read(missionProvider.notifier);
    final pending = mission.pendingActions;
    final completed = mission.completedActions;
    final hasPartner = mission.accountabilityPartner != null;

    // Nothing to show if no actions at all
    if (pending.isEmpty && completed.isEmpty) {
      return _buildEmptyState(context, mission.focus.label);
    }

    // All done — show compact summary
    final allDone = pending.isEmpty && completed.isNotEmpty;

    final visiblePending = _isExpanded ? pending : pending.take(2).toList();
    final recentCompleted = _isExpanded ? completed.take(3).toList() : <MissionAction>[];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: Container(
          padding: EdgeInsets.all(allDone ? 12 : 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: allDone
                ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.3)
                : theme.colorScheme.surface.withValues(alpha: 0.8),
            border: Border.all(
              color: allDone
                  ? theme.colorScheme.secondary.withValues(alpha: 0.3)
                  : theme.colorScheme.outline.withValues(alpha: 0.08),
            ),
          ),
          child: allDone
              ? _buildCompactAllDone(theme, completed.length, context)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    GestureDetector(
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      child: Row(
                        children: [
                          Icon(
                            Icons.volunteer_activism_rounded,
                            size: 18,
                            color: theme.colorScheme.primary.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Today\'s Acts',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Spacer(),
                          if (pending.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${pending.length} pending',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          AnimatedRotation(
                            turns: _isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              Icons.expand_more,
                              size: 20,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Pending actions with checkboxes
                    ...visiblePending.map((action) => _ActionItem(
                      action: action,
                      onToggle: () => notifier.toggleCompleted(action),
                    )),

                    // Show "and X more" when collapsed
                    if (!_isExpanded && pending.length > 2)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: GestureDetector(
                          onTap: () => setState(() => _isExpanded = true),
                          child: Text(
                            '+ ${pending.length - 2} more actions',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                    // Recently completed (when expanded)
                    if (_isExpanded && recentCompleted.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Divider(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
                      const SizedBox(height: 4),
                      ...recentCompleted.map((action) => Opacity(
                        opacity: 0.5,
                        child: _ActionItem(
                          action: action,
                          onToggle: () => notifier.toggleCompleted(action),
                        ),
                      )),
                    ],

                    const SizedBox(height: 8),

                    // Action buttons row
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => context.push(AppRoutes.act),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Step'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        if (hasPartner) ...[
                          const SizedBox(width: 10),
                          OutlinedButton(
                            onPressed: () => context.push(AppRoutes.growTogether),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Check in'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildCompactAllDone(ThemeData theme, int completedCount, BuildContext context) {
    return Row(
      children: [
        Icon(Icons.check_circle, color: theme.colorScheme.secondary, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'All $completedCount acts completed',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.secondary,
            ),
          ),
        ),
        TextButton(
          onPressed: () => context.push(AppRoutes.act),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Add more',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, String focusLabel) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: theme.colorScheme.surface.withValues(alpha: 0.8),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.volunteer_activism_rounded,
                  size: 18,
                  color: theme.colorScheme.primary.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Text(
                  'Choose a Step',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Choose one practical $focusLabel step you can complete today.',
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.4,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => context.push(AppRoutes.act),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Open Act'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({required this.action, required this.onToggle});

  final MissionAction action;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                action.isCompleted
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked,
                size: 20,
                color: action.isCompleted
                    ? theme.colorScheme.secondary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  action.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    decoration: action.isCompleted ? TextDecoration.lineThrough : null,
                    color: action.isCompleted
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                        : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (action.requiresFollowUp && !action.isCompleted)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Follow-up',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 9,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
