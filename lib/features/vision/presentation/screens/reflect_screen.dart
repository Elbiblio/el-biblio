import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../shared/widgets/vision_illustration.dart';
import '../../application/vision_state.dart';
import '../../domain/vision_models.dart';
import '../widgets/vision_panel.dart';
import 'hangout_room_screen.dart';

class ReflectScreen extends ConsumerStatefulWidget {
  const ReflectScreen({super.key});

  @override
  ConsumerState<ReflectScreen> createState() => _ReflectScreenState();
}

class _ReflectScreenState extends ConsumerState<ReflectScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(visionProvider.notifier).load(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(visionProvider);
    final active = state.activeCommitment;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Reflect')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(visionProvider.notifier).load(force: true),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            Text(
              'Walk this with others',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              active == null
                  ? 'Reflection opens when you join a commitment.'
                  : active.plan.title,
            ),
            const SizedBox(height: 18),
            _HangoutPanel(),
            const SizedBox(height: 16),
            if (active == null)
              VisionPanel(
                icon: LucideIcons.lock,
                title: 'Join a commitment first',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: VisionIllustration(
                        asset: VisionIllustrationAsset.protection,
                        size: 86,
                        semanticLabel: 'Commitment required',
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'The feed is private to people walking the same commitment.',
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: () => context.go(AppRoutes.commit),
                      icon: const Icon(LucideIcons.flag, size: 18),
                      label: const Text('Choose commitment'),
                    ),
                  ],
                ),
              )
            else ...[
              _ReflectionComposer(controller: _controller),
              const SizedBox(height: 16),
              _FeedList(),
            ],
          ],
        ),
      ),
    );
  }
}

class _HangoutPanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(visionProvider);
    final hangouts = state.hangouts;
    return VisionPanel(
      icon: LucideIcons.headphones,
      title: 'Audio hangouts',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hangouts.isEmpty)
            const Text('No live or scheduled hangouts are available yet.')
          else
            ...hangouts.map(
              (hangout) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(LucideIcons.radio),
                title: Text(hangout.title),
                subtitle: Text(
                  '${_scopeLabel(hangout)} - ${hangout.participantCount}/${hangout.maxParticipants} joined',
                ),
                trailing: FilledButton.tonal(
                  onPressed: hangout.canJoin
                      ? () async {
                          final joined = await ref
                              .read(visionProvider.notifier)
                              .joinHangout(hangout);
                          if (!context.mounted) return;
                          if (joined?.liveKit?.isValid == true) {
                            await Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => HangoutRoomScreen(
                                  hangout: joined!,
                                  credentials: joined.liveKit!,
                                  onLeave: () => ref
                                      .read(visionProvider.notifier)
                                      .leaveHangout(joined.id),
                                ),
                              ),
                            );
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('We could not join this hangout.'),
                            ),
                          );
                        }
                      : null,
                  child: const Text('Join'),
                ),
              ),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _showCreateHangout(context, ref),
            icon: const Icon(LucideIcons.plus, size: 18),
            label: const Text('Start hangout'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateHangout(BuildContext context, WidgetRef ref) async {
    final titleController = TextEditingController(text: 'Evening return');
    final visionState = ref.read(visionProvider);
    final scopeOptions = _scopeOptions(visionState);
    var selectedScope = scopeOptions.first;
    var maxParticipants = 8.0;
    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Start hangout'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    maxLength: 80,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<_HangoutScope>(
                    segments: scopeOptions
                        .map(
                          (scope) => ButtonSegment<_HangoutScope>(
                            value: scope,
                            label: Text(scope.label),
                            icon: Icon(scope.icon, size: 18),
                          ),
                        )
                        .toList(),
                    selected: {selectedScope},
                    onSelectionChanged: (value) =>
                        setState(() => selectedScope = value.first),
                  ),
                  const SizedBox(height: 12),
                  Text('Max people: ${maxParticipants.round()}'),
                  Slider(
                    value: maxParticipants,
                    min: 2,
                    max: 50,
                    divisions: 48,
                    onChanged: (value) =>
                        setState(() => maxParticipants = value),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Start'),
                ),
              ],
            );
          },
        );
      },
    );

    if (created != true || !context.mounted) {
      titleController.dispose();
      return;
    }
    final hangout = await ref
        .read(visionProvider.notifier)
        .createCommitmentHangout(
          title: titleController.text,
          scopeType: selectedScope.type,
          scopeId: selectedScope.id,
          maxParticipants: maxParticipants.round(),
        );
    titleController.dispose();
    if (!context.mounted) return;
    if (hangout?.liveKit?.isValid == true) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => HangoutRoomScreen(
            hangout: hangout!,
            credentials: hangout.liveKit!,
            onLeave: () =>
                ref.read(visionProvider.notifier).leaveHangout(hangout.id),
          ),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          hangout == null
              ? 'We could not start it.'
              : 'Hangout started, but audio credentials were unavailable.',
        ),
      ),
    );
  }

  List<_HangoutScope> _scopeOptions(VisionState state) {
    return [
      if (state.activeCommitment != null)
        _HangoutScope(
          type: 'commitment',
          id: state.activeCommitment!.plan.id,
          label: 'Commitment',
          icon: LucideIcons.flag,
        ),
      if (state.primaryTribe != null)
        _HangoutScope(
          type: 'tribe',
          id: state.primaryTribe!.tribe.id,
          label: 'Tribe',
          icon: LucideIcons.users,
        ),
      const _HangoutScope(
        type: 'everyone',
        label: 'Everyone',
        icon: LucideIcons.globe2,
      ),
    ];
  }

  String _scopeLabel(CommitmentHangout hangout) {
    return switch (hangout.scopeType) {
      'tribe' => 'Tribe',
      'everyone' => 'Everyone',
      _ => 'Commitment',
    };
  }
}

class _HangoutScope {
  const _HangoutScope({
    required this.type,
    required this.label,
    required this.icon,
    this.id,
  });

  final String type;
  final int? id;
  final String label;
  final IconData icon;
}

class _ReflectionComposer extends ConsumerWidget {
  const _ReflectionComposer({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(visionProvider);
    final active = state.activeCommitment;
    if (active == null) return const SizedBox.shrink();

    if (!active.checkedInToday) {
      return VisionPanel(
        icon: LucideIcons.checkCircle,
        title: 'Return today first',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You can read the feed now. Share after you complete today.',
            ),
            const SizedBox(height: 12),
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

    if (state.reflectionPostedToday) {
      return const VisionPanel(
        icon: LucideIcons.messageCircle,
        title: 'Reflection shared',
        child: Text('Your reflection for today is posted.'),
      );
    }

    return VisionPanel(
      icon: LucideIcons.messageCircle,
      title: 'Share one honest reflection',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Visible to members of this commitment as ${state.visibilityAlias}.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            minLines: 3,
            maxLines: 5,
            maxLength: 500,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            decoration: const InputDecoration(
              hintText: 'What felt hard, hopeful, or honest today?',
              border: OutlineInputBorder(),
            ),
          ),
          FilledButton.icon(
            onPressed: () async {
              final posted = await ref
                  .read(visionProvider.notifier)
                  .postReflection(controller.text);
              if (!context.mounted) return;
              if (!posted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'We could not post this reflection. Please try again.',
                    ),
                  ),
                );
                return;
              }
              controller.clear();
            },
            icon: const Icon(LucideIcons.send, size: 18),
            label: const Text('Post reflection'),
          ),
        ],
      ),
    );
  }
}

class _FeedList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(visionProvider).feed;
    if (feed.isEmpty) {
      return const VisionPanel(
        icon: LucideIcons.messagesSquare,
        title: 'Reflection feed',
        child: Text(
          'No reflections yet. The feed grows one honest post at a time.',
        ),
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
                .read(visionProvider.notifier)
                .reactToReflection(item, 'support'),
          ),
        );
      }).toList(),
    );
  }
}
