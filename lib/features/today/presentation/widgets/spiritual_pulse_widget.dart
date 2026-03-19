import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/app_providers.dart';
import '../../domain/models/daily_anchors.dart';

class SpiritualPulseWidget extends ConsumerStatefulWidget {
  const SpiritualPulseWidget({super.key});

  @override
  ConsumerState<SpiritualPulseWidget> createState() => _SpiritualPulseWidgetState();
}

class _SpiritualPulseWidgetState extends ConsumerState<SpiritualPulseWidget> {
  final TextEditingController _noteController = TextEditingController();
  SpiritualPulseType? _selectedType;
  double _intensity = 1.0;
  String _goingWell = '';
  String _struggling = '';
  String _needHelp = '';
  String _followUpAnswer = '';
  String _virtueFocus = '';

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _submitPulse() {
    if (_selectedType == null || _noteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a pulse type and add a note'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    ref.read(dailyAnchorsProvider.notifier).addSpiritualPulse(
      type: _selectedType!,
      note: _noteController.text.trim(),
      intensity: _intensity,
      goingWell: _goingWell.isNotEmpty ? _goingWell : null,
      struggling: _struggling.isNotEmpty ? _struggling : null,
      needHelp: _needHelp.isNotEmpty ? _needHelp : null,
      followUpAnswer: _followUpAnswer.isNotEmpty ? _followUpAnswer : null,
      virtueFocus: _virtueFocus.isNotEmpty ? _virtueFocus : null,
    );

    // Clear form
    setState(() {
      _selectedType = null;
      _intensity = 1.0;
      _goingWell = '';
      _struggling = '';
      _needHelp = '';
      _followUpAnswer = '';
      _virtueFocus = '';
    });
    _noteController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Spiritual pulse recorded'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1e293b) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spiritual Pulse Check-in',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          
          // Pulse type selection
          Text(
            'How are you feeling spiritually?',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SpiritualPulseType.values.map((type) {
              final isSelected = _selectedType == type;
              return FilterChip(
                label: Text(_getPulseTypeLabel(type)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedType = selected ? type : null;
                  });
                },
                backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                checkmarkColor: theme.colorScheme.primary,
              );
            }).toList(),
          ),
          
          if (_selectedType != null) ...[
            const SizedBox(height: 20),
            
            // Intensity slider
            Text(
              'Intensity: ${(_intensity * 100).round()}%',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Slider(
              value: _intensity,
              onChanged: (value) {
                setState(() {
                  _intensity = value;
                });
              },
              min: 0.0,
              max: 1.0,
              activeColor: theme.colorScheme.primary,
            ),
            
            const SizedBox(height: 20),
            
            // Note input
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: 'Add a note about your spiritual state...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
              ),
              maxLines: 3,
            ),
            
            const SizedBox(height: 20),
            
            // Optional reflection questions
            ExpansionTile(
              title: Text(
                'Add reflection details (optional)',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'What\'s going well?',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                  ),
                  onChanged: (value) => _goingWell = value,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'What are you struggling with?',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                  ),
                  onChanged: (value) => _struggling = value,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'What do you need help with?',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                  ),
                  onChanged: (value) => _needHelp = value,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Virtue focus',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                  ),
                  onChanged: (value) => _virtueFocus = value,
                  maxLines: 1,
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitPulse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Record Spiritual Pulse',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getPulseTypeLabel(SpiritualPulseType type) {
    switch (type) {
      case SpiritualPulseType.peace:
        return 'Peace';
      case SpiritualPulseType.joy:
        return 'Joy';
      case SpiritualPulseType.gratitude:
        return 'Gratitude';
      case SpiritualPulseType.hope:
        return 'Hope';
      case SpiritualPulseType.love:
        return 'Love';
      case SpiritualPulseType.wisdom:
        return 'Wisdom';
    }
  }
}
