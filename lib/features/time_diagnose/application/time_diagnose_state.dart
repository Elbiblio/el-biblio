import '../domain/models/time_diagnose_models.dart';

class TimeDiagnoseState {
  final Map<TimePillar, int> allocations;
  final SpiritualGrowthLevel currentGrowth;
  final SpiritualGrowthLevel targetGrowth;

  TimeDiagnoseState({
    required this.allocations,
    required this.currentGrowth,
    required this.targetGrowth,
  });

  factory TimeDiagnoseState.initial() {
    return TimeDiagnoseState(
      allocations: {
        for (var pillar in TimePillar.values) pillar: pillar.defaultMinutes,
      },
      currentGrowth: SpiritualGrowthLevel.min15,
      targetGrowth: SpiritualGrowthLevel.hr1,
    );
  }

  int get totalMinutes => allocations.values.fold(0, (sum, minutes) => sum + minutes);

  bool get isValid24Hours => totalMinutes == 24 * 60;

  TimeDiagnoseState copyWith({
    Map<TimePillar, int>? allocations,
    SpiritualGrowthLevel? currentGrowth,
    SpiritualGrowthLevel? targetGrowth,
  }) {
    return TimeDiagnoseState(
      allocations: allocations ?? this.allocations,
      currentGrowth: currentGrowth ?? this.currentGrowth,
      targetGrowth: targetGrowth ?? this.targetGrowth,
    );
  }
}
