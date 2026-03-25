import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/app_providers.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../application/graduated_commitment_notifier.dart';
import '../../data/commitment_catalog.dart';
import '../../domain/models/commitment_progress.dart';
import '../../domain/models/graduated_commitment.dart';
import 'tier_badge.dart';

/// A summary card for the Today screen showing the active commitment or next
/// available level.
class CommitmentSummaryCard extends ConsumerWidget {
  const CommitmentSummaryCard({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(graduatedCommitmentProvider);
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    if (state.isLoading) {
      return _CardShell(
        tokens: tokens,
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (state.activeCommitment != null) {
      return _ActiveCard(
        commitment: state.activeCommitment!,
        state: state,
        tokens: tokens,
        onTap: onTap,
      );
    }

    return _NextLevelCard(
      progress: state.progress,
      tokens: tokens,
      onTap: onTap,
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.tokens, required this.child});

  final AppThemeTokens tokens;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: tokens.palette.paper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.palette.border),
      ),
      child: child,
    );
  }
}

class _ActiveCard extends StatelessWidget {
  const _ActiveCard({
    required this.commitment,
    required this.state,
    required this.tokens,
    required this.onTap,
  });

  final GraduatedCommitment commitment;
  final GraduatedCommitmentState state;
  final AppThemeTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              commitment.tier.color.withValues(alpha: 0.08),
              commitment.tier.color.withValues(alpha: 0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: commitment.tier.color.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                TierBadge(
                  tier: commitment.tier,
                  size: TierBadgeSize.small,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: commitment.tier.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    state.remainingFormatted,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: commitment.tier.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Level ${commitment.level}: ${commitment.title}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              commitment.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 12),
            // Mini progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: state.timerProgress,
                backgroundColor: commitment.tier.color.withValues(alpha: 0.1),
                valueColor:
                    AlwaysStoppedAnimation<Color>(commitment.tier.color),
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextLevelCard extends StatelessWidget {
  const _NextLevelCard({
    required this.progress,
    required this.tokens,
    required this.onTap,
  });

  final CommitmentProgress progress;
  final AppThemeTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nextCommitment = CommitmentCatalog.getByLevel(progress.currentLevel);
    final tier = nextCommitment.tier;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tokens.palette.paper,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: tokens.palette.border),
        ),
        child: Row(
          children: [
            // Level circle
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [tier.color, tier.color.withValues(alpha: 0.7)],
                ),
              ),
              child: Center(
                child: Text(
                  '${progress.currentLevel}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next: ${nextCommitment.title}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${tier.timeRange}  \u2022  +${nextCommitment.xpReward} XP',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}
