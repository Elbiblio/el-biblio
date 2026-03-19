import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/app_providers.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_tokens.dart';

class RhythmSummaryCard extends ConsumerWidget {
  const RhythmSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    final streak = settings.streakCount;
    final longestStreak = settings.longestStreakCount;

    final last = settings.lastCheckIn;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final normalizedLast = last == null
        ? null
        : DateTime(last.year, last.month, last.day);

    final daysSince = normalizedLast == null
        ? null
        : today.difference(normalizedLast).inDays;

    final lastLabel = daysSince == null
        ? '—'
        : daysSince == 0
            ? 'Today'
            : daysSince == 1
                ? 'Yesterday'
                : '$daysSince days ago';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.palette.border),
        color: theme.colorScheme.surface.withValues(alpha: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RHYTHM',
            style: theme.textTheme.sectionHeader.copyWith(
              color: tokens.palette.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'Streak',
                  value: streak == 0 ? '—' : '$streak',
                  suffix: streak == 1 ? 'day' : 'days',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Metric(
                  label: 'Best',
                  value: longestStreak == 0 ? '—' : '$longestStreak',
                  suffix: longestStreak == 1 ? 'day' : 'days',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Metric(
                  label: 'Last check-in',
                  value: lastLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              border: Border.all(color: tokens.palette.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Reminders: ${settings.morningTime} / ${settings.eveningTime}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                    ),
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

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    this.suffix,
  });

  final String label;
  final String value;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 6,
          children: [
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            if (suffix != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  suffix!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
