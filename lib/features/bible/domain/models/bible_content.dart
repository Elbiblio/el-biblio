import 'package:json_annotation/json_annotation.dart';

part 'bible_content.g.dart';

@JsonSerializable()
class BibleBook {
  const BibleBook({
    required this.id,
    required this.name,
    required this.abbreviation,
    this.chapters,
    this.testament,
  });

  final int id;
  final String name;
  final String abbreviation;
  final int? chapters;
  final String? testament;

  factory BibleBook.fromJson(Map<String, dynamic> json) => _$BibleBookFromJson(json);
  Map<String, dynamic> toJson() => _$BibleBookToJson(this);
}

@JsonSerializable()
class BibleVerseContent {
  const BibleVerseContent({
    required this.id,
    required this.bookId,
    required this.chapter,
    required this.verse,
    required this.text,
    this.reference,
    this.isHighlighted = false,
    this.isBookmarked = false,
  });

  final int id;
  @JsonKey(name: 'book_id')
  final int bookId;
  final int chapter;
  final int verse;
  final String text;
  final String? reference;
  @JsonKey(name: 'is_highlighted')
  final bool isHighlighted;
  @JsonKey(name: 'is_bookmarked')
  final bool isBookmarked;

  factory BibleVerseContent.fromJson(Map<String, dynamic> json) => _$BibleVerseContentFromJson(json);
  Map<String, dynamic> toJson() => _$BibleVerseContentToJson(this);

  BibleVerseContent copyWith({
    int? id,
    int? bookId,
    int? chapter,
    int? verse,
    String? text,
    String? reference,
    bool? isHighlighted,
    bool? isBookmarked,
  }) {
    return BibleVerseContent(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      chapter: chapter ?? this.chapter,
      verse: verse ?? this.verse,
      text: text ?? this.text,
      reference: reference ?? this.reference,
      isHighlighted: isHighlighted ?? this.isHighlighted,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }
}
