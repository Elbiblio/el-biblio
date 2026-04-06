import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/app_providers.dart';
import '../widgets/mission_hub_sections.dart';

class PersonProfileScreen extends ConsumerStatefulWidget {
  const PersonProfileScreen({
    super.key,
    required this.personId,
  });

  final String personId;

  @override
  ConsumerState<PersonProfileScreen> createState() => _PersonProfileScreenState();
}

class _PersonProfileScreenState extends ConsumerState<PersonProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final mission = ref.watch(missionProvider);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final matchingProfiles = settings.personProfiles.where(
      (profile) => profile.id == widget.personId,
    );
    final profile = matchingProfiles.isEmpty ? null : matchingProfiles.first;

    if (profile == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Person Profile'),
        ),
        body: Center(
          child: Text(
            'This person could not be found.',
            style: theme.textTheme.bodyLarge,
          ),
        ),
      );
    }

    // Filter actions for this person
    final personActions = mission.actions
        .where((action) => action.personName == profile.name)
        .toList()
      ..sort((a, b) => (b.completedAt ?? b.createdAt).compareTo(a.completedAt ?? a.createdAt));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Person Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => _showEditDialog(context, ref, profile),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Person info card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primary.withValues(alpha: 0.15),
                          theme.colorScheme.primary.withValues(alpha: 0.05),
                        ],
                      ),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.person_rounded,
                          color: theme.colorScheme.primary,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          profile.name,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getRelationship(mission),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        if ((profile.contactInfo ?? '').isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            profile.contactInfo!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                        if ((profile.notes ?? '').isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            profile.notes!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        _StatRow(
                          label: 'Total actions',
                          value: '${personActions.length}',
                          icon: Icons.task_alt_rounded,
                        ),
                        const SizedBox(height: 8),
                        _StatRow(
                          label: 'Completed',
                          value: '${personActions.where((a) => a.isCompleted).length}',
                          icon: Icons.check_circle_rounded,
                        ),
                        const SizedBox(height: 8),
                        _StatRow(
                          label: 'Follow-ups done',
                          value: '${personActions.where((a) => a.followUpCompletedAt != null).length}',
                          icon: Icons.handshake_rounded,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Actions with this person',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          if (personActions.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_off_rounded,
                      size: 64,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No actions yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => _showAddActionDialog(context, ref),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add first action'),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final action = personActions[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: MissionActionCard(
                        action: action,
                        isDark: isDark,
                        onToggle: () {
                          ref.read(missionProvider.notifier).toggleCompleted(action);
                        },
                      ),
                    );
                  },
                  childCount: personActions.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
      floatingActionButton: personActions.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showAddActionDialog(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add action'),
            )
          : null,
    );
  }

  String _getPersonName(dynamic mission) {
    // In a real implementation, this would fetch the PersonProfile
    // For now, we'll use a placeholder
    final settings = ref.read(settingsProvider);
    final matchingProfiles = settings.personProfiles.where(
      (profile) => profile.id == widget.personId,
    );
    return matchingProfiles.isEmpty ? 'Person' : matchingProfiles.first.name;
  }

  String _getRelationship(dynamic mission) {
    // In a real implementation, this would fetch from PersonProfile
    final settings = ref.read(settingsProvider);
    final matchingProfiles = settings.personProfiles.where(
      (profile) => profile.id == widget.personId,
    );
    return matchingProfiles.isEmpty ? 'Friend' : matchingProfiles.first.relationship;
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, dynamic profile) {
    // In a real implementation, this would open an edit dialog
    final nameController = TextEditingController(text: profile.name as String? ?? '');
    final relationshipController = TextEditingController(text: profile.relationship as String? ?? '');
    final contactController = TextEditingController(text: profile.contactInfo as String? ?? '');
    final notesController = TextEditingController(text: profile.notes as String? ?? '');

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit person details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: relationshipController,
                decoration: const InputDecoration(labelText: 'Relationship'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contactController,
                decoration: const InputDecoration(labelText: 'Contact info'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(missionProvider.notifier).savePersonProfile(
                    profileId: profile.id as String?,
                    name: nameController.text,
                    relationship: relationshipController.text,
                    contactInfo: contactController.text,
                    notes: notesController.text,
                  );
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddActionDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add action for this person'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'What do you want to do?',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Add more details...',
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
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                ref.read(missionProvider.notifier).addAction(
                      title: titleController.text.trim(),
                      description: descriptionController.text.trim(),
                      personName: _getPersonName(ref.read(missionProvider)),
                    );
                Navigator.of(context).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
