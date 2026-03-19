import '../domain/models/daily_anchors.dart';

class VirtueState {
  const VirtueState({
    required this.primaryVirtue,
    required this.scores,
    required this.suggestionAccepted,
    required this.overrideReason,
    required this.imbalanceSignals,
  });

  final VirtueType primaryVirtue;
  final Map<VirtueType, int> scores;
  final bool suggestionAccepted;
  final String? overrideReason;
  final List<String> imbalanceSignals;

  factory VirtueState.initial({
    required VirtueType primaryVirtue,
  }) {
    return VirtueState(
      primaryVirtue: primaryVirtue,
      scores: const <VirtueType, int>{},
      suggestionAccepted: true,
      overrideReason: null,
      imbalanceSignals: const <String>[],
    );
  }

  VirtueState copyWith({
    VirtueType? primaryVirtue,
    Map<VirtueType, int>? scores,
    bool? suggestionAccepted,
    String? overrideReason,
    List<String>? imbalanceSignals,
  }) {
    return VirtueState(
      primaryVirtue: primaryVirtue ?? this.primaryVirtue,
      scores: scores ?? this.scores,
      suggestionAccepted: suggestionAccepted ?? this.suggestionAccepted,
      overrideReason: overrideReason ?? this.overrideReason,
      imbalanceSignals: imbalanceSignals ?? this.imbalanceSignals,
    );
  }
}
