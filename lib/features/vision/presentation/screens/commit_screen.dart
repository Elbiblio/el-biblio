import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/di/app_providers.dart';
import '../../../../shared/widgets/premium_success_dialog.dart';
import '../../../../shared/widgets/vision_illustration.dart';
import '../../domain/vision_models.dart';
import '../widgets/vision_panel.dart';

class CommitScreen extends ConsumerStatefulWidget {
  const CommitScreen({super.key});

  @override
  ConsumerState<CommitScreen> createState() => _CommitScreenState();
}

class _CommitScreenState extends ConsumerState<CommitScreen> {
  int _selectedNudges = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(visionProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(visionProvider);
    final active = state.activeCommitment;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Commit')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          Text(
            active == null ? 'Choose one path' : 'Keep your commitment',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            active == null
                ? 'A time-bound commitment gives your growth a concrete shape.'
                : 'Your daily return is simple, specific, and supported.',
          ),
          const SizedBox(height: 18),
          if (active == null) ...[
            const Center(
              child: VisionIllustration(
                asset: VisionIllustrationAsset.commitment,
                size: 118,
                semanticLabel: 'Commitment',
              ),
            ),
            const SizedBox(height: 18),
          ],
          if (active != null) ...[
            _ActiveCommitment(active: active),
            const SizedBox(height: 20),
            VisionPanel(
              icon: LucideIcons.lock,
              title: 'One commitment at a time',
              child: Text(
                'Continue this path before beginning another. This keeps your daily rhythm simple.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ] else ...[
            ...state.recommendedCommitments.map(_buildCommitmentOption),
          ],
        ],
      ),
    );
  }

  Widget _buildCommitmentOption(CommitmentPlan plan) {
    final theme = Theme.of(context);
    final min = plan.nudgeMin;
    final max = plan.nudgeMax;
    final nudges = _selectedNudges.clamp(min, max);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
          Text(
            plan.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(plan.description),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(LucideIcons.bell, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text('$nudges gentle nudges per day')),
            ],
          ),
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
                : () async {
                    final joined = await ref
                        .read(visionProvider.notifier)
                        .joinCommitment(plan, nudges);
                    if (!mounted) return;
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
                          'Your daily return is ready. Gentle nudges will help you remember the path.',
                      primaryActionText: 'Continue',
                    );
                  },
            icon: const Icon(LucideIcons.flag, size: 18),
            label: const Text('Join commitment'),
          ),
        ],
      ),
    );
  }
}

class _ActiveCommitment extends ConsumerWidget {
  const _ActiveCommitment({required this.active});

  final CommitmentSeason active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return VisionPanel(
      icon: LucideIcons.checkCircle,
      title: active.plan.title,
      trailing: Text('Day ${active.currentDay}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(active.plan.dailyAction),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: active.progress),
          const SizedBox(height: 12),
          if (active.checkedInToday)
            const Row(
              children: [
                Icon(LucideIcons.checkCircle, size: 18),
                SizedBox(width: 8),
                Text('You returned today.'),
              ],
            )
          else
            FilledButton.icon(
              onPressed: () async {
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
              icon: const Icon(LucideIcons.checkCircle, size: 18),
              label: const Text('Mark today\'s return'),
            ),
        ],
      ),
    );
  }
}
