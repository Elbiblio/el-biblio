import 'dart:ui';

import 'package:flutter/material.dart';

class PremiumOnboardingBackground extends StatelessWidget {
  const PremiumOnboardingBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            scheme.surface.withValues(alpha: 1.0),
            scheme.surface.withValues(alpha: 0.96),
            scheme.surface.withValues(alpha: 1.0),
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            left: -90,
            child: _BlurBlob(
              color: scheme.primary.withValues(alpha: 0.12),
              size: 260,
            ),
          ),
          Positioned(
            top: 90,
            right: -120,
            child: _BlurBlob(
              color: scheme.primary.withValues(alpha: 0.08),
              size: 300,
            ),
          ),
          Positioned(
            bottom: -140,
            left: -120,
            child: _BlurBlob(
              color: scheme.secondary.withValues(alpha: 0.08),
              size: 320,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _BlurBlob extends StatelessWidget {
  const _BlurBlob({
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}
