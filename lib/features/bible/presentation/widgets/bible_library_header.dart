import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../application/bible_reading_notifier.dart';
import '../helpers/bible_library_helpers.dart' as helpers;

class BibleLibraryHeader extends StatelessWidget {
  const BibleLibraryHeader({
    super.key,
    required this.bibleReadingState,
    required this.searchController,
    required this.isSearching,
    required this.primaryColor,
    required this.surfaceColor,
    required this.textColor,
    required this.textMutedColor,
    required this.borderColor,
    required this.isDark,
    required this.onSettingsTap,
    required this.onSearchChanged,
    required this.onSearchCleared,
  });

  final BibleReadingState bibleReadingState;
  final TextEditingController searchController;
  final bool isSearching;
  final Color primaryColor;
  final Color surfaceColor;
  final Color textColor;
  final Color textMutedColor;
  final Color borderColor;
  final bool isDark;
  final VoidCallback onSettingsTap;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchCleared;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(LucideIcons.chevronLeft),
                tooltip: 'Back',
                color: textColor,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.2),
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Icon(LucideIcons.user, color: primaryColor),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            helpers.getMotivationalGreeting(bibleReadingState),
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: textColor,
                                  letterSpacing: -0.5,
                                ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            helpers.getMotivationalSubtitle(bibleReadingState),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: textMutedColor),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onSettingsTap,
                icon: Icon(LucideIcons.settings, color: textColor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search books, verses, or plans...',
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: textMutedColor,
                      fontSize: 15,
                    ),
                prefixIcon:
                    Icon(LucideIcons.search, color: textMutedColor, size: 20),
                suffixIcon: isSearching
                    ? IconButton(
                        icon: Icon(Icons.clear, color: textMutedColor, size: 20),
                        onPressed: onSearchCleared,
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
