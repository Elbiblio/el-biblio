// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verse.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Verse _$VerseFromJson(Map<String, dynamic> json) => Verse(
      id: (json['id'] as num).toInt(),
      text: json['text'] as String,
      reference: json['reference'] as String,
      translation: json['translation'] as String,
      book: json['book'] as String,
      chapter: (json['chapter'] as num).toInt(),
      verseNumber: (json['verse'] as num).toInt(),
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      votes: (json['votes'] as num?)?.toInt() ?? 0,
      shares: (json['shares'] as num?)?.toInt() ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      isVoted: json['isVoted'] as bool? ?? false,
      theme: json['theme'] == null
          ? null
          : VerseTheme.fromJson(json['theme'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['created_at'] as String),
      date:
          json['date'] == null ? null : DateTime.parse(json['date'] as String),
    );

Map<String, dynamic> _$VerseToJson(Verse instance) => <String, dynamic>{
      'id': instance.id,
      'text': instance.text,
      'reference': instance.reference,
      'translation': instance.translation,
      'book': instance.book,
      'chapter': instance.chapter,
      'verse': instance.verseNumber,
      'likes': instance.likes,
      'votes': instance.votes,
      'shares': instance.shares,
      'isLiked': instance.isLiked,
      'isVoted': instance.isVoted,
      'theme': instance.theme,
      'created_at': instance.createdAt.toIso8601String(),
      'date': instance.date?.toIso8601String(),
    };

VerseTheme _$VerseThemeFromJson(Map<String, dynamic> json) => VerseTheme(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      color: json['color'] as String?,
    );

Map<String, dynamic> _$VerseThemeToJson(VerseTheme instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'color': instance.color,
    };
