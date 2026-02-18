import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/app_providers.dart';
import '../../../../shared/widgets/surface_card.dart';
import '../../application/actionable_intelligence.dart';
import '../../application/mood_notifier.dart';
import '../../domain/models/mood.dart';

class CurrentActionCard extends ConsumerWidget {
  const CurrentActionCard({
    super.key,
    this.onCompleted,
    this.onSkip,
  });

  final VoidCallback? onCompleted;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final moodState = ref.watch(moodProvider);
    
    // Get actual virtue type from settings
    final virtueType = settings.primaryVirtue;
    // Get actual mood from mood provider
    final moodType = moodState.currentMood?.type;
    
    // Get current time context
    final hour = DateTime.now().hour;
    final timeContext = hour >= 6 && hour < 12 
        ? TimeContext.morning 
        : hour >= 12 && hour < 18 
            ? TimeContext.midday 
            : hour >= 18 && hour < 22 
                ? TimeContext.evening 
                : TimeContext.night;
    
    final currentAction = ActionableIntelligence.getCurrentAction(
      virtueType: virtueType,
      moodType: moodType,
      timeContext: timeContext,
    );

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bolt,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Your Next Action (Now)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      currentAction.context,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  currentAction.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  currentAction.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.hourglass_bottom,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${currentAction.timeRequired}s',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: () {
                        onCompleted?.call();
                      },
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('I Did This'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {
                        onSkip?.call();
                      },
                      child: const Text('Skip'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
