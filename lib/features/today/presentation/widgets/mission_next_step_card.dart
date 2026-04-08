import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../../../mission/domain/models/mission_focus.dart';

/// Unified commitment/action card for the Today screen.
///
/// Shows the user's next action in a compact format that feels like part
/// of the daily rhythm — not a separate module. If the user has an active
/// commitment journey, service opportunities, or mission actions, they all
/// surface here as "your next step" rather than cluttering the screen with
/// multiple cards.
class MissionNextStepCard extends ConsumerWidget {
  const MissionNextStepCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mission = ref.watch(missionProvider);
    final settings = ref.watch(settingsProvider);
    final journeyState = ref.watch(commitmentJourneyProvider);
    final nextAction = mission.nextAction;
    final hasPartner = mission.accountabilityPartner != null;
    final archetype = settings.primaryArchetypeId;
    final hasActiveJourney = journeyState.activeJourney != null;

    // Count active commitments for context label
    final activeCount = [
      if (nextAction != null) 1,
      if (hasActiveJourney) 1,
    ].length;

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
            // Compact header
            Row(
              children: [
                Icon(
                  Icons.volunteer_activism_rounded,
                  size: 18,
                  color: theme.colorScheme.primary.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Text(
                  activeCount > 0
                      ? 'Your Next Step'
                      : 'Choose a Step',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                if (activeCount > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$activeCount active',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Action title
            Text(
              nextAction?.title ?? 'Choose one step for today',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // Subtitle: brief description
            Text(
              nextAction?.description ?? _fallbackCopy(mission.focus.label, archetype),
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.4,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Compact action row
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => context.push(AppRoutes.act),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(nextAction == null ? 'Open Act' : 'Continue'),
                  ),
                ),
                const SizedBox(width: 10),
                if (hasPartner)
                  OutlinedButton(
                    onPressed: () => context.push(AppRoutes.growTogether),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Check in'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fallbackCopy(String focusLabel, String? archetype) {
    if ((archetype ?? '').isNotEmpty) {
      return 'Take one $focusLabel step today as part of your calling.';
    }
    return 'Choose one practical step you can complete today.';
  }
}
