import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/app_providers.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_theme_tokens.dart';

class DailyVerseCard extends ConsumerWidget {
  const DailyVerseCard({
    super.key,
    this.onReflect,
    this.onShare,
  });

  final VoidCallback? onReflect;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final verseState = ref.watch(verseProvider);
    final dailyVerse = verseState.todayVerse;
    final isLoading = verseState.isLoading;
    final error = verseState.error;

    if (isLoading) {
      return const SizedBox(
        height: 150,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (error != null || dailyVerse == null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error),
            const SizedBox(height: 8),
            Text(
              error ?? 'No verse available for today.',
              textAlign: TextAlign.center,
            ),
            if (error != null)
              TextButton(
                onPressed: () => ref.refresh(verseProvider),
                child: const Text('Retry'),
              ),
          ],
        ),
      );
    }

    final isDark = theme.brightness == Brightness.dark;
    final verseBackground = Color.alphaBlend(
      tokens.palette.primary.withValues(alpha: isDark ? 0.16 : 0.08),
      tokens.palette.paper,
    );
    final verseBorder = tokens.palette.primary.withValues(alpha: isDark ? 0.35 : 0.24);
    final verseReference = isDark ? tokens.palette.primaryLight : tokens.palette.primaryDark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DAILY VERSE',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              InkWell(
                onTap: onShare,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'Share',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: verseBackground,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: verseBorder,
              ),
            ),
            child: InkWell(
              onTap: () {
                // Navigate to the specific verse in Bible reader
                final reference = dailyVerse.reference;
                // Parse reference like "John 3:16" or "Psalm 23:1"
                final parts = reference.split(' ');
                if (parts.length >= 2) {
                  final bookName = parts[0];
                  final chapterVerse = parts[1];
                  final cvParts = chapterVerse.split(':');
                  if (cvParts.length == 2) {
                    final chapter = int.tryParse(cvParts[0]);
                    final verse = int.tryParse(cvParts[1]);
                    if (chapter != null && verse != null) {
                      context.push(
                        '${AppRoutes.bibleReader}?book=$bookName&chapter=$chapter&verse=$verse',
                      );
                    }
                  }
                }
              },
              borderRadius: BorderRadius.circular(24),
              child: Column(
                children: [
                  Text(
                    '"${dailyVerse.text}"',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                      height: 1.6,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.menu_book,
                        size: 16,
                        color: verseReference,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dailyVerse.reference,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: verseReference,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
