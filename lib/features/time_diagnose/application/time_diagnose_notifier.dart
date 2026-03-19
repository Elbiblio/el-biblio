import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/time_diagnose_models.dart';
import 'time_diagnose_state.dart';

class TimeDiagnoseNotifier extends Notifier<TimeDiagnoseState> {
  @override
  TimeDiagnoseState build() {
    return TimeDiagnoseState.initial();
  }

  void updateAllocation(TimePillar pillar, int newMinutes) {
    if (newMinutes < 0) return;
    
    final newAllocations = Map<TimePillar, int>.from(state.allocations);
    newAllocations[pillar] = newMinutes;
    
    state = state.copyWith(allocations: newAllocations);
  }

  void incrementAllocation(TimePillar pillar, {int amount = 15}) {
    updateAllocation(pillar, (state.allocations[pillar] ?? 0) + amount);
  }

  void decrementAllocation(TimePillar pillar, {int amount = 15}) {
    updateAllocation(pillar, (state.allocations[pillar] ?? 0) - amount);
  }

  void setCurrentGrowth(SpiritualGrowthLevel level) {
    state = state.copyWith(currentGrowth: level);
  }

  void setTargetGrowth(SpiritualGrowthLevel level) {
    state = state.copyWith(targetGrowth: level);
  }
}

final timeDiagnoseProvider = NotifierProvider<TimeDiagnoseNotifier, TimeDiagnoseState>(() {
  return TimeDiagnoseNotifier();
});
