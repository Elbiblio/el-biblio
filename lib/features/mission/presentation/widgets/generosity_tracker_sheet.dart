import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/app_providers.dart';
import '../../domain/models/kingdom_action_models.dart';

/// Bottom sheet for recording generosity/mercy actions
class GenerosityTrackerSheet extends ConsumerStatefulWidget {
  const GenerosityTrackerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const GenerosityTrackerSheet(),
    );
  }

  @override
  ConsumerState<GenerosityTrackerSheet> createState() =>
      _GenerosityTrackerSheetState();
}

class _GenerosityTrackerSheetState
    extends ConsumerState<GenerosityTrackerSheet> {
  GenerosityType _selectedType = GenerosityType.financial;
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _recipientController = TextEditingController();
  final _impactController = TextEditingController();
  String? _selectedCategory;
  bool _isRecurring = false;
  String? _recurringFrequency;
  bool _isSubmitting = false;
  bool _showForm = false;

  final List<String> _categoryOptions = [
    'tithe',
    'offering',
    'mercy',
    'missions',
    'community',
    'pastoral care',
  ];

  final List<String> _recurringOptions = ['weekly', 'monthly', 'quarterly'];

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _recipientController.dispose();
    _impactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mission = ref.watch(missionProvider);
    final records = mission.generosityRecords;

    // Calculate stats
    final stats = _calculateStats(records);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header with stats
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
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.favorite_outline,
                        color: Colors.green.shade400,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Generosity Tracker',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Record giving, time, and resources shared',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
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
                const SizedBox(height: 16),
                // Stats row
                Row(
                  children: [
                    Expanded(
                      child: _StatPill(
                        label: 'Financial',
                        value:
                            '\$${stats['financial']?.toStringAsFixed(0) ?? '0'}',
                        icon: Icons.attach_money,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatPill(
                        label: 'Hours',
                        value: stats['time']?.toStringAsFixed(0) ?? '0',
                        icon: Icons.schedule,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatPill(
                        label: 'Resources',
                        value: '${stats['resource']?.toInt() ?? 0}',
                        icon: Icons.card_giftcard,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _showForm
                ? _buildAddForm(theme)
                : _buildRecordsList(theme, records),
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
                  label: const Text('Record Generosity'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: Colors.green,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Map<String, double> _calculateStats(List<GenerosityRecord> records) {
    var financial = 0.0;
    var time = 0.0;
    var resource = 0.0;

    for (final record in records) {
      switch (record.type) {
        case GenerosityType.financial:
          financial += record.amount ?? 0;
        case GenerosityType.time:
          // Parse hours from description or use amount field
          time += record.amount ?? 1;
        case GenerosityType.resource:
          resource += 1;
      }
    }

    return {'financial': financial, 'time': time, 'resource': resource};
  }

  Widget _buildRecordsList(ThemeData theme, List<GenerosityRecord> records) {
    if (records.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_outline,
                size: 64,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No generosity recorded yet',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Track your giving, time donated, and resources shared',
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

    // Sort by date descending
    final sorted = [...records]..sort((a, b) => b.date.compareTo(a.date));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final record = sorted[index];
        return _GenerosityRecordCard(record: record);
      },
    );
  }

  Widget _buildAddForm(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type selector
          Text(
            'Type of Generosity',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<GenerosityType>(
            segments: GenerosityType.values.map((type) {
              return ButtonSegment(
                value: type,
                label: Text(type.label),
                icon: Icon(_getTypeIcon(type)),
              );
            }).toList(),
            selected: {_selectedType},
            onSelectionChanged: (selected) {
              setState(() => _selectedType = selected.first);
            },
          ),
          const SizedBox(height: 20),

          // Amount (for financial) or Hours (for time)
          if (_selectedType == GenerosityType.financial) ...[
            Text(
              'Amount',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: '0.00',
                prefixIcon: Icon(Icons.attach_money),
                prefixText: '\$ ',
              ),
            ),
            const SizedBox(height: 20),
          ] else if (_selectedType == GenerosityType.time) ...[
            Text(
              'Hours Given',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: '1.5',
                prefixIcon: Icon(Icons.schedule),
                suffixText: 'hours',
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Description
          Text(
            'Description',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              hintText: _getDescriptionHint(),
              prefixIcon: const Icon(Icons.description_outlined),
            ),
          ),
          const SizedBox(height: 20),

          // Recipient
          Text(
            'Recipient',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _recipientController,
            decoration: const InputDecoration(
              hintText: 'e.g., Church, Friend, Charity...',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 20),

          // Category
          Text(
            'Category',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categoryOptions.map((category) {
              final isSelected = _selectedCategory == category;
              return ChoiceChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedCategory = category),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Recurring option
          CheckboxListTile(
            value: _isRecurring,
            onChanged: (value) => setState(() => _isRecurring = value ?? false),
            title: const Text('This is a recurring gift'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          if (_isRecurring) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recurringOptions.map((freq) {
                final isSelected = _recurringFrequency == freq;
                return ChoiceChip(
                  label: Text(freq),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _recurringFrequency = freq),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],

          // Impact description
          Text(
            'Impact (optional)',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _impactController,
            decoration: const InputDecoration(
              hintText: 'What happened as a result? How were they helped?',
              prefixIcon: Icon(Icons.emoji_emotions_outlined),
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
                  onPressed: _isSubmitting ? null : _submitRecord,
                  style: FilledButton.styleFrom(backgroundColor: Colors.green),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Record Generosity'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getDescriptionHint() {
    switch (_selectedType) {
      case GenerosityType.financial:
        return 'e.g., Monthly tithe, Offering, Donation...';
      case GenerosityType.time:
        return 'e.g., Volunteered at food bank, Visited elderly...';
      case GenerosityType.resource:
        return 'e.g., Lent car, Gave clothes, Shared tools...';
    }
  }

  IconData _getTypeIcon(GenerosityType type) {
    switch (type) {
      case GenerosityType.financial:
        return Icons.attach_money;
      case GenerosityType.time:
        return Icons.schedule;
      case GenerosityType.resource:
        return Icons.card_giftcard;
    }
  }

  Future<void> _submitRecord() async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    double? amount;
    if (_amountController.text.isNotEmpty) {
      amount = double.tryParse(_amountController.text);
    }

    await ref
        .read(missionProvider.notifier)
        .recordGenerosity(
          type: _selectedType,
          description: description,
          amount: amount,
          recipientName: _recipientController.text.trim().isNotEmpty
              ? _recipientController.text.trim()
              : null,
          category: _selectedCategory,
          isRecurring: _isRecurring,
          recurringFrequency: _recurringFrequency,
          impactDescription: _impactController.text.trim().isNotEmpty
              ? _impactController.text.trim()
              : null,
        );

    if (mounted) {
      ref.read(soundServiceProvider).playSuccess();
      setState(() {
        _isSubmitting = false;
        _showForm = false;
        _descriptionController.clear();
        _amountController.clear();
        _recipientController.clear();
        _impactController.clear();
        _selectedCategory = null;
        _isRecurring = false;
        _recurringFrequency = null;
      });
    }
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenerosityRecordCard extends StatelessWidget {
  const _GenerosityRecordCard({required this.record});

  final GenerosityRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color typeColor;
    IconData typeIcon;
    switch (record.type) {
      case GenerosityType.financial:
        typeColor = Colors.green;
        typeIcon = Icons.attach_money;
      case GenerosityType.time:
        typeColor = Colors.blue;
        typeIcon = Icons.schedule;
      case GenerosityType.resource:
        typeColor = Colors.orange;
        typeIcon = Icons.card_giftcard;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
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
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(typeIcon, size: 20, color: typeColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.description,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        record.type.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: typeColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (record.isRecurring)
                  Icon(
                    Icons.repeat,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (record.amount != null && record.amount! > 0) ...[
                  _buildDetailChip(
                    record.type == GenerosityType.financial
                        ? '\$${record.amount!.toStringAsFixed(2)}'
                        : '${record.amount} hrs',
                    typeColor,
                    theme,
                  ),
                  const SizedBox(width: 8),
                ],
                if (record.category != null) ...[
                  _buildDetailChip(
                    record.category!,
                    theme.colorScheme.onSurface,
                    theme,
                  ),
                  const SizedBox(width: 8),
                ],
                if (record.recipientName != null)
                  Expanded(
                    child: Text(
                      'To: ${record.recipientName}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('MMM d, yyyy').format(record.date),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(String text, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
