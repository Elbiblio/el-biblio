import '../domain/models/meditation_enums.dart';
import '../domain/models/meditation_guide.dart';

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
    this.guide,
    this.virtueName,
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
  final MeditationGuide? guide;
  final String? virtueName;

  int get totalSeconds => selectedMinutes * 60;
  double get progress =>
      totalSeconds > 0 ? (elapsedSeconds / totalSeconds).clamp(0.0, 1.0) : 0.0;
  int get remainingSeconds => (totalSeconds - elapsedSeconds).clamp(0, totalSeconds);

  bool get isReadyToBegin {
    if (selectedMinutes <= 0) return false;
    if (style == MeditationStyle.virtue && (virtueName == null || virtueName!.isEmpty)) {
      return false;
    }
    return true;
  }

  factory MeditationState.initial() {
    return const MeditationState(
      phase: MeditationPhase.setup,
      style: MeditationStyle.virtue,
      selectedMinutes: 10,
      backgroundSound: BackgroundSound.ambient,
      breathPace: BreathPace.medium,
      centeringWord: 'Jesus',
      countdown: 5,
      elapsedSeconds: 0,
      breathPhase: BreathPhase.breathIn,
      sessionCount: 0,
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
    String? virtueName,
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
      virtueName: virtueName ?? this.virtueName,
    );
  }
}
