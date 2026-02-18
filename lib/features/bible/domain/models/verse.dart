import 'package:json_annotation/json_annotation.dart';

part 'verse.g.dart';

@JsonSerializable()
class Verse {
  const Verse({
    required this.id,
    required this.text,
    required this.reference,
    required this.translation,
    required this.book,
    required this.chapter,
    required this.verseNumber,
    this.likes = 0,
    this.votes = 0,
    this.shares = 0,
    this.isLiked = false,
    this.isVoted = false,
    this.theme,
    required this.createdAt,
    this.date,
  });

  final int id;
  final String text;
  final String reference;
  final String translation;
  final String book;
  final int chapter;
  @JsonKey(name: 'verse')
  final int verseNumber;
  final int likes;
  final int votes;
  final int shares;
  final bool isLiked;
  final bool isVoted;
  final VerseTheme? theme;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  final DateTime? date;

  factory Verse.fromJson(Map<String, dynamic> json) => _$VerseFromJson(json);

  Map<String, dynamic> toJson() => _$VerseToJson(this);
}

@JsonSerializable()
class VerseTheme {
  const VerseTheme({
    required this.id,
    required this.name,
    this.color,
  });

  final int id;
  final String name;
  final String? color;

  factory VerseTheme.fromJson(Map<String, dynamic> json) => _$VerseThemeFromJson(json);

  Map<String, dynamic> toJson() => _$VerseThemeToJson(this);
}
