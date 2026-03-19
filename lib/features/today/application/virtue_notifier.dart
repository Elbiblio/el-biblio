import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/daily_anchors.dart';
import 'virtue_state.dart';

class VirtueNotifier extends StateNotifier<VirtueState> {
  VirtueNotifier(super.initialState);

  void syncFromSettings({
    required VirtueType primaryVirtue,
  }) {
    state = state.copyWith(
      primaryVirtue: primaryVirtue,
    );
  }

  void applyAssessmentScores(Map<VirtueType, int> scores) {
    if (scores.isEmpty) {
      return;
    }

    final ranked = scores.entries.toList()
      ..sort((left, right) => right.value.compareTo(left.value));

    final dominant = ranked.first.key;

    final signals = <String>[];
    final spread = ranked.first.value - ranked.last.value;
    if (spread >= 4) {
      signals.add('Strong imbalance detected between dominant and neglected virtues.');
    }
    if ((scores[VirtueType.humility] ?? 0) <= 1) {
      signals.add('Humility appears under-practiced this season.');
    }
    if ((scores[VirtueType.faith] ?? 0) <= 1) {
      signals.add('Faith confidence appears low; anchor trust in action today.');
    }

    state = state.copyWith(
      primaryVirtue: dominant,
      scores: scores,
      suggestionAccepted: false,
      imbalanceSignals: signals,
    );
  }

  void acceptSuggestion() {
    state = state.copyWith(
      suggestionAccepted: true,
      overrideReason: null,
    );
  }

  void overridePrimary(VirtueType virtue, String reason) {
    state = state.copyWith(
      primaryVirtue: virtue,
      suggestionAccepted: false,
      overrideReason: reason,
    );
  }
}
