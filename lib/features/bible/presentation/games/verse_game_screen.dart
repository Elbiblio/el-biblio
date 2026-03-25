import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../application/verse_game_notifier.dart';
import '../../../../core/di/app_providers.dart';

class FontSizeCalculator {
  static double calculateOptimalFontSize({
    required int wordCount,
    required double maxWidth,
    required double maxHeight,
    required TextStyle baseStyle,
    double minFontSize = 12.0,
    double maxFontSize = 28.0,
  }) {
    double fontSize = baseStyle.fontSize ?? 16.0;

    if (wordCount > 15) {
      fontSize = max(minFontSize, fontSize - 4);
    } else if (wordCount > 12) {
      fontSize = max(minFontSize, fontSize - 2);
    } else if (wordCount > 8) {
      fontSize = max(minFontSize, fontSize - 1);
    } else if (wordCount < 5) {
      fontSize = min(maxFontSize, fontSize + 2);
    }

    final averageWordLength = maxWidth / wordCount;
    if (averageWordLength > 80) {
      fontSize = max(minFontSize, fontSize - 2);
    }

    return fontSize.clamp(minFontSize, maxFontSize);
  }

  static double calculateContextFontSize({
    required List<String> words,
    required double availableWidth,
    required TextStyle baseStyle,
    double minFontSize = 14.0,
    double maxFontSize = 26.0,
  }) {
    final totalWords = words.length;

    if (totalWords == 0) {
      return baseStyle.fontSize?.clamp(minFontSize, maxFontSize) ?? minFontSize;
    }

    final longestWord = words.reduce((a, b) => a.length > b.length ? a : b).length;

    double fontSize = baseStyle.fontSize ?? 20.0;

    if (totalWords > 20) {
      fontSize = max(minFontSize, fontSize - 6);
    } else if (totalWords > 15) {
      fontSize = max(minFontSize, fontSize - 4);
    } else if (totalWords > 10) {
      fontSize = max(minFontSize, fontSize - 2);
    } else if (totalWords < 6) {
      fontSize = min(maxFontSize, fontSize + 2);
    }

    if (longestWord > 12) {
      fontSize = max(minFontSize, fontSize - 2);
    } else if (longestWord > 8) {
      fontSize = max(minFontSize, fontSize - 1);
    }

    return fontSize.clamp(minFontSize, maxFontSize);
  }
}

// ── Particle Effect Overlay ──────────────────────────────────────────
class _ParticleOverlay extends StatefulWidget {
  final bool show;
  final bool isSuccess;
  const _ParticleOverlay({required this.show, required this.isSuccess});

  @override
  State<_ParticleOverlay> createState() => _ParticleOverlayState();
}

class _ParticleOverlayState extends State<_ParticleOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final List<_Particle> _particles = [];
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant _ParticleOverlay old) {
    super.didUpdateWidget(old);
    if (widget.show && !old.show) {
      _spawnParticles();
      _ctrl.forward(from: 0);
    }
  }

  void _spawnParticles() {
    _particles.clear();
    final colors = widget.isSuccess
        ? [Colors.green, Colors.greenAccent, Colors.lightGreen, Colors.amber]
        : [Colors.red, Colors.redAccent, Colors.orange];
    for (int i = 0; i < 24; i++) {
      _particles.add(_Particle(
        x: _rng.nextDouble(),
        y: 0.4 + _rng.nextDouble() * 0.2,
        vx: (_rng.nextDouble() - 0.5) * 2,
        vy: -_rng.nextDouble() * 2 - 0.5,
        color: colors[_rng.nextInt(colors.length)],
        size: _rng.nextDouble() * 6 + 3,
      ));
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show || !_ctrl.isAnimating) return const SizedBox.shrink();
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _ParticlePainter(_particles, _ctrl.value),
      ),
    );
  }
}

class _Particle {
  double x, y, vx, vy, size;
  Color color;
  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double t;
  _ParticlePainter(this.particles, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final px = (p.x + p.vx * t) * size.width;
      final py = (p.y + p.vy * t + 0.5 * t * t) * size.height;
      final opacity = (1 - t).clamp(0.0, 1.0);
      final paint = Paint()..color = p.color.withValues(alpha: opacity);
      canvas.drawCircle(Offset(px, py), p.size * (1 - t * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => true;
}

// ── Screen Shake Widget ──────────────────────────────────────────────
class _ShakeWidget extends StatefulWidget {
  final Widget child;
  final bool shake;
  const _ShakeWidget({required this.child, required this.shake});

  @override
  State<_ShakeWidget> createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<_ShakeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: -8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8, end: 6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(covariant _ShakeWidget old) {
    super.didUpdateWidget(old);
    if (widget.shake && !old.shake) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_animation.value, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ── Tutorial / Onboarding Overlay ────────────────────────────────────
class _TutorialOverlay extends StatefulWidget {
  final VoidCallback onComplete;
  const _TutorialOverlay({required this.onComplete});

  @override
  State<_TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<_TutorialOverlay> {
  int _step = 0;
  static const _steps = [
    _TutorialStep(
      title: 'Welcome to Verse Scramble!',
      description:
          'Test your Bible knowledge by rearranging scrambled verses or guessing missing words.',
      icon: Icons.auto_stories,
    ),
    _TutorialStep(
      title: 'Two Game Modes',
      description:
          'ARRANGE mode: tap words in the correct order to rebuild the verse.\n'
          'GUESS mode: identify the missing word from the options.',
      icon: Icons.swap_horiz,
    ),
    _TutorialStep(
      title: 'Combos & Bonuses',
      description:
          'Answer correctly in a row to build combos and earn multiplied points! '
          'Every 5th question is a bonus round worth 2x.',
      icon: Icons.whatshot,
    ),
    _TutorialStep(
      title: 'Hints & Lives',
      description:
          'Use hints to reveal the next correct word. You have 3 lives -- '
          'wrong answers and timeouts cost a life. Good luck!',
      icon: Icons.favorite,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final step = _steps[_step];
    return Material(
      color: Colors.black54,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(step.icon, size: 64, color: Colors.white),
                const SizedBox(height: 24),
                Text(
                  step.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  step.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                // Progress dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _steps.length,
                    (i) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _step ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _step
                            ? Colors.white
                            : Colors.white30,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () {
                    if (_step < _steps.length - 1) {
                      setState(() => _step++);
                    } else {
                      widget.onComplete();
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF5e7153),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    _step < _steps.length - 1 ? 'Next' : "Let's Go!",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_step > 0) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: widget.onComplete,
                    child: const Text(
                      'Skip Tutorial',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TutorialStep {
  final String title;
  final String description;
  final IconData icon;
  const _TutorialStep({
    required this.title,
    required this.description,
    required this.icon,
  });
}

// ── Combo Indicator Widget ───────────────────────────────────────────
class _ComboIndicator extends StatelessWidget {
  final int streak;
  final int multiplier;
  const _ComboIndicator({required this.streak, required this.multiplier});

  @override
  Widget build(BuildContext context) {
    if (streak < 2) return const SizedBox.shrink();
    final color = streak >= 5
        ? Colors.deepOrange
        : streak >= 3
            ? Colors.orange
            : Colors.amber;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.elasticOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.7)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_fire_department,
                color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(
              '${multiplier}x COMBO',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '($streak)',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// MAIN SCREEN
// ══════════════════════════════════════════════════════════════════════

class VerseGameScreen extends ConsumerStatefulWidget {
  const VerseGameScreen({super.key});

  @override
  ConsumerState<VerseGameScreen> createState() => _VerseGameScreenState();
}

class _VerseGameScreenState extends ConsumerState<VerseGameScreen>
    with TickerProviderStateMixin {
  final Random _random = Random();
  late List<double> _rotations;
  late List<Offset> _translations;

  bool _showTutorial = false;
  bool _showParticles = false;
  bool _isParticleSuccess = true;
  bool _triggerShake = false;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _generateRandomTransformations();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    _checkFirstTimeTutorial();
  }

  Future<void> _checkFirstTimeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('verse_game_tutorial_seen') ?? false;
    if (!seen && mounted) {
      setState(() => _showTutorial = true);
    }
  }

  Future<void> _completeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('verse_game_tutorial_seen', true);
    if (mounted) {
      setState(() => _showTutorial = false);
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _generateRandomTransformations() {
    _rotations = List.generate(
        50, (index) => (_random.nextDouble() * 10 - 5) * pi / 180);
    _translations = List.generate(
        50,
        (index) => Offset(_random.nextDouble() * 20 - 10,
            _random.nextDouble() * 20 - 10));
  }

  Color _getDifficultyColor(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.beginner:
        return Colors.green;
      case DifficultyLevel.easy:
        return Colors.blue;
      case DifficultyLevel.medium:
        return Colors.orange;
      case DifficultyLevel.hard:
        return Colors.red;
      case DifficultyLevel.expert:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(verseGameProvider);
    final notifier = ref.read(verseGameProvider.notifier);

    // Edge-detect state changes for visual effects
    ref.listen(verseGameProvider.select((s) => s.state), (prev, next) {
      if (next == GameState.success && prev != GameState.success) {
        ref.read(soundServiceProvider).playGameSuccess();
        HapticFeedback.heavyImpact();
        setState(() {
          _showParticles = true;
          _isParticleSuccess = true;
        });
        Future.delayed(const Duration(milliseconds: 900), () {
          if (mounted) setState(() => _showParticles = false);
        });
        if (gameState.streak >= 3) {
          _confettiController.play();
        }
      } else if (next == GameState.sessionComplete &&
          prev != GameState.sessionComplete) {
        ref.read(soundServiceProvider).playGameSuccess();
        HapticFeedback.heavyImpact();
        _confettiController.play();
      } else if (next == GameState.failed && prev != GameState.failed) {
        ref.read(soundServiceProvider).playGameFail();
        HapticFeedback.heavyImpact();
        setState(() {
          _triggerShake = true;
          _showParticles = true;
          _isParticleSuccess = false;
        });
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) setState(() => _triggerShake = false);
        });
        Future.delayed(const Duration(milliseconds: 900), () {
          if (mounted) setState(() => _showParticles = false);
        });
      }
    });

    const primaryColor = Color(0xFF5e7153);
    const parchmentColor = Color(0xFFf4f1ea);
    const parchmentDarkColor = Color(0xFFe8e4d9);
    const textMainColor = Color(0xFF2c2e30);
    const textMutedColor = Color(0xFF7c838a);

    final mediaSize = MediaQuery.sizeOf(context);
    final isLandscape = mediaSize.width > mediaSize.height;
    final isCompactHeight = mediaSize.height < 620;
    final shouldScrollWords = isLandscape || isCompactHeight;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1a1c1e) : parchmentColor;
    final textColor = isDark ? Colors.white : textMainColor;
    final mutedTextColor = isDark ? textMutedColor : textMutedColor;
    final borderColor =
        isDark ? const Color(0xFF334155) : parchmentDarkColor;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          SafeArea(
            child: gameState.state == GameState.loading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: primaryColor))
                : gameState.state == GameState.gameOver ||
                        gameState.state == GameState.sessionComplete
                    ? _buildEndScreen(context, gameState, notifier,
                        primaryColor, textColor)
                    : _ShakeWidget(
                        shake: _triggerShake,
                        child: Column(
                          children: [
                            // Header with difficulty indicators
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 16),
                              child: Column(
                                children: [
                                  // Top row
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.close,
                                            color: mutedTextColor),
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (gameState.difficulty !=
                                              null) ...[
                                            Container(
                                              padding: const EdgeInsets
                                                  .symmetric(
                                                  horizontal: 8,
                                                  vertical: 2),
                                              decoration: BoxDecoration(
                                                color:
                                                    _getDifficultyColor(
                                                        gameState
                                                            .difficulty!
                                                            .category),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        12),
                                              ),
                                              child: Text(
                                                gameState
                                                    .difficulty!
                                                    .category
                                                    .name
                                                    .toUpperCase(),
                                                style: const TextStyle(
                                                  fontSize: 8,
                                                  fontWeight:
                                                      FontWeight.w900,
                                                  color: Colors.white,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                          ],
                                          const Text(
                                            'Q',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900,
                                              color: primaryColor,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                          Text(
                                            '${gameState.currentQuestionIndex}/${gameState.totalQuestions}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: textColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        children: [
                                          Row(
                                            children:
                                                List.generate(3, (i) {
                                              return Icon(
                                                i < gameState.lives
                                                    ? Icons.favorite
                                                    : Icons
                                                        .favorite_border,
                                                color:
                                                    i < gameState.lives
                                                        ? Colors.red
                                                        : mutedTextColor,
                                                size: 16,
                                              );
                                            }),
                                          ),
                                          const SizedBox(height: 4),
                                          if (gameState.hintsRemaining >
                                              0)
                                            Row(
                                              children: [
                                                const Icon(
                                                    Icons
                                                        .lightbulb_outline,
                                                    color: Colors.amber,
                                                    size: 14),
                                                const SizedBox(width: 2),
                                                Text(
                                                  '${gameState.hintsRemaining}',
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    color: Colors.amber,
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  // Bonus round indicator
                                  if (gameState.isBonusRound) ...[
                                    SizedBox(
                                        height:
                                            isLandscape ? 4 : 8),
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.amber
                                            .withValues(alpha: 0.2),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        border: Border.all(
                                            color: Colors.amber,
                                            width: 1),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.star,
                                              color: Colors.amber,
                                              size: 16),
                                          SizedBox(width: 4),
                                          Text(
                                            'BONUS ROUND - 2X POINTS',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight:
                                                  FontWeight.w900,
                                              color: Colors.amber,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  // Combo indicator (improved)
                                  if (gameState.streak >= 2) ...[
                                    const SizedBox(height: 6),
                                    _ComboIndicator(
                                      streak: gameState.streak,
                                      multiplier:
                                          gameState.comboMultiplier,
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Title & Timer
                            const SizedBox(height: 8),
                            Text(
                              gameState.verse?.reference ?? '',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color:
                                    textColor.withValues(alpha: 0.6),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Timer with color shift when low
                            Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                TweenAnimationBuilder<double>(
                                  tween: Tween(
                                    begin: 1.0,
                                    end: gameState.timeLeft <= 5
                                        ? 1.08
                                        : 1.0,
                                  ),
                                  duration: const Duration(
                                      milliseconds: 300),
                                  builder: (ctx, scale, child) =>
                                      Transform.scale(
                                    scale: scale,
                                    child: child,
                                  ),
                                  child: Text(
                                    gameState.timeLeft
                                        .toString()
                                        .padLeft(2, '0'),
                                    style: TextStyle(
                                      fontSize:
                                          isLandscape ? 60 : 72,
                                      fontWeight: FontWeight.w900,
                                      color: gameState.timeLeft <= 5
                                          ? Colors.red
                                          : primaryColor,
                                      height: 1.0,
                                      letterSpacing: -5,
                                      shadows: [
                                        Shadow(
                                          color: (gameState.timeLeft <=
                                                      5
                                                  ? Colors.red
                                                  : primaryColor)
                                              .withValues(
                                                  alpha: 0.2),
                                          blurRadius: 20,
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: -30,
                                  top: 12,
                                  child: Icon(
                                    Icons.timer_outlined,
                                    color: primaryColor
                                        .withValues(alpha: 0.3),
                                    size: isLandscape ? 26 : 30,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: isLandscape ? 2 : 4),
                            Text(
                              gameState.currentMode ==
                                      GameMode.arrange
                                  ? 'ARRANGE THE VERSE'
                                  : 'GUESS THE WORD',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: mutedTextColor,
                                letterSpacing: 2,
                              ),
                            ),

                            SizedBox(height: isLandscape ? 8 : 12),

                            if (gameState.currentMode ==
                                GameMode.guess)
                              _buildGuessContext(
                                  gameState, textColor, primaryColor)
                            else if (gameState.currentMode ==
                                GameMode.arrange)
                              _buildArrangeContext(gameState, textColor,
                                  primaryColor, mutedTextColor),

                            // Word Cloud / Options
                            Expanded(
                              child: _buildWordOptions(
                                gameState: gameState,
                                ref: ref,
                                notifier: notifier,
                                isDark: isDark,
                                borderColor: borderColor,
                                primaryColor: primaryColor,
                                textColor: textColor,
                                shouldScroll: shouldScrollWords,
                              ),
                            ),

                            // Footer
                            if (gameState.state ==
                                    GameState.success ||
                                gameState.state ==
                                    GameState.checking)
                              Container(
                                padding: const EdgeInsets.all(16),
                                margin: const EdgeInsets.only(
                                    bottom: 24, left: 16, right: 16),
                                decoration: BoxDecoration(
                                  color: gameState.state ==
                                          GameState.success
                                      ? Colors.green
                                          .withValues(alpha: 0.1)
                                      : Colors.blue
                                          .withValues(alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(16),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      gameState.state ==
                                              GameState.success
                                          ? (gameState.streak >= 3
                                              ? '${gameState.streak}x Streak! Amazing!'
                                              : 'Great job! Loading next question...')
                                          : 'Checking...',
                                      style: TextStyle(
                                        color: gameState.state ==
                                                GameState.success
                                            ? Colors.green
                                            : Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (gameState.state ==
                                            GameState.success &&
                                        gameState.currentMode ==
                                            GameMode.arrange) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        gameState.originalWords
                                            .join(' '),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        gameState.verse?.reference ??
                                            '',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ]
                                  ],
                                ),
                              )
                            else if (gameState.state ==
                                GameState.failed)
                              Container(
                                padding: const EdgeInsets.all(16),
                                margin: const EdgeInsets.only(
                                    bottom: 24, left: 16, right: 16),
                                decoration: BoxDecoration(
                                  color: Colors.red
                                      .withValues(alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(16),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      gameState.currentMode ==
                                              GameMode.arrange
                                          ? 'Oops! Not quite right.'
                                          : 'Oops! It was "${gameState.missingWord}".',
                                      style: const TextStyle(
                                          color: Colors.red,
                                          fontWeight:
                                              FontWeight.bold),
                                    ),
                                    if (gameState.currentMode ==
                                        GameMode.arrange) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        gameState.originalWords
                                            .join(' '),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        gameState.verse?.reference ??
                                            '',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ]
                                  ],
                                ),
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.only(
                                    bottom: 40),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.touch_app,
                                            size: 16,
                                            color: mutedTextColor),
                                        const SizedBox(width: 8),
                                        Text(
                                          gameState.currentMode ==
                                                  GameMode.arrange
                                              ? 'TAP IN ORDER'
                                              : 'TAP THE ANSWER',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight:
                                                FontWeight.bold,
                                            color: mutedTextColor,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    if (gameState.hintsRemaining >
                                            0 ||
                                        gameState.isBonusRound)
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment
                                                .spaceEvenly,
                                        children: [
                                          if (gameState
                                                  .hintsRemaining >
                                              0)
                                            ElevatedButton.icon(
                                              onPressed: () {
                                                ref
                                                    .read(
                                                        verseGameProvider
                                                            .notifier)
                                                    .useHint();
                                                HapticFeedback
                                                    .lightImpact();
                                              },
                                              icon: const Icon(
                                                  Icons.lightbulb,
                                                  size: 16),
                                              label: Text(
                                                  'HINT (${gameState.hintsRemaining})'),
                                              style: ElevatedButton
                                                  .styleFrom(
                                                backgroundColor:
                                                    Colors.amber,
                                                foregroundColor:
                                                    Colors.black,
                                                padding:
                                                    const EdgeInsets
                                                        .symmetric(
                                                        horizontal:
                                                            16,
                                                        vertical: 8),
                                                shape:
                                                    RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius
                                                          .circular(
                                                              20),
                                                ),
                                              ),
                                            ),
                                          if (gameState.isBonusRound)
                                            ElevatedButton.icon(
                                              onPressed: () {
                                                ref
                                                    .read(
                                                        verseGameProvider
                                                            .notifier)
                                                    .useTimeBoost();
                                                HapticFeedback
                                                    .lightImpact();
                                              },
                                              icon: const Icon(
                                                  Icons.timer,
                                                  size: 16),
                                              label:
                                                  const Text('+10s'),
                                              style: ElevatedButton
                                                  .styleFrom(
                                                backgroundColor:
                                                    Colors.blue,
                                                foregroundColor:
                                                    Colors.white,
                                                padding:
                                                    const EdgeInsets
                                                        .symmetric(
                                                        horizontal:
                                                            16,
                                                        vertical: 8),
                                                shape:
                                                    RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius
                                                          .circular(
                                                              20),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    const SizedBox(height: 16),
                                    Container(
                                      width: 64,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: borderColor,
                                        borderRadius:
                                            BorderRadius.circular(2),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
          ),
          // Particle overlay
          _ParticleOverlay(
            show: _showParticles,
            isSuccess: _isParticleSuccess,
          ),
          // Confetti for streaks
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 20,
              gravity: 0.3,
              colors: const [
                Colors.green,
                Colors.amber,
                Colors.blue,
                Colors.purple,
                Colors.orange,
              ],
            ),
          ),
          // Tutorial overlay
          if (_showTutorial)
            _TutorialOverlay(onComplete: _completeTutorial),
        ],
      ),
    );
  }

  Widget _buildGuessContext(
      VerseGameState gameState, Color textColor, Color primaryColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final optimalFontSize = FontSizeCalculator.calculateContextFontSize(
          words: gameState.originalWords,
          availableWidth: constraints.maxWidth,
          baseStyle: const TextStyle(fontSize: 24),
        );

        return Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Wrap(
            spacing: 4,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: gameState.originalWords.map((word) {
              final isMissing = word.contains('_____');
              return Container(
                constraints: BoxConstraints(
                  minWidth: isMissing ? 80 : 20,
                ),
                child: Text(
                  word,
                  overflow: TextOverflow.visible,
                  softWrap: true,
                  style: TextStyle(
                    fontSize: optimalFontSize,
                    fontWeight:
                        isMissing ? FontWeight.w900 : FontWeight.w500,
                    color: isMissing ? primaryColor : textColor,
                    height: 1.2,
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildArrangeContext(VerseGameState gameState, Color textColor,
      Color primaryColor, Color mutedColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final optimalFontSize = FontSizeCalculator.calculateContextFontSize(
          words: gameState.selectedIndices
              .map((index) => gameState.shuffledWords[index])
              .toList(),
          availableWidth: constraints.maxWidth,
          baseStyle: const TextStyle(fontSize: 20),
        );

        return Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Wrap(
            spacing: 6,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: gameState.selectedIndices.map((index) {
              final word = gameState.shuffledWords[index];

              return Container(
                constraints: const BoxConstraints(
                  minWidth: 20,
                ),
                child: Text(
                  word,
                  overflow: TextOverflow.visible,
                  softWrap: true,
                  style: TextStyle(
                    fontSize: optimalFontSize,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    height: 1.2,
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildWordOptions({
    required VerseGameState gameState,
    required WidgetRef ref,
    required VerseGameNotifier notifier,
    required bool isDark,
    required Color borderColor,
    required Color primaryColor,
    required Color textColor,
    required bool shouldScroll,
  }) {
    final words = gameState.currentMode == GameMode.arrange
        ? gameState.shuffledWords
        : gameState.guessOptions;

    return LayoutBuilder(
      builder: (context, constraints) {
        final optimalFontSize = FontSizeCalculator.calculateOptimalFontSize(
          wordCount: words.length,
          maxWidth: constraints.maxWidth,
          maxHeight: constraints.maxHeight,
          baseStyle: const TextStyle(fontSize: 14),
        );

        final wrap = Wrap(
          spacing: 8,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: words.asMap().entries.map((entry) {
            final index = entry.key;
            final word = entry.value;
            final transformIndex = word.hashCode % _rotations.length;

            final isSelected =
                gameState.currentMode == GameMode.arrange &&
                    gameState.selectedIndices.contains(index);
            final selectionOrder = isSelected
                ? gameState.selectedIndices.indexOf(index) + 1
                : null;

            final chip = AnimatedScale(
              scale: 1.0,
              duration: const Duration(milliseconds: 200),
              child: Transform.translate(
                offset: gameState.currentMode == GameMode.arrange
                    ? _translations[transformIndex]
                    : Offset.zero,
                child: Transform.rotate(
                  angle: gameState.currentMode == GameMode.arrange
                      ? _rotations[transformIndex]
                      : 0,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: gameState.state == GameState.playing
                          ? () {
                              ref
                                  .read(soundServiceProvider)
                                  .playGameTap();
                              HapticFeedback.mediumImpact();
                              if (gameState.currentMode ==
                                  GameMode.arrange) {
                                if (isSelected) {
                                  notifier.removeArrangeWord(index);
                                } else {
                                  notifier
                                      .selectArrangeWord(index);
                                }
                              } else {
                                notifier.submitGuess(word);
                              }
                            }
                          : null,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          AnimatedContainer(
                            duration:
                                const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1e293b)
                                  : Colors.white,
                              borderRadius:
                                  BorderRadius.circular(12),
                              border: Border.all(
                                  color: isSelected
                                      ? primaryColor
                                      : borderColor,
                                  width: isSelected ? 2 : 1),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Opacity(
                              opacity: isSelected ? 0.3 : 1.0,
                              child: Text(
                                word,
                                style: TextStyle(
                                  fontSize: optimalFontSize,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ),
                          if (isSelected && selectionOrder != null)
                            Positioned(
                              top: -8,
                              right: -8,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  selectionOrder.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );

            return chip;
          }).toList(),
        );

        if (shouldScroll) {
          return SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  minHeight: constraints.maxHeight * 0.9),
              child: Center(child: wrap),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Center(child: wrap),
        );
      },
    );
  }

  Widget _buildEndScreen(
      BuildContext context,
      VerseGameState gameState,
      VerseGameNotifier notifier,
      Color primaryColor,
      Color textColor) {
    final isSuccess = gameState.state == GameState.sessionComplete;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSuccess
                ? Icons.emoji_events
                : Icons.sentiment_dissatisfied,
            size: 80,
            color: isSuccess ? Colors.amber : primaryColor,
          ),
          const SizedBox(height: 24),
          Text(
            isSuccess ? 'Session Complete!' : 'Game Over',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Score: ${gameState.score}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          if (gameState.streak > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Best streak: ${gameState.streak}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 48),
          ElevatedButton.icon(
            onPressed: () => notifier.restartSession(),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            icon: const Icon(Icons.refresh),
            label: const Text('Play Again',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Back to Bible',
                style: TextStyle(
                    color: textColor.withValues(alpha: 0.6))),
          ),
        ],
      ),
    );
  }
}
