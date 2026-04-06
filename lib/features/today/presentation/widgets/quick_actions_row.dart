import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';

/// Horizontal scrolling row of compact action chips for quick access
/// to features that were displaced from the home screen.
class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          _ActionChip(
            icon: Icons.medical_services_rounded,
            label: 'Care',
            color: Colors.red.shade400,
            isDark: isDark,
            onTap: () => context.push(AppRoutes.spiritualAid),
          ),
          const SizedBox(width: 10),
          _ActionChip(
            icon: Icons.menu_book_rounded,
            label: 'Bible',
            color: theme.colorScheme.primary,
            isDark: isDark,
            onTap: () => context.push(AppRoutes.bible),
          ),
          const SizedBox(width: 10),
          _ActionChip(
            icon: Icons.edit_note_rounded,
            label: 'Journal',
            color: Colors.teal.shade400,
            isDark: isDark,
            onTap: () => context.push(AppRoutes.journal),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.3 : 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
