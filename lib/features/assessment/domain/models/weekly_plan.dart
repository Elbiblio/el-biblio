/// A weekly plan or rule-of-life that translates the calling profile
/// into concrete daily and weekly structure.
class WeeklyPlan {
  const WeeklyPlan({
    required this.id,
    required this.callingProfileId,
    required this.weekStart,
    required this.dailyAnchors,
    required this.weeklyCommitments,
    required this.missionFocusForWeek,
    required this.accountabilityFocus,
    required this.reflectionPrompt,
    required this.createdAt,
  });

  /// Unique identifier for this weekly plan
  final String id;

  /// Reference to the calling profile this plan is based on
  final String callingProfileId;

  /// The start date of this week (Monday)
  final DateTime weekStart;

  /// Daily anchor practices (morning/evening rhythms)
  final List<DailyAnchor> dailyAnchors;

  /// Weekly commitments specific to this week
  final List<WeeklyCommitment> weeklyCommitments;

  /// The mission focus for this specific week
  final String missionFocusForWeek;

  /// Accountability focus for the week (e.g., "check in on service actions")
  final String accountabilityFocus;

  /// A reflection question for the week
  final String reflectionPrompt;

  /// When this plan was generated
  final DateTime createdAt;

  WeeklyPlan copyWith({
    String? id,
    String? callingProfileId,
    DateTime? weekStart,
    List<DailyAnchor>? dailyAnchors,
    List<WeeklyCommitment>? weeklyCommitments,
    String? missionFocusForWeek,
    String? accountabilityFocus,
    String? reflectionPrompt,
    DateTime? createdAt,
  }) {
    return WeeklyPlan(
      id: id ?? this.id,
      callingProfileId: callingProfileId ?? this.callingProfileId,
      weekStart: weekStart ?? this.weekStart,
      dailyAnchors: dailyAnchors ?? this.dailyAnchors,
      weeklyCommitments: weeklyCommitments ?? this.weeklyCommitments,
      missionFocusForWeek: missionFocusForWeek ?? this.missionFocusForWeek,
      accountabilityFocus: accountabilityFocus ?? this.accountabilityFocus,
      reflectionPrompt: reflectionPrompt ?? this.reflectionPrompt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'callingProfileId': callingProfileId,
      'weekStart': weekStart.toIso8601String(),
      'dailyAnchors': dailyAnchors.map((a) => a.toMap()).toList(),
      'weeklyCommitments': weeklyCommitments.map((c) => c.toMap()).toList(),
      'missionFocusForWeek': missionFocusForWeek,
      'accountabilityFocus': accountabilityFocus,
      'reflectionPrompt': reflectionPrompt,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory WeeklyPlan.fromMap(Map<String, dynamic> map) {
    return WeeklyPlan(
      id: map['id'] as String,
      callingProfileId: map['callingProfileId'] as String,
      weekStart: DateTime.parse(map['weekStart'] as String),
      dailyAnchors: (map['dailyAnchors'] as List)
          .map((a) => DailyAnchor.fromMap(a as Map<String, dynamic>))
          .toList(),
      weeklyCommitments: (map['weeklyCommitments'] as List)
          .map((c) => WeeklyCommitment.fromMap(c as Map<String, dynamic>))
          .toList(),
      missionFocusForWeek: map['missionFocusForWeek'] as String,
      accountabilityFocus: map['accountabilityFocus'] as String,
      reflectionPrompt: map['reflectionPrompt'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  /// Generate a default weekly plan ID based on week start
  static String generateId(DateTime weekStart) {
    return 'week_${weekStart.year}_${weekStart.month}_${weekStart.day}';
  }
}

/// A daily anchor practice (morning or evening rhythm)
class DailyAnchor {
  const DailyAnchor({
    required this.timeOfDay,
    required this.practice,
    required this.duration,
    required this.description,
  });

  /// Time of day: 'morning' or 'evening'
  final String timeOfDay;

  /// The practice name (e.g., "Scripture Reading", "Examen")
  final String practice;

  /// Expected duration in minutes
  final int duration;

  /// Description of what to do
  final String description;

  Map<String, dynamic> toMap() {
    return {
      'timeOfDay': timeOfDay,
      'practice': practice,
      'duration': duration,
      'description': description,
    };
  }

  factory DailyAnchor.fromMap(Map<String, dynamic> map) {
    return DailyAnchor(
      timeOfDay: map['timeOfDay'] as String,
      practice: map['practice'] as String,
      duration: map['duration'] as int,
      description: map['description'] as String,
    );
  }
}

/// A weekly commitment (action, practice, or focus for the week)
class WeeklyCommitment {
  const WeeklyCommitment({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.targetCount,
    required this.currentCount,
    required this.category,
  });

  /// Unique identifier for this commitment
  final String id;

  /// Type: 'action', 'practice', or 'focus'
  final String type;

  /// Title of the commitment
  final String title;

  /// Description of what it involves
  final String description;

  /// Target count for the week (e.g., number of actions, days of practice)
  final int targetCount;

  /// Current progress count
  final int currentCount;

  /// Category: 'growth', 'discipline', or 'charity'
  final String category;

  WeeklyCommitment copyWith({
    String? id,
    String? type,
    String? title,
    String? description,
    int? targetCount,
    int? currentCount,
    String? category,
  }) {
    return WeeklyCommitment(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      targetCount: targetCount ?? this.targetCount,
      currentCount: currentCount ?? this.currentCount,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'targetCount': targetCount,
      'currentCount': currentCount,
      'category': category,
    };
  }

  factory WeeklyCommitment.fromMap(Map<String, dynamic> map) {
    return WeeklyCommitment(
      id: map['id'] as String,
      type: map['type'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      targetCount: map['targetCount'] as int,
      currentCount: map['currentCount'] as int,
      category: map['category'] as String,
    );
  }

  /// Generate a default ID for a commitment
  static String generateId(String type, String title) {
    return '${type}_${title.toLowerCase().replaceAll(' ', '_')}';
  }

  /// Calculate completion percentage
  double get completionPercentage {
    if (targetCount == 0) return 0.0;
    return (currentCount / targetCount).clamp(0.0, 1.0);
  }

  /// Check if commitment is complete
  bool get isComplete => currentCount >= targetCount;
}
