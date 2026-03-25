import 'package:flutter/material.dart';

import '../../domain/models/commitment_progress.dart';
import '../../domain/models/graduated_commitment.dart';
import 'level_node.dart';

/// A visual roadmap showing all 40 commitment levels in a winding path.
class CommitmentRoadmap extends StatelessWidget {
  const CommitmentRoadmap({
    super.key,
    required this.progress,
    this.onLevelTap,
  });

  final CommitmentProgress progress;
  final void Function(int level)? onLevelTap;

  // ignore: unused_field
  static const double _nodeSize = 48;

  @override
  Widget build(BuildContext context) {
    const tiers = CommitmentTier.values;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final tier in tiers) ...[
          _TierHeader(tier: tier, progress: progress),
          const SizedBox(height: 8),
          _TierGrid(
            tier: tier,
            progress: progress,
            onLevelTap: onLevelTap,
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}

class _TierHeader extends StatelessWidget {
  const _TierHeader({required this.tier, required this.progress});

  final CommitmentTier tier;
  final CommitmentProgress progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = (tier.value - 1) * 10 + 1;
    final end = tier.value * 10;
    int completed = 0;
    for (int i = start; i <= end; i++) {
      if (progress.levelCompletionMap[i] == true) completed++;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: tier.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                tier.icon,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tier.label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: tier.color,
                  ),
                ),
                Text(
                  '$completed/10 completed  \u2022  ${tier.timeRange}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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

class _TierGrid extends StatelessWidget {
  const _TierGrid({
    required this.tier,
    required this.progress,
    this.onLevelTap,
  });

  final CommitmentTier tier;
  final CommitmentProgress progress;
  final void Function(int level)? onLevelTap;

  @override
  Widget build(BuildContext context) {
    final start = (tier.value - 1) * 10 + 1;
    final levels = List.generate(10, (i) => start + i);

    // Build rows of 5 with alternating direction for a winding path
    final rows = <List<int>>[];
    for (int i = 0; i < levels.length; i += 5) {
      final end = (i + 5).clamp(0, levels.length);
      final row = levels.sublist(i, end);
      // Reverse every other row for the winding effect
      if (rows.length.isOdd) {
        rows.add(row.reversed.toList());
      } else {
        rows.add(row);
      }
    }

    return Column(
      children: [
        for (int r = 0; r < rows.length; r++) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final level in rows[r])
                LevelNode(
                  level: level,
                  nodeState: _stateForLevel(level),
                  tier: tier,
                  onTap: () => onLevelTap?.call(level),
                  size: CommitmentRoadmap._nodeSize,
                ),
            ],
          ),
          if (r < rows.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }

  LevelNodeState _stateForLevel(int level) {
    if (progress.levelCompletionMap[level] == true) {
      return LevelNodeState.completed;
    }
    if (level == progress.currentLevel) {
      return LevelNodeState.current;
    }
    return LevelNodeState.locked;
  }
}
