import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../../data/static_books.dart';

class ChapterSelectionDialog {
  const ChapterSelectionDialog._();

  static Future<void> show(
    BuildContext context,
    WidgetRef ref,
    BibleBookDefinition book,
  ) {
    // Capture the router from the parent context before opening the dialog,
    // so we can navigate after the dialog is popped (dialog context becomes unmounted).
    final router = GoRouter.of(context);

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Select Chapter - ${book.name}'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: book.chapters,
              itemBuilder: (context, index) {
                final chapterNumber = index + 1;
                return ListTile(
                  title: Text('Chapter $chapterNumber'),
                  onTap: () {
                    Navigator.of(dialogContext).pop();
                    ref
                        .read(bibleReadingProvider.notifier)
                        .trackReadingLocation(
                          bookName: book.name,
                          chapter: chapterNumber,
                          testament: book.testament,
                        );
                    router.push(
                      '${AppRoutes.bibleReader}?book=${Uri.encodeComponent(book.name)}&chapter=$chapterNumber&fromLibrary=true',
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
