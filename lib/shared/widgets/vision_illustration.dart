import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum VisionIllustrationAsset {
  completion('assets/images/vision_completion.svg'),
  commitment('assets/images/vision_commitment.svg'),
  belonging('assets/images/vision_belonging.svg'),
  protection('assets/images/vision_protection.svg'),
  growth('assets/images/vision_growth.svg'),
  play('assets/images/vision_play.svg');

  const VisionIllustrationAsset(this.path);

  final String path;
}

class VisionIllustration extends StatelessWidget {
  const VisionIllustration({
    super.key,
    required this.asset,
    this.size = 92,
    this.semanticLabel,
  });

  final VisionIllustrationAsset asset;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset.path,
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticsLabel: semanticLabel,
      errorBuilder: (context, error, stackTrace) {
        return SizedBox.square(
          dimension: size,
          child: Icon(
            Icons.check_circle_rounded,
            size: size * 0.68,
            color: Theme.of(context).colorScheme.primary,
          ),
        );
      },
    );
  }
}
