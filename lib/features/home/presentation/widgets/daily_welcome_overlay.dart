import 'package:flutter/material.dart';

class DailyWelcomeOverlay extends StatefulWidget {
  const DailyWelcomeOverlay({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<DailyWelcomeOverlay> createState() => _DailyWelcomeOverlayState();
}

class _DailyWelcomeOverlayState extends State<DailyWelcomeOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _rotationAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _burstAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.15).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
      ),
    );
    _burstAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );

    _controller.forward().whenComplete(() {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);

    if (reducedMotion) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) widget.onComplete();
      });
      return Container(
        color: colors.surface.withValues(alpha: 0.4),
        child: const Center(child: SizedBox.shrink()),
      );
    }

    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  color: colors.surface.withValues(alpha: 0.0),
                ),
              ),
              // Centre burst sparkle — peaks at the sound's brightest moment
              Positioned(
                top: size.height * 0.28,
                left: size.width * 0.5 - 28,
                child: Opacity(
                  opacity: (_burstAnimation.value * (1 - _burstAnimation.value) * 4)
                      .clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.4 + _burstAnimation.value * 1.2,
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: 56,
                      color: colors.primary.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -MediaQuery.of(context).size.height * 0.2,
                left: -MediaQuery.of(context).size.width * 0.3,
                right: -MediaQuery.of(context).size.width * 0.3,
                height: MediaQuery.of(context).size.height * 0.9,
                child: Transform.rotate(
                  angle: _rotationAnimation.value * 3.14,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0.5, 0.0),
                          radius: 0.8,
                          colors: [
                            colors.primary.withValues(alpha: 0.18),
                            colors.primary.withValues(alpha: 0.08),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -MediaQuery.of(context).size.height * 0.1,
                left: -MediaQuery.of(context).size.width * 0.4,
                right: -MediaQuery.of(context).size.width * 0.4,
                height: MediaQuery.of(context).size.height * 0.7,
                child: Transform.rotate(
                  angle: -_rotationAnimation.value * 3.14,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0.5, 0.0),
                        radius: 0.7,
                        colors: [
                          colors.secondary.withValues(alpha: 0.10),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              ..._buildSparkles(context),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildSparkles(BuildContext context) {
    final positions = [0.12, 0.28, 0.45, 0.62, 0.78, 0.88];
    return positions.map((dx) {
      final delay = Interval(dx * 0.6, dx * 0.6 + 0.3, curve: Curves.easeOut);
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = delay.transform(_controller.value);
          return Positioned(
            top: MediaQuery.of(context).size.height * 0.05 + dx * 120,
            left: MediaQuery.of(context).size.width * dx,
            child: Opacity(
              opacity: t,
              child: Transform.scale(
                scale: 0.5 + t * 0.5,
                child: Icon(
                  Icons.star,
                  size: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.7),
                ),
              ),
            ),
          );
        },
      );
    }).toList();
  }
}
