import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/app_providers.dart';

class BibleSearchDelegate extends SearchDelegate {
  BibleSearchDelegate(this.ref);

  final WidgetRef ref;

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          ref.read(bibleProvider.notifier).clearSearch();
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isNotEmpty) {
      // Trigger search
      ref.read(bibleProvider.notifier).search(query);
    }

    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // We could implement search history or suggestions here
    return Container(); 
  }

  Widget _buildSearchResults(BuildContext context) {
    final bibleState = ref.watch(bibleProvider);

    if (bibleState.isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (bibleState.searchResults.isEmpty) {
      if (query.isNotEmpty) {
        return const Center(child: Text('No results found.'));
      }
      return Container();
    }

    return ListView.builder(
      itemCount: bibleState.searchResults.length,
      itemBuilder: (context, index) {
        final verse = bibleState.searchResults[index];
        return ListTile(
          title: Text(verse.text),
          subtitle: Text(verse.reference ?? ''),
          onTap: () {
            // Navigate to verse
            // We need to find the book object to select it
            final book = bibleState.books.firstWhere(
              (b) => verse.reference != null && verse.reference!.startsWith(b.abbreviation),
              orElse: () => bibleState.books.first, // Fallback, imperfect
            );
            
            ref.read(bibleProvider.notifier).selectBook(book);
            ref.read(bibleProvider.notifier).selectChapter(verse.chapter);
            
            close(context, null);
          },
        );
      },
    );
  }
}
