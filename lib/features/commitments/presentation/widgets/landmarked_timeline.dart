import 'package:flutter/material.dart';

import '../../domain/models/commitment_journey.dart';

/// A vertical landmarked timeline showing the user's journey progress.
/// Displays: Start → Milestones → "You Are Here" → Remaining path → Finish
class LandmarkedTimeline extends StatelessWidget {
  const LandmarkedTimeline({
    super.key,
    required this.journey,
    required this.activeJourney,
    this.onMilestoneTap,
  });

  final CommitmentJourney journey;
  final ActiveJourney activeJourney;
  final void Function(CommitmentMilestone)? onMilestoneTap;

  @override
  Widget build(BuildContext context) {
    final currentDay = activeJourney.currentDay;
    final totalDays = journey.totalDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Start node
        _StartNode(
          day: 1,
          title: journey.title,
          isComplete: currentDay > 1 || activeJourney.completedDays.contains(1),
        ),
        
        // Path through milestones and current position
        ..._buildPathNodes(context, currentDay, totalDays),
        
        // Finish node
        _FinishNode(
          day: totalDays,
          isComplete: activeJourney.isComplete,
        ),
      ],
    );
  }

  List<Widget> _buildPathNodes(BuildContext context, int currentDay, int totalDays) {
    final nodes = <Widget>[];
    final milestones = journey.milestones.toList()..sort((a, b) => a.day.compareTo(b.day));
    
    int lastDay = 1;
    
    for (final milestone in milestones) {
      // Regular progress between last point and this milestone
      if (milestone.day > lastDay + 1) {
        nodes.add(_ProgressSegment(
          fromDay: lastDay,
          toDay: milestone.day,
          currentDay: currentDay,
        ));
      }
      
      // Milestone node
      final isReached = currentDay >= milestone.day;
      final isCurrent = currentDay == milestone.day;
      
      nodes.add(
        _MilestoneNode(
          milestone: milestone,
          isReached: isReached,
          isCurrent: isCurrent,
          onTap: () => onMilestoneTap?.call(milestone),
        ),
      );
      
      lastDay = milestone.day;
    }
    
    // Progress from last milestone to finish (or current position)
    if (lastDay < totalDays) {
      // If we're between last milestone and current day
      if (currentDay > lastDay && currentDay < totalDays) {
        // Show progress to current day
        nodes.add(_ProgressSegment(
          fromDay: lastDay,
          toDay: currentDay,
          currentDay: currentDay,
          isYouAreHere: true,
        ));
        
        // Current position marker
        nodes.add(_YouAreHereNode(
          day: currentDay,
          nextMilestone: journey.nextMilestoneAfter(currentDay),
        ));
        
        // Remaining path to finish
        if (currentDay < totalDays) {
          nodes.add(_ProgressSegment(
            fromDay: currentDay,
            toDay: totalDays,
            currentDay: currentDay,
            isRemaining: true,
          ));
        }
      } else {
        // Just show the full remaining path
        nodes.add(_ProgressSegment(
          fromDay: lastDay,
          toDay: totalDays,
          currentDay: currentDay,
          isRemaining: currentDay < lastDay,
        ));
      }
    }
    
    return nodes;
  }
}

/// Start of journey node
class _StartNode extends StatelessWidget {
  const _StartNode({
    required this.day,
    required this.title,
    required this.isComplete,
  });

  final int day;
  final String title;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isComplete 
                    ? theme.colorScheme.primary 
                    : theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
              child: Center(
                child: isComplete
                    ? Icon(Icons.check, color: theme.colorScheme.onPrimary, size: 20)
                    : const Text(
                        '🏁',
                        style: TextStyle(fontSize: 18),
                      ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BEGIN WITH GOD',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Day $day: "$title"',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isComplete) ...[
                const SizedBox(height: 2),
                Text(
                  '✓ Rooted',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }
}

/// Milestone node where commitment deepens
class _MilestoneNode extends StatelessWidget {
  const _MilestoneNode({
    required this.milestone,
    required this.isReached,
    required this.isCurrent,
    this.onTap,
  });

  final CommitmentMilestone milestone;
  final bool isReached;
  final bool isCurrent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isReached
                      ? theme.colorScheme.secondary.withValues(alpha: 0.15)
                      : theme.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isReached
                        ? theme.colorScheme.secondary
                        : theme.colorScheme.outline.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: isReached
                      ? Icon(Icons.diamond_outlined, 
                          color: theme.colorScheme.secondary, 
                          size: 18)
                      : Icon(Icons.lock_outline, 
                          color: theme.colorScheme.outline, 
                          size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isReached
                        ? theme.colorScheme.secondary.withValues(alpha: 0.1)
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '📍 MILESTONE • Day ${milestone.day}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isReached
                          ? theme.colorScheme.secondary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  milestone.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                    color: isReached
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                if (isReached) ...[
                  const SizedBox(height: 4),
                  Text(
                    '✓ Commitment deepened',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 4),
                  Text(
                    'Locked until Day ${milestone.day}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "You Are Here" marker for current position
class _YouAreHereNode extends StatelessWidget {
  const _YouAreHereNode({
    required this.day,
    this.nextMilestone,
  });

  final int day;
  final CommitmentMilestone? nextMilestone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on, color: theme.colorScheme.onPrimary, size: 14),
                Text(
                  '$day',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '🎯 YOU ARE HERE',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Today: Stay focused on your calling',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (nextMilestone != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Next deepening: Day ${nextMilestone!.day}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }
}

/// Finish/end of journey node
class _FinishNode extends StatelessWidget {
  const _FinishNode({
    required this.day,
    required this.isComplete,
  });

  final int day;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isComplete
                ? const Color(0xFFFFD700).withValues(alpha: 0.2) // Gold
                : theme.colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
            border: Border.all(
              color: isComplete
                  ? const Color(0xFFFFD700)
                  : theme.colorScheme.outline.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              isComplete ? '🏆' : '★',
              style: TextStyle(
                fontSize: isComplete ? 20 : 16,
                color: isComplete ? null : theme.colorScheme.outline,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FULL ALIGNMENT',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: isComplete
                      ? const Color(0xFFB8860B) // Dark gold
                      : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Day $day: Your calling, clearer',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isComplete ? FontWeight.w600 : FontWeight.normal,
                  color: isComplete
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              if (isComplete) ...[
                const SizedBox(height: 4),
                Text(
                  '✓ Journey complete',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFB8860B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Visual connector between nodes showing progress
class _ProgressSegment extends StatelessWidget {
  const _ProgressSegment({
    required this.fromDay,
    required this.toDay,
    required this.currentDay,
    this.isYouAreHere = false,
    this.isRemaining = false,
  });

  final int fromDay;
  final int toDay;
  final int currentDay;
  final bool isYouAreHere;
  final bool isRemaining;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = toDay - fromDay;
    
    return Padding(
      padding: const EdgeInsets.only(left: 18), // Center under the 36-40px nodes
      child: Row(
        children: [
          Container(
            width: 4,
            height: days * 8.0 + 16, // Scale height by days
            decoration: BoxDecoration(
              color: isRemaining
                  ? theme.colorScheme.outline.withValues(alpha: 0.2)
                  : theme.colorScheme.primary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 34), // 40 - 18 - 4 = 18, plus some spacing
          if (days > 1 && !isYouAreHere)
            Text(
              '$days days',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }
}
