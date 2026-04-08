import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/app_providers.dart';

class IntegrityBadge extends ConsumerWidget {
  const IntegrityBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    final score = settings.lastIntegrityScore;
    final date = settings.lastIntegrityDate;

    if (score <= 0 || date == null) {
      return const SizedBox.shrink();
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final normalizedDate = DateTime(date.year, date.month, date.day);

    if (normalizedDate != today) {
      return const SizedBox.shrink();
    }

    final gradient = _getGradient(score, theme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.verified_rounded,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '$score',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'integrity',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  LinearGradient _getGradient(int score, ThemeData theme) {
    if (score >= 12) {
      return LinearGradient(
        colors: [
          theme.colorScheme.tertiary.withValues(alpha: 0.9),
          theme.colorScheme.primary.withValues(alpha: 0.9),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    if (score >= 8) {
      return LinearGradient(
        colors: [
          Colors.amber.withValues(alpha: 0.9),
          Colors.orange.withValues(alpha: 0.9),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    return LinearGradient(
      colors: [
        Colors.blueGrey.withValues(alpha: 0.85),
        Colors.blueGrey.withValues(alpha: 0.65),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}
