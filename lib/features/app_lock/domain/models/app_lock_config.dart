import 'dart:convert';

class AppLockConfig {
  final String id;
  final String appName;
  final String packageName;
  final int dailyLimitMinutes;
  final bool isEnabled;
  final String category; // social, entertainment, news, gaming, other
  final DateTime createdAt;

  AppLockConfig({
    required this.id,
    required this.appName,
    required this.packageName,
    required this.dailyLimitMinutes,
    this.isEnabled = true,
    required this.category,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  AppLockConfig copyWith({
    String? id,
    String? appName,
    String? packageName,
    int? dailyLimitMinutes,
    bool? isEnabled,
    String? category,
    DateTime? createdAt,
  }) {
    return AppLockConfig(
      id: id ?? this.id,
      appName: appName ?? this.appName,
      packageName: packageName ?? this.packageName,
      dailyLimitMinutes: dailyLimitMinutes ?? this.dailyLimitMinutes,
      isEnabled: isEnabled ?? this.isEnabled,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appName': appName,
      'packageName': packageName,
      'dailyLimitMinutes': dailyLimitMinutes,
      'isEnabled': isEnabled,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AppLockConfig.fromJson(Map<String, dynamic> json) {
    return AppLockConfig(
      id: json['id'] as String,
      appName: json['appName'] as String,
      packageName: json['packageName'] as String,
      dailyLimitMinutes: json['dailyLimitMinutes'] as int,
      isEnabled: json['isEnabled'] as bool? ?? true,
      category: json['category'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  String encode() => jsonEncode(toJson());

  factory AppLockConfig.decode(String source) =>
      AppLockConfig.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
