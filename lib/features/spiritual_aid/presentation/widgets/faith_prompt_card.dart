import 'package:flutter/material.dart';

import '../../domain/models/faith_prompt.dart';

class FaithPromptCard extends StatelessWidget {
  const FaithPromptCard({
    super.key,
    required this.prompt,
    this.isFeatured = false,
    this.onJournalTap,
    this.onShareTap,
  });

  final FaithPrompt prompt;
  final bool isFeatured;
  final VoidCallback? onJournalTap;
  final VoidCallback? onShareTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isFeatured) {
      return _buildFeaturedCard(context, theme);
    }
    return _buildCompactCard(context, theme);
  }

  Widget _buildFeaturedCard(BuildContext context, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'TODAY\'S PROMPT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatCategory(prompt.category),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Question
            Text(
              prompt.question,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),

            // Context
            Text(
              prompt.context,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            // Scripture
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
                    prompt.relatedScripture,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '- ${prompt.scriptureReference}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Discussion starters
            Text(
              'Discussion Starters',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...prompt.discussionStarters.map((starter) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.subdirectory_arrow_right_rounded,
                        size: 16,
                        color: theme.colorScheme.primary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          starter,
                          style: theme.textTheme.bodySmall?.copyWith(
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 16),

            // Actions
            Row(
              children: [
                if (onJournalTap != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onJournalTap,
                      icon: const Icon(Icons.edit_note, size: 18),
                      label: const Text('Journal'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                if (onJournalTap != null && onShareTap != null)
                  const SizedBox(width: 8),
                if (onShareTap != null)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onShareTap,
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text('Share'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactCard(BuildContext context, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: InkWell(
        onTap: onJournalTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _formatCategory(prompt.category),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                prompt.question,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                prompt.scriptureReference,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCategory(String raw) {
    return raw
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }
}
