import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/onboarding_notifier.dart';

class CommitView extends ConsumerWidget {
  const CommitView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);
    final primary = notifier.primaryArchetype;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            'What matters most right now?',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose one focus to start your journey.',
            style: textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
            ),
          ),
          const SizedBox(height: 28),
          _CommitChoiceCard(
            icon: Icons.auto_awesome_outlined,
            title: 'Start a good habit',
            description: 'Build a daily spiritual practice — prayer, Bible, gratitude, silence.',
            isSelected: state.commitmentChoice == 'good_habit',
            onTap: () => notifier.setCommitmentChoice('good_habit'),
          ),
          const SizedBox(height: 12),
          _CommitChoiceCard(
            icon: Icons.block_outlined,
            title: 'Break a bad habit',
            description: 'Stop a habit that\'s holding you back, with support and accountability.',
            isSelected: state.commitmentChoice == 'bad_habit',
            onTap: () => notifier.setCommitmentChoice('bad_habit'),
          ),
          const SizedBox(height: 12),
          _CommitChoiceCard(
            icon: Icons.explore_outlined,
            title: 'Follow a 40-day guide',
            description: 'A structured plan to grow in a specific area of your faith.',
            isSelected: state.commitmentChoice == 'forty_day',
            onTap: () => notifier.setCommitmentChoice('forty_day'),
          ),
          if (primary != null && state.commitmentChoice != null) ...[
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.tertiary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 18,
                        color: theme.colorScheme.tertiary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Suggested for you',
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.tertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...primary.growthCommitments.take(3).map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(fontWeight: FontWeight.w700)),
                          Expanded(child: Text(c)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (state.commitmentChoice != null) ...[
            const SizedBox(height: 24),
            Text(
              'Great choice. You\'ll set the details when you start.',
              style: textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _CommitChoiceCard extends StatelessWidget {
  const _CommitChoiceCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : theme.colorScheme.surface.withValues(alpha: 0.74),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.14),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary.withValues(alpha: 0.12)
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.2)
                      : theme.colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
