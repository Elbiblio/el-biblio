import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/app_providers.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../shared/widgets/light_rays_reveal.dart';
import '../../../../shared/widgets/skeleton_loader.dart';

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
      return const Padding(
        padding: EdgeInsets.only(bottom: 24),
        child: SkeletonLoader(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonText(width: 90, height: 12),
              SizedBox(height: 12),
              SkeletonCard(height: 140, borderRadius: 24),
            ],
          ),
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
                // Parse "John 3:16", "Psalm 23:1", "1 Corinthians 13:4",
                // "Song of Solomon 2:1", or "John 3:16-17". Book name may
                // include a leading numeral or multiple words.
                final reference = dailyVerse.reference.trim();
                final match = RegExp(
                  r'^((?:\d\s+)?[A-Za-z]+(?:\s+[A-Za-z]+)*)\s+(\d+):(\d+)(?:-\d+)?$',
                ).firstMatch(reference);
                if (match != null) {
                  final bookName = match.group(1)!;
                  final chapter = int.tryParse(match.group(2)!);
                  final verse = int.tryParse(match.group(3)!);
                  if (chapter != null && verse != null) {
                    context.push(
                      '${AppRoutes.bibleReader}?book=$bookName&chapter=$chapter&verse=$verse',
                    );
                  }
                }
              },
              borderRadius: BorderRadius.circular(24),
              child: Column(
                children: [
                  LightRaysReveal(
                    delay: const Duration(milliseconds: 250),
                    rayCount: 6,
                    maxOpacity: 0.25,
                    rotate: false,
                    child: Text(
                      '"${dailyVerse.text}"',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                        height: 1.6,
                        color: theme.colorScheme.onSurface,
                      ),
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
