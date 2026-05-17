import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

enum VisionDataSource {
  remote,
  compatibility,
  offlineFallback,
  error;

  bool get isReadOnly => this == offlineFallback || this == error;
}

enum VisibilityMode {
  anonymous('anonymous', 'Anonymous'),
  initials('initials', 'Initials'),
  nickname('nickname', 'Nickname'),
  public('public', 'Visible profile');

  const VisibilityMode(this.value, this.label);

  final String value;
  final String label;

  static VisibilityMode fromValue(String? value) {
    return VisibilityMode.values.firstWhere(
      (mode) => mode.value == value,
      orElse: () => VisibilityMode.anonymous,
    );
  }
}

class TribeIdentity {
  const TribeIdentity({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.iconKey,
    this.matchScore = 0,
    this.matchReason,
    this.matchedArchetypes = const [],
  });

  final int id;
  final String name;
  final String slug;
  final String description;
  final String iconKey;
  final int matchScore;
  final String? matchReason;
  final List<String> matchedArchetypes;

  String get displayName => displayTribeName(name);

  factory TribeIdentity.fromJson(Map<String, dynamic> json) {
    return TribeIdentity(
      id: _intFromJson(json['id']) ?? 0,
      name: json['name'] as String? ?? 'Spiritual Tribe',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String? ?? '',
      iconKey: json['icon_key'] as String? ?? 'users',
      matchScore: _intFromJson(json['match_score']) ?? 0,
      matchReason: json['match_reason'] as String?,
      matchedArchetypes:
          (json['matched_archetypes'] as List<dynamic>? ?? const [])
              .map((item) => item.toString())
              .where((item) => item.isNotEmpty)
              .toList(),
    );
  }
}

class TribeMembership {
  const TribeMembership({
    required this.tribe,
    required this.visibilityMode,
    required this.displayAlias,
    required this.isPrimary,
  });

  final TribeIdentity tribe;
  final VisibilityMode visibilityMode;
  final String displayAlias;
  final bool isPrimary;

  factory TribeMembership.fromJson(Map<String, dynamic> json) {
    return TribeMembership(
      tribe: TribeIdentity.fromJson(
        Map<String, dynamic>.from(json['tribe'] as Map? ?? const {}),
      ),
      visibilityMode: VisibilityMode.fromValue(
        json['visibility_mode'] as String?,
      ),
      displayAlias: json['display_alias'] as String? ?? 'Anonymous',
      isPrimary: _boolFromJson(json['is_primary']) ?? false,
    );
  }
}

class TribeGameLeaderboardEntry {
  const TribeGameLeaderboardEntry({
    required this.rank,
    required this.tribeName,
    required this.gameTitle,
    required this.score,
    this.tribeId,
    this.periodLabel = 'This week',
    this.metricLabel = 'points',
  });

  final int rank;
  final int? tribeId;
  final String tribeName;
  final String gameTitle;
  final int score;
  final String periodLabel;
  final String metricLabel;

  String get tribeDisplayName => displayTribeName(tribeName);

  factory TribeGameLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    final tribe = Map<String, dynamic>.from(json['tribe'] as Map? ?? const {});
    return TribeGameLeaderboardEntry(
      rank: _intFromJson(json['rank']) ?? 0,
      tribeId: _intFromJson(json['tribe_id'] ?? tribe['id']),
      tribeName:
          json['tribe_name'] as String? ??
          tribe['name'] as String? ??
          'Spiritual Tribe',
      gameTitle:
          json['game_title'] as String? ??
          json['game'] as String? ??
          'Scripture Games',
      score: _intFromJson(json['score'] ?? json['points']) ?? 0,
      periodLabel:
          json['period_label'] as String? ??
          json['period'] as String? ??
          'This week',
      metricLabel: json['metric_label'] as String? ?? 'points',
    );
  }
}

class CommitmentPlan {
  const CommitmentPlan({
    required this.id,
    required this.title,
    required this.description,
    required this.durationDays,
    required this.category,
    required this.dailyAction,
    required this.nudgeMin,
    required this.nudgeMax,
    this.tribe,
  });

  final int id;
  final String title;
  final String description;
  final int durationDays;
  final String category;
  final String dailyAction;
  final int nudgeMin;
  final int nudgeMax;
  final TribeIdentity? tribe;

  factory CommitmentPlan.fromJson(Map<String, dynamic> json) {
    final tribeRaw = json['tribe'];
    return CommitmentPlan(
      id: _intFromJson(json['id']) ?? 0,
      title: json['title'] as String? ?? 'Commitment',
      description: json['description'] as String? ?? '',
      durationDays: _intFromJson(json['duration_days']) ?? 30,
      category: json['category'] as String? ?? 'growth',
      dailyAction: json['daily_action'] as String? ?? '',
      nudgeMin: _intFromJson(json['nudge_min']) ?? 3,
      nudgeMax: _intFromJson(json['nudge_max']) ?? 10,
      tribe: tribeRaw is Map
          ? TribeIdentity.fromJson(Map<String, dynamic>.from(tribeRaw))
          : null,
    );
  }
}

class CommitmentSeason {
  const CommitmentSeason({
    required this.plan,
    required this.currentDay,
    required this.completedDaysCount,
    required this.nudgeCountPerDay,
    this.lastCheckInAt,
    this.checkedInTodayOverride,
    this.firstCheckInPlanWhen,
    this.firstCheckInPlanObstacle,
  });

  final CommitmentPlan plan;
  final int currentDay;
  final int completedDaysCount;
  final int nudgeCountPerDay;
  final DateTime? lastCheckInAt;
  final bool? checkedInTodayOverride;
  final String? firstCheckInPlanWhen;
  final String? firstCheckInPlanObstacle;

  bool get checkedInToday {
    final override = checkedInTodayOverride;
    if (override != null) return override;
    final last = lastCheckInAt;
    if (last == null) return false;
    final now = DateTime.now();
    return last.year == now.year &&
        last.month == now.month &&
        last.day == now.day;
  }

  double get progress {
    if (plan.durationDays <= 0) return 0;
    return (completedDaysCount / plan.durationDays).clamp(0, 1);
  }

  factory CommitmentSeason.fromJson(Map<String, dynamic> json) {
    return CommitmentSeason(
      plan: CommitmentPlan.fromJson(
        Map<String, dynamic>.from(json['challenge'] as Map? ?? const {}),
      ),
      currentDay: _intFromJson(json['current_day']) ?? 1,
      completedDaysCount: _intFromJson(json['completed_days_count']) ?? 0,
      nudgeCountPerDay: _intFromJson(json['nudge_count_per_day']) ?? 3,
      lastCheckInAt: DateTime.tryParse(
        json['last_check_in_at']?.toString() ?? '',
      ),
      checkedInTodayOverride: _boolFromJson(json['checked_in_today']),
      firstCheckInPlanWhen: json['check_in_plan_when'] as String?,
      firstCheckInPlanObstacle: json['check_in_plan_obstacle'] as String?,
    );
  }
}

class CommitmentPlanContext {
  const CommitmentPlanContext({this.when, this.obstacle});

  final String? when;
  final String? obstacle;
}

class CommitmentReflection {
  const CommitmentReflection({
    required this.id,
    required this.alias,
    required this.content,
    required this.createdAt,
    this.reactionCount = 0,
    this.authorMemberSince,
    this.authorTribeName,
    this.authorCompletedChallengesCount = 0,
    this.authorCurrentStreakCount = 0,
    this.myReactionType,
  });

  final int id;
  final String alias;
  final String content;
  final DateTime createdAt;
  final int reactionCount;
  final DateTime? authorMemberSince;
  final String? authorTribeName;
  final int authorCompletedChallengesCount;
  final int authorCurrentStreakCount;
  final String? myReactionType;

  bool get supportedByMe =>
      myReactionType != null && myReactionType!.isNotEmpty;

  String get authorTribeDisplayName =>
      displayTribeName(authorTribeName ?? '').isEmpty
      ? 'No tribe yet'
      : displayTribeName(authorTribeName ?? '');

  factory CommitmentReflection.fromJson(Map<String, dynamic> json) {
    final reactions = json['reactions'];
    final reactionCounts = Map<String, dynamic>.from(
      json['reaction_counts'] as Map? ?? const {},
    );
    final authorProfile = Map<String, dynamic>.from(
      json['author_profile'] as Map? ?? const {},
    );
    return CommitmentReflection(
      id: _intFromJson(json['id']) ?? 0,
      alias:
          json['author_alias'] as String? ??
          json['visibility_alias'] as String? ??
          'Anonymous',
      content: json['content'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      reactionCount: reactionCounts.isNotEmpty
          ? reactionCounts.values.fold<int>(
              0,
              (sum, value) => sum + (_intFromJson(value) ?? 0),
            )
          : reactions is List
          ? reactions.length
          : 0,
      authorMemberSince: DateTime.tryParse(
        authorProfile['member_since']?.toString() ??
            json['author_member_since']?.toString() ??
            '',
      ),
      authorTribeName:
          authorProfile['tribe_name'] as String? ??
          json['author_tribe_name'] as String?,
      authorCompletedChallengesCount:
          _intFromJson(authorProfile['completed_challenges_count']) ??
          _intFromJson(json['author_completed_challenges_count']) ??
          0,
      authorCurrentStreakCount:
          _intFromJson(authorProfile['current_streak_count']) ??
          _intFromJson(json['author_current_streak_count']) ??
          0,
      myReactionType:
          json['my_reaction_type'] as String? ??
          json['current_user_reaction'] as String? ??
          json['my_reaction'] as String? ??
          _firstString(json['my_reactions']),
    );
  }
}

String? _firstString(Object? value) {
  if (value is List && value.isNotEmpty) return value.first?.toString();
  return null;
}

String displayTribeName(String name) {
  return name.trim().replaceFirst(
    RegExp(r'\s+Circle$', caseSensitive: false),
    '',
  );
}

class WeeklyRitualReflection {
  const WeeklyRitualReflection({
    required this.id,
    required this.alias,
    required this.content,
    required this.createdAt,
    required this.expiresAt,
    required this.bookmarkedByMe,
  });

  final int id;
  final String alias;
  final String content;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool bookmarkedByMe;

  factory WeeklyRitualReflection.fromJson(Map<String, dynamic> json) {
    return WeeklyRitualReflection(
      id: _intFromJson(json['id']) ?? 0,
      alias: json['author_alias'] as String? ?? 'Anonymous',
      content: json['content'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? ''),
      bookmarkedByMe: _boolFromJson(json['bookmarked_by_me']) ?? false,
    );
  }

  WeeklyRitualReflection copyWith({bool? bookmarkedByMe}) {
    return WeeklyRitualReflection(
      id: id,
      alias: alias,
      content: content,
      createdAt: createdAt,
      expiresAt: expiresAt,
      bookmarkedByMe: bookmarkedByMe ?? this.bookmarkedByMe,
    );
  }
}

class DailyGrowthQuestion {
  const DailyGrowthQuestion({
    required this.id,
    required this.question,
    required this.conciseExplanation,
    required this.spiritualInsight,
    required this.practicalPerspective,
    required this.realWorldContext,
    this.dailyLivingGuide,
    this.actionSteps = const [],
    this.scriptureRefs = const [],
    this.answerOptions = const [],
    this.packQuestions = const [],
    this.category,
    this.position,
    this.answer,
    this.answeredToday = false,
  });

  final int id;
  final String question;
  final String conciseExplanation;
  final String spiritualInsight;
  final String practicalPerspective;
  final String realWorldContext;
  final String? dailyLivingGuide;
  final List<DailyFaithActionStep> actionSteps;
  final List<String> scriptureRefs;
  final List<String> answerOptions;
  final List<DailyGrowthQuestion> packQuestions;
  final String? category;
  final int? position;
  final String? answer;
  final bool answeredToday;

  factory DailyGrowthQuestion.fromJson(Map<String, dynamic> json) {
    final packRaw = json['questions'];
    return DailyGrowthQuestion(
      id: _intFromJson(json['id']) ?? 0,
      question:
          json['question'] as String? ?? 'What is one faithful step today?',
      conciseExplanation: json['concise_explanation'] as String? ?? '',
      spiritualInsight: json['spiritual_insight'] as String? ?? '',
      practicalPerspective: json['practical_perspective'] as String? ?? '',
      realWorldContext: json['real_world_context'] as String? ?? '',
      dailyLivingGuide: json['daily_living_guide'] as String?,
      actionSteps: (json['action_steps'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                DailyFaithActionStep.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      scriptureRefs: (json['scripture_refs'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      answerOptions:
          ((json['answer_options'] ?? json['quiz_options']) as List<dynamic>? ??
                  const [])
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .toList(),
      packQuestions: packRaw is List
          ? packRaw
                .whereType<Map>()
                .map(
                  (item) => DailyGrowthQuestion.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
      category: json['category'] as String?,
      position: _intFromJson(json['position']),
      answer: json['answer'] as String?,
      answeredToday: _boolFromJson(json['answered_today']) ?? false,
    );
  }

  DailyGrowthQuestion copyWith({
    String? answer,
    bool? answeredToday,
    List<DailyGrowthQuestion>? packQuestions,
  }) {
    return DailyGrowthQuestion(
      id: id,
      question: question,
      conciseExplanation: conciseExplanation,
      spiritualInsight: spiritualInsight,
      practicalPerspective: practicalPerspective,
      realWorldContext: realWorldContext,
      dailyLivingGuide: dailyLivingGuide,
      actionSteps: actionSteps,
      scriptureRefs: scriptureRefs,
      answerOptions: answerOptions,
      packQuestions: packQuestions ?? this.packQuestions,
      category: category,
      position: position,
      answer: answer ?? this.answer,
      answeredToday: answeredToday ?? this.answeredToday,
    );
  }
}

int? _intFromJson(Object? value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

bool? _boolFromJson(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  return null;
}

class DailyFaithActionStep {
  const DailyFaithActionStep({
    required this.label,
    required this.instruction,
    required this.why,
    this.minutes,
  });

  final String label;
  final String instruction;
  final String why;
  final int? minutes;

  factory DailyFaithActionStep.fromJson(Map<String, dynamic> json) {
    return DailyFaithActionStep(
      label: json['label'] as String? ?? 'Practice',
      instruction: json['instruction'] as String? ?? '',
      why: json['why'] as String? ?? '',
      minutes: _intFromJson(json['minutes']),
    );
  }
}

class CommitmentHangout {
  const CommitmentHangout({
    required this.id,
    required this.title,
    required this.status,
    required this.participantCount,
    required this.maxParticipants,
    required this.canJoin,
    required this.scopeType,
    this.joinedByMe = false,
    this.startsAt,
    this.scopeId,
    this.liveKit,
  });

  final int id;
  final String title;
  final String status;
  final int participantCount;
  final int maxParticipants;
  final bool canJoin;
  final String scopeType;
  final bool joinedByMe;
  final int? scopeId;
  final DateTime? startsAt;
  final LiveKitRoomCredentials? liveKit;

  factory CommitmentHangout.fromJson(Map<String, dynamic> json) {
    return CommitmentHangout(
      id: _intFromJson(json['id']) ?? 0,
      title: json['title'] as String? ?? 'Tribe hangout',
      status: json['status'] as String? ?? 'scheduled',
      participantCount: _intFromJson(json['participant_count']) ?? 0,
      maxParticipants: _intFromJson(json['max_participants']) ?? 8,
      canJoin: _boolFromJson(json['can_join']) ?? false,
      scopeType: json['scope_type'] as String? ?? 'commitment',
      joinedByMe: _boolFromJson(json['joined_by_me']) ?? false,
      scopeId: _intFromJson(json['scope_id']),
      startsAt: DateTime.tryParse(json['starts_at']?.toString() ?? ''),
      liveKit: json['livekit'] is Map
          ? LiveKitRoomCredentials.fromJson(
              Map<String, dynamic>.from(json['livekit'] as Map),
            )
          : null,
    );
  }
}

class LiveKitRoomCredentials {
  const LiveKitRoomCredentials({
    required this.token,
    required this.url,
    required this.identity,
    required this.room,
  });

  final String token;
  final String url;
  final String identity;
  final String room;

  bool get isValid => token.isNotEmpty && url.isNotEmpty && room.isNotEmpty;

  factory LiveKitRoomCredentials.fromJson(Map<String, dynamic> json) {
    return LiveKitRoomCredentials(
      token: json['token'] as String? ?? '',
      url: json['url'] as String? ?? '',
      identity: json['identity'] as String? ?? '',
      room: json['room'] as String? ?? '',
    );
  }
}

class TribePulseItem {
  const TribePulseItem({
    required this.text,
    required this.iconKey,
    this.type = 'activity',
    this.createdAt,
  });

  final String text;
  final String iconKey;
  final String type;
  final DateTime? createdAt;

  factory TribePulseItem.fromJson(Map<String, dynamic> json) {
    return TribePulseItem(
      text: json['text'] as String? ?? 'Your tribe is checking in today.',
      iconKey: json['icon_key'] as String? ?? 'users',
      type: json['type'] as String? ?? 'activity',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}

class TribePulse {
  const TribePulse({
    required this.returnedCount,
    required this.activeMembersCount,
    required this.reflectionCount,
    required this.supportCount,
    required this.items,
  });

  final int returnedCount;
  final int activeMembersCount;
  final int reflectionCount;
  final int supportCount;
  final List<TribePulseItem> items;

  factory TribePulse.fromJson(Map<String, dynamic> json) {
    final today = Map<String, dynamic>.from(json['today'] as Map? ?? const {});
    final items = (json['items'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => TribePulseItem.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    return TribePulse(
      returnedCount:
          _intFromJson(today['checked_in_count']) ??
          _intFromJson(today['returned_count']) ??
          0,
      activeMembersCount: _intFromJson(today['active_members_count']) ?? 0,
      reflectionCount: _intFromJson(today['reflection_count']) ?? 0,
      supportCount: _intFromJson(today['support_count']) ?? 0,
      items: items,
    );
  }

  static const empty = TribePulse(
    returnedCount: 0,
    activeMembersCount: 0,
    reflectionCount: 0,
    supportCount: 0,
    items: [],
  );
}

class VisionNotificationItem {
  const VisionNotificationItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.read,
    this.actionLabel,
    this.route,
    this.iconKey = 'bell',
    this.hangoutId,
    this.commitmentId,
    this.reflectionId,
  });

  final int id;
  final String kind;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;
  final String? actionLabel;
  final String? route;
  final String iconKey;
  final int? hangoutId;
  final int? commitmentId;
  final int? reflectionId;

  IconData get icon => GrowthJourneyEvent.iconForKey(iconKey);

  factory VisionNotificationItem.fromJson(Map<String, dynamic> json) {
    final payload = Map<String, dynamic>.from(
      json['payload'] as Map? ?? const {},
    );
    return VisionNotificationItem(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      kind: payload['kind'] as String? ?? 'notification',
      title: payload['title'] as String? ?? 'Something new on ElBiblio',
      body: payload['body'] as String? ?? 'Open ElBiblio when you are ready.',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      read: json['read_at'] != null,
      actionLabel: payload['action_label'] as String?,
      route: payload['route'] as String?,
      iconKey: payload['icon_key'] as String? ?? 'bell',
      hangoutId: _intFromJson(payload['hangout_id']),
      commitmentId: _intFromJson(payload['commitment_id']),
      reflectionId: _intFromJson(payload['reflection_id']),
    );
  }
}

enum GrowthJourneyEventType {
  compassComplete(
    'compass_complete',
    'Compass complete',
    'You named where you are beginning.',
    'compass',
  ),
  tribeJoined(
    'tribe_joined',
    'Tribe joined',
    'You found a place to grow with others.',
    'users',
  ),
  commitmentJoined(
    'commitment_joined',
    'Commitment joined',
    'You chose a concrete commitment for this season.',
    'flag',
  ),
  dailyCommitmentComplete(
    'daily_commitment_complete',
    'Daily check-in',
    'You checked in today.',
    'check-circle',
  ),
  reflectionPosted(
    'reflection_posted',
    'Reflection shared',
    'You shared honestly with your commitment.',
    'message-circle',
  ),
  supportGiven(
    'support_given',
    'Support given',
    'You encouraged someone keeping a commitment.',
    'heart-handshake',
  ),
  inviteSent(
    'invite_sent',
    'Invite sent',
    'You opened the door for someone else.',
    'send',
  ),
  weeklyRitualPosted(
    'weekly_ritual_posted',
    'Weekly reflection',
    'You marked the week with your tribe.',
    'calendar-heart',
  ),
  tribeHangoutJoined(
    'tribe_hangout_joined',
    'Tribe hangout',
    'You joined a live gathering with your tribe.',
    'radio',
  );

  const GrowthJourneyEventType(
    this.value,
    this.title,
    this.subtitle,
    this.iconKey,
  );

  final String value;
  final String title;
  final String subtitle;
  final String iconKey;

  static GrowthJourneyEventType fromValue(String? value) {
    return GrowthJourneyEventType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => GrowthJourneyEventType.compassComplete,
    );
  }
}

class GrowthJourneyEvent {
  const GrowthJourneyEvent({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.occurredAt,
    required this.iconKey,
    this.route,
  });

  final GrowthJourneyEventType type;
  final String title;
  final String subtitle;
  final DateTime occurredAt;
  final String iconKey;
  final String? route;

  IconData get icon => iconForKey(iconKey);

  static IconData iconForKey(String key) {
    return switch (key) {
      'compass' => LucideIcons.compass,
      'users' => LucideIcons.users,
      'flag' => LucideIcons.flag,
      'check-circle' => LucideIcons.checkCircle,
      'message-circle' => LucideIcons.messageCircle,
      'heart-handshake' => LucideIcons.heartHandshake,
      'send' => LucideIcons.send,
      'calendar-heart' => LucideIcons.calendarHeart,
      'bell' => LucideIcons.bell,
      'radio' => LucideIcons.radio,
      _ => LucideIcons.sparkles,
    };
  }

  factory GrowthJourneyEvent.fromJson(Map<String, dynamic> json) {
    final type = GrowthJourneyEventType.fromValue(json['type'] as String?);
    return GrowthJourneyEvent(
      type: type,
      title: json['title'] as String? ?? type.title,
      subtitle: json['subtitle'] as String? ?? type.subtitle,
      occurredAt:
          DateTime.tryParse(json['occurred_at']?.toString() ?? '') ??
          DateTime.now(),
      iconKey: json['icon_key'] as String? ?? type.iconKey,
      route: json['route'] as String?,
    );
  }
}
