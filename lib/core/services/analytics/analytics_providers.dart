import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'analytics_service.dart';

/// Provider for the analytics service
/// 
/// Can be overridden in tests or for production analytics
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  // Currently using debug analytics - swap for production implementation
  return DebugAnalyticsService();
});

/// Provider for analytics-enabled state notifier
/// 
/// Use this as a mixin pattern for notifiers that need analytics
final analyticsProvider = Provider((ref) => ref.watch(analyticsServiceProvider));

/// Extension to easily access analytics from WidgetRef
extension AnalyticsRefExtension on WidgetRef {
  AnalyticsService get analytics => read(analyticsProvider);
}

/// Extension to easily access analytics from Ref
extension AnalyticsRef on Ref {
  AnalyticsService get analytics => read(analyticsProvider);
}
