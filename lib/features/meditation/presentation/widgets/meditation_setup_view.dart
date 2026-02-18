import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/meditation_notifier.dart';
import '../../domain/models/meditation_enums.dart';
import 'meditation_setup_steps.dart';

/// Step-by-step setup wizard — one focused choice per screen.
class MeditationSetupView extends ConsumerStatefulWidget {
  const MeditationSetupView({super.key});

  @override
  ConsumerState<MeditationSetupView> createState() =>
      _MeditationSetupViewState();
}

class _MeditationSetupViewState extends ConsumerState<MeditationSetupView> {
  int _step = 0;

  // Whether the current style has a detail step (virtue/centering/jesusPrayer)
  bool _hasDetailStep(MeditationStyle style) =>
      style == MeditationStyle.virtue ||
      style == MeditationStyle.centering ||
      style == MeditationStyle.jesusPrayer;

  // Whether the current style has a sound step (everything except chant)
  bool _hasSoundStep(MeditationStyle style) =>
      style != MeditationStyle.chant;

  int _totalSteps(MeditationStyle style) =>
      1 +
      (_hasDetailStep(style) ? 1 : 0) +
      1 + // duration always present
      (_hasSoundStep(style) ? 1 : 0);

  void _next(MeditationStyle style) {
    final total = _totalSteps(style);
    if (_step >= total - 1) return;
    // If on step 0 (style) and no detail step, jump to duration (step 2 logical → step 1 actual)
    if (_step == 0 && !_hasDetailStep(style)) {
      setState(() => _step = 2);
    } else {
      setState(() => _step++);
    }
  }

  void _back(MeditationStyle style) {
    if (_step == 0) return;
    // If on duration step and no detail step, jump back to style
    if (_step == 2 && !_hasDetailStep(style)) {
      setState(() => _step = 0);
    } else {
      setState(() => _step--);
    }
  }

  bool _canProceed(int step, MeditationStyle style, dynamic state) {
    if (step == 0) return true;
    if (step == 1 && _hasDetailStep(style)) {
      if (style == MeditationStyle.virtue) {
        final v = state.virtueName as String?;
        return v != null && v.isNotEmpty;
      }
      return true;
    }
    final durationStep = _hasDetailStep(style) ? 2 : 1;
    if (step == durationStep) return (state.selectedMinutes as int) > 0;
    return true;
  }

  Widget _buildCurrentStep(
    int step,
    MeditationStyle style,
    dynamic state,
    MeditationNotifier notifier,
  ) {
    // Step 0: style
    if (step == 0) {
      return StyleSelectionStep(
        key: const ValueKey('style'),
        selectedStyle: style,
        notifier: notifier,
      );
    }

    // Step 1: detail (only if style has one)
    if (step == 1 && _hasDetailStep(style)) {
      if (style == MeditationStyle.virtue) {
        return VirtueSelectionStep(
          key: const ValueKey('virtue'),
          selectedVirtue: state.virtueName as String?,
          notifier: notifier,
        );
      }
      if (style == MeditationStyle.centering) {
        return CenteringWordStep(
          key: const ValueKey('centering'),
          selectedWord: state.centeringWord as String,
          notifier: notifier,
        );
      }
      // jesusPrayer
      return BreathPaceStep(
        key: const ValueKey('pace'),
        selectedPace: state.breathPace as BreathPace,
        notifier: notifier,
      );
    }

    // Duration step (step 2 if detail exists, step 1 if not — but we use
    // raw _step value so check against durationStep)
    final durationStep = _hasDetailStep(style) ? 2 : 1;
    if (step == durationStep) {
      return DurationSelectionStep(
        key: const ValueKey('duration'),
        selectedMinutes: state.selectedMinutes as int,
        notifier: notifier,
      );
    }

    // Sound step (last)
    return SoundSelectionStep(
      key: const ValueKey('sound'),
      selectedSound: state.backgroundSound as BackgroundSound,
      notifier: notifier,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(meditationProvider);
    final notifier = ref.read(meditationProvider.notifier);
    final theme = Theme.of(context);
    final style = state.style;
    final total = _totalSteps(style);
    final step = _step.clamp(0, total - 1);
    final isLast = step == total - 1;
    final canProceed = _canProceed(step, style, state);

    return Column(
      children: [
        // ── Progress bar ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: Row(
            children: List.generate(total, (i) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: i <= step
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              );
            }),
          ),
        ),

        // ── Step content ───────────────────────────────────────────────
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: anim, curve: Curves.easeOut),
                ),
                child: child,
              ),
            ),
            child: _buildCurrentStep(step, style, state, notifier),
          ),
        ),

        // ── Navigation ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Row(
            children: [
              if (step > 0) ...[
                OutlinedButton(
                  onPressed: () => _back(style),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    side: BorderSide(
                      color:
                          theme.colorScheme.outline.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: isLast
                    ? FilledButton(
                        onPressed: canProceed
                            ? () => notifier.startSession()
                            : null,
                        style: FilledButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Begin Meditation'),
                      )
                    : FilledButton(
                        onPressed: canProceed
                            ? () => _next(style)
                            : null,
                        style: FilledButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Continue'),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
