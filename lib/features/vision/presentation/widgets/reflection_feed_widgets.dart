import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/di/app_providers.dart';
import '../../domain/vision_models.dart';
import 'vision_panel.dart';

class VisionReflectionComposer extends ConsumerWidget {
  const VisionReflectionComposer({
    super.key,
    required this.controller,
    this.showCheckInButton = true,
  });

  final TextEditingController controller;
  final bool showCheckInButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(visionProvider);
    final active = state.activeCommitment;
    if (active == null) return const SizedBox.shrink();

    if (!active.checkedInToday) {
      return VisionPanel(
        icon: LucideIcons.checkCircle,
        title: 'Check in today first',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You can read the feed now. Share after you complete today.',
            ),
            if (showCheckInButton) ...[
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
                label: const Text('Check in for today'),
              ),
            ],
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
            'Visible only to this commitment as ${state.visibilityAlias}. Keep it honest, brief, and human.',
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
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, child) {
              final canPost = value.text.trim().isNotEmpty;
              return FilledButton.icon(
                onPressed: canPost
                    ? () async {
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
                      }
                    : null,
                icon: const Icon(LucideIcons.send, size: 18),
                label: const Text('Post reflection'),
              );
            },
          ),
        ],
      ),
    );
  }
}

class VisionReflectionFeed extends ConsumerWidget {
  const VisionReflectionFeed({
    super.key,
    this.title = 'Commitment reflections',
    this.pinnedIds = const {},
    this.onTogglePinned,
  });

  final String title;
  final Set<int> pinnedIds;
  final ValueChanged<CommitmentReflection>? onTogglePinned;

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

    final ordered = [...feed]
      ..sort((a, b) {
        final aPinned = pinnedIds.contains(a.id);
        final bPinned = pinnedIds.contains(b.id);
        if (aPinned != bPinned) return aPinned ? -1 : 1;
        return 0;
      });

    return VisionPanel(
      icon: LucideIcons.messagesSquare,
      title: title,
      trailing: pinnedIds.isEmpty
          ? null
          : Text('${pinnedIds.length} pinned for now'),
      child: Column(
        children: ordered
            .map(
              (item) => VisionReflectionCard(
                item: item,
                isPinned: pinnedIds.contains(item.id),
                onTogglePinned: onTogglePinned == null
                    ? null
                    : () => onTogglePinned!(item),
              ),
            )
            .toList(),
      ),
    );
  }
}

class VisionReflectionCard extends ConsumerWidget {
  const VisionReflectionCard({
    super.key,
    required this.item,
    this.isPinned = false,
    this.onTogglePinned,
  });

  final CommitmentReflection item;
  final bool isPinned;
  final VoidCallback? onTogglePinned;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPinned
              ? theme.colorScheme.primary.withValues(alpha: 0.34)
              : theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => _showVisibleProfile(context, item),
                child: Tooltip(
                  message: 'View visible profile',
                  child: CircleAvatar(
                    radius: 16,
                    child: Text(
                      item.alias.isEmpty ? '?' : item.alias[0].toUpperCase(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.alias,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (onTogglePinned != null)
                IconButton(
                  tooltip: isPinned ? 'Unpin for now' : 'Pin for now',
                  icon: Icon(
                    isPinned ? Icons.push_pin : LucideIcons.pin,
                    size: 20,
                  ),
                  onPressed: onTogglePinned,
                ),
              if (item.reactionCount > 0)
                Text(
                  '${item.reactionCount}',
                  style: theme.textTheme.labelMedium,
                ),
              IconButton(
                tooltip: item.supportedByMe ? 'Remove support' : 'Support',
                color: item.supportedByMe ? theme.colorScheme.primary : null,
                icon: Icon(
                  item.supportedByMe
                      ? Icons.favorite
                      : LucideIcons.heartHandshake,
                ),
                onPressed: () async {
                  final reacted = await ref
                      .read(visionProvider.notifier)
                      .reactToReflection(item, 'support');
                  if (!context.mounted || reacted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'We could not update support. Please try again.',
                      ),
                    ),
                  );
                },
              ),
              PopupMenuButton<String>(
                tooltip: 'Reflection actions',
                icon: const Icon(LucideIcons.moreHorizontal),
                onSelected: (reason) => _reportReflection(context, ref, reason),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'unsafe_or_crisis',
                    child: Text('Report safety concern'),
                  ),
                  PopupMenuItem(
                    value: 'shaming_or_harmful',
                    child: Text('Report harmful response'),
                  ),
                  PopupMenuItem(
                    value: 'spam_or_misuse',
                    child: Text('Report spam or misuse'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.content,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }

  void _showVisibleProfile(BuildContext context, CommitmentReflection item) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => _VisibleProfileSheet(item: item),
    );
  }

  Future<void> _reportReflection(
    BuildContext context,
    WidgetRef ref,
    String reason,
  ) async {
    final reported = await ref
        .read(visionProvider.notifier)
        .reportReflection(item, reason);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          reported
              ? 'Thanks. We will review this reflection.'
              : 'We could not send the report. Please try again.',
        ),
      ),
    );
  }
}

class _VisibleProfileSheet extends StatelessWidget {
  const _VisibleProfileSheet({required this.item});

  final CommitmentReflection item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                child: Text(
                  item.alias.isEmpty ? '?' : item.alias[0].toUpperCase(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.alias,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ProfileMetric(
                icon: LucideIcons.calendarDays,
                label: _memberSinceLabel(item.authorMemberSince),
              ),
              _ProfileMetric(
                icon: LucideIcons.users,
                label: item.authorTribeDisplayName,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileMetric extends StatelessWidget {
  const _ProfileMetric({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 7),
          Text(label, style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}

String _memberSinceLabel(DateTime? joinedAt) {
  if (joinedAt == null) return 'New here';
  final days = DateTime.now().difference(joinedAt).inDays + 1;
  if (days <= 1) return 'Joined today';
  if (days < 60) return '$days days here';
  final months = (days / 30).floor();
  if (months < 12) return '$months months here';
  final years = (days / 365).floor();
  return '$years years here';
}
