import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'dart:convert';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../domain/models/note.dart';

class NoteReaderScreen extends ConsumerStatefulWidget {
  const NoteReaderScreen({
    super.key,
    required this.noteId,
  });

  final String noteId;

  @override
  ConsumerState<NoteReaderScreen> createState() => _NoteReaderScreenState();
}

class _NoteReaderScreenState extends ConsumerState<NoteReaderScreen> {
  Note? _note;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  Future<void> _loadNote() async {
    final journalState = ref.read(journalProvider);
    final note = journalState.notes.cast<Note?>().firstWhere(
      (n) => n?.id.toString() == widget.noteId,
      orElse: () => null,
    );

    if (mounted) {
      setState(() {
        _note = note;
        _isLoading = false;
      });
    }
  }

  Color _getVirtueColor(String virtue, bool isDark) {
    switch (virtue.toLowerCase()) {
      case 'wisdom': return const Color(0xFFeab308);
      case 'peace': return const Color(0xFF38bdf8);
      case 'courage': return const Color(0xFFf87171);
      case 'compassion': return const Color(0xFFf472b6);
      case 'gratitude': return const Color(0xFF4ade80);
      case 'humility': return const Color(0xFF8b5cf6);
      case 'love': return const Color(0xFFef4444);
      case 'faith': return const Color(0xFF10b981);
      case 'knowledge': return const Color(0xFF3b82f6);
      default: return isDark ? Colors.grey.shade500 : Colors.blueGrey.shade400;
    }
  }

  String _estimateReadingTime(String text) {
    try {
      // Try to parse as Quill JSON and extract plain text
      String plainText = text;
      try {
        final decoded = jsonDecode(text);
        if (decoded is Map<String, dynamic> && decoded['ops'] is List) {
          final operations = decoded['ops'] as List;
          plainText = operations.map((op) {
            if (op is Map<String, dynamic>) {
              return op['insert'] as String? ?? '';
            }
            return '';
          }).join('');
        } else if (decoded is List) {
          plainText = decoded.map((op) {
            if (op is Map<String, dynamic>) {
              return op['insert'] as String? ?? '';
            }
            return '';
          }).join('');
        }
      } catch (_) {
        // Use original text if JSON parsing fails
      }

      final wordCount = plainText.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
      final readingTime = (wordCount / 200).ceil(); // Average reading speed: 200 words per minute
      
      if (readingTime <= 1) {
        return '1 min read';
      } else {
        return '$readingTime min read';
      }
    } catch (e) {
      return '1 min read';
    }
  }

  Widget _buildRichTextContent(String text) {
    final theme = Theme.of(context);
    
    try {
      final decoded = jsonDecode(text);
      final document = quill.Document.fromJson(decoded);
      
      return SizedBox(
        width: double.infinity,
        child: Theme(
          data: Theme.of(context).copyWith(
            textTheme: Theme.of(context).textTheme.copyWith(
              displayLarge: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                height: 1.2,
                color: theme.colorScheme.onSurface,
              ),
              displayMedium: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                height: 1.3,
                color: theme.colorScheme.onSurface,
              ),
              displaySmall: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: theme.colorScheme.onSurface,
              ),
              bodyLarge: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 16,
                height: 1.6,
                color: theme.colorScheme.onSurface,
              ),
              bodyMedium: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                height: 1.5,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          child: quill.QuillEditor(
            controller: quill.QuillController(
              document: document,
              selection: const TextSelection.collapsed(offset: 0),
              readOnly: true,
            ),
            scrollController: ScrollController(),
            focusNode: FocusNode(canRequestFocus: false),
          ),
        ),
      );
    } catch (e) {
      // Fallback to plain text if JSON parsing fails
      return Text(
        text,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontSize: 16,
          height: 1.6,
          color: theme.colorScheme.onSurface,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_note == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.note_alt_outlined,
                size: 64,
                color: tokens.palette.textTertiary,
              ),
              const SizedBox(height: 16),
              Text(
                'Note not found',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final timeAgoStr = timeago.format(_note!.updatedAt, locale: 'en_US');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            backgroundColor: theme.scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => context.pop(),
              color: tokens.palette.textSecondary,
            ),
            actions: [
              // Share button
              IconButton(
                icon: const Icon(Icons.share, size: 20),
                onPressed: () {
                  // TODO: Implement share functionality
                },
                color: tokens.palette.textSecondary,
                tooltip: 'Share Note',
              ),
              // Edit button
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () {
                  context.push('${AppRoutes.journal}/${_note!.id}/edit');
                },
                color: tokens.palette.textSecondary,
                tooltip: 'Edit Note',
              ),
              const SizedBox(width: 8),
            ],
            floating: true,
            pinned: false,
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Metadata
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time and visibility
                    Row(
                      children: [
                        Text(
                          timeAgoStr.toUpperCase(),
                          style: Theme.of(context).textTheme.metadata.copyWith(
                            color: isDark ? Colors.grey.shade500 : Colors.blueGrey.shade400,
                            fontSize: 12,
                          ),
                        ),
                        if (_note!.isPublic) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'PUBLIC',
                              style: Theme.of(context).textTheme.metadata.copyWith(
                                color: primaryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    const SizedBox(height: 24),

                    // Title
                    if (_note!.title?.isNotEmpty == true) ...[
                      Text(
                        _note!.title!,
                        style: Theme.of(context).textTheme.journalTitle.copyWith(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // Virtue tags
                    if (_note!.virtues.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _note!.virtues.map((virtue) {
                          final color = _getVirtueColor(virtue, isDark);
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: color.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              virtue.toUpperCase(),
                              style: Theme.of(context).textTheme.chipText.copyWith(
                                color: color,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // Rich text content with reading progress
                    if (_note!.text?.isNotEmpty == true) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark 
                              ? theme.colorScheme.surfaceContainerLow
                              : tokens.palette.paper,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark 
                                ? theme.colorScheme.outline.withValues(alpha: 0.2)
                                : tokens.palette.border,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Reading time estimate
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    size: 14,
                                    color: primaryColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _estimateReadingTime(_note!.text!),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: primaryColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Rich text content
                            _buildRichTextContent(_note!.text!),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ]),
            ),
          ),

          // Bottom padding
          const SliverPadding(
            padding: EdgeInsets.only(bottom: 100),
          ),
        ],
      ),
    );
  }
}
