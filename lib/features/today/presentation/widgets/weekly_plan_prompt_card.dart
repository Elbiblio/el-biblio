import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/theme/app_animations.dart';
import '../../../assessment/domain/models/weekly_plan.dart';

/// A compact prompt card shown on the Today screen when it is Monday and
/// there is no weekly plan for the current week.
///
/// Tapping navigates to [AppRoutes.weeklyAssessment] so the user can
/// interactively create their plan for the week.
class WeeklyPlanPromptCard extends ConsumerStatefulWidget {
  const WeeklyPlanPromptCard({super.key});

  /// Returns `true` when the card should be visible:
  /// - Today is Monday, AND
  /// - There is no weekly plan whose week matches the current week.
  static bool shouldShow({
    required WeeklyPlan? currentPlan,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    if (today.weekday != DateTime.monday) return false;

    if (currentPlan == null) return true;

    // Check if the plan's week matches the current week
    final weekStart = _startOfWeek(today);
    final planId = WeeklyPlan.generateId(weekStart);
    return currentPlan.id != planId;
  }

  static DateTime _startOfWeek(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  @override
  ConsumerState<WeeklyPlanPromptCard> createState() =>
      _WeeklyPlanPromptCardState();
}

class _WeeklyPlanPromptCardState extends ConsumerState<WeeklyPlanPromptCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.slow,
    );
    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.fadeCurve,
    );
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.defaultCurve,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SlideTransition(
      position: _slideIn,
      child: FadeTransition(
        opacity: _fadeIn,
        child: GestureDetector(
          onTap: () {
            HapticService.selection();
            context.push(AppRoutes.weeklyAssessment);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.1),
                  theme.colorScheme.primary.withValues(alpha: 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color:
                        theme.colorScheme.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.calendar_today_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Set Your Weekly Focus',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Reflect on last week and plan your growth',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: theme.colorScheme.primary.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
