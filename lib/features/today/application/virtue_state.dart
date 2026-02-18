import '../domain/models/daily_anchors.dart';

class VirtueState {
  const VirtueState({
    required this.primaryVirtue,
    required this.neglectedVirtue,
    required this.scores,
    required this.suggestionAccepted,
    required this.overrideReason,
    required this.imbalanceSignals,
  });

  final VirtueType primaryVirtue;
  final VirtueType neglectedVirtue;
  final Map<VirtueType, int> scores;
  final bool suggestionAccepted;
  final String? overrideReason;
  final List<String> imbalanceSignals;

  factory VirtueState.initial({
    required VirtueType primaryVirtue,
    required VirtueType neglectedVirtue,
  }) {
    return VirtueState(
      primaryVirtue: primaryVirtue,
      neglectedVirtue: neglectedVirtue,
      scores: const <VirtueType, int>{},
      suggestionAccepted: true,
      overrideReason: null,
      imbalanceSignals: const <String>[],
    );
  }

  VirtueState copyWith({
    VirtueType? primaryVirtue,
    VirtueType? neglectedVirtue,
    Map<VirtueType, int>? scores,
    bool? suggestionAccepted,
    String? overrideReason,
    List<String>? imbalanceSignals,
  }) {
    return VirtueState(
      primaryVirtue: primaryVirtue ?? this.primaryVirtue,
      neglectedVirtue: neglectedVirtue ?? this.neglectedVirtue,
      scores: scores ?? this.scores,
      suggestionAccepted: suggestionAccepted ?? this.suggestionAccepted,
      overrideReason: overrideReason ?? this.overrideReason,
      imbalanceSignals: imbalanceSignals ?? this.imbalanceSignals,
    );
  }
}
