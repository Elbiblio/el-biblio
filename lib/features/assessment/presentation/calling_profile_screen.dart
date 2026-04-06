import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/app_providers.dart';

class CallingProfileScreen extends ConsumerWidget {
  const CallingProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final profile = settings.callingProfile;
    final weeklyPlan = settings.currentWeeklyPlan;

    if (profile == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Calling Profile'),
        ),
        body: Center(
          child: Text(
            'Your calling profile is not ready yet.',
            style: theme.textTheme.bodyLarge,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calling Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            title: profile.archetypeIdentity,
            subtitle: profile.archetypeId,
            children: [
              Text(
                'Mission focus: ${profile.missionFocus}',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Commitment category: ${profile.commitmentCategory}',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Weekly Priorities',
            children: profile.weeklyPriorities
                .map(
                  (priority) => _BulletBlock(
                    title: priority.area,
                    subtitle: priority.focus,
                    items: priority.suggestedActions,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Service Tendencies',
            children: [
              _StringList(items: profile.burdensAndServiceTendencies),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Relational Focus',
            children: [
              _StringList(items: profile.relationalFocus),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Growth Risks',
            children: [
              _StringList(items: profile.growthRisks),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Recommended Practices',
            children: profile.recommendedPractices
                .map(
                  (practice) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(practice.name),
                    subtitle: Text(practice.description),
                    trailing: Text(practice.frequency),
                  ),
                )
                .toList(),
          ),
          if (profile.personalDistractions.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Personal Distractions',
              children: [
                _StringList(items: profile.personalDistractions),
              ],
            ),
          ],
          if (weeklyPlan != null) ...[
            const SizedBox(height: 16),
            _SectionCard(
              title: 'This Week',
              children: [
                Text(
                  weeklyPlan.reflectionPrompt,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                ...weeklyPlan.weeklyCommitments.map(
                  (commitment) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(commitment.title),
                    subtitle: Text(commitment.description),
                    trailing: Text('${commitment.currentCount}/${commitment.targetCount}'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if ((subtitle ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ],
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _StringList extends StatelessWidget {
  const _StringList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Icon(
                      Icons.circle,
                      size: 8,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _BulletBlock extends StatelessWidget {
  const _BulletBlock({
    required this.title,
    required this.subtitle,
    required this.items,
  });

  final String title;
  final String subtitle;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(subtitle),
          const SizedBox(height: 8),
          _StringList(items: items),
        ],
      ),
    );
  }
}
