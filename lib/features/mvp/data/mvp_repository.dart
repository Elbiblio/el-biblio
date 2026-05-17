import 'package:logger/logger.dart';

import '../../../core/network/dio_client.dart';
import '../domain/mvp_models.dart';

class MvpRepository {
  MvpRepository(this._dio, this._logger);

  final DioClient _dio;
  final Logger _logger;

  Future<MvpBootstrap> bootstrap() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/mvp/bootstrap');
      final data = _payloadMap(response.data);
      final user = Map<String, dynamic>.from(data['user'] as Map? ?? const {});
      final active = (data['active_commitments'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) => MvpCommitmentMembership.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
      final tribeRaw = data['primary_tribe'];

      return MvpBootstrap(
        visibilityMode: MvpVisibilityMode.fromValue(
          user['visibility_mode'] as String?,
        ),
        visibilityAlias: user['visibility_alias'] as String? ?? 'Anonymous',
        primaryTribe: tribeRaw is Map
            ? MvpTribeMembership.fromJson(Map<String, dynamic>.from(tribeRaw))
            : null,
        activeCommitment: active.isNotEmpty ? active.first : null,
        dailyQuestion: data['today_faith_question'] is Map
            ? MvpDailyFaithQuestion.fromJson(
                Map<String, dynamic>.from(data['today_faith_question'] as Map),
              )
            : null,
      );
    } catch (e, st) {
      _logger.w(
        'MVP bootstrap failed, using local fallback',
        error: e,
        stackTrace: st,
      );
      return const MvpBootstrap(
        visibilityMode: MvpVisibilityMode.anonymous,
        visibilityAlias: 'Anonymous',
        primaryTribe: null,
        activeCommitment: null,
        dailyQuestion: _fallbackQuestion,
      );
    }
  }

  Future<List<MvpTribe>> recommendedTribes() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/tribes/recommended',
      );
      final list = _payloadList(response.data);
      final tribes = list
          .whereType<Map>()
          .map((item) => MvpTribe.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      return tribes.isEmpty ? _fallbackTribes : tribes;
    } catch (e) {
      _logger.w('MVP recommended tribes failed: $e');
      return _fallbackTribes;
    }
  }

  Future<MvpTribeMembership> joinTribe({
    required int tribeId,
    required MvpVisibilityMode visibilityMode,
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
    return MvpTribeMembership.fromJson(_payloadMap(response.data));
  }

  Future<void> updateVisibility({
    required MvpVisibilityMode visibilityMode,
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

  Future<List<MvpCommitmentChallenge>> recommendedCommitments({
    int? tribeId,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/commitments/recommended',
        queryParameters: {if (tribeId != null) 'tribe_id': tribeId},
      );
      final list = _payloadList(response.data);
      final commitments = list
          .whereType<Map>()
          .map(
            (item) => MvpCommitmentChallenge.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
      return commitments.isEmpty ? _fallbackCommitments : commitments;
    } catch (e) {
      _logger.w('MVP recommended commitments failed: $e');
      return _fallbackCommitments;
    }
  }

  Future<MvpCommitmentMembership> joinCommitment({
    required int commitmentId,
    required int nudgeCount,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/commitments/$commitmentId/join',
      data: {'nudge_count_per_day': nudgeCount},
    );
    return MvpCommitmentMembership.fromJson(_payloadMap(response.data));
  }

  Future<MvpCommitmentMembership> checkIn({
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
    return MvpCommitmentMembership.fromJson(
      Map<String, dynamic>.from(data['membership'] as Map? ?? const {}),
    );
  }

  Future<List<MvpReflection>> feed(int commitmentId) async {
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
      return list
          .whereType<Map>()
          .map(
            (item) => MvpReflection.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (e) {
      _logger.w('MVP feed failed: $e');
      return const [];
    }
  }

  Future<MvpReflection> postReflection({
    required int commitmentId,
    required String content,
    required String alias,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/commitments/$commitmentId/reflections',
      data: {'content': content, 'visibility_alias': alias},
    );
    return MvpReflection.fromJson(_payloadMap(response.data));
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

  Future<MvpDailyFaithQuestion> todayQuestion() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/faith-questions/today',
      );
      return MvpDailyFaithQuestion.fromJson(_payloadMap(response.data));
    } catch (e) {
      _logger.w('MVP daily faith question failed: $e');
      return _fallbackQuestion;
    }
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
    return data is List ? data : const [];
  }
}

class MvpBootstrap {
  const MvpBootstrap({
    required this.visibilityMode,
    required this.visibilityAlias,
    required this.primaryTribe,
    required this.activeCommitment,
    required this.dailyQuestion,
  });

  final MvpVisibilityMode visibilityMode;
  final String visibilityAlias;
  final MvpTribeMembership? primaryTribe;
  final MvpCommitmentMembership? activeCommitment;
  final MvpDailyFaithQuestion? dailyQuestion;
}

const _fallbackTribes = [
  MvpTribe(
    id: 1,
    name: 'Quiet Discipline',
    slug: 'quiet-discipline',
    description:
        'Rebuild attention, self-control, and faithful practice without shame.',
    iconKey: 'compass',
  ),
  MvpTribe(
    id: 2,
    name: 'Healing & Forgiveness',
    slug: 'healing-forgiveness',
    description:
        'Walk through hurt, resentment, doubt, and repair with support.',
    iconKey: 'heart-handshake',
  ),
  MvpTribe(
    id: 3,
    name: 'Gratitude & Presence',
    slug: 'gratitude-presence',
    description: 'Notice God in ordinary life and become more present.',
    iconKey: 'sparkles',
  ),
];

const _fallbackCommitments = [
  MvpCommitmentChallenge(
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
  MvpCommitmentChallenge(
    id: 2,
    title: '30 Days of Gratitude',
    description: 'Practice daily gratitude in small, honest moments.',
    durationDays: 30,
    category: 'gratitude',
    dailyAction: 'Name one concrete gift from today and thank God for it.',
    nudgeMin: 3,
    nudgeMax: 10,
  ),
  MvpCommitmentChallenge(
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

const _fallbackQuestion = MvpDailyFaithQuestion(
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
