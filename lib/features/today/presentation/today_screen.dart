import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/services/analytics/app_analytics_service.dart';
import '../../../../core/storage/app_settings.dart';
import '../../../../core/storage/settings_storage.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../commitments/presentation/widgets/commitment_welcome_dialog.dart';
import '../../companion/presentation/widgets/ai_partner_invite_card.dart';
import '../../companion/presentation/widgets/companion_bubble.dart';
import '../domain/models/daily_anchors.dart';
import 'widgets/assessment_prompt_widget.dart';
import 'widgets/commitment_completion_dialog.dart';
import 'widgets/commitment_waiting_dialog.dart';
import 'widgets/daily_focus_card.dart';
import 'widgets/daily_verse_card.dart';
import 'widgets/forty_day_task_card.dart';
import 'widgets/habit_reset_dialog.dart';
import 'widgets/journey_check_in_section.dart';
import 'widgets/mission_next_step_card.dart' show MissionNextStepCard;
import 'widgets/physical_activity_guide.dart';
import 'widgets/prayer_guide_dialog.dart';
import 'widgets/recalibration_suggestion_dialog.dart';
import 'widgets/soul_care_dialog.dart';
import 'widgets/spiritual_pulse_widget.dart';
import 'widgets/time_diagnose_suggestion_dialog.dart';
import 'widgets/pending_checkin_card.dart';
import 'widgets/today_header.dart';
import 'widgets/weekly_plan_prompt_card.dart';
import 'widgets/weekly_section_widget.dart';

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsProvider).track(AppAnalyticsEvent.todayScreenViewed);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForMissedDaysAndShowSuggestion();
      _checkAlarmProximity();
      _checkAndShowDailyPrayerGuide();
      ref.read(settingsProvider.notifier).refreshWeeklyPlanIfNeeded();
      ref.read(pillarScoreProvider.notifier).refresh();
    });
  }

  Future<void> _checkForMissedDaysAndShowSuggestion() async {
    final missedDays = await ref
        .read(dailyAnchorsProvider.notifier)
        .getConsecutiveMissedDays();
    if (!mounted || missedDays < 2) return;

    final settings = ref.read(settingsProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastPrompt = settings.lastRecalibrationPromptDate;
    final lastPromptDay = lastPrompt == null
        ? null
        : DateTime(lastPrompt.year, lastPrompt.month, lastPrompt.day);

    if (lastPromptDay == today) return;

    await ref
        .read(settingsProvider.notifier)
        .markRecalibrationPromptShown(today);

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

    final morningTimeParts = settings.morningTime.split(':');
    final morningHour = int.parse(morningTimeParts[0]);
    final morningMinute = int.parse(morningTimeParts[1]);
    final morningTime = DateTime(
      now.year,
      now.month,
      now.day,
      morningHour,
      morningMinute,
    );

    final timeDifference = now.difference(morningTime);
    final isWithin30Minutes =
        timeDifference.inMinutes >= -30 && timeDifference.inMinutes <= 30;

    final isEarlyMorning = now.hour >= 5 && now.hour < 10;

    setState(() {
      _isNearAlarmTime = isWithin30Minutes || isEarlyMorning;
    });
  }

  Future<void> _checkAndShowDailyPrayerGuide() async {
    final settings = ref.read(settingsProvider);
    const storage = SettingsStorage();

    if (!settings.onboardingCompleted) return;

    if (!settings.hasSeenTodayWelcome) {
      final anchors = ref.read(dailyAnchorsProvider);
      final virtue = anchors.coreVirtue;
      if (!virtue.isCompleted && mounted) {
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
          () async {
            await storage.markPrayerGuideShown();
            ref
                .read(dailyAnchorsProvider.notifier)
                .markAnchorDone(AnchorType.coreVirtue);
          },
          showQuickStart: true,
          activeJourney: activeJourney,
          commitmentJourney: commitmentJourney,
        );
        await storage.markPrayerGuideShown();
      }
      await ref.read(settingsProvider.notifier).markTodayWelcomeSeen();
      return;
    }

    if (!storage.isMorningHours()) return;
    if (!storage.shouldShowPrayerGuide(settings)) return;

    final anchors = ref.read(dailyAnchorsProvider);
    final virtue = anchors.coreVirtue;
    if (virtue.isCompleted || !mounted) return;

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
      () async {
        await storage.markPrayerGuideShown();
        ref
            .read(dailyAnchorsProvider.notifier)
            .markAnchorDone(AnchorType.coreVirtue);
      },
      showQuickStart: true,
      activeJourney: activeJourney,
      commitmentJourney: commitmentJourney,
    );
    await storage.markPrayerGuideShown();
  }

  @override
  Widget build(BuildContext context) {
    final anchors = ref.watch(dailyAnchorsProvider);
    final settings = ref.watch(settingsProvider);
    final tokens = Theme.of(context).tokens;
    final layout = _TodayLayout.fromContext(context);

    final now = DateTime.now();
    final todayPulse =
        settings.spiritualPulseByDate[DateTime(
          now.year,
          now.month,
          now.day,
        ).toIso8601String()];

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
              _adaptiveSection(
                layout: layout,
                child: TodayHeader(onHelpTap: _showQuickHelp),
              ),
              if (settings.companionCharacterCode != null)
                _adaptiveSection(
                  layout: layout,
                  child: const CompanionBubble(),
                ),
              if (settings.companionCharacterCode != null &&
                  settings.accountabilityPartner == null)
                _adaptiveSection(
                  layout: layout,
                  child: const AiPartnerInviteCard(),
                ),
              _adaptiveSection(
                layout: layout,
                child: const PendingCheckInCard(),
              ),
              _adaptiveSection(
                layout: layout,
                child: DailyFocusCard(
                  anchors: anchors,
                  onPrayerTap: () => _showPrayerGuide(anchors.coreVirtue),
                  onHabitTap: () => _handleHabitTap(anchors),
                  onActivityTap: _showPhysicalActivityGuide,
                ),
              ),
              if (settings.onboardingCompleted &&
                  !settings.hasSeenAssessmentPrompt)
                _adaptiveSection(
                  layout: layout,
                  padding: EdgeInsets.symmetric(
                    horizontal: layout.promptHorizontalPadding,
                  ),
                  child: const AssessmentPromptWidget(),
                ),
              if (settings.onboardingCompleted &&
                  settings.hasSeenAssessmentPrompt &&
                  WeeklyPlanPromptCard.shouldShow(
                    currentPlan: settings.currentWeeklyPlan,
                  ))
                _adaptiveSection(
                  layout: layout,
                  padding: EdgeInsets.symmetric(
                    horizontal: layout.promptHorizontalPadding,
                  ),
                  child: const WeeklyPlanPromptCard(),
                ),
              ..._buildSecondaryWidgets(settings, todayPulse, layout),
              if (anchors.coreVirtue.isCompleted &&
                  anchors.habit.isCompleted &&
                  anchors.energyAction.isCompleted)
                _adaptiveSection(
                  layout: layout,
                  padding: EdgeInsets.symmetric(
                    horizontal: layout.promptHorizontalPadding + 8,
                  ),
                  child: DailyVerseCard(
                    onShare: () {
                      final verse = ref.read(verseProvider).todayVerse;
                      if (verse != null) {
                        Share.share(
                          '"${verse.text}" - ${verse.reference}\n\nShared from El-Biblio',
                        );
                      }
                    },
                  ),
                ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height:
                      MediaQuery.paddingOf(context).bottom +
                      layout.bottomSpacing,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSecondaryWidgets(
    AppSettings settings,
    SpiritualPulseResponse? todayPulse,
    _TodayLayout layout,
  ) {
    return [
      _adaptiveSection(layout: layout, child: const JourneyCheckInSection()),
      _adaptiveSection(layout: layout, child: const FortyDayTaskCard()),
      _adaptiveSection(layout: layout, child: const MissionNextStepCard()),
      _adaptiveSection(layout: layout, child: const WeeklySectionWidget()),
      if ((todayPulse?.entries.length ?? 0) == 0 && settings.streakCount > 0)
        _adaptiveSection(layout: layout, child: const SpiritualPulseWidget()),
    ];
  }

  SliverToBoxAdapter _adaptiveSection({
    required _TodayLayout layout,
    required Widget child,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
  }) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: padding,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: layout.maxContentWidth),
            child: child,
          ),
        ),
      ),
    );
  }

  void _handleHabitTap(DailyAnchors anchors) async {
    final habit = anchors.habit;

    if (habit.isCompleted) {
      return;
    }

    if (habit.canStartCommitment) {
      final settings = ref.read(settingsProvider);

      if (!settings.hasSeenCommitmentWelcome) {
        if (!mounted) return;
        await CommitmentWelcomeDialog.show(context);
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
        onSucceeded: () => ref
            .read(dailyAnchorsProvider.notifier)
            .completeCommitment(succeeded: true),
        onFailed: () => ref
            .read(dailyAnchorsProvider.notifier)
            .completeCommitment(succeeded: false),
      );
    } else if (habit.isCommitmentActive) {
      return;
    } else if (habit.isLockedIn && habit.commitmentStartTime != null) {
      if (habit.isCommitmentComplete) {
        CommitmentCompletionDialog.show(
          context,
          habit: habit,
          onSucceeded: () => ref
              .read(dailyAnchorsProvider.notifier)
              .completeCommitment(succeeded: true),
          onFailed: () => ref
              .read(dailyAnchorsProvider.notifier)
              .completeCommitment(succeeded: false),
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
            description:
                'Begin and lock in a habit during the day for a minimum of 4 hours.',
            durationMinutes: 240,
            type: HabitType.reflection,
            isCompleted: false,
          );
          final currentAnchors = ref.read(dailyAnchorsProvider);
          final updatedAnchors = currentAnchors.copyWith(habit: resetHabit);
          ref
              .read(dailyAnchorsProvider.notifier)
              .repository
              .save(updatedAnchors);
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
      () => ref
          .read(dailyAnchorsProvider.notifier)
          .markAnchorDone(AnchorType.coreVirtue),
      showQuickStart: _isNearAlarmTime,
      activeJourney: activeJourney,
      commitmentJourney: commitmentJourney,
    );
  }

  void _showQuickHelp() {
    ref.read(analyticsProvider).track(AppAnalyticsEvent.soulCareDialogOpened);
    showDialog(context: context, builder: (context) => const SoulCareDialog());
  }
}

class _TodayLayout {
  const _TodayLayout({
    required this.maxContentWidth,
    required this.promptHorizontalPadding,
    required this.bottomSpacing,
  });

  final double maxContentWidth;
  final double promptHorizontalPadding;
  final double bottomSpacing;

  factory _TodayLayout.fromContext(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (width >= 1200) {
      return const _TodayLayout(
        maxContentWidth: 920,
        promptHorizontalPadding: 24,
        bottomSpacing: 116,
      );
    }

    if (width >= 840) {
      return const _TodayLayout(
        maxContentWidth: 760,
        promptHorizontalPadding: 20,
        bottomSpacing: 108,
      );
    }

    return const _TodayLayout(
      maxContentWidth: 640,
      promptHorizontalPadding: 16,
      bottomSpacing: 100,
    );
  }
}
