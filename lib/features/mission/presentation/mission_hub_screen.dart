import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/di/app_providers.dart';
import '../domain/models/mission_focus.dart';
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
                  const SizedBox(height: 20),
                  Text(
                    'Suggested steps',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ..._templatesFor(mission.focus).map(
                    (template) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: MissionTemplateCard(
                        title: template.title,
                        description: template.description,
                        badge: template.badge,
                        onTap: () => notifier.addAction(
                          title: template.title,
                          description: template.description,
                          requiresFollowUp: template.requiresFollowUp,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push(AppRoutes.actOpportunities),
                          icon: const Icon(Icons.search_rounded, size: 18),
                          label: const Text('Opportunities'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showCustomActionSheet(context, ref),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add action'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (mission.pendingActions.isNotEmpty) ...[
                    Text(
                      'In progress',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
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
                    const SizedBox(height: 24),
                  ],
                  if (mission.completedActions.isNotEmpty) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Impact history',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          '${mission.completedActions.length} completed',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (mission.completedActions.length > 4) ...[
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => context.push(AppRoutes.actHistory),
                            child: const Text('View all'),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...mission.completedActions.take(4).map(
                      (action) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: MissionActionCard(
                          action: action,
                          isDark: isDark,
                          onToggle: () => notifier.toggleCompleted(action),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: theme.colorScheme.secondaryContainer.withValues(alpha: isDark ? 0.32 : 0.55),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bring someone in',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          mission.accountabilityPartner == null
                              ? 'Add one trusted person so your next step does not stay private.'
                              : 'Keep ${mission.accountabilityPartner!.name} in the loop on your next step.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                          ),
                        ),
                        const SizedBox(height: 14),
                        FilledButton.tonalIcon(
                          onPressed: () => context.push(AppRoutes.growTogether),
                          icon: const Icon(Icons.people_alt_rounded),
                          label: Text(
                            mission.accountabilityPartner == null
                                ? 'Add partner'
                                : 'Open partner',
                          ),
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
