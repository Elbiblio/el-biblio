import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../today/domain/models/daily_anchors.dart';

class ProgressReminderDialog extends ConsumerWidget {
  const ProgressReminderDialog({
    super.key,
    required this.anchors,
  });

  final DailyAnchors anchors;

  static void show(BuildContext context, DailyAnchors anchors) {
    showDialog(
      context: context,
      builder: (context) => ProgressReminderDialog(
        anchors: anchors,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final completedItems = _getCompletedItems(anchors);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.1),
              theme.colorScheme.surface.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.celebration_rounded,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Progress',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${completedItems.length} of 3 completed',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close_rounded,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Progress overview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: completedItems.length / 3,
                          backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                          strokeWidth: 4,
                          strokeCap: StrokeCap.round,
                        ),
                        Center(
                          child: Text(
                            '${((completedItems.length / 3) * 100).toInt()}%',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Great progress today!',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'You\'re building spiritual momentum.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Completed items list
            if (completedItems.isNotEmpty) ...[
              Text(
                'Completed Today',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 12),
              
              ...completedItems.map((item) => Padding(
                padding: EdgeInsets.only(bottom: item != completedItems.last ? 12 : 0),
                child: _buildCompletedItem(context, item),
              )),
            ],
            
            // Remaining items
            if (completedItems.length < 3) ...[
              const SizedBox(height: 20),
              Text(
                'Still To Do',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 12),
              
              ..._getRemainingItems(anchors).map((item) => Padding(
                padding: EdgeInsets.only(bottom: item != _getRemainingItems(anchors).last ? 12 : 0),
                child: _buildRemainingItem(context, item),
              )),
            ],
            
            const SizedBox(height: 24),
            
            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Keep Going!',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedItem(BuildContext context, CompletedItem item) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.palette.success.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: tokens.palette.success.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: tokens.palette.success.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_rounded,
              color: tokens.palette.success,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: tokens.palette.success,
                  ),
                ),
                if (item.description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemainingItem(BuildContext context, RemainingItem item) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.icon,
              color: theme.colorScheme.onPrimaryContainer,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (item.description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<CompletedItem> _getCompletedItems(DailyAnchors anchors) {
    final items = <CompletedItem>[];
    
    if (anchors.coreVirtue.isCompleted) {
      items.add(CompletedItem(
        title: 'Morning Prayer',
        description: 'Prayed about ${anchors.coreVirtue.type.title}',
        icon: Icons.wb_sunny_outlined,
        virtueType: anchors.coreVirtue.type,
      ));
    }
    
    if (anchors.habit.isCompleted) {
      items.add(CompletedItem(
        title: 'Daily Anchor',
        description: anchors.habit.displayDescription,
        icon: Icons.task_alt_rounded,
      ));
    }
    
    if (anchors.energyAction.isCompleted) {
      items.add(CompletedItem(
        title: 'Physical Activity',
        description: anchors.energyAction.description,
        icon: Icons.directions_walk_rounded,
      ));
    }
    
    return items;
  }

  List<RemainingItem> _getRemainingItems(DailyAnchors anchors) {
    final items = <RemainingItem>[];
    
    if (!anchors.coreVirtue.isCompleted) {
      items.add(RemainingItem(
        title: 'Morning Prayer',
        description: 'Pray about your current virtue: ${anchors.coreVirtue.type.title}',
        icon: Icons.wb_sunny_outlined,
      ));
    }
    
    if (!anchors.habit.isCompleted) {
      items.add(RemainingItem(
        title: 'Daily Anchor',
        description: anchors.habit.displayDescription,
        icon: Icons.task_alt_rounded,
      ));
    }
    
    if (!anchors.energyAction.isCompleted) {
      items.add(RemainingItem(
        title: 'Physical Activity',
        description: anchors.energyAction.description,
        icon: Icons.directions_walk_rounded,
      ));
    }
    
    return items;
  }
}

class CompletedItem {
  const CompletedItem({
    required this.title,
    this.description,
    required this.icon,
    this.virtueType,
  });

  final String title;
  final String? description;
  final IconData icon;
  final VirtueType? virtueType;
}

class RemainingItem {
  const RemainingItem({
    required this.title,
    this.description,
    required this.icon,
  });

  final String title;
  final String? description;
  final IconData icon;
}
