import '../domain/vision_models.dart';

class VisionState {
  const VisionState({
    this.isLoading = false,
    this.error,
    this.visibilityMode = VisibilityMode.anonymous,
    this.visibilityAlias = 'Anonymous',
    this.primaryTribe,
    this.recommendedTribes = const [],
    this.activeCommitment,
    this.recommendedCommitments = const [],
    this.feed = const [],
    this.dailyQuestion,
    this.journeyEvents = const [],
    this.reflectionPostedToday = false,
    this.tribePulse = TribePulse.empty,
    this.hangouts = const [],
    this.weeklyReflections = const [],
    this.notifications = const [],
    this.unreadNotificationCount = 0,
  });

  final bool isLoading;
  final String? error;
  final VisibilityMode visibilityMode;
  final String visibilityAlias;
  final TribeMembership? primaryTribe;
  final List<TribeIdentity> recommendedTribes;
  final CommitmentSeason? activeCommitment;
  final List<CommitmentPlan> recommendedCommitments;
  final List<CommitmentReflection> feed;
  final DailyGrowthQuestion? dailyQuestion;
  final List<GrowthJourneyEvent> journeyEvents;
  final bool reflectionPostedToday;
  final TribePulse tribePulse;
  final List<CommitmentHangout> hangouts;
  final List<WeeklyRitualReflection> weeklyReflections;
  final List<VisionNotificationItem> notifications;
  final int unreadNotificationCount;

  VisionState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearPrimaryTribe = false,
    bool clearActiveCommitment = false,
    bool clearDailyQuestion = false,
    VisibilityMode? visibilityMode,
    String? visibilityAlias,
    TribeMembership? primaryTribe,
    List<TribeIdentity>? recommendedTribes,
    CommitmentSeason? activeCommitment,
    List<CommitmentPlan>? recommendedCommitments,
    List<CommitmentReflection>? feed,
    DailyGrowthQuestion? dailyQuestion,
    List<GrowthJourneyEvent>? journeyEvents,
    bool? reflectionPostedToday,
    TribePulse? tribePulse,
    List<CommitmentHangout>? hangouts,
    List<WeeklyRitualReflection>? weeklyReflections,
    List<VisionNotificationItem>? notifications,
    int? unreadNotificationCount,
  }) {
    return VisionState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      visibilityMode: visibilityMode ?? this.visibilityMode,
      visibilityAlias: visibilityAlias ?? this.visibilityAlias,
      primaryTribe: clearPrimaryTribe
          ? null
          : primaryTribe ?? this.primaryTribe,
      recommendedTribes: recommendedTribes ?? this.recommendedTribes,
      activeCommitment: clearActiveCommitment
          ? null
          : activeCommitment ?? this.activeCommitment,
      recommendedCommitments:
          recommendedCommitments ?? this.recommendedCommitments,
      feed: feed ?? this.feed,
      dailyQuestion: clearDailyQuestion
          ? null
          : dailyQuestion ?? this.dailyQuestion,
      journeyEvents: journeyEvents ?? this.journeyEvents,
      reflectionPostedToday:
          reflectionPostedToday ?? this.reflectionPostedToday,
      tribePulse: tribePulse ?? this.tribePulse,
      hangouts: hangouts ?? this.hangouts,
      weeklyReflections: weeklyReflections ?? this.weeklyReflections,
      notifications: notifications ?? this.notifications,
      unreadNotificationCount:
          unreadNotificationCount ?? this.unreadNotificationCount,
    );
  }
}
