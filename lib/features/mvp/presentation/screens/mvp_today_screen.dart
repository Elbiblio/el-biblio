import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/theme/app_theme_tokens.dart';

class MvpTodayScreen extends ConsumerStatefulWidget {
  const MvpTodayScreen({super.key});

  @override
  ConsumerState<MvpTodayScreen> createState() => _MvpTodayScreenState();
}

class _MvpTodayScreenState extends ConsumerState<MvpTodayScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mvpProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mvpProvider);
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
            onRefresh: () => ref.read(mvpProvider.notifier).load(),
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
                  _CommitmentCard(),
                  const SizedBox(height: 14),
                  _TribeCue(),
                  const SizedBox(height: 14),
                  _QuestionPreview(),
                  const SizedBox(height: 14),
                  _MilestoneStrip(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _headline(dynamic state) {
    final active = state.activeCommitment;
    if (active == null) {
      return 'Begin with belonging, then choose one commitment.';
    }
    if (active.checkedInToday) {
      return 'You completed today. Share one honest reflection when you are ready.';
    }
    return 'One commitment. One check-in. One small return.';
  }
}

class _CommitmentCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mvpProvider);
    final active = state.activeCommitment;
    final theme = Theme.of(context);

    if (active == null) {
      return _Panel(
        icon: LucideIcons.flag,
        title: 'Choose a commitment',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A challenge unlocks your daily check-in and private reflection feed.',
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => context.go(AppRoutes.mvpChallenge),
              icon: const Icon(LucideIcons.arrowRight, size: 18),
              label: const Text('Find a challenge'),
            ),
          ],
        ),
      );
    }

    return _Panel(
      icon: LucideIcons.flag,
      title: active.challenge.title,
      trailing: Text(
        'Day ${active.currentDay}/${active.challenge.durationDays}',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            active.challenge.dailyAction,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 14),
          LinearProgressIndicator(value: active.progress),
          const SizedBox(height: 14),
          if (active.checkedInToday)
            FilledButton.tonalIcon(
              onPressed: () => context.go(AppRoutes.mvpChallenge),
              icon: const Icon(LucideIcons.messageCircle, size: 18),
              label: const Text('Open reflection feed'),
            )
          else
            FilledButton.icon(
              onPressed: state.isLoading
                  ? null
                  : () => ref.read(mvpProvider.notifier).checkIn(),
              icon: const Icon(LucideIcons.checkCircle, size: 18),
              label: const Text('Complete today'),
            ),
        ],
      ),
    );
  }
}

class _TribeCue extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tribe = ref.watch(mvpProvider).primaryTribe;
    if (tribe == null) {
      return _Panel(
        icon: LucideIcons.users,
        title: 'Find your tribe',
        child: Row(
          children: [
            const Expanded(
              child: Text('A tribe gives your challenge a place to belong.'),
            ),
            TextButton(
              onPressed: () => context.go(AppRoutes.mvpTribes),
              child: const Text('Choose'),
            ),
          ],
        ),
      );
    }

    return _Panel(
      icon: LucideIcons.users,
      title: tribe.tribe.name,
      child: Text(
        'Posting as ${tribe.displayAlias}. Weekend rituals open inside your tribe.',
      ),
    );
  }
}

class _QuestionPreview extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final question = ref.watch(mvpProvider).dailyQuestion;
    if (question == null) return const SizedBox.shrink();

    return _Panel(
      icon: LucideIcons.helpCircle,
      title: 'Daily question',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question.question),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.go(AppRoutes.mvpQuestions),
            child: const Text('Sit with this'),
          ),
        ],
      ),
    );
  }
}

class _MilestoneStrip extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final milestones = ref.watch(mvpProvider).milestones;
    if (milestones.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: milestones.map((milestone) {
        return Chip(
          avatar: Icon(
            milestone.icon,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          label: Text(milestone.title),
        );
      }).toList(),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
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
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
