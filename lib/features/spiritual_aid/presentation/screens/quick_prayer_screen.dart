import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/tts_service.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../application/spiritual_aid_notifier.dart';
import '../../domain/models/quick_prayer.dart';
import '../widgets/category_chips.dart';
import '../widgets/prayer_card.dart';
import '../widgets/verse_reveal_animation.dart';

class QuickPrayerScreen extends ConsumerStatefulWidget {
  const QuickPrayerScreen({super.key});

  @override
  ConsumerState<QuickPrayerScreen> createState() => _QuickPrayerScreenState();
}

class _QuickPrayerScreenState extends ConsumerState<QuickPrayerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _ttsService = TTSService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _ttsService.initialize();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(spiritualAidProvider.notifier).loadPrayers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ttsService.stop();
    _ttsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(spiritualAidProvider);
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: tokens.pageGradient,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 24, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Quick Prayers',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Tabs
              TabBar(
                controller: _tabController,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurface.withValues(
                  alpha: 0.5,
                ),
                indicatorSize: TabBarIndicatorSize.label,
                dividerHeight: 0,
                tabs: const [
                  Tab(text: 'All Prayers'),
                  Tab(text: 'Favorites'),
                  Tab(text: 'History'),
                ],
              ),
              const SizedBox(height: 8),

              // Category filter
              CategoryChips(
                categories: QuickPrayer.categories,
                selected: state.activePrayerCategory,
                onSelected: (cat) {
                  ref
                      .read(spiritualAidProvider.notifier)
                      .filterPrayersByCategory(cat);
                },
              ),
              const SizedBox(height: 8),

              // Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPrayerList(state.prayers),
                    _buildPrayerList(state.favoritePrayers),
                    _buildPrayerList(state.prayerHistory),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrayerList(List<QuickPrayer> prayers) {
    if (prayers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.church_rounded,
              size: 48,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'No prayers found',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      itemCount: prayers.length,
      itemBuilder: (context, index) {
        final prayer = prayers[index];
        return PrayerCard(
          prayer: prayer,
          onFavoriteToggle: () {
            ref.read(spiritualAidProvider.notifier).toggleFavorite(prayer.id);
          },
          onTTSPlay: () {
            _ttsService.speak(prayer.body);
            ref
                .read(spiritualAidProvider.notifier)
                .addPrayerToHistory(prayer.id);
          },
          onPrayWithMe: () => _showPrayWithMe(prayer),
        );
      },
    );
  }

  void _showPrayWithMe(QuickPrayer prayer) {
    ref.read(spiritualAidProvider.notifier).addPrayerToHistory(prayer.id);

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _PrayWithMeSheet(prayer: prayer, ttsService: _ttsService),
    );
  }
}

class _PrayWithMeSheet extends StatefulWidget {
  const _PrayWithMeSheet({required this.prayer, required this.ttsService});

  final QuickPrayer prayer;
  final TTSService ttsService;

  @override
  State<_PrayWithMeSheet> createState() => _PrayWithMeSheetState();
}

class _PrayWithMeSheetState extends State<_PrayWithMeSheet> {
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    // Also read aloud
    widget.ttsService.speak(widget.prayer.body, speechRate: 0.6);
  }

  @override
  void dispose() {
    widget.ttsService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Handle
              Container(
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                widget.prayer.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Follow along as the prayer unfolds...',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 32),

              // Prayer text with word-by-word reveal
              Expanded(
                child: SingleChildScrollView(
                  child: VerseRevealAnimation(
                    text: widget.prayer.body,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.8,
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                    ),
                    wordDuration: const Duration(milliseconds: 180),
                    onComplete: () {
                      if (mounted) setState(() => _isComplete = true);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Amen button
              AnimatedOpacity(
                opacity: _isComplete ? 1.0 : 0.3,
                duration: const Duration(milliseconds: 400),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isComplete
                        ? () => Navigator.of(context).pop()
                        : null,
                    child: const Text('Amen'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
