import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/bible_content.dart';
import '../../../../core/di/app_providers.dart';
import 'verse_insight_sheet.dart';

class BibleVerseActionSheet extends ConsumerWidget {
  const BibleVerseActionSheet({
    super.key,
    required this.verse,
    required this.onHighlight,
    required this.onBookmark,
    required this.onCompare,
    required this.onJournal,
    required this.onAllInsights,
    required this.onAddNote,
    required this.onLike,
    required this.onShare,
    this.onExplain,
  });

  final BibleVerseContent verse;
  final VoidCallback onHighlight;
  final VoidCallback onBookmark;
  final VoidCallback onCompare;
  final VoidCallback onJournal;
  final VoidCallback onAllInsights;
  final VoidCallback onAddNote;
  final VoidCallback onLike;
  final VoidCallback onShare;
  final VoidCallback? onExplain;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom + 24;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: bottomPadding),
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
              _VerseActionSection(
                title: 'Quick Actions',
                children: [
                  _ActionTile(
                    icon: Icons.edit_note,
                    iconColor: Colors.green,
                    title: 'Journal Note',
                    subtitle: 'Create a personal reflection',
                    onTap: () {
                      Navigator.pop(context);
                      onJournal();
                    },
                  ),
                  _ActionTile(
                    icon: Icons.note_add,
                    iconColor: Colors.orange,
                    title: 'Add Note',
                    subtitle: 'Attach a personal note to this verse',
                    onTap: () {
                      Navigator.pop(context);
                      onAddNote();
                    },
                  ),
                  _ActionTile(
                    icon: Icons.auto_awesome,
                    iconColor: Colors.purple,
                    title: 'Get Insight',
                    subtitle: 'Explain this verse',
                    onTap: () {
                      Navigator.pop(context);
                      if (onExplain != null) {
                        onExplain!();
                      } else {
                        _explainVerse(context, ref);
                      }
                    },
                  ),
                ],
              ),
              const Divider(),
              _VerseActionSection(
                title: 'Share & Save',
                children: [
                  _ActionTile(
                    icon: verse.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    iconColor: Colors.blue,
                    title: verse.isBookmarked ? 'Remove Bookmark' : 'Bookmark',
                    subtitle: 'Save this verse for later',
                    onTap: () {
                      Navigator.pop(context);
                      onBookmark();
                    },
                  ),
                  _ActionTile(
                    icon: Icons.share,
                    iconColor: Colors.teal,
                    title: 'Share Verse',
                    subtitle: 'Share with others',
                    onTap: () {
                      Navigator.pop(context);
                      onShare();
                    },
                  ),
                  _ActionTile(
                    icon: Icons.copy,
                    iconColor: Colors.grey,
                    title: 'Copy Text',
                    subtitle: 'Copy verse to clipboard',
                    onTap: () {
                      Navigator.pop(context);
                      _copyVerseToClipboard(context, verse);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyVerseToClipboard(BuildContext context, BibleVerseContent verse) {
    final verseText = '${verse.reference ?? ""}\n\n${verse.text}';
    Clipboard.setData(ClipboardData(text: verseText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Verse copied to clipboard')),
    );
  }

  void _explainVerse(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => VerseInsightSheet(
        verse: verse,
        fetchInsight: () => ref.read(verseProvider.notifier).explainVerse(
              verseId: verse.id.toString(),
              reference: verse.reference ?? '',
              text: verse.text,
              version: 'eng_rv_vpl',
            ),
      ),
    );
  }
}

class _VerseActionSection extends StatelessWidget {
  const _VerseActionSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}
