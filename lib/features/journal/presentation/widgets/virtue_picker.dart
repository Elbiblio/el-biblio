import 'package:flutter/material.dart';
import '../../../today/domain/models/daily_anchors.dart';

class VirtuePicker extends StatelessWidget {
  const VirtuePicker({
    super.key,
    required this.selectedVirtues,
    required this.onVirtueToggle,
  });

  final List<String> selectedVirtues;
  final Function(String) onVirtueToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: VirtueType.values.map((virtue) {
        final isSelected = selectedVirtues.contains(virtue.name);
        return FilterChip(
          label: Text(virtue.title),
          selected: isSelected,
          onSelected: (_) => onVirtueToggle(virtue.name),
          selectedColor: Theme.of(context).colorScheme.primaryContainer,
          checkmarkColor: Theme.of(context).colorScheme.primary,
          labelStyle: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }
}
