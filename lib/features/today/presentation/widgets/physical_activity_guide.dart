import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/services/xp_service.dart';
import '../../../../core/services/celebration_service.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../domain/models/daily_anchors.dart';

/// Physical activity data model
class PhysicalActivity {
  final String id;
  final IconData icon;
  final String title;
  final String description;
  final String duration;
  final int xpReward;

  const PhysicalActivity({
    required this.id,
    required this.icon,
    required this.title,
    required this.description,
    required this.duration,
    required this.xpReward,
  });
}

/// Widget for displaying physical activity guide dialog
class PhysicalActivityGuide extends ConsumerWidget {
  const PhysicalActivityGuide({super.key});

  static const List<PhysicalActivity> _activities = [
    PhysicalActivity(
      id: 'walking',
      icon: Icons.directions_walk,
      title: 'Walking',
      description: '30 minutes of mindful walking\nFocus on your virtue with each step',
      duration: '30 min',
      xpReward: XPRewards.physicalActivity,
    ),
    PhysicalActivity(
      id: 'running',
      icon: Icons.directions_run,
      title: 'Run or Jog',
      description: '20-30 minutes of jogging\nUse rhythmic breathing to meditate on your virtue',
      duration: '10-30 min',
      xpReward: XPRewards.physicalActivity,
    ),
    PhysicalActivity(
      id: 'self_affirmation',
      icon: Icons.self_improvement,
      title: 'Self Affirmation',
      description: '15 minutes of gentle stretching\nCombine with self-affirmations about your virtue',
      duration: '15 min',
      xpReward: XPRewards.physicalActivity,
    ),
    PhysicalActivity(
      id: 'outdoor',
      icon: Icons.park,
      title: 'Outdoor Activity',
      description: 'Any outdoor physical activity\nConnect with nature while reflecting on your virtue',
      duration: '30+ min',
      xpReward: XPRewards.physicalActivity,
    ),
  ];

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const PhysicalActivityGuide(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: const Text('Physical Activity Guide'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose an activity to help internalize your virtue focus:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            
            ..._activities.map((activity) => _buildActivityOption(
              context: context,
              ref: ref,
              activity: activity,
            )),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildActivityOption({
    required BuildContext context,
    required WidgetRef ref,
    required PhysicalActivity activity,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleActivityTap(context, ref, activity),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    activity.icon,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            activity.title,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              activity.duration,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activity.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleActivityTap(BuildContext context, WidgetRef ref, PhysicalActivity activity) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final isDark = theme.brightness == Brightness.dark;
    
    // Show confirmation dialog with brand-aligned design
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? tokens.palette.surface : tokens.palette.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: tokens.palette.border.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        contentPadding: const EdgeInsets.all(24),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Activity icon with brand styling
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                activity.icon,
                color: theme.colorScheme.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Complete ${activity.title}?',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to mark this activity as completed?',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Activity details card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: tokens.palette.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: tokens.palette.border.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    color: tokens.palette.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      activity.duration,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: tokens.palette.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: tokens.palette.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: tokens.palette.success.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      'Ready to complete',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: tokens.palette.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Cancel button with subtle styling
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: tokens.palette.border.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: Text(
              'Cancel',
              style: theme.textTheme.labelLarge?.copyWith(
                color: tokens.palette.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Complete button with brand primary color
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close confirmation dialog
              Navigator.of(context).pop(); // Close activity guide dialog
              
              // Add XP for the activity
              await ref.read(xpProvider.notifier).addXP(
                type: XPActivityType.physicalActivity,
                description: 'Completed ${activity.title}',
                metadata: {
                  'activity_id': activity.id,
                  'title': activity.title,
                  'duration': activity.duration,
                },
              );
              
              // Mark the daily anchor as done
              await ref.read(dailyAnchorsProvider.notifier).markAnchorDone(AnchorType.energyAction);
              
              // Play celebration with sound and visual feedback
              if (context.mounted) {
                // Play celebration immediately for instant feedback
                CelebrationService.instance.playActivityCompletion(
                  context, 
                  activityKey: activity.id,
                );
                
                // Show enhanced success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.celebration_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Excellent work!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Physical activity completed successfully',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: tokens.palette.success,
                    duration: const Duration(seconds: 4),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    margin: const EdgeInsets.all(12),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: tokens.palette.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Complete',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        actionsAlignment: MainAxisAlignment.spaceBetween,
      ),
    );
  }
}
