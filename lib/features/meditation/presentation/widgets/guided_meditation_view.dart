import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/meditation_notifier.dart';
import '../../application/meditation_state.dart';
import '../../domain/models/guided_meditation_phases.dart';
import '../../domain/models/meditation_enums.dart';

/// Custom painter for breathing phase indicator dots (like Calm)
class _BreathingDotsPainter extends CustomPainter {
  const _BreathingDotsPainter({
    required this.phase,
    required this.progress,
  });

  final BreathPhase phase;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.4;
    const dotCount = 8;
    const dotSize = 4.0;
    
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < dotCount; i++) {
      final angle = (i * 2 * math.pi) / dotCount;
      final dotPosition = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      
      // Animate dot opacity based on progress
      final dotProgress = (progress + (i / dotCount)) % 1.0;
      final opacity = dotProgress < 0.5 ? dotProgress * 2 : (1 - dotProgress) * 2;
      
      paint.color = Colors.white.withValues(alpha: opacity * 0.6);
      canvas.drawCircle(dotPosition, dotSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BreathingDotsPainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.progress != progress;
  }
}

/// A clean, Calm-inspired guided meditation view
class GuidedMeditationView extends ConsumerWidget {
  const GuidedMeditationView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(meditationProvider);
    final notifier = ref.read(meditationProvider.notifier);
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    
    final currentPhase = state.currentGuidedPhase ?? GuidedPhase.breathing;
    final phaseContent = state.currentPhaseContent;
    final phaseProgress = state.guidedPhaseProgress;
    
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0F172A), // Deep slate blue
            Color(0xFF1E293B), // Dark slate
            Color(0xFF334155), // Medium slate
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header with phase indicator
            _buildPhaseHeader(context, currentPhase, phaseProgress),
            
            // Main content area
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Breathing orb (simplified)
                  _buildBreathingOrb(state, size),
                  
                  const SizedBox(height: 48),
                  
                  // Phase title
                  Text(
                    phaseContent?.title ?? currentPhase.displayName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Phase instruction
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(
                      phaseContent?.instruction ?? currentPhase.description,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.6,
                        fontWeight: FontWeight.w300,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Breathing cue or focus point
                  if (phaseContent?.breathingCue != null)
                    _buildBreathingCue(context, phaseContent!.breathingCue!)
                  else if (phaseContent?.focusPoint != null)
                    _buildFocusPoint(context, phaseContent!.focusPoint!),
                ],
              ),
            ),
            
            // Bottom controls
            _buildControls(context, notifier, state),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseHeader(BuildContext context, GuidedPhase phase, double progress) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Phase name
          Text(
            phase.displayName,
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.6),
              letterSpacing: 2.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Progress bar
          Container(
            height: 2,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(1),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreathingOrb(MeditationState state, Size size) {
    final orbSize = (size.width * 0.7).clamp(200.0, 320.0);
    final currentPhase = state.currentGuidedPhase ?? GuidedPhase.breathing;
    
    // Enhanced breathing animation for breathing phase
    String breathText = '';
    
    if (currentPhase == GuidedPhase.breathing) {
      breathText = switch (state.breathPhase) {
        BreathPhase.breathIn => 'Breathe In',
        BreathPhase.hold => 'Hold',
        BreathPhase.breathOut => 'Breathe Out',
      };
    }
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Breathing instruction text (like Calm)
        if (breathText.isNotEmpty)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              breathText,
              key: ValueKey(breathText),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w300,
                letterSpacing: 2.0,
              ),
            ),
          ),
        
        const SizedBox(height: 32),
        
        // Main breathing orb with progress ring
        AnimatedContainer(
          duration: Duration(milliseconds: currentPhase == GuidedPhase.breathing ? 800 : 2000),
          curve: Curves.easeInOut,
          width: orbSize,
          height: orbSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Progress ring (like Calm)
              if (currentPhase == GuidedPhase.breathing)
                SizedBox(
                  width: orbSize,
                  height: orbSize,
                  child: CircularProgressIndicator(
                    value: switch (state.breathPhase) {
                      BreathPhase.breathIn => 0.25,
                      BreathPhase.hold => 0.5,
                      BreathPhase.breathOut => 0.75,
                    },
                    strokeWidth: 3,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withValues(alpha: 0.4),
                    ),
                    strokeCap: StrokeCap.round,
                  ),
                ),
              
              // Outer glow effect
              Container(
                width: orbSize,
                height: orbSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.15),
                      blurRadius: 40,
                      spreadRadius: 15,
                    ),
                    if (currentPhase == GuidedPhase.breathing)
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.2),
                        blurRadius: 60,
                        spreadRadius: 20,
                      ),
                  ],
                ),
              ),
              
              // Main orb with gradient
              AnimatedContainer(
                duration: Duration(milliseconds: currentPhase == GuidedPhase.breathing ? 800 : 2000),
                curve: Curves.easeInOut,
                width: orbSize * 0.85,
                height: orbSize * 0.85,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.4),
                      Colors.white.withValues(alpha: 0.15),
                      Colors.white.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.4, 0.7, 1.0],
                  ),
                ),
              ),
              
              // Inner bright center
              Container(
                width: orbSize * 0.3,
                height: orbSize * 0.3,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.8),
                      Colors.white.withValues(alpha: 0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              
              // Breathing phase indicator (small dots like Calm)
              if (currentPhase == GuidedPhase.breathing)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _BreathingDotsPainter(
                      phase: state.breathPhase,
                      progress: switch (state.breathPhase) {
                        BreathPhase.breathIn => 0.25,
                        BreathPhase.hold => 0.5,
                        BreathPhase.breathOut => 0.75,
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBreathingCue(BuildContext context, String cue) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        cue,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: Colors.white.withValues(alpha: 0.7),
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildFocusPoint(BuildContext context, String focusPoint) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.psychology_rounded,
            color: Colors.white.withValues(alpha: 0.6),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              focusPoint,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context, MeditationNotifier notifier, MeditationState state) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // Pause/Resume button
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                if (state.phase == MeditationPhase.active) {
                  notifier.pause();
                } else if (state.phase == MeditationPhase.paused) {
                  notifier.resume();
                }
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(state.phase == MeditationPhase.paused ? 'Resume' : 'Pause'),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // End button
          Expanded(
            child: FilledButton(
              onPressed: notifier.endSession,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('End'),
            ),
          ),
        ],
      ),
    );
  }
}
