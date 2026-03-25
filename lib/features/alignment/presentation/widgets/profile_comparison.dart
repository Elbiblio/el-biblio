import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_theme_tokens.dart';
import '../../domain/models/spiritual_profile.dart';

/// Before/after spiritual profile comparison widget.
class ProfileComparison extends StatelessWidget {
  const ProfileComparison({
    super.key,
    required this.current,
    required this.previous,
  });

  final SpiritualProfile current;
  final SpiritualProfile previous;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final growth = current.growthSince(previous);
    final isPositive = growth >= 0;

    // Get all dimension keys from both profiles
    final allKeys = {...current.dimensions.keys, ...previous.dimensions.keys};

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.palette.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPositive ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                color: isPositive ? tokens.palette.success : tokens.palette.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Growth Since Last Assessment',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: tokens.palette.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Compared to ${_formatDate(previous.assessedAt)}',
            style: TextStyle(
              fontSize: 11,
              color: tokens.palette.textTertiary,
            ),
          ),
          const SizedBox(height: 16),
          // Overall growth indicator
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isPositive ? tokens.palette.success : tokens.palette.error)
                  .withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Overall: ${isPositive ? '+' : ''}${(growth * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isPositive ? tokens.palette.success : tokens.palette.error,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Dimension-by-dimension comparison
          ...allKeys.map((key) {
            final currentVal = current.dimensions[key] ?? 0.0;
            final previousVal = previous.dimensions[key] ?? 0.0;
            final delta = currentVal - previousVal;
            final deltaPositive = delta >= 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      key,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: tokens.palette.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        height: 8,
                        child: Stack(
                          children: [
                            Container(color: tokens.palette.surface),
                            FractionallySizedBox(
                              widthFactor: currentVal.clamp(0, 1),
                              child: Container(
                                color: tokens.palette.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 50,
                    child: Text(
                      '${deltaPositive ? '+' : ''}${(delta * 100).round()}%',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: deltaPositive
                            ? tokens.palette.success
                            : tokens.palette.error,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
