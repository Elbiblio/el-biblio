import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_theme_tokens.dart';

/// Horizontal scrolling row of compact action chips for quick access
/// to features aligned with the product spine: Discover, Align, Act, Reflect, Grow
class QuickActionsRow extends ConsumerWidget {
  const QuickActionsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          // Act: Service and evangelism actions
          _ActionChip(
            icon: Icons.volunteer_activism_rounded,
            label: 'Act',
            color: tokens.palette.success,
            isDark: isDark,
            onTap: () => context.push(AppRoutes.act),
          ),
          const SizedBox(width: 10),
          // Reflect: Journal for reflection
          _ActionChip(
            icon: Icons.edit_note_rounded,
            label: 'Reflect',
            color: tokens.palette.growthColor,
            isDark: isDark,
            onTap: () => context.push(AppRoutes.journal),
          ),
          const SizedBox(width: 10),
          // Align: Bible reading
          _ActionChip(
            icon: Icons.menu_book_rounded,
            label: 'Scripture',
            color: tokens.palette.primary,
            isDark: isDark,
            onTap: () => context.push(AppRoutes.bible),
          ),
          const SizedBox(width: 10),
          // Care: Soul care / meditation
          _ActionChip(
            icon: Icons.favorite_rounded,
            label: 'Care',
            color: tokens.palette.primaryLight,
            isDark: isDark,
            onTap: () => context.push(AppRoutes.meditation),
          ),
          const SizedBox(width: 10),
          // Grow Together: Community
          _ActionChip(
            icon: Icons.people_alt_rounded,
            label: 'Together',
            color: tokens.palette.identityColor,
            isDark: isDark,
            onTap: () => context.push(AppRoutes.growTogether),
          ),
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
