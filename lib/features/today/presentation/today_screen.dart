import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/storage/settings_storage.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../domain/models/daily_anchors.dart';
import 'widgets/physical_activity_guide.dart';
import '../../commitments/presentation/widgets/commitment_welcome_dialog.dart';
import 'widgets/prayer_guide_dialog.dart';
import 'widgets/progress_reminder_dialog.dart';
import 'widgets/end_of_day_reflection_dialog.dart';
import 'widgets/first_aid_kit_dialog.dart';
import 'widgets/commitment_waiting_dialog.dart';
import 'widgets/commitment_completion_dialog.dart';
import 'widgets/habit_reset_dialog.dart';
import 'widgets/share_elbiblio_dialog.dart';
import 'widgets/time_diagnose_suggestion_dialog.dart';
import 'widgets/recalibration_suggestion_dialog.dart';
import 'widgets/today_header.dart';
import 'widgets/daily_focus_card.dart';
import 'widgets/quick_actions_row.dart';
import 'widgets/daily_rhythm_section.dart';
import 'helpers/share_helper.dart' as share_helper;

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  bool _isNearAlarmTime = false;

  @override
  void initState() {
    super.initState();
    // Check for missed days and alarm proximity when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForMissedDaysAndShowSuggestion();
      _checkAlarmProximity();
      _checkAndShowDailyPrayerGuide();
      // Refresh pillar scores on screen load
      ref.read(pillarScoreProvider.notifier).refresh();
    });
  }

  // ---------------------------------------------------------------------------
  // Lifecycle helpers
  // ---------------------------------------------------------------------------

  Future<void> _checkForMissedDaysAndShowSuggestion() async {
    final missedDays = await ref.read(dailyAnchorsProvider.notifier).getConsecutiveMissedDays();
    if (!mounted) return;

    if (missedDays < 2) return;

    final settings = ref.read(settingsProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastPrompt = settings.lastRecalibrationPromptDate;
    final lastPromptDay = lastPrompt == null
        ? null
        : DateTime(lastPrompt.year, lastPrompt.month, lastPrompt.day);

    if (lastPromptDay == today) return;

    await ref.read(settingsProvider.notifier).markRecalibrationPromptShown(today);

    if (!mounted) return;
    await RecalibrationSuggestionDialog.show(
      context,
      missedDays: missedDays,
      onOpenTimeDiagnose: () {
        TimeDiagnoseSuggestionDialog.show(context);
      },
    );
  }

  void _checkAlarmProximity() {
    final settings = ref.read(settingsProvider);
    final now = DateTime.now();

    // Parse morning time (default 07:30)
    final morningTimeParts = settings.morningTime.split(':');
    final morningHour = int.parse(morningTimeParts[0]);
    final morningMinute = int.parse(morningTimeParts[1]);
    final morningTime = DateTime(now.year, now.month, now.day, morningHour, morningMinute);

    // Check if within 30 minutes of alarm time
    final timeDifference = now.difference(morningTime);
    final isWithin30Minutes = timeDifference.inMinutes >= -30 && timeDifference.inMinutes <= 30;

    // Also check if it's early morning (5 AM - 10 AM) for simplified interface
    final isEarlyMorning = now.hour >= 5 && now.hour < 10;

    setState(() {
      _isNearAlarmTime = isWithin30Minutes || isEarlyMorning;
    });
  }

  Future<void> _checkAndShowDailyPrayerGuide() async {
    final settings = ref.read(settingsProvider);
    const storage = SettingsStorage();

    // Only show if onboarding is completed and it's morning hours
    if (!settings.onboardingCompleted) return;
    if (!storage.isMorningHours()) return;
    if (!storage.shouldShowPrayerGuide(settings)) return;

    // Get current virtue for prayer guide
    final anchors = ref.read(dailyAnchorsProvider);
    final virtue = anchors.coreVirtue;

    // Don't show if virtue is already completed
    if (virtue.isCompleted) return;

    // Show prayer guide dialog
    if (mounted) {
      PrayerGuideDialog.show(
        context,
        virtue,
        () async {
          // Mark prayer guide as shown and mark virtue as done
          await storage.markPrayerGuideShown();
          ref.read(dailyAnchorsProvider.notifier).markAnchorDone(AnchorType.coreVirtue);
        },
        showQuickStart: true,
      );

      // Mark as shown even if user dismisses (so it doesn't show again today)
      await storage.markPrayerGuideShown();
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final anchors = ref.watch(dailyAnchorsProvider);
    final tokens = Theme.of(context).tokens;
    final now = DateTime.now();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: tokens.pageGradient,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              // Header (profile, greeting, help & share buttons)
              SliverToBoxAdapter(
                child: TodayHeader(
                  onHelpTap: _showQuickHelp,
                  onShareTap: _showShareModal,
                ),
              ),

              // Daily Focus: archetype + progress + commitment in one card
              SliverToBoxAdapter(
                child: DailyFocusCard(
                  anchors: anchors,
                  onProgressTap: () => _showProgressReminder(anchors),
                ),
              ),

              // Quick Actions: horizontal chips for displaced features
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: QuickActionsRow(),
                ),
              ),

              // Daily Rhythm (time-based anchor display)
              DailyRhythmSection(
                anchors: anchors,
                now: now,
                onPrayerTap: _showPrayerGuide,
                onHabitTap: () => _handleHabitTap(anchors, now),
                onPhysicalActivityTap: _showPhysicalActivityGuide,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void _handleHabitTap(DailyAnchors anchors, DateTime now) async {
    final habit = anchors.habit;

    debugPrint('TodayScreen: _handleHabitTap called');
    debugPrint('TodayScreen: habit.isCompleted=${habit.isCompleted}');
    debugPrint('TodayScreen: habit.canStartCommitment=${habit.canStartCommitment}');
    debugPrint('TodayScreen: habit.isCommitmentActive=${habit.isCommitmentActive}');
    debugPrint('TodayScreen: habit.isCommitmentComplete=${habit.isCommitmentComplete}');
    debugPrint('TodayScreen: habit.isLockedIn=${habit.isLockedIn}');
    debugPrint('TodayScreen: habit.commitmentStartTime=${habit.commitmentStartTime}');
    debugPrint('TodayScreen: habit.commitmentLockedTime=${habit.commitmentLockedTime}');

    if (habit.isCompleted) {
      debugPrint('TodayScreen: Habit already completed, returning');
      return;
    }

    if (habit.canStartCommitment) {
      debugPrint('TodayScreen: Can start commitment, checking welcome state');
      final settings = ref.read(settingsProvider);

      if (!settings.hasSeenCommitmentWelcome) {
        debugPrint('TodayScreen: First time - showing welcome dialog');
        if (!mounted) return;
        await CommitmentWelcomeDialog.show(context);
        // The dialog handles navigation to commitment journey when user
        // taps "Begin My Journey" and marks the flag as seen.
        return;
      }

      // User has already seen the welcome -- go straight to the journey screen
      debugPrint('TodayScreen: Navigating to commitment journey');
      if (!mounted) return;
      context.push(AppRoutes.commitmentJourney);
    } else if (habit.isLockedIn && habit.commitmentStartTime == null) {
      debugPrint('TodayScreen: Habit locked in but not started, showing waiting dialog');
      CommitmentWaitingDialog.show(context, habit);
    } else if (habit.isCommitmentActive && habit.isCommitmentComplete) {
      debugPrint('TodayScreen: Showing completion dialog');
      CommitmentCompletionDialog.show(
        context,
        habit: habit,
        onSucceeded: () => ref.read(dailyAnchorsProvider.notifier).completeCommitment(succeeded: true),
        onFailed: () => ref.read(dailyAnchorsProvider.notifier).completeCommitment(succeeded: false),
      );
    } else if (habit.isCommitmentActive) {
      debugPrint('TodayScreen: Habit is active - EnhancedCommitmentCard handles tap');
      return;
    } else if (habit.isLockedIn && habit.commitmentStartTime != null) {
      debugPrint('TodayScreen: Habit locked in and started, checking completion status');
      if (habit.isCommitmentComplete) {
        CommitmentCompletionDialog.show(
          context,
          habit: habit,
          onSucceeded: () => ref.read(dailyAnchorsProvider.notifier).completeCommitment(succeeded: true),
          onFailed: () => ref.read(dailyAnchorsProvider.notifier).completeCommitment(succeeded: false),
        );
      } else {
        debugPrint('TodayScreen: Habit locked in but not active - EnhancedCommitmentCard handles tap');
        return;
      }
    } else {
      debugPrint('TodayScreen: No valid habit state found, showing reset option');
      HabitResetDialog.show(
        context,
        onReset: () {
          const resetHabit = Habit(
            title: 'Practice a Habit',
            description: 'Begin and lock in a habit during the day for a minimum of 4 hours.',
            durationMinutes: 240,
            type: HabitType.reflection,
            isCompleted: false,
          );
          final currentAnchors = ref.read(dailyAnchorsProvider);
          final updatedAnchors = currentAnchors.copyWith(habit: resetHabit);
          ref.read(dailyAnchorsProvider.notifier).repository.save(updatedAnchors);
        },
      );
    }
  }

  void _showPhysicalActivityGuide() {
    PhysicalActivityGuide.show(context);
  }

  bool _isEveningTime() {
    final now = DateTime.now();
    return now.hour >= 19 || now.hour < 2; // 7 PM to 2 AM considered evening
  }

  void _showProgressReminder(DailyAnchors anchors) {
    final completedCount = _calculateCompletedAnchors(anchors);
    if (_isEveningTime() && completedCount == 0) {
      showDialog(
        context: context,
        builder: (context) => const EndOfDayReflectionDialog(),
      );
    } else {
      ProgressReminderDialog.show(context, anchors);
    }
  }

  void _showPrayerGuide(Virtue virtue) {
    PrayerGuideDialog.show(
      context,
      virtue,
      () => ref.read(dailyAnchorsProvider.notifier).markAnchorDone(AnchorType.coreVirtue),
      showQuickStart: _isNearAlarmTime,
    );
  }

  int _calculateCompletedAnchors(DailyAnchors anchors) {
    int count = 0;
    if (anchors.coreVirtue.isCompleted) count++;
    if (anchors.habit.isCompleted) count++;
    if (anchors.energyAction.isCompleted) count++;
    return count;
  }

  void _showShareModal() {
    final authState = ref.read(authProvider);
    ShareElbiblioDialog.show(
      context,
      onShareWithContacts: () => share_helper.shareWithContacts(
        context,
        isAuthenticated: authState.isAuthenticated,
        isGuest: authState.isGuest,
      ),
      onShareUrl: () => share_helper.shareAppUrl(context),
      onLeaveReview: () => share_helper.openStoreReview(context),
    );
  }

  void _showQuickHelp() {
    showDialog(
      context: context,
      builder: (context) => const FirstAidKitDialog(),
    );
  }

}
