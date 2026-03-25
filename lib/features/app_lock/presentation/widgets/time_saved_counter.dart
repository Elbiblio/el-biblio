import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_tokens.dart';

class TimeSavedCounter extends StatelessWidget {
  const TimeSavedCounter({
    super.key,
    required this.minutesSaved,
    this.streakDays = 0,
  });

  final int minutesSaved;
  final int streakDays;

  String _formatTime(int minutes) {
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
    }
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tokens.palette.success.withValues(alpha: 0.12),
            tokens.palette.primary.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(
          color: tokens.palette.success.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.trending_up_rounded,
            color: tokens.palette.success,
            size: 28,
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: minutesSaved),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return Text(
                _formatTime(value),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: tokens.palette.success,
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            'time reclaimed today',
            style: theme.textTheme.bodySmall?.copyWith(
              color: tokens.palette.textSecondary,
            ),
          ),
          if (streakDays > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: tokens.palette.success.withValues(alpha: 0.15),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_fire_department_rounded,
                    size: 16,
                    color: tokens.palette.success,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$streakDays day streak',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: tokens.palette.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
