import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/app_providers.dart';
import '../../domain/models/daily_anchors.dart';

class VirtueFocusBadge extends ConsumerWidget {
  const VirtueFocusBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    
    // Get the current virtue focus
    final virtueType = settings.primaryVirtue;
    final virtueColor = _getVirtueColor(virtueType, theme);
    final virtueTitle = virtueType.title;

    return GestureDetector(
      onTap: () {
        _showVirtueSelectionDialog(context, ref);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Virtue Icon
          Icon(
            _getVirtueIcon(virtueType),
            size: 20,
            color: virtueColor,
          ),
          const SizedBox(width: 8),
          
          // Virtue Info
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Nurturing...',
                  style: theme.textTheme.displaySmall?.copyWith(fontSize: 24),
                ),
                const SizedBox(height: 2),
                Text(
                  virtueTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: virtueColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          // Dropdown indicator
          Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: virtueColor.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }

  void _showVirtueSelectionDialog(BuildContext context, WidgetRef ref) {
    final currentVirtue = ref.read(settingsProvider).primaryVirtue;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Virtue Focus'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: VirtueType.values.map((virtue) {
              final virtueColor = _getVirtueColor(virtue, Theme.of(context));
              final isSelected = virtue == currentVirtue;
              
              return ListTile(
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: virtueColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: isSelected 
                        ? Border.all(color: virtueColor, width: 2)
                        : null,
                  ),
                  child: Icon(
                    _getVirtueIcon(virtue),
                    size: 18,
                    color: virtueColor,
                  ),
                ),
                title: Text(
                  virtue.title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: virtueColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  virtue.focusPrompt,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: isSelected
                    ? Icon(
                        Icons.check_circle,
                        color: virtueColor,
                        size: 20,
                      )
                    : null,
                onTap: () {
                  ref.read(settingsProvider.notifier).setVirtueFocus(primaryVirtue: virtue);
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Color _getVirtueColor(VirtueType virtue, ThemeData theme) {
    switch (virtue) {
      case VirtueType.humility:
        return const Color(0xFF8B5E3C); // Brown
      case VirtueType.love:
        return const Color(0xFFC85F4B); // Red
      case VirtueType.faith:
        return const Color(0xFF638B6C); // Green
      case VirtueType.knowledge:
        return const Color(0xFF4A6FA5); // Blue
    }
  }

  IconData _getVirtueIcon(VirtueType virtue) {
    switch (virtue) {
      case VirtueType.humility:
        return Icons.self_improvement_rounded;
      case VirtueType.love:
        return Icons.favorite_rounded;
      case VirtueType.faith:
        return Icons.sailing_rounded;
      case VirtueType.knowledge:
        return Icons.lightbulb_rounded;
    }
  }
}
