import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/theme/app_theme_tokens.dart';

/// GrowHubScreen - Unified personal growth dashboard.
///
/// Consolidates alignment hub features (spiritual profile, habits, 40-day goals)
/// with learning & community features into one streamlined screen.
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
      ref.read(alignmentProvider.notifier).loadProfile();
      ref.read(habitProvider.notifier).loadHabits();
      ref.read(fortyDayProvider.notifier).loadGoal();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = ref.watch(settingsProvider);
    final alignmentState = ref.watch(alignmentProvider);
    final habitState = ref.watch(habitProvider);
    final fortyDayState = ref.watch(fortyDayProvider);
    final profile = alignmentState.currentProfile;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
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
                  archetype:
                      profile?.archetypeName ??
                      settings.callingProfile?.archetypeIdentity ??
                      'Discoverer',
                  streakDays: settings.streakCount,
                  completedActions: settings.missionActions
                      .where((a) => a.isCompleted)
                      .length,
                  onTap: () => context.push('/alignment/profile'),
                ),

                const SizedBox(height: 24),

                // ── YOUR JOURNEY ────────────────────────────────
                Text(
                  'Your Journey',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Spiritual Profile
                _GrowHubCard(
                  icon: LucideIcons.compass,
                  iconColor: colorScheme.primary,
                  title: profile != null
                      ? 'The ${profile.archetypeName}'
                      : 'Discover Your Archetype',
                  subtitle: profile != null
                      ? 'Your spiritual identity shapes your growth path.'
                      : 'Take the assessment to discover your unique gifts.',
                  onTap: () => context.push('/alignment/profile'),
                ),

                const SizedBox(height: 12),

                // Habit Tracking
                _GrowHubCard(
                  icon: LucideIcons.target,
                  iconColor: colorScheme.secondary,
                  title: 'Habit Conquest',
                  subtitle: habitState.activeHabits.isEmpty
                      ? 'Build spiritual habits that anchor your purpose daily.'
                      : '${habitState.activeHabits.length} active habits | ${habitState.longestStreak}d best streak',
                  trailing: habitState.activeHabits.isNotEmpty
                      ? _ProgressBadge(
                          value: habitState.consistencyPercent,
                          color: colorScheme.secondary,
                        )
                      : null,
                  onTap: () {
                    if (habitState.activeHabits.isEmpty) {
                      context.push('/alignment/habit-assessment');
                    } else {
                      context.push('/alignment/habit-tracker');
                    }
                  },
                ),

                const SizedBox(height: 12),

                // 40-Day Goal
                _GrowHubCard(
                  icon: LucideIcons.flame,
                  iconColor: colorScheme.tertiary,
                  title: fortyDayState.hasActiveGoal
                      ? fortyDayState.activeGoal!.title
                      : '40-Day Spiritual Goal',
                  subtitle: fortyDayState.hasActiveGoal
                      ? 'Day ${fortyDayState.currentDay} of 40 | ${fortyDayState.streakDays}d streak'
                      : 'Set a focused 40-day goal with daily tasks.',
                  trailing: fortyDayState.hasActiveGoal
                      ? _ProgressBadge(
                          value: fortyDayState.progress,
                          color: colorScheme.tertiary,
                        )
                      : null,
                  onTap: () {
                    if (fortyDayState.hasActiveGoal) {
                      context.push('/alignment/forty-day-progress');
                    } else {
                      context.push('/alignment/forty-day-setup');
                    }
                  },
                ),

                const SizedBox(height: 24),

                // ── LEARN & PLAY ────────────────────────────────
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
                  subtitle: 'Learn God\'s word through play.',
                  onTap: () => context.push(AppRoutes.games),
                ),

                const SizedBox(height: 12),

                _GrowHubCard(
                  icon: Icons.help_outline_rounded,
                  iconColor: colorScheme.tertiary,
                  title: 'Faith Questions',
                  subtitle: 'Bring honest questions to Scripture.',
                  onTap: () => context.push(AppRoutes.faithQuestions),
                ),

                const SizedBox(height: 24),

                // ── STUDY & REFLECT ────────────────────────────
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
                  subtitle: 'Follow guided paths through Scripture.',
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

                // ── GROW TOGETHER ────────────────────────────────
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
                  subtitle: 'Connect with someone to support your growth.',
                  onTap: () => context.push(AppRoutes.growTogether),
                ),

                const SizedBox(height: 12),

                _GrowHubCard(
                  icon: Icons.person_add_rounded,
                  iconColor: colorScheme.tertiary,
                  title: 'Invite someone',
                  subtitle: 'Share ElBiblio with someone who wants to grow.',
                  onTap: () => context.push(AppRoutes.invite),
                ),

                // Career & Calling (only show when profile exists)
                if (profile != null) ...[
                  const SizedBox(height: 12),
                  _GrowHubCard(
                    icon: LucideIcons.briefcase,
                    iconColor: colorScheme.outline,
                    title: 'Career & Calling',
                    subtitle:
                        'See how your identity shapes your professional life.',
                    onTap: () => context.push('/alignment/career'),
                  ),
                ],

                const SizedBox(height: 120),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBadge extends StatelessWidget {
  const _ProgressBadge({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${(value * 100).round()}%',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: color,
        ),
      ),
    );
  }
}

class _GrowthSummaryCard extends StatelessWidget {
  const _GrowthSummaryCard({
    required this.archetype,
    required this.streakDays,
    required this.completedActions,
    this.onTap,
  });

  final String archetype;
  final int streakDays;
  final int completedActions;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                    color: colorScheme.onPrimaryContainer.withValues(
                      alpha: 0.1,
                    ),
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
                          color: colorScheme.onPrimaryContainer.withValues(
                            alpha: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.4),
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
    this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

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
                child: Icon(icon, color: iconColor, size: 24),
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
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ] else
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
