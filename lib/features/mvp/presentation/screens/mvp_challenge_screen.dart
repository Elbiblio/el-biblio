import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/di/app_providers.dart';
import '../../domain/mvp_models.dart';

class MvpChallengeScreen extends ConsumerStatefulWidget {
  const MvpChallengeScreen({super.key});

  @override
  ConsumerState<MvpChallengeScreen> createState() => _MvpChallengeScreenState();
}

class _MvpChallengeScreenState extends ConsumerState<MvpChallengeScreen> {
  final _reflectionController = TextEditingController();
  int _selectedNudges = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(mvpProvider.notifier).load(),
    );
  }

  @override
  void dispose() {
    _reflectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mvpProvider);
    final active = state.activeCommitment;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Challenge')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          if (active == null)
            ..._buildCommitmentPicker(state.recommendedCommitments)
          else ...[
            Text(
              active.challenge.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(active.challenge.description),
            const SizedBox(height: 16),
            _ProgressPanel(active: active),
            const SizedBox(height: 16),
            if (active.checkedInToday)
              _ReflectionComposer(controller: _reflectionController),
            const SizedBox(height: 16),
            _FeedList(),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildCommitmentPicker(
    List<MvpCommitmentChallenge> commitments,
  ) {
    final theme = Theme.of(context);
    return [
      Text(
        'Choose one commitment',
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 8),
      const Text('Your reflection feed opens after you join a challenge.'),
      const SizedBox(height: 18),
      ...commitments.map((challenge) {
        final min = challenge.nudgeMin;
        final max = challenge.nudgeMax;
        _selectedNudges = _selectedNudges.clamp(min, max);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.12),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                challenge.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(challenge.description),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(LucideIcons.bell, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('$_selectedNudges gentle nudges per day'),
                  ),
                ],
              ),
              Slider(
                value: _selectedNudges.toDouble(),
                min: min.toDouble(),
                max: max.toDouble(),
                divisions: max - min,
                label: '$_selectedNudges',
                onChanged: (value) =>
                    setState(() => _selectedNudges = value.round()),
              ),
              FilledButton.icon(
                onPressed: () => ref
                    .read(mvpProvider.notifier)
                    .joinCommitment(challenge, _selectedNudges),
                icon: const Icon(LucideIcons.flag, size: 18),
                label: const Text('Join challenge'),
              ),
            ],
          ),
        );
      }),
    ];
  }
}

class _ProgressPanel extends ConsumerWidget {
  const _ProgressPanel({required this.active});

  final MvpCommitmentMembership active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(active.challenge.dailyAction),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: active.progress),
          const SizedBox(height: 12),
          if (!active.checkedInToday)
            FilledButton.icon(
              onPressed: () => ref.read(mvpProvider.notifier).checkIn(),
              icon: const Icon(LucideIcons.checkCircle, size: 18),
              label: const Text('Complete today'),
            )
          else
            const Row(
              children: [
                Icon(LucideIcons.checkCircle, size: 18),
                SizedBox(width: 8),
                Text('Today is complete'),
              ],
            ),
        ],
      ),
    );
  }
}

class _ReflectionComposer extends ConsumerWidget {
  const _ReflectionComposer({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mvpProvider);
    if (state.reflectionPostedToday) {
      return const Text('Your reflection for today is posted.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          minLines: 3,
          maxLines: 5,
          maxLength: 500,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          decoration: const InputDecoration(
            labelText: 'Share one honest reflection',
            border: OutlineInputBorder(),
          ),
        ),
        FilledButton.icon(
          onPressed: () async {
            await ref
                .read(mvpProvider.notifier)
                .postReflection(controller.text);
            controller.clear();
          },
          icon: const Icon(LucideIcons.messageCircle, size: 18),
          label: const Text('Post reflection'),
        ),
      ],
    );
  }
}

class _FeedList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(mvpProvider).feed;
    if (feed.isEmpty) {
      return const Text(
        'No reflections yet. The feed grows one honest post at a time.',
      );
    }

    return Column(
      children: feed.map((item) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(child: Icon(LucideIcons.user, size: 18)),
          title: Text(item.alias),
          subtitle: Text(item.content),
          trailing: IconButton(
            tooltip: 'Support',
            icon: const Icon(LucideIcons.heartHandshake),
            onPressed: () => ref
                .read(mvpProvider.notifier)
                .reactToReflection(item, 'support'),
          ),
        );
      }).toList(),
    );
  }
}
