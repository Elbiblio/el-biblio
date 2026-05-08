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
      return _parseBootstrap(_payloadMap(response.data));
    } catch (_) {
      try {
        final response = await _dio.get<Map<String, dynamic>>('/mvp/bootstrap');
        return _parseBootstrap(_payloadMap(response.data));
      } catch (e, st) {
        _logger.w(
          'Vision bootstrap failed, using read-only fallback',
          error: e,
          stackTrace: st,
        );
        return const VisionBootstrap(
          visibilityMode: VisibilityMode.anonymous,
          visibilityAlias: 'Anonymous',
          primaryTribe: null,
          activeCommitment: null,
          dailyQuestion: _fallbackQuestion,
          journeyEvents: [],
        );
      }
    }
  }

  Future<List<TribeIdentity>> recommendedTribes() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/tribes/recommended',
      );
      final list = _payloadList(response.data);
      final tribes = list
          .whereType<Map>()
          .map(
            (item) => TribeIdentity.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
      return tribes.isEmpty ? _fallbackTribes : tribes;
    } catch (e) {
      _logger.w('Vision recommended tribes failed: $e');
      return _fallbackTribes;
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
      return commitments.isEmpty ? _fallbackCommitments : commitments;
    } catch (e) {
      _logger.w('Vision recommended commitments failed: $e');
      return _fallbackCommitments;
    }
  }

  Future<CommitmentSeason> joinCommitment({
    required int commitmentId,
    required int nudgeCount,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/commitments/$commitmentId/join',
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

  VisionBootstrap _parseBootstrap(Map<String, dynamic> data) {
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
  });

  final VisibilityMode visibilityMode;
  final String visibilityAlias;
  final TribeMembership? primaryTribe;
  final CommitmentSeason? activeCommitment;
  final DailyGrowthQuestion? dailyQuestion;
  final List<GrowthJourneyEvent> journeyEvents;
}

class CommitmentFeedResult {
  const CommitmentFeedResult({
    required this.reflections,
    required this.postedToday,
  });

  final List<CommitmentReflection> reflections;
  final bool postedToday;
}

const _fallbackTribes = [
  TribeIdentity(
    id: 1,
    name: 'Watchman Circle',
    slug: 'watchman-circle',
    description: 'For people rebuilding attention, vigilance, and prayer.',
    iconKey: 'compass',
  ),
  TribeIdentity(
    id: 2,
    name: 'Healer Circle',
    slug: 'healer-circle',
    description: 'For people walking through repair, forgiveness, and hope.',
    iconKey: 'heart-handshake',
  ),
  TribeIdentity(
    id: 3,
    name: 'Cultivator Circle',
    slug: 'cultivator-circle',
    description: 'For people growing slowly through faithfulness and presence.',
    iconKey: 'sparkles',
  ),
];

const _fallbackCommitments = [
  CommitmentPlan(
    id: 1,
    title: '30-Day Social Media Fast',
    description: 'Create space for prayer, attention, and real connection.',
    durationDays: 30,
    category: 'discipline',
    dailyAction:
        'Stay off social media today and use one urge as a prompt to pray.',
    nudgeMin: 3,
    nudgeMax: 10,
  ),
  CommitmentPlan(
    id: 2,
    title: '30 Days of Gratitude',
    description: 'Practice daily gratitude in small, honest moments.',
    durationDays: 30,
    category: 'gratitude',
    dailyAction: 'Name one concrete gift from today and thank God for it.',
    nudgeMin: 3,
    nudgeMax: 10,
  ),
  CommitmentPlan(
    id: 3,
    title: '+5 Minutes Daily Prayer',
    description: 'Add five focused minutes of prayer each day for one month.',
    durationDays: 30,
    category: 'prayer',
    dailyAction:
        'Pray for five focused minutes before moving to the next thing.',
    nudgeMin: 3,
    nudgeMax: 10,
  ),
];

const _fallbackQuestion = DailyGrowthQuestion(
  id: 0,
  question: 'What is one faithful step I can take today?',
  conciseExplanation:
      'Spiritual growth usually begins with the next honest step.',
  spiritualInsight: 'God meets return, not performance.',
  practicalPerspective: 'Choose one small action that can be completed today.',
  realWorldContext:
      'When life is noisy, small obedience keeps the soul oriented.',
  category: 'daily',
);
