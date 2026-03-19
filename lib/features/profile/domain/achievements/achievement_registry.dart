import 'achievement_badge.dart';

class AchievementRegistry {
  static const List<AchievementBadge> all = [
    AchievementBadge(
      id: 'streak_3',
      title: 'Spark',
      description: '3-day streak of daily check-ins.',
      icon: '🔥',
    ),
    AchievementBadge(
      id: 'streak_7',
      title: 'Rhythm',
      description: '7-day streak of daily check-ins.',
      icon: '🔥',
    ),
    AchievementBadge(
      id: 'streak_14',
      title: 'Steadfast',
      description: '14-day streak of daily check-ins.',
      icon: '🔥',
    ),
    AchievementBadge(
      id: 'integrity_8',
      title: 'Aligned',
      description: 'Earned 8+ integrity points in a day.',
      icon: '✅',
    ),
    AchievementBadge(
      id: 'integrity_12',
      title: 'Unshakable',
      description: 'Earned 12+ integrity points in a day.',
      icon: '🏆',
    ),
    AchievementBadge(
      id: 'comeback',
      title: 'Return',
      description: 'Came back after missing a few days.',
      icon: '↩️',
    ),
  ];

  static AchievementBadge? byId(String id) {
    for (final badge in all) {
      if (badge.id == id) return badge;
    }
    return null;
  }
}
