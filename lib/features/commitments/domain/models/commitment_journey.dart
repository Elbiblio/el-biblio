import 'commitment_category.dart';

/// Duration options for commitment journeys.
enum CommitmentDuration {
  seed3Day(3, '3-Day Seed', 'Begin something new with God'),
  path10Day(10, '10-Day Path', 'Establish a rhythm of growth'),
  journey40Day(40, '40-Day Journey', 'Deep transformation');

  final int days;
  final String label;
  final String description;

  const CommitmentDuration(this.days, this.label, this.description);
}

/// Represents a milestone where the commitment deepens (gets tighter).
/// Example: Day 10 milestone changes fasting from 12pm to 3pm.
class CommitmentMilestone {
  const CommitmentMilestone({
    required this.day,
    required this.description,
    required this.newRequirement,
  });

  final int day; // Which day this milestone occurs (1-40)
  final String description; // "Fasting extends to 3pm"
  final String newRequirement; // What the user must now do

  CommitmentMilestone copyWith({
    int? day,
    String? description,
    String? newRequirement,
  }) {
    return CommitmentMilestone(
      day: day ?? this.day,
      description: description ?? this.description,
      newRequirement: newRequirement ?? this.newRequirement,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'description': description,
      'newRequirement': newRequirement,
    };
  }

  factory CommitmentMilestone.fromJson(Map<String, dynamic> json) {
    return CommitmentMilestone(
      day: json['day'] as int,
      description: json['description'] as String,
      newRequirement: json['newRequirement'] as String,
    );
  }
}

/// A commitment journey is a multi-day commitment with optional milestones.
/// This is the new model for 3-day, 10-day, and 40-day journeys.
class CommitmentJourney {
  const CommitmentJourney({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    required this.virtueAlignment,
    this.milestones = const [],
    this.struggleTags = const [],
    this.category = CommitmentCategory.growth,
    this.tips = const [],
    this.baseRequirement,
    this.encouragement,
    this.failureGrace,
  });

  final String id;
  final String title;
  final String description;
  final CommitmentDuration duration;
  final String virtueAlignment; // e.g., "prayer", "fasting", "generosity"
  final List<CommitmentMilestone> milestones; // Max 4, optional
  final List<String> struggleTags; // e.g., ["social_media", "anger"]
  final CommitmentCategory category;
  final List<String> tips;
  final String? baseRequirement; // What to do on day 1
  final String? encouragement; // Shown on completion
  final String? failureGrace; // Shown if failed

  int get totalDays => duration.days;
  bool get hasMilestones => milestones.isNotEmpty;
  int get milestoneCount => milestones.length;

  /// Get the requirement for a specific day (base or milestone-based).
  String requirementForDay(int day) {
    if (day < 1 || day > totalDays) return '';

    // Find the most recent milestone
    String currentRequirement = baseRequirement ?? '';
    for (final milestone in milestones) {
      if (day >= milestone.day) {
        currentRequirement = milestone.newRequirement;
      }
    }
    return currentRequirement;
  }

  /// Get the next milestone after a given day, or null if none.
  CommitmentMilestone? nextMilestoneAfter(int day) {
    for (final milestone in milestones) {
      if (milestone.day > day) return milestone;
    }
    return null;
  }

  CommitmentJourney copyWith({
    String? id,
    String? title,
    String? description,
    CommitmentDuration? duration,
    String? virtueAlignment,
    List<CommitmentMilestone>? milestones,
    List<String>? struggleTags,
    CommitmentCategory? category,
    List<String>? tips,
    String? baseRequirement,
    String? encouragement,
    String? failureGrace,
  }) {
    return CommitmentJourney(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      duration: duration ?? this.duration,
      virtueAlignment: virtueAlignment ?? this.virtueAlignment,
      milestones: milestones ?? this.milestones,
      struggleTags: struggleTags ?? this.struggleTags,
      category: category ?? this.category,
      tips: tips ?? this.tips,
      baseRequirement: baseRequirement ?? this.baseRequirement,
      encouragement: encouragement ?? this.encouragement,
      failureGrace: failureGrace ?? this.failureGrace,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'duration': duration.name,
      'virtueAlignment': virtueAlignment,
      'milestones': milestones.map((m) => m.toJson()).toList(),
      'struggleTags': struggleTags,
      'category': category.name,
      'tips': tips,
      'baseRequirement': baseRequirement,
      'encouragement': encouragement,
      'failureGrace': failureGrace,
    };
  }

  factory CommitmentJourney.fromJson(Map<String, dynamic> json) {
    return CommitmentJourney(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      duration: CommitmentDuration.values.firstWhere(
        (d) => d.name == json['duration'],
        orElse: () => CommitmentDuration.journey40Day,
      ),
      virtueAlignment: json['virtueAlignment'] as String,
      milestones: (json['milestones'] as List<dynamic>?)
              ?.map((m) => CommitmentMilestone.fromJson(m as Map<String, dynamic>))
              .toList() ??
          const [],
      struggleTags: (json['struggleTags'] as List<dynamic>?)
              ?.map((s) => s.toString())
              .toList() ??
          const [],
      category: CommitmentCategory.fromString(
        json['category'] as String? ?? 'growth',
      ),
      tips: (json['tips'] as List<dynamic>?)?.map((t) => t.toString()).toList() ??
          const [],
      baseRequirement: json['baseRequirement'] as String?,
      encouragement: json['encouragement'] as String?,
      failureGrace: json['failureGrace'] as String?,
    );
  }
}

/// Tracks a user's active journey with their prayer intention and progress.
class ActiveJourney {
  const ActiveJourney({
    required this.journeyId,
    required this.startedAt,
    required this.prayerIntention,
    this.currentDay = 1,
    this.completedDays = const {},
    this.lastCheckInAt,
    this.status = JourneyStatus.active,
    this.milestonesReached = const {},
  });

  final String journeyId;
  final DateTime startedAt;
  final String prayerIntention; // "What I ask God to do in me"
  final int currentDay;
  final Set<int> completedDays; // Which days have been checked in
  final DateTime? lastCheckInAt;
  final JourneyStatus status;
  final Set<int> milestonesReached; // Which milestone days were celebrated

  int get daysRemaining => _calculateDaysRemaining();
  double get progressPercent => completedDays.length / _totalDays;
  bool get isComplete => status == JourneyStatus.completed;
  bool get isActive => status == JourneyStatus.active;
  int get streakDays => _calculateStreak();

  int get _totalDays {
    // Parse from journeyId or default to 40
    if (journeyId.contains('seed')) return 3;
    if (journeyId.contains('path')) return 10;
    return 40;
  }

  int _calculateDaysRemaining() {
    final elapsed = DateTime.now().difference(startedAt).inDays + 1;
    final remaining = _totalDays - elapsed;
    return remaining.clamp(0, _totalDays);
  }

  int _calculateStreak() {
    if (completedDays.isEmpty) return 0;
    final sorted = completedDays.toList()..sort();
    int streak = 1;
    for (int i = sorted.length - 1; i > 0; i--) {
      if (sorted[i] - sorted[i - 1] == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  /// Mark today as checked in.
  ActiveJourney checkInToday() {
    final today = DateTime.now().difference(startedAt).inDays + 1;
    final updatedCompleted = Set<int>.from(completedDays)..add(today);
    return copyWith(
      completedDays: updatedCompleted,
      lastCheckInAt: DateTime.now(),
    );
  }

  /// Advance to the next day (called at midnight or on check-in).
  ActiveJourney advanceDay() {
    final nextDay = currentDay + 1;
    if (nextDay > _totalDays) {
      return copyWith(status: JourneyStatus.completed);
    }
    return copyWith(currentDay: nextDay);
  }

  /// Mark a milestone as reached.
  ActiveJourney reachMilestone(int milestoneDay) {
    final updated = Set<int>.from(milestonesReached)..add(milestoneDay);
    return copyWith(milestonesReached: updated);
  }

  ActiveJourney copyWith({
    String? journeyId,
    DateTime? startedAt,
    String? prayerIntention,
    int? currentDay,
    Set<int>? completedDays,
    DateTime? lastCheckInAt,
    JourneyStatus? status,
    Set<int>? milestonesReached,
  }) {
    return ActiveJourney(
      journeyId: journeyId ?? this.journeyId,
      startedAt: startedAt ?? this.startedAt,
      prayerIntention: prayerIntention ?? this.prayerIntention,
      currentDay: currentDay ?? this.currentDay,
      completedDays: completedDays ?? this.completedDays,
      lastCheckInAt: lastCheckInAt ?? this.lastCheckInAt,
      status: status ?? this.status,
      milestonesReached: milestonesReached ?? this.milestonesReached,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'journeyId': journeyId,
      'startedAt': startedAt.toIso8601String(),
      'prayerIntention': prayerIntention,
      'currentDay': currentDay,
      'completedDays': completedDays.toList(),
      'lastCheckInAt': lastCheckInAt?.toIso8601String(),
      'status': status.name,
      'milestonesReached': milestonesReached.toList(),
    };
  }

  factory ActiveJourney.fromJson(Map<String, dynamic> json) {
    return ActiveJourney(
      journeyId: json['journeyId'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      prayerIntention: json['prayerIntention'] as String? ?? '',
      currentDay: json['currentDay'] as int? ?? 1,
      completedDays: ((json['completedDays'] as List<dynamic>?) ?? [])
          .map((d) => d as int)
          .toSet(),
      lastCheckInAt: json['lastCheckInAt'] != null
          ? DateTime.parse(json['lastCheckInAt'] as String)
          : null,
      status: JourneyStatus.values.firstWhere(
        (s) => s.name == (json['status'] as String? ?? 'active'),
        orElse: () => JourneyStatus.active,
      ),
      milestonesReached: ((json['milestonesReached'] as List<dynamic>?) ?? [])
          .map((m) => m as int)
          .toSet(),
    );
  }
}

enum JourneyStatus { active, completed, abandoned, paused }
