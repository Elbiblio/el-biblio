import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/mood.dart';

class MoodState {
  const MoodState({
    required this.currentMood,
    required this.backgroundColors,
  });

  final Mood? currentMood;
  final List<Color> backgroundColors;

  MoodState copyWith({
    Mood? currentMood,
    List<Color>? backgroundColors,
  }) {
    return MoodState(
      currentMood: currentMood ?? this.currentMood,
      backgroundColors: backgroundColors ?? this.backgroundColors,
    );
  }

  static MoodState initial() {
    return MoodState(
      currentMood: null,
      backgroundColors: MoodType.neutral.gradientColors,
    );
  }
}

class MoodNotifier extends StateNotifier<MoodState> {
  MoodNotifier() : super(MoodState.initial());

  void setMood(MoodType moodType) {
    final mood = Mood(
      type: moodType,
      selectedAt: DateTime.now(),
    );

    state = state.copyWith(
      currentMood: mood,
      backgroundColors: moodType.gradientColors,
    );
  }

  void resetToNeutral() {
    state = state.copyWith(
      currentMood: null,
      backgroundColors: MoodType.neutral.gradientColors,
    );
  }

  TimeContext getCurrentTimeContext() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) return TimeContext.morning;
    if (hour >= 12 && hour < 18) return TimeContext.midday;
    if (hour >= 18 && hour < 22) return TimeContext.evening;
    return TimeContext.night;
  }

  String getCurrentGreeting() {
    return getCurrentTimeContext().greeting;
  }

  String getCurrentFocus() {
    return getCurrentTimeContext().focus;
  }
}

final moodProvider = StateNotifierProvider<MoodNotifier, MoodState>((ref) {
  return MoodNotifier();
});
