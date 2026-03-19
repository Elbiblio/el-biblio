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

  const XPState({
    required this.totalXP,
    required this.todayXP,
    required this.weeklyXP,
    required this.monthlyXP,
    required this.xpBreakdown,
    required this.isLoading,
  });

  XPState.initial()
      : totalXP = 0,
        todayXP = 0,
        weeklyXP = 0,
        monthlyXP = 0,
        xpBreakdown = {},
        isLoading = false;

  XPState copyWith({
    int? totalXP,
    int? todayXP,
    int? weeklyXP,
    int? monthlyXP,
    Map<XPActivityType, int>? xpBreakdown,
    bool? isLoading,
  }) {
    return XPState(
      totalXP: totalXP ?? this.totalXP,
      todayXP: todayXP ?? this.todayXP,
      weeklyXP: weeklyXP ?? this.weeklyXP,
      monthlyXP: monthlyXP ?? this.monthlyXP,
      xpBreakdown: xpBreakdown ?? this.xpBreakdown,
      isLoading: isLoading ?? this.isLoading,
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

    state = state.copyWith(
      totalXP: totalXP,
      todayXP: todayXP,
      weeklyXP: weeklyXP,
      monthlyXP: monthlyXP,
      xpBreakdown: xpBreakdown,
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
    // This would require historical data comparison
    // For now, return a placeholder
    return 0.12; // 12% increase
  }

  @override
  void dispose() {
    _xpService.dispose();
    super.dispose();
  }
}
