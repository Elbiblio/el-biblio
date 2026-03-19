import 'guided_meditation_phases.dart';
import 'meditation_enums.dart';

/// Content for a specific phase of guided meditation
class GuidedPhaseContent {
  const GuidedPhaseContent({
    required this.phase,
    required this.title,
    required this.instruction,
    required this.spokenText,
    this.durationSeconds,
    this.breathingCue,
    this.imagery,
    this.focusPoint,
  });

  final GuidedPhase phase;
  final String title;
  final String instruction;
  final String spokenText;
  final int? durationSeconds;
  final String? breathingCue;
  final String? imagery;
  final String? focusPoint;

  GuidedPhaseContent copyWith({
    GuidedPhase? phase,
    String? title,
    String? instruction,
    String? spokenText,
    int? durationSeconds,
    String? breathingCue,
    String? imagery,
    String? focusPoint,
  }) {
    return GuidedPhaseContent(
      phase: phase ?? this.phase,
      title: title ?? this.title,
      instruction: instruction ?? this.instruction,
      spokenText: spokenText ?? this.spokenText,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      breathingCue: breathingCue ?? this.breathingCue,
      imagery: imagery ?? this.imagery,
      focusPoint: focusPoint ?? this.focusPoint,
    );
  }
}

/// Complete guided meditation session content
class GuidedMeditationContent {
  const GuidedMeditationContent({
    required this.style,
    required this.phases,
    required this.totalDurationMinutes,
    this.openingPrayer,
    this.closingPrayer,
    this.backgroundTheme,
  });

  final MeditationStyle style;
  final List<GuidedPhaseContent> phases;
  final int totalDurationMinutes;
  final String? openingPrayer;
  final String? closingPrayer;
  final String? backgroundTheme;

  /// Get content for a specific phase
  GuidedPhaseContent? getPhaseContent(GuidedPhase phase) {
    try {
      return phases.firstWhere((p) => p.phase == phase);
    } catch (e) {
      return null;
    }
  }

  /// Calculate duration for a specific phase
  int calculatePhaseDuration(GuidedPhase phase) {
    final content = getPhaseContent(phase);
    if (content?.durationSeconds != null) {
      return content!.durationSeconds!;
    }
    
    // Use typical duration ratio if no specific duration is set
    final totalSeconds = totalDurationMinutes * 60;
    return (totalSeconds * phase.typicalDurationRatio).round();
  }

  /// Get the current phase based on elapsed time
  GuidedPhase getCurrentPhase(int elapsedSeconds) {
    var accumulatedTime = 0;
    
    for (final phase in GuidedPhase.values) {
      final phaseDuration = calculatePhaseDuration(phase);
      if (elapsedSeconds < accumulatedTime + phaseDuration) {
        return phase;
      }
      accumulatedTime += phaseDuration;
    }
    
    // If we've exceeded all phases, return closing
    return GuidedPhase.closing;
  }

  /// Get progress within the current phase (0.0 to 1.0)
  double getPhaseProgress(int elapsedSeconds) {
    final currentPhase = getCurrentPhase(elapsedSeconds);
    var accumulatedTime = 0;
    
    // Calculate time accumulated before current phase
    for (final phase in GuidedPhase.values) {
      if (phase == currentPhase) break;
      accumulatedTime += calculatePhaseDuration(phase);
    }
    
    final phaseElapsed = elapsedSeconds - accumulatedTime;
    final phaseDuration = calculatePhaseDuration(currentPhase);
    
    return phaseDuration > 0 ? (phaseElapsed / phaseDuration).clamp(0.0, 1.0) : 0.0;
  }
}
