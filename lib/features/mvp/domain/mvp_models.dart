import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

enum MvpVisibilityMode {
  anonymous('anonymous', 'Anonymous'),
  initials('initials', 'Initials'),
  nickname('nickname', 'Nickname'),
  public('public', 'Public profile');

  const MvpVisibilityMode(this.value, this.label);

  final String value;
  final String label;

  static MvpVisibilityMode fromValue(String? value) {
    return MvpVisibilityMode.values.firstWhere(
      (mode) => mode.value == value,
      orElse: () => MvpVisibilityMode.anonymous,
    );
  }
}

class MvpTribe {
  const MvpTribe({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.iconKey,
  });

  final int id;
  final String name;
  final String slug;
  final String description;
  final String iconKey;

  factory MvpTribe.fromJson(Map<String, dynamic> json) {
    return MvpTribe(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? 'Spiritual Tribe',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String? ?? '',
      iconKey: json['icon_key'] as String? ?? 'users',
    );
  }
}

class MvpTribeMembership {
  const MvpTribeMembership({
    required this.tribe,
    required this.visibilityMode,
    required this.displayAlias,
    required this.isPrimary,
  });

  final MvpTribe tribe;
  final MvpVisibilityMode visibilityMode;
  final String displayAlias;
  final bool isPrimary;

  factory MvpTribeMembership.fromJson(Map<String, dynamic> json) {
    return MvpTribeMembership(
      tribe: MvpTribe.fromJson(
        Map<String, dynamic>.from(json['tribe'] as Map? ?? const {}),
      ),
      visibilityMode: MvpVisibilityMode.fromValue(
        json['visibility_mode'] as String?,
      ),
      displayAlias: json['display_alias'] as String? ?? 'Anonymous',
      isPrimary: json['is_primary'] as bool? ?? false,
    );
  }
}

class MvpCommitmentChallenge {
  const MvpCommitmentChallenge({
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
  final MvpTribe? tribe;

  factory MvpCommitmentChallenge.fromJson(Map<String, dynamic> json) {
    final tribeRaw = json['tribe'];
    return MvpCommitmentChallenge(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? 'Commitment',
      description: json['description'] as String? ?? '',
      durationDays: (json['duration_days'] as num?)?.toInt() ?? 30,
      category: json['category'] as String? ?? 'growth',
      dailyAction: json['daily_action'] as String? ?? '',
      nudgeMin: (json['nudge_min'] as num?)?.toInt() ?? 3,
      nudgeMax: (json['nudge_max'] as num?)?.toInt() ?? 10,
      tribe: tribeRaw is Map
          ? MvpTribe.fromJson(Map<String, dynamic>.from(tribeRaw))
          : null,
    );
  }
}

class MvpCommitmentMembership {
  const MvpCommitmentMembership({
    required this.challenge,
    required this.currentDay,
    required this.completedDaysCount,
    required this.nudgeCountPerDay,
    this.lastCheckInAt,
  });

  final MvpCommitmentChallenge challenge;
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
    if (challenge.durationDays <= 0) return 0;
    return (completedDaysCount / challenge.durationDays).clamp(0, 1);
  }

  factory MvpCommitmentMembership.fromJson(Map<String, dynamic> json) {
    return MvpCommitmentMembership(
      challenge: MvpCommitmentChallenge.fromJson(
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

class MvpReflection {
  const MvpReflection({
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

  factory MvpReflection.fromJson(Map<String, dynamic> json) {
    final reactions = json['reactions'];
    return MvpReflection(
      id: (json['id'] as num?)?.toInt() ?? 0,
      alias: json['visibility_alias'] as String? ?? 'Anonymous',
      content: json['content'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      reactionCount: reactions is List ? reactions.length : 0,
    );
  }
}

class MvpDailyFaithQuestion {
  const MvpDailyFaithQuestion({
    required this.id,
    required this.question,
    required this.conciseExplanation,
    required this.spiritualInsight,
    required this.practicalPerspective,
    required this.realWorldContext,
    this.category,
  });

  final int id;
  final String question;
  final String conciseExplanation;
  final String spiritualInsight;
  final String practicalPerspective;
  final String realWorldContext;
  final String? category;

  factory MvpDailyFaithQuestion.fromJson(Map<String, dynamic> json) {
    return MvpDailyFaithQuestion(
      id: (json['id'] as num?)?.toInt() ?? 0,
      question:
          json['question'] as String? ?? 'What is one faithful step today?',
      conciseExplanation: json['concise_explanation'] as String? ?? '',
      spiritualInsight: json['spiritual_insight'] as String? ?? '',
      practicalPerspective: json['practical_perspective'] as String? ?? '',
      realWorldContext: json['real_world_context'] as String? ?? '',
      category: json['category'] as String?,
    );
  }
}

enum MilestoneEventType {
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
    'Daily commitment complete',
    'You returned today.',
    'check-circle',
  ),
  reflectionPosted(
    'reflection_posted',
    'Reflection posted',
    'You shared honestly with your challenge.',
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
    'Weekly ritual posted',
    'You marked the week with your tribe.',
    'calendar-heart',
  );

  const MilestoneEventType(this.value, this.title, this.subtitle, this.iconKey);

  final String value;
  final String title;
  final String subtitle;
  final String iconKey;
}

class MilestoneEvent {
  const MilestoneEvent({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.occurredAt,
    required this.iconKey,
    this.route,
  });

  final MilestoneEventType type;
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
      _ => LucideIcons.sparkles,
    };
  }
}
