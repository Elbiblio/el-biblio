import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/meditation_notifier.dart';
import '../../application/meditation_state.dart';
import '../../domain/models/guided_meditation_phases.dart';
import '../../domain/models/meditation_enums.dart';
import '../../domain/models/guided_meditation_content.dart';

/// Immersive 3D meditation view with smooth animations and proper depth
class ImmersiveGuidedMeditationView extends ConsumerStatefulWidget {
  const ImmersiveGuidedMeditationView({super.key});

  @override
  ConsumerState<ImmersiveGuidedMeditationView> createState() =>
      _ImmersiveGuidedMeditationViewState();
}

class _ImmersiveGuidedMeditationViewState
    extends ConsumerState<ImmersiveGuidedMeditationView>
    with TickerProviderStateMixin {
  late AnimationController _breathController;
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late Animation<double> _breathAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _particleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Breathing animation controller (4 seconds per breath cycle)
    _breathController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    
    // Gentle pulse animation for ambiance
    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    // Glow intensity animation
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    // Breathing scale animation (1.0 -> 1.4 -> 1.0)
    _breathAnimation = Tween<double>(
      begin: 1.0,
      end: 1.4,
    ).animate(CurvedAnimation(
      parent: _breathController,
      curve: Curves.easeInOut,
    ));

    // Gentle pulse animation
    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Glow intensity animation
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    // Particle movement animation
    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _breathController,
      curve: Curves.linear,
    ));
  }

  void _startAnimations() {
    _breathController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
    _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(meditationProvider);
    final notifier = ref.read(meditationProvider.notifier);
    final size = MediaQuery.sizeOf(context);
    
    final currentPhase = state.currentGuidedPhase ?? GuidedPhase.breathing;
    final phaseContent = state.currentPhaseContent;
    final phaseProgress = state.guidedPhaseProgress;

    return Container(
      decoration: _buildImmersiveGradient(currentPhase),
      child: SafeArea(
        child: Stack(
          children: [
            // Background particles for depth
            _buildParticleField(size),
            
            // Main content
            Column(
              children: [
                // Phase header with glassmorphism
                _buildGlassPhaseHeader(currentPhase, phaseProgress),
                
                // Main meditation area
                Expanded(
                  child: Center(
                    child: _buildImmersiveBreathingOrb(state, size, currentPhase),
                  ),
                ),
                
                // Phase content with glass cards
                _buildGlassContentCard(phaseContent, currentPhase),
                
                // Bottom controls with glassmorphism
                _buildGlassControls(notifier, state),
              ],
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _buildImmersiveGradient(GuidedPhase phase) {
    final colors = switch (phase) {
      GuidedPhase.breathing => [
        const Color(0xFF0A1929), // Deep blue
        const Color(0xFF1E3A5F), // Medium blue
        const Color(0xFF2E5266), // Light blue
      ],
      GuidedPhase.sceneryJourney => [
        const Color(0xFF1A2332), // Dark purple
        const Color(0xFF2D1B69), // Purple
        const Color(0xFF4A3C8C), // Light purple
      ],
      GuidedPhase.focusPrayer => [
        const Color(0xFF1A1A2E), // Dark indigo
        const Color(0xFF16213E), // Navy
        const Color(0xFF0F3460), // Blue
      ],
      GuidedPhase.closing => [
        const Color(0xFF2C1810), // Dark amber
        const Color(0xFF5C3D2E), // Brown
        const Color(0xFF8B5A3C), // Light brown
      ],
    };

    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
        stops: const [0.0, 0.5, 1.0],
      ),
    );
  }

  Widget _buildParticleField(Size size) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _particleAnimation,
        builder: (context, child) {
          return CustomPaint(
            painter: _ParticlePainter(_particleAnimation.value),
            size: size,
          );
        },
      ),
    );
  }

  Widget _buildGlassPhaseHeader(GuidedPhase phase, double progress) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Phase name
          Text(
            phase.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 2.0,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Progress bar with glow
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.4),
                      Colors.white.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImmersiveBreathingOrb(MeditationState state, Size size, GuidedPhase phase) {
    final isBreathingPhase = phase == GuidedPhase.breathing;
    final orbSize = size.width * 0.75;
    
    return AnimatedBuilder(
      animation: Listenable.merge([_breathAnimation, _pulseAnimation, _glowAnimation]),
      builder: (context, child) {
        final scale = isBreathingPhase ? _breathAnimation.value : _pulseAnimation.value;
        final glowIntensity = _glowAnimation.value;
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Breathing instruction text
            if (isBreathingPhase)
              _buildBreathingInstruction(state.breathPhase),
            
            const SizedBox(height: 40),
            
            // Main 3D orb with multiple layers
            SizedBox(
              width: orbSize,
              height: orbSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glow layer
                  _buildGlowLayer(orbSize, glowIntensity, phase),
                  
                  // Outer ring
                  _buildOuterRing(orbSize, scale, phase),
                  
                  // Main orb with 3D effect
                  _buildMainOrb(orbSize, scale, phase),
                  
                  // Inner core
                  _buildInnerCore(orbSize, scale),
                  
                  // Breathing particles
                  if (isBreathingPhase)
                    _buildBreathingParticles(orbSize, _breathAnimation.value),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBreathingInstruction(BreathPhase breathPhase) {
    String instruction = '';
    String subText = '';
    
    switch (breathPhase) {
      case BreathPhase.breathIn:
        instruction = 'Breathe In';
        subText = 'Slowly and deeply';
        break;
      case BreathPhase.hold:
        instruction = 'Hold';
        subText = 'Feel the calm';
        break;
      case BreathPhase.breathOut:
        instruction = 'Breathe Out';
        subText = 'Release tension';
        break;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Column(
        key: ValueKey(instruction),
        children: [
          Text(
            instruction,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w300,
              letterSpacing: 3.0,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlowLayer(double size, double intensity, GuidedPhase phase) {
    final glowColor = switch (phase) {
      GuidedPhase.breathing => Colors.blue.withValues(alpha: intensity * 0.3),
      GuidedPhase.sceneryJourney => Colors.purple.withValues(alpha: intensity * 0.3),
      GuidedPhase.focusPrayer => Colors.indigo.withValues(alpha: intensity * 0.3),
      GuidedPhase.closing => Colors.amber.withValues(alpha: intensity * 0.3),
    };

    return Container(
      width: size * 1.2,
      height: size * 1.2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: glowColor,
            blurRadius: 60,
            spreadRadius: 30,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: intensity * 0.2),
            blurRadius: 40,
            spreadRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildOuterRing(double size, double scale, GuidedPhase phase) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainOrb(double size, double scale, GuidedPhase phase) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: size * 0.85,
        height: size * 0.85,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.6),
              Colors.white.withValues(alpha: 0.3),
              Colors.white.withValues(alpha: 0.1),
              Colors.transparent,
            ],
            stops: const [0.0, 0.3, 0.6, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.4),
              blurRadius: 30,
              spreadRadius: 10,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInnerCore(double size, double scale) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: size * 0.4,
        height: size * 0.4,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.9),
              Colors.white.withValues(alpha: 0.6),
              Colors.white.withValues(alpha: 0.3),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.8),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreathingParticles(double size, double scale) {
    return Positioned.fill(
      child: CustomPaint(
        painter: _BreathingParticlePainter(scale),
      ),
    );
  }

  Widget _buildGlassContentCard(GuidedPhaseContent? content, GuidedPhase phase) {
    if (content == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            content.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 12),
          
          Text(
            content.instruction,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          
          if (content.breathingCue != null || content.focusPoint != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    content.breathingCue != null ? Icons.air : Icons.psychology,
                    color: Colors.white.withValues(alpha: 0.8),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      content.breathingCue ?? content.focusPoint ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGlassControls(MeditationNotifier notifier, MeditationState state) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Pause/Resume button
          Expanded(
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              child: TextButton(
                onPressed: () {
                  if (state.phase == MeditationPhase.active) {
                    notifier.pause();
                  } else if (state.phase == MeditationPhase.paused) {
                    notifier.resume();
                  }
                },
                child: Text(
                  state.phase == MeditationPhase.paused ? 'Resume' : 'Pause',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // End button
          Expanded(
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.red.withValues(alpha: 0.3),
                    Colors.red.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.3),
                ),
              ),
              child: TextButton(
                onPressed: notifier.endSession,
                child: const Text(
                  'End',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for background particles
class _ParticlePainter extends CustomPainter {
  final double animation;

  _ParticlePainter(this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    const particleCount = 20;
    for (int i = 0; i < particleCount; i++) {
      final progress = (animation + (i * 0.1)) % (2 * math.pi);
      final x = size.width * 0.5 + math.cos(progress) * size.width * 0.4;
      final y = size.height * 0.5 + math.sin(progress) * size.height * 0.4;
      final radius = 2.0 + math.sin(animation + i) * 1.0;
      
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

/// Custom painter for breathing particles
class _BreathingParticlePainter extends CustomPainter {
  final double scale;

  _BreathingParticlePainter(this.scale);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    const particleCount = 12;
    
    for (int i = 0; i < particleCount; i++) {
      final angle = (i * 2 * math.pi) / particleCount;
      final distance = size.shortestSide * 0.3 * scale;
      final x = center.dx + math.cos(angle) * distance;
      final y = center.dy + math.sin(angle) * distance;
      
      canvas.drawCircle(Offset(x, y), 3.0, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BreathingParticlePainter oldDelegate) {
    return oldDelegate.scale != scale;
  }
}
