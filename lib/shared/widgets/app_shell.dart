import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_routes.dart';
import '../../core/services/haptic_service.dart';
import '../../core/theme/app_theme_tokens.dart';

@visibleForTesting
bool isShellRouteSelected(String location, String route) {
  return location == route || location.startsWith('$route/');
}

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
    final palette = tokens.palette;

    // Hide nav on certain routes like onboarding or full-screen assessment
    if (location == AppRoutes.onboarding) {
      return const SizedBox.shrink();
    }

    final isDark = theme.brightness == Brightness.dark;
    final shellFill = isDark
        ? Color.alphaBlend(
            palette.primary.withValues(alpha: 0.08),
            theme.colorScheme.surface.withValues(alpha: 0.88),
          )
        : Color.alphaBlend(
            palette.primaryLight.withValues(alpha: 0.07),
            palette.paper.withValues(alpha: 0.92),
          );

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          18 + MediaQuery.paddingOf(context).bottom * 0.45,
        ),
        child: Center(
          heightFactor: 1.0,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: (MediaQuery.of(context).size.width * 0.92).clamp(
                0,
                460,
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
                    color: shellFill,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: palette.border.withValues(
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
                          accent: palette.primary,
                          isSelected:
                              location == AppRoutes.today ||
                              location == AppRoutes.root,
                          onTap: () => context.go(AppRoutes.today),
                        ),
                      ),
                      Expanded(
                        child: _NavItem(
                          icon: LucideIcons.flag,
                          label: 'Commit',
                          accent: palette.commitmentColor,
                          isSelected: isShellRouteSelected(
                            location,
                            AppRoutes.commit,
                          ),
                          onTap: () => context.go(AppRoutes.commit),
                        ),
                      ),
                      Expanded(
                        child: _NavItem(
                          icon: LucideIcons.messageCircle,
                          label: 'Reflect',
                          accent: palette.identityColor,
                          isSelected: isShellRouteSelected(
                            location,
                            AppRoutes.reflect,
                          ),
                          onTap: () => context.go(AppRoutes.reflect),
                        ),
                      ),
                      Expanded(
                        child: _NavItem(
                          icon: LucideIcons.users,
                          label: 'Tribe',
                          accent: palette.distractionColor,
                          isSelected: isShellRouteSelected(
                            location,
                            AppRoutes.tribe,
                          ),
                          onTap: () => context.go(AppRoutes.tribe),
                        ),
                      ),
                      Expanded(
                        child: _NavItem(
                          icon: LucideIcons.sprout,
                          label: 'Grow',
                          accent: palette.growthColor,
                          isSelected: isShellRouteSelected(
                            location,
                            AppRoutes.grow,
                          ),
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
    required this.accent,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final color = isSelected
        ? accent
        : theme.colorScheme.onSurface.withValues(alpha: 0.52);
    final selectedFill = Color.alphaBlend(
      accent.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.20 : 0.13,
      ),
      tokens.palette.surface.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.34 : 0.64,
      ),
    );

    return InkWell(
      onTap: () {
        HapticService.selection();
        onTap();
      },
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected ? selectedFill : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? accent.withValues(alpha: 0.20)
                : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              scale: isSelected ? 1.04 : 1,
              child: Icon(icon, color: color, size: 23),
            ),
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
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              width: isSelected ? 16 : 4,
              height: 3,
              decoration: BoxDecoration(
                color: isSelected
                    ? accent.withValues(alpha: 0.86)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
