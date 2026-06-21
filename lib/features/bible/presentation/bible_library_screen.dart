import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/ambient_scope.dart';
import '../../../shared/domain/models/activity.dart';
import '../../bible/application/bible_notifier.dart';
import '../../bible/domain/models/bible_content.dart';
import '../../bible/domain/models/reading_plan.dart';
import '../../bible/data/book_cache.dart';
import '../../../../shared/widgets/safe_bottom_padding.dart';
import 'helpers/bible_library_helpers.dart' as helpers;
import 'widgets/compact_plan_card.dart';
import 'widgets/tab_button.dart';
import 'widgets/recent_location_chip.dart';
import 'widgets/library_options_sheet.dart';
import 'widgets/reading_plan_setup_sheet.dart';
import 'widgets/continue_reading_card.dart';
import 'widgets/bible_library_header.dart';

class BibleLibraryScreen extends ConsumerStatefulWidget {
  const BibleLibraryScreen({super.key});

  @override
  ConsumerState<BibleLibraryScreen> createState() => _BibleLibraryScreenState();
}

class _BibleLibraryScreenState extends ConsumerState<BibleLibraryScreen> {
  String _selectedTab = 'NT';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _initializeScreenData();
  }

  Future<void> _initializeScreenData() async {
    try {
      BookCache.preloadCache();
      await ref.read(bibleProvider.notifier).loadInitialData();
      if (ref.read(bibleReadingProvider).history.isEmpty) {
        await ref.read(bibleReadingProvider.notifier).loadHistory();
      }
    } catch (e) {
      debugPrint('Error initializing screen data: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final bibleState = ref.watch(bibleProvider);
    final bibleReadingState = ref.watch(bibleReadingProvider);
    final readingPlanState = ref.watch(readingPlanProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final textMutedColor = isDark ? Colors.white54 : const Color(0xFF666666);
    final borderColor = isDark
        ? Colors.white10
        : Colors.black.withValues(alpha: 0.05);

    return AmbientScope(
      asset: SoundService.ambientBibleAsset,
      volume: 0.08,
      child: Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: SafeCustomScrollView(
          bottomPadding: shellChromeBottomPadding,
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: BibleLibraryHeader(
                bibleReadingState: bibleReadingState,
                searchController: _searchController,
                isSearching: _isSearching,
                primaryColor: primaryColor,
                surfaceColor: surfaceColor,
                textColor: textColor,
                textMutedColor: textMutedColor,
                borderColor: borderColor,
                isDark: isDark,
                onSettingsTap: () => LibraryOptionsSheet.show(
                  context,
                  onOpenReading: (activity) =>
                      _openLastReading(context, ref, activity),
                ),
                onSearchChanged: (value) {
                  setState(() {
                    if (value.isNotEmpty) {
                      _isSearching = true;
                      _performSearch(value);
                    } else {
                      _isSearching = false;
                      ref.read(bibleProvider.notifier).clearSearch();
                    }
                  });
                },
                onSearchCleared: () {
                  _searchController.clear();
                  setState(() => _isSearching = false);
                  ref.read(bibleProvider.notifier).clearSearch();
                },
              ),
            ),

            // Search Results
            if (_isSearching)
              _buildSearchResults(
                context,
                bibleState,
                surfaceColor,
                textColor,
                textMutedColor,
                borderColor,
              ),

            // Main content
            if (!_isSearching)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 8),
                    // Continue Reading
                    ContinueReadingCard(
                      isLoading: bibleReadingState.isLoading,
                      history: List<Activity>.from(bibleReadingState.history),
                      primaryColor: primaryColor,
                      surfaceColor: surfaceColor,
                      textColor: textColor,
                      textMutedColor: textMutedColor,
                      borderColor: borderColor,
                      onOpenReading: (activity) =>
                          _openLastReading(context, ref, activity),
                      onStartReading: () => ReadingPlanSetupSheet.show(context),
                    ),
                    const SizedBox(height: 32),
                    // Library Tabs
                    _buildLibraryTabs(
                      context,
                      isDark,
                      primaryColor,
                      textMutedColor,
                    ),
                    const SizedBox(height: 16),
                    _buildTabContent(
                      context,
                      bibleState,
                      isDark,
                      surfaceColor,
                      textColor,
                      textMutedColor,
                      borderColor,
                      primaryColor,
                    ),
                    const SizedBox(height: 32),
                    // Your Reading Plans
                    _buildReadingPlansSection(
                      context,
                      readingPlanState,
                      isDark,
                      surfaceColor,
                      textColor,
                      textMutedColor,
                      borderColor,
                      primaryColor,
                    ),
                    const SizedBox(height: 32),
                    // Recent Locations
                    _buildRecentLocations(
                      context,
                      bibleReadingState,
                      isDark,
                      surfaceColor,
                      textMutedColor,
                      borderColor,
                    ),
                  ]),
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildSearchResults(
    BuildContext context,
    BibleState bibleState,
    Color surfaceColor,
    Color textColor,
    Color textMutedColor,
    Color borderColor,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          const SizedBox(height: 16),
          Text(
            'Search Results',
            style: Theme.of(
              context,
            ).textTheme.cardTitle.copyWith(color: textColor),
          ),
          const SizedBox(height: 12),
          if (bibleState.isSearching)
            const Center(child: CircularProgressIndicator())
          else if (bibleState.searchResults.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.search_off, color: textMutedColor, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'No results found',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: textMutedColor),
                  ),
                ],
              ),
            )
          else
            ...bibleState.searchResults.map(
              (verse) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: ListTile(
                  dense: true,
                  title: Text(
                    verse.text,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: textColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    verse.reference ??
                        'Chapter ${verse.chapter}:${verse.verse}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: textMutedColor),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: textMutedColor,
                    size: 20,
                  ),
                  onTap: () => _navigateToSearchResult(verse, bibleState),
                ),
              ),
            ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Library Tabs
  // ---------------------------------------------------------------------------

  Widget _buildLibraryTabs(
    BuildContext context,
    bool isDark,
    Color primaryColor,
    Color textMutedColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Library',
          style: Theme.of(context).textTheme.sectionHeader.copyWith(
            color: textMutedColor,
            letterSpacing: 1.2,
          ),
        ),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.grey.shade800
                : const Color(0xFFE8E4D9).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              TabButton(
                text: 'NT',
                isSelected: _selectedTab == 'NT',
                onTap: () => setState(() => _selectedTab = 'NT'),
                isDark: isDark,
                primaryColor: primaryColor,
              ),
              TabButton(
                text: 'OT',
                isSelected: _selectedTab == 'OT',
                onTap: () => setState(() => _selectedTab = 'OT'),
                isDark: isDark,
                primaryColor: primaryColor,
              ),
              TabButton(
                text: 'Reading Plans',
                isSelected: _selectedTab == 'Reading Plans',
                onTap: () => setState(() => _selectedTab = 'Reading Plans'),
                isDark: isDark,
                primaryColor: primaryColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabContent(
    BuildContext context,
    BibleState bibleState,
    bool isDark,
    Color surfaceColor,
    Color textColor,
    Color textMutedColor,
    Color borderColor,
    Color primaryColor,
  ) {
    switch (_selectedTab) {
      case 'OT':
        return _buildBooksList(
          context,
          'OT',
          surfaceColor,
          textColor,
          textMutedColor,
          borderColor,
        );
      case 'NT':
        return _buildBooksList(
          context,
          'NT',
          surfaceColor,
          textColor,
          textMutedColor,
          borderColor,
        );
      case 'Reading Plans':
      default:
        return _buildReadingPlansList(
          context,
          isDark,
          surfaceColor,
          textColor,
          textMutedColor,
          borderColor,
          primaryColor,
        );
    }
  }

  Widget _buildBooksList(
    BuildContext context,
    String testament,
    Color surfaceColor,
    Color textColor,
    Color textMutedColor,
    Color borderColor,
  ) {
    final staticBooks = testament == 'OT'
        ? BookCache.getOldTestamentBooks()
        : BookCache.getNewTestamentBooks();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: staticBooks.length,
      itemBuilder: (context, index) {
        final book = staticBooks[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: ListTile(
            dense: true,
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  book.abbreviation,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            title: Text(
              book.name,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: textColor),
            ),
            subtitle: Text(
              '${book.chapters} chapters',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: textMutedColor),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: textMutedColor,
              size: 20,
            ),
            onTap: () {
              ref
                  .read(bibleReadingProvider.notifier)
                  .trackReadingLocation(
                    bookName: book.name,
                    chapter: 1,
                    testament: book.testament,
                  );
              context.push(
                '${AppRoutes.bibleReader}?book=${Uri.encodeComponent(book.name)}&chapter=1&fromLibrary=true',
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildReadingPlansList(
    BuildContext context,
    bool isDark,
    Color surfaceColor,
    Color textColor,
    Color textMutedColor,
    Color borderColor,
    Color primaryColor,
  ) {
    final readingPlanState = ref.watch(readingPlanProvider);

    return Column(
      children: [
        if (readingPlanState.activePlans.isNotEmpty) ...[
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              children: readingPlanState.activePlans.map((plan) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: CompactPlanCard(
                    title: plan.plan?.title ?? 'Reading Plan',
                    subtitle:
                        'Day ${plan.currentDay} of ${plan.plan?.durationDays ?? 30}',
                    virtue: helpers.getVirtueFromPlan(plan.plan),
                    virtueColor: helpers.getVirtueColor(plan.plan?.themeId),
                    progress: helpers.calculatePlanProgress(
                      plan.currentDay,
                      plan.plan?.durationDays,
                    ),
                    isDark: isDark,
                    surfaceColor: surfaceColor,
                    textColor: textColor,
                    textMutedColor: textMutedColor,
                    borderColor: borderColor,
                    imageGradientColors: helpers.getGradientColors(
                      plan.plan?.themeId,
                    ),
                    onTap: plan.plan == null
                        ? null
                        : () {
                            ref.read(soundServiceProvider).playPageTurn();
                            context.push(
                              '${AppRoutes.biblePlanDetails}/${plan.plan!.id}',
                            );
                          },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],
        ...readingPlanState.plans.map((plan) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: ListTile(
              dense: true,
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: helpers.getGradientColors(plan.themeId),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    helpers.getVirtueFromPlan(plan),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              title: Text(
                plan.title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(color: textColor),
              ),
              subtitle: Text(
                '${plan.durationDays} days - ${plan.description ?? 'Bible reading plan'}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: textMutedColor),
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: textMutedColor,
                size: 20,
              ),
              onTap: () =>
                  context.push('${AppRoutes.biblePlanDetails}/${plan.id}'),
            ),
          );
        }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Reading Plans + Recent Locations sections
  // ---------------------------------------------------------------------------

  Widget _buildReadingPlansSection(
    BuildContext context,
    dynamic readingPlanState,
    bool isDark,
    Color surfaceColor,
    Color textColor,
    Color textMutedColor,
    Color borderColor,
    Color primaryColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Reading Plans',
              style: Theme.of(
                context,
              ).textTheme.cardTitle.copyWith(color: textColor),
            ),
            TextButton(
              onPressed: () => setState(() => _selectedTab = 'Reading Plans'),
              style: TextButton.styleFrom(
                foregroundColor: primaryColor,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'View All',
                style: Theme.of(context).textTheme.buttonText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: readingPlanState.isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Loading reading plans...',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: textMutedColor),
                      ),
                    ],
                  ),
                )
              : readingPlanState.activePlans.isNotEmpty
              ? ListView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  children: readingPlanState.activePlans.map<Widget>((plan) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: CompactPlanCard(
                        title: plan.plan?.title ?? 'Reading Plan',
                        subtitle:
                            'Day ${plan.currentDay} of ${plan.plan?.durationDays ?? 30}',
                        virtue: helpers.getVirtueFromPlan(plan.plan),
                        virtueColor: helpers.getVirtueColor(plan.plan?.themeId),
                        progress: helpers.calculatePlanProgress(
                          plan.currentDay,
                          plan.plan?.durationDays,
                        ),
                        isDark: isDark,
                        surfaceColor: surfaceColor,
                        textColor: textColor,
                        textMutedColor: textMutedColor,
                        borderColor: borderColor,
                        imageGradientColors: helpers.getGradientColors(
                          plan.plan?.themeId,
                        ),
                        onTap: () {
                          ref.read(soundServiceProvider).playPageTurn();
                          _navigateToPlanReading(context, plan);
                        },
                      ),
                    );
                  }).toList(),
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.calendar,
                        color: textMutedColor,
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No active plans',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: textMutedColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Explore plans to begin',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: textMutedColor),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildRecentLocations(
    BuildContext context,
    dynamic bibleReadingState,
    bool isDark,
    Color surfaceColor,
    Color textMutedColor,
    Color borderColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Locations',
          style: Theme.of(context).textTheme.sectionHeader.copyWith(
            color: textMutedColor,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: bibleReadingState.history.isNotEmpty
              ? Row(
                  children: (bibleReadingState.history as List)
                      .take(5)
                      .map<Widget>((activity) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: RecentLocationChip(
                            text: helpers.getLocationFromActivity(
                              activity as Activity,
                            ),
                            onTap: () =>
                                _openLastReading(context, ref, activity),
                            isDark: isDark,
                            surfaceColor: surfaceColor,
                            borderColor: borderColor,
                          ),
                        );
                      })
                      .toList(),
                )
              : Row(
                  children: [
                    RecentLocationChip(
                      text: 'No recent reading',
                      isDark: isDark,
                      surfaceColor: surfaceColor,
                      borderColor: borderColor,
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Navigation helpers
  // ---------------------------------------------------------------------------

  void _openLastReading(
    BuildContext context,
    WidgetRef ref,
    Activity activity,
  ) {
    final info = helpers.extractReadingInfo(activity);
    final bookName = info['book'] as String;
    final chapter = info['chapter'] as int;
    final verse = info['verse'] as int?;
    final isFromPlan =
        activity.metadata?['reading_mode'] == 'plan' ||
        activity.metadata?['plan_name'] != null;

    String location = AppRoutes.bibleReader;
    if (bookName.isNotEmpty) {
      location += '?book=${Uri.encodeComponent(bookName)}';
      location += '&chapter=$chapter';
      if (verse != null) location += '&verse=$verse';
      if (isFromPlan) location += '&planMode=true';
    }
    context.push(location);
  }

  void _navigateToPlanReading(BuildContext context, dynamic plan) {
    String book = 'Genesis';
    int chapter = 1;

    if (plan is UserReadingPlan) {
      final days = plan.plan?.days ?? const <ReadingPlanDay>[];
      if (days.isNotEmpty) {
        final dayIndex = (plan.currentDay - 1)
            .clamp(0, days.length - 1)
            .toInt();
        final verses = days[dayIndex].verses;
        if (verses.isNotEmpty) {
          final parsed = helpers.parseReference(verses.first);
          book = (parsed['book'] as String?) ?? book;
          chapter = (parsed['chapter'] as int?) ?? chapter;
        }
      }
    }

    context.push(
      '${AppRoutes.bibleReader}?book=${Uri.encodeComponent(book)}&chapter=$chapter&planMode=true',
    );
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;
    ref.read(bibleProvider.notifier).search(query.trim());
  }

  void _navigateToSearchResult(BibleVerseContent verse, BibleState bibleState) {
    final ref = verse.reference;
    if (ref != null && bibleState.books.isNotEmpty) {
      final book = bibleState.books.firstWhere(
        (b) => ref.startsWith(b.name) || ref.startsWith(b.abbreviation),
        orElse: () => bibleState.books.first,
      );
      final parts = ref.split(' ');
      if (parts.length >= 2) {
        final cvParts = parts.last.split(':');
        if (cvParts.length == 2) {
          final chapter = int.tryParse(cvParts[0]) ?? verse.chapter;
          final verseNum = int.tryParse(cvParts[1]) ?? verse.verse;
          context.push(
            '${AppRoutes.bibleReader}?book=${Uri.encodeComponent(book.name)}&chapter=$chapter&verse=$verseNum',
          );
          return;
        }
      }
    }

    final fallbackReference = ref != null ? helpers.parseReference(ref) : null;
    final fallbackBook = fallbackReference?['book'] as String?;
    final fallbackChapter =
        fallbackReference?['chapter'] as int? ?? verse.chapter;
    final fallbackVerse = fallbackReference?['verse'] as int? ?? verse.verse;
    context.push(
      '${AppRoutes.bibleReader}?${fallbackBook != null && fallbackBook.isNotEmpty ? 'book=${Uri.encodeComponent(fallbackBook)}&' : ''}chapter=$fallbackChapter&verse=$fallbackVerse',
    );
  }
}
