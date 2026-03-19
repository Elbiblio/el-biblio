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
  ConsumerState<BreathingMeditationWidget> createState() => _BreathingMeditationWidgetState();
}

class _BreathingMeditationWidgetState extends ConsumerState<BreathingMeditationWidget>
    with TickerProviderStateMixin {
  late AnimationController _breathController;
  late AnimationController _pulseController;
  late Animation<double> _breathAnimation;
  late Animation<double> _pulseAnimation;
  
  int _currentBreath = 0;
  Timer? _breathTimer;
  bool _isCompleted = false;

  // Breathing phases timing (in milliseconds)
  static const int inhaleTime = 4000;
  static const int holdTime = 4000;
  static const int exhaleTime = 4000;
  static const int breathCycleTime = inhaleTime + holdTime + exhaleTime;

  @override
  void initState() {
    super.initState();
    
    _breathController = AnimationController(
      duration: const Duration(milliseconds: breathCycleTime),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _breathAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _breathController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _startBreathingSequence();
  }

  void _startBreathingSequence() {
    _breathController.forward();
    _pulseController.repeat(reverse: true);
    
    _breathTimer = Timer.periodic(
      const Duration(milliseconds: breathCycleTime),
      (timer) {
        if (_currentBreath < widget.breathCount - 1) {
          setState(() {
            _currentBreath++;
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
    _pulseController.stop();
    setState(() {
      _isCompleted = true;
    });
    
    // Brief pause before completion callback
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _breathTimer?.cancel();
    _breathController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String _getBreathingInstruction() {
    final progress = _breathAnimation.value;
    
    if (progress < 0.33) {
      return 'Breathe In';
    } else if (progress < 0.66) {
      return 'Hold';
    } else {
      return 'Breathe Out';
    }
  }

  double _getBreathSize() {
    final progress = _breathAnimation.value;
    const baseSize = 80.0;
    const maxSize = 140.0;
    
    if (progress < 0.33) {
      // Inhale: growing
      return baseSize + (maxSize - baseSize) * (progress * 3);
    } else if (progress < 0.66) {
      // Hold: steady at max
      return maxSize;
    } else {
      // Exhale: shrinking
      final exhaleProgress = (progress - 0.66) * 3;
      return maxSize - (maxSize - baseSize) * exhaleProgress;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final virtueColor = _getVirtueColor();
    
    if (_isCompleted) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: virtueColor,
                size: 48,
              ),
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
      height: 280,
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
                animation: Listenable.merge([_breathAnimation, _pulseAnimation]),
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer glow effect
                      Container(
                        width: _getBreathSize() * 1.3 * _pulseAnimation.value,
                        height: _getBreathSize() * 1.3 * _pulseAnimation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: virtueColor.withValues(alpha: 0.1),
                        ),
                      ),
                      
                      // Main breathing circle
                      Container(
                        width: _getBreathSize(),
                        height: _getBreathSize(),
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
                        width: _getBreathSize() * 0.6,
                        height: _getBreathSize() * 0.6,
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
          
          // Breathing instruction
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
          
          const SizedBox(height: 8),
          
          // Subtle timing hint
          Text(
            'Follow the gentle rhythm',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Color _getVirtueColor() {
    // This would be passed in or determined from context
    // For now, using a default calming blue
    return const Color(0xFF638B6C);
  }
}
