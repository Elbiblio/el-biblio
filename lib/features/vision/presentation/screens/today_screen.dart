import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../core/services/celebration_service.dart';
import '../../../../shared/widgets/premium_success_dialog.dart';
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
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
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
                  _headline(state.activeCommitment?.checkedInToday ?? false),
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
                  _DailyLoopHero(),
                  const SizedBox(height: 14),
                  if (state.activeCommitment?.checkedInToday ?? false) ...[
                    _AfterReturnPanel(),
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

  String _headline(bool checkedInToday) {
    if (checkedInToday) {
      return 'You returned today. Let the next step stay light.';
    }
    return 'One commitment. One check-in. One small return.';
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
    final theme = Theme.of(context);

    if (active == null) {
      return _LoopHeroCard(
        icon: LucideIcons.flag,
        title: 'Choose one path',
        body:
            'Start with a concrete practice, a gentle nudge rhythm, and a private reflection feed.',
        primaryLabel: 'Find a path',
        primaryIcon: LucideIcons.arrowRight,
        onPrimary: () => context.go(AppRoutes.commit),
      );
    }

    if (active.checkedInToday && !state.reflectionPostedToday) {
      return _LoopHeroCard(
        icon: LucideIcons.messageCircle,
        title: 'Return complete',
        body:
            'Share one honest sentence with people walking the same path, or let today stay quiet.',
        primaryLabel: 'Share on Path',
        primaryIcon: LucideIcons.send,
        onPrimary: () => context.go(AppRoutes.commit),
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
        title: 'You returned today',
        body:
            'Your path is cared for. Read support when you want it, then move gently back into the day.',
        primaryLabel: 'Open Path',
        primaryIcon: LucideIcons.flag,
        onPrimary: () => context.go(AppRoutes.commit),
      );
    }

    return VisionPanel(
      icon: LucideIcons.flag,
      title: active.plan.title,
      trailing: Text('Day ${active.currentDay}/${active.plan.durationDays}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            active.plan.dailyAction,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 14),
          LinearProgressIndicator(value: active.progress),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: state.isLoading
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
                    CelebrationService.instance.playDailyCheckInCompletion(
                      context,
                    );
                    await PremiumSuccessDialog.show(
                      context,
                      title: 'You returned today',
                      message:
                          'Your commitment is checked in. Share a reflection only if it helps you stay honest.',
                      primaryActionText: 'Open Path',
                      onPrimaryAction: () => context.go(AppRoutes.commit),
                    );
                  },
            icon: const Icon(LucideIcons.checkCircle, size: 18),
            label: const Text('Mark today\'s return'),
          ),
        ],
      ),
    );
  }
}

class _LoopHeroCard extends StatelessWidget {
  const _LoopHeroCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.primaryIcon,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final IconData icon;
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
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(body, style: theme.textTheme.bodyMedium?.copyWith(height: 1.45)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onPrimary,
            icon: Icon(primaryIcon, size: 18),
            label: Text(primaryLabel),
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

class _AfterReturnPanel extends ConsumerWidget {
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
      title: 'After your return',
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
            'Everything here is optional. The daily return is the center.',
            style: theme.textTheme.bodySmall,
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
    final liveHangout = state.hangouts.where((item) => item.canJoin).isNotEmpty;
    final returned = state.tribePulse.returnedCount;

    return VisionPanel(
      icon: LucideIcons.users,
      title: 'Ambient support',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tribe == null)
            Row(
              children: [
                const Expanded(
                  child: Text('Belonging gives your path a place to grow.'),
                ),
                TextButton(
                  onPressed: () => context.go(AppRoutes.tribe),
                  child: const Text('Choose'),
                ),
              ],
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
                  label: returned > 0 ? '$returned returned' : 'Quiet today',
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

    return VisionPanel(
      icon: LucideIcons.helpCircle,
      title: 'Daily faith question',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question.question),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.go(AppRoutes.grow),
            child: const Text('Sit with this'),
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
