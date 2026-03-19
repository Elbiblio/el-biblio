import 'package:json_annotation/json_annotation.dart';

part 'user_profile.g.dart';

@JsonSerializable()
class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.role,
    this.status,
    this.avatarUrl,
    required this.createdAt,
    this.timezone,
    this.points = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalActiveTime = 0,
    this.memberSince,
    this.badges = const [],
    this.stats,
  });

  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String? role;
  final String? status;
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  final String? timezone;
  final int points;
  @JsonKey(name: 'current_streak')
  final int currentStreak;
  @JsonKey(name: 'longest_streak')
  final int longestStreak;
  @JsonKey(name: 'total_active_time')
  final int totalActiveTime;
  @JsonKey(name: 'member_since')
  final DateTime? memberSince;
  final List<String> badges;
  final UserStats? stats;

  factory UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);
  Map<String, dynamic> toJson() => _$UserProfileToJson(this);

  /// Creates a guest profile for offline use
  static UserProfile createGuestProfile() {
    return UserProfile(
      id: 0,
      name: 'Guest User',
      email: 'guest@elbiblio.com',
      createdAt: DateTime.now(),
      points: 0,
      currentStreak: 0,
      longestStreak: 0,
      totalActiveTime: 0,
      badges: [],
    );
  }
}

@JsonSerializable()
class UserStats {
  const UserStats({
    this.totalVersesRead = 0,
    this.totalReflections = 0,
    this.totalBookmarks = 0,
    this.totalActivities = 0,
    this.totalPoints = 0,
    this.totalMeditationSessions = 0,
    this.totalChallengesCompleted = 0,
    this.totalActiveTime = 0,
    this.totalActiveDays = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.rank = 0,
    this.level = 0,
  });

  @JsonKey(name: 'total_verses_read')
  final int totalVersesRead;
  @JsonKey(name: 'total_reflections')
  final int totalReflections;
  @JsonKey(name: 'total_bookmarks')
  final int totalBookmarks;
  @JsonKey(name: 'total_activities')
  final int totalActivities;
  @JsonKey(name: 'total_points')
  final int totalPoints;
  @JsonKey(name: 'total_meditation_sessions')
  final int totalMeditationSessions;
  @JsonKey(name: 'total_challenges_completed')
  final int totalChallengesCompleted;
  @JsonKey(name: 'total_active_time')
  final int totalActiveTime;
  @JsonKey(name: 'total_active_days')
  final int totalActiveDays;
  @JsonKey(name: 'current_streak')
  final int currentStreak;
  @JsonKey(name: 'longest_streak')
  final int longestStreak;
  final int rank;
  final int level;

  factory UserStats.fromJson(Map<String, dynamic> json) => _$UserStatsFromJson(json);
  Map<String, dynamic> toJson() => _$UserStatsToJson(this);

  /// Creates guest stats for offline use
  static UserStats createGuestStats() {
    return const UserStats(
      totalVersesRead: 0,
      totalReflections: 0,
      totalBookmarks: 0,
      totalActivities: 0,
      totalPoints: 0,
      totalMeditationSessions: 0,
      totalChallengesCompleted: 0,
      totalActiveTime: 0,
      totalActiveDays: 0,
      currentStreak: 0,
      longestStreak: 0,
      rank: 0,
      level: 1,
    );
  }
}
