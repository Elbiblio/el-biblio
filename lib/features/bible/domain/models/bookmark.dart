import 'package:json_annotation/json_annotation.dart';

part 'bookmark.g.dart';

@JsonSerializable()
class Bookmark {
  const Bookmark({
    required this.id,
    required this.verseId,
    required this.bookName,
    required this.chapter,
    required this.verse,
    required this.text,
    required this.reference,
    this.note,
    required this.createdAt,
    this.updatedAt,
  });

  final int id;
  @JsonKey(name: 'verse_id')
  final int verseId;
  @JsonKey(name: 'book_name')
  final String bookName;
  final int chapter;
  final int verse;
  final String text;
  final String reference;
  final String? note;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  factory Bookmark.fromJson(Map<String, dynamic> json) => _$BookmarkFromJson(json);

  Map<String, dynamic> toJson() => _$BookmarkToJson(this);

  Bookmark copyWith({
    int? id,
    int? verseId,
    String? bookName,
    int? chapter,
    int? verse,
    String? text,
    String? reference,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Bookmark(
      id: id ?? this.id,
      verseId: verseId ?? this.verseId,
      bookName: bookName ?? this.bookName,
      chapter: chapter ?? this.chapter,
      verse: verse ?? this.verse,
      text: text ?? this.text,
      reference: reference ?? this.reference,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
