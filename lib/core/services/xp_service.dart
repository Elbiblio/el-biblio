import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import '../storage/hive_boxes.dart';

/// XP Activity types for different user actions
enum XPActivityType {
  physicalActivity,
  meditation,
  bibleReading,
  journaling,
  dailyCheckIn,
  commitment,
  verseGame,
  socialConnection,
}

/// XP Activity data model
class XPActivity {
  final String id;
  final XPActivityType type;
  final String description;
  final int xpAmount;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  XPActivity({
    required this.id,
    required this.type,
    required this.description,
    required this.xpAmount,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'description': description,
      'xpAmount': xpAmount,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory XPActivity.fromMap(Map<String, dynamic> map) {
    return XPActivity(
      id: map['id'],
      type: XPActivityType.values.firstWhere((e) => e.name == map['type']),
      description: map['description'],
      xpAmount: map['xpAmount'],
      timestamp: DateTime.parse(map['timestamp']),
      metadata: map['metadata'],
    );
  }
}

/// XP rewards configuration
class XPRewards {
  static const int physicalActivity = 25;
  static const int meditation = 20;
  static const int bibleReading = 15;
  static const int journaling = 10;
  static const int dailyCheckIn = 5;
  static const int commitment = 30;
  static const int verseGame = 8;
  static const int socialConnection = 12;

  static int getRewardForActivity(XPActivityType type) {
    switch (type) {
      case XPActivityType.physicalActivity:
        return physicalActivity;
      case XPActivityType.meditation:
        return meditation;
      case XPActivityType.bibleReading:
        return bibleReading;
      case XPActivityType.journaling:
        return journaling;
      case XPActivityType.dailyCheckIn:
        return dailyCheckIn;
      case XPActivityType.commitment:
        return commitment;
      case XPActivityType.verseGame:
        return verseGame;
      case XPActivityType.socialConnection:
        return socialConnection;
    }
  }
}

/// Service for tracking and managing user XP
class XPService {
  static XPService? _instance;
  static XPService get instance => _instance ??= XPService._();
  XPService._();

  Box<dynamic>? _xpActivitiesBox;
  Box<int>? _xpTotalsBox;
  Future<void>? _initializeFuture;

  Box<dynamic> get _xpBox {
    final box = _xpActivitiesBox;
    if (box == null || !box.isOpen) {
      throw StateError('XPService has not been initialized.');
    }
    return box;
  }

  Box<int> get _xpTotalBox {
    final box = _xpTotalsBox;
    if (box == null || !box.isOpen) {
      throw StateError('XPService has not been initialized.');
    }
    return box;
  }

  final StreamController<int> _xpStreamController =
      StreamController<int>.broadcast();
  Stream<int> get xpStream => _xpStreamController.stream;

  Future<void> initialize() async {
    final activitiesReady = _xpActivitiesBox?.isOpen ?? false;
    final totalsReady = _xpTotalsBox?.isOpen ?? false;
    if (activitiesReady && totalsReady) {
      return;
    }

    final pending = _initializeFuture;
    if (pending != null) {
      return pending;
    }

    final future = _openBoxes();
    _initializeFuture = future;
    try {
      await future;
      _initializeFuture = null;
    } catch (_) {
      _initializeFuture = null;
      rethrow;
    }
  }

  Future<void> _openBoxes() async {
    _xpActivitiesBox = Hive.isBoxOpen(HiveBoxes.xpActivities)
        ? Hive.box<dynamic>(HiveBoxes.xpActivities)
        : await Hive.openBox<dynamic>(HiveBoxes.xpActivities);
    _xpTotalsBox = Hive.isBoxOpen(HiveBoxes.xpTotals)
        ? Hive.box<int>(HiveBoxes.xpTotals)
        : await Hive.openBox<int>(HiveBoxes.xpTotals);
  }

  /// Add XP for a completed activity
  Future<void> addXP({
    required XPActivityType type,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    await initialize();

    final activity = XPActivity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      description: description,
      xpAmount: XPRewards.getRewardForActivity(type),
      timestamp: DateTime.now(),
      metadata: metadata,
    );

    await _xpBox.put(activity.id, activity.toMap());

    // Update total XP
    final currentTotal = _xpTotalBox.get('total', defaultValue: 0) ?? 0;
    final newTotal = currentTotal + activity.xpAmount;
    await _xpTotalBox.put('total', newTotal);

    // Broadcast XP change
    _xpStreamController.add(newTotal);
  }

  /// Get current total XP
  int getTotalXP() {
    return _xpTotalBox.get('total', defaultValue: 0) ?? 0;
  }

  /// Get XP activities for today
  List<XPActivity> getTodayActivities() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return _xpBox.values
        .map((map) => XPActivity.fromMap(map as Map<String, dynamic>))
        .where((activity) {
          return activity.timestamp.isAfter(today) &&
              activity.timestamp.isBefore(tomorrow);
        })
        .toList();
  }

  /// Get XP activities for a specific date range
  List<XPActivity> getActivitiesInRange(DateTime start, DateTime end) {
    return _xpBox.values
        .map((map) => XPActivity.fromMap(map as Map<String, dynamic>))
        .where((activity) {
          return activity.timestamp.isAfter(start) &&
              activity.timestamp.isBefore(end);
        })
        .toList();
  }

  /// Get XP earned today
  int getTodayXP() {
    return getTodayActivities().fold(
      0,
      (sum, activity) => sum + activity.xpAmount,
    );
  }

  /// Get XP earned this week
  int getWeeklyXP() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDay = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day,
    );

    return getActivitiesInRange(
      weekStartDay,
      now,
    ).fold(0, (sum, activity) => sum + activity.xpAmount);
  }

  /// Get XP earned this month
  int getMonthlyXP() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    return getActivitiesInRange(
      monthStart,
      now,
    ).fold(0, (sum, activity) => sum + activity.xpAmount);
  }

  /// Get XP breakdown by activity type
  Map<XPActivityType, int> getXPBreakdown() {
    final Map<XPActivityType, int> breakdown = {};

    for (final map in _xpBox.values) {
      final activity = XPActivity.fromMap(map as Map<String, dynamic>);
      breakdown[activity.type] =
          (breakdown[activity.type] ?? 0) + activity.xpAmount;
    }

    return breakdown;
  }

  /// Clear all XP data (for testing/reset)
  Future<void> clearAllXP() async {
    await initialize();
    await _xpBox.clear();
    await _xpTotalBox.clear();
    _xpStreamController.add(0);
  }

  /// Dispose resources
  void dispose() {
    _xpStreamController.close();
  }
}
