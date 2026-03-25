import 'dart:convert';

class UsageSession {
  final DateTime startTime;
  final DateTime? endTime;
  final int durationMinutes;

  UsageSession({
    required this.startTime,
    this.endTime,
    required this.durationMinutes,
  });

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'durationMinutes': durationMinutes,
    };
  }

  factory UsageSession.fromJson(Map<String, dynamic> json) {
    return UsageSession(
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      durationMinutes: json['durationMinutes'] as int,
    );
  }
}

class AppUsageRecord {
  final String packageName;
  final String appName;
  final int usedMinutesToday;
  final int dailyLimitMinutes;
  final DateTime date;
  final List<UsageSession> sessions;

  AppUsageRecord({
    required this.packageName,
    required this.appName,
    required this.usedMinutesToday,
    required this.dailyLimitMinutes,
    required this.date,
    this.sessions = const [],
  });

  double get usagePercentage => dailyLimitMinutes > 0
      ? (usedMinutesToday / dailyLimitMinutes).clamp(0.0, 1.0)
      : 0.0;

  bool get isLimitReached => usedMinutesToday >= dailyLimitMinutes;

  int get remainingMinutes =>
      (dailyLimitMinutes - usedMinutesToday).clamp(0, dailyLimitMinutes);

  AppUsageRecord copyWith({
    String? packageName,
    String? appName,
    int? usedMinutesToday,
    int? dailyLimitMinutes,
    DateTime? date,
    List<UsageSession>? sessions,
  }) {
    return AppUsageRecord(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      usedMinutesToday: usedMinutesToday ?? this.usedMinutesToday,
      dailyLimitMinutes: dailyLimitMinutes ?? this.dailyLimitMinutes,
      date: date ?? this.date,
      sessions: sessions ?? this.sessions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'packageName': packageName,
      'appName': appName,
      'usedMinutesToday': usedMinutesToday,
      'dailyLimitMinutes': dailyLimitMinutes,
      'date': date.toIso8601String(),
      'sessions': sessions.map((s) => s.toJson()).toList(),
    };
  }

  factory AppUsageRecord.fromJson(Map<String, dynamic> json) {
    return AppUsageRecord(
      packageName: json['packageName'] as String,
      appName: json['appName'] as String,
      usedMinutesToday: json['usedMinutesToday'] as int,
      dailyLimitMinutes: json['dailyLimitMinutes'] as int,
      date: DateTime.parse(json['date'] as String),
      sessions: (json['sessions'] as List<dynamic>?)
              ?.map((s) => UsageSession.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  String encode() => jsonEncode(toJson());

  factory AppUsageRecord.decode(String source) =>
      AppUsageRecord.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
