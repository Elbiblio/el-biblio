import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_tokens.dart';

class VisionActionTile extends StatelessWidget {
  const VisionActionTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.selected = false,
    this.dense = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool selected;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final enabled = onTap != null;
    final accent = selected
        ? theme.colorScheme.primary
        : tokens.palette.textPrimary;
    final fill = selected
        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.34)
        : theme.colorScheme.surface.withValues(
            alpha: theme.brightness == Brightness.dark ? 0.58 : 0.78,
          );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          constraints: BoxConstraints(minHeight: dense ? 64 : 78),
          padding: EdgeInsets.all(dense ? 12 : 14),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary.withValues(alpha: 0.44)
                  : tokens.palette.border,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: dense ? 38 : 44,
                height: dense ? 38 : 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(
                    alpha: selected ? 0.16 : 0.1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: dense ? 19 : 22,
                  color: enabled
                      ? theme.colorScheme.primary
                      : theme.disabledColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: enabled
                            ? accent
                            : theme.disabledColor.withValues(alpha: 0.86),
                        fontWeight: FontWeight.w900,
                        height: 1.12,
                      ),
                    ),
                    if (subtitle?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!.trim(),
                        maxLines: dense ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: tokens.palette.textSecondary,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 10), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

class VisionActionTileColumn extends StatelessWidget {
  const VisionActionTileColumn({
    super.key,
    required this.children,
    this.spacing = 10,
  });

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(height: spacing),
          children[i],
        ],
      ],
    );
  }
}
