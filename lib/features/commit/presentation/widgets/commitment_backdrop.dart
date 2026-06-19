import 'package:flutter/material.dart';

import '../../data/commitment_media_catalog.dart';

class CommitmentBackdrop extends StatelessWidget {
  const CommitmentBackdrop({
    super.key,
    required this.category,
    this.child,
    this.opacity = 0.6,
  });

  final String category;
  final Widget? child;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = CommitmentMediaCatalog.getMedia(category);

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            media.backgroundImage,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: media.accentColor.withValues(alpha: 0.15),
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.scaffoldBackgroundColor.withValues(alpha: 0.2),
                  theme.scaffoldBackgroundColor.withValues(alpha: opacity),
                  theme.scaffoldBackgroundColor,
                ],
              ),
            ),
          ),
        ),
        if (child != null) child!,
      ],
    );
  }
}
