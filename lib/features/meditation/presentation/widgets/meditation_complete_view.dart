import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/services/analytics/app_analytics_service.dart';
import '../../application/meditation_notifier.dart';
import 'god_spoke_prompt.dart';

/// Shown after a meditation session completes.
class MeditationCompleteView extends ConsumerWidget {
  const MeditationCompleteView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(meditationProvider);
    final notifier = ref.read(meditationProvider.notifier);
    final theme = Theme.of(context);
    final guide = state.guide;

    // Track meditation completion
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsProvider).track(AppAnalyticsEvent.meditationCompleted);
    });

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Success badge ─────────────────────────────────────────
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.tertiary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.check_rounded, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              'Meditation Complete',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Take a moment to thank God for your experience.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),

            // ── Closing reminder / invitation ─────────────────────────
            if (guide != null && (guide.closingReminder?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      "Today's Invitation",
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      guide.closingReminder!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // ── Action buttons ────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  notifier.resetToSetup();
                  context.go(AppRoutes.home);
                },
                icon: const Icon(Icons.home_outlined, size: 20),
                label: const Text('Finish'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  notifier.resetToSetup();
                  // Stay on meditation screen for another session
                },
                icon: const Icon(Icons.replay_rounded, size: 20),
                label: const Text('Meditate Again'),
              ),
            ),
            const SizedBox(height: 24),

            // ── "God Spoke to Me" prompt ────────────────────────────
            const GodSpokePrompt(),
          ],
        ),
      ),
    );
  }
}
