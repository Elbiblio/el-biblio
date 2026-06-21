import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../shared/widgets/ambient_scope.dart';
import '../../domain/models/graduated_commitment.dart';
import '../widgets/commitment_timer.dart';
import '../widgets/tier_badge.dart';

/// Motivational verses shown during active commitments.
const _motivationalVerses = [
  '"I can do all things through Christ who strengthens me." \u2014 Philippians 4:13',
  '"Be still and know that I am God." \u2014 Psalm 46:10',
  '"The Lord is my strength and my shield." \u2014 Psalm 28:7',
  '"Cast all your anxiety on Him because He cares for you." \u2014 1 Peter 5:7',
  '"God is within her, she will not fall." \u2014 Psalm 46:5',
  '"Trust in the Lord with all your heart." \u2014 Proverbs 3:5',
  '"His mercies are new every morning." \u2014 Lamentations 3:23',
  '"The joy of the Lord is my strength." \u2014 Nehemiah 8:10',
  '"He makes all things work together for good." \u2014 Romans 8:28',
  '"Do not be afraid; I am with you." \u2014 Isaiah 41:10',
];

/// Active commitment screen with countdown timer and actions.
class CommitmentActiveScreen extends ConsumerStatefulWidget {
  const CommitmentActiveScreen({super.key});

  @override
  ConsumerState<CommitmentActiveScreen> createState() =>
      _CommitmentActiveScreenState();
}

class _CommitmentActiveScreenState
    extends ConsumerState<CommitmentActiveScreen> {
  bool _tipsExpanded = false;
  int _verseIndex = 0;

  @override
  void initState() {
    super.initState();
    _verseIndex = math.Random().nextInt(_motivationalVerses.length);
  }

  void _cycleVerse() {
    setState(() {
      _verseIndex = (_verseIndex + 1) % _motivationalVerses.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(graduatedCommitmentProvider);
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    // If commitment just completed, redirect to completion screen
    if (state.justCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.pushReplacement(AppRoutes.commitmentCompletion);
      });
    }

    final commitment = state.activeCommitment;
    if (commitment == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'No active commitment',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return AmbientScope(
      asset: SoundService.ambientCommitmentAsset,
      volume: 0.07,
      child: Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              commitment.tier.color.withValues(alpha: 0.08),
              tokens.pageGradient.last,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => context.pop(),
                    ),
                    const Spacer(),
                    TierBadge(tier: commitment.tier),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      // Title
                      Text(
                        'Level ${commitment.level}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: commitment.tier.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        commitment.title,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        commitment.description,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.65),
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Timer
                      CommitmentTimer(
                        progress: state.timerProgress,
                        remainingText: state.remainingFormatted,
                        elapsedText: state.elapsedFormatted,
                        color: commitment.tier.color,
                      ),

                      const SizedBox(height: 28),

                      // Motivational verse
                      GestureDetector(
                        onTap: () {
                          ref.read(soundServiceProvider).playPaperRustle();
                          _cycleVerse();
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: commitment.tier.color.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  commitment.tier.color.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                _motivationalVerses[_verseIndex],
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  height: 1.5,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Tap for another verse',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: commitment.tier.color
                                      .withValues(alpha: 0.5),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Tips section
                      if (commitment.tips.isNotEmpty)
                        _TipsSection(
                          tips: commitment.tips,
                          expanded: _tipsExpanded,
                          color: commitment.tier.color,
                          onToggle: () => setState(
                              () => _tipsExpanded = !_tipsExpanded),
                        ),

                      const SizedBox(height: 32),

                      // Action buttons
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: state.canComplete
                              ? () {
                                  ref.read(soundServiceProvider).playChimeGentle();
                                  ref
                                      .read(
                                          graduatedCommitmentProvider.notifier)
                                      .completeCommitment();
                                }
                              : null,
                          icon: const Icon(Icons.check_circle_outline_rounded),
                          label: Text(
                            state.canComplete
                                ? 'I completed this!'
                                : 'Complete (available at 80%)',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: commitment.tier.color,
                            disabledBackgroundColor:
                                commitment.tier.color.withValues(alpha: 0.3),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _showFailDialog(context, ref, commitment),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('I need to restart'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.error,
                            side: BorderSide(
                              color: theme.colorScheme.error.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  void _showFailDialog(
    BuildContext context,
    WidgetRef ref,
    GraduatedCommitment commitment,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Need to restart?'),
        content: Text(
          commitment.failureGrace,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep Going'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(graduatedCommitmentProvider.notifier).failCommitment();
              context.pop();
            },
            child: Text(
              'Restart',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipsSection extends StatelessWidget {
  const _TipsSection({
    required this.tips,
    required this.expanded,
    required this.color,
    required this.onToggle,
  });

  final List<String> tips;
  final bool expanded;
  final Color color;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline_rounded,
                    color: color, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Tips',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.expand_more_rounded,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
            if (expanded) ...[
              const SizedBox(height: 12),
              for (final tip in tips)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '\u2022  ',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          tip,
                          style: theme.textTheme.bodySmall?.copyWith(
                            height: 1.4,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.65),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
