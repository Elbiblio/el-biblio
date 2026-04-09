import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../../../commitments/domain/models/commitment_journey.dart';

/// Section on TodayScreen showing the active commitment journey.
///
/// Shows today's requirement with clickable Bible references and allows
/// check-in at any time (not just evening). The journey task is always
/// visible and actionable.
class JourneyCheckInSection extends ConsumerWidget {
  const JourneyCheckInSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journeyState = ref.watch(commitmentJourneyProvider);

    if (journeyState.activeJourney == null) {
      return const SizedBox.shrink();
    }

    final activeJourney = journeyState.activeJourney!;

    return FutureBuilder<CommitmentJourney>(
      future: ref.read(commitmentJourneyProvider.notifier).getCurrentJourneyDetails(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final journey = snapshot.data!;
        final alreadyCheckedIn = activeJourney.completedDays.contains(activeJourney.currentDay);
        final todayRequirement = journey.requirementForDay(activeJourney.currentDay);

        return _JourneyTaskCard(
          journey: journey,
          activeJourney: activeJourney,
          todayRequirement: todayRequirement,
          alreadyCheckedIn: alreadyCheckedIn,
          onCheckIn: () => _handleCheckIn(ref),
        );
      },
    );
  }

  Future<void> _handleCheckIn(WidgetRef ref) async {
    await ref.read(commitmentJourneyProvider.notifier).checkInToday();
  }
}

/// Unified journey task card that shows today's requirement and allows check-in.
class _JourneyTaskCard extends ConsumerWidget {
  const _JourneyTaskCard({
    required this.journey,
    required this.activeJourney,
    required this.todayRequirement,
    required this.alreadyCheckedIn,
    required this.onCheckIn,
  });

  final CommitmentJourney journey;
  final ActiveJourney activeJourney;
  final String todayRequirement;
  final bool alreadyCheckedIn;
  final VoidCallback onCheckIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: alreadyCheckedIn
            ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.3)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: alreadyCheckedIn
              ? theme.colorScheme.secondary.withValues(alpha: 0.3)
              : theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                alreadyCheckedIn ? Icons.check_circle : Icons.route_rounded,
                size: 18,
                color: alreadyCheckedIn
                    ? theme.colorScheme.secondary
                    : theme.colorScheme.primary.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  journey.title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: alreadyCheckedIn
                        ? theme.colorScheme.secondary
                        : theme.colorScheme.primary,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Day ${activeJourney.currentDay}/${journey.duration.days}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Today's requirement with clickable Bible references
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today\'s Task',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 6),
                _ClickableRequirement(
                  text: todayRequirement,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // Intention (if set)
          if (activeJourney.prayerIntention.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.favorite_outline,
                  size: 14,
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    activeJourney.prayerIntention,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),

          // Action row
          if (alreadyCheckedIn)
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.secondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Day ${activeJourney.currentDay} complete. Well done.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onCheckIn,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Complete'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () => _showStruggledDialog(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Struggling'),
                ),
              ],
            ),

          // Progress bar
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: activeJourney.progressPercent,
              minHeight: 4,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(
                alreadyCheckedIn
                    ? theme.colorScheme.secondary
                    : theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStruggledDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('That\'s okay'),
        content: const Text(
          'Growth includes struggle. Tomorrow is a new day to begin again. '
          'Consider sharing this with your accountability partner for support.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push(AppRoutes.growTogether);
            },
            child: const Text('Reach out'),
          ),
        ],
      ),
    );
  }
}

/// Renders text with Bible references as clickable links.
///
/// Detects patterns like "Genesis 1", "John 3:16", "Psalm 23",
/// "1 Corinthians 13", "Read Matthew 5" and makes them tappable
/// to navigate to the Bible reader.
class _ClickableRequirement extends StatelessWidget {
  const _ClickableRequirement({required this.text, this.style});

  final String text;
  final TextStyle? style;

  // Match Bible references: optional number prefix, book name, chapter, optional verse
  static final _bibleRefPattern = RegExp(
    r'(\d?\s?(?:Genesis|Exodus|Leviticus|Numbers|Deuteronomy|Joshua|Judges|Ruth|'
    r'1\s?Samuel|2\s?Samuel|1\s?Kings|2\s?Kings|1\s?Chronicles|2\s?Chronicles|'
    r'Ezra|Nehemiah|Esther|Job|Psalms?|Proverbs|Ecclesiastes|'
    r'Song\s?of\s?Solomon|Isaiah|Jeremiah|Lamentations|Ezekiel|Daniel|'
    r'Hosea|Joel|Amos|Obadiah|Jonah|Micah|Nahum|Habakkuk|Zephaniah|'
    r'Haggai|Zechariah|Malachi|'
    r'Matthew|Mark|Luke|John|Acts|Romans|'
    r'1\s?Corinthians|2\s?Corinthians|Galatians|Ephesians|Philippians|'
    r'Colossians|1\s?Thessalonians|2\s?Thessalonians|'
    r'1\s?Timothy|2\s?Timothy|Titus|Philemon|Hebrews|James|'
    r'1\s?Peter|2\s?Peter|1\s?John|2\s?John|3\s?John|Jude|Revelation)'
    r'\s+\d+(?::\d+(?:-\d+)?)?)',
    caseSensitive: false,
  );

  @override
  Widget build(BuildContext context) {
    final matches = _bibleRefPattern.allMatches(text).toList();

    if (matches.isEmpty) {
      return Text(text, style: style);
    }

    final theme = Theme.of(context);
    final spans = <InlineSpan>[];
    int lastEnd = 0;

    for (final match in matches) {
      // Text before this match
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start), style: style));
      }

      final refText = match.group(0)!;
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: GestureDetector(
          onTap: () => _navigateToBible(context, refText),
          child: Text(
            refText,
            style: style?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor: theme.colorScheme.primary.withValues(alpha: 0.4),
            ),
          ),
        ),
      ));

      lastEnd = match.end;
    }

    // Remaining text after last match
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd), style: style));
    }

    return Text.rich(TextSpan(children: spans));
  }

  void _navigateToBible(BuildContext context, String reference) {
    // Parse "Book Chapter:Verse" from the reference
    final parts = reference.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return;

    // Reconstruct book name (may be multi-word like "1 Samuel" or "Song of Solomon")
    String bookName = '';
    int? chapter;
    int? verse;

    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];
      // Check if this part contains chapter:verse
      if (RegExp(r'^\d+').hasMatch(part) && i > 0) {
        final chapterVerse = part.split(':');
        chapter = int.tryParse(chapterVerse[0]);
        if (chapterVerse.length > 1) {
          verse = int.tryParse(chapterVerse[1].split('-')[0]);
        }
        break;
      } else {
        if (bookName.isNotEmpty) bookName += ' ';
        bookName += part;
      }
    }

    if (bookName.isEmpty || chapter == null) return;

    final encodedBook = Uri.encodeComponent(bookName);
    var url = '${AppRoutes.bibleReader}?book=$encodedBook&chapter=$chapter';
    if (verse != null) {
      url += '&verse=$verse';
    }

    context.push(url);
  }
}
