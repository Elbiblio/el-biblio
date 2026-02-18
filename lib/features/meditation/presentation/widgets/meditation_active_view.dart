import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/meditation_notifier.dart';
import '../../application/meditation_state.dart';
import '../../domain/models/meditation_enums.dart';

/// The active meditation view — full-screen presence, one thing at a time.
class MeditationActiveView extends ConsumerWidget {
  const MeditationActiveView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(meditationProvider);
    final notifier = ref.read(meditationProvider.notifier);
    final theme = Theme.of(context);
    final guide = state.guide;
    final size = MediaQuery.sizeOf(context);
    final circleSize = (size.width * 0.62).clamp(200.0, 280.0);

    return Column(
      children: [
        // ── Elapsed / total timer (top, subtle) ─────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatTime(state.elapsedSeconds),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w300,
                  letterSpacing: 2,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              Text(
                _formatTime(state.totalSeconds),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),

        // ── Thin progress bar ────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: state.progress,
              minHeight: 2,
              backgroundColor:
                  theme.colorScheme.outline.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),

        const Spacer(flex: 2),

        // ── Breathing circle ─────────────────────────────────────────
        SizedBox(
          width: circleSize,
          height: circleSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer ring
              SizedBox(
                width: circleSize,
                height: circleSize,
                child: CircularProgressIndicator(
                  value: state.progress,
                  strokeWidth: 3,
                  backgroundColor:
                      theme.colorScheme.outline.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  strokeCap: StrokeCap.round,
                ),
              ),

              // Animated breath pulse
              AnimatedContainer(
                duration: Duration(
                  milliseconds: switch (state.breathPhase) {
                    BreathPhase.breathIn => state.breathPace.inMs,
                    BreathPhase.hold => state.breathPace.holdMs,
                    BreathPhase.breathOut => state.breathPace.outMs,
                  },
                ),
                curve: Curves.easeInOut,
                width: switch (state.breathPhase) {
                  BreathPhase.breathIn => circleSize * 0.68,
                  BreathPhase.hold => circleSize * 0.68,
                  BreathPhase.breathOut => circleSize * 0.38,
                },
                height: switch (state.breathPhase) {
                  BreathPhase.breathIn => circleSize * 0.68,
                  BreathPhase.hold => circleSize * 0.68,
                  BreathPhase.breathOut => circleSize * 0.38,
                },
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.3),
                      theme.colorScheme.primary.withValues(alpha: 0.06),
                    ],
                  ),
                ),
              ),

              // Centre: breath instruction only (no timer clutter)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  key: ValueKey(state.breathPhase),
                  _breathLabel(state),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.primary.withValues(alpha: 0.9),
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // ── Jesus Prayer phrases (only for that style) ───────────────
        if (state.style == MeditationStyle.jesusPrayer)
          _JesusPrayerGuide(breathPhase: state.breathPhase),

        // ── Centering word reminder ──────────────────────────────────
        if (state.style == MeditationStyle.centering)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            child: Text(
              key: ValueKey(state.breathPhase),
              state.centeringWord,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w300,
                letterSpacing: 4,
                color: theme.colorScheme.primary.withValues(alpha: 0.7),
              ),
            ),
          ),

        // ── Guide declaration (virtue / parable) ────────────────────
        if (guide != null &&
            guide.declaration.isNotEmpty &&
            state.style != MeditationStyle.jesusPrayer &&
            state.style != MeditationStyle.centering)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              guide.declaration,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                height: 1.6,
              ),
            ),
          ),

        const Spacer(flex: 3),

        // ── Controls ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => notifier.pause(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Text('Pause'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => notifier.endSession(),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        theme.colorScheme.error.withValues(alpha: 0.8),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('End'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _breathLabel(MeditationState state) {
    if (state.style == MeditationStyle.centering) return 'Return';
    if (state.style == MeditationStyle.chant) return 'Sing';
    return switch (state.breathPhase) {
      BreathPhase.breathIn => 'Breathe In',
      BreathPhase.hold => 'Hold',
      BreathPhase.breathOut => 'Breathe Out',
    };
  }

  static String _formatTime(int totalSeconds) {
    final clamped = totalSeconds.clamp(0, 99999);
    final mins = clamped ~/ 60;
    final secs = clamped % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

class _JesusPrayerGuide extends StatelessWidget {
  const _JesusPrayerGuide({required this.breathPhase});
  final BreathPhase breathPhase;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = theme.colorScheme.primary;
    final dim = theme.colorScheme.onSurface.withValues(alpha: 0.2);

    return Column(
      children: [
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 400),
          style: theme.textTheme.titleMedium!.copyWith(
            color: breathPhase == BreathPhase.breathIn ? active : dim,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
          child: const Text('Lord Jesus Christ'),
        ),
        const SizedBox(height: 6),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 400),
          style: theme.textTheme.titleMedium!.copyWith(
            color: breathPhase == BreathPhase.hold ? active : dim,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
          child: const Text('Son of God'),
        ),
        const SizedBox(height: 6),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 400),
          style: theme.textTheme.titleMedium!.copyWith(
            color: breathPhase == BreathPhase.breathOut ? active : dim,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
          child: const Text('have mercy on me'),
        ),
      ],
    );
  }
}
