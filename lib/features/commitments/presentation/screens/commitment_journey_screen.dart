import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../application/graduated_commitment_notifier.dart';
import '../../data/commitment_catalog.dart';
import '../../domain/models/commitment_progress.dart';
import '../../domain/models/graduated_commitment.dart';
import '../widgets/commitment_roadmap.dart';
import '../widgets/tier_badge.dart';

/// Main journey view showing the 40-level roadmap, stats, and progress.
class CommitmentJourneyScreen extends ConsumerWidget {
  const CommitmentJourneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(graduatedCommitmentProvider);
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: tokens.pageGradient,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                  slivers: [
                    // App bar
                    SliverAppBar(
                      pinned: true,
                      backgroundColor: Colors.transparent,
                      surfaceTintColor: Colors.transparent,
                      title: Text(
                        'Clarity Commitments',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back_rounded),
                        onPressed: () => context.pop(),
                      ),
                    ),

                    // Stats bar
                    SliverToBoxAdapter(
                      child: _StatsBar(progress: state.progress),
                    ),

                    // Overall progress
                    SliverToBoxAdapter(
                      child: _OverallProgressCard(
                        progress: state.progress,
                        tokens: tokens,
                      ),
                    ),

                    // Active commitment banner
                    if (state.activeCommitment != null)
                      SliverToBoxAdapter(
                        child: _ActiveCommitmentBanner(
                          commitment: state.activeCommitment!,
                          state: state,
                          onTap: () =>
                              context.push(AppRoutes.commitmentActive),
                        ),
                      ),

                    // Start button (when no active commitment)
                    if (state.activeCommitment == null &&
                        !state.progress.isJourneyComplete)
                      SliverToBoxAdapter(
                        child: _StartButton(
                          progress: state.progress,
                          onStart: () {
                            ref
                                .read(graduatedCommitmentProvider.notifier)
                                .startNextCommitment();
                          },
                        ),
                      ),

                    // Roadmap
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                        child: Text(
                          'Your Clarity Path',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                        child: CommitmentRoadmap(
                          progress: state.progress,
                          onLevelTap: (level) {
                            _showLevelDetail(context, ref, level, state);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _showLevelDetail(
    BuildContext context,
    WidgetRef ref,
    int level,
    GraduatedCommitmentState state,
  ) {
    final commitment = CommitmentCatalog.getByLevel(level);
    final isCompleted = state.progress.levelCompletionMap[level] == true;
    final isCurrent = level == state.progress.currentLevel;
    final isLocked = !isCompleted && !isCurrent;
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  TierBadge(tier: commitment.tier),
                  const Spacer(),
                  if (isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle,
                              color: Colors.green, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Completed',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (isLocked)
                    Icon(
                      Icons.lock_outline_rounded,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Level ${commitment.level}: ${commitment.title}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                commitment.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              // Duration and XP
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.timer_outlined,
                    label: _formatDuration(commitment.durationMinutes),
                    theme: theme,
                  ),
                  const SizedBox(width: 10),
                  _InfoChip(
                    icon: Icons.star_outline_rounded,
                    label: '+${commitment.xpReward} XP',
                    theme: theme,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Tips
              if (commitment.tips.isNotEmpty) ...[
                Text(
                  'Tips',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                for (final tip in commitment.tips)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '\u2022  ',
                          style: TextStyle(
                            color: commitment.tier.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            tip,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              if (isCurrent && state.activeCommitment == null) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      ref
                          .read(graduatedCommitmentProvider.notifier)
                          .startNextCommitment();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: commitment.tier.color,
                    ),
                    child: Text('Start Level ${commitment.level}'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

class _StatsBar extends StatelessWidget {
  const _StatsBar({required this.progress});

  final CommitmentProgress progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            label: 'Completed',
            value: '${progress.completedCount}/40',
            icon: Icons.check_circle_outline_rounded,
            color: Colors.green,
            theme: theme,
          ),
          _StatItem(
            label: 'Streak',
            value: '${progress.currentStreak}',
            icon: Icons.local_fire_department_rounded,
            color: Colors.orange,
            theme: theme,
          ),
          _StatItem(
            label: 'XP Earned',
            value: '${progress.totalXpEarned}',
            icon: Icons.star_rounded,
            color: Colors.amber,
            theme: theme,
          ),
          _StatItem(
            label: 'Rate',
            value: progress.completedCount + progress.failedCount > 0
                ? '${((progress.completedCount / (progress.completedCount + progress.failedCount)) * 100).round()}%'
                : '--',
            icon: Icons.trending_up_rounded,
            color: Colors.blue,
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.theme,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _OverallProgressCard extends StatelessWidget {
  const _OverallProgressCard({
    required this.progress,
    required this.tokens,
  });

  final CommitmentProgress progress;
  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = (progress.overallProgress * 100).round();
    final tier = progress.currentTier;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tokens.palette.paper,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: tokens.palette.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Clarity Progress',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '$pct%',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: tier.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 10,
                child: Row(
                  children: [
                    for (final t in CommitmentTier.values)
                      Expanded(
                        child: _TierProgressSegment(
                          tier: t,
                          progress: progress,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final t in CommitmentTier.values) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: t.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    t.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 9,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  if (t != CommitmentTier.dayLong) const SizedBox(width: 8),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TierProgressSegment extends StatelessWidget {
  const _TierProgressSegment({
    required this.tier,
    required this.progress,
  });

  final CommitmentTier tier;
  final CommitmentProgress progress;

  @override
  Widget build(BuildContext context) {
    final start = (tier.value - 1) * 10 + 1;
    int completed = 0;
    for (int i = start; i < start + 10; i++) {
      if (progress.levelCompletionMap[i] == true) completed++;
    }
    final fraction = completed / 10.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: fraction,
          backgroundColor: tier.color.withValues(alpha: 0.15),
          valueColor: AlwaysStoppedAnimation<Color>(tier.color),
          minHeight: 10,
        ),
      ),
    );
  }
}

class _ActiveCommitmentBanner extends StatelessWidget {
  const _ActiveCommitmentBanner({
    required this.commitment,
    required this.state,
    required this.onTap,
  });

  final GraduatedCommitment commitment;
  final GraduatedCommitmentState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                commitment.tier.color.withValues(alpha: 0.12),
                commitment.tier.color.withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: commitment.tier.color.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: commitment.tier.color,
                ),
                child: const Center(
                  child: Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 28),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active: ${commitment.title}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${state.remainingFormatted} remaining',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: commitment.tier.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: commitment.tier.color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({required this.progress, required this.onStart});

  final CommitmentProgress progress;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final commitment = CommitmentCatalog.getByLevel(progress.currentLevel);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: onStart,
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text('Start Level ${progress.currentLevel}: ${commitment.title}'),
          style: FilledButton.styleFrom(
            backgroundColor: commitment.tier.color,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.theme,
  });

  final IconData icon;
  final String label;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
