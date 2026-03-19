import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme_tokens.dart';
import '../../../../../core/theme/app_text_styles.dart';

class CurrentAnchorCard extends StatelessWidget {
  const CurrentAnchorCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    required this.onTap,
    this.virtueColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isCompleted;
  final VoidCallback onTap;
  final Color? virtueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(screenWidth < 360 ? 12 : 16),
        decoration: BoxDecoration(
          color: isCompleted
              ? tokens.palette.success.withValues(alpha: 0.1)
              : isDark
                  ? theme.colorScheme.surface
                  : tokens.palette.paper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: virtueColor != null
                ? virtueColor!.withValues(alpha: 0.3)
                : isCompleted
                    ? tokens.palette.success.withValues(alpha: 0.3)
                    : isDark
                        ? theme.colorScheme.outline.withValues(alpha: 0.2)
                        : tokens.palette.border.withValues(alpha: 0.85),
            width: virtueColor != null ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: screenWidth < 360 ? 40 : 48,
              height: screenWidth < 360 ? 40 : 48,
              decoration: BoxDecoration(
                color: isCompleted
                    ? tokens.palette.success.withValues(alpha: 0.2)
                    : virtueColor != null
                        ? virtueColor!.withValues(alpha: 0.2)
                        : theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompleted ? Icons.check_circle_rounded : icon,
                color: isCompleted
                    ? tokens.palette.success
                    : virtueColor != null
                        ? virtueColor!
                        : theme.colorScheme.onPrimaryContainer,
                size: screenWidth < 360 ? 20 : 24,
              ),
            ),
            SizedBox(width: screenWidth < 360 ? 12 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.cardTitle.copyWith(
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                          color: isCompleted ? tokens.palette.textSecondary : theme.colorScheme.onSurface,
                          fontSize: screenWidth < 360 ? 15 : null,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: screenWidth < 360 ? 2 : 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: screenWidth < 360 ? 11 : 13,
                          color: tokens.palette.textSecondary,
                          height: 1.3,
                        ),
                    maxLines: screenWidth < 360 ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
