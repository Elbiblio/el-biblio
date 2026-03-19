import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/meditation_notifier.dart';
import '../../application/meditation_state.dart';
import '../../domain/models/meditation_enums.dart';
import '../../domain/models/meditation_templates.dart';
import 'simplified_meditation_steps.dart';
import 'meditation_setup_steps.dart'; // For DurationSelectionStep and SoundSelectionStep

enum _SetupStepKind {
  style,
  bibleTemplate,
  affirmationCategory,
  virtueAffirmation,
  habitAffirmation,
  customBibleVerses,
  duration,
  sound,
  chant,
}

/// Step-by-step setup wizard — one focused choice per screen.
class MeditationSetupView extends ConsumerStatefulWidget {
  const MeditationSetupView({super.key});

  @override
  ConsumerState<MeditationSetupView> createState() =>
      _MeditationSetupViewState();
}

class _DndStatusBanner extends StatelessWidget {
  const _DndStatusBanner({required this.status});

  final DndStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    IconData icon;
    Color containerColor;
    Color borderColor;
    String message;

    switch (status) {
      case DndStatus.enabled:
        icon = Icons.verified_rounded;
        containerColor = theme.colorScheme.primaryContainer.withValues(alpha: 0.35);
        borderColor = theme.colorScheme.primary.withValues(alpha: 0.4);
        message = 'Do Not Disturb is enabled for this session.';
        break;
      case DndStatus.failed:
        icon = Icons.warning_amber_rounded;
        containerColor = theme.colorScheme.errorContainer.withValues(alpha: 0.3);
        borderColor = theme.colorScheme.error.withValues(alpha: 0.4);
        message = 'Couldn\'t enable Do Not Disturb automatically. Please turn it on manually before you begin.';
        break;
      case DndStatus.unsupported:
        icon = Icons.info_outline_rounded;
        containerColor = theme.colorScheme.surfaceContainerHighest;
        borderColor = theme.colorScheme.outline.withValues(alpha: 0.3);
        message = 'This device doesn\'t support automatic Do Not Disturb. Consider silencing notifications manually.';
        break;
      case DndStatus.unknown:
        icon = Icons.do_not_disturb_on_rounded;
        containerColor = theme.colorScheme.primaryContainer.withValues(alpha: 0.3);
        borderColor = theme.colorScheme.primary.withValues(alpha: 0.2);
        message = 'For a distraction-free practice, enable Do Not Disturb before starting.';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: borderColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MeditationSetupViewState extends ConsumerState<MeditationSetupView> {
  int _step = 0;

  // Auto-advance to next step when selection is made
  void _autoAdvanceIfSelected(MeditationStyle style, dynamic state) {
    final steps = _stepsForStyle(style, state);
    final total = steps.length;
    final stepIndex = _step.clamp(0, total - 1);
    final currentStep = steps[stepIndex];
    
    // Check if current step has a valid selection
    if (_canProceed(currentStep, style, state) && stepIndex < total - 1) {
      // Small delay to show selection feedback before advancing
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() => _step = stepIndex + 1);
        }
      });
    }
  }

  // Whether the current style has a bible template step
  bool _hasBibleTemplateStep(MeditationStyle style) =>
      style == MeditationStyle.bible;

  // Whether the current style has an affirmation category step
  bool _hasAffirmationCategoryStep(MeditationStyle style) =>
      style == MeditationStyle.affirmation;

  // Whether the current style has a virtue affirmation step
  bool _hasVirtueAffirmationStep(MeditationStyle style, dynamic state) =>
      style == MeditationStyle.affirmation &&
      state.affirmationCategory == AffirmationCategory.growVirtue;

  // Whether the current style has a habit affirmation step
  bool _hasHabitAffirmationStep(MeditationStyle style, dynamic state) =>
      style == MeditationStyle.affirmation &&
      state.affirmationCategory == AffirmationCategory.stopHabit;

  // Whether the current style has a custom bible verses step
  bool _hasCustomBibleVersesStep(MeditationStyle style, dynamic state) =>
      style == MeditationStyle.bible &&
      state.bibleTemplate == BibleTemplate.custom;

  // Whether the current style has a sound step (everything except chant)
  bool _hasSoundStep(MeditationStyle style) =>
      style != MeditationStyle.chant;

  // Whether the current style has a chant selection step
  bool _hasChantStep(MeditationStyle style) =>
      style == MeditationStyle.chant;

  List<_SetupStepKind> _stepsForStyle(MeditationStyle style, dynamic state) {
    final steps = <_SetupStepKind>[_SetupStepKind.style];
    
    if (_hasBibleTemplateStep(style)) {
      steps.add(_SetupStepKind.bibleTemplate);
      if (_hasCustomBibleVersesStep(style, state)) {
        steps.add(_SetupStepKind.customBibleVerses);
      }
    }
    
    if (_hasAffirmationCategoryStep(style)) {
      steps.add(_SetupStepKind.affirmationCategory);
      if (_hasVirtueAffirmationStep(style, state)) {
        steps.add(_SetupStepKind.virtueAffirmation);
      }
      if (_hasHabitAffirmationStep(style, state)) {
        steps.add(_SetupStepKind.habitAffirmation);
      }
    }
    
    steps.add(_SetupStepKind.duration);
    if (_hasSoundStep(style)) {
      steps.add(_SetupStepKind.sound);
    }
    if (_hasChantStep(style)) {
      steps.add(_SetupStepKind.chant);
    }
    return steps;
  }

  int _totalSteps(MeditationStyle style, dynamic state) => _stepsForStyle(style, state).length;

  void _next(MeditationStyle style, dynamic state) {
    final total = _totalSteps(style, state);
    final current = _step.clamp(0, total - 1);
    if (current >= total - 1) return;

    setState(() => _step = current + 1);
  }

  void _back(MeditationStyle style, dynamic state) {
    final total = _totalSteps(style, state);
    final current = _step.clamp(0, total - 1);
    if (current == 0) return;

    setState(() => _step = current - 1);
  }

  bool _canProceed(_SetupStepKind kind, MeditationStyle style, dynamic state) {
    if (kind == _SetupStepKind.style) return true;
    if (kind == _SetupStepKind.bibleTemplate) return state.bibleTemplate != null;
    if (kind == _SetupStepKind.affirmationCategory) return state.affirmationCategory != null;
    if (kind == _SetupStepKind.virtueAffirmation) return state.virtueAffirmation != null;
    if (kind == _SetupStepKind.habitAffirmation) return state.habitAffirmation != null;
    if (kind == _SetupStepKind.customBibleVerses) {
      return state.customBibleVerses != null && state.customBibleVerses!.isNotEmpty;
    }
    if (kind == _SetupStepKind.duration) return (state.selectedMinutes as int) > 0;
    return true;
  }

  Widget _buildCurrentStep(
    _SetupStepKind kind,
    MeditationStyle style,
    dynamic state,
    MeditationNotifier notifier,
  ) {
    if (kind == _SetupStepKind.style) {
      return SimplifiedStyleSelectionStep(
        key: const ValueKey('style'),
        selectedStyle: style,
        notifier: notifier,
        onSelectionChanged: () => _autoAdvanceIfSelected(style, state),
      );
    }

    if (kind == _SetupStepKind.bibleTemplate) {
      return BibleTemplateStep(
        key: const ValueKey('bibleTemplate'),
        selectedTemplate: state.bibleTemplate as BibleTemplate?,
        notifier: notifier,
        onSelectionChanged: () => _autoAdvanceIfSelected(style, state),
      );
    }

    if (kind == _SetupStepKind.affirmationCategory) {
      return AffirmationCategoryStep(
        key: const ValueKey('affirmationCategory'),
        selectedCategory: state.affirmationCategory as AffirmationCategory?,
        notifier: notifier,
        onSelectionChanged: () => _autoAdvanceIfSelected(style, state),
      );
    }

    if (kind == _SetupStepKind.virtueAffirmation) {
      return VirtueAffirmationStep(
        key: const ValueKey('virtueAffirmation'),
        selectedAffirmation: state.virtueAffirmation as VirtueAffirmation?,
        notifier: notifier,
        onSelectionChanged: () => _autoAdvanceIfSelected(style, state),
      );
    }

    if (kind == _SetupStepKind.habitAffirmation) {
      return HabitAffirmationStep(
        key: const ValueKey('habitAffirmation'),
        selectedAffirmation: state.habitAffirmation as HabitAffirmation?,
        notifier: notifier,
        onSelectionChanged: () => _autoAdvanceIfSelected(style, state),
      );
    }

    if (kind == _SetupStepKind.customBibleVerses) {
      return CustomBibleVersesStep(
        key: const ValueKey('customBibleVerses'),
        notifier: notifier,
      );
    }

    if (kind == _SetupStepKind.duration) {
      return DurationSelectionStep(
        key: const ValueKey('duration'),
        selectedMinutes: state.selectedMinutes as int,
        notifier: notifier,
        onSelectionChanged: () => _autoAdvanceIfSelected(style, state),
      );
    }

    if (kind == _SetupStepKind.sound && _hasSoundStep(style)) {
      return SoundSelectionStep(
        key: const ValueKey('sound'),
        selectedSound: state.backgroundSound as BackgroundSound,
        notifier: notifier,
        onSelectionChanged: () => _autoAdvanceIfSelected(style, state),
      );
    }

    if (kind == _SetupStepKind.chant && _hasChantStep(style)) {
      return ChantSelectionStep(
        key: const ValueKey('chant'),
        notifier: notifier,
      );
    }

    // Default fallback
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(meditationProvider);
    final notifier = ref.read(meditationProvider.notifier);
    final theme = Theme.of(context);
    final style = state.style;
    final steps = _stepsForStyle(style, state);
    final total = steps.length;
    final stepIndex = _step.clamp(0, total - 1);
    final currentStep = steps[stepIndex];
    final isLast = stepIndex == total - 1;
    final canProceed = _canProceed(currentStep, style, state);

    return Column(
      children: [
        // ── Progress bar ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: List.generate(total, (i) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: 2,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(1),
                    color: i <= stepIndex
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              );
            }),
          ),
        ),

        if (isLast && canProceed)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
            child: _DndStatusBanner(status: state.dndStatus),
          ),

        // ── Step content ───────────────────────────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
              child: _buildCurrentStep(currentStep, style, state, notifier),
            ),
          ),
        ),

        // ── Navigation ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
          child: Row(
            children: [
              if (stepIndex > 0) ...[
                OutlinedButton(
                  onPressed: () => _back(style, state),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    side: BorderSide(
                      color:
                          theme.colorScheme.outline.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: isLast
                    ? FilledButton(
                        onPressed: canProceed
                            ? () => notifier.startSession()
                            : null,
                        style: FilledButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Begin Meditation'),
                      )
                    : FilledButton(
                        onPressed: canProceed
                            ? () => _next(style, state)
                            : null,
                        style: FilledButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
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
