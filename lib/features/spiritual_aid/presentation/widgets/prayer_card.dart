import 'package:flutter/material.dart';

import '../../domain/models/quick_prayer.dart';

class PrayerCard extends StatefulWidget {
  const PrayerCard({
    super.key,
    required this.prayer,
    required this.onFavoriteToggle,
    required this.onTTSPlay,
    required this.onPrayWithMe,
  });

  final QuickPrayer prayer;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onTTSPlay;
  final VoidCallback onPrayWithMe;

  @override
  State<PrayerCard> createState() => _PrayerCardState();
}

class _PrayerCardState extends State<PrayerCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prayer = widget.prayer;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: InkWell(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        borderRadius: BorderRadius.circular(18),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _formatCategory(prayer.category),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(prayer.estimatedSeconds / 60).ceil()} min read',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        prayer.isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: prayer.isFavorite ? Colors.red.shade400 : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        size: 20,
                      ),
                      onPressed: widget.onFavoriteToggle,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Title
                Text(
                  prayer.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),

                if (_isExpanded) ...[
                  const SizedBox(height: 12),

                  // Prayer body
                  Text(
                    prayer.body,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Related verse
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prayer.relatedVerse,
                          style: theme.textTheme.bodySmall?.copyWith(
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '- ${prayer.relatedVerseReference}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onTTSPlay,
                          icon: const Icon(Icons.volume_up_rounded, size: 18),
                          label: const Text('Listen'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 40),
                            textStyle: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: widget.onPrayWithMe,
                          icon: const Icon(Icons.auto_awesome, size: 18),
                          label: const Text('Pray with Me'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 40),
                            textStyle: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 4),
                  Text(
                    prayer.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatCategory(String raw) {
    return raw[0].toUpperCase() + raw.substring(1);
  }
}
