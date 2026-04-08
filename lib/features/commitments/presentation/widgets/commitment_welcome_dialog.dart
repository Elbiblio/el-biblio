import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';

/// One-time welcome dialog explaining the 40-day commitment journey.
///
/// Shown the first time a user taps "Begin Your Commitment" on the home
/// screen. After dismissal via "Begin My Journey", the flag
/// `hasSeenCommitmentWelcome` is persisted so it never appears again.
class CommitmentWelcomeDialog extends ConsumerWidget {
  const CommitmentWelcomeDialog({super.key});

  /// Convenience method matching the pattern used by other dialogs in the app.
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const CommitmentWelcomeDialog(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    const accentColor = Color(0xFF7B68EE); // soft purple, spiritual tone

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              accentColor.withValues(alpha: 0.08),
              theme.cardColor,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    accentColor.withValues(alpha: 0.25),
                    accentColor.withValues(alpha: 0.10),
                  ],
                ),
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: accentColor,
                size: 32,
              ),
            ),

            const SizedBox(height: 20),

            // Title
            Text(
              'Your 40-Day Clarity Journey',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),

            const SizedBox(height: 14),

            // Subtitle
            Text(
              'Spiritual growth is a daily practice, not a sprint.\n'
              'Each day, commit to one small action aligned with '
              'your spiritual identity.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.55,
              ),
            ),

            const SizedBox(height: 20),

            // Feature bullets
            const _BulletRow(
              icon: Icons.looks_one_rounded,
              color: Color(0xFF4CAF50),
              text: 'Just ONE commitment per day',
            ),
            const SizedBox(height: 10),
            const _BulletRow(
              icon: Icons.trending_up_rounded,
              color: Color(0xFF2196F3),
              text: 'Start small, build momentum',
            ),
            const SizedBox(height: 10),
            const _BulletRow(
              icon: Icons.route_rounded,
              color: Color(0xFFFF9800),
              text: 'Growth, Discipline, or Charity tracks',
            ),
            const SizedBox(height: 10),
            const _BulletRow(
              icon: Icons.calendar_month_rounded,
              color: Color(0xFF9C27B0),
              text: 'Track your progress over 40 days',
            ),

            const SizedBox(height: 20),

            // Grace note
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.15),
                ),
              ),
              child: Text(
                "You're not alone in this. God's grace makes the difference.",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: accentColor,
                  height: 1.4,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Primary CTA
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  await ref
                      .read(settingsProvider.notifier)
                      .markCommitmentWelcomeSeen();
                  if (context.mounted) {
                    Navigator.of(context).pop(true);
                    context.push(AppRoutes.commitmentJourney);
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: accentColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Begin My Journey',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Secondary dismiss
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Not Now',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BulletRow extends StatelessWidget {
  const _BulletRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
