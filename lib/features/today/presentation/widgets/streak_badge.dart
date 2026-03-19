import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/app_providers.dart';

class StreakBadge extends ConsumerWidget {
  const StreakBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final streakCount = settings.streakCount;
    final theme = Theme.of(context);

    if (streakCount == 0) {
      return const SizedBox.shrink(); // Don't show if no streak
    }

    final lastCheckIn = settings.lastCheckIn;
    if (lastCheckIn == null) {
      return const SizedBox.shrink();
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final lastDay = DateTime(lastCheckIn.year, lastCheckIn.month, lastCheckIn.day);

    // If the last check-in wasn't today or yesterday, the streak is stale.
    if (lastDay != today && lastDay != yesterday) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withValues(alpha: 0.8),
            Colors.deepOrange.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStreakIcon(streakCount),
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '$streakCount day${streakCount == 1 ? '' : 's'}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStreakIcon(int streakCount) {
    if (streakCount >= 30) {
      return Icons.local_fire_department; // Fire for long streaks
    } else if (streakCount >= 7) {
      return Icons.whatshot; // Flame for week+ streaks
    } else if (streakCount >= 3) {
      return Icons.local_florist; // Flower for 3+ day streaks
    } else {
      return Icons.flash_on; // Lightning for 1-2 day streaks
    }
  }
}
