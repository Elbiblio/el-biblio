import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../shared/widgets/vision_illustration.dart';
import '../../application/vision_state.dart';
import '../../domain/vision_models.dart';
import '../widgets/reflection_feed_widgets.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Reflect')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(visionProvider.notifier).load(force: true),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            _ReflectHeader(state: state),
            const SizedBox(height: 16),
            if (active == null)
              VisionPanel(
                icon: LucideIcons.lock,
                title: 'Join a commitment to open the room',
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
                      'Reflect is intentionally scoped. You share with people walking the same commitment, not a public crowd.',
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
              VisionReflectionComposer(controller: _controller),
              const SizedBox(height: 16),
              const VisionReflectionFeed(),
              const SizedBox(height: 16),
              _HangoutPanel(),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReflectHeader extends StatelessWidget {
  const _ReflectHeader({required this.state});

  final VisionState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = state.activeCommitment;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.messagesSquare,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Reflect together',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            active == null
                ? 'A quieter social space opens after you choose a commitment.'
                : 'A private feed for ${active.plan.title}. Return first, then share one honest sentence if it helps.',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
          if (active != null) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ReflectStat(
                  icon: LucideIcons.checkCircle,
                  label: active.checkedInToday
                      ? 'Returned today'
                      : 'Return open',
                ),
                _ReflectStat(
                  icon: LucideIcons.messageCircle,
                  label: state.reflectionPostedToday
                      ? 'Shared today'
                      : 'One reflection',
                ),
                _ReflectStat(
                  icon: LucideIcons.heartHandshake,
                  label: '${state.feed.length} reflections',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ReflectStat extends StatelessWidget {
  const _ReflectStat({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(999),
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

class _HangoutPanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(visionProvider);
    final hangouts = state.hangouts;
    return VisionPanel(
      icon: LucideIcons.radio,
      title: 'Live support rooms',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hangouts.isEmpty)
            const Text(
              'No live rooms yet. Start a small room when reflection needs a voice.',
            )
          else
            ...hangouts.map(
              (hangout) => _HangoutCard(
                hangout: hangout,
                scopeLabel: _scopeLabel(hangout),
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

class _HangoutCard extends ConsumerWidget {
  const _HangoutCard({required this.hangout, required this.scopeLabel});

  final CommitmentHangout hangout;
  final String scopeLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hangout.status == 'live' ? LucideIcons.radio : LucideIcons.clock3,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hangout.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$scopeLabel - ${hangout.participantCount}/${hangout.maxParticipants} joined',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          FilledButton.tonal(
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
        ],
      ),
    );
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
