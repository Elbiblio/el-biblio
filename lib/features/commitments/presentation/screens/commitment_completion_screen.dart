import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../data/commitment_catalog.dart';
import '../widgets/tier_badge.dart';

/// Celebration screen shown after completing a commitment.
class CommitmentCompletionScreen extends ConsumerStatefulWidget {
  const CommitmentCompletionScreen({super.key});

  @override
  ConsumerState<CommitmentCompletionScreen> createState() =>
      _CommitmentCompletionScreenState();
}

class _CommitmentCompletionScreenState
    extends ConsumerState<CommitmentCompletionScreen>
    with TickerProviderStateMixin {
  late final AnimationController _celebrateController;
  late final AnimationController _contentController;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scaleUp;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _celebrateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeIn = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOut,
    );
    _scaleUp = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.elasticOut),
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOutCubic,
    ));

    _celebrateController.forward();
    _contentController.forward();
  }

  @override
  void dispose() {
    _celebrateController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(graduatedCommitmentProvider);
    final progress = state.progress;
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    // The commitment that was just completed is one level below current
    final completedLevel =
        progress.currentLevel > 1 ? progress.currentLevel - 1 : 1;
    final completedCommitment = CommitmentCatalog.getByLevel(completedLevel);

    // Next commitment preview
    final hasNext = progress.currentLevel <= 40;
    final nextCommitment = hasNext
        ? CommitmentCatalog.getByLevel(progress.currentLevel)
        : null;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              completedCommitment.tier.color.withValues(alpha: 0.12),
              tokens.pageGradient.last,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Confetti / celebration particles
              _ConfettiOverlay(
                controller: _celebrateController,
                color: completedCommitment.tier.color,
              ),

              // Main content
              FadeTransition(
                opacity: _fadeIn,
                child: SlideTransition(
                  position: _slideUp,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),

                        // Celebration icon
                        ScaleTransition(
                          scale: _scaleUp,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  completedCommitment.tier.color,
                                  completedCommitment.tier.color
                                      .withValues(alpha: 0.7),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: completedCommitment.tier.color
                                      .withValues(alpha: 0.4),
                                  blurRadius: 24,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.celebration_rounded,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        Text(
                          'Well Done!',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: completedCommitment.tier.color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Level ${completedCommitment.level} Complete',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Encouragement message
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: tokens.palette.paper,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: tokens.palette.border),
                          ),
                          child: Text(
                            completedCommitment.encouragement,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              height: 1.6,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // XP earned
                        _XPDisplay(
                          xp: completedCommitment.xpReward,
                          color: completedCommitment.tier.color,
                        ),

                        const SizedBox(height: 16),

                        // Stats row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _CompletionStat(
                              label: 'Streak',
                              value: '${progress.currentStreak}',
                              icon: Icons.local_fire_department_rounded,
                              color: Colors.orange,
                              theme: theme,
                            ),
                            _CompletionStat(
                              label: 'Completed',
                              value: '${progress.completedCount}/40',
                              icon: Icons.check_circle_outline_rounded,
                              color: Colors.green,
                              theme: theme,
                            ),
                            _CompletionStat(
                              label: 'Total XP',
                              value: '${progress.totalXpEarned}',
                              icon: Icons.star_rounded,
                              color: Colors.amber,
                              theme: theme,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Next level preview
                        if (nextCommitment != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: tokens.palette.paper,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: tokens.palette.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Up Next',
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                    const Spacer(),
                                    TierBadge(
                                      tier: nextCommitment.tier,
                                      size: TierBadgeSize.small,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Level ${nextCommitment.level}: ${nextCommitment.title}',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_formatDuration(nextCommitment.durationMinutes)}  \u2022  +${nextCommitment.xpReward} XP',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Buttons
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () {
                              ref
                                  .read(graduatedCommitmentProvider.notifier)
                                  .acknowledgeCompletion();
                              context.go(AppRoutes.commitmentJourney);
                            },
                            child: const Text('View Journey'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              ref
                                  .read(graduatedCommitmentProvider.notifier)
                                  .acknowledgeCompletion();
                              context.go(AppRoutes.home);
                            },
                            child: const Text('Back to Home'),
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _XPDisplay extends StatelessWidget {
  const _XPDisplay({required this.xp, required this.color});

  final int xp;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: xp),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOut,
      builder: (context, value, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.15),
                color.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, color: color, size: 28),
              const SizedBox(width: 10),
              Text(
                '+$value XP',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CompletionStat extends StatelessWidget {
  const _CompletionStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.theme,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

/// Simple confetti-like particle overlay.
class _ConfettiOverlay extends StatelessWidget {
  const _ConfettiOverlay({
    required this.controller,
    required this.color,
  });

  final AnimationController controller;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _ConfettiPainter(
            progress: controller.value,
            baseColor: color,
          ),
        );
      },
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.progress, required this.baseColor});

  final double progress;
  final Color baseColor;

  static final _random = math.Random(42);
  static final List<_Particle> _particles = List.generate(30, (i) {
    return _Particle(
      x: _random.nextDouble(),
      startY: -0.1 - _random.nextDouble() * 0.3,
      speed: 0.4 + _random.nextDouble() * 0.6,
      size: 4 + _random.nextDouble() * 6,
      rotation: _random.nextDouble() * math.pi * 2,
      colorIndex: _random.nextInt(5),
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final colors = [
      baseColor,
      baseColor.withValues(alpha: 0.7),
      Colors.amber,
      Colors.white,
      baseColor.withValues(alpha: 0.5),
    ];

    for (final p in _particles) {
      final y = p.startY + progress * p.speed;
      if (y > 1.1) continue;

      final opacity = (1.0 - (progress * 0.5)).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = colors[p.colorIndex].withValues(alpha: opacity);

      final px = p.x * size.width;
      final py = y * size.height;

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(p.rotation + progress * 4);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

class _Particle {
  final double x;
  final double startY;
  final double speed;
  final double size;
  final double rotation;
  final int colorIndex;

  const _Particle({
    required this.x,
    required this.startY,
    required this.speed,
    required this.size,
    required this.rotation,
    required this.colorIndex,
  });
}
