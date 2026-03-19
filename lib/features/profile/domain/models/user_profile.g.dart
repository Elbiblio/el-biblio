// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => UserProfile(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      role: json['role'] as String?,
      status: json['status'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      timezone: json['timezone'] as String?,
      points: (json['points'] as num?)?.toInt() ?? 0,
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longest_streak'] as num?)?.toInt() ?? 0,
      totalActiveTime: (json['total_active_time'] as num?)?.toInt() ?? 0,
      memberSince: json['member_since'] == null
          ? null
          : DateTime.parse(json['member_since'] as String),
      badges: (json['badges'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      stats: json['stats'] == null
          ? null
          : UserStats.fromJson(json['stats'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserProfileToJson(UserProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'phone': instance.phone,
      'role': instance.role,
      'status': instance.status,
      'avatar_url': instance.avatarUrl,
      'created_at': instance.createdAt.toIso8601String(),
      'timezone': instance.timezone,
      'points': instance.points,
      'current_streak': instance.currentStreak,
      'longest_streak': instance.longestStreak,
      'total_active_time': instance.totalActiveTime,
      'member_since': instance.memberSince?.toIso8601String(),
      'badges': instance.badges,
      'stats': instance.stats,
    };

UserStats _$UserStatsFromJson(Map<String, dynamic> json) => UserStats(
      totalVersesRead: (json['total_verses_read'] as num?)?.toInt() ?? 0,
      totalReflections: (json['total_reflections'] as num?)?.toInt() ?? 0,
      totalBookmarks: (json['total_bookmarks'] as num?)?.toInt() ?? 0,
      totalActivities: (json['total_activities'] as num?)?.toInt() ?? 0,
      totalPoints: (json['total_points'] as num?)?.toInt() ?? 0,
      totalMeditationSessions:
          (json['total_meditation_sessions'] as num?)?.toInt() ?? 0,
      totalChallengesCompleted:
          (json['total_challenges_completed'] as num?)?.toInt() ?? 0,
      totalActiveTime: (json['total_active_time'] as num?)?.toInt() ?? 0,
      totalActiveDays: (json['total_active_days'] as num?)?.toInt() ?? 0,
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longest_streak'] as num?)?.toInt() ?? 0,
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$UserStatsToJson(UserStats instance) => <String, dynamic>{
      'total_verses_read': instance.totalVersesRead,
      'total_reflections': instance.totalReflections,
      'total_bookmarks': instance.totalBookmarks,
      'total_activities': instance.totalActivities,
      'total_points': instance.totalPoints,
      'total_meditation_sessions': instance.totalMeditationSessions,
      'total_challenges_completed': instance.totalChallengesCompleted,
      'total_active_time': instance.totalActiveTime,
      'total_active_days': instance.totalActiveDays,
      'current_streak': instance.currentStreak,
      'longest_streak': instance.longestStreak,
      'rank': instance.rank,
      'level': instance.level,
    };
