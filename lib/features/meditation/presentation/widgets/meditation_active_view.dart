import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/meditation_notifier.dart';
import '../../application/meditation_state.dart';
import '../../domain/models/meditation_enums.dart';
import '../../domain/models/meditation_guide.dart';

class MeditationActiveView extends ConsumerWidget {
  const MeditationActiveView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(meditationProvider);
    final notifier = ref.read(meditationProvider.notifier);
    final theme = Theme.of(context);
    final guide = state.guide;
    final size = MediaQuery.sizeOf(context);
    final orbSize = (size.width * 0.6).clamp(220.0, 320.0);
    final pulseScale = switch (state.breathPhase) {
      BreathPhase.breathIn => 1.0,
      BreathPhase.hold => 1.04,
      BreathPhase.breathOut => 0.72,
    };
    final animationMs = switch (state.breathPhase) {
      BreathPhase.breathIn => state.breathPace.inMs,
      BreathPhase.hold => state.breathPace.holdMs,
      BreathPhase.breathOut => state.breathPace.outMs,
    };

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0A1929), // Deeper, more spiritual blue
            Color(0xFF1A2332), // Rich midnight blue
            Color(0xFF2A1F3A), // Purple hint for spirituality
            Color(0xFF1F1A2E), // Deep cosmic purple
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _HaloPainter(
                  color: theme.colorScheme.primary.withValues(alpha: 0.4),
                  progress: state.progress,
                ),
              ),
            ),
          ),
          Positioned(
            top: 72,
            left: 0,
            right: 0,
            child: _TopTimeBar(state: state),
          ),
          Positioned.fill(
            child: Column(
              children: [
                const SizedBox(height: 128),
                Text(
                  _spiritualHeadline(state),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.92),
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _phasePrompt(state),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                ),
                
                // Show scripture text for Bible meditation
                if (state.style == MeditationStyle.bible) ...[
                  const SizedBox(height: 16),
                  _ScriptureDisplay(guide: guide),
                ],
                
                const Spacer(),
                AnimatedScale(
                  scale: pulseScale,
                  duration: Duration(milliseconds: animationMs),
                  curve: Curves.easeInOut,
                  child: _BreathOrb(
                    state: state,
                    size: orbSize,
                  ),
                ),
                const SizedBox(height: 28),
                _PrayerLine(
                  style: state.style,
                  declaration: guide?.declaration ?? '',
                  centeringWord: state.centeringWord,
                  breathPhase: state.breathPhase,
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: notifier.pause,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.35),
                            ),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Pause'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: notifier.endSession,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFD65F5F),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('End'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _spiritualHeadline(MeditationState state) {
    if (state.style == MeditationStyle.bible) {
      final guide = state.guide;
      if (guide != null) {
        return guide.title;
      }
      return 'Scripture Meditation';
    }
    if (state.style == MeditationStyle.quietReflection) {
      return 'Rest In Divine Presence';
    }
    if (state.style == MeditationStyle.chant) {
      return 'Lift Your Heart In Praise';
    }
    if (state.style == MeditationStyle.affirmation) {
      return 'Cultivate Sacred Virtue';
    }
    return 'Be Still And Know God';
  }

  String _phasePrompt(MeditationState state) {
    if (state.style == MeditationStyle.bible) {
      final guide = state.guide;
      if (guide != null && guide.scripture.isNotEmpty) {
        // Show scripture reference for Bible meditation
        return guide.scripture;
      }
      return 'Meditate on sacred Scripture';
    }
    if (state.style == MeditationStyle.quietReflection) {
      return 'Return gently to "${state.centeringWord}"';
    }
    if (state.style == MeditationStyle.chant) {
      return 'Let each phrase become sacred prayer';
    }
    if (state.style == MeditationStyle.affirmation) {
      return 'Breathe in ${state.virtueName ?? "grace"}';
    }
    return switch (state.breathPhase) {
      BreathPhase.breathIn => 'Breathe in Divine Peace',
      BreathPhase.hold => 'Rest in Holy Stillness',
      BreathPhase.breathOut => 'Release all burdens',
    };
  }
}

class _TopTimeBar extends StatelessWidget {
  const _TopTimeBar({required this.state});

  final MeditationState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatTime(state.elapsedSeconds),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.86),
                      letterSpacing: 1.8,
                      fontWeight: FontWeight.w300,
                    ),
              ),
              Text(
                _formatTime(state.totalSeconds),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.5),
                      letterSpacing: 1.1,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: state.progress,
              minHeight: 3,
              backgroundColor: Colors.white.withValues(alpha: 0.16),
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.white.withValues(alpha: 0.78),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final clamped = totalSeconds.clamp(0, 99999);
    final mins = clamped ~/ 60;
    final secs = clamped % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

class _BreathOrb extends StatelessWidget {
  const _BreathOrb({
    required this.state,
    required this.size,
  });

  final MeditationState state;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final indicatorColor = Colors.white.withValues(alpha: 0.9);
    final glowColor = theme.colorScheme.primary.withValues(alpha: 0.3);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow effect
          Container(
            width: size * 1.1,
            height: size * 1.1,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: glowColor,
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: theme.colorScheme.tertiary.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 3,
                ),
              ],
            ),
          ),
          // Progress ring
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: state.progress,
              strokeWidth: 4,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
              strokeCap: StrokeCap.round,
            ),
          ),
          // Inner radiant orb
          Container(
            width: size * 0.85,
            height: size * 0.85,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.8),
                  theme.colorScheme.primary.withValues(alpha: 0.4),
                  theme.colorScheme.tertiary.withValues(alpha: 0.2),
                  Colors.white.withValues(alpha: 0.05),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.3, 0.6, 0.8, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          // Divine center light
          Container(
            width: size * 0.3,
            height: size * 0.3,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white,
                  Colors.white.withValues(alpha: 0.8),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Breath phase text and icon
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _breathLabel(state),
                style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                child: Icon(
                  _breathIcon(state),
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _breathLabel(MeditationState state) {
    if (state.style == MeditationStyle.quietReflection) return 'Return';
    if (state.style == MeditationStyle.chant) return 'Sing';
    return switch (state.breathPhase) {
      BreathPhase.breathIn => 'Breathe In',
      BreathPhase.hold => 'Be Still',
      BreathPhase.breathOut => 'Breathe Out',
    };
  }

  IconData _breathIcon(MeditationState state) {
    if (state.style == MeditationStyle.chant) return Icons.music_note_rounded;
    return switch (state.breathPhase) {
      BreathPhase.breathIn => Icons.arrow_upward_rounded,
      BreathPhase.hold => Icons.pause_rounded,
      BreathPhase.breathOut => Icons.arrow_downward_rounded,
    };
  }
}

class _PrayerLine extends StatelessWidget {
  const _PrayerLine({
    required this.style,
    required this.declaration,
    required this.centeringWord,
    required this.breathPhase,
  });

  final MeditationStyle style;
  final String declaration;
  final String centeringWord;
  final BreathPhase breathPhase;

  @override
  Widget build(BuildContext context) {
    final text = switch (style) {
      MeditationStyle.bible => _biblePrayerText(breathPhase),
      MeditationStyle.quietReflection => 'Sacred word: $centeringWord',
      MeditationStyle.chant => 'Pray the melody, not just the words.',
      _ => declaration.isNotEmpty
          ? declaration
          : 'Your breath is a quiet prayer before God.'
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.76),
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
      ),
    );
  }

  String _biblePrayerText(BreathPhase phase) {
    return switch (phase) {
      BreathPhase.breathIn => 'Lord Jesus Christ',
      BreathPhase.hold => 'Son of God',
      BreathPhase.breathOut => 'Have mercy on me',
    };
  }
}

class _ScriptureDisplay extends StatelessWidget {
  const _ScriptureDisplay({required this.guide});

  final MeditationGuide? guide;

  List<Widget> _parseBibleImagery(BuildContext context, String imagery) {
    final theme = Theme.of(context);
    final parts = imagery.split('\n\n');
    
    return parts.map((part) {
      if (part.trim().isEmpty) return const SizedBox.shrink();
      
      // If it looks like verse text (longer, contains quotes), display it differently
      final isVerseText = part.length > 50 && (part.contains('"') || part.contains('Lord') || part.contains('God'));
      
      return Column(
        children: [
          Text(
            part,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              fontStyle: isVerseText ? FontStyle.normal : FontStyle.italic,
              height: 1.4,
              fontWeight: isVerseText ? FontWeight.w500 : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
          if (part != parts.last) const SizedBox(height: 12),
        ],
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (guide == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.05),
            Colors.white.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          if (guide!.imagery.isNotEmpty) ...[
            // Split imagery to separate instructions from verse text
            ..._parseBibleImagery(context, guide!.imagery),
          ],
          if (guide!.scripture.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              guide!.scripture,
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (guide!.focus.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Focus: ${guide!.focus}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.6),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _HaloPainter extends CustomPainter {
  _HaloPainter({
    required this.color,
    required this.progress,
  });

  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.shortestSide * 0.28;
    
    // Animated expanding rings based on progress
    final rings = <double>[];
    const ringCount = 5;
    
    for (var i = 0; i < ringCount; i++) {
      final ringProgress = (progress + (i * 0.2)) % 1.0;
      final radius = baseRadius * (0.8 + (ringProgress * 0.8));
      rings.add(radius);
    }

    // Draw spiritual halo rings
    for (var i = 0; i < rings.length; i++) {
      final ringProgress = (progress + (i * 0.2)) % 1.0;
      final opacity = (0.3 - (i * 0.05)) * (1.0 - ringProgress * 0.5);
      
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (i == 0 ? 3.0 : 2.0) * (1.0 - ringProgress * 0.3)
        ..color = color.withValues(alpha: opacity.clamp(0.02, 0.3));
      
      canvas.drawCircle(center, rings[i], paint);
    }
    
    // Draw divine light rays
    const rayCount = 12;
    for (var i = 0; i < rayCount; i++) {
      final angle = (i * 2 * 3.14159) / rayCount;
      final startRadius = baseRadius * 1.2;
      final endRadius = baseRadius * (1.8 + progress * 0.4);
      
      final rayOpacity = 0.1 * (1.0 - progress * 0.3);
      final rayPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = color.withValues(alpha: rayOpacity.clamp(0.02, 0.15));
      
      final start = Offset(
        center.dx + startRadius * math.cos(angle),
        center.dy + startRadius * math.sin(angle),
      );
      final end = Offset(
        center.dx + endRadius * math.cos(angle),
        center.dy + endRadius * math.sin(angle),
      );
      
      canvas.drawLine(start, end, rayPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HaloPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

