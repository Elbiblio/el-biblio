import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BreathingMeditationWidget extends ConsumerStatefulWidget {
  const BreathingMeditationWidget({
    super.key,
    required this.onComplete,
    this.breathCount = 3,
  });

  final VoidCallback onComplete;
  final int breathCount;

  @override
  ConsumerState<BreathingMeditationWidget> createState() =>
      _BreathingMeditationWidgetState();
}

class _BreathingMeditationWidgetState
    extends ConsumerState<BreathingMeditationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathController;
  late Animation<double> _breathAnimation;

  int _currentBreath = 0;
  Timer? _breathTimer;
  Timer? _countdownTimer;
  bool _isCompleted = false;

  // Breathing phases timing (in milliseconds)
  // 4-2-6 pattern: longer exhale activates the parasympathetic nervous system
  static const int inhaleTime = 4000; // 4 s
  static const int holdTime = 2000; // 2 s
  static const int exhaleTime = 6000; // 6 s
  static const int breathCycleTime =
      inhaleTime + holdTime + exhaleTime; // 12000 ms

  // Normalized phase boundaries based on controller.value (0.0 → 1.0)
  static const double _inhaleEnd = inhaleTime / breathCycleTime; // 0.333
  static const double _holdEnd =
      (inhaleTime + holdTime) / breathCycleTime; // 0.500

  // Per-second countdown state for the current phase
  int _phaseSecondsRemaining = inhaleTime ~/ 1000;

  @override
  void initState() {
    super.initState();

    _breathController = AnimationController(
      duration: const Duration(milliseconds: breathCycleTime),
      vsync: this,
    );

    // TweenSequence gives each phase its own curve and correct time weight.
    // The resulting value goes 0→1 (inhale), stays 1 (hold), then 1→0 (exhale).
    _breathAnimation = TweenSequence<double>([
      // Inhale: 0→1 over 4 s, easeIn (slow natural start, accelerates gently)
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 4,
      ),
      // Hold: flat at 1.0 for 2 s (circle perfectly still at maximum)
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 2),
      // Exhale: 1→0 over 6 s, easeOut (fast release, decelerates peacefully)
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 6,
      ),
    ]).animate(_breathController);

    _startBreathingSequence();
  }

  void _startBreathingSequence() {
    _phaseSecondsRemaining = inhaleTime ~/ 1000;
    _breathController.forward();

    // Per-second countdown — reads controller.value as the authoritative
    // source of which phase we're in, so it stays in sync even under timer drift.
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _phaseSecondsRemaining--;
        if (_phaseSecondsRemaining <= 0) {
          final t = _breathController.value;
          if (t < _inhaleEnd) {
            _phaseSecondsRemaining = inhaleTime ~/ 1000;
          } else if (t < _holdEnd) {
            _phaseSecondsRemaining = holdTime ~/ 1000;
          } else {
            _phaseSecondsRemaining = exhaleTime ~/ 1000;
          }
        }
      });
    });

    _breathTimer = Timer.periodic(
      const Duration(milliseconds: breathCycleTime),
      (timer) {
        if (_currentBreath < widget.breathCount - 1) {
          setState(() {
            _currentBreath++;
            _phaseSecondsRemaining = inhaleTime ~/ 1000;
          });
          _breathController.reset();
          _breathController.forward();
        } else {
          _completeSequence();
        }
      },
    );
  }

  void _completeSequence() {
    _breathTimer?.cancel();
    _countdownTimer?.cancel();
    setState(() {
      _isCompleted = true;
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _breathTimer?.cancel();
    _countdownTimer?.cancel();
    _breathController.dispose();
    super.dispose();
  }

  String _getBreathingInstruction() {
    // Use normalized controller time — not animation value — so phase labels
    // match the exact millisecond boundaries regardless of curves.
    final t = _breathController.value;
    if (t < _inhaleEnd) return 'Breathe In';
    if (t < _holdEnd) return 'Hold';
    return 'Breathe Out';
  }

  double _getBreathSize() {
    // TweenSequence already encodes the correct curves and hold plateau.
    // This is a straight linear map over the resulting 0→1→1→0 value.
    const minSize = 72.0;
    const maxSize = 160.0;
    return minSize + (maxSize - minSize) * _breathAnimation.value;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final virtueColor = _getVirtueColor();

    if (_isCompleted) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_rounded, color: virtueColor, size: 48),
              const SizedBox(height: 16),
              Text(
                'Ready for Prayer',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: virtueColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: Column(
        children: [
          // Breath counter
          Text(
            'Breath ${_currentBreath + 1} of ${widget.breathCount}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),

          const SizedBox(height: 20),

          // Breathing circle
          Expanded(
            child: Center(
              child: AnimatedBuilder(
                animation: _breathAnimation,
                builder: (context, child) {
                  final breathVal = _breathAnimation.value;
                  final size = _getBreathSize();
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer glow — size and opacity coupled to breath expansion
                      // (no independent pulse; glow breathes with the circle)
                      Container(
                        width: size * 1.4,
                        height: size * 1.4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: virtueColor.withValues(
                            alpha: 0.05 + breathVal * 0.12,
                          ),
                        ),
                      ),

                      // Main breathing circle
                      Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              virtueColor.withValues(alpha: 0.3),
                              virtueColor.withValues(alpha: 0.1),
                            ],
                          ),
                          border: Border.all(
                            color: virtueColor.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                      ),

                      // Inner circle
                      Container(
                        width: size * 0.6,
                        height: size * 0.6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: virtueColor.withValues(alpha: 0.2),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Phase label
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Text(
              _getBreathingInstruction(),
              key: ValueKey(_getBreathingInstruction()),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: virtueColor,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
          ),

          const SizedBox(height: 6),

          // Per-second countdown within the current phase
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              '$_phaseSecondsRemaining',
              key: ValueKey(_phaseSecondsRemaining),
              style: theme.textTheme.titleMedium?.copyWith(
                color: virtueColor.withValues(alpha: 0.55),
                letterSpacing: 2.0,
              ),
            ),
          ),

          const SizedBox(height: 4),

          // Static hint
          Text(
            'Follow the quiet pace',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Color _getVirtueColor() {
    return const Color(0xFF638B6C);
  }
}
