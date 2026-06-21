import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../shared/widgets/safe_bottom_padding.dart';
import '../../../commit/application/failure_protocol_service.dart';
import '../../../companion/presentation/widgets/companion_bubble.dart';
import '../../../today/presentation/widgets/recalibration_suggestion_dialog.dart';
import '../../../today/presentation/widgets/streak_badge.dart';
import '../../../today/presentation/widgets/time_diagnose_suggestion_dialog.dart';
import '../../../vision/application/vision_state.dart';
import '../../../vision/domain/vision_models.dart';
import '../../../vision/presentation/widgets/commitment_daily_load_widgets.dart';
import '../../../vision/presentation/widgets/vision_panel.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(visionProvider.notifier).load();
      _checkForMissedDaysAndShowSuggestion();
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

    final active = ref.read(visionProvider).activeCommitment;
    final protocol = ref.read(failureProtocolServiceProvider);
    final failureState = active != null ? protocol.evaluate(active) : FailureState.empty;
    final habitName = active?.plan.title ?? 'your commitment';

    await ref
        .read(settingsProvider.notifier)
        .markRecalibrationPromptShown(today);

    if (!mounted) return;
    await RecalibrationSuggestionDialog.show(
      context,
      missedDays: missedDays,
      failureState: failureState,
      habitName: habitName,
      admissionOptions: protocol.admissionOptions(),
      onRecordAdmission: (admittedTo) async {
        if (active == null) return;
        await protocol.recordAdmission(
          commitmentId: active.plan.id,
          habitId: active.plan.id.toString(),
          habitName: active.plan.title,
          missedDay: active.currentDay,
          missedDate: today.subtract(Duration(days: missedDays)),
          admittedTo: admittedTo,
        );
      },
      onOpenTimeDiagnose: () {
        TimeDiagnoseSuggestionDialog.show(context);
      },
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    return switch (hour) {
      < 12 => 'Good morning',
      < 17 => 'Good afternoon',
      _ => 'Good evening',
    };
  }

  String _headline(VisionState state) {
    final active = state.activeCommitment;
    if (active != null) {
      return 'Day ${active.currentDay} of your ${active.plan.title}.';
    }
    return 'How is your spirit today?';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(visionProvider);
    final theme = Theme.of(context);
    final tokens = theme.tokens;

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
          child: RefreshIndicator(
            onRefresh: () =>
                ref.read(visionProvider.notifier).load(force: true),
            child: SafeListView(
              bottomPadding: shellChromeBottomPadding,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${_greeting()}, Friend.',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const StreakBadge(),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _headline(state),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.62),
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _NotificationButton(),
                  ],
                ),
                const SizedBox(height: 20),
                if (state.isLoading && state.activeCommitment == null)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else ...[
                  if (state.error?.isNotEmpty == true) ...[
                    VisionPanel(
                      icon: LucideIcons.wifiOff,
                      title: state.isReadOnly
                          ? 'Reconnect to continue'
                          : 'Something needs a retry',
                      child: Text(
                        state.error!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.62),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const CompanionBubble(),
                  const SizedBox(height: 16),
                  if (state.activeCommitment != null) ...[
                    _ActiveCommitmentSummary(
                      active: state.activeCommitment!,
                      onCheckIn: () => context.go(AppRoutes.commit),
                    ),
                    const SizedBox(height: 16),
                    _TribePulseCard(),
                    const SizedBox(height: 16),
                  ] else ...[
                    VisionPanel(
                      icon: LucideIcons.flag,
                      title: 'No active commitment',
                      child: Text(
                        'Start a new commitment to begin your journey.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.62),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: 'Start a Commitment',
                      icon: LucideIcons.flag,
                      onPressed: () => context.go(AppRoutes.commit),
                    ),
                    const SizedBox(height: 16),
                    _TribePulseCard(),
                    const SizedBox(height: 16),
                  ],
                  _QuickActions(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveCommitmentSummary extends StatelessWidget {
  const _ActiveCommitmentSummary({
    required this.active,
    required this.onCheckIn,
  });

  final CommitmentSeason active;
  final VoidCallback onCheckIn;

  @override
  Widget build(BuildContext context) {
    return VisionPanel(
      icon: LucideIcons.flag,
      title: active.plan.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommitmentSnapshotBanner(active: active),
          const SizedBox(height: 12),
          CommitmentProgressStrip(active: active),
          const SizedBox(height: 12),
          CommitmentDailyChecklist(
            items: active.todayItems,
            onItemTap: (_) {},
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onCheckIn,
              icon: const Icon(LucideIcons.checkCircle, size: 18),
              label: const Text('Check in'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TribePulseCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(visionProvider);
    final pulse = state.tribePulse;
    final theme = Theme.of(context);

    return VisionPanel(
      icon: LucideIcons.users,
      title: 'Tribe pulse',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.primaryTribe == null)
            Text(
              'Join a tribe to share the journey.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              ),
            )
          else if (pulse.items.isEmpty)
            Text(
              pulse.returnedCount > 0
                  ? '${pulse.returnedCount} people checked in today.'
                  : 'Your check-in can be today\'s first signal.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              ),
            )
          else
            ...pulse.items.take(3).map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(GrowthJourneyEvent.iconForKey(item.iconKey)),
                title: Text(item.text),
                dense: true,
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push(AppRoutes.tribe),
              icon: const Icon(LucideIcons.users, size: 18),
              label: Text(
                state.primaryTribe == null ? 'Find tribe' : 'Open tribe',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Tools',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _QuickActionChip(
              icon: LucideIcons.bookOpen,
              label: 'Bible',
              onTap: () => context.push(AppRoutes.bible),
            ),
            _QuickActionChip(
              icon: LucideIcons.feather,
              label: 'Journal',
              onTap: () => context.push(AppRoutes.journal),
            ),
            _QuickActionChip(
              icon: LucideIcons.headphones,
              label: 'Meditate',
              onTap: () => context.push(AppRoutes.meditation),
            ),
            _QuickActionChip(
              icon: LucideIcons.messagesSquare,
              label: 'Companion',
              onTap: () => context.push(AppRoutes.companionChat),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      onPressed: onTap,
      side: BorderSide(
        color: theme.colorScheme.outline.withValues(alpha: 0.3),
      ),
    );
  }
}

class _NotificationButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(visionProvider);
    final unread = state.notifications.where((n) => !n.read).length;

    return Stack(
      children: [
        IconButton(
          icon: const Icon(LucideIcons.bell),
          onPressed: () => context.push(AppRoutes.notifications),
        ),
        if (unread > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$unread',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon, size: 18) : null,
        label: Text(label),
      ),
    );
  }
}
