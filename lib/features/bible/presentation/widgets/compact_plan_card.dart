import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';

class CompactPlanCard extends StatelessWidget {
  const CompactPlanCard({super.key, 
    required this.title,
    required this.subtitle,
    required this.virtue,
    required this.virtueColor,
    required this.progress,
    required this.isDark,
    required this.surfaceColor,
    required this.textColor,
    required this.textMutedColor,
    required this.borderColor,
    required this.imageGradientColors,
    this.onTap,
    this.currentBook,
    this.currentChapter,
  });

  final String title;
  final String subtitle;
  final String virtue;
  final Color virtueColor;
  final double progress;
  final bool isDark;
  final Color surfaceColor;
  final Color textColor;
  final Color textMutedColor;
  final Color borderColor;
  final List<Color> imageGradientColors;
  final VoidCallback? onTap;
  final String? currentBook;
  final int? currentChapter;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
      width: 200, // Reduced from 260
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16), // Slightly smaller radius
        border: Border.all(color: borderColor),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03), // Reduced shadow
              blurRadius: 8, // Reduced blur
              offset: const Offset(0, 2), // Reduced offset
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 80, // Reduced from 110
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: imageGradientColors,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 8, // Reduced padding
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), // Smaller padding
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12), // Smaller radius
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Text(
                      virtue,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8, // Smaller font
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12), // Reduced padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.cardTitle.copyWith(
                    color: textColor,
                    height: 1.1,
                    fontSize: 14, // Smaller font
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4), // Reduced spacing
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: textMutedColor,
                    fontSize: 11, // Smaller font
                  ),
                ),
                const SizedBox(height: 8), // Reduced spacing
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PROGRESS',
                      style: Theme.of(context).textTheme.metadata.copyWith(
                        color: textMutedColor,
                        letterSpacing: 0.3,
                        fontSize: 9, // Smaller font
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: Theme.of(context).textTheme.chipText.copyWith(
                        color: virtueColor,
                        fontSize: 10, // Smaller font
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4), // Reduced spacing
                ClipRRect(
                  borderRadius: BorderRadius.circular(3), // Smaller radius
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(virtueColor),
                    minHeight: 4, // Reduced height
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
