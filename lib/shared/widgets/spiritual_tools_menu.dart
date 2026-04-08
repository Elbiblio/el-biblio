import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/di/app_providers.dart';
import '../../../core/theme/app_theme_tokens.dart';

class SpiritualToolsMenu extends ConsumerWidget {
  const SpiritualToolsMenu({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SpiritualToolsMenu(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Container(
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surface.withValues(alpha: 0.85)
            : theme.colorScheme.surface.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.5),
            blurRadius: 30,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle Indicator
                  Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 8),
                    height: 6,
                    width: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),

                  // Header Section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'QUICK ACTIONS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Spiritual Tools',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Tool Tiles
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      children: [
                        // 1. Daily Verse Tile - Dynamic
                        _DailyVerseTile(),
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            // 2. Quick Help Tool Tile (Soul Care)
                            Expanded(
                              child: _SmallToolTile(
                                icon: Icons.favorite_rounded,
                                iconColor: Colors.red.shade400,
                                title: 'Quick Help',
                                subtitle: 'Spiritual aid & prayers',
                                actionText: 'Open Hub',
                                actionIcon: Icons.arrow_forward,
                                buttonColor: Colors.red.shade400,
                                onTap: () {
                                  Navigator.pop(context);
                                  context.push(AppRoutes.spiritualAid);
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            // 3. Alignment Hub Tool Tile
                            Expanded(
                              child: _SmallToolTile(
                                icon: Icons.track_changes_rounded,
                                iconColor: tokens.palette.pillarIdentity ?? theme.colorScheme.primary,
                                title: 'Alignment',
                                subtitle: 'Habits & goals',
                                actionText: 'Open Hub',
                                actionIcon: Icons.arrow_forward,
                                buttonColor: tokens.palette.pillarIdentity ?? theme.colorScheme.primary,
                                onTap: () {
                                  Navigator.pop(context);
                                  context.push(AppRoutes.alignment);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            // 4. Faith Questions Tool Tile
                            Expanded(
                              child: _SmallToolTile(
                                icon: Icons.help_outline_rounded,
                                iconColor: Theme.of(context).colorScheme.primary,
                                title: 'Faith Q&A',
                                subtitle: 'Explore & learn',
                                actionText: 'Explore',
                                actionIcon: Icons.arrow_forward,
                                buttonColor: Theme.of(context).colorScheme.primary,
                                onTap: () {
                                  Navigator.pop(context);
                                  context.push(AppRoutes.faithQuestions);
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            // 5. Quick Prayer Tool Tile
                            Expanded(
                              child: _SmallToolTile(
                                icon: Icons.auto_awesome_rounded,
                                iconColor: Colors.purple.shade400,
                                title: 'Quick Prayer',
                                subtitle: 'Pray now',
                                actionText: 'Pray',
                                actionIcon: Icons.arrow_forward,
                                buttonColor: Colors.purple.shade400,
                                onTap: () {
                                  Navigator.pop(context);
                                  context.push('${AppRoutes.spiritualAid}/prayers');
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Footer Text
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Text(
                      'The world is noisy. Spiritual focus drives true purpose.\nElbiblio gives you that focus.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}

class _DailyVerseTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verseState = ref.watch(verseProvider);
    final dailyVerse = verseState.todayVerse;
    final isLoading = verseState.isLoading;
    final error = verseState.error;

    if (isLoading) {
      return _ToolTile(
        icon: Icons.menu_book,
        iconColor: Theme.of(context).colorScheme.primary,
        title: 'Verse of the Day',
        subtitle: 'Loading...',
        description: 'Fetching today\'s verse...',
        actionText: 'Open Scripture',
        onTap: () {
          Navigator.pop(context);
          context.push(AppRoutes.bible);
        },
      );
    }

    if (error != null || dailyVerse == null) {
      return _ToolTile(
        icon: Icons.menu_book,
        iconColor: Theme.of(context).colorScheme.primary,
        title: 'Verse of the Day',
        subtitle: 'Unavailable',
        description: 'Tap to retry loading today\'s verse.',
        actionText: 'Retry',
        onTap: () {
          // Retry loading the daily verse
          ref.read(verseProvider.notifier).loadDailyVerses();
        },
      );
    }

    return _ToolTile(
      icon: Icons.menu_book,
      iconColor: Theme.of(context).colorScheme.primary,
      title: 'Verse of the Day',
      subtitle: dailyVerse.displayReference,
      description: '"${dailyVerse.text}"',
      actionText: 'Open Scripture',
      onTap: () {
        Navigator.pop(context);
        // Navigate to the specific verse in Bible reader
        final reference = dailyVerse.referenceDisplay ?? dailyVerse.reference;
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
              return;
            }
          }
        }
        // Fallback to main Bible screen
        context.push(AppRoutes.bible);
      },
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.actionText,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String description;
  final String actionText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: iconColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(icon, color: iconColor, size: 20),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                title,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: iconColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              height: 1.5,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                      ),
                      child: Center(child: Icon(Icons.menu_book, color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        actionText,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios, size: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SmallToolTile extends StatelessWidget {
  const _SmallToolTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.actionText,
    required this.actionIcon,
    required this.buttonColor,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String actionText;
  final IconData actionIcon;
  final Color buttonColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: iconColor, size: 20),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: buttonColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        actionText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                      Icon(actionIcon, size: 16, color: theme.colorScheme.onPrimary),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
