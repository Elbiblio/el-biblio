enum GoalStatus {
  notStarted,
  active,
  completed,
  abandoned;

  String get label => switch (this) {
        notStarted => 'Not Started',
        active => 'Active',
        completed => 'Completed',
        abandoned => 'Abandoned',
      };
}

class FortyDayGoal {
  final String id;
  final String title;
  final String category;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final List<DailyGoalTask> dailyTasks;
  final Map<int, DayCompletion> completions;
  final GoalStatus status;

  const FortyDayGoal({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.dailyTasks,
    this.completions = const {},
    this.status = GoalStatus.notStarted,
  });

  int get currentDay {
    final days = DateTime.now().difference(startDate).inDays + 1;
    return days.clamp(1, 40);
  }

  double get progress => completions.length / 40.0;

  int get streakDays {
    if (completions.isEmpty) return 0;
    int streak = 0;
    for (int day = currentDay; day >= 1; day--) {
      if (completions.containsKey(day)) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  int get totalCompletedDays => completions.length;

  bool get isToday {
    final now = DateTime.now();
    return now.isAfter(startDate.subtract(const Duration(days: 1))) &&
        now.isBefore(endDate.add(const Duration(days: 1)));
  }

  DailyGoalTask? get todayTask {
    final day = currentDay;
    if (day < 1 || day > dailyTasks.length) return null;
    return dailyTasks[day - 1];
  }

  bool isDayCompleted(int dayNumber) => completions.containsKey(dayNumber);

  FortyDayGoal copyWith({
    String? id,
    String? title,
    String? category,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    List<DailyGoalTask>? dailyTasks,
    Map<int, DayCompletion>? completions,
    GoalStatus? status,
  }) {
    return FortyDayGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      dailyTasks: dailyTasks ?? this.dailyTasks,
      completions: completions ?? this.completions,
      status: status ?? this.status,
    );
  }

  factory FortyDayGoal.fromJson(Map<String, dynamic> json) {
    final completionsMap = <int, DayCompletion>{};
    if (json['completions'] != null) {
      (json['completions'] as Map<String, dynamic>).forEach((key, value) {
        completionsMap[int.parse(key)] =
            DayCompletion.fromJson(value as Map<String, dynamic>);
      });
    }

    return FortyDayGoal(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      description: json['description'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      dailyTasks: (json['dailyTasks'] as List)
          .map((e) => DailyGoalTask.fromJson(e as Map<String, dynamic>))
          .toList(),
      completions: completionsMap,
      status: GoalStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => GoalStatus.notStarted,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'dailyTasks': dailyTasks.map((e) => e.toJson()).toList(),
      'completions': completions.map(
        (key, value) => MapEntry(key.toString(), value.toJson()),
      ),
      'status': status.name,
    };
  }
}

class DailyGoalTask {
  final int dayNumber;
  final String title;
  final String description;
  final int durationMinutes;
  final String reflectionPrompt;
  final String relatedVerse;

  const DailyGoalTask({
    required this.dayNumber,
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.reflectionPrompt,
    required this.relatedVerse,
  });

  factory DailyGoalTask.fromJson(Map<String, dynamic> json) {
    return DailyGoalTask(
      dayNumber: json['dayNumber'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      durationMinutes: json['durationMinutes'] as int,
      reflectionPrompt: json['reflectionPrompt'] as String,
      relatedVerse: json['relatedVerse'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dayNumber': dayNumber,
      'title': title,
      'description': description,
      'durationMinutes': durationMinutes,
      'reflectionPrompt': reflectionPrompt,
      'relatedVerse': relatedVerse,
    };
  }
}

class DayCompletion {
  final int dayNumber;
  final DateTime completedAt;
  final String? reflectionNote;
  final int rating;

  const DayCompletion({
    required this.dayNumber,
    required this.completedAt,
    this.reflectionNote,
    this.rating = 3,
  });

  factory DayCompletion.fromJson(Map<String, dynamic> json) {
    return DayCompletion(
      dayNumber: json['dayNumber'] as int,
      completedAt: DateTime.parse(json['completedAt'] as String),
      reflectionNote: json['reflectionNote'] as String?,
      rating: json['rating'] as int? ?? 3,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dayNumber': dayNumber,
      'completedAt': completedAt.toIso8601String(),
      'reflectionNote': reflectionNote,
      'rating': rating,
    };
  }
}
