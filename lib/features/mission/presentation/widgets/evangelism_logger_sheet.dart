import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/app_providers.dart';
import '../../domain/models/kingdom_action_models.dart';

/// Bottom sheet for logging evangelism conversations and follow-ups
class EvangelismLoggerSheet extends ConsumerStatefulWidget {
  const EvangelismLoggerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const EvangelismLoggerSheet(),
    );
  }

  @override
  ConsumerState<EvangelismLoggerSheet> createState() => _EvangelismLoggerSheetState();
}

class _EvangelismLoggerSheetState extends ConsumerState<EvangelismLoggerSheet> {
  final _nameController = TextEditingController();
  final _contextController = TextEditingController();
  final _contentController = TextEditingController();
  final _notesController = TextEditingController();
  final _prayerController = TextEditingController();
  String _selectedMethod = 'in-person';
  String? _selectedResponse;
  bool _showForm = false;
  bool _isSubmitting = false;

  final List<String> _methodOptions = [
    'in-person',
    'phone',
    'text',
    'social-media',
    'email',
  ];

  final Map<String, String> _responseOptions = {
    'receptive': 'Receptive - Interested in learning more',
    'neutral': 'Neutral - Listened but no clear response',
    'resistant': 'Resistant - Not interested at this time',
    'unknown': 'Unknown - Unclear how they received it',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _contextController.dispose();
    _contentController.dispose();
    _notesController.dispose();
    _prayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mission = ref.watch(missionProvider);
    final conversations = mission.evangelismConversations;

    // Get needing follow-up
    final needsFollowUp = ref.read(missionProvider.notifier).evangelismNeedsFollowUp;

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
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.wb_sunny_outlined,
                        color: Colors.orange.shade400,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Faith Sharing Log',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Track conversations and follow-ups',
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
                if (needsFollowUp.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.notifications_active, color: Colors.orange.shade400, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${needsFollowUp.length} conversation${needsFollowUp.length > 1 ? 's' : ''} need follow-up',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Content
          Expanded(
            child: _showForm
                ? _buildAddForm(theme)
                : _buildConversationsList(theme, conversations, needsFollowUp),
          ),

          // Bottom action
          if (!_showForm)
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
                  onPressed: () => setState(() => _showForm = true),
                  icon: const Icon(Icons.add),
                  label: const Text('Log Conversation'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: Colors.orange,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConversationsList(
    ThemeData theme,
    List<EvangelismConversation> conversations,
    List<EvangelismConversation> needsFollowUp,
  ) {
    if (conversations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wb_sunny_outlined,
                size: 64,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No conversations logged yet',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Record faith conversations to track follow-ups and see God\'s work',
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

    // Sort: needs follow-up first, then by date
    final sorted = [...conversations]..sort((a, b) {
      final aNeeds = needsFollowUp.any((c) => c.id == a.id);
      final bNeeds = needsFollowUp.any((c) => c.id == b.id);
      if (aNeeds && !bNeeds) return -1;
      if (!aNeeds && bNeeds) return 1;
      return b.date.compareTo(a.date);
    });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final conversation = sorted[index];
        final needsFollowUpFlag = needsFollowUp.any((c) => c.id == conversation.id);
        return _ConversationCard(
          conversation: conversation,
          needsFollowUp: needsFollowUpFlag,
          onTap: () => _showConversationDetail(conversation),
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
          // Person name
          Text(
            'Person\'s Name',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: 'e.g., Sarah Johnson',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 20),

          // Method
          Text(
            'Method',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _methodOptions.map((method) {
              final isSelected = _selectedMethod == method;
              return ChoiceChip(
                label: Text(_capitalizeFirst(method.replaceAll('-', ' '))),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedMethod = method),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Context
          Text(
            'Context',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _contextController,
            decoration: const InputDecoration(
              hintText: 'How you know them, where conversation happened...',
              prefixIcon: Icon(Icons.place_outlined),
            ),
          ),
          const SizedBox(height: 20),

          // Content shared
          Text(
            'What was shared',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _contentController,
            decoration: const InputDecoration(
              hintText: 'Gospel content, testimony, scripture, invitation...',
              prefixIcon: Icon(Icons.message_outlined),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 20),

          // Response
          Text(
            'Their Response',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ..._responseOptions.entries.map((entry) {
            final isSelected = _selectedResponse == entry.key;
            return RadioListTile<String>(
              title: Text(
                entry.value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : null,
                ),
              ),
              value: entry.key,
              groupValue: _selectedResponse,
              onChanged: (value) => setState(() => _selectedResponse = value),
              contentPadding: EdgeInsets.zero,
              dense: true,
            );
          }),
          const SizedBox(height: 20),

          // Prayer requests
          Text(
            'Prayer Requests (optional)',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _prayerController,
            decoration: const InputDecoration(
              hintText: 'What they asked prayer for...',
              prefixIcon: Icon(Icons.favorite_outline),
            ),
          ),
          const SizedBox(height: 20),

          // Notes
          Text(
            'Additional Notes',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              hintText: 'Next steps, follow-up plan, impressions...',
              prefixIcon: Icon(Icons.notes),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _showForm = false),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submitConversation,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Log Conversation'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Future<void> _submitConversation() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final prayerRequests = _prayerController.text.trim().isNotEmpty
        ? [_prayerController.text.trim()]
        : null;

    await ref.read(missionProvider.notifier).logEvangelismConversation(
      personName: name,
      method: _selectedMethod,
      initialContext: _contextController.text.trim().isNotEmpty
          ? _contextController.text.trim()
          : null,
      contentShared: _contentController.text.trim().isNotEmpty
          ? _contentController.text.trim()
          : null,
      responseType: _selectedResponse,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      prayerRequests: prayerRequests,
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _showForm = false;
        _nameController.clear();
        _contextController.clear();
        _contentController.clear();
        _notesController.clear();
        _prayerController.clear();
        _selectedResponse = null;
      });
    }
  }

  void _showConversationDetail(EvangelismConversation conversation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ConversationDetailSheet(conversation: conversation),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({
    required this.conversation,
    required this.needsFollowUp,
    required this.onTap,
  });

  final EvangelismConversation conversation;
  final bool needsFollowUp;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color statusColor;
    switch (conversation.responseType) {
      case 'receptive':
        statusColor = Colors.green;
      case 'resistant':
        statusColor = Colors.red;
      case 'neutral':
        statusColor = Colors.orange;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: needsFollowUp
              ? Colors.orange.withValues(alpha: 0.5)
              : theme.colorScheme.outline.withValues(alpha: 0.3),
          width: needsFollowUp ? 2 : 1,
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
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.wb_sunny,
                      size: 20,
                      color: Colors.orange.shade400,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          conversation.personName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _capitalizeFirst(conversation.method.replaceAll('-', ' ')),
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
              const SizedBox(height: 12),
              if (conversation.responseType != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _capitalizeFirst(conversation.responseType!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (conversation.contentShared?.isNotEmpty ?? false) ...[
                Text(
                  conversation.contentShared!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM d, yyyy').format(conversation.date),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  if (conversation.followUpDates.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Icon(
                      Icons.repeat,
                      size: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${conversation.followUpDates.length} follow-ups',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

class _ConversationDetailSheet extends ConsumerStatefulWidget {
  const _ConversationDetailSheet({required this.conversation});

  final EvangelismConversation conversation;

  @override
  ConsumerState<_ConversationDetailSheet> createState() => _ConversationDetailSheetState();
}

class _ConversationDetailSheetState extends ConsumerState<_ConversationDetailSheet> {
  final _followUpNoteController = TextEditingController();
  String? _decisionMade;
  bool _isSubmitting = false;

  final Map<String, String> _decisionOptions = {
    'accepted': 'Accepted Christ',
    'considering': 'Still Considering',
    'not-ready': 'Not Ready',
    'declined': 'Not Interested',
  };

  @override
  void dispose() {
    _followUpNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final conversation = widget.conversation;

    Color responseColor;
    switch (conversation.responseType) {
      case 'receptive':
        responseColor = Colors.green;
      case 'resistant':
        responseColor = Colors.red;
      case 'neutral':
        responseColor = Colors.orange;
      default:
        responseColor = Colors.grey;
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
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
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.wb_sunny,
                    color: Colors.orange.shade400,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conversation.personName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        conversation.isOngoing ? 'Ongoing' : 'Concluded',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: conversation.isOngoing
                              ? Colors.orange
                              : theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
                // Original conversation
                _buildSection(
                  'Original Conversation',
                  DateFormat('MMMM d, yyyy').format(conversation.date),
                  Icons.calendar_today,
                  theme,
                ),
                const SizedBox(height: 16),

                if (conversation.initialContext?.isNotEmpty ?? false) ...[
                  _buildDetailRow('Context', conversation.initialContext!, theme),
                  const SizedBox(height: 12),
                ],
                if (conversation.contentShared?.isNotEmpty ?? false) ...[
                  _buildDetailRow('Content Shared', conversation.contentShared!, theme),
                  const SizedBox(height: 12),
                ],
                if (conversation.responseType != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: responseColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: responseColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.emoji_emotions, color: responseColor, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Response: ${_capitalizeFirst(conversation.responseType!)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: responseColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Follow-up history
                if (conversation.followUpDates.isNotEmpty) ...[
                  Text(
                    'Follow-ups',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...conversation.followUpDates.map((date) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Colors.green.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('MMMM d, yyyy').format(date),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 20),
                ],

                // Decision
                if (conversation.decisionMade != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Decision Made',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _decisionOptions[conversation.decisionMade] ?? conversation.decisionMade!,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (conversation.decisionDate != null)
                          Text(
                            DateFormat('MMMM d, yyyy').format(conversation.decisionDate!),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Prayer requests
                if (conversation.prayerRequests?.isNotEmpty ?? false) ...[
                  Text(
                    'Prayer Requests',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...conversation.prayerRequests!.map((prayer) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.favorite,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(prayer)),
                      ],
                    ),
                  )),
                  const SizedBox(height: 20),
                ],

                // Notes
                if (conversation.notes?.isNotEmpty ?? false) ...[
                  _buildDetailRow('Notes', conversation.notes!, theme),
                  const SizedBox(height: 20),
                ],

                // Add follow-up section
                if (conversation.isOngoing) ...[
                  const Divider(),
                  const SizedBox(height: 20),
                  Text(
                    'Record Follow-up',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _followUpNoteController,
                    decoration: const InputDecoration(
                      hintText: 'What happened in follow-up? New prayer requests, progress...',
                      prefixIcon: Icon(Icons.note_add_outlined),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Decision (if any)',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _decisionOptions.entries.map((entry) {
                      final isSelected = _decisionMade == entry.key;
                      return ChoiceChip(
                        label: Text(entry.value),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _decisionMade = entry.key),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),

          // Actions
          if (conversation.isOngoing)
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
                      child: OutlinedButton(
                        onPressed: () => _concludeWithoutDecision(),
                        child: const Text('Conclude'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: _isSubmitting ? null : _recordFollowUp,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Record Follow-up'),
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
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              Text(
                content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Future<void> _recordFollowUp() async {
    setState(() => _isSubmitting = true);

    await ref.read(missionProvider.notifier).recordEvangelismFollowUp(
      conversationId: widget.conversation.id,
      notes: _followUpNoteController.text.trim().isNotEmpty
          ? _followUpNoteController.text.trim()
          : null,
      decisionMade: _decisionMade,
    );

    if (mounted) Navigator.pop(context);
  }

  Future<void> _concludeWithoutDecision() async {
    setState(() => _isSubmitting = true);

    await ref.read(missionProvider.notifier).recordEvangelismFollowUp(
      conversationId: widget.conversation.id,
      notes: 'Conversation concluded',
    );

    if (mounted) Navigator.pop(context);
  }
}
