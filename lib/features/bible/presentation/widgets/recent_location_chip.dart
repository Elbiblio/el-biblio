import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';

class RecentLocationChip extends StatelessWidget {
  const RecentLocationChip({super.key, 
    required this.text,
    this.onTap,
    required this.isDark,
    required this.surfaceColor,
    required this.borderColor,
  });

  final String text;
  final VoidCallback? onTap;
  final bool isDark;
  final Color surfaceColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? surfaceColor.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 14, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              text,
              style: Theme.of(context).textTheme.chipText,
            ),
          ],
        ),
      ),
    );
  }
}
