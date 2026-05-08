import 'package:flutter/material.dart';

import '../../domain/vision_models.dart';

class VisibilityModePicker extends StatelessWidget {
  const VisibilityModePicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final VisibilityMode value;
  final ValueChanged<VisibilityMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: VisibilityMode.values.map((mode) {
        return ChoiceChip(
          label: Text(mode.label),
          selected: value == mode,
          onSelected: (_) => onChanged(mode),
        );
      }).toList(),
    );
  }
}
