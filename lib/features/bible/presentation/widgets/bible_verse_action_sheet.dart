import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/bible_content.dart';

class BibleVerseActionSheet extends ConsumerWidget {
  const BibleVerseActionSheet({
    super.key,
    required this.verse,
    required this.onHighlight,
    required this.onBookmark,
    required this.onInsight,
    required this.onCompare,
  });

  final BibleVerseContent verse;
  final VoidCallback onHighlight;
  final VoidCallback onBookmark;
  final VoidCallback onInsight;
  final VoidCallback onCompare;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              verse.reference ?? 'Verse Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.auto_awesome, color: Colors.purple),
            title: const Text('Get Insight'),
            onTap: () {
              Navigator.pop(context);
              onInsight();
            },
          ),
          ListTile(
            leading: Icon(
              verse.isHighlighted ? Icons.highlight_remove : Icons.highlight,
              color: Colors.amber,
            ),
            title: Text(verse.isHighlighted ? 'Remove Highlight' : 'Highlight'),
            onTap: () {
              Navigator.pop(context);
              onHighlight();
            },
          ),
          ListTile(
            leading: Icon(
              verse.isBookmarked ? Icons.bookmark_remove : Icons.bookmark_add,
              color: Colors.blue,
            ),
            title: Text(verse.isBookmarked ? 'Remove Bookmark' : 'Bookmark'),
            onTap: () {
              Navigator.pop(context);
              onBookmark();
            },
          ),
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('Copy Text'),
            onTap: () async {
              Navigator.pop(context);
              await Clipboard.setData(ClipboardData(text: '${verse.text} (${verse.reference})'));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Verse copied to clipboard')),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share'),
            onTap: () {
              Navigator.pop(context);
              // Simplified share using generic platform share if available, 
              // otherwise just copy and show snackbar for now if package not added
              // But standard practice: Share.share('${verse.text} (${verse.reference})');
              // We'll leave this as a TODO or use copy fallback if share_plus not in pubspec
              Clipboard.setData(ClipboardData(text: '${verse.text} (${verse.reference})'));
               if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Verse copied for sharing')),
                );
              }
            },
          ),
           ListTile(
            leading: const Icon(Icons.compare_arrows),
            title: const Text('Compare Versions'),
            onTap: () {
              Navigator.pop(context);
              onCompare();
            },
          ),
        ],
      ),
    );
  }
}
