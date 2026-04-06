import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/services/analytics/app_analytics_service.dart';
import '../application/bible_notifier.dart';
import '../domain/models/bible_content.dart';
import 'widgets/bible_verse_action_sheet.dart';
import 'widgets/bible_insight_sheet.dart';
import 'widgets/bible_search_delegate.dart';
import 'widgets/bible_settings_sheet.dart';
import 'widgets/bible_versions_sheet.dart';
import 'widgets/bible_compare_sheet.dart';
import 'widgets/all_insights_modal.dart';
import 'widgets/verse_note_modal.dart';
import 'widgets/compact_reading_plan_list.dart';
import 'widgets/bible_stats_sheet.dart';
import 'games/verse_game_screen.dart';

class BibleScreen extends ConsumerStatefulWidget {
  const BibleScreen({
    super.key,
    this.bookName,
    this.chapter,
    this.verse,
    this.isPlanMode = false,
  });
  
  final String? bookName;
  final int? chapter;
  final int? verse;
  final bool isPlanMode;
  
  @override
  ConsumerState<BibleScreen> createState() => _BibleScreenState();
}

class _BibleScreenState extends ConsumerState<BibleScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _hasNavigatedToVerse = false;
  Timer? _idleTimer;
  Timer? _scrollDebounceTimer;
  bool _showGameIcon = false;

  @override
  void initState() {
    super.initState();
    // Track Bible reading opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsProvider).track(AppAnalyticsEvent.bibleReadingOpened);
    });
    // Add scroll listener with debouncing to reset timer on scroll
    _scrollController.addListener(() {
      // Cancel existing debounce timer
      _scrollDebounceTimer?.cancel();
      
      // Set a new debounce timer to reset the idle timer after scrolling stops
      _scrollDebounceTimer = Timer(const Duration(milliseconds: 500), () {
        _resetIdleTimer();
      });
    });
    
    // Start the idle timer immediately when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resetIdleTimer();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollDebounceTimer?.cancel();
    _idleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bibleState = ref.watch(bibleProvider);
    final bibleNotifier = ref.read(bibleProvider.notifier);
    final theme = Theme.of(context);

    // Handle navigation to specific verse (scroll without highlighting)
    ref.listen(bibleProvider.select((s) => s.isLoading), (previous, next) {
      // Only reset idle timer when loading completes (not when it starts)
      // This prevents excessive timer resets during initial loading
      if (previous == true && next == false) {
        _resetIdleTimer();
      }
      
      // When loading completes and we have navigation parameters, navigate to the verse
      if (!next && previous == true && !_hasNavigatedToVerse) {
        if (widget.bookName != null && widget.chapter != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (widget.verse != null) {
              // Use scrollToVerse for specific verse navigation with focus mode
              bibleNotifier.scrollToVerse(
                widget.bookName!,
                widget.chapter!,
                widget.verse!,
              );
              // Set highlighted verse for focus mode
              bibleNotifier.setHighlightedVerse(widget.verse!);
            } else {
              // Use scrollToVerse for book/chapter navigation (no focus mode)
              bibleNotifier.scrollToVerse(
                widget.bookName!,
                widget.chapter!,
              );
            }
            _hasNavigatedToVerse = true;
          });
        }
      }
    });

    // Also handle case when verses are already loaded
    if (!_hasNavigatedToVerse && 
        !bibleState.isLoading && 
        bibleState.verses.isNotEmpty && 
        widget.bookName != null && 
        widget.chapter != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.verse != null) {
          // Use scrollToVerse for specific verse navigation with focus mode
          bibleNotifier.scrollToVerse(
            widget.bookName!,
            widget.chapter!,
            widget.verse!,
          );
          // Set highlighted verse for focus mode
          bibleNotifier.setHighlightedVerse(widget.verse!);
        } else {
          // Use scrollToVerse for book/chapter navigation (no focus mode)
          bibleNotifier.scrollToVerse(
            widget.bookName!,
            widget.chapter!,
          );
        }
        _hasNavigatedToVerse = true;
      });
    }

    // Handle scroll to verse functionality
    ref.listen(bibleProvider.select((s) => s.scrollToVerseId), (previous, next) {
      if (next != null && next != previous) {
        // Find the verse widget and scroll to it
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToVerse(next);
        });
      }
    });

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
          // Font size control
          IconButton(
            icon: const Icon(Icons.format_size),
            tooltip: 'Font Size',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => const BibleSettingsSheet(),
              );
            },
          ),
          // Reading stats icon (hidden when game icon appears)
          if (!_showGameIcon)
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
          // Verse game icon (appears after 5s idle)
          if (_showGameIcon)
            IconButton(
              icon: Icon(
                Icons.videogame_asset,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
              ),
              tooltip: 'Verse Game',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const VerseGameScreen(),
                  ),
                );
              },
            ),
        ],
      ),
      body: bibleState.isLoading && bibleState.verses.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
              onTap: () {
                // Clear highlighted verse if user taps outside verse items
                if (bibleState.highlightedVerseId != null) {
                  bibleNotifier.clearHighlightedVerse();
                }
                _resetIdleTimer(); // Reset timer on tap
              },
              onHorizontalDragEnd: (details) {
                _resetIdleTimer(); // Reset timer on swipe
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
                      Container(
                        margin: const EdgeInsets.all(8.0),
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: theme.colorScheme.error),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Error: ${bibleState.error}',
                                style: TextStyle(color: theme.colorScheme.error),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: bibleState.verses.isEmpty
                          ? _buildEmptyState(context)
                          : _buildVersesList(context, bibleState, bibleNotifier, theme),
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
          ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final bibleState = ref.watch(bibleProvider);
    
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          Icon(
            Icons.menu_book,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 16),
          Text(
            bibleState.currentBook == null 
              ? 'Select a book to begin reading'
              : 'No verses available',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          if (bibleState.currentBook != null && bibleState.currentVersion != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  Text(
                    'Trying to load: ${bibleState.currentBook!.name} ${bibleState.currentChapter}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version: ${bibleState.currentVersion!.name ?? bibleState.currentVersion!.abbreviation}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          if (bibleState.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              child: Column(
                children: [
                  Text(
                    'Unable to load verses',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bibleState.error!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try selecting a different version or check your internet connection',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          if (bibleState.isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text('Loading verses...'),
                ],
              ),
            ),
          if (!bibleState.isLoading && bibleState.error == null && bibleState.currentBook != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ElevatedButton(
                onPressed: () {
                  final notifier = ref.read(bibleProvider.notifier);
                  notifier.loadVerses();
                },
                child: const Text('Retry'),
              ),
            ),
        ],
      ),
    ),
    );
  }

  Widget _buildVersesList(BuildContext context, BibleState state, BibleNotifier notifier, ThemeData theme) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: state.verses.length + 1, // +1 for navigation footer
      itemBuilder: (context, index) {
        if (index == state.verses.length) {
          return _buildNavigationFooter(context, ref, state, notifier);
        }
        
        final verse = state.verses[index];
        return _buildVerseItem(context, verse, state, notifier, theme);
      },
    );
  }

  Widget _buildVerseItem(BuildContext context, BibleVerseContent verse, BibleState state, BibleNotifier notifier, ThemeData theme) {
    final isHighlightedVerse = verse.verse == state.highlightedVerseId;
    
    return InkWell(
      onTap: () => _showVerseActionSheet(context, verse, state, notifier),
      onLongPress: () => _showVerseActionSheet(context, verse, state, notifier),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        decoration: BoxDecoration(
          color: verse.isHighlighted 
              ? Colors.amber.withValues(alpha: 0.2) 
              : isHighlightedVerse
                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                  : Colors.transparent,
          border: verse.isBookmarked
              ? Border(left: BorderSide(color: theme.colorScheme.primary, width: 3))
              : isHighlightedVerse
                  ? Border(left: BorderSide(color: theme.colorScheme.primary, width: 4))
                  : null,
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.only(bottom: 12.0, top: 4.0, left: 4.0, right: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isHighlightedVerse) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'FOCUS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimary,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ],
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${verse.verse} ',
                    style: TextStyle(
                      fontSize: isHighlightedVerse ? 14 : 12,
                      fontWeight: FontWeight.bold,
                      color: isHighlightedVerse 
                          ? theme.colorScheme.primary
                          : theme.colorScheme.primary.withValues(alpha: 0.8),
                    ),
                  ),
                  TextSpan(
                    text: verse.text,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                      fontSize: isHighlightedVerse ? state.fontSize + 4 : state.fontSize,
                      fontWeight: isHighlightedVerse ? FontWeight.w500 : FontWeight.normal,
                      color: isHighlightedVerse 
                          ? theme.colorScheme.onSurface
                          : null,
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

  void _showVerseActionSheet(BuildContext context, BibleVerseContent verse, BibleState state, BibleNotifier notifier) {
    showModalBottomSheet(
      context: context,
      builder: (context) => BibleVerseActionSheet(
        verse: verse,
        onHighlight: () => notifier.toggleHighlight(verse.id),
        onBookmark: () => notifier.toggleBookmark(verse.id),
        onJournal: () {
          final reference = verse.reference ?? '${state.currentBook?.name} ${state.currentChapter}:${verse.verse}';
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
          notifier.compareVerses(verse.reference ?? '${state.currentBook?.abbreviation} ${state.currentChapter}:${verse.verse}');
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
            notifier.clearComparison();
          });
        },
        onAllInsights: () {
          final reference = verse.reference ?? '${state.currentBook?.name} ${state.currentChapter}:${verse.verse}';
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            backgroundColor: Colors.transparent,
            builder: (context) => Consumer(
              builder: (context, ref, child) {
                final bibleState = ref.watch(bibleProvider);
                return AllInsightsModal(
                  verseReference: reference,
                  insights: bibleState.insight != null ? [bibleState.insight!] : [],
                  isLoading: bibleState.isInsightLoading,
                );
              },
            ),
          ).whenComplete(() {
            // Optionally clear insight when modal closes
          });
        },
        onAddNote: () {
          final reference = verse.reference ?? '${state.currentBook?.name} ${state.currentChapter}:${verse.verse}';
          final existingNote = notifier.getVerseNote(verse.id);
          
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            backgroundColor: Colors.transparent,
            builder: (context) => VerseNoteModal(
              verseReference: reference,
              verseText: verse.text,
              existingNote: existingNote,
            ),
          ).then((result) {
            if (result != null && result is String) {
              if (result.isEmpty) {
                // Delete note
                notifier.deleteVerseNote(verse.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Note deleted')),
                  );
                }
              } else {
                // Save/update note
                notifier.saveVerseNote(verse.id, result);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Note saved')),
                  );
                }
              }
            }
          });
        },
        onLike: () {
          notifier.toggleLikeVerse(verse.id);
          if (context.mounted) {
            final isLiked = notifier.isVerseLiked(verse.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(isLiked ? 'Verse liked!' : 'Like removed')),
            );
          }
        },
        onShare: () async {
          final result = await notifier.shareVerse(verse.id);
          if (!context.mounted) return;
          
          if (result != null) {
            // Copy to clipboard for sharing
            await Clipboard.setData(ClipboardData(text: '${verse.text} (${verse.reference})'));
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Verse copied for sharing')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to share verse')),
            );
          }
        },
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
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                '${state.currentBook!.name} ${state.currentChapter}',
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
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
          // Only show "Mark Chapter as Read" button in plan mode
          if (widget.isPlanMode)
            Consumer(
              builder: (context, ref, child) {
                final readingState = ref.watch(bibleReadingProvider);
                if (readingState.isLoading) {
                  return const CircularProgressIndicator();
                }
                return FilledButton.icon(
                  onPressed: () {
                    ref.read(bibleReadingProvider.notifier).completeReading(
                      readingMode: 'plan',
                      planName: 'Reading Plan',
                      chaptersRead: ['${state.currentBook?.name} ${state.currentChapter}'],
                    ).then((_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text('Chapter marked as read! +15 XP'),
                              ],
                            ),
                            backgroundColor: Colors.green[600],
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    });
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Mark Chapter as Read (+15 XP)'),
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
              length: 3,
              initialIndex: 0, // NT is default (index 0)
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'New Testament'),
                      Tab(text: 'Old Testament'),
                      Tab(text: 'Reading Plans'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // New Testament Books
                        _buildBooksList(context, state, notifier, 'NT', scrollController),
                        // Old Testament Books
                        _buildBooksList(context, state, notifier, 'OT', scrollController),
                        // Reading Plans
                        const CompactReadingPlanList(),
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

  Widget _buildBooksList(BuildContext context, BibleState state, BibleNotifier notifier, String testament, ScrollController scrollController) {
    final filteredBooks = state.books.where((book) => book.testament == testament).toList();
    
    return Column(
      children: [
        // Chapters selector for selected book
        if (state.currentBook != null && state.currentBook!.testament == testament) ...[
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${state.currentBook!.name} - Chapters',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: GridView.builder(
                    controller: scrollController,
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 60,
                      childAspectRatio: 1,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
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
                ),
              ],
            ),
          ),
          const Divider(height: 1),
        ],
        // Books list
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: filteredBooks.length,
            itemBuilder: (context, index) {
              final book = filteredBooks[index];
              final isSelected = book.id == state.currentBook?.id;
              return ListTile(
                title: Text(book.name),
                selected: isSelected,
                trailing: isSelected ? const Icon(Icons.check) : null,
                onTap: () {
                  notifier.selectBook(book);
                  // Keep the same tab open to show chapters
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _scrollToVerse(int verseNumber) {
    // Find the verse in the list and scroll to it
    final bibleState = ref.read(bibleProvider);
    final targetVerseIndex = bibleState.verses.indexWhere(
      (verse) => verse.verse == verseNumber,
    );
    
    if (targetVerseIndex != -1) {
      // Calculate the scroll position (estimated item height)
      const estimatedItemHeight = 80.0;
      final targetScrollOffset = targetVerseIndex * estimatedItemHeight;
      
      // Scroll to the verse with some padding
      _scrollController.animateTo(
        targetScrollOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _resetIdleTimer() {
    // Cancel existing timer
    _idleTimer?.cancel();
    
    // Hide game icon immediately
    if (mounted) {
      setState(() {
        _showGameIcon = false;
      });
    }
    
    // Start new 5-second timer
    _idleTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showGameIcon = true;
        });
      }
    });
  }
}
