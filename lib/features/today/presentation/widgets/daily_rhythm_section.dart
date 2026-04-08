import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../domain/models/daily_anchors.dart';
import '../../domain/models/commitment.dart';
import '../../data/offline_commitment_data.dart';
import 'current_anchor_card.dart';
import 'daily_verse_card.dart';
import 'enhanced_commitment_card.dart';

Color getVirtueColor(VirtueType virtue, ThemeData theme) {
  final tokens = theme.tokens;
  switch (virtue) {
    case VirtueType.humility:
      return tokens.palette.commitmentColor; // Green
    case VirtueType.love:
      return tokens.palette.growthColor; // Orange
    case VirtueType.faith:
      return tokens.palette.commitmentColor; // Green
    case VirtueType.knowledge:
      return tokens.palette.distractionColor; // Blue
  }
}

/// Displays the daily spiritual journey organized by time of day.
///
/// The journey flows through three phases:
///   1. Morning: Connect with God through prayer
///   2. Midday: Live your calling through your commitment
///   3. Evening: Reflect and refresh
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
    final theme = Theme.of(context);
    final hour = now.hour;
    
    // Determine time context for contextual messaging
    final timeContext = _getTimeContext(hour);
    
    return SliverPadding(
      padding: const EdgeInsets.all(24),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // Section header with time-appropriate greeting
          Text(
            timeContext.headerLabel,
            style: theme.textTheme.sectionHeader.copyWith(
                  fontSize: 12,
                  letterSpacing: 1.2,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
          ),
          const SizedBox(height: 16),
          
          // Show the current phase card (only one at a time for clarity)
          _buildCurrentPhaseCard(context, timeContext),
          
          const SizedBox(height: 120), // Bottom padding for floating nav
        ]),
      ),
    );
  }

  Widget _buildCurrentPhaseCard(BuildContext context, TimeContext timeContext) {
    // 1. All daily anchors completed → show daily verse
    if (anchors.coreVirtue.isCompleted &&
        anchors.habit.isCompleted &&
        anchors.energyAction.isCompleted) {
      return const DailyVerseCard();
    }

    // 2. Active commitment takes priority (regardless of time)
    if (!anchors.habit.isCompleted && anchors.habit.isCommitmentActive) {
      return _buildActiveCommitmentCard(context);
    }

    // 3. Morning phase: Prayer not done
    if (!anchors.coreVirtue.isCompleted) {
      return _morningCard(context);
    }

    // 4. Midday phase: Commitment not started or in progress
    if (!anchors.habit.isCompleted) {
      return _middayCard(context);
    }

    // 5. Evening phase: Activity not done
    if (!anchors.energyAction.isCompleted) {
      return _eveningCard(context);
    }

    // Fallback → daily verse
    return const DailyVerseCard();
  }

  // --- Phase-specific cards with clear time labels ---

  Widget _morningCard(BuildContext context) {
    return CurrentAnchorCard(
      icon: Icons.wb_sunny_outlined,
      title: 'Morning: Connect with God',
      subtitle: anchors.coreVirtue.isCompleted
          ? 'Morning prayer complete'
          : 'Start your day grounded in prayer and scripture',
      isCompleted: anchors.coreVirtue.isCompleted,
      virtueColor: getVirtueColor(anchors.coreVirtue.type, Theme.of(context)),
      onTap: () => onPrayerTap(anchors.coreVirtue),
    );
  }

  Widget _middayCard(BuildContext context) {
    // Show specific commitment if selected, otherwise generic
    final commitmentTitle = anchors.habit.commitmentTitle;
    final title = commitmentTitle != null
        ? 'Midday: $commitmentTitle'
        : 'Midday: Live Your Commitment';
    
    final subtitle = anchors.habit.isLockedIn
        ? 'Your commitment is locked in. Stay focused!'
        : anchors.habit.commitmentDescription ?? 'Choose and practice your daily habit';

    return CurrentAnchorCard(
      icon: Icons.flag_outlined,
      title: title,
      subtitle: subtitle,
      isCompleted: anchors.habit.isCompleted,
      onTap: onHabitTap,
    );
  }

  Widget _eveningCard(BuildContext context) {
    return CurrentAnchorCard(
      icon: Icons.nightlight_outlined,
      title: 'Evening: Refresh & Reflect',
      subtitle: 'Take a walk, breathe deeply, and thank God for today',
      isCompleted: anchors.energyAction.isCompleted,
      virtueColor: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.8),
      onTap: onPhysicalActivityTap,
    );
  }

  Widget _buildActiveCommitmentCard(BuildContext context) {
    final hour = now.hour;
    String timePeriod = 'Morning';
    if (hour >= 11 && hour < 17) {
      timePeriod = 'Afternoon';
    } else if (hour >= 17) {
      timePeriod = 'Evening';
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

  TimeContext _getTimeContext(int hour) {
    if (hour >= 5 && hour < 12) {
      return TimeContext.morning;
    } else if (hour >= 12 && hour < 17) {
      return TimeContext.midday;
    } else if (hour >= 17 && hour < 22) {
      return TimeContext.evening;
    } else {
      return TimeContext.night;
    }
  }
}

/// Time contexts for contextual messaging
class TimeContext {
  final String headerLabel;
  
  const TimeContext._(this.headerLabel);
  
  static final morning = TimeContext._('YOUR MORNING JOURNEY');
  static final midday = TimeContext._('YOUR MIDDAY JOURNEY');
  static final evening = TimeContext._('YOUR EVENING JOURNEY');
  static final night = TimeContext._('TONIGHT\'S REFLECTION');
}
