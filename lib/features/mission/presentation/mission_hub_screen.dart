import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/di/app_providers.dart';
import '../domain/models/mission_focus.dart';
import 'widgets/accountability_check_in_sheet.dart';
import 'widgets/mission_hub_sections.dart';

class MissionHubScreen extends ConsumerWidget {
  const MissionHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mission = ref.watch(missionProvider);
    final notifier = ref.read(missionProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Act'),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  MissionHeroCard(mission: mission),
                  const SizedBox(height: 20),
                  Text(
                    'Choose a focus',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: MissionFocusType.values.map((focus) {
                      final isSelected = mission.focus == focus;
                      return ChoiceChip(
                        label: Text(focus.label),
                        selected: isSelected,
                        onSelected: (_) => notifier.setFocus(focus),
                        selectedColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                        labelStyle: TextStyle(
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withValues(alpha: 0.75),
                        ),
                      );
                    }).toList(),
                  ),
                  // Focus description — contextualizes what this focus means
                  const SizedBox(height: 8),
                  Text(
                    mission.focus.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text(
                        'Suggested Actions',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tap to add to today',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ..._templatesFor(mission.focus).map(
                    (template) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: MissionTemplateCard(
                        title: template.title,
                        description: template.description,
                        badge: template.badge,
                        onTap: () {
                          notifier.addAction(
                            title: template.title,
                            description: template.description,
                            requiresFollowUp: template.requiresFollowUp,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Action added to your list'),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _showCustomActionSheet(context, ref),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Create Your Own'),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // All actions: pending first, then completed
                  if (mission.pendingActions.isNotEmpty || mission.completedActions.isNotEmpty) ...[
                    Row(
                      children: [
                        Text(
                          'Today\'s Actions',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (mission.pendingActions.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${mission.pendingActions.length}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...mission.pendingActions.map(
                      (action) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: MissionActionCard(
                          action: action,
                          isDark: isDark,
                          onToggle: () => notifier.toggleCompleted(action),
                        ),
                      ),
                    ),
                    ...mission.completedActions.take(4).map(
                      (action) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Opacity(
                          opacity: 0.6,
                          child: MissionActionCard(
                            action: action,
                            isDark: isDark,
                            onToggle: () => notifier.toggleCompleted(action),
                          ),
                        ),
                      ),
                    ),
                    if (mission.completedActions.length > 4)
                      Center(
                        child: TextButton(
                          onPressed: () => context.push(AppRoutes.actHistory),
                          child: Text('View all ${mission.completedActions.length} completed'),
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],

                  // Impact summary
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: theme.colorScheme.primaryContainer.withValues(alpha: isDark ? 0.2 : 0.3),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _ImpactStat(
                          value: '${mission.completedActions.length}',
                          label: 'Done',
                          icon: Icons.check_circle_outline_rounded,
                          color: theme.colorScheme.primary,
                        ),
                        _ImpactStat(
                          value: '${mission.pendingActions.length}',
                          label: 'Active',
                          icon: Icons.pending_actions_rounded,
                          color: theme.colorScheme.secondary,
                        ),
                        _ImpactStat(
                          value: '${mission.pendingActions.where((a) => a.requiresFollowUp).length}',
                          label: 'Follow-up',
                          icon: Icons.schedule_rounded,
                          color: theme.colorScheme.tertiary,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Accountability partner
                  if (mission.accountabilityPartner != null)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: theme.colorScheme.secondaryContainer.withValues(alpha: isDark ? 0.32 : 0.55),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.people_alt_rounded, color: theme.colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Walking with ${mission.accountabilityPartner!.name}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                AccountabilityCheckInSheet.show(context),
                            child: const Text('Check in'),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 120),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCustomActionSheet(BuildContext context, WidgetRef ref) async {
    final titleController = TextEditingController();
    final personController = TextEditingController();
    final noteController = TextEditingController();
    var requiresFollowUp = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create a custom step',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Action title',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: personController,
                    decoration: const InputDecoration(
                      labelText: 'Person involved',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: requiresFollowUp,
                    title: const Text('Needs follow-up'),
                    onChanged: (value) => setModalState(() => requiresFollowUp = value),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        final title = titleController.text.trim();
                        final notes = noteController.text.trim();
                        if (title.isEmpty) {
                          return;
                        }

                        await ref.read(missionProvider.notifier).addAction(
                              title: title,
                              description: notes.isEmpty
                                  ? 'A custom kingdom step you committed to complete.'
                                  : notes,
                              personName: personController.text.trim().isEmpty
                                  ? null
                                  : personController.text.trim(),
                              notes: notes.isEmpty ? null : notes,
                              requiresFollowUp: requiresFollowUp,
                            );
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text('Save step'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<MissionTemplate> _templatesFor(MissionFocusType focus) {
    return switch (focus) {
      MissionFocusType.service => const [
          MissionTemplate(
            title: 'Serve someone in a practical way',
            description: 'Choose one concrete act of service today and complete it before the day ends.',
            badge: 'Today',
          ),
          MissionTemplate(
            title: 'Check on someone carrying a burden',
            description: 'Call, text, or visit one person who may need support and ask how you can help.',
            badge: 'Relational',
            requiresFollowUp: true,
          ),
          MissionTemplate(
            title: 'Volunteer one hour this week',
            description: 'Commit one hour to a church, ministry, or local need where you can show up faithfully.',
            badge: 'This week',
          ),
        ],
      MissionFocusType.faithSharing => const [
          MissionTemplate(
            title: 'Start one spiritual conversation',
            description: 'Ask one intentional question that opens the door to faith, prayer, or hope.',
            badge: 'Courage',
          ),
          MissionTemplate(
            title: 'Follow up with someone after a faith conversation',
            description: 'Reach back out, answer a question, or offer prayer so the conversation keeps moving.',
            badge: 'Follow-up',
            requiresFollowUp: true,
          ),
          MissionTemplate(
            title: 'Invite someone to church, prayer, or Scripture',
            description: 'Extend one concrete invitation that helps someone take a next step toward God.',
            badge: 'Invite',
            requiresFollowUp: true,
          ),
        ],
      MissionFocusType.encouragement => const [
          MissionTemplate(
            title: 'Send one intentional encouragement',
            description: 'Speak life to one person with a message, call, voice note, or prayer.',
            badge: 'Care',
          ),
          MissionTemplate(
            title: 'Pray with someone live',
            description: 'Do not say you will pray later. Pray with someone in the moment if possible.',
            badge: 'Prayer',
          ),
          MissionTemplate(
            title: 'Write a reflection for someone you want to strengthen',
            description: 'Share a short testimony, verse, or note that reminds them God sees them.',
            badge: 'Reflect',
          ),
        ],
    };
  }
}

class _ImpactStat extends StatelessWidget {
  const _ImpactStat({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
