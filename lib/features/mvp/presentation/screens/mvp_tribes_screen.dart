import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/di/app_providers.dart';
import '../../domain/mvp_models.dart';

class MvpTribesScreen extends ConsumerStatefulWidget {
  const MvpTribesScreen({super.key});

  @override
  ConsumerState<MvpTribesScreen> createState() => _MvpTribesScreenState();
}

class _MvpTribesScreenState extends ConsumerState<MvpTribesScreen> {
  final _aliasController = TextEditingController();
  MvpVisibilityMode _mode = MvpVisibilityMode.anonymous;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(mvpProvider);
      _mode = state.visibilityMode;
      _aliasController.text = state.visibilityAlias == 'Anonymous'
          ? ''
          : state.visibilityAlias;
      ref.read(mvpProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _aliasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mvpProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Tribes')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          Text(
            'Belonging before performance',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose how you appear, then join a spiritually aligned tribe.',
          ),
          const SizedBox(height: 18),
          _VisibilityPanel(
            mode: _mode,
            controller: _aliasController,
            onModeChanged: (mode) => setState(() => _mode = mode),
            onSave: () => ref
                .read(mvpProvider.notifier)
                .setVisibility(_mode, alias: _aliasController.text),
          ),
          const SizedBox(height: 18),
          if (state.primaryTribe != null) ...[
            _CurrentTribe(membership: state.primaryTribe!),
            const SizedBox(height: 18),
          ],
          ...state.recommendedTribes.map((tribe) {
            final isJoined = state.primaryTribe?.tribe.id == tribe.id;
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
                  Row(
                    children: [
                      Icon(
                        MilestoneEvent.iconForKey(tribe.iconKey),
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          tribe.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(tribe.description),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    onPressed: isJoined
                        ? null
                        : () => ref.read(mvpProvider.notifier).joinTribe(tribe),
                    icon: Icon(
                      isJoined ? LucideIcons.checkCircle : LucideIcons.users,
                      size: 18,
                    ),
                    label: Text(isJoined ? 'Joined' : 'Join tribe'),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _VisibilityPanel extends StatelessWidget {
  const _VisibilityPanel({
    required this.mode,
    required this.controller,
    required this.onModeChanged,
    required this.onSave,
  });

  final MvpVisibilityMode mode;
  final TextEditingController controller;
  final ValueChanged<MvpVisibilityMode> onModeChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          SegmentedButton<MvpVisibilityMode>(
            segments: MvpVisibilityMode.values
                .map(
                  (item) => ButtonSegment(value: item, label: Text(item.label)),
                )
                .toList(),
            selected: {mode},
            onSelectionChanged: (selection) => onModeChanged(selection.first),
          ),
          if (mode == MvpVisibilityMode.nickname ||
              mode == MvpVisibilityMode.public) ...[
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLength: 50,
              decoration: const InputDecoration(
                labelText: 'Display name',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onSave,
              child: const Text('Save visibility'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentTribe extends StatelessWidget {
  const _CurrentTribe({required this.membership});

  final MvpTribeMembership membership;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.all(16),
      tileColor: Theme.of(
        context,
      ).colorScheme.primaryContainer.withValues(alpha: 0.24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      leading: const Icon(LucideIcons.users),
      title: Text(membership.tribe.name),
      subtitle: Text('Posting as ${membership.displayAlias}'),
    );
  }
}
