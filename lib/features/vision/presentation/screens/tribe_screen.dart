import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../shared/widgets/premium_success_dialog.dart';
import '../../../../shared/widgets/vision_illustration.dart';
import '../../domain/vision_models.dart';
import '../widgets/visibility_mode_picker.dart';
import '../widgets/vision_panel.dart';

class TribeScreen extends ConsumerStatefulWidget {
  const TribeScreen({super.key});

  @override
  ConsumerState<TribeScreen> createState() => _TribeScreenState();
}

class _TribeScreenState extends ConsumerState<TribeScreen> {
  final _aliasController = TextEditingController();
  final _weeklyController = TextEditingController();
  VisibilityMode _mode = VisibilityMode.anonymous;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(visionProvider);
      _mode = state.visibilityMode;
      _aliasController.text = state.visibilityAlias == 'Anonymous'
          ? ''
          : state.visibilityAlias;
      ref.read(visionProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _aliasController.dispose();
    _weeklyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(visionProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Tribe')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          Text(
            state.primaryTribe?.tribe.displayName ?? 'Find your tribe',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.primaryTribe == null
                ? 'Tribe is belonging before performance.'
                : 'Posting as ${state.primaryTribe!.displayAlias}.',
          ),
          const SizedBox(height: 18),
          if (state.primaryTribe == null) ...[
            const Center(
              child: VisionIllustration(
                asset: VisionIllustrationAsset.belonging,
                size: 118,
                semanticLabel: 'Belonging',
              ),
            ),
            const SizedBox(height: 18),
          ],
          _PulsePanel(),
          const SizedBox(height: 14),
          _WeeklyReflectionHub(controller: _weeklyController),
          const SizedBox(height: 14),
          _ActionPanel(
            mode: _mode,
            controller: _aliasController,
            onModeChanged: (mode) => setState(() => _mode = mode),
            onSave: () async {
              final saved = await ref
                  .read(visionProvider.notifier)
                  .setVisibility(_mode, alias: _aliasController.text);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    saved
                        ? 'Visibility updated.'
                        : 'We could not save visibility. Please try again.',
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          ...state.recommendedTribes.map((tribe) {
            final joined = state.primaryTribe?.tribe.id == tribe.id;
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
                        GrowthJourneyEvent.iconForKey(tribe.iconKey),
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          tribe.displayName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(tribe.description),
                  if (tribe.matchReason?.isNotEmpty == true) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.22,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            LucideIcons.compass,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              tribe.matchReason!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    onPressed: joined
                        ? null
                        : () async {
                            final joined = await ref
                                .read(visionProvider.notifier)
                                .joinTribe(tribe);
                            if (!context.mounted) return;
                            if (!joined) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'We could not join this tribe. Please try again.',
                                  ),
                                ),
                              );
                              return;
                            }
                            await PremiumSuccessDialog.show(
                              context,
                              title: 'You joined ${tribe.displayName}',
                              message:
                                  'Your commitment and reflections now have a place of belonging.',
                              primaryActionText: 'Continue',
                            );
                          },
                    icon: Icon(
                      joined ? LucideIcons.checkCircle : LucideIcons.users,
                      size: 18,
                    ),
                    label: Text(joined ? 'Joined' : 'Join tribe'),
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

class _WeeklyReflectionHub extends ConsumerWidget {
  const _WeeklyReflectionHub({required this.controller});

  final TextEditingController controller;

  bool get _isWeekend {
    final weekday = DateTime.now().weekday;
    return weekday == DateTime.saturday || weekday == DateTime.sunday;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(visionProvider);
    final tribe = state.primaryTribe;
    final theme = Theme.of(context);
    final bookmarkedCount = state.weeklyReflections
        .where((item) => item.bookmarkedByMe)
        .length;

    return VisionPanel(
      icon: LucideIcons.calendarHeart,
      title: 'Weekend reflection',
      trailing: tribe == null
          ? null
          : TextButton.icon(
              onPressed: () => _openHub(context),
              icon: const Icon(LucideIcons.arrowUpRight, size: 16),
              label: const Text('Open'),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tribe == null)
            const Text('Join a tribe to share a weekend reflection.')
          else ...[
            Text(
              _isWeekend
                  ? 'A slower place for what this week formed in ${tribe.tribe.displayName}.'
                  : 'It opens Saturday and Sunday. Read or save anything you want to carry forward.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _WeeklyPill(
                  icon: LucideIcons.messageCircle,
                  label: '${state.weeklyReflections.length} shared',
                ),
                _WeeklyPill(
                  icon: LucideIcons.bookmark,
                  label: '$bookmarkedCount saved',
                ),
                _WeeklyPill(
                  icon: _isWeekend ? LucideIcons.unlock : LucideIcons.lock,
                  label: _isWeekend ? 'Open now' : 'Weekend',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _openHub(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) =>
          _WeeklyReflectionSheet(controller: controller, isWeekend: _isWeekend),
    );
  }
}

class _WeeklyReflectionSheet extends ConsumerWidget {
  const _WeeklyReflectionSheet({
    required this.controller,
    required this.isWeekend,
  });

  final TextEditingController controller;
  final bool isWeekend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(visionProvider);
    final tribe = state.primaryTribe;
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      minChildSize: 0.42,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Text(
              'Weekend reflection',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tribe == null
                  ? 'Join a tribe to share a weekend reflection.'
                  : 'A weekly pause for ${tribe.tribe.displayName}. Save what you want to keep close.',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.42),
            ),
            if (tribe != null && isWeekend) ...[
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                minLines: 2,
                maxLines: 4,
                maxLength: 500,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                decoration: const InputDecoration(
                  hintText: 'What did this week teach you?',
                  border: OutlineInputBorder(),
                ),
              ),
              FilledButton.icon(
                onPressed: () async {
                  final posted = await ref
                      .read(visionProvider.notifier)
                      .postWeeklyReflection(controller.text);
                  if (!context.mounted) return;
                  if (!posted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'We could not post this weekly reflection.',
                        ),
                      ),
                    );
                    return;
                  }
                  controller.clear();
                },
                icon: const Icon(LucideIcons.send, size: 18),
                label: const Text('Post weekly reflection'),
              ),
            ],
            const SizedBox(height: 18),
            if (state.weeklyReflections.isEmpty)
              const Text('No weekly reflections yet.')
            else
              ...state.weeklyReflections.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    child: Icon(LucideIcons.user, size: 18),
                  ),
                  title: Text(item.alias),
                  subtitle: Text(item.content),
                  trailing: IconButton(
                    tooltip: item.bookmarkedByMe
                        ? 'Remove bookmark'
                        : 'Bookmark',
                    icon: Icon(
                      item.bookmarkedByMe
                          ? Icons.bookmark
                          : LucideIcons.bookmark,
                    ),
                    onPressed: () => ref
                        .read(visionProvider.notifier)
                        .setWeeklyBookmark(item, !item.bookmarkedByMe),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _WeeklyPill extends StatelessWidget {
  const _WeeklyPill({required this.icon, required this.label});

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

class _PulsePanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(visionProvider);
    final pulse = state.tribePulse;
    return VisionPanel(
      icon: LucideIcons.activity,
      title: 'Today in your tribe',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.primaryTribe == null)
            const Text(
              'Join a tribe to see daily check-ins and shared returns.',
            )
          else if (pulse.items.isEmpty)
            Text(
              pulse.returnedCount > 0
                  ? '${pulse.returnedCount} people returned today.'
                  : 'Your tribe pulse will appear as people return today.',
            )
          else
            ...pulse.items.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(GrowthJourneyEvent.iconForKey(item.iconKey)),
                title: Text(item.text),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => context.push(AppRoutes.invite),
                icon: const Icon(LucideIcons.send, size: 18),
                label: const Text('Invite'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () =>
                    context.push('${AppRoutes.assessment}/compass'),
                icon: const Icon(LucideIcons.compass, size: 18),
                label: const Text('Retake compass'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({
    required this.mode,
    required this.controller,
    required this.onModeChanged,
    required this.onSave,
  });

  final VisibilityMode mode;
  final TextEditingController controller;
  final ValueChanged<VisibilityMode> onModeChanged;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    return VisionPanel(
      icon: LucideIcons.eye,
      title: 'Visibility',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This is how people in your tribe and commitment feed will know you.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          VisibilityModePicker(value: mode, onChanged: onModeChanged),
          if (mode == VisibilityMode.nickname ||
              mode == VisibilityMode.public) ...[
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
            child: TextButton(onPressed: onSave, child: const Text('Save')),
          ),
        ],
      ),
    );
  }
}
