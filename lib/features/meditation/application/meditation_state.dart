import '../domain/models/meditation_enums.dart';
import '../domain/models/meditation_guide.dart';
import '../domain/models/meditation_templates.dart';
import '../domain/models/guided_meditation_content.dart';
import '../domain/models/guided_meditation_phases.dart';

enum DndStatus { unknown, enabled, failed, unsupported }

/// Immutable state for the meditation feature.
class MeditationState {
  const MeditationState({
    required this.phase,
    required this.style,
    required this.selectedMinutes,
    required this.backgroundSound,
    required this.breathPace,
    required this.centeringWord,
    required this.countdown,
    required this.elapsedSeconds,
    required this.breathPhase,
    required this.sessionCount,
    required this.dndStatus,
    this.guide,
    this.guidedContent,
    this.currentGuidedPhase,
    this.virtueName,
    this.chosenChantId,
    this.bibleTemplate,
    this.affirmationCategory,
    this.virtueAffirmation,
    this.habitAffirmation,
    this.customBibleVerses,
  });

  final MeditationPhase phase;
  final MeditationStyle style;
  final int selectedMinutes;
  final BackgroundSound backgroundSound;
  final BreathPace breathPace;
  final String centeringWord;
  final int countdown;
  final int elapsedSeconds;
  final BreathPhase breathPhase;
  final int sessionCount;
  final DndStatus dndStatus;
  final MeditationGuide? guide;
  final GuidedMeditationContent? guidedContent;
  final GuidedPhase? currentGuidedPhase;
  final String? virtueName;
  final String? chosenChantId;
  final BibleTemplate? bibleTemplate;
  final AffirmationCategory? affirmationCategory;
  final VirtueAffirmation? virtueAffirmation;
  final HabitAffirmation? habitAffirmation;
  final String? customBibleVerses;

  int get totalSeconds => selectedMinutes * 60;
  double get progress =>
      totalSeconds > 0 ? (elapsedSeconds / totalSeconds).clamp(0.0, 1.0) : 0.0;
  int get remainingSeconds => (totalSeconds - elapsedSeconds).clamp(0, totalSeconds);

  /// Get progress within the current guided phase (0.0 to 1.0)
  double get guidedPhaseProgress {
    if (guidedContent == null || currentGuidedPhase == null) return 0.0;
    return guidedContent!.getPhaseProgress(elapsedSeconds);
  }

  /// Get the current guided phase content
  GuidedPhaseContent? get currentPhaseContent {
    if (guidedContent == null || currentGuidedPhase == null) return null;
    return guidedContent!.getPhaseContent(currentGuidedPhase!);
  }

  bool get isReadyToBegin {
    if (selectedMinutes <= 0) return false;
    if (style == MeditationStyle.bible && bibleTemplate == null) {
      return false;
    }
    if (style == MeditationStyle.affirmation && affirmationCategory == null) {
      return false;
    }
    if (style == MeditationStyle.affirmation && 
        affirmationCategory == AffirmationCategory.growVirtue && 
        virtueAffirmation == null) {
      return false;
    }
    if (style == MeditationStyle.affirmation && 
        affirmationCategory == AffirmationCategory.stopHabit && 
        habitAffirmation == null) {
      return false;
    }
    if (style == MeditationStyle.bible && 
        bibleTemplate == BibleTemplate.custom && 
        (customBibleVerses == null || customBibleVerses!.isEmpty)) {
      return false;
    }
    if (style == MeditationStyle.chant && (chosenChantId == null || chosenChantId!.isEmpty)) {
      return false;
    }
    return true;
  }

  factory MeditationState.initial() {
    return const MeditationState(
      phase: MeditationPhase.setup,
      style: MeditationStyle.quietReflection,
      selectedMinutes: 10,
      backgroundSound: BackgroundSound.ambient,
      breathPace: BreathPace.medium,
      centeringWord: 'Jesus',
      countdown: 5,
      elapsedSeconds: 0,
      breathPhase: BreathPhase.breathIn,
      sessionCount: 0,
      dndStatus: DndStatus.unknown,
    );
  }

  MeditationState copyWith({
    MeditationPhase? phase,
    MeditationStyle? style,
    int? selectedMinutes,
    BackgroundSound? backgroundSound,
    BreathPace? breathPace,
    String? centeringWord,
    int? countdown,
    int? elapsedSeconds,
    BreathPhase? breathPhase,
    int? sessionCount,
    MeditationGuide? guide,
    GuidedMeditationContent? guidedContent,
    GuidedPhase? currentGuidedPhase,
    String? virtueName,
    String? chosenChantId,
    BibleTemplate? bibleTemplate,
    AffirmationCategory? affirmationCategory,
    VirtueAffirmation? virtueAffirmation,
    HabitAffirmation? habitAffirmation,
    String? customBibleVerses,
    DndStatus? dndStatus,
  }) {
    return MeditationState(
      phase: phase ?? this.phase,
      style: style ?? this.style,
      selectedMinutes: selectedMinutes ?? this.selectedMinutes,
      backgroundSound: backgroundSound ?? this.backgroundSound,
      breathPace: breathPace ?? this.breathPace,
      centeringWord: centeringWord ?? this.centeringWord,
      countdown: countdown ?? this.countdown,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      breathPhase: breathPhase ?? this.breathPhase,
      sessionCount: sessionCount ?? this.sessionCount,
      guide: guide ?? this.guide,
      guidedContent: guidedContent ?? this.guidedContent,
      currentGuidedPhase: currentGuidedPhase ?? this.currentGuidedPhase,
      virtueName: virtueName ?? this.virtueName,
      chosenChantId: chosenChantId ?? this.chosenChantId,
      bibleTemplate: bibleTemplate ?? this.bibleTemplate,
      affirmationCategory: affirmationCategory ?? this.affirmationCategory,
      virtueAffirmation: virtueAffirmation ?? this.virtueAffirmation,
      habitAffirmation: habitAffirmation ?? this.habitAffirmation,
      customBibleVerses: customBibleVerses ?? this.customBibleVerses,
      dndStatus: dndStatus ?? this.dndStatus,
    );
  }
}
