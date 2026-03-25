import 'package:flutter/material.dart';

/// A beautifully designed card for sharing faith content.
class ShareableCard extends StatelessWidget {
  const ShareableCard({
    super.key,
    required this.title,
    required this.body,
    this.reference,
    this.category,
    this.colorTheme = ShareableCardTheme.blue,
  });

  final String title;
  final String body;
  final String? reference;
  final String? category;
  final ShareableCardTheme colorTheme;

  @override
  Widget build(BuildContext context) {
    final colors = _getColors();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (category != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                category!.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 15,
              height: 1.6,
            ),
          ),
          if (reference != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                reference!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: Colors.white.withValues(alpha: 0.6),
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                'ElBiblio',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Color> _getColors() {
    return switch (colorTheme) {
      ShareableCardTheme.blue => const [Color(0xFF1a3a5c), Color(0xFF2b5c8a)],
      ShareableCardTheme.purple => const [Color(0xFF4a1a5c), Color(0xFF7b3d9e)],
      ShareableCardTheme.green => const [Color(0xFF1a5c3a), Color(0xFF3d9e6b)],
      ShareableCardTheme.sunset => const [Color(0xFF8b4513), Color(0xFFc67b3c)],
      ShareableCardTheme.rose => const [Color(0xFF7a1e3a), Color(0xFFb83b5e)],
    };
  }
}

enum ShareableCardTheme {
  blue,
  purple,
  green,
  sunset,
  rose,
}
