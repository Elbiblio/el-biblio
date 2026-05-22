import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../core/storage/app_settings.dart';
import '../../../../shared/widgets/safe_bottom_padding.dart';
import '../../../../shared/widgets/vision_illustration.dart';
import '../../application/vision_state.dart';
import '../../domain/vision_models.dart';
import '../widgets/commitment_daily_load_widgets.dart';
import '../widgets/vision_action_tile.dart';
import '../widgets/vision_panel.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(visionProvider.notifier).load();
    });
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
                      child: Text(
                        'Today',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _NotificationButton(),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _headline(state),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                    height: 1.45,
                  ),
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
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  _DailyLoopHero(),
                  const SizedBox(height: 14),
                  if (state.activeCommitment?.checkedInToday ?? false) ...[
                    _AfterCheckInPanel(),
                    const SizedBox(height: 14),
                  ],
                  _AmbientSupportPanel(),
                  const SizedBox(height: 14),
                  _DailyInsightPreview(),
                  const SizedBox(height: 14),
                  _StorySoFarTile(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _headline(VisionState state) {
    final active = state.activeCommitment;
    if (active != null) {
      return '${active.plan.title} - Day ${active.currentDay}/${active.plan.durationDays} - ${active.completionPercentLabel}';
    }
    return 'Choose a commitment.';
  }
}

class _NotificationButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(visionProvider).unreadNotificationCount;
    final theme = Theme.of(context);
    return IconButton(
      tooltip: 'Notifications',
      onPressed: () => context.go(AppRoutes.notifications),
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text(count > 9 ? '9+' : '$count'),
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(LucideIcons.bell),
      ),
    );
  }
}

class _DailyLoopHero extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(visionProvider);
    final active = state.activeCommitment;
    final settings = ref.watch(settingsProvider);

    if (active == null) {
      return _LoopHeroCard(
        icon: LucideIcons.flag,
        illustration: VisionIllustrationAsset.commitment,
        title: 'Choose one commitment',
        body: 'Pick the practice, load, reminders, and first day.',
        primaryLabel: 'Find commitment',
        primaryIcon: LucideIcons.arrowRight,
        onPrimary: () => context.go(AppRoutes.commit),
      );
    }

    if (active.checkedInToday && !state.reflectionPostedToday) {
      return _LoopHeroCard(
        icon: LucideIcons.messageCircle,
        illustration: VisionIllustrationAsset.growth,
        title: 'Check-in complete',
        body: 'Post one line, or keep it quiet.',
        primaryLabel: 'Reflect',
        primaryIcon: LucideIcons.send,
        onPrimary: () => context.go(AppRoutes.reflect),
        secondaryLabel: 'Stay quiet today',
        onSecondary: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('That is okay. You can reflect later if it helps.'),
          ),
        ),
      );
    }

    if (active.checkedInToday) {
      return _LoopHeroCard(
        icon: LucideIcons.checkCircle,
        illustration: VisionIllustrationAsset.completion,
        title: 'Checked in today',
        body: 'Done for today.',
        primaryLabel: 'Open commitment',
        primaryIcon: LucideIcons.flag,
        onPrimary: () => context.go(AppRoutes.commit),
      );
    }

    return VisionPanel(
      icon: LucideIcons.flag,
      title: active.plan.title,
      trailing: Text(active.completionPercentLabel),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommitmentSnapshotBanner(active: active),
          if (_hasPlanContextFor(active, settings)) ...[
            const SizedBox(height: 12),
            _RememberedPlanPanel(active: active, settings: settings),
          ],
          const SizedBox(height: 14),
          CommitmentDailyChecklist(items: active.todayItems),
          const SizedBox(height: 14),
          VisionActionTile(
            icon: LucideIcons.checkCircle,
            title: 'Mark today',
            subtitle:
                '${active.totalRequiredItemCount} actions - ${active.dailyLoadLabel}',
            onTap: state.isLoading
                ? null
                : () async {
                    final completed = await ref
                        .read(visionProvider.notifier)
                        .checkIn();
                    if (!context.mounted) return;
                    if (!completed) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'We could not complete today. Please try again.',
                          ),
                        ),
                      );
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${active.totalRequiredItemCount}/${active.totalRequiredItemCount} marked today.',
                        ),
                      ),
                    );
                  },
          ),
          const SizedBox(height: 10),
          VisionActionTile(
            icon: LucideIcons.slidersHorizontal,
            title: 'Adjust load',
            subtitle: 'Light, Steady, or Deep',
            onTap: () => context.go(AppRoutes.commit),
            dense: true,
          ),
        ],
      ),
    );
  }
}

class _RememberedPlanPanel extends StatelessWidget {
  const _RememberedPlanPanel({required this.active, required this.settings});

  final CommitmentSeason active;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final when = _planWhenFor(active, settings);
    final obstacle = _planObstacleFor(active, settings);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Remember your plan',
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

bool _hasPlanContextFor(CommitmentSeason active, AppSettings settings) {
  return _planWhenFor(active, settings)?.isNotEmpty == true ||
      _planObstacleFor(active, settings)?.isNotEmpty == true;
}

String? _planWhenFor(CommitmentSeason active, AppSettings settings) {
  if (active.firstCheckInPlanWhen?.trim().isNotEmpty == true) {
    return active.firstCheckInPlanWhen!.trim();
  }
  if (settings.firstCheckInPlanCommitmentId == active.plan.id) {
    final value = settings.firstCheckInPlanWhen?.trim();
    return value?.isNotEmpty == true ? value : null;
  }
  return null;
}

String? _planObstacleFor(CommitmentSeason active, AppSettings settings) {
  if (active.firstCheckInPlanObstacle?.trim().isNotEmpty == true) {
    return active.firstCheckInPlanObstacle!.trim();
  }
  if (settings.firstCheckInPlanCommitmentId == active.plan.id) {
    final value = settings.firstCheckInPlanObstacle?.trim();
    return value?.isNotEmpty == true ? value : null;
  }
  return null;
}

class _LoopHeroCard extends StatelessWidget {
  const _LoopHeroCard({
    required this.icon,
    required this.illustration,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.primaryIcon,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final IconData icon;
  final VisionIllustrationAsset illustration;
  final String title;
  final String body;
  final String primaryLabel;
  final IconData primaryIcon;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: theme.colorScheme.primary),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      body,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.42),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              VisionIllustration(
                asset: illustration,
                size: 92,
                semanticLabel: title,
              ),
            ],
          ),
          const SizedBox(height: 16),
          VisionActionTile(
            icon: primaryIcon,
            title: primaryLabel,
            onTap: onPrimary,
          ),
          if (secondaryLabel != null && onSecondary != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
          ],
        ],
      ),
    );
  }
}

class _AfterCheckInPanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(visionProvider);
    final theme = Theme.of(context);
    final supportCount = state.feed.fold<int>(
      0,
      (sum, item) => sum + item.reactionCount,
    );

    return VisionPanel(
      icon: LucideIcons.sparkles,
      title: 'After your check-in',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _AmbientPill(
                icon: state.reflectionPostedToday
                    ? LucideIcons.checkCircle
                    : LucideIcons.messageCircle,
                label: state.reflectionPostedToday
                    ? 'Reflection shared'
                    : 'Reflection open',
              ),
              _AmbientPill(
                icon: LucideIcons.heartHandshake,
                label: '$supportCount supports',
              ),
              if (state.dailyQuestion != null)
                const _AmbientPill(
                  icon: LucideIcons.helpCircle,
                  label: 'Question ready',
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${state.activeCommitment?.plan.title ?? 'Commitment'} - ${state.activeCommitment?.completionPercentLabel ?? '0.0%'}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          VisionActionTileColumn(
            children: [
              if (!state.reflectionPostedToday)
                VisionActionTile(
                  icon: LucideIcons.messageCircle,
                  title: 'Reflect',
                  subtitle: 'Posting as ${state.visibilityAlias}',
                  onTap: () => context.go(AppRoutes.reflect),
                  dense: true,
                ),
              VisionActionTile(
                icon: LucideIcons.helpCircle,
                title: 'Answer question',
                subtitle: 'One honest sentence',
                onTap: () => context.go(AppRoutes.grow),
                dense: true,
              ),
              VisionActionTile(
                icon: LucideIcons.users,
                title: 'Open tribe',
                subtitle:
                    state.primaryTribe?.tribe.displayName ?? 'Invite or join',
                onTap: () => context.go(AppRoutes.tribe),
                dense: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AmbientSupportPanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(visionProvider);
    final tribe = state.primaryTribe;
    final liveHangout =
        tribe != null &&
        state.hangouts.any(
          (item) =>
              item.canJoin &&
              item.scopeType == 'tribe' &&
              item.scopeId == tribe.tribe.id,
        );
    final returned = state.tribePulse.returnedCount;

    return VisionPanel(
      icon: LucideIcons.users,
      title: 'Support',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tribe == null)
            VisionActionTile(
              icon: LucideIcons.users,
              title: 'Choose tribe',
              subtitle: 'Join for check-ins',
              onTap: () => context.go(AppRoutes.tribe),
              dense: true,
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _AmbientPill(
                  icon: LucideIcons.users,
                  label: tribe.tribe.displayName,
                ),
                _AmbientPill(
                  icon: LucideIcons.checkCircle,
                  label: returned > 0 ? '$returned checked in' : 'Quiet today',
                ),
                if (liveHangout)
                  const _AmbientPill(
                    icon: LucideIcons.radio,
                    label: 'Live room',
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _AmbientPill extends StatelessWidget {
  const _AmbientPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _DailyInsightPreview extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final question = ref.watch(visionProvider).dailyQuestion;
    if (question == null) return const SizedBox.shrink();
    final previewQuestion = question.packQuestions.isNotEmpty
        ? question.packQuestions.first
        : question;

    return VisionPanel(
      icon: LucideIcons.helpCircle,
      title: 'Question',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(previewQuestion.question),
          const SizedBox(height: 12),
          VisionActionTile(
            icon: LucideIcons.helpCircle,
            title: 'Answer',
            subtitle: 'Today',
            onTap: () => context.go(AppRoutes.grow),
            dense: true,
          ),
        ],
      ),
    );
  }
}

class _StorySoFarTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(visionProvider).journeyEvents;
    if (events.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 12),
      leading: const Icon(LucideIcons.map),
      title: Text(
        'Story so far',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text('${events.length} milestones'),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: events.map((event) {
              return Chip(
                avatar: Icon(
                  event.icon,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                label: Text(event.title),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
