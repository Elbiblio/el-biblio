import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/storage/settings_storage.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../commitments/presentation/widgets/commitment_summary_card.dart';
import '../domain/models/daily_anchors.dart';
import '../domain/models/commitment.dart';
import 'widgets/commitment_selection_dialog.dart';
import 'widgets/physical_activity_guide.dart';
import 'widgets/assessment_prompt_widget.dart';
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
import 'widgets/daily_progress_card.dart';
import 'widgets/daily_rhythm_section.dart';
import 'widgets/rhythm_summary_card.dart';
import 'widgets/weekly_recap_card.dart';
import 'widgets/time_assessment_widget.dart';
import 'widgets/need_help_widget.dart';
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
    final settings = ref.watch(settingsProvider);
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

              // Assessment Prompt for first-time users
              if (settings.onboardingCompleted && !settings.hasSeenAssessmentPrompt)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: AssessmentPromptWidget(),
                  ),
                ),

              // Progress Overview
              SliverToBoxAdapter(
                child: DailyProgressCard(
                  anchors: anchors,
                  onTap: () => _showProgressReminder(anchors),
                ),
              ),

              // Graduated Commitment Journey Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: CommitmentSummaryCard(
                    onTap: () {
                      final gcState = ref.read(graduatedCommitmentProvider);
                      if (gcState.activeCommitment != null) {
                        context.push(AppRoutes.commitmentActive);
                      } else {
                        context.push(AppRoutes.commitmentJourney);
                      }
                    },
                  ),
                ),
              ),

              // Conditional widget based on weekend and streak
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: _buildConditionalWidget(settings, now),
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
      debugPrint('TodayScreen: Can start commitment, showing dialog');
      final selectedCommitment = await showDialog<Commitment>(
        context: context,
        builder: (context) => const CommitmentSelectionDialog(),
      );

      if (selectedCommitment != null) {
        debugPrint('TodayScreen: Commitment selected: ${selectedCommitment.title}');
        final updatedHabit = habit.copyWith(
          title: selectedCommitment.title,
          description: selectedCommitment.description,
          durationMinutes: selectedCommitment.durationMinutes,
          commitmentId: selectedCommitment.id,
          commitmentTitle: selectedCommitment.title,
          commitmentDescription: selectedCommitment.description,
        );

        final updatedAnchors = anchors.copyWith(habit: updatedHabit);
        await ref.read(dailyAnchorsProvider.notifier).repository.save(updatedAnchors);

        debugPrint('TodayScreen: Starting commitment');
        await ref.read(dailyAnchorsProvider.notifier).startCommitment();

        debugPrint('TodayScreen: Locking in commitment');
        await ref.read(dailyAnchorsProvider.notifier).lockInCommitment();
        debugPrint('TodayScreen: Commitment locked in successfully');

        // Refresh state to ensure UI updates immediately
        await ref.read(dailyAnchorsProvider.notifier).loadToday();
      } else {
        debugPrint('TodayScreen: No commitment selected');
      }
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

  Widget _buildConditionalWidget(settings, DateTime now) {
    final isFridayOrSunday =
        now.weekday == DateTime.friday || now.weekday == DateTime.sunday;
    final isWeekend = now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
    final hasStreak = settings.streakCount > 0;

    if (isFridayOrSunday) {
      return const WeeklyRecapCard();
    }
    
    // Show RhythmSummaryCard only on weekends OR when daily verse is showing
    if (isWeekend || _isDailyVerseShowing()) {
      return const RhythmSummaryCard();
    }
    
    // Weekday logic based on streak
    if (!hasStreak) {
      return const TimeAssessmentWidget();
    } else {
      return const NeedHelpWidget();
    }
  }

  bool _isDailyVerseShowing() {
    final anchors = ref.watch(dailyAnchorsProvider);
    // Daily verse shows when all anchors are completed
    return anchors.coreVirtue.isCompleted &&
           anchors.habit.isCompleted &&
           anchors.energyAction.isCompleted;
  }
}
