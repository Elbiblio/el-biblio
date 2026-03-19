import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../../domain/models/bible_content.dart';

class BibleSmartSearchComponent extends ConsumerStatefulWidget {
  const BibleSmartSearchComponent({
    super.key,
    required this.isDark,
    required this.surfaceColor,
    required this.textColor,
    required this.textMutedColor,
    required this.borderColor,
  });

  final bool isDark;
  final Color surfaceColor;
  final Color textColor;
  final Color textMutedColor;
  final Color borderColor;

  @override
  ConsumerState<BibleSmartSearchComponent> createState() => _BibleSmartSearchComponentState();
}

class _BibleSmartSearchComponentState extends ConsumerState<BibleSmartSearchComponent> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  bool _isSearching = false;
  List<BibleVerseContent> _results = [];
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _showResults = _focusNode.hasFocus && _searchController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _showResults = false;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _showResults = true;
    });

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final bibleState = ref.read(bibleProvider);
      if (bibleState.currentVersion == null) {
        setState(() => _isSearching = false);
        return;
      }

      final versionIdentifier = bibleState.currentVersion!.tableName ?? bibleState.currentVersion!.abbreviation;
      final dbService = ref.read(bibleDatabaseServiceProvider);

      try {
        final results = await dbService.searchVerses(versionIdentifier, query, limit: 20);
        if (mounted) {
          setState(() {
            _results = results;
            _isSearching = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _results = [];
            _isSearching = false;
          });
        }
      }
    });
  }

  void _navigateToVerse(BibleVerseContent verse) {
    _focusNode.unfocus();
    setState(() => _showResults = false);

    // Extract book abbreviation from reference (e.g., "GN 1:1" -> "GN")
    final referenceParts = verse.reference?.split(' ');
    final bookAbbr = referenceParts != null && referenceParts.isNotEmpty ? referenceParts[0] : '';
    
    // Find full book name or use abbreviation
    final bibleState = ref.read(bibleProvider);
    final book = bibleState.books.firstWhere(
      (b) => b.abbreviation == bookAbbr,
      orElse: () => bibleState.books.first,
    );

    final uri = Uri(
      path: AppRoutes.bibleReader,
      queryParameters: {
        'book': book.name,
        'chapter': verse.chapter.toString(),
        'verse': verse.verse.toString(),
      },
    );
    
    context.push(uri.toString());
  }

  Widget _buildRichText(String text) {
    if (!text.contains('<b>')) {
      return Text(
        text,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: widget.textColor.withValues(alpha: 0.8),
        ),
      );
    }

    final spans = <TextSpan>[];
    final RegExp exp = RegExp(r'<b>(.*?)<\/b>');
    int lastMatchEnd = 0;

    for (final Match match in exp.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: text.substring(lastMatchEnd, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
      ));
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd)));
    }

    return RichText(
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: widget.textColor.withValues(alpha: 0.8),
        ),
        children: spans,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: widget.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.borderColor),
            boxShadow: [
              if (!widget.isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            onChanged: _onSearchChanged,
            style: TextStyle(color: widget.textColor),
            decoration: InputDecoration(
              hintText: 'Search books, verses, or plans...',
              hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: widget.textMutedColor,
                fontSize: 15,
              ),
              prefixIcon: Icon(LucideIcons.search, color: widget.textMutedColor, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: widget.textMutedColor, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                        _focusNode.unfocus();
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        if (_showResults)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: widget.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: widget.borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 300),
            child: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _results.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Center(
                          child: Text(
                            'No results found for "${_searchController.text}"',
                            style: TextStyle(color: widget.textMutedColor),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: _results.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          color: widget.borderColor,
                        ),
                        itemBuilder: (context, index) {
                          final verse = _results[index];
                          return InkWell(
                            onTap: () => _navigateToVerse(verse),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    verse.reference ?? 'Unknown Reference',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  _buildRichText(verse.text),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
      ],
    );
  }
}
