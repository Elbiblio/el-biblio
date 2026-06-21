import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/di/app_providers.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/ambient_scope.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../widgets/alignment_hub_card.dart';

class AlignmentHubScreen extends ConsumerStatefulWidget {
  const AlignmentHubScreen({super.key});

  @override
  ConsumerState<AlignmentHubScreen> createState() => _AlignmentHubScreenState();
}

class _AlignmentHubScreenState extends ConsumerState<AlignmentHubScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(alignmentProvider.notifier).loadProfile();
      ref.read(habitProvider.notifier).loadHabits();
      ref.read(fortyDayProvider.notifier).loadGoal();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final alignmentState = ref.watch(alignmentProvider);
    final habitState = ref.watch(habitProvider);
    final fortyDayState = ref.watch(fortyDayProvider);
    final profile = alignmentState.currentProfile;

    return AmbientScope(
      asset: SoundService.ambientAssessmentAsset,
      volume: 0.06,
      child: Scaffold(
      backgroundColor: tokens.palette.background,
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: tokens.palette.background,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 14),
              title: Text(
                'Spiritual Alignment',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: tokens.palette.textPrimary,
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Section header
                Text(
                  'CLARITY ALIGNMENT',
                  style: Theme.of(context).textTheme.sectionHeader.copyWith(
                    color: tokens.palette.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Discover how your God-given identity shapes your calling',
                  style: TextStyle(
                    fontSize: 13,
                    color: tokens.palette.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),

                // 1. Spiritual Profile Card
                AlignmentHubCard(
                  icon: LucideIcons.compass,
                  iconColor: const Color(0xFF7B68EE),
                  title: profile != null
                      ? 'The ${profile.archetypeName}'
                      : 'Discover Your Archetype',
                  subtitle: profile != null
                      ? profile.description
                      : 'Take the spiritual compass to discover your gifts and growth direction.',
                  onTap: () => context.push('/alignment/profile'),
                ),
                const SizedBox(height: 12),

                // 2. Habits Section
                AlignmentHubCard(
                  icon: LucideIcons.target,
                  iconColor: const Color(0xFF5A8E67),
                  title: 'Habit Conquest',
                  subtitle: habitState.activeHabits.isEmpty
                      ? 'Build spiritual habits that anchor your clarity daily.'
                      : '${habitState.activeHabits.length} clarity habits | ${habitState.longestStreak}d best streak',
                  progress: habitState.activeHabits.isNotEmpty
                      ? habitState.consistencyPercent
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

                // 3. 40-Day Goal
                AlignmentHubCard(
                  icon: LucideIcons.flame,
                  iconColor: const Color(0xFFFF6B35),
                  title: fortyDayState.hasActiveGoal
                      ? fortyDayState.activeGoal!.title
                      : '40-Day Spiritual Goal',
                  subtitle: fortyDayState.hasActiveGoal
                      ? 'Day ${fortyDayState.currentDay} of 40 | ${fortyDayState.streakDays}d streak'
                      : 'Set a 40-day clarity goal with daily tasks and spiritual reflections.',
                  progress: fortyDayState.hasActiveGoal
                      ? fortyDayState.progress
                      : null,
                  trailing: fortyDayState.hasActiveGoal
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFFF6B35,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${(fortyDayState.progress * 100).round()}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Color(0xFFFF6B35),
                            ),
                          ),
                        )
                      : null,
                  onTap: () {
                    ref.read(soundServiceProvider).playTap();
                    if (fortyDayState.hasActiveGoal) {
                      context.push('/alignment/forty-day-progress');
                    } else {
                      context.push('/alignment/forty-day-setup');
                    }
                  },
                ),
                const SizedBox(height: 12),

                // 4. Career Alignment
                AlignmentHubCard(
                  icon: LucideIcons.briefcase,
                  iconColor: const Color(0xFFA97A46),
                  title: 'Career & Calling',
                  subtitle: profile != null
                      ? 'Your ${profile.archetypeName} identity reveals how your spiritual clarity shapes your professional calling.'
                      : 'Complete your spiritual identity profile to unlock career clarity insights.',
                  onTap: profile != null
                      ? () {
                          ref.read(soundServiceProvider).playTap();
                          context.push('/alignment/career');
                        }
                      : null,
                ),
                const SizedBox(height: 24),

                // Quick actions
                Text(
                  'QUICK ACTIONS',
                  style: Theme.of(context).textTheme.sectionHeader.copyWith(
                    color: tokens.palette.textTertiary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _QuickAction(
                      icon: LucideIcons.refreshCw,
                      label: 'Re-Assess',
                      color: const Color(0xFF7B68EE),
                      onTap: () => context.push('/assessment/compass'),
                    ),
                    const SizedBox(width: 12),
                    _QuickAction(
                      icon: LucideIcons.clipboardList,
                      label: 'Habit Quiz',
                      color: const Color(0xFF5A8E67),
                      onTap: () => context.push('/alignment/habit-assessment'),
                    ),
                    const SizedBox(width: 12),
                    _QuickAction(
                      icon: LucideIcons.bookOpen,
                      label: 'Resources',
                      color: const Color(0xFFA97A46),
                      onTap: profile != null
                          ? () => context.push('/alignment/career')
                          : null,
                    ),
                  ],
                ),

                // Bottom padding for nav bar
                const SizedBox(height: 120),
              ]),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: tokens.palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
