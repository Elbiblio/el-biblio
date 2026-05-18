import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../domain/models/verse.dart';

class VerseReaderLocation {
  const VerseReaderLocation({
    required this.book,
    required this.chapter,
    this.verse,
  });

  final String book;
  final int chapter;
  final int? verse;

  String get route {
    return Uri(
      path: AppRoutes.bibleReader,
      queryParameters: {
        'book': book,
        'chapter': chapter.toString(),
        if (verse != null) 'verse': verse.toString(),
      },
    ).toString();
  }
}

VerseReaderLocation? resolveVerseReaderLocation(Verse verse) {
  final structuredBook = verse.book.trim();
  if (structuredBook.isNotEmpty && verse.chapter > 0) {
    return VerseReaderLocation(
      book: structuredBook,
      chapter: verse.chapter,
      verse: verse.verseNumber > 0 ? verse.verseNumber : null,
    );
  }

  for (final reference in [verse.referenceDisplay, verse.reference]) {
    final parsed = parseVerseReference(reference);
    if (parsed != null) return parsed;
  }

  return null;
}

VerseReaderLocation? parseVerseReference(String? reference) {
  final raw = reference?.trim();
  if (raw == null || raw.isEmpty) return null;
  final text = raw.replaceAll('\u2013', '-').replaceAll('\u2014', '-');

  final match = RegExp(
    r'^((?:[1-3]\s*)?[A-Za-z]+(?:\s+[A-Za-z]+)*)\s+(\d+)(?::(\d+))?(?:-\d+)?',
  ).firstMatch(text);
  if (match == null) return null;

  final book = match.group(1)?.trim().replaceAll(RegExp(r'\s+'), ' ');
  final chapter = int.tryParse(match.group(2) ?? '');
  final verse = int.tryParse(match.group(3) ?? '');

  if (book == null || book.isEmpty || chapter == null || chapter <= 0) {
    return null;
  }

  return VerseReaderLocation(
    book: book,
    chapter: chapter,
    verse: verse != null && verse > 0 ? verse : null,
  );
}

bool openVerseInReader(BuildContext context, Verse verse) {
  final location = resolveVerseReaderLocation(verse);
  if (location == null) return false;
  context.push(location.route);
  return true;
}
