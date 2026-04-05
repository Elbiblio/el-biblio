import 'package:flutter/material.dart';

import '../../../../../core/theme/app_text_styles.dart';
import '../../domain/models/daily_anchors.dart';
import '../../domain/models/commitment.dart';
import '../../data/offline_commitment_data.dart';
import 'current_anchor_card.dart';
import 'daily_verse_card.dart';
import 'enhanced_commitment_card.dart';

Color getVirtueColor(VirtueType virtue, ThemeData theme) {
  switch (virtue) {
    case VirtueType.humility:
      return const Color(0xFF8B5E3C); // Brown
    case VirtueType.love:
      return const Color(0xFFC85F4B); // Red
    case VirtueType.faith:
      return const Color(0xFF638B6C); // Green
    case VirtueType.knowledge:
      return const Color(0xFF4A6FA5); // Blue
  }
}

/// Displays the appropriate anchor card based on completion state.
///
/// Priority flow (simplified, no strict time windows):
///   1. All anchors complete → DailyVerseCard
///   2. Active commitment    → EnhancedCommitmentCard
///   3. Prayer not done      → Prayer card
///   4. Prayer done, commitment not started → "Begin Your Commitment" card
///   5. Commitment done, activity not done  → Small activity suggestion
///   6. Evening (19+)        → Evening review for remaining items
class DailyRhythmSection extends StatelessWidget {
  const DailyRhythmSection({
    super.key,
    required this.anchors,
    required this.now,
    required this.onPrayerTap,
    required this.onHabitTap,
    required this.onPhysicalActivityTap,
  });

  final DailyAnchors anchors;
  final DateTime now;
  final void Function(Virtue virtue) onPrayerTap;
  final VoidCallback onHabitTap;
  final VoidCallback onPhysicalActivityTap;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(24),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Text(
            'YOUR DAILY CLARITY',
            style: Theme.of(context).textTheme.sectionHeader.copyWith(
                  fontSize: 12,
                  letterSpacing: 1.2,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
          ),
          const SizedBox(height: 16),
          _buildCurrentAnchor(context),
          const SizedBox(height: 120), // Bottom padding for floating nav
        ]),
      ),
    );
  }

  Widget _buildCurrentAnchor(BuildContext context) {
    final hour = now.hour;

    // 1. All daily anchors completed → show daily verse
    if (anchors.coreVirtue.isCompleted &&
        anchors.habit.isCompleted &&
        anchors.energyAction.isCompleted) {
      return const DailyVerseCard();
    }

    // 2. Active commitment takes priority
    if (!anchors.habit.isCompleted && anchors.habit.isCommitmentActive) {
      return _buildEnhancedCommitmentCard(context);
    }

    // 3. Prayer not done → show prayer card
    if (!anchors.coreVirtue.isCompleted) {
      final subtitle = hour >= 19
          ? 'Complete your morning prayer before the day ends.'
          : 'Start your day with a moment of prayer.';
      return _prayerCard(context, subtitle: subtitle);
    }

    // 4. Prayer done, commitment not started → show "Begin Your Commitment"
    if (!anchors.habit.isCompleted) {
      return _beginCommitmentCard(context);
    }

    // 5. Commitment done, activity not done → small activity suggestion
    if (!anchors.energyAction.isCompleted) {
      return _activitySuggestionCard(context);
    }

    // Fallback → daily verse
    return const DailyVerseCard();
  }

  // --- Card helpers ---

  Widget _prayerCard(BuildContext context, {required String subtitle}) {
    return CurrentAnchorCard(
      icon: Icons.wb_sunny_outlined,
      title: 'Morning Prayer',
      subtitle: subtitle,
      isCompleted: false,
      virtueColor: getVirtueColor(anchors.coreVirtue.type, Theme.of(context)),
      onTap: () => onPrayerTap(anchors.coreVirtue),
    );
  }

  Widget _beginCommitmentCard(BuildContext context) {
    return CurrentAnchorCard(
      icon: Icons.flag_rounded,
      title: 'Begin Your Commitment',
      subtitle: 'Choose your daily commitment',
      isCompleted: false,
      onTap: onHabitTap,
    );
  }

  Widget _activitySuggestionCard(BuildContext context) {
    return CurrentAnchorCard(
      icon: Icons.directions_walk_rounded,
      title: 'Optional Activity',
      subtitle: 'A short walk or movement to round off your day.',
      isCompleted: false,
      onTap: onPhysicalActivityTap,
    );
  }

  Widget _buildEnhancedCommitmentCard(BuildContext context) {
    final hour = now.hour;
    String timePeriod = 'MORNING';
    if (hour >= 11 && hour < 17) {
      timePeriod = 'AFTERNOON';
    } else if (hour >= 17) {
      timePeriod = 'EVENING';
    }

    Commitment? commitmentData;
    if (anchors.habit.commitmentId != null) {
      try {
        final offlineCommitments =
            OfflineCommitmentData.getCommitmentsForVirtue(anchors.coreVirtue.type);
        commitmentData = offlineCommitments
            .where((c) => c.id == anchors.habit.commitmentId)
            .firstOrNull;
      } catch (e) {
        debugPrint('Could not find commitment data: $e');
      }
    }

    return EnhancedCommitmentCard(
      anchor: anchors.habit,
      onTap: onHabitTap,
      timePeriod: timePeriod,
      commitment: commitmentData,
    );
  }
}
