import '../domain/mvp_models.dart';

class MvpState {
  const MvpState({
    this.isLoading = false,
    this.error,
    this.visibilityMode = MvpVisibilityMode.anonymous,
    this.visibilityAlias = 'Anonymous',
    this.primaryTribe,
    this.recommendedTribes = const [],
    this.activeCommitment,
    this.recommendedCommitments = const [],
    this.feed = const [],
    this.dailyQuestion,
    this.milestones = const [],
    this.reflectionPostedToday = false,
  });

  final bool isLoading;
  final String? error;
  final MvpVisibilityMode visibilityMode;
  final String visibilityAlias;
  final MvpTribeMembership? primaryTribe;
  final List<MvpTribe> recommendedTribes;
  final MvpCommitmentMembership? activeCommitment;
  final List<MvpCommitmentChallenge> recommendedCommitments;
  final List<MvpReflection> feed;
  final MvpDailyFaithQuestion? dailyQuestion;
  final List<MilestoneEvent> milestones;
  final bool reflectionPostedToday;

  MvpState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    MvpVisibilityMode? visibilityMode,
    String? visibilityAlias,
    MvpTribeMembership? primaryTribe,
    List<MvpTribe>? recommendedTribes,
    MvpCommitmentMembership? activeCommitment,
    List<MvpCommitmentChallenge>? recommendedCommitments,
    List<MvpReflection>? feed,
    MvpDailyFaithQuestion? dailyQuestion,
    List<MilestoneEvent>? milestones,
    bool? reflectionPostedToday,
  }) {
    return MvpState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      visibilityMode: visibilityMode ?? this.visibilityMode,
      visibilityAlias: visibilityAlias ?? this.visibilityAlias,
      primaryTribe: primaryTribe ?? this.primaryTribe,
      recommendedTribes: recommendedTribes ?? this.recommendedTribes,
      activeCommitment: activeCommitment ?? this.activeCommitment,
      recommendedCommitments:
          recommendedCommitments ?? this.recommendedCommitments,
      feed: feed ?? this.feed,
      dailyQuestion: dailyQuestion ?? this.dailyQuestion,
      milestones: milestones ?? this.milestones,
      reflectionPostedToday:
          reflectionPostedToday ?? this.reflectionPostedToday,
    );
  }
}
