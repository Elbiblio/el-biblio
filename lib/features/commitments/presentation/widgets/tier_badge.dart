import 'package:flutter/material.dart';

import '../../domain/models/graduated_commitment.dart';

/// A small badge showing the commitment tier with its color and icon.
class TierBadge extends StatelessWidget {
  const TierBadge({
    super.key,
    required this.tier,
    this.size = TierBadgeSize.medium,
    this.showLabel = true,
  });

  final CommitmentTier tier;
  final TierBadgeSize size;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final double iconSize;
    final double paddingH;
    final double paddingV;
    final TextStyle? textStyle;

    switch (size) {
      case TierBadgeSize.small:
        iconSize = 14;
        paddingH = 8;
        paddingV = 4;
        textStyle = Theme.of(context).textTheme.labelSmall;
      case TierBadgeSize.medium:
        iconSize = 18;
        paddingH = 12;
        paddingV = 6;
        textStyle = Theme.of(context).textTheme.labelMedium;
      case TierBadgeSize.large:
        iconSize = 24;
        paddingH = 16;
        paddingV = 8;
        textStyle = Theme.of(context).textTheme.labelLarge;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: paddingV),
      decoration: BoxDecoration(
        color: tier.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tier.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(tier.icon, style: TextStyle(fontSize: iconSize)),
          if (showLabel) ...[
            const SizedBox(width: 6),
            Text(
              tier.label,
              style: textStyle?.copyWith(
                color: tier.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum TierBadgeSize { small, medium, large }
