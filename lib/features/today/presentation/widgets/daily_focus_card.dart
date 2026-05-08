import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../commitments/domain/models/commitment_category.dart';
import '../../domain/models/daily_anchors.dart';
import 'contextual_help_button.dart';
import 'today_journey_timeline.dart';

/// A unified card showing identity, daily journey progress, and current commitment.
/// 
/// Separates identity (who you are) from daily progress (what you do today)
/// to reduce cognitive load and make the daily journey crystal clear.
class DailyFocusCard extends ConsumerWidget {
  const DailyFocusCard({
    super.key,
    required this.anchors,
    this.onPrayerTap,
    this.onHabitTap,
    this.onActivityTap,
  });

  final DailyAnchors anchors;
  final VoidCallback? onPrayerTap;
  final VoidCallback? onHabitTap;
  final VoidCallback? onActivityTap;

  int _completedCount() {
    int count = 0;
    if (anchors.coreVirtue.isCompleted) count++;
    if (anchors.habit.isCompleted) count++;
    if (anchors.energyAction.isCompleted) count++;
    return count;
  }

  int _currentPhaseIndex() {
    // 0 = morning (prayer), 1 = midday (commitment), 2 = evening (activity)
    if (!anchors.coreVirtue.isCompleted) return 0;
    if (!anchors.habit.isCompleted) return 1;
    if (!anchors.energyAction.isCompleted) return 2;
    return -1; // All done
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final isDark = theme.brightness == Brightness.dark;
    final completed = _completedCount();
    final currentPhase = _currentPhaseIndex();

    final archetypeName = settings.primaryArchetypeId;
    final categoryName = settings.commitmentCategory;
    final category = categoryName == null
        ? null
        : CommitmentCategory.fromString(categoryName);
    final hasArchetype = archetypeName != null && archetypeName.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Identity Section: Your Calling
          if (hasArchetype) ...[
            Row(
              children: [
                Icon(
                  Icons.fingerprint_outlined,
                  size: 18,
                  color: theme.colorScheme.primary.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Text(
                  'Your Calling',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(width: 8),
                const ContextualHelpButton(
                  title: 'Your Calling',
                  explanation: 'Your archetype reflects how God designed you to serve. '
                      'It shapes your daily practices and helps you grow in your unique purpose.',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Semantics(
              button: true,
              label: 'Open calling profile for $archetypeName',
              child: GestureDetector(
                onTap: () => context.push(AppRoutes.callingProfile),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.25 : 0.15),
                    ),
                  ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            archetypeName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          if (category != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Focus: ${category.label}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ),
            ),
            ),
            const SizedBox(height: 20),
          ],

          // Journey Timeline Section
          TodayJourneyTimeline(
            completedPhases: completed,
            currentPhase: currentPhase,
            onPhaseTap: (index) {
              final callback = _getPhaseCallback(index);
              if (callback != null) callback();
            },
          ),
          
          const SizedBox(height: 16),
          
          // Current Action Summary (when not all done)
          if (currentPhase >= 0) ...[
            Semantics(
              button: true,
              label: _getCurrentPhaseTitle(currentPhase),
              child: GestureDetector(
              onTap: _getPhaseCallback(currentPhase),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                      theme.colorScheme.primary.withValues(alpha: isDark ? 0.1 : 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.3 : 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getCurrentPhaseIcon(currentPhase),
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getCurrentPhaseTitle(currentPhase),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getCurrentPhaseSubtitle(currentPhase, anchors),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            ),
          ],

          // All done celebration (when all phases complete)
          if (currentPhase < 0) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: tokens.palette.success.withValues(alpha: isDark ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: tokens.palette.success.withValues(alpha: isDark ? 0.3 : 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: tokens.palette.success.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.celebration_outlined,
                      color: tokens.palette.success,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Day Complete!',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: tokens.palette.success,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Rest in God\'s presence. See your daily verse below.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  VoidCallback? _getPhaseCallback(int phase) {
    return switch (phase) {
      0 => onPrayerTap,
      1 => onHabitTap,
      2 => onActivityTap,
      _ => null,
    };
  }

  IconData _getCurrentPhaseIcon(int phase) {
    return switch (phase) {
      0 => Icons.wb_sunny_outlined,
      1 => Icons.flag_outlined,
      2 => Icons.directions_walk_outlined,
      _ => Icons.check_circle_outline,
    };
  }

  String _getCurrentPhaseTitle(int phase) {
    return switch (phase) {
      0 => 'Next: Morning Prayer',
      1 => 'Next: Live Your Commitment',
      2 => 'Next: Evening Refresh',
      _ => 'Day Complete',
    };
  }

  String _getCurrentPhaseSubtitle(int phase, DailyAnchors anchors) {
    return switch (phase) {
      0 => 'Start your day with God',
      1 => anchors.habit.commitmentTitle ?? 'Practice your daily habit',
      2 => 'A short walk or movement',
      _ => 'All phases complete',
    };
  }
}
