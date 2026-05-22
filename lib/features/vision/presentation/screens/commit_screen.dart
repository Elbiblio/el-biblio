import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart' as permissions;

import '../../../../core/di/app_providers.dart';
import '../../../../core/models/accountability_tone.dart';
import '../../../../shared/widgets/safe_bottom_padding.dart';
import '../../../../shared/widgets/premium_success_dialog.dart';
import '../../../../shared/widgets/vision_illustration.dart';
import '../../domain/vision_models.dart';
import '../widgets/commitment_daily_load_widgets.dart';
import '../widgets/vision_action_tile.dart';
import '../widgets/vision_panel.dart';

class CommitScreen extends ConsumerStatefulWidget {
  const CommitScreen({super.key});

  @override
  ConsumerState<CommitScreen> createState() => _CommitScreenState();
}

class _CommitScreenState extends ConsumerState<CommitScreen> {
  int _selectedNudges = 3;
  int _selectedDailyLoad = 1;
  String _selectedCategory = 'all';
  _HabitViceSeed? _selectedHabitSeed;
  _ReplacementHabit? _selectedReplacement;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(visionProvider.notifier).load(),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(visionProvider);
    final active = state.activeCommitment;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Commit'),
        actions: [
          if (active != null)
            IconButton(
              tooltip: 'Browse commitments',
              onPressed: () =>
                  _showCommitmentLibrary(state.recommendedCommitments, active),
              icon: const Icon(LucideIcons.layoutGrid),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(visionProvider.notifier).load(force: true),
        child: SafeListView(
          bottomPadding: shellChromeBottomPadding,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            _CommitHeader(active: active),
            const SizedBox(height: 16),
            if (state.error?.isNotEmpty == true) ...[
              _LaunchIssuePanel(message: state.error!),
              const SizedBox(height: 16),
            ],
            if (state.notificationWarning?.isNotEmpty == true) ...[
              _LaunchIssuePanel(
                icon: LucideIcons.bellOff,
                title: 'Reminders need attention',
                message: state.notificationWarning!,
              ),
              const SizedBox(height: 16),
            ],
            if (active != null) ...[
              _ActiveCommitment(
                active: active,
                showCheckInAction: true,
                onAdjustLoad: () => _showDailyLoadSheet(active),
                onBrowseNext: () => _showCommitmentLibrary(
                  state.recommendedCommitments,
                  active,
                ),
              ),
              const SizedBox(height: 16),
              _MonthlyReviewPanel(active: active),
              const SizedBox(height: 16),
              _NotificationRecoveryPanel(),
              const SizedBox(height: 16),
              _AccountabilityAssistantPanel(active: active),
            ] else ...[
              _NudgeEducationPanel(onLearnMore: _showNudgeHelp),
              const SizedBox(height: 16),
              if (state.recommendedCommitments.isEmpty)
                _LaunchIssuePanel(
                  icon: LucideIcons.wifiOff,
                  title: state.isReadOnly
                      ? 'Reconnect to choose a commitment'
                      : 'Commitment catalog unavailable',
                  message:
                      'Reconnect to choose a real commitment for this season.',
                )
              else ...[
                _CommitmentChoiceGuide(
                  recommended: _bestCommitment(state.recommendedCommitments),
                  totalCount: state.recommendedCommitments.length,
                  onCompare: () =>
                      _showCommitmentChooser(state.recommendedCommitments),
                ),
                const SizedBox(height: 12),
                _buildCommitmentOption(
                  _bestCommitment(state.recommendedCommitments),
                ),
                const SizedBox(height: 2),
                _HabitViceHelperPanel(
                  selectedHabit: _selectedHabitSeed,
                  selectedReplacement: _selectedReplacement,
                  suggestedPlan: _bestHabitCommitment(
                    state.recommendedCommitments,
                  ),
                  onHabitSelected: (habit) => setState(() {
                    _selectedHabitSeed = habit;
                    _selectedReplacement = habit.replacements.first;
                    _selectedCategory = habit.category;
                  }),
                  onReplacementSelected: (replacement) =>
                      setState(() => _selectedReplacement = replacement),
                  onReview: _selectedHabitSeed == null
                      ? null
                      : () {
                          final plan = _bestHabitCommitment(
                            state.recommendedCommitments,
                          );
                          if (plan == null) return;
                          _showCommitmentWalkthrough(
                            plan,
                            _selectedNudges
                                .clamp(plan.nudgeMin, plan.nudgeMax)
                                .toInt(),
                            dailyLoadCount: _selectedDailyLoad,
                            planObstacle: _habitObstacleCopy(),
                          );
                        },
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCommitmentOption(CommitmentPlan plan) {
    final theme = Theme.of(context);
    final min = plan.nudgeMin;
    final max = plan.nudgeMax;
    final nudges = _selectedNudges.clamp(min, max).toInt();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CategoryIcon(category: plan.category),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetaPill(
                          icon: LucideIcons.calendarDays,
                          label: '${plan.durationDays} days',
                        ),
                        _MetaPill(
                          icon: LucideIcons.bell,
                          label: '${plan.nudgeMin}-${plan.nudgeMax} reminders',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      plan.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(plan.description, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              plan.dailyAction,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Daily load',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          DailyLoadSelector(
            value: _selectedDailyLoad,
            onChanged: (value) => setState(() => _selectedDailyLoad = value),
          ),
          const SizedBox(height: 12),
          CommitmentDailyChecklist(
            items: CommitmentDailyItem.fallbackItems(
              plan: plan,
              dailyLoadCount: _selectedDailyLoad,
              completedToday: false,
              obstacle: _habitObstacleCopy(),
            ),
          ),
          const SizedBox(height: 14),
          _NudgeSelectorHeader(nudges: nudges, onHelp: _showNudgeHelp),
          Slider(
            value: nudges.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: (max - min).clamp(1, 10),
            label: '$nudges',
            onChanged: (value) =>
                setState(() => _selectedNudges = value.round()),
          ),
          FilledButton.icon(
            onPressed: ref.watch(visionProvider).isLoading
                ? null
                : () => _showCommitmentWalkthrough(
                    plan,
                    nudges,
                    dailyLoadCount: _selectedDailyLoad,
                  ),
            icon: const Icon(LucideIcons.compass, size: 18),
            label: const Text('Review and begin'),
          ),
        ],
      ),
    );
  }

  List<CommitmentPlan> _visibleCommitments(List<CommitmentPlan> plans) {
    if (_selectedCategory == 'all') return plans;
    return plans
        .where((plan) => plan.category == _selectedCategory)
        .toList(growable: false);
  }

  CommitmentPlan _bestCommitment(List<CommitmentPlan> plans) {
    final visible = _visibleCommitments(plans);
    return visible.isNotEmpty ? visible.first : plans.first;
  }

  CommitmentPlan? _bestHabitCommitment(List<CommitmentPlan> plans) {
    final habit = _selectedHabitSeed;
    if (habit == null || plans.isEmpty) return null;
    final categoryMatches = plans
        .where((plan) => plan.category.toLowerCase() == habit.category)
        .toList(growable: false);
    final candidates = categoryMatches.isNotEmpty ? categoryMatches : plans;
    for (final keyword in habit.keywords) {
      final match = candidates
          .where((plan) {
            final text = '${plan.title} ${plan.description} ${plan.dailyAction}'
                .toLowerCase();
            return text.contains(keyword);
          })
          .toList(growable: false);
      if (match.isNotEmpty) return match.first;
    }
    return candidates.first;
  }

  String? _habitObstacleCopy() {
    final habit = _selectedHabitSeed;
    if (habit == null) return null;
    final replacement = _selectedReplacement;
    if (replacement == null) {
      return 'When I feel pulled toward ${habit.label.toLowerCase()}, pause and choose one faithful next step.';
    }
    return 'When I feel pulled toward ${habit.label.toLowerCase()}, practice ${replacement.label.toLowerCase()} instead.';
  }

  void _showNudgeHelp() {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (context) => const _NudgeHelpSheet(),
    );
  }

  void _showCommitmentLibrary(
    List<CommitmentPlan> commitments,
    CommitmentSeason active,
  ) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) =>
          _CommitmentLibrarySheet(commitments: commitments, active: active),
    );
  }

  void _showCommitmentChooser(List<CommitmentPlan> commitments) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _CommitmentChooserSheet(
        commitments: commitments,
        selectedCategory: _selectedCategory,
        onCategoryChanged: (category) =>
            setState(() => _selectedCategory = category),
        onReview: (plan) {
          Navigator.of(context).pop();
          final nudges = _selectedNudges
              .clamp(plan.nudgeMin, plan.nudgeMax)
              .toInt();
          _showCommitmentWalkthrough(
            plan,
            nudges,
            dailyLoadCount: _selectedDailyLoad,
          );
        },
      ),
    );
  }

  void _showDailyLoadSheet(CommitmentSeason active) {
    var selected = active.dailyLoadCount;
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final safeBottom = MediaQuery.paddingOf(sheetContext).bottom;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + safeBottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily load',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CommitmentSnapshotBanner(
                    active: active.copyWith(dailyLoadCount: selected),
                  ),
                  const SizedBox(height: 14),
                  DailyLoadSelector(
                    value: selected,
                    onChanged: (value) => setSheetState(() {
                      selected = value;
                    }),
                  ),
                  const SizedBox(height: 14),
                  CommitmentDailyChecklist(
                    items: CommitmentDailyItem.fallbackItems(
                      plan: active.plan,
                      dailyLoadCount: selected,
                      completedToday: active.checkedInToday,
                      obstacle: active.firstCheckInPlanObstacle,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () async {
                      final updated = await ref
                          .read(visionProvider.notifier)
                          .updateDailyLoad(selected);
                      if (!context.mounted) return;
                      Navigator.of(sheetContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            updated
                                ? '${dailyLoadLabelForCount(selected)} load selected.'
                                : 'Daily load could not be changed.',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(LucideIcons.layers, size: 18),
                    label: const Text('Use this load'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showCommitmentWalkthrough(
    CommitmentPlan plan,
    int initialNudges, {
    required int dailyLoadCount,
    String? planWhen,
    String? planObstacle,
  }) async {
    final joined = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _CommitmentWalkthroughSheet(
        plan: plan,
        initialNudges: initialNudges,
        dailyLoadCount: dailyLoadCount,
        initialPlanWhen: planWhen,
        initialPlanObstacle: planObstacle,
        onJoin: (nudges, planWhen, planObstacle) async {
          final joined = await ref
              .read(visionProvider.notifier)
              .joinCommitment(
                plan,
                nudges,
                dailyLoadCount: dailyLoadCount,
                planWhen: planWhen,
                planObstacle: planObstacle,
              );
          if (context.mounted) {
            Navigator.of(context).pop(joined);
          }
        },
      ),
    );

    if (!mounted || joined == null) return;
    if (!joined) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'We could not start this commitment. Please try again.',
          ),
        ),
      );
      return;
    }
    await PremiumSuccessDialog.show(
      context,
      title: 'Commitment joined',
      message:
          'Your reminders are ready. Let them help you return without shame.',
      primaryActionText: 'Continue',
    );
  }
}

class _LaunchIssuePanel extends StatelessWidget {
  const _LaunchIssuePanel({
    required this.message,
    this.title = 'Something needs a retry',
    this.icon = LucideIcons.alertCircle,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return VisionPanel(
      icon: icon,
      title: title,
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
      ),
    );
  }
}

class _CommitHeader extends StatelessWidget {
  const _CommitHeader({required this.active});

  final CommitmentSeason? active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasActive = active != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const VisionIllustration(
            asset: VisionIllustrationAsset.commitment,
            size: 86,
            semanticLabel: 'Commitment',
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasActive ? active!.plan.title : 'Choose one commitment',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.02,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  hasActive
                      ? 'Day ${active!.currentDay}/${active!.plan.durationDays} - ${active!.completionPercentLabel} - ${active!.completedTodayItemCount}/${active!.totalRequiredItemCount} today'
                      : 'Choose the practice, load, reminders, and first check-in plan.',
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.42),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NudgeEducationPanel extends StatelessWidget {
  const _NudgeEducationPanel({required this.onLearnMore});

  final VoidCallback onLearnMore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return VisionPanel(
      icon: LucideIcons.bellRing,
      title: 'Reminders',
      trailing: IconButton(
        tooltip: 'Learn about reminders',
        onPressed: onLearnMore,
        icon: const Icon(LucideIcons.helpCircle, size: 20),
      ),
      child: Text(
        'Start small. Raise support only when you need more structure.',
        style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
      ),
    );
  }
}

class _HabitViceHelperPanel extends StatelessWidget {
  const _HabitViceHelperPanel({
    required this.selectedHabit,
    required this.selectedReplacement,
    required this.suggestedPlan,
    required this.onHabitSelected,
    required this.onReplacementSelected,
    required this.onReview,
  });

  final _HabitViceSeed? selectedHabit;
  final _ReplacementHabit? selectedReplacement;
  final CommitmentPlan? suggestedPlan;
  final ValueChanged<_HabitViceSeed> onHabitSelected;
  final ValueChanged<_ReplacementHabit> onReplacementSelected;
  final VoidCallback? onReview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return VisionPanel(
      icon: LucideIcons.repeat2,
      title: 'Habit and vice helper',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose one pattern you want to weaken. Then choose one small replacement practice. This is a focus aid, not a diagnosis.',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _habitViceSeeds.map((habit) {
              return ChoiceChip(
                selected: selectedHabit?.id == habit.id,
                label: Text(habit.label),
                avatar: Icon(habit.icon, size: 16),
                onSelected: (_) => onHabitSelected(habit),
              );
            }).toList(),
          ),
          if (selectedHabit != null) ...[
            const SizedBox(height: 14),
            Text(
              'Replacement practice',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selectedHabit!.replacements.map((replacement) {
                return ChoiceChip(
                  selected: selectedReplacement?.id == replacement.id,
                  label: Text(replacement.label),
                  onSelected: (_) => onReplacementSelected(replacement),
                );
              }).toList(),
            ),
            if (suggestedPlan != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.18,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Closest commitment: ${suggestedPlan!.title}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              FilledButton.tonalIcon(
                onPressed: onReview,
                icon: const Icon(LucideIcons.flag, size: 18),
                label: const Text('Review this focus'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _CommitmentChoiceGuide extends StatelessWidget {
  const _CommitmentChoiceGuide({
    required this.recommended,
    required this.totalCount,
    required this.onCompare,
  });

  final CommitmentPlan recommended;
  final int totalCount;
  final VoidCallback onCompare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return VisionPanel(
      icon: LucideIcons.compass,
      title: 'Start here',
      trailing: Text('${recommended.durationDays} days'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pick one clear practice for the month.',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaPill(
                icon: _categoryIcon(recommended.category),
                label: _categoryLabel(recommended.category),
              ),
              _MetaPill(
                icon: LucideIcons.bell,
                label:
                    '${recommended.nudgeMin}-${recommended.nudgeMax} reminders',
              ),
            ],
          ),
          if (totalCount > 1) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onCompare,
              icon: const Icon(LucideIcons.listFilter, size: 18),
              label: Text('Compare $totalCount commitments'),
            ),
          ],
        ],
      ),
    );
  }
}

class _NotificationRecoveryPanel extends ConsumerStatefulWidget {
  @override
  ConsumerState<_NotificationRecoveryPanel> createState() =>
      _NotificationRecoveryPanelState();
}

class _NotificationRecoveryPanelState
    extends ConsumerState<_NotificationRecoveryPanel> {
  late Future<bool> _enabledFuture;

  @override
  void initState() {
    super.initState();
    _enabledFuture = ref
        .read(notificationServiceProvider)
        .areNotificationsEnabled();
  }

  Future<void> _requestAgain() async {
    final granted = await ref
        .read(notificationServiceProvider)
        .requestPermissions();
    if (!granted) {
      await permissions.openAppSettings();
    }
    if (mounted) {
      setState(() {
        _enabledFuture = ref
            .read(notificationServiceProvider)
            .areNotificationsEnabled();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _enabledFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            snapshot.data != false) {
          return const SizedBox.shrink();
        }
        final theme = Theme.of(context);
        return VisionPanel(
          icon: LucideIcons.bellOff,
          title: 'Turn reminders back on',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your commitment is still active, but device notifications look disabled. Turn them on so ElBiblio can remind you at the moments you chose.',
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: _requestAgain,
                icon: const Icon(LucideIcons.bellRing, size: 18),
                label: const Text('Enable reminders'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MonthlyReviewPanel extends ConsumerWidget {
  const _MonthlyReviewPanel({required this.active});

  final CommitmentSeason active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final reviewAt =
        settings.nextCommitmentReviewAt ??
        DateTime.now().add(const Duration(days: 30));
    final now = DateTime.now();
    final due = !reviewAt.isAfter(now);
    final theme = Theme.of(context);

    return VisionPanel(
      icon: LucideIcons.calendarClock,
      title: due ? 'Monthly review is ready' : 'Monthly review',
      trailing: Text('${reviewAt.month}/${reviewAt.day}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            due
                ? 'Choose whether this commitment should continue, deepen, or make room for a new focus.'
                : 'Daily practice stays stable. At review time, you choose whether to continue, deepen, or switch focus.',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
          if (due) ...[
            const SizedBox(height: 12),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ReviewAction(
                  label: 'Continue',
                  outcome: CommitmentMonthlyReviewOutcome.continuePractice,
                ),
                _ReviewAction(
                  label: 'Deepen slightly',
                  outcome: CommitmentMonthlyReviewOutcome.deepen,
                ),
                _ReviewAction(
                  label: 'Switch focus',
                  outcome: CommitmentMonthlyReviewOutcome.switchFocus,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewAction extends ConsumerWidget {
  const _ReviewAction({required this.label, required this.outcome});

  final String label;
  final CommitmentMonthlyReviewOutcome outcome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FilledButton.tonal(
      onPressed: () async {
        await ref
            .read(settingsProvider.notifier)
            .completeCommitmentMonthlyReview(outcome);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Monthly review saved: $label.')),
        );
      },
      child: Text(label),
    );
  }
}

class _CategoryRail extends StatelessWidget {
  const _CategoryRail({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          final isSelected = selected == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: isSelected,
              label: Text(_categoryLabel(category)),
              avatar: Icon(_categoryIcon(category), size: 16),
              onSelected: (_) => onSelected(category),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(_categoryIcon(category), color: theme.colorScheme.primary),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 5),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _NudgeSelectorHeader extends StatelessWidget {
  const _NudgeSelectorHeader({required this.nudges, required this.onHelp});

  final int nudges;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            '$nudges gentle reminders per day',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        IconButton(
          tooltip: 'How reminders work',
          onPressed: onHelp,
          icon: const Icon(LucideIcons.helpCircle, size: 20),
        ),
      ],
    );
  }
}

class _NudgeHelpSheet extends StatelessWidget {
  const _NudgeHelpSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + safeBottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How reminders work',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          const _ExpectationRow(
            icon: LucideIcons.bell,
            title: 'Prompt',
            body: 'Tap it, do the action, check in.',
          ),
          const _ExpectationRow(
            icon: LucideIcons.heartHandshake,
            title: 'No shame',
            body: 'Missed reminders show where support is needed.',
          ),
          const _ExpectationRow(
            icon: LucideIcons.sprout,
            title: 'Formation',
            body: 'Each prompt names the virtue and next step.',
          ),
        ],
      ),
    );
  }
}

class _CommitmentLibrarySheet extends StatelessWidget {
  const _CommitmentLibrarySheet({
    required this.commitments,
    required this.active,
  });

  final List<CommitmentPlan> commitments;
  final CommitmentSeason active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.74,
      minChildSize: 0.38,
      maxChildSize: 0.92,
      builder: (context, controller) {
        return ListView(
          controller: controller,
          padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + safeBottom),
          children: [
            Text(
              'Commitment library',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Keep one active commitment.',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.42),
            ),
            const SizedBox(height: 16),
            ...commitments.map(
              (plan) => _CommitmentLibraryCard(
                plan: plan,
                isActive: plan.id == active.plan.id,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CommitmentChooserSheet extends StatefulWidget {
  const _CommitmentChooserSheet({
    required this.commitments,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.onReview,
  });

  final List<CommitmentPlan> commitments;
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<CommitmentPlan> onReview;

  @override
  State<_CommitmentChooserSheet> createState() =>
      _CommitmentChooserSheetState();
}

class _CommitmentChooserSheetState extends State<_CommitmentChooserSheet> {
  late String _category = widget.selectedCategory;

  List<CommitmentPlan> get _visible {
    if (_category == 'all') return widget.commitments;
    return widget.commitments
        .where((plan) => plan.category == _category)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.42,
      maxChildSize: 0.94,
      builder: (context, controller) {
        return ListView(
          controller: controller,
          padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + safeBottom),
          children: [
            Text(
              'Compare commitments',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose one concrete practice.',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.42),
            ),
            const SizedBox(height: 16),
            _CategoryRail(
              categories: _categoriesForPlans(widget.commitments),
              selected: _category,
              onSelected: (category) {
                setState(() => _category = category);
                widget.onCategoryChanged(category);
              },
            ),
            const SizedBox(height: 16),
            ..._visible.map(
              (plan) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CommitmentChooserCard(
                  plan: plan,
                  onReview: () => widget.onReview(plan),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CommitmentChooserCard extends StatelessWidget {
  const _CommitmentChooserCard({required this.plan, required this.onReview});

  final CommitmentPlan plan;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CategoryIcon(category: plan.category),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      plan.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaPill(
                icon: LucideIcons.calendarDays,
                label: '${plan.durationDays} days',
              ),
              _MetaPill(
                icon: LucideIcons.bell,
                label: '${plan.nudgeMin}-${plan.nudgeMax} reminders',
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: onReview,
            icon: const Icon(LucideIcons.compass, size: 18),
            label: const Text('Review and begin'),
          ),
        ],
      ),
    );
  }
}

class _CommitmentLibraryCard extends StatelessWidget {
  const _CommitmentLibraryCard({required this.plan, required this.isActive});

  final CommitmentPlan plan;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isActive
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.18)
            : theme.colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive
              ? theme.colorScheme.primary.withValues(alpha: 0.28)
              : theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CategoryIcon(category: plan.category),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        plan.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (isActive) const Icon(LucideIcons.checkCircle, size: 18),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  plan.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetaPill(
                      icon: LucideIcons.calendarDays,
                      label: '${plan.durationDays} days',
                    ),
                    _MetaPill(
                      icon: LucideIcons.bell,
                      label: '${plan.nudgeMin}-${plan.nudgeMax} reminders',
                    ),
                    if (isActive)
                      const _MetaPill(
                        icon: LucideIcons.flag,
                        label: 'Current commitment',
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommitmentWalkthroughSheet extends StatefulWidget {
  const _CommitmentWalkthroughSheet({
    required this.plan,
    required this.initialNudges,
    required this.dailyLoadCount,
    required this.onJoin,
    this.initialPlanWhen,
    this.initialPlanObstacle,
  });

  final CommitmentPlan plan;
  final int initialNudges;
  final int dailyLoadCount;
  final String? initialPlanWhen;
  final String? initialPlanObstacle;
  final Future<void> Function(int nudges, String planWhen, String planObstacle)
  onJoin;

  @override
  State<_CommitmentWalkthroughSheet> createState() =>
      _CommitmentWalkthroughSheetState();
}

class _CommitmentWalkthroughSheetState
    extends State<_CommitmentWalkthroughSheet> {
  late int _nudges;
  late final TextEditingController _whenController;
  late final TextEditingController _obstacleController;
  bool _joining = false;

  @override
  void initState() {
    super.initState();
    _nudges = widget.initialNudges
        .clamp(widget.plan.nudgeMin, widget.plan.nudgeMax)
        .toInt();
    _whenController = TextEditingController(text: widget.initialPlanWhen);
    _obstacleController = TextEditingController(
      text: widget.initialPlanObstacle,
    );
  }

  @override
  void dispose() {
    _whenController.dispose();
    _obstacleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 24 + safeBottom),
      child: ListView(
        shrinkWrap: true,
        children: [
          Text(
            'Before you begin',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          CommitmentSnapshotBanner(
            active: CommitmentSeason(
              plan: widget.plan,
              currentDay: 1,
              completedDaysCount: 0,
              nudgeCountPerDay: _nudges,
              dailyLoadCount: widget.dailyLoadCount,
              dailyLoadLabel: dailyLoadLabelForCount(widget.dailyLoadCount),
              todayItems: CommitmentDailyItem.fallbackItems(
                plan: widget.plan,
                dailyLoadCount: widget.dailyLoadCount,
                completedToday: false,
                obstacle: widget.initialPlanObstacle,
              ),
            ),
          ),
          const SizedBox(height: 18),
          CommitmentDailyChecklist(
            items: CommitmentDailyItem.fallbackItems(
              plan: widget.plan,
              dailyLoadCount: widget.dailyLoadCount,
              completedToday: false,
              obstacle: widget.initialPlanObstacle,
            ),
          ),
          const SizedBox(height: 16),
          _ExpectationRow(
            icon: LucideIcons.checkCircle,
            title: 'What you do',
            body: widget.plan.dailyAction,
          ),
          const _ExpectationRow(
            icon: LucideIcons.bell,
            title: 'What reminders do',
            body: 'They prompt the action and check-in.',
          ),
          const _ExpectationRow(
            icon: LucideIcons.messageCircle,
            title: 'What happens after',
            body: 'Check in, then share one short reflection.',
          ),
          const SizedBox(height: 8),
          Text(
            'Your first check-in plan',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _whenController,
            decoration: const InputDecoration(
              labelText: 'When will you usually do this?',
              hintText: 'After prayer, lunch, work, or bedtime',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _obstacleController,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'What might get in the way?',
              hintText: 'Tiredness, scrolling, rushing, doubt',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Prayerful reminders',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$_nudges/day',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
          Slider(
            value: _nudges.toDouble(),
            min: widget.plan.nudgeMin.toDouble(),
            max: widget.plan.nudgeMax.toDouble(),
            divisions: (widget.plan.nudgeMax - widget.plan.nudgeMin)
                .clamp(1, 10)
                .toInt(),
            label: '$_nudges',
            onChanged: _joining
                ? null
                : (value) => setState(() => _nudges = value.round()),
          ),
          _FaithWalkthroughPreview(plan: widget.plan),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _joining
                ? null
                : () async {
                    setState(() => _joining = true);
                    await widget.onJoin(
                      _nudges,
                      _whenController.text,
                      _obstacleController.text,
                    );
                    if (mounted) {
                      setState(() => _joining = false);
                    }
                  },
            icon: _joining
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.flag, size: 18),
            label: Text('Begin ${widget.plan.durationDays}-day commitment'),
          ),
        ],
      ),
    );
  }
}

class _ExpectationRow extends StatelessWidget {
  const _ExpectationRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(body, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FaithWalkthroughPreview extends StatelessWidget {
  const _FaithWalkthroughPreview({required this.plan});

  final CommitmentPlan plan;

  @override
  Widget build(BuildContext context) {
    final insight = _faithInsightFor(plan.category);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.sprout, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${insight.$1}\n',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: insight.$2),
                ],
              ),
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveCommitment extends ConsumerWidget {
  const _ActiveCommitment({
    required this.active,
    this.showCheckInAction = true,
    required this.onAdjustLoad,
    required this.onBrowseNext,
  });

  final CommitmentSeason active;
  final bool showCheckInAction;
  final VoidCallback onAdjustLoad;
  final VoidCallback onBrowseNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final localPlanMatches =
        settings.firstCheckInPlanCommitmentId == active.plan.id;
    final planWhen = active.firstCheckInPlanWhen?.trim().isNotEmpty == true
        ? active.firstCheckInPlanWhen!.trim()
        : localPlanMatches
        ? settings.firstCheckInPlanWhen?.trim()
        : null;
    final planObstacle =
        active.firstCheckInPlanObstacle?.trim().isNotEmpty == true
        ? active.firstCheckInPlanObstacle!.trim()
        : localPlanMatches
        ? settings.firstCheckInPlanObstacle?.trim()
        : null;
    return VisionPanel(
      icon: LucideIcons.checkCircle,
      title: active.plan.title,
      trailing: Text(active.completionPercentLabel),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommitmentSnapshotBanner(active: active),
          if (_hasPlanContext(planWhen, planObstacle)) ...[
            const SizedBox(height: 12),
            _FirstCheckInPlanCue(when: planWhen, obstacle: planObstacle),
          ],
          const SizedBox(height: 12),
          CommitmentDailyChecklist(items: active.todayItems),
          const SizedBox(height: 12),
          if (active.checkedInToday)
            const Row(
              children: [
                Icon(LucideIcons.checkCircle, size: 18),
                SizedBox(width: 8),
                Text('Checked in today.'),
              ],
            )
          else if (!showCheckInAction)
            const Row(
              children: [
                Icon(LucideIcons.clock3, size: 18),
                SizedBox(width: 8),
                Text('Today is still open. Check in when you can.'),
              ],
            )
          else
            VisionActionTile(
              icon: LucideIcons.checkCircle,
              title: 'Mark today',
              subtitle:
                  '${active.totalRequiredItemCount}/${active.totalRequiredItemCount} today',
              onTap: () async {
                final completed = await ref
                    .read(visionProvider.notifier)
                    .checkIn();
                if (!context.mounted || completed) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'We could not complete today. Please try again.',
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 12),
          VisionActionTileColumn(
            children: [
              VisionActionTile(
                icon: LucideIcons.layers,
                title: 'Adjust load',
                subtitle: active.dailyLoadLabel,
                onTap: onAdjustLoad,
                dense: true,
              ),
              VisionActionTile(
                icon: LucideIcons.calendarClock,
                title: 'Review season',
                subtitle:
                    'Day ${active.currentDay}/${active.plan.durationDays}',
                onTap: () => _showSeasonReview(context, active),
                dense: true,
              ),
              VisionActionTile(
                icon: LucideIcons.layoutGrid,
                title: 'Browse library',
                subtitle: 'Keep current season',
                onTap: onBrowseNext,
                dense: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSeasonReview(BuildContext context, CommitmentSeason active) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (context) {
        final safeBottom = MediaQuery.paddingOf(context).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + safeBottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                active.plan.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              CommitmentProgressStrip(active: active),
              const SizedBox(height: 14),
              CommitmentDailyChecklist(items: active.todayItems),
            ],
          ),
        );
      },
    );
  }
}

class _FirstCheckInPlanCue extends StatelessWidget {
  const _FirstCheckInPlanCue({this.when, this.obstacle});

  final String? when;
  final String? obstacle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your plan',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (when?.isNotEmpty == true) Text('Usually: $when'),
          if (obstacle?.isNotEmpty == true) Text('Watch for: $obstacle'),
        ],
      ),
    );
  }
}

bool _hasPlanContext(String? when, String? obstacle) {
  return when?.isNotEmpty == true || obstacle?.isNotEmpty == true;
}

class _AccountabilityAssistantPanel extends ConsumerWidget {
  const _AccountabilityAssistantPanel({required this.active});

  final CommitmentSeason active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tone = ref.watch(settingsProvider).accountabilityTone;
    final canIncrease = active.nudgeCountPerDay < active.plan.nudgeMax;
    final suggested = (active.nudgeCountPerDay + 2).clamp(
      active.plan.nudgeMin,
      active.plan.nudgeMax,
    );

    return VisionPanel(
      icon: LucideIcons.bellRing,
      title: 'Your accountability assistant',
      trailing: Text('${tone.label} - ${active.nudgeCountPerDay}/day'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            active.checkedInToday
                ? 'The reminder did its work today: it helped you check in, then got out of the way.'
                : _missedDayCopy(tone),
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 12),
          _FaithWalkthroughPreview(plan: active.plan),
          if (!active.checkedInToday && canIncrease) ...[
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () async {
                final updated = await ref
                    .read(visionProvider.notifier)
                    .updateNudges(suggested);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      updated
                          ? 'Reminders increased to $suggested per day.'
                          : 'We could not update reminders. Please try again.',
                    ),
                  ),
                );
              },
              icon: const Icon(LucideIcons.plus, size: 18),
              label: Text('Add support: $suggested/day'),
            ),
          ],
        ],
      ),
    );
  }
}

String _missedDayCopy(AccountabilityTone tone) {
  return switch (tone) {
    AccountabilityTone.gentle =>
      'What made today hard? Notice the obstacle first; then choose one small return.',
    AccountabilityTone.balanced =>
      'Choose one support adjustment before the day slips away: check in now, increase reminders, or name the obstacle.',
    AccountabilityTone.firm =>
      'Recommit before continuing tomorrow. The structure is here to hold the line with you.',
  };
}

class _ReplacementHabit {
  const _ReplacementHabit({required this.id, required this.label});

  final String id;
  final String label;
}

class _HabitViceSeed {
  const _HabitViceSeed({
    required this.id,
    required this.label,
    required this.category,
    required this.icon,
    required this.keywords,
    required this.replacements,
  });

  final String id;
  final String label;
  final String category;
  final IconData icon;
  final List<String> keywords;
  final List<_ReplacementHabit> replacements;
}

const _habitViceSeeds = [
  _HabitViceSeed(
    id: 'scrolling',
    label: 'Endless scrolling',
    category: 'discipline',
    icon: LucideIcons.smartphone,
    keywords: ['social', 'content', 'focus', 'fast', 'silence'],
    replacements: [
      _ReplacementHabit(id: 'scripture', label: 'Read Scripture first'),
      _ReplacementHabit(id: 'silence', label: 'Two minutes of silence'),
      _ReplacementHabit(id: 'walk', label: 'Take a short prayer walk'),
    ],
  ),
  _HabitViceSeed(
    id: 'lust',
    label: 'Lust or fantasy',
    category: 'discipline',
    icon: LucideIcons.shield,
    keywords: ['fast', 'purity', 'desire', 'body', 'discipline'],
    replacements: [
      _ReplacementHabit(id: 'exit', label: 'Leave the trigger quickly'),
      _ReplacementHabit(id: 'prayer', label: 'Pray one honest sentence'),
      _ReplacementHabit(id: 'body', label: 'Move your body'),
    ],
  ),
  _HabitViceSeed(
    id: 'anger',
    label: 'Anger or contempt',
    category: 'charity',
    icon: LucideIcons.flame,
    keywords: ['forgiveness', 'mercy', 'anger', 'service', 'grace'],
    replacements: [
      _ReplacementHabit(id: 'pause', label: 'Pause before replying'),
      _ReplacementHabit(id: 'bless', label: 'Bless instead of rehearsing'),
      _ReplacementHabit(id: 'repair', label: 'Make one repair attempt'),
    ],
  ),
  _HabitViceSeed(
    id: 'avoidance',
    label: 'Avoiding responsibility',
    category: 'discipline',
    icon: LucideIcons.clock3,
    keywords: ['begin', 'start', 'discipline', 'focus', 'plan'],
    replacements: [
      _ReplacementHabit(id: 'first_step', label: 'Do the first small step'),
      _ReplacementHabit(id: 'timer', label: 'Set a ten-minute timer'),
      _ReplacementHabit(id: 'tell', label: 'Tell one trusted person'),
    ],
  ),
  _HabitViceSeed(
    id: 'self_pity',
    label: 'Self-pity or despair',
    category: 'growth',
    icon: LucideIcons.cloudRain,
    keywords: ['gratitude', 'hope', 'prayer', 'trust', 'growth'],
    replacements: [
      _ReplacementHabit(id: 'thanks', label: 'Name one mercy'),
      _ReplacementHabit(id: 'psalm', label: 'Pray a Psalm'),
      _ReplacementHabit(id: 'reach', label: 'Ask for support'),
    ],
  ),
  _HabitViceSeed(
    id: 'people_pleasing',
    label: 'People-pleasing',
    category: 'discipline',
    icon: LucideIcons.users,
    keywords: ['boundary', 'discipline', 'honest', 'focus', 'clarity'],
    replacements: [
      _ReplacementHabit(id: 'truth', label: 'Tell the simple truth'),
      _ReplacementHabit(id: 'boundary', label: 'Set one kind boundary'),
      _ReplacementHabit(id: 'pray', label: 'Pray before answering'),
    ],
  ),
];

(String, String) _faithInsightFor(String category) {
  return switch (category.toLowerCase()) {
    'discipline' => (
      'Discipline protects attention.',
      'A fast is not contempt for desire. It trains the soul to notice what has been ruling it and turn freely to God.',
    ),
    'prayer' => (
      'Prayer keeps the heart turned.',
      'Five honest minutes can loosen self-reliance and make space for dependence, confession, and trust.',
    ),
    'gratitude' => (
      'Gratitude heals spiritual blindness.',
      'Naming gifts does not deny pain. It teaches the soul to see grace without pretending life is easy.',
    ),
    'forgiveness' => (
      'Forgiveness releases the grip of resentment.',
      'It does not excuse harm. It opens a way where bitterness no longer gets to form your spirit.',
    ),
    _ => (
      'Faithfulness is formed through daily check-in.',
      'Small repeated acts tell the soul what matters and make growth possible without performance.',
    ),
  };
}

String _categoryLabel(String category) {
  return switch (category.toLowerCase()) {
    'all' => 'All commitments',
    'discipline' => 'Discipline',
    'prayer' => 'Prayer',
    'gratitude' => 'Gratitude',
    'forgiveness' => 'Forgiveness',
    _ =>
      category.isEmpty
          ? 'Growth'
          : '${category[0].toUpperCase()}${category.substring(1)}',
  };
}

List<String> _categoriesForPlans(List<CommitmentPlan> plans) {
  return ['all', ...plans.map((plan) => plan.category).toSet()];
}

IconData _categoryIcon(String category) {
  return switch (category.toLowerCase()) {
    'discipline' => LucideIcons.shield,
    'prayer' => LucideIcons.flame,
    'gratitude' => LucideIcons.sparkles,
    'forgiveness' => LucideIcons.heartHandshake,
    'all' => LucideIcons.layoutGrid,
    _ => LucideIcons.sprout,
  };
}
