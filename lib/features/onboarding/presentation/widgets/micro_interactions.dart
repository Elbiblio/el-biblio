import 'package:flutter/material.dart';

class MicroInteractions {
  // Gentle pulse animation for interactive elements
  static Widget pulse({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1500),
    double minScale = 0.95,
    double maxScale = 1.05,
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween(begin: minScale, end: maxScale),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      onEnd: () {
        // Reverse animation
        // This creates a breathing effect
      },
    );
  }

  // Subtle fade in with slide up
  static Widget fadeInUp({
    required Widget child,
    Duration duration = const Duration(milliseconds: 600),
    double offset = 30.0,
    Curve curve = Curves.easeOutCubic,
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween(begin: 0.0, end: 1.0),
      curve: curve,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, offset * (1 - value)),
            child: child,
          ),
        );
      },
    );
  }

  // Staggered animation for lists
  static Widget staggeredItem({
    required Widget child,
    required int index,
    Duration baseDelay = const Duration(milliseconds: 100),
    Duration itemDuration = const Duration(milliseconds: 400),
  }) {
    return TweenAnimationBuilder<double>(
      duration: itemDuration,
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
    );
  }

  // Gentle shimmer effect for loading states
  static Widget shimmer({
    required Widget child,
    Color baseColor = Colors.grey,
    Color highlightColor = Colors.white,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            baseColor.withValues(alpha: 0.3),
            highlightColor.withValues(alpha: 0.1),
            baseColor.withValues(alpha: 0.3),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: child,
    );
  }

  // Interactive hover effect for buttons
  static Widget hoverEffect({
    required Widget child,
    double hoverScale = 1.05,
    Duration duration = const Duration(milliseconds: 200),
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: duration,
        child: Transform.scale(
          scale: hoverScale,
          child: child,
        ),
      ),
    );
  }

  // Smooth page transition
  static Widget pageTransition({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    return AnimatedSwitcher(
      duration: duration,
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: curve)),
          child: child,
        );
      },
      child: child,
    );
  }

  // Ripple effect for touch feedback
  static Widget ripple({
    required Widget child,
    Color rippleColor = Colors.white,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        splashColor: rippleColor.withValues(alpha: 0.3),
        highlightColor: rippleColor.withValues(alpha: 0.1),
        onTap: () {},
        child: child,
      ),
    );
  }

  // Breathing animation for meditative elements
  static Widget breathe({
    required Widget child,
    Duration duration = const Duration(milliseconds: 4000),
    double minScale = 0.98,
    double maxScale = 1.02,
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween(begin: minScale, end: maxScale),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
    );
  }

  // Floating animation for decorative elements
  static Widget float({
    required Widget child,
    Duration duration = const Duration(milliseconds: 3000),
    double amplitude = 10.0,
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, amplitude * (0.5 - (value - 0.5).abs() * 2)),
          child: child,
        );
      },
    );
  }

  // Gentle rotation for loading indicators
  static Widget gentleRotate({
    required Widget child,
    Duration duration = const Duration(milliseconds: 2000),
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.rotate(
          angle: value * 0.1,
          child: child,
        );
      },
    );
  }
}

class InteractiveCard extends StatefulWidget {
  const InteractiveCard({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = 12.0,
    this.elevation = 2.0,
    this.hoverElevation = 8.0,
    this.backgroundColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;
  final double elevation;
  final double hoverElevation;
  final Color? backgroundColor;

  @override
  State<InteractiveCard> createState() => _InteractiveCardState();
}

class _InteractiveCardState extends State<InteractiveCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _elevationAnimation = Tween<double>(
      begin: widget.elevation,
      end: widget.hoverElevation,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    if (widget.onTap != null) {
      widget.onTap!();
    }
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: widget.backgroundColor ?? Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
                    blurRadius: _elevationAnimation.value * 2,
                    offset: Offset(0, _elevationAnimation.value),
                  ),
                ],
              ),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

class SmoothTransitionBuilder extends StatelessWidget {
  const SmoothTransitionBuilder({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOutCubic,
    this.delay = Duration.zero,
  });

  final Widget child;
  final Duration duration;
  final Curve curve;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween(begin: 0.0, end: 1.0),
      curve: curve,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
