import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_tokens.dart';

/// Hub section card for the alignment hub screen.
class AlignmentHubCard extends StatelessWidget {
  const AlignmentHubCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.progress,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final double? progress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;

    return Container(
      decoration: BoxDecoration(
        color: tokens.palette.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.palette.border),
      ),
      child: Material(
        color: Colors.transparent,
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
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: iconColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: tokens.palette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: tokens.palette.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (trailing != null) trailing!,
                    if (trailing == null)
                      Icon(
                        Icons.chevron_right_rounded,
                        color: tokens.palette.textTertiary,
                      ),
                  ],
                ),
                if (progress != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress!.clamp(0, 1),
                      minHeight: 6,
                      backgroundColor: tokens.palette.surface,
                      valueColor: AlwaysStoppedAnimation(tokens.palette.primary),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
