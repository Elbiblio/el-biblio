import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../../application/mission_state.dart';
import '../../domain/models/mission_action.dart';
import '../../domain/models/mission_focus.dart';

class MissionHeroCard extends StatelessWidget {
  const MissionHeroCard({
    super.key,
    required this.mission,
  });

  final MissionState mission;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final partner = mission.accountabilityPartner;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.15),
            theme.colorScheme.primary.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your current kingdom focus',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            mission.focus.label,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            mission.focus.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricPill(
                label: 'Pending',
                value: '${mission.pendingActions.length}',
              ),
              _MetricPill(
                label: 'Completed',
                value: '${mission.completedActions.length}',
              ),
              _MetricPill(
                label: 'Partner',
                value: partner == null ? 'Not set' : partner.name,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MissionTemplateCard extends StatelessWidget {
  const MissionTemplateCard({
    super.key,
    required this.title,
    required this.description,
    required this.badge,
    required this.onTap,
  });

  final String title;
  final String description;
  final String badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          ),
                          child: Text(
                            badge,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.45,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.add_circle_outline_rounded,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MissionActionCard extends ConsumerWidget {
  const MissionActionCard({
    super.key,
    required this.action,
    required this.isDark,
    required this.onToggle,
  });

  final MissionAction action;
  final bool isDark;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final formatter = DateFormat('MMM d');
    final missionNotifier = ref.read(missionProvider.notifier);
    final profiles = ref.watch(settingsProvider).personProfiles;
    final matchingProfiles = profiles.where((profile) => profile.name == action.personName);
    final personProfile = matchingProfiles.isEmpty ? null : matchingProfiles.first;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: action.isCompleted
            ? Colors.green.withValues(alpha: isDark ? 0.14 : 0.08)
            : theme.colorScheme.surface,
        border: Border.all(
          color: action.isCompleted
              ? Colors.green.withValues(alpha: 0.25)
              : theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: onToggle,
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    action.isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: action.isCompleted
                        ? Colors.green.shade600
                        : theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        decoration: action.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      action.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.45,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _TagChip(
                          label: action.focus.label,
                          color: theme.colorScheme.primary,
                        ),
                        _TagChip(
                          label: action.isCompleted
                              ? 'Completed ${formatter.format(action.completedAt ?? action.createdAt)}'
                              : 'Added ${formatter.format(action.createdAt)}',
                          color: Colors.blueGrey,
                        ),
                        if ((action.personName ?? '').isNotEmpty)
                          _TagChip(
                            label: action.personName!,
                            color: Colors.teal,
                            onTap: personProfile == null
                                ? null
                                : () => context.push(
                                      '${AppRoutes.actPeople}/${personProfile.id}',
                                    ),
                          ),
                        if (action.requiresFollowUp)
                          _TagChip(
                            label: action.followUpCompletedAt != null
                                ? 'Follow-up done'
                                : 'Follow-up',
                            color: action.followUpCompletedAt != null
                                ? Colors.green
                                : Colors.orange,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (action.isCompleted && action.requiresFollowUp && action.followUpCompletedAt == null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showFollowUpDialog(context, missionNotifier),
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Mark follow-up complete'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showFollowUpDialog(BuildContext context, dynamic missionNotifier) {
    final noteController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log follow-up'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How did the follow-up with ${action.personName ?? 'this person'} go?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'What happened during the follow-up?',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await missionNotifier.completeFollowUp(
                action,
                notes: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
              );
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }
}

class MissionTemplate {
  const MissionTemplate({
    required this.title,
    required this.description,
    required this.badge,
    this.requiresFollowUp = false,
  });

  final String title;
  final String description;
  final String badge;
  final bool requiresFollowUp;
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: theme.colorScheme.surface.withValues(alpha: 0.72),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.color,
    this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: color.withValues(alpha: 0.1),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
        ),
      ),
    );
  }
}
