import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/app_providers.dart';
import '../../domain/models/kingdom_action_models.dart';

/// Bottom sheet for managing person commitments - specific people the user is helping
class PersonCommitmentSheet extends ConsumerStatefulWidget {
  const PersonCommitmentSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PersonCommitmentSheet(),
    );
  }

  @override
  ConsumerState<PersonCommitmentSheet> createState() => _PersonCommitmentSheetState();
}

class _PersonCommitmentSheetState extends ConsumerState<PersonCommitmentSheet> {
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  final _needsController = TextEditingController();
  String _selectedRelationship = 'Friend';
  final List<String> _selectedTags = [];
  bool _isAddingNew = false;
  bool _isSubmitting = false;

  final List<String> _relationshipOptions = [
    'Family',
    'Friend',
    'Coworker',
    'Neighbor',
    'Stranger',
    'Church Member',
    'Mentee',
    'Other',
  ];

  final List<String> _tagOptions = [
    'elderly',
    'job-seeking',
    'spiritual-curious',
    'sick',
    'lonely',
    'new-believer',
    'financial-need',
    'grieving',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _needsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mission = ref.watch(missionProvider);
    final commitments = mission.personCommitments.where((c) => c.isActive).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.people_outline_rounded,
                    color: Colors.purple.shade400,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'People You\'re Helping',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Track specific commitments to individuals',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isAddingNew
                ? _buildAddForm(theme)
                : _buildCommitmentsList(theme, commitments),
          ),

          // Bottom action
          if (!_isAddingNew)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: SafeArea(
                child: FilledButton.icon(
                  onPressed: () => setState(() => _isAddingNew = true),
                  icon: const Icon(Icons.add),
                  label: const Text('Commit to Help Someone'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCommitmentsList(ThemeData theme, List<PersonCommitment> commitments) {
    if (commitments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline_rounded,
                size: 64,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No active commitments yet',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Commit to helping specific people and track your follow-through',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: commitments.length,
      itemBuilder: (context, index) {
        final commitment = commitments[index];
        return _CommitmentCard(
          commitment: commitment,
          onTap: () => _showCommitmentDetails(commitment),
        );
      },
    );
  }

  Widget _buildAddForm(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name
          Text(
            'Their Name',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: 'e.g., John Smith',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 20),

          // Relationship
          Text(
            'Relationship',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _relationshipOptions.map((relationship) {
              final isSelected = _selectedRelationship == relationship;
              return ChoiceChip(
                label: Text(relationship),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedRelationship = relationship),
                selectedColor: Colors.purple.withValues(alpha: 0.2),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Needs
          Text(
            'What do they need?',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _needsController,
            decoration: const InputDecoration(
              hintText: 'e.g., Job search help, prayer, friendship...',
              prefixIcon: Icon(Icons.help_outline),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 20),

          // Tags
          Text(
            'Tags (optional)',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tagOptions.map((tag) {
              final isSelected = _selectedTags.contains(tag);
              return FilterChip(
                label: Text(tag),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTags.add(tag);
                    } else {
                      _selectedTags.remove(tag);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Notes
          Text(
            'Notes (optional)',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              hintText: 'How you met, context, prayer requests...',
              prefixIcon: Icon(Icons.notes),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _isAddingNew = false),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submitCommitment,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create Commitment'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submitCommitment() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    await ref.read(missionProvider.notifier).createPersonCommitment(
      name: name,
      relationship: _selectedRelationship,
      needs: _needsController.text.trim().isNotEmpty ? _needsController.text.trim() : null,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      tags: _selectedTags,
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _isAddingNew = false;
        _nameController.clear();
        _notesController.clear();
        _needsController.clear();
        _selectedTags.clear();
      });
    }
  }

  void _showCommitmentDetails(PersonCommitment commitment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CommitmentDetailSheet(commitment: commitment),
    );
  }
}

class _CommitmentCard extends StatelessWidget {
  const _CommitmentCard({
    required this.commitment,
    required this.onTap,
  });

  final PersonCommitment commitment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final needsFollowUp = commitment.needsFollowUp;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.person,
                      size: 20,
                      color: Colors.purple.shade400,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          commitment.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          commitment.relationship,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (needsFollowUp)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Follow-up',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              if (commitment.needs?.isNotEmpty ?? false) ...[
                const SizedBox(height: 12),
                Text(
                  'Needs: ${commitment.needs}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatChip(
                    Icons.check_circle_outline,
                    '${commitment.committedActions.length} actions',
                    theme,
                  ),
                  const SizedBox(width: 8),
                  if (commitment.tags.isNotEmpty)
                    _buildStatChip(
                      Icons.label_outline,
                      '${commitment.tags.length} tags',
                      theme,
                    ),
                  const Spacer(),
                  if (commitment.lastContactAt != null)
                    Text(
                      'Last contact: ${DateFormat('MMM d').format(commitment.lastContactAt!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommitmentDetailSheet extends ConsumerStatefulWidget {
  const _CommitmentDetailSheet({required this.commitment});

  final PersonCommitment commitment;

  @override
  ConsumerState<_CommitmentDetailSheet> createState() => _CommitmentDetailSheetState();
}

class _CommitmentDetailSheetState extends ConsumerState<_CommitmentDetailSheet> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final commitment = widget.commitment;

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.person,
                    color: Colors.purple.shade400,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        commitment.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${commitment.relationship} • ${commitment.committedActions.length} actions',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (commitment.needs?.isNotEmpty ?? false) ...[
                  _buildSection(
                    'Needs',
                    commitment.needs!,
                    Icons.help_outline,
                    theme,
                  ),
                  const SizedBox(height: 20),
                ],
                if (commitment.notes?.isNotEmpty ?? false) ...[
                  _buildSection(
                    'Notes',
                    commitment.notes!,
                    Icons.notes,
                    theme,
                  ),
                  const SizedBox(height: 20),
                ],
                if (commitment.tags.isNotEmpty) ...[
                  Text(
                    'Tags',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: commitment.tags.map((tag) => Chip(
                      label: Text(tag),
                      backgroundColor: Colors.purple.withValues(alpha: 0.1),
                    )).toList(),
                  ),
                  const SizedBox(height: 20),
                ],
                _buildInfoRow(
                  'Created',
                  DateFormat('MMMM d, yyyy').format(commitment.createdAt),
                  theme,
                ),
                if (commitment.lastContactAt != null)
                  _buildInfoRow(
                    'Last Contact',
                    DateFormat('MMMM d, yyyy').format(commitment.lastContactAt!),
                    theme,
                  ),
                if (commitment.nextFollowUpAt != null)
                  _buildInfoRow(
                    'Next Follow-up',
                    DateFormat('MMMM d, yyyy').format(commitment.nextFollowUpAt!),
                    theme,
                    isHighlight: true,
                  ),
              ],
            ),
          ),

          // Actions
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _archiveCommitment(),
                      icon: const Icon(Icons.archive_outlined),
                      label: const Text('Archive'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: () => _markContacted(),
                      icon: const Icon(Icons.check),
                      label: const Text('Mark Contacted'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content, IconData icon, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            content,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, ThemeData theme, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isHighlight ? FontWeight.w600 : null,
              color: isHighlight ? theme.colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markContacted() async {
    await ref.read(missionProvider.notifier).updatePersonCommitment(
      widget.commitment.id,
      lastContactAt: DateTime.now(),
    );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _archiveCommitment() async {
    await ref.read(missionProvider.notifier).updatePersonCommitment(
      widget.commitment.id,
      isActive: false,
    );
    if (mounted) Navigator.pop(context);
  }
}
