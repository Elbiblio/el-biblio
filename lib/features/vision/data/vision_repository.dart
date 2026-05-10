import 'package:logger/logger.dart';

import '../../../core/network/dio_client.dart';
import '../domain/vision_models.dart';

class VisionRepository {
  VisionRepository(this._dio, this._logger);

  final DioClient _dio;
  final Logger _logger;

  Future<VisionBootstrap> bootstrap() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/vision/bootstrap',
      );
      return _parseBootstrap(
        _payloadMap(response.data),
        dataSource: VisionDataSource.remote,
      );
    } catch (_) {
      try {
        final response = await _dio.get<Map<String, dynamic>>('/mvp/bootstrap');
        return _parseBootstrap(
          _payloadMap(response.data),
          dataSource: VisionDataSource.compatibility,
        );
      } catch (e, st) {
        _logger.w(
          'Vision bootstrap failed, entering read-only error state',
          error: e,
          stackTrace: st,
        );
        return VisionBootstrap(
          visibilityMode: VisibilityMode.anonymous,
          visibilityAlias: 'Anonymous',
          primaryTribe: null,
          activeCommitment: null,
          dailyQuestion: null,
          journeyEvents: const [],
          dataSource: VisionDataSource.error,
          errorMessage: _friendlyError(e),
        );
      }
    }
  }

  Future<List<TribeIdentity>> recommendedTribes({
    List<String> archetypes = const [],
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/tribes/recommended',
        queryParameters: {if (archetypes.isNotEmpty) 'archetypes': archetypes},
      );
      final list = _payloadList(response.data);
      final tribes = list
          .whereType<Map>()
          .map(
            (item) => TribeIdentity.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
      return tribes;
    } catch (e) {
      _logger.w('Vision recommended tribes failed: $e');
      rethrow;
    }
  }

  Future<TribeMembership> joinTribe({
    required int tribeId,
    required VisibilityMode visibilityMode,
    String? displayAlias,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/tribes/$tribeId/join',
      data: {
        'visibility_mode': visibilityMode.value,
        if (displayAlias != null && displayAlias.trim().isNotEmpty)
          'display_alias': displayAlias.trim(),
        'is_primary': true,
      },
    );
    return TribeMembership.fromJson(_payloadMap(response.data));
  }

  Future<void> updateVisibility({
    required VisibilityMode visibilityMode,
    String? alias,
  }) async {
    await _dio.put<Map<String, dynamic>>(
      '/users/me/visibility',
      data: {
        'visibility_mode': visibilityMode.value,
        if (alias != null && alias.trim().isNotEmpty)
          'visibility_alias': alias.trim(),
      },
    );
  }

  Future<List<CommitmentPlan>> recommendedCommitments({int? tribeId}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/commitments/recommended',
        queryParameters: {if (tribeId != null) 'tribe_id': tribeId},
      );
      final list = _payloadList(response.data);
      final commitments = list
          .whereType<Map>()
          .map(
            (item) => CommitmentPlan.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
      return commitments;
    } catch (e) {
      _logger.w('Vision recommended commitments failed: $e');
      rethrow;
    }
  }

  Future<CommitmentSeason> joinCommitment({
    required int commitmentId,
    required int nudgeCount,
    String? planWhen,
    String? planObstacle,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/commitments/$commitmentId/join',
      data: {
        'nudge_count_per_day': nudgeCount,
        if (planWhen != null && planWhen.trim().isNotEmpty)
          'check_in_plan_when': planWhen.trim(),
        if (planObstacle != null && planObstacle.trim().isNotEmpty)
          'check_in_plan_obstacle': planObstacle.trim(),
      },
    );
    return CommitmentSeason.fromJson(_payloadMap(response.data));
  }

  Future<CommitmentSeason> updateNudges({
    required int commitmentId,
    required int nudgeCount,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/commitments/$commitmentId/nudges',
      data: {'nudge_count_per_day': nudgeCount},
    );
    return CommitmentSeason.fromJson(_payloadMap(response.data));
  }

  Future<CommitmentSeason> checkIn({
    required int commitmentId,
    String? note,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/commitments/$commitmentId/check-ins',
      data: {
        'completed': true,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
    );
    final data = _payloadMap(response.data);
    return CommitmentSeason.fromJson(
      Map<String, dynamic>.from(data['membership'] as Map? ?? const {}),
    );
  }

  Future<CommitmentFeedResult> feed(int commitmentId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/commitments/$commitmentId/feed',
      );
      final data = _payload(response.data);
      final list = data is Map && data['data'] is List
          ? data['data'] as List<dynamic>
          : data is List
          ? data
          : const <dynamic>[];
      return CommitmentFeedResult(
        reflections: list
            .whereType<Map>()
            .map(
              (item) => CommitmentReflection.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList(),
        postedToday: data is Map ? _postedTodayFromFeed(data) : false,
      );
    } catch (e) {
      _logger.w('Vision feed failed: $e');
      return const CommitmentFeedResult(reflections: [], postedToday: false);
    }
  }

  Future<CommitmentReflection> postReflection({
    required int commitmentId,
    required String content,
    required String alias,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/commitments/$commitmentId/reflections',
      data: {'content': content, 'visibility_alias': alias},
    );
    return CommitmentReflection.fromJson(_payloadMap(response.data));
  }

  Future<List<WeeklyRitualReflection>> weeklyRitual(int tribeId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/tribes/$tribeId/weekly-ritual',
      );
      final data = _payload(response.data);
      final list = data is Map && data['data'] is List
          ? data['data'] as List<dynamic>
          : data is List
          ? data
          : const <dynamic>[];
      return list
          .whereType<Map>()
          .map(
            (item) => WeeklyRitualReflection.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } catch (e) {
      _logger.w('Vision weekly ritual failed: $e');
      return const [];
    }
  }

  Future<WeeklyRitualReflection> postWeeklyRitual({
    required int tribeId,
    required String content,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/tribes/$tribeId/weekly-ritual',
      data: {'content': content.trim()},
    );
    return WeeklyRitualReflection.fromJson(_payloadMap(response.data));
  }

  Future<WeeklyRitualReflection> setWeeklyBookmark({
    required int reflectionId,
    required bool bookmarked,
  }) async {
    final response = bookmarked
        ? await _dio.post<Map<String, dynamic>>(
            '/weekly-ritual/$reflectionId/bookmark',
          )
        : await _dio.delete<Map<String, dynamic>>(
            '/weekly-ritual/$reflectionId/bookmark',
          );
    return WeeklyRitualReflection.fromJson(_payloadMap(response.data));
  }

  Future<void> reactToReflection({
    required int reflectionId,
    required String reactionType,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/reflections/$reflectionId/reactions',
      data: {'reaction_type': reactionType},
    );
  }

  Future<void> reportReflection({
    required int reflectionId,
    required String reason,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/reflections/$reflectionId/report',
      data: {'reason': reason.trim()},
    );
  }

  Future<void> reportHangout({
    required int hangoutId,
    required String reason,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/hangouts/$hangoutId/report',
      data: {'reason': reason.trim()},
    );
  }

  Future<List<VisionNotificationItem>> notifications() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/notifications/user',
        queryParameters: {'per_page': 30},
      );
      final data = _payload(response.data);
      final list = data is Map && data['data'] is List
          ? data['data'] as List<dynamic>
          : data is List
          ? data
          : const <dynamic>[];
      return list
          .whereType<Map>()
          .map(
            (item) => VisionNotificationItem.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } catch (e) {
      _logger.w('Vision notifications failed: $e');
      return const [];
    }
  }

  Future<int> unreadNotificationCount() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/notifications/unread-count',
      );
      final data = _payloadMap(response.data);
      return (data['count'] as num?)?.toInt() ?? 0;
    } catch (e) {
      _logger.w('Vision unread notification count failed: $e');
      return 0;
    }
  }

  Future<void> markNotificationRead(int notificationId) async {
    await _dio.post<Map<String, dynamic>>(
      '/notifications/$notificationId/read',
    );
  }

  Future<void> markAllNotificationsRead() async {
    await _dio.post<Map<String, dynamic>>('/notifications/mark-all-read');
  }

  Future<void> answerDailyQuestion({
    required int questionId,
    required String answer,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/faith-questions/$questionId/answer',
      data: {'answer': answer.trim()},
    );
  }

  Future<DailyGrowthQuestion> todayQuestion() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/faith-questions/today',
    );
    return DailyGrowthQuestion.fromJson(_payloadMap(response.data));
  }

  Future<TribePulse> tribePulse(int tribeId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/tribes/$tribeId/pulse',
      );
      return TribePulse.fromJson(_payloadMap(response.data));
    } catch (e) {
      _logger.w('Vision tribe pulse failed: $e');
      return TribePulse.empty;
    }
  }

  Future<List<CommitmentHangout>> commitmentHangouts(int commitmentId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/commitments/$commitmentId/hangouts',
      );
      final list = _payloadList(response.data);
      return list
          .whereType<Map>()
          .map(
            (item) =>
                CommitmentHangout.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (e) {
      _logger.w('Vision commitment hangouts failed: $e');
      return const [];
    }
  }

  Future<List<CommitmentHangout>> visibleHangouts() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/hangouts');
      final list = _payloadList(response.data);
      return list
          .whereType<Map>()
          .map(
            (item) =>
                CommitmentHangout.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (e) {
      _logger.w('Vision visible hangouts failed: $e');
      return const [];
    }
  }

  Future<CommitmentHangout> createHangout({
    required String title,
    required String scopeType,
    int? scopeId,
    required int maxParticipants,
    bool startNow = true,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/hangouts',
      data: {
        'title': title.trim(),
        'scope_type': scopeType,
        if (scopeId != null) 'scope_id': scopeId,
        'max_participants': maxParticipants,
        'start_now': startNow,
      },
    );
    return CommitmentHangout.fromJson(_payloadMap(response.data));
  }

  Future<CommitmentHangout> joinHangout(int hangoutId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/hangouts/$hangoutId/join',
    );
    return CommitmentHangout.fromJson(_payloadMap(response.data));
  }

  Future<CommitmentHangout> leaveHangout(int hangoutId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/hangouts/$hangoutId/leave',
    );
    return CommitmentHangout.fromJson(_payloadMap(response.data));
  }

  VisionBootstrap _parseBootstrap(
    Map<String, dynamic> data, {
    required VisionDataSource dataSource,
  }) {
    final user = Map<String, dynamic>.from(data['user'] as Map? ?? const {});
    final activeRaw = data['active_commitment'];
    final activeList =
        (data['active_commitments'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map(
              (item) =>
                  CommitmentSeason.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
    final tribeRaw = data['primary_tribe'];

    return VisionBootstrap(
      visibilityMode: VisibilityMode.fromValue(
        user['visibility_mode'] as String?,
      ),
      visibilityAlias: user['visibility_alias'] as String? ?? 'Anonymous',
      primaryTribe: tribeRaw is Map
          ? TribeMembership.fromJson(Map<String, dynamic>.from(tribeRaw))
          : null,
      activeCommitment: activeRaw is Map
          ? CommitmentSeason.fromJson(Map<String, dynamic>.from(activeRaw))
          : activeList.isNotEmpty
          ? activeList.first
          : null,
      dailyQuestion: data['today_faith_question'] is Map
          ? DailyGrowthQuestion.fromJson(
              Map<String, dynamic>.from(data['today_faith_question'] as Map),
            )
          : data['daily_spiritual_insight'] is Map
          ? DailyGrowthQuestion.fromJson(
              Map<String, dynamic>.from(data['daily_spiritual_insight'] as Map),
            )
          : null,
      journeyEvents: _parseJourneyEvents(data),
      dataSource: dataSource,
    );
  }

  List<GrowthJourneyEvent> _parseJourneyEvents(Map<String, dynamic> data) {
    final journey = Map<String, dynamic>.from(
      data['growth_journey'] as Map? ?? const {},
    );
    final events = (journey['events'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map(
          (item) =>
              GrowthJourneyEvent.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
    return events;
  }

  bool _postedTodayFromFeed(Map<dynamic, dynamic> data) {
    if (data['posted_today'] is bool) {
      return data['posted_today'] as bool;
    }
    final status = data['reflection_status'];
    if (status is Map && status['posted_today'] is bool) {
      return status['posted_today'] as bool;
    }
    final list = data['data'];
    if (list is List) {
      return list.whereType<Map>().any((item) => item['posted_today'] == true);
    }
    return false;
  }

  dynamic _payload(Map<String, dynamic>? response) {
    return response == null ? null : response['data'];
  }

  Map<String, dynamic> _payloadMap(Map<String, dynamic>? response) {
    final data = _payload(response);
    return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
  }

  List<dynamic> _payloadList(Map<String, dynamic>? response) {
    final data = _payload(response);
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return const [];
  }
}

class VisionBootstrap {
  const VisionBootstrap({
    required this.visibilityMode,
    required this.visibilityAlias,
    required this.primaryTribe,
    required this.activeCommitment,
    required this.dailyQuestion,
    this.journeyEvents = const [],
    this.dataSource = VisionDataSource.remote,
    this.errorMessage,
  });

  final VisibilityMode visibilityMode;
  final String visibilityAlias;
  final TribeMembership? primaryTribe;
  final CommitmentSeason? activeCommitment;
  final DailyGrowthQuestion? dailyQuestion;
  final List<GrowthJourneyEvent> journeyEvents;
  final VisionDataSource dataSource;
  final String? errorMessage;
}

class CommitmentFeedResult {
  const CommitmentFeedResult({
    required this.reflections,
    required this.postedToday,
  });

  final List<CommitmentReflection> reflections;
  final bool postedToday;
}

String _friendlyError(Object error) {
  final text = error.toString();
  const marker = 'message: ';
  final index = text.indexOf(marker);
  if (index >= 0) {
    final message = text.substring(index + marker.length).split(',').first;
    if (message.trim().isNotEmpty) return message.trim();
  }
  return 'We could not reach ElBiblio right now. Please try again.';
}
