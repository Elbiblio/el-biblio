import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

enum VisibilityMode {
  anonymous('anonymous', 'Anonymous'),
  initials('initials', 'Initials'),
  nickname('nickname', 'Nickname'),
  public('public', 'Public profile');

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

  factory TribeIdentity.fromJson(Map<String, dynamic> json) {
    return TribeIdentity(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? 'Spiritual Tribe',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String? ?? '',
      iconKey: json['icon_key'] as String? ?? 'users',
      matchScore: (json['match_score'] as num?)?.toInt() ?? 0,
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
      isPrimary: json['is_primary'] as bool? ?? false,
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
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? 'Commitment',
      description: json['description'] as String? ?? '',
      durationDays: (json['duration_days'] as num?)?.toInt() ?? 30,
      category: json['category'] as String? ?? 'growth',
      dailyAction: json['daily_action'] as String? ?? '',
      nudgeMin: (json['nudge_min'] as num?)?.toInt() ?? 3,
      nudgeMax: (json['nudge_max'] as num?)?.toInt() ?? 10,
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
  });

  final CommitmentPlan plan;
  final int currentDay;
  final int completedDaysCount;
  final int nudgeCountPerDay;
  final DateTime? lastCheckInAt;

  bool get checkedInToday {
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
      currentDay: (json['current_day'] as num?)?.toInt() ?? 1,
      completedDaysCount: (json['completed_days_count'] as num?)?.toInt() ?? 0,
      nudgeCountPerDay: (json['nudge_count_per_day'] as num?)?.toInt() ?? 3,
      lastCheckInAt: DateTime.tryParse(
        json['last_check_in_at']?.toString() ?? '',
      ),
    );
  }
}

class CommitmentReflection {
  const CommitmentReflection({
    required this.id,
    required this.alias,
    required this.content,
    required this.createdAt,
    this.reactionCount = 0,
  });

  final int id;
  final String alias;
  final String content;
  final DateTime createdAt;
  final int reactionCount;

  factory CommitmentReflection.fromJson(Map<String, dynamic> json) {
    final reactions = json['reactions'];
    final reactionCounts = Map<String, dynamic>.from(
      json['reaction_counts'] as Map? ?? const {},
    );
    return CommitmentReflection(
      id: (json['id'] as num?)?.toInt() ?? 0,
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
              (sum, value) => sum + ((value as num?)?.toInt() ?? 0),
            )
          : reactions is List
          ? reactions.length
          : 0,
    );
  }
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
      id: (json['id'] as num?)?.toInt() ?? 0,
      alias: json['author_alias'] as String? ?? 'Anonymous',
      content: json['content'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? ''),
      bookmarkedByMe: json['bookmarked_by_me'] as bool? ?? false,
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
    this.category,
    this.answer,
    this.answeredToday = false,
  });

  final int id;
  final String question;
  final String conciseExplanation;
  final String spiritualInsight;
  final String practicalPerspective;
  final String realWorldContext;
  final String? category;
  final String? answer;
  final bool answeredToday;

  factory DailyGrowthQuestion.fromJson(Map<String, dynamic> json) {
    return DailyGrowthQuestion(
      id: (json['id'] as num?)?.toInt() ?? 0,
      question:
          json['question'] as String? ?? 'What is one faithful step today?',
      conciseExplanation: json['concise_explanation'] as String? ?? '',
      spiritualInsight: json['spiritual_insight'] as String? ?? '',
      practicalPerspective: json['practical_perspective'] as String? ?? '',
      realWorldContext: json['real_world_context'] as String? ?? '',
      category: json['category'] as String?,
      answer: json['answer'] as String?,
      answeredToday: json['answered_today'] as bool? ?? false,
    );
  }

  DailyGrowthQuestion copyWith({String? answer, bool? answeredToday}) {
    return DailyGrowthQuestion(
      id: id,
      question: question,
      conciseExplanation: conciseExplanation,
      spiritualInsight: spiritualInsight,
      practicalPerspective: practicalPerspective,
      realWorldContext: realWorldContext,
      category: category,
      answer: answer ?? this.answer,
      answeredToday: answeredToday ?? this.answeredToday,
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
  final int? scopeId;
  final DateTime? startsAt;
  final LiveKitRoomCredentials? liveKit;

  factory CommitmentHangout.fromJson(Map<String, dynamic> json) {
    return CommitmentHangout(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? 'Commitment hangout',
      status: json['status'] as String? ?? 'scheduled',
      participantCount: (json['participant_count'] as num?)?.toInt() ?? 0,
      maxParticipants: (json['max_participants'] as num?)?.toInt() ?? 8,
      canJoin: json['can_join'] as bool? ?? false,
      scopeType: json['scope_type'] as String? ?? 'commitment',
      scopeId: (json['scope_id'] as num?)?.toInt(),
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
      text: json['text'] as String? ?? 'Your tribe is returning today.',
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
      returnedCount: (today['returned_count'] as num?)?.toInt() ?? 0,
      activeMembersCount: (today['active_members_count'] as num?)?.toInt() ?? 0,
      reflectionCount: (today['reflection_count'] as num?)?.toInt() ?? 0,
      supportCount: (today['support_count'] as num?)?.toInt() ?? 0,
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
      hangoutId: (payload['hangout_id'] as num?)?.toInt(),
      commitmentId: (payload['commitment_id'] as num?)?.toInt(),
      reflectionId: (payload['reflection_id'] as num?)?.toInt(),
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
    'You chose a concrete path for this season.',
    'flag',
  ),
  dailyCommitmentComplete(
    'daily_commitment_complete',
    'Daily return',
    'You returned today.',
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
    'You encouraged someone on the path.',
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
