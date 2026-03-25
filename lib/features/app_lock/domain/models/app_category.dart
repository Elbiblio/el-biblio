import 'package:flutter/material.dart';

enum AppCategory {
  social(
    id: 'social',
    label: 'Social Media',
    icon: Icons.people_rounded,
    color: Color(0xFF5B8DEF),
    suggestedLimitMinutes: 60,
  ),
  entertainment(
    id: 'entertainment',
    label: 'Entertainment',
    icon: Icons.movie_rounded,
    color: Color(0xFFE87D5F),
    suggestedLimitMinutes: 90,
  ),
  news(
    id: 'news',
    label: 'News',
    icon: Icons.newspaper_rounded,
    color: Color(0xFF6BBF8A),
    suggestedLimitMinutes: 30,
  ),
  gaming(
    id: 'gaming',
    label: 'Gaming',
    icon: Icons.sports_esports_rounded,
    color: Color(0xFFA97BDB),
    suggestedLimitMinutes: 60,
  ),
  other(
    id: 'other',
    label: 'Other',
    icon: Icons.apps_rounded,
    color: Color(0xFF8B9BAF),
    suggestedLimitMinutes: 60,
  );

  const AppCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.suggestedLimitMinutes,
  });

  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final int suggestedLimitMinutes;

  static AppCategory fromId(String id) {
    return AppCategory.values.firstWhere(
      (c) => c.id == id,
      orElse: () => AppCategory.other,
    );
  }
}

class PopularApp {
  final String name;
  final String packageName;
  final AppCategory category;
  final IconData icon;

  const PopularApp({
    required this.name,
    required this.packageName,
    required this.category,
    required this.icon,
  });
}

const List<PopularApp> popularApps = [
  // Social Media
  PopularApp(
    name: 'Instagram',
    packageName: 'com.instagram.android',
    category: AppCategory.social,
    icon: Icons.camera_alt_rounded,
  ),
  PopularApp(
    name: 'Facebook',
    packageName: 'com.facebook.katana',
    category: AppCategory.social,
    icon: Icons.facebook_rounded,
  ),
  PopularApp(
    name: 'TikTok',
    packageName: 'com.zhiliaoapp.musically',
    category: AppCategory.social,
    icon: Icons.music_note_rounded,
  ),
  PopularApp(
    name: 'Twitter / X',
    packageName: 'com.twitter.android',
    category: AppCategory.social,
    icon: Icons.tag_rounded,
  ),
  PopularApp(
    name: 'Snapchat',
    packageName: 'com.snapchat.android',
    category: AppCategory.social,
    icon: Icons.photo_camera_front_rounded,
  ),
  PopularApp(
    name: 'Reddit',
    packageName: 'com.reddit.frontpage',
    category: AppCategory.social,
    icon: Icons.forum_rounded,
  ),

  // Entertainment
  PopularApp(
    name: 'YouTube',
    packageName: 'com.google.android.youtube',
    category: AppCategory.entertainment,
    icon: Icons.play_circle_rounded,
  ),
  PopularApp(
    name: 'Netflix',
    packageName: 'com.netflix.mediaclient',
    category: AppCategory.entertainment,
    icon: Icons.tv_rounded,
  ),
  PopularApp(
    name: 'Spotify',
    packageName: 'com.spotify.music',
    category: AppCategory.entertainment,
    icon: Icons.headphones_rounded,
  ),
  PopularApp(
    name: 'Twitch',
    packageName: 'tv.twitch.android.app',
    category: AppCategory.entertainment,
    icon: Icons.live_tv_rounded,
  ),

  // News
  PopularApp(
    name: 'Google News',
    packageName: 'com.google.android.apps.magazines',
    category: AppCategory.news,
    icon: Icons.article_rounded,
  ),
  PopularApp(
    name: 'Apple News',
    packageName: 'com.apple.news',
    category: AppCategory.news,
    icon: Icons.newspaper_rounded,
  ),

  // Gaming
  PopularApp(
    name: 'Roblox',
    packageName: 'com.roblox.client',
    category: AppCategory.gaming,
    icon: Icons.videogame_asset_rounded,
  ),
  PopularApp(
    name: 'Candy Crush',
    packageName: 'com.king.candycrushsaga',
    category: AppCategory.gaming,
    icon: Icons.grid_view_rounded,
  ),
  PopularApp(
    name: 'Clash of Clans',
    packageName: 'com.supercell.clashofclans',
    category: AppCategory.gaming,
    icon: Icons.shield_rounded,
  ),
];
