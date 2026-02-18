import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/meditation_notifier.dart';

/// Full-screen countdown before the meditation session begins.
class MeditationCountdownView extends ConsumerWidget {
  const MeditationCountdownView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(meditationProvider);
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated countdown number
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, animation) {
              return ScaleTransition(
                scale: animation,
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: Container(
              key: ValueKey(state.countdown),
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  width: 3,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '${state.countdown}',
                style: theme.textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.w300,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Preparing your meditation…',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Take a deep breath',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w400,
              color: theme.colorScheme.primary.withValues(alpha: 0.8),
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
