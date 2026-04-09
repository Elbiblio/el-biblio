import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/storage/settings_storage.dart';
import '../../../../core/services/analytics/app_analytics_service.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../domain/models/daily_anchors.dart';
import 'widgets/physical_activity_guide.dart';
import '../../commitments/presentation/widgets/commitment_welcome_dialog.dart';
import 'widgets/prayer_guide_dialog.dart';
import 'widgets/soul_care_dialog.dart';
import 'widgets/commitment_waiting_dialog.dart';
import 'widgets/commitment_completion_dialog.dart';
import 'widgets/habit_reset_dialog.dart';
import 'widgets/time_diagnose_suggestion_dialog.dart';
import 'widgets/recalibration_suggestion_dialog.dart';
import 'widgets/today_header.dart';
import 'widgets/assessment_prompt_widget.dart';
import 'widgets/weekly_plan_prompt_card.dart';
import 'widgets/daily_focus_card.dart';
import 'widgets/weekly_section_widget.dart';
import 'widgets/mission_next_step_card.dart'
    show MissionNextStepCard;
import 'widgets/daily_verse_card.dart';
import 'widgets/spiritual_pulse_widget.dart';
import 'widgets/journey_check_in_section.dart';
import 'widgets/forty_day_task_card.dart';

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
    // Track TodayScreen view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsProvider).track(AppAnalyticsEvent.todayScreenViewed);
    });
    // Check for missed days and alarm proximity when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForMissedDaysAndShowSuggestion();
      _checkAlarmProximity();
      _checkAndShowDailyPrayerGuide();
      ref.read(settingsProvider.notifier).refreshWeeklyPlanIfNeeded();
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

    if (!settings.onboardingCompleted) return;

    // First-time welcome: show prayer guide immediately regardless of time
    if (!settings.hasSeenTodayWelcome) {
      final anchors = ref.read(dailyAnchorsProvider);
      final virtue = anchors.coreVirtue;
      if (!virtue.isCompleted && mounted) {
        final journeyState = ref.read(commitmentJourneyProvider);
        final aj = journeyState.activeJourney;
        final cj = aj != null
            ? journeyState.availableJourneys.cast<dynamic>().firstWhere(
                (j) => j.id == aj.journeyId, orElse: () => null)
            : null;
        PrayerGuideDialog.show(
          context,
          virtue,
          () async {
            await storage.markPrayerGuideShown();
            ref.read(dailyAnchorsProvider.notifier).markAnchorDone(AnchorType.coreVirtue);
          },
          showQuickStart: true,
          activeJourney: aj,
          commitmentJourney: cj,
        );
        await storage.markPrayerGuideShown();
      }
      await ref.read(settingsProvider.notifier).markTodayWelcomeSeen();
      return;
    }

    // Normal behavior: only show during morning hours
    if (!storage.isMorningHours()) return;
    if (!storage.shouldShowPrayerGuide(settings)) return;

    final anchors = ref.read(dailyAnchorsProvider);
    final virtue = anchors.coreVirtue;
    if (virtue.isCompleted) return;

    if (mounted) {
      final journeyState = ref.read(commitmentJourneyProvider);
      final aj = journeyState.activeJourney;
      final cj = aj != null
          ? journeyState.availableJourneys.cast<dynamic>().firstWhere(
              (j) => j.id == aj.journeyId, orElse: () => null)
          : null;
      PrayerGuideDialog.show(
        context,
        virtue,
        () async {
          await storage.markPrayerGuideShown();
          ref.read(dailyAnchorsProvider.notifier).markAnchorDone(AnchorType.coreVirtue);
        },
        showQuickStart: true,
        activeJourney: aj,
        commitmentJourney: cj,
      );
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
    final todayPulse = settings.spiritualPulseByDate[
      DateTime(now.year, now.month, now.day).toIso8601String()
    ];

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
              // Header (profile, greeting, help button)
              SliverToBoxAdapter(
                child: TodayHeader(
                  onHelpTap: _showQuickHelp,
                ),
              ),

              // Daily Focus: archetype + progress + commitment in one card
              SliverToBoxAdapter(
                child: DailyFocusCard(
                  anchors: anchors,
                  onPrayerTap: () => _showPrayerGuide(anchors.coreVirtue),
                  onHabitTap: () => _handleHabitTap(anchors, now),
                  onActivityTap: _showPhysicalActivityGuide,
                ),
              ),

              if (settings.onboardingCompleted && !settings.hasSeenAssessmentPrompt)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: AssessmentPromptWidget(),
                  ),
                ),

              // Weekly assessment prompt — shown when no current weekly plan
              if (settings.onboardingCompleted &&
                  settings.hasSeenAssessmentPrompt &&
                  WeeklyPlanPromptCard.shouldShow(currentPlan: settings.currentWeeklyPlan))
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: WeeklyPlanPromptCard(),
                  ),
                ),

              // --- Time-aware secondary widget ordering ---
              // Evening: promote journey check-in; Afternoon: promote mission
              ..._buildSecondaryWidgets(settings, anchors, todayPulse, now),

              // Daily verse when all anchors complete
              if (anchors.coreVirtue.isCompleted &&
                  anchors.habit.isCompleted &&
                  anchors.energyAction.isCompleted)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: DailyVerseCard(
                      onShare: () {
                        final verse = ref.read(verseProvider).todayVerse;
                        if (verse != null) {
                          Share.share(
                            '"${verse.text}" — ${verse.reference}\n\nShared from El-Biblio',
                          );
                        }
                      },
                    ),
                  ),
                ),

              // Responsive bottom padding for floating nav
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).padding.bottom + 100,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Secondary widgets (consistent order)
  // ---------------------------------------------------------------------------

  /// Returns secondary slivers in a consistent, predictable order.
  /// Users build spatial memory for where things are — don't rearrange by time.
  List<Widget> _buildSecondaryWidgets(
    dynamic settings,
    DailyAnchors anchors,
    dynamic todayPulse,
    DateTime now,
  ) {
    return [
      // 1. Commitment journey — today's task (always visible when active)
      const SliverToBoxAdapter(child: JourneyCheckInSection()),

      // 2. 40-Day goal — today's task (always visible when active)
      const SliverToBoxAdapter(child: FortyDayTaskCard()),

      // 3. Mission acts — pending actions with inline completion
      const SliverToBoxAdapter(child: MissionNextStepCard()),

      // 4. Weekly plan (when a plan exists)
      const SliverToBoxAdapter(child: WeeklySectionWidget()),

      // 5. Spiritual pulse (mood check — only if not yet recorded today)
      if ((todayPulse?.entries.length ?? 0) == 0 && settings.streakCount > 0)
        const SliverToBoxAdapter(child: SpiritualPulseWidget()),
    ];
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void _handleHabitTap(DailyAnchors anchors, DateTime now) async {
    final habit = anchors.habit;

    if (habit.isCompleted) {
      return;
    }

    if (habit.canStartCommitment) {
      final settings = ref.read(settingsProvider);

      if (!settings.hasSeenCommitmentWelcome) {
        if (!mounted) return;
        await CommitmentWelcomeDialog.show(context);
        // The dialog handles navigation to commitment journey when user
        // taps "Begin My Journey" and marks the flag as seen.
        return;
      }

      if (!mounted) return;
      context.push(AppRoutes.commitmentJourney);
    } else if (habit.isLockedIn && habit.commitmentStartTime == null) {
      CommitmentWaitingDialog.show(context, habit);
    } else if (habit.isCommitmentActive && habit.isCommitmentComplete) {
      CommitmentCompletionDialog.show(
        context,
        habit: habit,
        onSucceeded: () => ref.read(dailyAnchorsProvider.notifier).completeCommitment(succeeded: true),
        onFailed: () => ref.read(dailyAnchorsProvider.notifier).completeCommitment(succeeded: false),
      );
    } else if (habit.isCommitmentActive) {
      return;
    } else if (habit.isLockedIn && habit.commitmentStartTime != null) {
      if (habit.isCommitmentComplete) {
        CommitmentCompletionDialog.show(
          context,
          habit: habit,
          onSucceeded: () => ref.read(dailyAnchorsProvider.notifier).completeCommitment(succeeded: true),
          onFailed: () => ref.read(dailyAnchorsProvider.notifier).completeCommitment(succeeded: false),
        );
      } else {
        return;
      }
    } else {
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

  void _showPrayerGuide(Virtue virtue) {
    final journeyState = ref.read(commitmentJourneyProvider);
    final activeJourney = journeyState.activeJourney;
    final commitmentJourney = activeJourney != null
        ? journeyState.availableJourneys.cast<dynamic>().firstWhere(
            (j) => j.id == activeJourney.journeyId,
            orElse: () => null,
          )
        : null;
    PrayerGuideDialog.show(
      context,
      virtue,
      () => ref.read(dailyAnchorsProvider.notifier).markAnchorDone(AnchorType.coreVirtue),
      showQuickStart: _isNearAlarmTime,
      activeJourney: activeJourney,
      commitmentJourney: commitmentJourney,
    );
  }

  void _showQuickHelp() {
    ref.read(analyticsProvider).track(AppAnalyticsEvent.soulCareDialogOpened);
    showDialog(
      context: context,
      builder: (context) => const SoulCareDialog(),
    );
  }

}
