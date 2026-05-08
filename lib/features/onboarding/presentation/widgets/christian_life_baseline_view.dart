import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../companion/domain/models/christian_life_baseline.dart';
import '../../application/onboarding_notifier.dart';

/// Step 5: Christian-Life Baseline — six questions captured as an honest
/// snapshot. Never shamed; framed as the starting point.
///
/// Feeds backend weekly-plan difficulty and the companion's opening tone.
class ChristianLifeBaselineView extends ConsumerWidget {
  const ChristianLifeBaselineView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'An honest starting point',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No judgement — just where you are today. This shapes a first step that actually fits.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),

          const _QuestionLabel('How often do you read the Bible?'),
          const SizedBox(height: 10),
          _SingleSelect<BibleReadingCadence>(
            options: BibleReadingCadence.values,
            current: state.bibleReadingCadence,
            labelOf: (v) => v.label,
            onChanged: notifier.setBibleReadingCadence,
          ),
          const SizedBox(height: 24),

          const _QuestionLabel('When were you last at church?'),
          const SizedBox(height: 10),
          _SingleSelect<ChurchAttendance>(
            options: ChurchAttendance.values,
            current: state.lastChurchAttendance,
            labelOf: (v) => v.label,
            onChanged: notifier.setLastChurchAttendance,
          ),
          const SizedBox(height: 24),

          const _QuestionLabel('What\'s your prayer rhythm right now?'),
          const SizedBox(height: 10),
          _SingleSelect<PrayerRhythm>(
            options: PrayerRhythm.values,
            current: state.prayerRhythm,
            labelOf: (v) => v.label,
            onChanged: notifier.setPrayerRhythm,
          ),
          const SizedBox(height: 32),

          Text(
            'Rate yourself gently — 1 is struggle, 5 is rest.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),

          _ScoreRow(
            title: 'Trust in God\'s sovereignty',
            anchorLow: 'I struggle to trust',
            anchorHigh: 'I rest in His plan',
            value: state.sovereigntyScore,
            onChanged: notifier.setSovereigntyScore,
          ),
          const SizedBox(height: 20),
          _ScoreRow(
            title: 'Charity — giving posture',
            anchorLow: 'I rarely give',
            anchorHigh: 'Giving shapes my week',
            value: state.charityScore,
            onChanged: notifier.setCharityScore,
          ),
          const SizedBox(height: 20),
          _ScoreRow(
            title: 'Trust / faith in others',
            anchorLow: 'I keep walls up',
            anchorHigh: 'I lean into community',
            value: state.trustScore,
            onChanged: notifier.setTrustScore,
          ),
        ],
      ),
    );
  }
}

class _QuestionLabel extends StatelessWidget {
  const _QuestionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
      ),
    );
  }
}

class _SingleSelect<T> extends StatelessWidget {
  const _SingleSelect({
    required this.options,
    required this.current,
    required this.labelOf,
    required this.onChanged,
  });

  final List<T> options;
  final T? current;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final selected = opt == current;
        return ChoiceChip(
          label: Text(labelOf(opt)),
          selected: selected,
          onSelected: (_) => onChanged(opt),
          selectedColor: theme.colorScheme.primary.withValues(alpha: 0.14),
          labelStyle: theme.textTheme.bodySmall?.copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.78),
          ),
        );
      }).toList(),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.title,
    required this.anchorLow,
    required this.anchorHigh,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String anchorLow;
  final String anchorHigh;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: List.generate(5, (i) {
            final score = i + 1;
            final selected = value == score;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(score),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 44,
                  decoration: BoxDecoration(
                    color: selected
                        ? theme.colorScheme.primary.withValues(alpha: 0.14)
                        : theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? theme.colorScheme.primary.withValues(alpha: 0.45)
                          : theme.colorScheme.outline.withValues(alpha: 0.12),
                      width: selected ? 1.4 : 1.0,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$score',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              anchorLow,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            Text(
              anchorHigh,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
