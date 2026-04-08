import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/xp_service.dart';

/// XP state for the application
class XPState {
  final int totalXP;
  final int todayXP;
  final int weeklyXP;
  final int monthlyXP;
  final Map<XPActivityType, int> xpBreakdown;
  final bool isLoading;
  final List<XPActivity> activities;

  const XPState({
    required this.totalXP,
    required this.todayXP,
    required this.weeklyXP,
    required this.monthlyXP,
    required this.xpBreakdown,
    required this.isLoading,
    this.activities = const [],
  });

  XPState.initial()
      : totalXP = 0,
        todayXP = 0,
        weeklyXP = 0,
        monthlyXP = 0,
        xpBreakdown = {},
        isLoading = false,
        activities = [];

  XPState copyWith({
    int? totalXP,
    int? todayXP,
    int? weeklyXP,
    int? monthlyXP,
    Map<XPActivityType, int>? xpBreakdown,
    bool? isLoading,
    List<XPActivity>? activities,
  }) {
    return XPState(
      totalXP: totalXP ?? this.totalXP,
      todayXP: todayXP ?? this.todayXP,
      weeklyXP: weeklyXP ?? this.weeklyXP,
      monthlyXP: monthlyXP ?? this.monthlyXP,
      xpBreakdown: xpBreakdown ?? this.xpBreakdown,
      isLoading: isLoading ?? this.isLoading,
      activities: activities ?? this.activities,
    );
  }
}

/// Notifier for managing XP state
class XPNotifier extends StateNotifier<XPState> {
  final XPService _xpService;

  XPNotifier(this._xpService) : super(XPState.initial()) {
    _initialize();
  }

  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);
    await _xpService.initialize();
    await _refreshXPData();
    state = state.copyWith(isLoading: false);
  }

  Future<void> _refreshXPData() async {
    final totalXP = _xpService.getTotalXP();
    final todayXP = _xpService.getTodayXP();
    final weeklyXP = _xpService.getWeeklyXP();
    final monthlyXP = _xpService.getMonthlyXP();
    final xpBreakdown = _xpService.getXPBreakdown();
    final activities = _xpService.getActivitiesInRange(
      DateTime.now().subtract(const Duration(days: 90)),
      DateTime.now(),
    );

    state = state.copyWith(
      totalXP: totalXP,
      todayXP: todayXP,
      weeklyXP: weeklyXP,
      monthlyXP: monthlyXP,
      xpBreakdown: xpBreakdown,
      activities: activities,
    );
  }

  /// Add XP for a completed activity
  Future<void> addXP({
    required XPActivityType type,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    await _xpService.addXP(
      type: type,
      description: description,
      metadata: metadata,
    );
    await _refreshXPData();
  }

  /// Refresh XP data
  Future<void> refreshXP() async {
    await _refreshXPData();
  }

  /// Get formatted XP string
  String getFormattedXP(int xp) {
    if (xp >= 1000) {
      final value = xp / 1000;
      return '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}k';
    }
    return xp.toString();
  }

  /// Get XP percentage change for this month
  double getMonthlyXPChange() {
    // Calculate actual percentage change from last month
    final now = DateTime.now();
    final lastMonth = now.subtract(const Duration(days: 30));

    final thisMonthXP = getRecentXP(days: 30);
    final lastMonthXP = _getHistoricalXPForPeriod(lastMonth.subtract(const Duration(days: 30)), lastMonth);

    if (lastMonthXP == 0) return thisMonthXP > 0 ? 1.0 : 0.0;
    return (thisMonthXP - lastMonthXP) / lastMonthXP;
  }

  /// Get XP earned in the last N days
  int getRecentXP({required int days}) {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));
    return _getHistoricalXPForPeriod(startDate, now);
  }

  int _getHistoricalXPForPeriod(DateTime start, DateTime end) {
    // Sum XP from activities within the date range
    return state.activities
        .where((a) => a.timestamp.isAfter(start) && a.timestamp.isBefore(end))
        .fold(0, (sum, a) => sum + a.xpAmount);
  }

  @override
  void dispose() {
    _xpService.dispose();
    super.dispose();
  }
}
