import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../application/bible_notifier.dart';
import 'widgets/bible_verse_action_sheet.dart';
import 'widgets/bible_insight_sheet.dart';
import 'widgets/bible_search_delegate.dart';
import 'widgets/bible_settings_sheet.dart';
import 'widgets/bible_versions_sheet.dart';
import 'widgets/bible_compare_sheet.dart';
import 'widgets/bible_stats_sheet.dart';

class BibleScreen extends ConsumerWidget {
  const BibleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bibleState = ref.watch(bibleProvider);
    final bibleNotifier = ref.read(bibleProvider.notifier);
    final theme = Theme.of(context);

    // Listen for insights loaded to show the sheet
    ref.listen(bibleProvider.select((s) => s.insight), (previous, next) {
      if (next != null && next != previous) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder: (context) => BibleInsightSheet(
            insight: next,
            verseReference: '${bibleState.currentBook?.name} ${bibleState.currentChapter}:${bibleState.verses.firstWhere((v) => v.id.toString() == bibleState.insight?.reference || true).verse}', // Approximate reference if not provided
          ),
        ).whenComplete(() {
          bibleNotifier.clearInsight();
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: _buildTitleSelector(context, bibleState, bibleNotifier),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Reading Stats',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (context) => const BibleStatsSheet(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.translate),
            tooltip: 'Versions',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (context) => const BibleVersionsSheet(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: BibleSearchDelegate(ref),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => const BibleSettingsSheet(),
              );
            },
          ),
        ],
      ),
      body: bibleState.isLoading && bibleState.verses.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity == null) return;
                final velocity = details.primaryVelocity!;
                if (velocity.abs() < 300) return; 

                if (velocity > 0) {
                  // Swipe Right -> Previous
                  if (bibleState.currentChapter > 1 || 
                      (bibleState.currentBook != null && bibleState.books.indexOf(bibleState.currentBook!) > 0)) {
                    HapticFeedback.lightImpact();
                    bibleNotifier.previousChapter();
                  }
                } else {
                   // Swipe Left -> Next
                   HapticFeedback.lightImpact();
                   bibleNotifier.nextChapter();
                }
              },
              child: Stack(
                children: [
                  Column(
                  children: [
                    if (bibleState.error != null)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Error: ${bibleState.error}',
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                    Expanded(
                      child: bibleState.verses.isEmpty
                          ? const Center(child: Text('Select a book and chapter'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: bibleState.verses.length + 1, // +1 for navigation footer
                              itemBuilder: (context, index) {
                                if (index == bibleState.verses.length) {
                                  return _buildNavigationFooter(context, ref, bibleState, bibleNotifier);
                                }
                                
                                final verse = bibleState.verses[index];
                                return InkWell(
                                  onLongPress: () {
                                    showModalBottomSheet(
                                      context: context,
                                      builder: (context) => BibleVerseActionSheet(
                                        verse: verse,
                                        onHighlight: () => bibleNotifier.toggleHighlight(verse.id),
                                        onBookmark: () => bibleNotifier.toggleBookmark(verse.id),
                                        onInsight: () => bibleNotifier.getInsight(verse.id),
                                        onJournal: () {
                                          final reference = verse.reference ?? '${bibleState.currentBook?.name} ${bibleState.currentChapter}:${verse.verse}';
                                          context.push(
                                            '${AppRoutes.journal}/new',
                                            extra: {
                                              'initialTitle': 'Reflection on $reference',
                                              'initialText': '"${verse.text}"\n\n$reference\n\n',
                                              'initialVirtues': <String>[],
                                            },
                                          );
                                        },
                                        onCompare: () {
                                          bibleNotifier.compareVerses(verse.reference ?? '${bibleState.currentBook?.abbreviation} ${bibleState.currentChapter}:${verse.verse}');
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            useSafeArea: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (context) => Consumer(
                                              builder: (context, ref, child) {
                                                final currentCompareState = ref.watch(bibleProvider);
                                                return BibleCompareSheet(
                                                  reference: verse.reference ?? 'Verse',
                                                  results: currentCompareState.comparisonResults,
                                                  isLoading: currentCompareState.isComparing,
                                                );
                                              },
                                            ),
                                          ).whenComplete(() {
                                            bibleNotifier.clearComparison();
                                          });
                                        },
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(4),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: verse.isHighlighted 
                                          ? Colors.amber.withValues(alpha: 0.2) 
                                          : Colors.transparent,
                                      border: verse.isBookmarked
                                          ? Border(left: BorderSide(color: theme.colorScheme.primary, width: 3))
                                          : null,
                                    ),
                                    padding: const EdgeInsets.only(bottom: 12.0, top: 4.0, left: 4.0, right: 4.0),
                                    child: Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text: '${verse.verse} ',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
                                            ),
                                          ),
                                          TextSpan(
                                            text: verse.text,
                                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                  height: 1.6,
                                                  fontSize: bibleState.fontSize,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
                if (bibleState.isInsightLoading)
                  Container(
                    color: Colors.black26,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Generating insight...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildTitleSelector(BuildContext context, BibleState state, BibleNotifier notifier) {
    if (state.currentBook == null) {
      return const Text('Bible');
    }
    
    return GestureDetector(
      onTap: () {
        _showBookChapterSelector(context, state, notifier);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${state.currentBook!.name} ${state.currentChapter}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationFooter(BuildContext context, WidgetRef ref, BibleState state, BibleNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        children: [
          Consumer(
            builder: (context, ref, child) {
              final readingState = ref.watch(bibleReadingProvider);
              if (readingState.isLoading) {
                return const CircularProgressIndicator();
              }
              return FilledButton.icon(
                onPressed: () {
                  ref.read(bibleReadingProvider.notifier).completeReading(
                    readingMode: 'plain',
                    planName: 'Free Reading',
                    chaptersRead: ['${state.currentBook?.name} ${state.currentChapter}'],
                  ).then((_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Chapter marked as read!')),
                      );
                    }
                  });
                },
                icon: const Icon(Icons.check),
                label: const Text('Mark Chapter as Read'),
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton.icon(
                onPressed: () => notifier.previousChapter(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Prev'),
              ),
              OutlinedButton.icon(
                onPressed: () => notifier.nextChapter(),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBookChapterSelector(BuildContext context, BibleState state, BibleNotifier notifier) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Books'),
                      Tab(text: 'Chapters'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Books List
                        ListView.builder(
                          controller: scrollController,
                          itemCount: state.books.length,
                          itemBuilder: (context, index) {
                            final book = state.books[index];
                            final isSelected = book.id == state.currentBook?.id;
                            return ListTile(
                              title: Text(book.name),
                              selected: isSelected,
                              trailing: isSelected ? const Icon(Icons.check) : null,
                              onTap: () {
                                notifier.selectBook(book);
                                // Animate to chapters tab
                                DefaultTabController.of(context).animateTo(1);
                              },
                            );
                          },
                        ),
                        // Chapters Grid
                        state.currentBook == null
                            ? const Center(child: Text('Select a book first'))
                            : GridView.builder(
                                controller: scrollController,
                                padding: const EdgeInsets.all(16),
                                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 60,
                                  childAspectRatio: 1,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                                itemCount: state.currentBook!.chapters ?? 50,
                                itemBuilder: (context, index) {
                                  final chapter = index + 1;
                                  final isSelected = chapter == state.currentChapter;
                                  return InkWell(
                                    onTap: () {
                                      notifier.selectChapter(chapter);
                                      Navigator.pop(context);
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Theme.of(context).colorScheme.primaryContainer
                                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(8),
                                        border: isSelected
                                            ? Border.all(color: Theme.of(context).colorScheme.primary)
                                            : null,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '$chapter',
                                        style: TextStyle(
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: isSelected
                                              ? Theme.of(context).colorScheme.primary
                                              : Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
