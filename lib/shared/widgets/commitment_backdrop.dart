import 'package:flutter/material.dart';

import '../../features/commit/data/commitment_media_catalog.dart';

class CommitmentBackdrop extends StatelessWidget {
  const CommitmentBackdrop({
    super.key,
    required this.category,
    required this.child,
    this.opacity = 0.12,
  });

  final String category;
  final Widget child;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final media = CommitmentMediaCatalog.getMedia(category);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            media.accentColor.withValues(alpha: opacity),
            Colors.transparent,
            media.accentColor.withValues(alpha: opacity * 0.5),
          ],
        ),
      ),
      child: child,
    );
  }
}
