import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../core/services/celebration_service.dart';
import '../../../../shared/widgets/premium_success_dialog.dart';
import '../../../../shared/widgets/vision_illustration.dart';
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
                Text(
                  'Today',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
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
                  _CommitmentReturnCard(),
                  const SizedBox(height: 14),
                  _TribePulsePreview(),
                  const SizedBox(height: 14),
                  _DailyInsightPreview(),
                  const SizedBox(height: 14),
                  _JourneyStrip(),
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
      return 'You returned today. Reflect when you are ready.';
    }
    return 'One commitment. One check-in. One small return.';
  }
}

class _CommitmentReturnCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(visionProvider);
    final active = state.activeCommitment;
    final theme = Theme.of(context);

    if (active == null) {
      return VisionPanel(
        icon: LucideIcons.flag,
        title: 'Choose a commitment',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A commitment opens your daily return and private reflection feed.',
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => context.go(AppRoutes.commit),
              icon: const Icon(LucideIcons.arrowRight, size: 18),
              label: const Text('Find a commitment'),
            ),
          ],
        ),
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
          if (active.checkedInToday)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: VisionIllustration(
                    asset: VisionIllustrationAsset.completion,
                    size: 86,
                    semanticLabel: 'Daily commitment complete',
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: () => context.go(AppRoutes.reflect),
                  icon: const Icon(LucideIcons.messageCircle, size: 18),
                  label: const Text('Open Reflect'),
                ),
              ],
            )
          else
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
                            'Your commitment is checked in. You can share one honest reflection when you are ready.',
                        primaryActionText: 'Open Reflect',
                        onPrimaryAction: () => context.go(AppRoutes.reflect),
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

class _TribePulsePreview extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(visionProvider);
    final tribe = state.primaryTribe;
    if (tribe == null) {
      return VisionPanel(
        icon: LucideIcons.users,
        title: 'Find your tribe',
        child: Row(
          children: [
            const Expanded(
              child: Text('Belonging gives your commitment a place to grow.'),
            ),
            TextButton(
              onPressed: () => context.go(AppRoutes.tribe),
              child: const Text('Choose'),
            ),
          ],
        ),
      );
    }

    final returned = state.tribePulse.returnedCount;
    return VisionPanel(
      icon: LucideIcons.users,
      title: tribe.tribe.name,
      child: Text(
        returned > 0
            ? '$returned people in your tribe returned today.'
            : 'Your tribe pulse will appear here as people return today.',
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

class _JourneyStrip extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(visionProvider).journeyEvents;
    if (events.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: events.map((event) {
        return Chip(
          avatar: Icon(event.icon, size: 16, color: theme.colorScheme.primary),
          label: Text(event.title),
        );
      }).toList(),
    );
  }
}
