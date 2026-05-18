import 'package:elbiblio/features/bible/domain/models/verse.dart';
import 'package:elbiblio/features/bible/presentation/helpers/verse_reader_navigation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolveVerseReaderLocation prefers structured verse metadata', () {
    final verse = _verse(
      book: 'John',
      chapter: 3,
      verseNumber: 16,
      reference: 'JHN3_16',
      referenceDisplay: 'John 3:16',
    );

    final location = resolveVerseReaderLocation(verse);

    expect(location?.book, 'John');
    expect(location?.chapter, 3);
    expect(location?.verse, 16);
    expect(location?.route, '/bible/reader?book=John&chapter=3&verse=16');
  });

  test('parseVerseReference handles numbered and multiword book names', () {
    final location = parseVerseReference('1 Corinthians 16:14-15');

    expect(location?.book, '1 Corinthians');
    expect(location?.chapter, 16);
    expect(location?.verse, 14);
  });

  test('resolveVerseReaderLocation falls back to reference display', () {
    final verse = _verse(
      book: '',
      chapter: 0,
      verseNumber: 0,
      reference: 'SOS2_1',
      referenceDisplay: 'Song of Solomon 2:1',
    );

    final location = resolveVerseReaderLocation(verse);

    expect(location?.book, 'Song of Solomon');
    expect(location?.chapter, 2);
    expect(location?.verse, 1);
  });
}

Verse _verse({
  required String book,
  required int chapter,
  required int verseNumber,
  required String reference,
  String? referenceDisplay,
}) {
  return Verse(
    id: 1,
    text: 'Verse text',
    reference: reference,
    referenceDisplay: referenceDisplay,
    translation: 'WEB',
    book: book,
    chapter: chapter,
    verseNumber: verseNumber,
    createdAt: DateTime(2026, 5, 18),
  );
}
