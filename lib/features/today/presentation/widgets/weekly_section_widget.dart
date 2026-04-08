import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/theme/app_animations.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../assessment/domain/models/weekly_plan.dart';
import 'streak_badge.dart';
import 'integrity_badge.dart';

/// Consolidated weekly section that combines WeeklyPrioritiesWidget and WeeklyRecapCard
/// into a single collapsible widget with streak and integrity metrics.
class WeeklySectionWidget extends ConsumerStatefulWidget {
  const WeeklySectionWidget({super.key});

  @override
  ConsumerState<WeeklySectionWidget> createState() => _WeeklySectionWidgetState();
}

class _WeeklySectionWidgetState extends ConsumerState<WeeklySectionWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final anchors = ref.watch(dailyAnchorsProvider);
    final weeklyPlan = settings.currentWeeklyPlan;
    final now = DateTime.now();
    final isFriday = now.weekday == DateTime.friday;
    final isSunday = now.weekday == DateTime.sunday;

    // Only show if there's a weekly plan OR it's Friday/Sunday for recap
    if (weeklyPlan == null && !isFriday && !isSunday) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final isDark = theme.brightness == Brightness.dark;

    final completedToday = <bool>[
      anchors.coreVirtue.isCompleted,
      anchors.habit.isCompleted,
      anchors.energyAction.isCompleted,
    ].where((value) => value).length;

    final streakLabel = settings.streakCount == 1 ? '1 day' : '${settings.streakCount} days';
    final score = settings.lastIntegrityScore;
    final date = settings.lastIntegrityDate;

    // Check if integrity score is from today
    bool showIntegrity = false;
    if (score > 0 && date != null) {
      final today = DateTime(now.year, now.month, now.day);
      final normalizedDate = DateTime(date.year, date.month, date.day);
      showIntegrity = normalizedDate == today;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  theme.colorScheme.surface.withValues(alpha: 0.3),
                  theme.colorScheme.surface.withValues(alpha: 0.1),
                ]
              : [
                  theme.colorScheme.primary.withValues(alpha: 0.05),
                  theme.colorScheme.secondary.withValues(alpha: 0.05),
                ],
        ),
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with expand/collapse
          InkWell(
            onTap: () {
              HapticService.selection();
              setState(() => _isExpanded = !_isExpanded);
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: AppAnimations.fast,
                    curve: AppAnimations.defaultCurve,
                    child: Icon(
                      Icons.expand_more,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'This Week',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  // Quick metrics (always visible)
                  if (settings.streakCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: StreakBadge(),
                    ),
                  if (showIntegrity)
                    IntegrityBadge(),
                ],
              ),
            ),
          ),
          
          // Expandable content with smooth animation
          AnimatedSize(
            duration: AppAnimations.normal,
            curve: AppAnimations.sizeCurve,
            alignment: Alignment.topCenter,
            child: _isExpanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
            const SizedBox(height: 12),

            // Weekly recap on Friday/Sunday
            if (isFriday || isSunday) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _RecapMetric(
                        label: 'Streak',
                        value: streakLabel,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _RecapMetric(
                        label: 'Today',
                        value: '$completedToday/3 anchors',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Weekly plan content
            if (weeklyPlan != null) ...[
              // Reflection Prompt
              if (weeklyPlan.reflectionPrompt.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline_rounded,
                            color: theme.colorScheme.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'This Week\'s Reflection',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        weeklyPlan.reflectionPrompt,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Weekly commitments
              ...weeklyPlan.weeklyCommitments.map((commitment) => _CommitmentItem(
                    commitment: commitment,
                    theme: theme,
                  )),
              
              const SizedBox(height: 8),
              
              // View profile link
              TextButton(
                onPressed: () => context.push(AppRoutes.callingProfile),
                child: const Text('View full profile'),
              ),
            ],
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _CommitmentItem extends StatelessWidget {
  const _CommitmentItem({
    required this.commitment,
    required this.theme,
  });

  final WeeklyCommitment commitment;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final progress = commitment.completionPercentage;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  commitment.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Text(
                '${commitment.currentCount}/${commitment.targetCount}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            commitment.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                commitment.isComplete
                    ? theme.colorScheme.tertiary
                    : theme.colorScheme.primary,
              ),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecapMetric extends StatelessWidget {
  const _RecapMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
