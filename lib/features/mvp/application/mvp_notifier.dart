import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mvp_repository.dart';
import '../domain/mvp_models.dart';
import 'mvp_state.dart';
import '../../../core/services/notifications/notification_service.dart';

class MvpNotifier extends StateNotifier<MvpState> {
  MvpNotifier(this._repository, this._notificationService)
    : super(const MvpState());

  final MvpRepository _repository;
  final NotificationService _notificationService;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final bootstrap = await _repository.bootstrap();
      final tribes = await _repository.recommendedTribes();
      final commitments = await _repository.recommendedCommitments(
        tribeId: bootstrap.primaryTribe?.tribe.id,
      );
      final feed = bootstrap.activeCommitment == null
          ? const <MvpReflection>[]
          : await _repository.feed(bootstrap.activeCommitment!.challenge.id);

      state = state.copyWith(
        isLoading: false,
        visibilityMode: bootstrap.visibilityMode,
        visibilityAlias: bootstrap.visibilityAlias,
        primaryTribe: bootstrap.primaryTribe,
        activeCommitment: bootstrap.activeCommitment,
        recommendedTribes: tribes,
        recommendedCommitments: commitments,
        feed: feed,
        dailyQuestion: bootstrap.dailyQuestion,
        milestones: _buildMilestones(
          bootstrap.primaryTribe,
          bootstrap.activeCommitment,
        ),
        reflectionPostedToday: _hasPostedToday(feed),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> setVisibility(MvpVisibilityMode mode, {String? alias}) async {
    await _repository.updateVisibility(visibilityMode: mode, alias: alias);
    state = state.copyWith(
      visibilityMode: mode,
      visibilityAlias: _aliasFor(mode, alias),
    );
  }

  Future<void> joinTribe(MvpTribe tribe) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final membership = await _repository.joinTribe(
        tribeId: tribe.id,
        visibilityMode: state.visibilityMode,
        displayAlias: state.visibilityAlias,
      );
      final commitments = await _repository.recommendedCommitments(
        tribeId: tribe.id,
      );
      state = state.copyWith(
        isLoading: false,
        primaryTribe: membership,
        recommendedCommitments: commitments,
        milestones: _buildMilestones(membership, state.activeCommitment),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> joinCommitment(
    MvpCommitmentChallenge challenge,
    int nudges,
  ) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final membership = await _repository.joinCommitment(
        commitmentId: challenge.id,
        nudgeCount: nudges,
      );
      await _notificationService.scheduleCommitmentNudges(
        commitmentId: membership.challenge.id,
        commitmentTitle: membership.challenge.title,
        dailyAction: membership.challenge.dailyAction,
        nudgeCount: membership.nudgeCountPerDay,
      );
      state = state.copyWith(
        isLoading: false,
        activeCommitment: membership,
        feed: const [],
        milestones: _buildMilestones(state.primaryTribe, membership),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> checkIn() async {
    final active = state.activeCommitment;
    if (active == null) return;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final membership = await _repository.checkIn(
        commitmentId: active.challenge.id,
      );
      state = state.copyWith(
        isLoading: false,
        activeCommitment: membership,
        milestones: _buildMilestones(state.primaryTribe, membership),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refreshFeed() async {
    final active = state.activeCommitment;
    if (active == null) return;
    final feed = await _repository.feed(active.challenge.id);
    state = state.copyWith(
      feed: feed,
      reflectionPostedToday: _hasPostedToday(feed),
    );
  }

  Future<void> postReflection(String content) async {
    final active = state.activeCommitment;
    if (active == null || content.trim().isEmpty || content.length > 500) {
      return;
    }

    final reflection = await _repository.postReflection(
      commitmentId: active.challenge.id,
      content: content.trim(),
      alias: state.visibilityAlias,
    );
    state = state.copyWith(
      feed: [reflection, ...state.feed],
      reflectionPostedToday: true,
    );
  }

  Future<void> reactToReflection(
    MvpReflection reflection,
    String reactionType,
  ) async {
    await _repository.reactToReflection(
      reflectionId: reflection.id,
      reactionType: reactionType,
    );
    await refreshFeed();
  }

  List<MilestoneEvent> _buildMilestones(
    MvpTribeMembership? tribe,
    MvpCommitmentMembership? commitment,
  ) {
    final now = DateTime.now();
    return [
      MilestoneEvent(
        type: MilestoneEventType.compassComplete,
        title: MilestoneEventType.compassComplete.title,
        subtitle: MilestoneEventType.compassComplete.subtitle,
        occurredAt: now,
        iconKey: MilestoneEventType.compassComplete.iconKey,
      ),
      if (tribe != null)
        MilestoneEvent(
          type: MilestoneEventType.tribeJoined,
          title: MilestoneEventType.tribeJoined.title,
          subtitle: tribe.tribe.name,
          occurredAt: now,
          iconKey: MilestoneEventType.tribeJoined.iconKey,
        ),
      if (commitment != null)
        MilestoneEvent(
          type: MilestoneEventType.commitmentJoined,
          title: MilestoneEventType.commitmentJoined.title,
          subtitle: commitment.challenge.title,
          occurredAt: now,
          iconKey: MilestoneEventType.commitmentJoined.iconKey,
        ),
      if (commitment?.checkedInToday ?? false)
        MilestoneEvent(
          type: MilestoneEventType.dailyCommitmentComplete,
          title: MilestoneEventType.dailyCommitmentComplete.title,
          subtitle: MilestoneEventType.dailyCommitmentComplete.subtitle,
          occurredAt: now,
          iconKey: MilestoneEventType.dailyCommitmentComplete.iconKey,
        ),
    ];
  }

  bool _hasPostedToday(List<MvpReflection> feed) {
    final now = DateTime.now();
    return feed.any(
      (item) =>
          item.alias == state.visibilityAlias &&
          item.createdAt.year == now.year &&
          item.createdAt.month == now.month &&
          item.createdAt.day == now.day,
    );
  }

  String _aliasFor(MvpVisibilityMode mode, String? alias) {
    return switch (mode) {
      MvpVisibilityMode.public =>
        alias?.trim().isNotEmpty == true ? alias!.trim() : 'Public profile',
      MvpVisibilityMode.nickname =>
        alias?.trim().isNotEmpty == true ? alias!.trim() : 'Friend',
      MvpVisibilityMode.initials =>
        alias?.trim().isNotEmpty == true ? alias!.trim() : 'EB',
      MvpVisibilityMode.anonymous => 'Anonymous',
    };
  }
}
