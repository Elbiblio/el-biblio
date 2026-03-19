// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bible_content.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BibleBook _$BibleBookFromJson(Map<String, dynamic> json) => BibleBook(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String,
      abbreviation: json['abbreviation'] as String,
      chapters: (json['chapters_count'] as num?)?.toInt(),
      testament: json['testament'] as String?,
    );

Map<String, dynamic> _$BibleBookToJson(BibleBook instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'abbreviation': instance.abbreviation,
      'chapters_count': instance.chapters,
      'testament': instance.testament,
    };

BibleVerseContent _$BibleVerseContentFromJson(Map<String, dynamic> json) =>
    BibleVerseContent(
      id: (json['id'] as num).toInt(),
      bookId: (json['book_id'] as num?)?.toInt(),
      chapter: (json['chapter'] as num).toInt(),
      verse: (json['verse'] as num).toInt(),
      text: json['text'] as String,
      reference: json['reference'] as String?,
      isHighlighted: json['is_highlighted'] as bool? ?? false,
      isBookmarked: json['is_bookmarked'] as bool? ?? false,
    );

Map<String, dynamic> _$BibleVerseContentToJson(BibleVerseContent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'book_id': instance.bookId,
      'chapter': instance.chapter,
      'verse': instance.verse,
      'text': instance.text,
      'reference': instance.reference,
      'is_highlighted': instance.isHighlighted,
      'is_bookmarked': instance.isBookmarked,
    };
