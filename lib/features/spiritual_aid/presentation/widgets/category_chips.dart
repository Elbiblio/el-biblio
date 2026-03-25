import 'package:flutter/material.dart';

class CategoryChips extends StatelessWidget {
  const CategoryChips({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
    this.labelBuilder,
  });

  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;
  final String Function(String)? labelBuilder;

  String _formatLabel(String raw) {
    if (labelBuilder != null) return labelBuilder!(raw);
    return raw
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            final isActive = selected == null;
            return FilterChip(
              label: const Text('All'),
              selected: isActive,
              onSelected: (_) => onSelected(null),
              selectedColor: theme.colorScheme.primary.withValues(alpha: 0.16),
              checkmarkColor: theme.colorScheme.primary,
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurface,
              ),
              side: BorderSide(
                color: isActive ? theme.colorScheme.primary.withValues(alpha: 0.4) : theme.dividerColor,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              visualDensity: VisualDensity.compact,
            );
          }

          final cat = categories[index - 1];
          final isActive = selected == cat;

          return FilterChip(
            label: Text(_formatLabel(cat)),
            selected: isActive,
            onSelected: (_) => onSelected(isActive ? null : cat),
            selectedColor: theme.colorScheme.primary.withValues(alpha: 0.16),
            checkmarkColor: theme.colorScheme.primary,
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurface,
            ),
            side: BorderSide(
              color: isActive ? theme.colorScheme.primary.withValues(alpha: 0.4) : theme.dividerColor,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }
}
