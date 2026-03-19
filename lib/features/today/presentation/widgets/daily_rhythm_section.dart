import 'package:flutter/material.dart';

import '../../../../../core/theme/app_text_styles.dart';
import '../../domain/models/daily_anchors.dart';
import '../../domain/models/commitment.dart';
import '../../data/offline_commitment_data.dart';
import 'current_anchor_card.dart';
import 'daily_verse_card.dart';
import 'enhanced_commitment_card.dart';
import 'end_of_day_reflection_dialog.dart';

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

/// Displays the appropriate anchor card based on time-of-day and completion state.
///
/// Hour-by-hour coverage:
///   0–4   → Default fallback: Prayer → Habit → Activity → DailyVerse
///   5–9   → Morning window:   Prayer (primary), then fallback
///   10    → Gap window:        Prayer → Habit → Activity → DailyVerse
///   11–15 → Afternoon window:  Habit (primary), then fallback
///   16–18 → Activity window:   Physical Activity (primary), then fallback
///   19–23 → Evening window:    Incomplete anchors first, then Evening Review
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
            'YOUR DAILY RHYTHM',
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

    // FIRST PRIORITY: All daily anchors completed → show daily verse
    if (anchors.coreVirtue.isCompleted &&
        anchors.habit.isCompleted &&
        anchors.energyAction.isCompleted) {
      return const DailyVerseCard();
    }

    // Active commitment takes priority over time-window logic
    if (!anchors.habit.isCompleted && anchors.habit.isCommitmentActive) {
      return _buildEnhancedCommitmentCard(context);
    }

    // Time-window based display
    // Morning (5am - 10am): Morning Prayer
    if (hour >= 5 && hour < 10) {
      return _buildForMorning(context);
    }

    // Gap period (10am - 11am)
    if (hour >= 10 && hour < 11) {
      return _buildFallbackAnchor(context,
          primaryMessage: 'Complete your morning prayer before the day gets busy.');
    }

    // Daily Anchor Window (11am - 4pm): Focus on commitment
    if (hour >= 11 && hour < 16) {
      return _buildForAfternoon(context);
    }

    // Physical Activity Window (4pm - 7pm)
    if (hour >= 16 && hour < 19) {
      return _buildForLateAfternoon(context);
    }

    // Evening (7pm onwards): Show remaining incomplete anchors first, then review
    if (hour >= 19) {
      return _buildForEvening(context);
    }

    // Default (0am - 5am): fallback priority
    return _buildFallbackAnchor(context,
        primaryMessage: 'Start your day with prayer about your current virtue: ${anchors.coreVirtue.type.title}');
  }

  // --- Time-window builders ---

  Widget _buildForMorning(BuildContext context) {
    if (!anchors.coreVirtue.isCompleted) {
      return _prayerCard(context,
          subtitle: 'Pray about your current virtue: ${anchors.coreVirtue.type.title}');
    }
    // Prayer done — show next incomplete
    return _buildFallbackAnchor(context,
        primaryMessage: 'Time for some movement to reinforce your virtue practice.');
  }

  Widget _buildForAfternoon(BuildContext context) {
    if (!anchors.habit.isCompleted) {
      return _habitCard(context);
    }
    // Habit done — show next incomplete
    return _buildFallbackAnchor(context,
        primaryMessage: 'Complete your morning prayer.');
  }

  Widget _buildForLateAfternoon(BuildContext context) {
    final hour = now.hour;
    if (!anchors.energyAction.isCompleted) {
      return _activityCard(context,
          subtitle: hour < 17
              ? 'Take a walk or do a workout to reinforce your virtue practice.'
              : 'Wrap up your day with some movement for energy and clarity.');
    }
    // Activity done — show next incomplete
    return _buildFallbackAnchor(context,
        primaryMessage: 'Complete your morning prayer.');
  }

  Widget _buildForEvening(BuildContext context) {
    // In the evening, show any remaining incomplete anchor first so the user
    // can still finish tasks. Evening Review is the fallback when all tasks
    // are done (handled by the all-complete check above) or as a secondary
    // suggestion when only the review remains relevant.
    if (!anchors.coreVirtue.isCompleted) {
      return _prayerCard(context,
          subtitle: 'You still have time to complete your prayer before the day ends.');
    }
    if (!anchors.habit.isCompleted) {
      return _habitCard(context);
    }
    if (!anchors.energyAction.isCompleted) {
      return _activityCard(context,
          subtitle: 'A short walk or stretching session before bed can help you unwind.');
    }
    // All anchors done — show evening review
    return CurrentAnchorCard(
      icon: Icons.nights_stay_rounded,
      title: 'Evening Review',
      subtitle: 'Reflect on your day and prepare for tomorrow.',
      isCompleted: false,
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => const EndOfDayReflectionDialog(),
        );
      },
    );
  }

  /// Generic fallback: show the next incomplete anchor in priority order
  /// Prayer → Habit → Physical Activity → DailyVerse
  Widget _buildFallbackAnchor(BuildContext context, {required String primaryMessage}) {
    if (!anchors.coreVirtue.isCompleted) {
      return _prayerCard(context, subtitle: primaryMessage);
    }
    if (!anchors.habit.isCompleted) {
      return _habitCard(context);
    }
    if (!anchors.energyAction.isCompleted) {
      return _activityCard(context, subtitle: primaryMessage);
    }
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

  Widget _habitCard(BuildContext context) {
    return CurrentAnchorCard(
      icon: Icons.task_alt_rounded,
      title: anchors.habit.displayTitle,
      subtitle: anchors.habit.displayDescription,
      isCompleted: false,
      onTap: onHabitTap,
    );
  }

  Widget _activityCard(BuildContext context, {required String subtitle}) {
    return CurrentAnchorCard(
      icon: Icons.directions_walk_rounded,
      title: 'Physical Activity',
      subtitle: subtitle,
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
