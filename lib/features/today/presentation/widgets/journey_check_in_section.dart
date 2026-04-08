import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/app_providers.dart';
import '../../../commitments/domain/models/commitment_journey.dart';
import 'partner_check_in_card.dart';

/// Section on TodayScreen that shows either:
/// 1. Partner check-in card (if viewing as partner, 6pm-8pm)
/// 2. User check-in card (8pm+ or no partner)
/// 3. Journey progress summary (if already checked in or too early)
class JourneyCheckInSection extends ConsumerWidget {
  const JourneyCheckInSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journeyState = ref.watch(commitmentJourneyProvider);
    
    // No active journey - show nothing (or a prompt to start one)
    if (journeyState.activeJourney == null) {
      return const SizedBox.shrink();
    }

    final activeJourney = journeyState.activeJourney!;
    final now = DateTime.now();
    final hour = now.hour;

    // Get journey details
    return FutureBuilder<CommitmentJourney>(
      future: ref.read(commitmentJourneyProvider.notifier).getCurrentJourneyDetails(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final journey = snapshot.data!;

        // Check if already checked in today
        final alreadyCheckedIn = activeJourney.completedDays.contains(activeJourney.currentDay);

        // Determine what to show based on time and status
        if (alreadyCheckedIn) {
          // Already checked in - show completion summary
          return UserEveningCheckInCard(
            journey: journey,
            activeJourney: activeJourney,
            onCheckIn: () {},
            partnerName: null,
          );
        }

        // Before 6pm - show upcoming check-in notice (subtle)
        if (hour < 18) {
          return _UpcomingCheckInNotice(
            journey: journey,
            activeJourney: activeJourney,
            hoursUntilCheckIn: 18 - hour,
          );
        }

        // 6pm-8pm - Partner check-in window
        // In a real app, this would detect if the current user is the partner
        // For now, we show the user view with partner notification
        if (hour >= 18 && hour < 20) {
          // TODO: Detect if viewing as partner vs user
          // For now, show user view with note about partner being asked
          return UserEveningCheckInCard(
            journey: journey,
            activeJourney: activeJourney,
            onCheckIn: () => _handleCheckIn(ref),
            partnerName: 'Partner', // Would come from user profile
          );
        }

        // 8pm+ - User can check in
        return UserEveningCheckInCard(
          journey: journey,
          activeJourney: activeJourney,
          onCheckIn: () => _handleCheckIn(ref),
          partnerName: null,
        );
      },
    );
  }

  Future<void> _handleCheckIn(WidgetRef ref) async {
    await ref.read(commitmentJourneyProvider.notifier).checkInToday();
  }
}

/// Simpler upcoming check-in notice for before 6pm
class _UpcomingCheckInNotice extends StatelessWidget {
  const _UpcomingCheckInNotice({
    required this.journey,
    required this.activeJourney,
    required this.hoursUntilCheckIn,
  });

  final CommitmentJourney journey;
  final ActiveJourney activeJourney;
  final int hoursUntilCheckIn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.schedule_outlined,
              size: 20,
              color: theme.colorScheme.primary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  journey.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Day ${activeJourney.currentDay} of ${journey.duration.days} • Check-in at 6pm',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
