import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/app_providers.dart';
import 'bible_streak_card.dart';

class BibleStatsSheet extends ConsumerStatefulWidget {
  const BibleStatsSheet({super.key});

  @override
  ConsumerState<BibleStatsSheet> createState() => _BibleStatsSheetState();
}

class _BibleStatsSheetState extends ConsumerState<BibleStatsSheet> {
  @override
  void initState() {
    super.initState();
    // Load history when sheet opens
    Future.microtask(() => 
      ref.read(bibleReadingProvider.notifier).loadHistory()
    );
  }

  @override
  Widget build(BuildContext context) {
    final readingState = ref.watch(bibleReadingProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.bar_chart, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Reading Stats',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    const BibleStreakCard(),
                    const SizedBox(height: 24),
                    Text(
                      'Recent History',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (readingState.isLoading && readingState.history.isEmpty)
                      const Center(child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ))
                    else if (readingState.history.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No reading history yet. Start reading today!'),
                        ),
                      )
                    else
                      ...readingState.history.map((activity) {
                        final date = activity.createdAt;
                        final metadata = activity.metadata ?? {};
                        final plan = metadata['plan_name']?.toString() ?? 'Bible Reading';
                        final chapters = metadata['chapters_read'];
                        String chaptersStr = '';
                        if (chapters is List) {
                          chaptersStr = chapters.join(', ');
                        } else if (chapters is String) {
                          chaptersStr = chapters;
                        }

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            child: Icon(Icons.menu_book, size: 16, color: Theme.of(context).colorScheme.primary),
                          ),
                          title: Text(plan),
                          subtitle: Text(chaptersStr.isNotEmpty ? chaptersStr : 'Reading completed'),
                          trailing: Text(
                            DateFormat('MMM d').format(date),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
