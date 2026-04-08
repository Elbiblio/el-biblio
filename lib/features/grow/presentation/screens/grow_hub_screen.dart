import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/theme/app_theme_tokens.dart';

/// GrowHubScreen - Central hub for spiritual growth and learning
/// 
/// Connects users to:
/// - Games (Scripture learning through play)
/// - Faith Questions (Deep theological exploration)
/// - Reading Plans (Structured Bible study)
/// - Progress tracking (Growth journey)
class GrowHubScreen extends ConsumerStatefulWidget {
  const GrowHubScreen({super.key});

  @override
  ConsumerState<GrowHubScreen> createState() => _GrowHubScreenState();
}

class _GrowHubScreenState extends ConsumerState<GrowHubScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsProvider).track('grow_hub_viewed');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = ref.watch(settingsProvider);
    final profile = settings.callingProfile;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 140,
            floating: true,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Grow'),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.15),
                      colorScheme.secondary.withValues(alpha: 0.1),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Growth Summary Card
                _GrowthSummaryCard(
                  archetype: profile?.archetypeIdentity ?? 'Discoverer',
                  streakDays: settings.streakCount,
                  completedActions: settings.missionActions.where((a) => a.isCompleted).length,
                ),

                const SizedBox(height: 24),

                // Learning Section
                Text(
                  'Learn & Play',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                _GrowHubCard(
                  icon: Icons.games_rounded,
                  iconColor: colorScheme.primary,
                  title: 'Scripture Games',
                  subtitle: 'Learn God\'s word through play. Every game strengthens your knowledge.',
                  onTap: () => context.push(AppRoutes.games),
                ),

                const SizedBox(height: 24),

                // Study Section
                Text(
                  'Study & Reflect',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                _GrowHubCard(
                  icon: Icons.menu_book_rounded,
                  iconColor: colorScheme.tertiary,
                  title: 'Reading Plans',
                  subtitle: 'Follow guided paths through Scripture with daily readings.',
                  onTap: () => context.push(AppRoutes.bible),
                ),

                const SizedBox(height: 12),

                _GrowHubCard(
                  icon: Icons.edit_note_rounded,
                  iconColor: colorScheme.primary,
                  title: 'Journal',
                  subtitle: 'Record your spiritual journey and insights.',
                  onTap: () => context.push(AppRoutes.journal),
                ),

                const SizedBox(height: 24),

                // Community Growth
                Text(
                  'Grow Together',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                _GrowHubCard(
                  icon: Icons.people_alt_rounded,
                  iconColor: colorScheme.secondary,
                  title: 'Accountability Partner',
                  subtitle: 'Connect with someone to support your spiritual growth.',
                  onTap: () => context.push(AppRoutes.growTogether),
                ),

                const SizedBox(height: 12),

                _GrowHubCard(
                  icon: Icons.person_add_rounded,
                  iconColor: colorScheme.tertiary,
                  title: 'Invite Friends',
                  subtitle: 'Share El-Biblio with others on their faith journey.',
                  onTap: () => context.push(AppRoutes.invite),
                ),

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _GrowthSummaryCard extends StatelessWidget {
  const _GrowthSummaryCard({
    required this.archetype,
    required this.streakDays,
    required this.completedActions,
  });

  final String archetype;
  final int streakDays;
  final int completedActions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = theme.tokens;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.trending_up_rounded,
                  color: colorScheme.onPrimaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Growth Journey',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      archetype,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatItem(
                value: '$streakDays',
                label: 'Day Streak',
                icon: Icons.local_fire_department_rounded,
              ),
              const SizedBox(width: 24),
              _StatItem(
                value: '$completedActions',
                label: 'Actions',
                icon: Icons.volunteer_activism_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

class _GrowHubCard extends StatelessWidget {
  const _GrowHubCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.tokens.palette.border.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
