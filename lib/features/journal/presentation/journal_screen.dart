import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:convert';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/safe_bottom_padding.dart';
import '../../today/domain/models/daily_anchors.dart';
import '../domain/models/note.dart';
import 'widgets/voice_recorder_bottom_sheet.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  bool _isSearchVisible = false;

  @override
  void initState() {
    super.initState();
    // Load notes when screen initializes, but only if not already loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final journalState = ref.read(journalProvider);
      if (journalState.notes.isEmpty && !journalState.isLoading) {
        ref.read(journalProvider.notifier).loadNotes();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final journalState = ref.watch(journalProvider);
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = theme.scaffoldBackgroundColor;
    final primaryTextColor = theme.colorScheme.onSurface;
    final secondaryTextColor = tokens.palette.textSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, ref, isDark, primaryTextColor),
            if (!journalState.showPublicNotes)
              _buildFilterSection(context, ref, isDark),
            Expanded(
              child: journalState.isLoading && journalState.notes.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : journalState.error != null
                  ? _buildErrorState(context, ref, journalState.error!)
                  : RefreshIndicator(
                      onRefresh: () async {
                        await ref.read(journalProvider.notifier).loadNotes();
                      },
                      child: journalState.filteredNotes.isEmpty
                          ? _buildEmptyState(context, ref)
                          : SafeListView(
                              bottomPadding: 120,
                              padding: const EdgeInsets.only(
                                left: 32,
                                right: 32,
                                top: 32,
                              ),
                              children: _buildNoteList(
                                journalState.filteredNotes,
                                isDark,
                                primaryTextColor,
                                secondaryTextColor,
                              ),
                            ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActions(context),
    );
  }

  Widget _buildFloatingActions(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fabBackground = isDark ? const Color(0xFF1e293b) : Colors.white;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          heroTag: 'journal_voice_note',
          onPressed: _showVoiceRecordingBottomSheet,
          backgroundColor: fabBackground,
          foregroundColor: theme.colorScheme.primary,
          elevation: 8,
          tooltip: 'Voice note',
          child: const Icon(Icons.mic, size: 20),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            heroTag: 'journal_new_note',
            onPressed: () => context.push('${AppRoutes.journal}/new'),
            backgroundColor: fabBackground,
            foregroundColor: theme.colorScheme.primary,
            elevation: 0,
            icon: const Icon(Icons.add, size: 22),
            label: Text(
              'New Note',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showVoiceRecordingBottomSheet() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VoiceRecorderBottomSheet(
        onNoteCreated: (text) {
          ref
              .read(journalProvider.notifier)
              .createNote(
                'Voice Note',
                jsonEncode([
                  {'insert': '$text\n'},
                ]),
                isPublic: false,
                isPinned: false,
                isVoiceRecorded: true,
                virtues: [],
              );
        },
      ),
    );
  }

  List<Widget> _buildNoteList(
    List<Note> notes,
    bool isDark,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    final List<Widget> widgets = [];

    for (int i = 0; i < notes.length; i++) {
      final note = notes[i];
      widgets.add(
        _NoteArticleCard(
          note: note,
          isDark: isDark,
          primaryTextColor: primaryTextColor,
          secondaryTextColor: secondaryTextColor,
          onTap: () => context.push('${AppRoutes.journal}/${note.id}'),
          onDelete: () => _deleteNote(note.id!),
        ),
      );

      // Add separator except for the last item
      if (i < notes.length - 1) {
        widgets.add(const SizedBox(height: 48));
      }
    }

    return widgets;
  }

  void _deleteNote(int id) {
    ref.read(journalProvider.notifier).deleteNote(id);
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    Color primaryTextColor,
  ) {
    final journalState = ref.watch(journalProvider);
    final notifier = ref.read(journalProvider.notifier);
    final isPublic = journalState.showPublicNotes;
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return Container(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 16),
      color: (isDark ? theme.colorScheme.surface : tokens.palette.paper)
          .withValues(alpha: 0.9),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 40),
              Text(
                'Journal',
                style: Theme.of(context).textTheme.brandTitle.copyWith(
                  fontSize: 18,
                  color: primaryTextColor,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.search, weight: 300),
                onPressed: () {
                  setState(() {
                    _isSearchVisible = !_isSearchVisible;
                    if (!_isSearchVisible) {
                      notifier.setSearchQuery('');
                    }
                  });
                },
                color: tokens.palette.textSecondary,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          if (_isSearchVisible) ...[
            const SizedBox(height: 24),
            TextField(
              decoration: InputDecoration(
                hintText: isPublic
                    ? 'Search community notes...'
                    : 'Search journal entries...',
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: tokens.palette.textTertiary,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: tokens.palette.textTertiary,
                ),
                filled: true,
                fillColor: isDark
                    ? theme.colorScheme.surfaceContainerHighest
                    : tokens.palette.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 0,
                ),
              ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: primaryTextColor,
                fontSize: 14,
              ),
              onChanged: (value) => notifier.setSearchQuery(value),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTabButton(
                title: 'PERSONAL',
                isActive: !isPublic,
                primaryTextColor: primaryTextColor,
                onTap: () {
                  if (isPublic) notifier.toggleShowPublicNotes();
                },
              ),
              const SizedBox(width: 16),
              _buildTabButton(
                title: 'COMMUNITY',
                isActive: isPublic,
                primaryTextColor: primaryTextColor,
                onTap: () {
                  if (!isPublic) notifier.toggleShowPublicNotes();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context, WidgetRef ref, bool isDark) {
    final journalState = ref.watch(journalProvider);
    final notifier = ref.read(journalProvider.notifier);
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      child: Row(
        children: [
          if (journalState.selectedVirtues.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: ActionChip(
                label: Text(
                  'Clear',
                  style: Theme.of(
                    context,
                  ).textTheme.chipText.copyWith(fontSize: 12),
                ),
                onPressed: () => notifier.clearFilters(),
                avatar: const Icon(Icons.close, size: 14),
                backgroundColor: isDark
                    ? theme.colorScheme.surfaceContainerHighest
                    : tokens.palette.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                side: BorderSide.none,
              ),
            ),

          Wrap(
            spacing: 8,
            children: VirtueType.values.map((virtue) {
              final isSelected = journalState.selectedVirtues.contains(
                virtue.name,
              );
              final color = _getVirtueColor(virtue.name, isDark);

              return InkWell(
                onTap: () => notifier.toggleVirtueFilter(virtue.name),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? color : tokens.palette.border,
                    ),
                  ),
                  child: Text(
                    virtue.title,
                    style: Theme.of(context).textTheme.chipText.copyWith(
                      color: isSelected ? color : tokens.palette.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _getVirtueColor(String virtue, bool isDark) {
    switch (virtue.toLowerCase()) {
      case 'wisdom':
        return const Color(0xFFeab308);
      case 'peace':
        return const Color(0xFF38bdf8);
      case 'courage':
        return const Color(0xFFf87171);
      case 'compassion':
        return const Color(0xFFf472b6);
      case 'gratitude':
        return const Color(0xFF4ade80);
      default:
        return isDark ? Colors.grey.shade500 : Colors.blueGrey.shade400;
    }
  }

  Widget _buildTabButton({
    required String title,
    required bool isActive,
    required Color primaryTextColor,
    required VoidCallback onTap,
  }) {
    final tokens = Theme.of(context).tokens;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontSize: 13,
                letterSpacing: 1.5,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive
                    ? primaryTextColor
                    : tokens.palette.textTertiary,
              ),
            ),
            if (isActive) ...[
              const SizedBox(height: 4),
              Container(
                width: 20,
                height: 2,
                decoration: BoxDecoration(
                  color: primaryTextColor,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, String error) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: tokens.palette.error),
          const SizedBox(height: 24),
          Text(
            'Failed to load journal',
            style: Theme.of(context).textTheme.journalTitle.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w300,
              color: tokens.palette.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => ref.read(journalProvider.notifier).loadNotes(),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            child: Text(
              'Try Again',
              style: Theme.of(context).textTheme.buttonText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    final journalState = ref.watch(journalProvider);
    final hasFilters =
        journalState.searchQuery.isNotEmpty ||
        journalState.selectedVirtues.isNotEmpty;
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.edit_note, size: 48, color: tokens.palette.textTertiary),
          const SizedBox(height: 24),
          Text(
            hasFilters ? 'No notes found' : 'Your journal is empty',
            style: Theme.of(context).textTheme.journalTitle.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilters
                ? 'Try adjusting your filters'
                : 'Capture your reflections and insights',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w300,
              color: tokens.palette.textSecondary,
            ),
          ),
          if (hasFilters) ...[
            const SizedBox(height: 24),
            TextButton(
              onPressed: () =>
                  ref.read(journalProvider.notifier).clearFilters(),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurface,
              ),
              child: Text(
                'Clear filters',
                style: Theme.of(context).textTheme.buttonText,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NoteArticleCard extends StatelessWidget {
  const _NoteArticleCard({
    required this.note,
    required this.isDark,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.onTap,
    required this.onDelete,
  });

  final Note note;
  final bool isDark;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  Color _getVirtueColor(String virtue) {
    switch (virtue.toLowerCase()) {
      case 'wisdom':
        return const Color(0xFFeab308);
      case 'peace':
        return const Color(0xFF38bdf8);
      case 'courage':
        return const Color(0xFFf87171);
      case 'compassion':
        return const Color(0xFFf472b6);
      case 'gratitude':
        return const Color(0xFF4ade80);
      default:
        return isDark ? Colors.grey.shade700 : Colors.blueGrey.shade200;
    }
  }

  Widget _buildNoteTextContent(
    BuildContext context,
    String text,
    Color secondaryTextColor,
  ) {
    String? extracted;

    // Try to parse as Quill JSON first (can be a Map with ops or a List of operations)
    try {
      final decoded = jsonDecode(text);

      List<dynamic>? operations;
      if (decoded is Map<String, dynamic>) {
        operations = decoded['ops'] as List<dynamic>?;
      } else if (decoded is List) {
        operations = decoded;
      }

      if (operations != null) {
        extracted = operations
            .map((op) {
              if (op is Map<String, dynamic>) {
                return op['insert'] as String? ?? '';
              }
              return '';
            })
            .join('');
      }
    } catch (_) {
      // Not JSON, treat as plain text
    }

    final displayText = (extracted ?? text).trim();

    return Text(
      displayText,
      style: Theme.of(
        context,
      ).textTheme.journalBody.copyWith(fontSize: 14, color: secondaryTextColor),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  @override
  Widget build(BuildContext context) {
    final virtueColor = note.virtues.isNotEmpty
        ? _getVirtueColor(note.virtues.first)
        : (isDark ? Colors.grey.shade700 : Colors.blueGrey.shade200);

    final timeAgoStr = timeago.format(note.updatedAt, locale: 'en_US');
    final visibilityStr = note.isPublic ? 'Public' : 'Private';
    final hasMeditation =
        note.meditationSessionId != null &&
        note.meditationSessionId!.isNotEmpty;
    final metadataText = hasMeditation
        ? '$timeAgoStr • $visibilityStr • After Meditation'
        : '$timeAgoStr • $visibilityStr';

    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showDeleteDialog(context),
      behavior: HitTestBehavior.opaque,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 1,
              color: virtueColor,
              margin: const EdgeInsets.only(top: 4, bottom: 4),
            ),
            const SizedBox(width: 32),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metadataText.toUpperCase(),
                    style: Theme.of(context).textTheme.metadata.copyWith(
                      color: isDark
                          ? Colors.grey.shade500
                          : Colors.blueGrey.shade400,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (note.title?.isNotEmpty == true) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            note.title!,
                            style: Theme.of(context).textTheme.journalTitle
                                .copyWith(
                                  fontSize: 30,
                                  color: primaryTextColor,
                                ),
                          ),
                        ),
                        if (note.isVoiceRecorded) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blue.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.mic, color: Colors.blue, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Voice',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (note.meditationSessionId != null &&
                            note.meditationSessionId!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.deepPurple.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.self_improvement,
                                  color: Colors.deepPurple,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Meditation',
                                  style: TextStyle(
                                    color: Colors.deepPurple,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (note.text?.isNotEmpty == true)
                    _buildNoteTextContent(
                      context,
                      note.text!,
                      secondaryTextColor,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Journal Entry'),
          content: Text(
            'Are you sure you want to delete "${note.title ?? 'this journal entry'}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onDelete();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
