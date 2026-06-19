import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_routes.dart';
import '../../core/services/haptic_service.dart';
import '../../core/theme/app_theme_tokens.dart';

@visibleForTesting
bool isShellRouteSelected(String location, String route) {
  return location == route || location.startsWith('$route/');
}

@visibleForTesting
bool shouldShowShellChrome(String location) {
  return _MinimizedShellNav.isTopLevelDestination(location);
}

final shellChromeController = ShellChromeController();
final rootChromeRouteObserver = ShellChromeRouteObserver(shellChromeController);
final shellChromeRouteObserver = ShellChromeRouteObserver(
  shellChromeController,
);

class ShellChromeController {
  final ValueNotifier<bool> hideChrome = ValueNotifier<bool>(false);

  int _popupDepth = 0;

  void _setDepth(int depth) {
    _popupDepth = depth < 0 ? 0 : depth;
    hideChrome.value = _popupDepth > 0;
  }

  void didPushPopup() {
    _setDepth(_popupDepth + 1);
  }

  void didPopPopup() {
    _setDepth(_popupDepth - 1);
  }

  void didReplacePopup({
    required bool oldRouteWasPopup,
    required bool newRouteIsPopup,
  }) {
    var depth = _popupDepth;
    if (oldRouteWasPopup) {
      depth--;
    }
    if (newRouteIsPopup) {
      depth++;
    }
    _setDepth(depth);
  }
}

class ShellChromeRouteObserver extends NavigatorObserver {
  ShellChromeRouteObserver(this._controller);

  final ShellChromeController _controller;

  bool _isPopup(Route<dynamic> route) => route is PopupRoute<dynamic>;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (_isPopup(route)) {
      _controller.didPushPopup();
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (_isPopup(route)) {
      _controller.didPopPopup();
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    if (_isPopup(route)) {
      _controller.didPopPopup();
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _controller.didReplacePopup(
      oldRouteWasPopup: oldRoute != null && _isPopup(oldRoute),
      newRouteIsPopup: newRoute != null && _isPopup(newRoute),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _menuOpen = false;

  @override
  void initState() {
    super.initState();
    shellChromeController.hideChrome.addListener(_handleChromeVisibility);
  }

  @override
  void dispose() {
    shellChromeController.hideChrome.removeListener(_handleChromeVisibility);
    super.dispose();
  }

  void _handleChromeVisibility() {
    if (shellChromeController.hideChrome.value && _menuOpen && mounted) {
      setState(() => _menuOpen = false);
    }
  }

  void _toggleMenu() {
    HapticService.selection();
    setState(() => _menuOpen = !_menuOpen);
  }

  void _closeMenu() {
    if (!_menuOpen) {
      return;
    }
    setState(() => _menuOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    final routerDelegate = GoRouter.of(context).routerDelegate;

    return AnimatedBuilder(
      animation: routerDelegate,
      builder: (context, _) {
        final location = routerDelegate.currentConfiguration.uri.path;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Stack(
            children: [
              Positioned.fill(child: widget.child),
              if (shouldShowShellChrome(location))
                ValueListenableBuilder<bool>(
                  valueListenable: shellChromeController.hideChrome,
                  builder: (context, hideChrome, _) {
                    if (hideChrome) {
                      return const SizedBox.shrink();
                    }

                    return _MinimizedShellNav(
                      isOpen: _menuOpen,
                      currentLocation: location,
                      onToggle: _toggleMenu,
                      onClose: _closeMenu,
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MinimizedShellNav extends StatelessWidget {
  const _MinimizedShellNav({
    required this.isOpen,
    required this.currentLocation,
    required this.onToggle,
    required this.onClose,
  });

  static const List<_ShellDestination> _destinations = [
    _ShellDestination(
      label: 'Home',
      route: AppRoutes.home,
      icon: LucideIcons.home,
      accent: _ShellAccent.primary,
      includeRoot: true,
    ),
    _ShellDestination(
      label: 'Connect',
      route: AppRoutes.connect,
      icon: LucideIcons.users,
      accent: _ShellAccent.connect,
    ),
    _ShellDestination(
      label: 'Commit',
      route: AppRoutes.commit,
      icon: LucideIcons.flag,
      accent: _ShellAccent.commit,
    ),
    _ShellDestination(
      label: 'Speak',
      route: AppRoutes.speak,
      icon: LucideIcons.messageCircle,
      accent: _ShellAccent.speak,
    ),
  ];

  final bool isOpen;
  final String currentLocation;
  final VoidCallback onToggle;
  final VoidCallback onClose;

  static bool isTopLevelDestination(String location) {
    return _destinations.any(
      (destination) =>
          location == destination.route ||
          (destination.includeRoot && location == AppRoutes.root),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaPadding = MediaQuery.paddingOf(context);
    final bottom = 18 + mediaPadding.bottom;
    final panelLeft = 16 + mediaPadding.left;
    final buttonLeft = mediaPadding.left - 6;
    final maxPanelHeight = MediaQuery.sizeOf(context).height * 0.64;

    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !isOpen,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 160),
              opacity: isOpen ? 1 : 0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onClose,
                child: ColoredBox(color: Colors.black.withValues(alpha: 0.10)),
              ),
            ),
          ),
        ),
        Positioned(
          left: panelLeft,
          bottom: bottom + 68,
          child: _ShellMenuPanel(
            isOpen: isOpen,
            maxHeight: maxPanelHeight,
            currentLocation: currentLocation,
            destinations: _destinations,
            onNavigate: onClose,
          ),
        ),
        Positioned(
          left: buttonLeft,
          bottom: bottom,
          child: _ShellMenuButton(isOpen: isOpen, onPressed: onToggle),
        ),
      ],
    );
  }
}

class _ShellMenuButton extends StatelessWidget {
  const _ShellMenuButton({required this.isOpen, required this.onPressed});

  final bool isOpen;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final palette = tokens.palette;
    final isDark = theme.brightness == Brightness.dark;
    final fill = Color.alphaBlend(
      palette.primary.withValues(alpha: isDark ? 0.18 : 0.10),
      isDark
          ? theme.colorScheme.surface.withValues(alpha: 0.92)
          : palette.paper.withValues(alpha: 0.94),
    );

    return Semantics(
      button: true,
      label: isOpen ? 'Close navigation menu' : 'Open navigation menu',
      child: Tooltip(
        message: isOpen ? 'Close menu' : 'Menu',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: fill,
                    border: Border.all(
                      color: palette.border.withValues(
                        alpha: isDark ? 0.72 : 0.9,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withValues(
                          alpha: isDark ? 0.22 : 0.10,
                        ),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: Icon(
                      isOpen ? LucideIcons.x : LucideIcons.menu,
                      key: ValueKey<bool>(isOpen),
                      color: palette.primary,
                      size: 25,
                    ),
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

class _ShellMenuPanel extends StatelessWidget {
  const _ShellMenuPanel({
    required this.isOpen,
    required this.maxHeight,
    required this.currentLocation,
    required this.destinations,
    required this.onNavigate,
  });

  final bool isOpen;
  final double maxHeight;
  final String currentLocation;
  final List<_ShellDestination> destinations;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final palette = tokens.palette;
    final isDark = theme.brightness == Brightness.dark;
    final fill = isDark
        ? Color.alphaBlend(
            palette.primary.withValues(alpha: 0.08),
            theme.colorScheme.surface.withValues(alpha: 0.94),
          )
        : Color.alphaBlend(
            palette.primaryLight.withValues(alpha: 0.08),
            palette.paper.withValues(alpha: 0.96),
          );

    return IgnorePointer(
      ignoring: !isOpen,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: isOpen ? 1 : 0,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 190),
          curve: Curves.easeOutCubic,
          offset: isOpen ? Offset.zero : const Offset(0, 0.08),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: Container(
                width: 292,
                constraints: BoxConstraints(maxHeight: maxHeight),
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: palette.border.withValues(
                      alpha: isDark ? 0.72 : 0.86,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withValues(
                        alpha: isDark ? 0.24 : 0.12,
                      ),
                      blurRadius: 30,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final destination in destinations)
                        _ShellMenuItem(
                          destination: destination,
                          isSelected: destination.isSelected(currentLocation),
                          onNavigate: onNavigate,
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

class _ShellMenuItem extends StatelessWidget {
  const _ShellMenuItem({
    required this.destination,
    required this.isSelected,
    required this.onNavigate,
  });

  final _ShellDestination destination;
  final bool isSelected;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final accent = destination.resolveAccent(tokens);
    final foreground = isSelected
        ? accent
        : theme.colorScheme.onSurface.withValues(alpha: 0.72);
    final selectedFill = Color.alphaBlend(
      accent.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.22 : 0.12,
      ),
      tokens.palette.surface.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.28 : 0.72,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isSelected ? selectedFill : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            HapticService.selection();
            onNavigate();
            context.go(destination.route);
          },
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 46,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(destination.icon, color: foreground, size: 21),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      destination.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 15,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: isSelected ? 7 : 0,
                    height: isSelected ? 7 : 0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _ShellAccent { primary, connect, commit, speak }

class _ShellDestination {
  const _ShellDestination({
    required this.label,
    required this.route,
    required this.icon,
    required this.accent,
    this.includeRoot = false,
  });

  final String label;
  final String route;
  final IconData icon;
  final _ShellAccent accent;
  final bool includeRoot;

  bool isSelected(String location) {
    return (includeRoot && location == AppRoutes.root) ||
        isShellRouteSelected(location, route);
  }

  Color resolveAccent(AppThemeTokens tokens) {
    return switch (accent) {
      _ShellAccent.primary => tokens.palette.primary,
      _ShellAccent.connect => tokens.palette.identityColor,
      _ShellAccent.commit => tokens.palette.commitmentColor,
      _ShellAccent.speak => tokens.palette.growthColor,
    };
  }
}
