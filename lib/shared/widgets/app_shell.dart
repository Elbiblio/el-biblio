import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_routes.dart';
import '../../core/services/haptic_service.dart';
import '../../core/theme/app_theme_tokens.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: const _FloatingBottomNav(),
    );
  }
}

class _FloatingBottomNav extends StatelessWidget {
  const _FloatingBottomNav();

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    // Hide nav on certain routes like onboarding or full-screen assessment
    if (location == AppRoutes.onboarding) {
      return const SizedBox.shrink();
    }

    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24.0, left: 20, right: 20),
        child: Center(
          heightFactor: 1.0,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: (MediaQuery.of(context).size.width * 0.92).clamp(
                0,
                420,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? theme.colorScheme.surface.withValues(alpha: 0.82)
                        : tokens.palette.paper.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: tokens.palette.border.withValues(
                        alpha: isDark ? 0.7 : 0.85,
                      ),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withValues(
                          alpha: isDark ? 0.2 : 0.08,
                        ),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: _NavItem(
                          icon: LucideIcons.sun,
                          label: 'Today',
                          isSelected:
                              location == AppRoutes.today ||
                              location == AppRoutes.root,
                          onTap: () => context.go(AppRoutes.today),
                        ),
                      ),
                      Expanded(
                        child: _NavItem(
                          icon: LucideIcons.flag,
                          label: 'Path',
                          isSelected:
                              location.startsWith(AppRoutes.commit) ||
                              location.startsWith(AppRoutes.reflect),
                          onTap: () => context.go(AppRoutes.commit),
                        ),
                      ),
                      Expanded(
                        child: _NavItem(
                          icon: LucideIcons.users,
                          label: 'Tribe',
                          isSelected: location.startsWith(AppRoutes.tribe),
                          onTap: () => context.go(AppRoutes.tribe),
                        ),
                      ),
                      Expanded(
                        child: _NavItem(
                          icon: LucideIcons.sprout,
                          label: 'Grow',
                          isSelected: location.startsWith(AppRoutes.grow),
                          onTap: () => context.go(AppRoutes.grow),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);

    return InkWell(
      onTap: () {
        HapticService.selection();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 23),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
