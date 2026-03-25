import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/di/app_providers.dart';

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

    return Container(
      decoration: BoxDecoration(
        color: isDark 
            ? const Color(0xFF101822).withValues(alpha: 0.85)
            : const Color(0xFFf6f7f8).withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle Indicator
                  Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 8),
                    height: 6,
                    width: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
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
                              'ELBIBLIO SPIRITUAL OS',
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
                        Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.withValues(alpha: 0.1),
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                          ),
                          child: Icon(
                            Icons.settings,
                            color: Colors.grey.shade400,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tool Tiles
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      children: [
                        // 1. Bible Tool Tile - Dynamic Daily Verse
                        _DailyVerseTile(),
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            // 2. Meditation Tool Tile
                            Expanded(
                              child: _SmallToolTile(
                                icon: Icons.self_improvement,
                                iconColor: Colors.teal.shade400,
                                title: 'Meditation',
                                subtitle: '5 min Virtue Breath',
                                actionText: 'Start Session',
                                actionIcon: Icons.play_arrow,
                                buttonColor: Colors.teal.shade500,
                                onTap: () {
                                  Navigator.pop(context);
                                  context.push(AppRoutes.meditation);
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            // 3. Journal Tool Tile
                            Expanded(
                              child: _SmallToolTile(
                                icon: Icons.edit_note,
                                iconColor: Theme.of(context).colorScheme.primary,
                                title: 'Journal',
                                subtitle: 'Reflect on Virtue',
                                actionText: 'New Entry',
                                actionIcon: Icons.add,
                                buttonColor: Theme.of(context).colorScheme.primary,
                                onTap: () {
                                  Navigator.pop(context);
                                  context.push('${AppRoutes.journal}/new');
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Spiritual First Aid Kit
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: _SmallToolTile(
                      icon: Icons.medical_services_rounded,
                      iconColor: Colors.red.shade400,
                      title: 'First Aid Kit',
                      subtitle: 'Spiritual Care',
                      actionText: 'Open Kit',
                      actionIcon: Icons.arrow_forward,
                      buttonColor: Colors.red.shade400,
                      onTap: () {
                        Navigator.pop(context);
                        context.push(AppRoutes.spiritualAid);
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Secondary Utilities
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _UtilityAction(
                          icon: Icons.notifications,
                          label: 'Reminders',
                          onTap: () {
                            Navigator.pop(context);
                            context.push('/profile/reminders');
                          },
                        ),
                        _UtilityAction(
                          icon: Icons.person,
                          label: 'Profile',
                          onTap: () {
                            Navigator.pop(context);
                            context.push(AppRoutes.profile);
                          },
                        ),
                        _UtilityAction(
                          icon: Icons.explore_rounded,
                          label: 'Alignment',
                          onTap: () {
                            Navigator.pop(context);
                            context.push('/alignment');
                          },
                        ),
                        _UtilityAction(
                          icon: Icons.more_horiz,
                          label: 'More',
                          onTap: () {
                            Navigator.pop(context);
                            context.push('/about');
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Footer Text
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Text(
                      'A life in harmony, spiritually and physically.\nCheck-in and grow daily.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.grey.shade500,
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
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
                        color: Colors.grey.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                      ),
                      child: const Center(child: Icon(Icons.menu_book, color: Colors.grey)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
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
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
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
                        color: Colors.grey.shade500,
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
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Icon(actionIcon, size: 16, color: Colors.white),
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

class _UtilityAction extends StatelessWidget {
  const _UtilityAction({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: Colors.grey.shade600, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
