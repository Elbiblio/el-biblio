import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'sound_service.dart';

/// Service for handling celebration animations and sounds
class CelebrationService {
  static CelebrationService? _instance;
  static CelebrationService get instance => _instance ??= CelebrationService._();
  CelebrationService._();

  final Map<String, ConfettiController> _controllers = {};

  /// Create and play a confetti animation
  ConfettiController createConfetti({
    required String key,
    required BuildContext context,
    Duration? duration,
    int? numberOfParticles,
    List<Color>? colors,
  }) {
    // Dispose existing controller if any
    _controllers[key]?.dispose();

    final controller = ConfettiController(
      duration: duration ?? const Duration(seconds: 3),
    );

    _controllers[key] = controller;
    controller.play();

    return controller;
  }

  /// Play celebration with confetti and sound
  void playCelebration({
    required BuildContext context,
    required String key,
    CelebrationType type = CelebrationType.general,
    VoidCallback? onComplete,
  }) {
    // Play sound
    _playSound(type);

    // Create confetti
    final controller = createConfetti(
      key: key,
      context: context,
      duration: _getDuration(type),
      numberOfParticles: _getParticleCount(type),
      colors: _getColors(type),
    );

    // Handle completion
    if (onComplete != null) {
      controller.addListener(() {
        if (controller.state == ConfettiControllerState.stopped) {
          onComplete();
          controller.dispose();
          _controllers.remove(key);
        }
      });
    } else {
      // Auto-cleanup after duration
      Future.delayed(_getDuration(type) + const Duration(seconds: 1), () {
        controller.dispose();
        _controllers.remove(key);
      });
    }
  }

  /// Play onboarding completion celebration
  void playOnboardingCompletion(BuildContext context) {
    playCelebration(
      context: context,
      key: 'onboarding_completion',
      type: CelebrationType.onboarding,
    );
  }

  /// Play daily check-in completion celebration
  void playDailyCheckInCompletion(BuildContext context) {
    playCelebration(
      context: context,
      key: 'daily_checkin_completion',
      type: CelebrationType.dailyCheckIn,
    );
  }

  /// Play activity completion celebration
  void playActivityCompletion(BuildContext context, {required String activityKey}) {
    playCelebration(
      context: context,
      key: 'activity_$activityKey',
      type: CelebrationType.activity,
    );
  }

  /// Play level up celebration
  void playLevelUp(BuildContext context) {
    playCelebration(
      context: context,
      key: 'level_up',
      type: CelebrationType.levelUp,
    );
  }

  /// Dispose specific controller
  void disposeController(String key) {
    _controllers[key]?.dispose();
    _controllers.remove(key);
  }

  /// Dispose all controllers
  void disposeAll() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
  }

  void _playSound(CelebrationType type) {
    final soundService = SoundService();
    
    switch (type) {
      case CelebrationType.onboarding:
        soundService.playOnboardingSuccess();
        break;
      case CelebrationType.dailyCheckIn:
        soundService.playGameLevelUp(); // Reuse level up sound
        break;
      case CelebrationType.activity:
        soundService.playGameSuccess();
        break;
      case CelebrationType.levelUp:
        soundService.playGameLevelUp();
        break;
      case CelebrationType.general:
        soundService.playGameSuccess();
        break;
    }
  }

  Duration _getDuration(CelebrationType type) {
    switch (type) {
      case CelebrationType.onboarding:
        return const Duration(seconds: 4);
      case CelebrationType.dailyCheckIn:
        return const Duration(seconds: 3);
      case CelebrationType.activity:
        return const Duration(seconds: 2);
      case CelebrationType.levelUp:
        return const Duration(seconds: 5);
      case CelebrationType.general:
        return const Duration(seconds: 3);
    }
  }

  int _getParticleCount(CelebrationType type) {
    switch (type) {
      case CelebrationType.onboarding:
        return 100;
      case CelebrationType.dailyCheckIn:
        return 50;
      case CelebrationType.activity:
        return 30;
      case CelebrationType.levelUp:
        return 150;
      case CelebrationType.general:
        return 40;
    }
  }

  List<Color> _getColors(CelebrationType type) {
    switch (type) {
      case CelebrationType.onboarding:
        return [
          const Color(0xFFF4B925), // Gold
          const Color(0xFF4CAF50), // Green
          const Color(0xFF2196F3), // Blue
          const Color(0xFF9C27B0), // Purple
        ];
      case CelebrationType.dailyCheckIn:
        return [
          const Color(0xFFFF9800), // Orange
          const Color(0xFFFFC107), // Amber
          const Color(0xFFFFEB3B), // Yellow
        ];
      case CelebrationType.activity:
        return [
          const Color(0xFF4CAF50), // Green
          const Color(0xFF8BC34A), // Light Green
        ];
      case CelebrationType.levelUp:
        return [
          const Color(0xFFFFD700), // Gold
          const Color(0xFFFFA500), // Orange
          const Color(0xFFFF69B4), // Hot Pink
          const Color(0xFF00CED1), // Dark Turquoise
          const Color(0xFF9370DB), // Medium Purple
        ];
      case CelebrationType.general:
        return [
          const Color(0xFF2196F3), // Blue
          const Color(0xFF4CAF50), // Green
        ];
    }
  }
}

/// Types of celebrations
enum CelebrationType {
  onboarding,
  dailyCheckIn,
  activity,
  levelUp,
  general,
}

/// Widget to display confetti overlay
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({
    super.key,
    required this.child,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final Alignment alignment;

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Align(
          alignment: widget.alignment,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            particleDrag: 0.05,
            emissionFrequency: 0.05,
            numberOfParticles: 50,
            gravity: 0.1,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple
            ],
            strokeWidth: 1,
            strokeColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
