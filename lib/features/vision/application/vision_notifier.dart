import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/notifications/notification_service.dart';
import '../data/vision_repository.dart';
import '../domain/vision_models.dart';
import 'vision_state.dart';

class VisionNotifier extends StateNotifier<VisionState> {
  VisionNotifier(
    this._repository,
    this._notificationService, {
    List<String> Function()? topArchetypes,
    Future<void> Function({
      required int commitmentId,
      String? when,
      String? obstacle,
    })?
    saveFirstCheckInPlan,
    CommitmentPlanContext Function(int commitmentId)? localPlanContext,
  }) : _topArchetypes = topArchetypes ?? (() => const <String>[]),
       _saveFirstCheckInPlan = saveFirstCheckInPlan,
       _localPlanContext = localPlanContext,
       super(const VisionState()) {
    _notificationService.setDailyCheckInActionHandler(() async {
      final completed = await checkIn();
      if (!completed) {
        throw StateError('No active commitment check-in was completed.');
      }
    });
  }

  final VisionRepository _repository;
  final NotificationService _notificationService;
  final List<String> Function() _topArchetypes;
  final Future<void> Function({
    required int commitmentId,
    String? when,
    String? obstacle,
  })?
  _saveFirstCheckInPlan;
  final CommitmentPlanContext Function(int commitmentId)? _localPlanContext;

  @override
  void dispose() {
    _notificationService.setDailyCheckInActionHandler(null);
    super.dispose();
  }

  Future<void> load({bool force = false}) async {
    if (!force &&
        !state.isLoading &&
        (state.primaryTribe != null ||
            state.activeCommitment != null ||
            state.recommendedTribes.isNotEmpty ||
            state.recommendedCommitments.isNotEmpty)) {
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final bootstrap = await _repository.bootstrap();
      final readOnly = bootstrap.dataSource.isReadOnly;
      final tribes = readOnly
          ? const <TribeIdentity>[]
          : await _repository.recommendedTribes(archetypes: _topArchetypes());
      final commitments = readOnly
          ? const <CommitmentPlan>[]
          : await _repository.recommendedCommitments(
              tribeId: bootstrap.primaryTribe?.tribe.id,
            );
      final feedResult = bootstrap.activeCommitment == null
          ? const CommitmentFeedResult(reflections: [], postedToday: false)
          : await _repository.feed(bootstrap.activeCommitment!.plan.id);
      final tribePulse = bootstrap.primaryTribe == null
          ? TribePulse.empty
          : await _repository.tribePulse(bootstrap.primaryTribe!.tribe.id);
      final weeklyReflections = bootstrap.primaryTribe == null
          ? const <WeeklyRitualReflection>[]
          : await _repository.weeklyRitual(bootstrap.primaryTribe!.tribe.id);
      final hangouts = await _repository.visibleHangouts();
      final notifications = await _repository.notifications();
      final unreadNotificationCount = notifications
          .where((item) => !item.read)
          .length;

      state = state.copyWith(
        isLoading: false,
        visibilityMode: bootstrap.visibilityMode,
        visibilityAlias: bootstrap.visibilityAlias,
        primaryTribe: bootstrap.primaryTribe,
        clearPrimaryTribe: bootstrap.primaryTribe == null,
        activeCommitment: bootstrap.activeCommitment,
        clearActiveCommitment: bootstrap.activeCommitment == null,
        recommendedTribes: tribes,
        recommendedCommitments: commitments,
        feed: feedResult.reflections,
        dailyQuestion: bootstrap.dailyQuestion,
        clearDailyQuestion: bootstrap.dailyQuestion == null,
        tribePulse: tribePulse,
        weeklyReflections: weeklyReflections,
        hangouts: hangouts,
        notifications: notifications,
        unreadNotificationCount: unreadNotificationCount,
        journeyEvents: bootstrap.journeyEvents,
        reflectionPostedToday: feedResult.postedToday,
        dataSource: bootstrap.dataSource,
        error: bootstrap.errorMessage ?? feedResult.errorMessage,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> setVisibility(VisibilityMode mode, {String? alias}) async {
    try {
      await _repository.updateVisibility(visibilityMode: mode, alias: alias);
      state = state.copyWith(
        visibilityMode: mode,
        visibilityAlias: _aliasFor(mode, alias),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> joinTribe(TribeIdentity tribe) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final membership = await _repository.joinTribe(
        tribeId: tribe.id,
        visibilityMode: state.visibilityMode,
        displayAlias: state.visibilityAlias,
      );
      if (state.isReadOnly) {
        state = state.copyWith(
          isLoading: false,
          error:
              'Reconnect before joining a tribe. Offline recommendations are read-only.',
        );
        return false;
      }
      final commitments = await _repository.recommendedCommitments(
        tribeId: tribe.id,
      );
      state = state.copyWith(
        isLoading: false,
        primaryTribe: membership,
        recommendedCommitments: commitments,
        tribePulse: await _repository.tribePulse(tribe.id),
        weeklyReflections: await _repository.weeklyRitual(tribe.id),
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> joinCommitment(
    CommitmentPlan plan,
    int nudges, {
    String? planWhen,
    String? planObstacle,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (state.isReadOnly) {
        state = state.copyWith(
          isLoading: false,
          error:
              'Reconnect before starting a commitment. Offline recommendations are read-only.',
        );
        return false;
      }
      final membership = await _repository.joinCommitment(
        commitmentId: plan.id,
        nudgeCount: nudges,
        planWhen: planWhen,
        planObstacle: planObstacle,
      );
      await _saveFirstCheckInPlan?.call(
        commitmentId: membership.plan.id,
        when: membership.firstCheckInPlanWhen ?? planWhen,
        obstacle: membership.firstCheckInPlanObstacle ?? planObstacle,
      );
      String? notificationWarning;
      try {
        final scheduled = await _notificationService.scheduleCommitmentNudges(
          commitmentId: membership.plan.id,
          commitmentTitle: membership.plan.title,
          dailyAction: membership.plan.dailyAction,
          nudgeCount: membership.nudgeCountPerDay,
          planWhen: membership.firstCheckInPlanWhen ?? planWhen,
          planObstacle: membership.firstCheckInPlanObstacle ?? planObstacle,
        );
        if (!scheduled) {
          notificationWarning =
              'Commitment joined, but device nudges could not be scheduled. You can still check in from the app.';
        }
      } catch (e) {
        notificationWarning =
            'Commitment joined, but device nudges could not be scheduled. You can still check in from the app.';
      }
      state = state.copyWith(
        isLoading: false,
        activeCommitment: membership,
        feed: const [],
        hangouts: await _repository.visibleHangouts(),
        notificationWarning: notificationWarning,
        clearNotificationWarning: notificationWarning == null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateNudges(int nudgeCount) async {
    final active = state.activeCommitment;
    if (active == null) return false;

    try {
      final membership = await _repository.updateNudges(
        commitmentId: active.plan.id,
        nudgeCount: nudgeCount,
      );
      final localContext = _localPlanContext?.call(membership.plan.id);
      final scheduled = await _notificationService.scheduleCommitmentNudges(
        commitmentId: membership.plan.id,
        commitmentTitle: membership.plan.title,
        dailyAction: membership.plan.dailyAction,
        nudgeCount: membership.nudgeCountPerDay,
        planWhen: membership.firstCheckInPlanWhen ?? localContext?.when,
        planObstacle:
            membership.firstCheckInPlanObstacle ?? localContext?.obstacle,
      );
      state = state.copyWith(
        activeCommitment: membership,
        notificationWarning: scheduled
            ? null
            : 'Nudge settings saved, but device notifications could not be scheduled.',
        clearNotificationWarning: scheduled,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> checkIn() async {
    final active = state.activeCommitment;
    if (active == null) return false;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final membership = await _repository.checkIn(
        commitmentId: active.plan.id,
      );
      try {
        final localContext = _localPlanContext?.call(membership.plan.id);
        final scheduled = await _notificationService.scheduleCommitmentNudges(
          commitmentId: membership.plan.id,
          commitmentTitle: membership.plan.title,
          dailyAction: membership.plan.dailyAction,
          nudgeCount: membership.nudgeCountPerDay,
          startTomorrow: true,
          planWhen: membership.firstCheckInPlanWhen ?? localContext?.when,
          planObstacle:
              membership.firstCheckInPlanObstacle ?? localContext?.obstacle,
        );
        if (!scheduled) {
          state = state.copyWith(
            notificationWarning:
                'Checked in, but tomorrow\'s nudges could not be refreshed.',
          );
        }
      } catch (_) {
        state = state.copyWith(
          notificationWarning:
              'Checked in, but tomorrow\'s nudges could not be refreshed.',
        );
      }
      state = state.copyWith(isLoading: false, activeCommitment: membership);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> refreshFeed() async {
    final active = state.activeCommitment;
    if (active == null) return;
    final feed = await _repository.feed(active.plan.id);
    state = state.copyWith(
      feed: feed.reflections,
      reflectionPostedToday: feed.postedToday,
      error: feed.errorMessage,
      clearError: feed.errorMessage == null,
    );
  }

  Future<bool> postReflection(String content) async {
    final active = state.activeCommitment;
    final trimmed = content.trim();
    if (active == null || trimmed.isEmpty || trimmed.length > 500) {
      return false;
    }

    try {
      final reflection = await _repository.postReflection(
        commitmentId: active.plan.id,
        content: trimmed,
        alias: state.visibilityAlias,
      );
      state = state.copyWith(
        feed: [reflection, ...state.feed],
        reflectionPostedToday: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> postWeeklyReflection(String content) async {
    final tribe = state.primaryTribe?.tribe;
    if (tribe == null || content.trim().isEmpty || content.length > 500) {
      return false;
    }

    try {
      final reflection = await _repository.postWeeklyRitual(
        tribeId: tribe.id,
        content: content.trim(),
      );
      state = state.copyWith(
        weeklyReflections: [reflection, ...state.weeklyReflections],
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<void> setWeeklyBookmark(
    WeeklyRitualReflection reflection,
    bool bookmarked,
  ) async {
    try {
      final updated = await _repository.setWeeklyBookmark(
        reflectionId: reflection.id,
        bookmarked: bookmarked,
      );
      state = state.copyWith(
        weeklyReflections: state.weeklyReflections
            .map((item) => item.id == updated.id ? updated : item)
            .toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<CommitmentHangout?> createCommitmentHangout({
    required String title,
    required String scopeType,
    int? scopeId,
    required int maxParticipants,
  }) async {
    if (title.trim().isEmpty) return null;

    try {
      final hangout = await _repository.createHangout(
        title: title,
        scopeType: scopeType,
        scopeId: scopeId,
        maxParticipants: maxParticipants,
      );
      state = state.copyWith(hangouts: [hangout, ...state.hangouts]);
      return hangout;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<CommitmentHangout?> joinHangout(CommitmentHangout hangout) async {
    try {
      final updated = await _repository.joinHangout(hangout.id);
      state = state.copyWith(
        hangouts: state.hangouts
            .map((item) => item.id == updated.id ? updated : item)
            .toList(),
      );
      return updated;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<void> leaveHangout(int hangoutId) async {
    try {
      final updated = await _repository.leaveHangout(hangoutId);
      state = state.copyWith(
        hangouts: updated.status == 'ended'
            ? state.hangouts.where((item) => item.id != updated.id).toList()
            : state.hangouts
                  .map((item) => item.id == updated.id ? updated : item)
                  .toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> loadNotifications() async {
    final notifications = await _repository.notifications();
    state = state.copyWith(
      notifications: notifications,
      unreadNotificationCount: notifications.where((item) => !item.read).length,
    );
  }

  Future<void> markNotificationRead(VisionNotificationItem item) async {
    if (!item.read) {
      await _repository.markNotificationRead(item.id);
    }
    state = state.copyWith(
      notifications: state.notifications
          .map(
            (notification) => notification.id == item.id
                ? VisionNotificationItem(
                    id: notification.id,
                    kind: notification.kind,
                    title: notification.title,
                    body: notification.body,
                    createdAt: notification.createdAt,
                    read: true,
                    actionLabel: notification.actionLabel,
                    route: notification.route,
                    iconKey: notification.iconKey,
                    hangoutId: notification.hangoutId,
                    commitmentId: notification.commitmentId,
                    reflectionId: notification.reflectionId,
                  )
                : notification,
          )
          .toList(),
      unreadNotificationCount:
          (state.unreadNotificationCount - (item.read ? 0 : 1))
              .clamp(0, 999)
              .toInt(),
    );
  }

  Future<void> markAllNotificationsRead() async {
    await _repository.markAllNotificationsRead();
    await loadNotifications();
  }

  Future<bool> answerDailyQuestion(
    String answer, {
    DailyGrowthQuestion? selectedQuestion,
  }) async {
    final question = state.dailyQuestion;
    final target = selectedQuestion ?? question;
    if (question == null || target == null || answer.trim().isEmpty) {
      return false;
    }

    try {
      await _repository.answerDailyQuestion(
        questionId: target.id,
        answer: answer,
      );
      final updatedPack = question.packQuestions
          .map(
            (item) => item.id == target.id
                ? item.copyWith(answer: answer.trim(), answeredToday: true)
                : item,
          )
          .toList();
      state = state.copyWith(
        dailyQuestion: (question.id == target.id ? target : question).copyWith(
          answer: question.id == target.id ? answer.trim() : question.answer,
          answeredToday: question.id == target.id
              ? true
              : question.answeredToday,
          packQuestions: updatedPack,
        ),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> reactToReflection(
    CommitmentReflection reflection,
    String reactionType,
  ) async {
    try {
      await _repository.reactToReflection(
        reflectionId: reflection.id,
        reactionType: reactionType,
      );
      await refreshFeed();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> reportReflection(
    CommitmentReflection reflection,
    String reason,
  ) async {
    final normalized = reason.trim();
    if (normalized.isEmpty) return false;
    try {
      await _repository.reportReflection(
        reflectionId: reflection.id,
        reason: normalized,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> reportHangout(CommitmentHangout hangout, String reason) async {
    final normalized = reason.trim();
    if (normalized.isEmpty) return false;
    try {
      await _repository.reportHangout(
        hangoutId: hangout.id,
        reason: normalized,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  String _aliasFor(VisibilityMode mode, String? alias) {
    return switch (mode) {
      VisibilityMode.public =>
        alias?.trim().isNotEmpty == true ? alias!.trim() : 'Visible profile',
      VisibilityMode.nickname =>
        alias?.trim().isNotEmpty == true ? alias!.trim() : 'Friend',
      VisibilityMode.initials =>
        alias?.trim().isNotEmpty == true ? alias!.trim() : 'EB',
      VisibilityMode.anonymous => 'Anonymous',
    };
  }
}
