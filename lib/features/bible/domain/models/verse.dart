import 'package:json_annotation/json_annotation.dart';

part 'verse.g.dart';

@JsonSerializable()
class Verse {
  const Verse({
    required this.id,
    required this.text,
    required this.reference,
    this.referenceDisplay,
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
  @JsonKey(name: 'reference_display')
  final String? referenceDisplay;
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

  // Helper to get the best reference display
  String get displayReference => referenceDisplay ?? reference;

  Verse copyWith({
    int? id,
    String? text,
    String? reference,
    String? referenceDisplay,
    String? translation,
    String? book,
    int? chapter,
    int? verseNumber,
    int? likes,
    int? votes,
    int? shares,
    bool? isLiked,
    bool? isVoted,
    VerseTheme? theme,
    DateTime? createdAt,
    DateTime? date,
  }) {
    return Verse(
      id: id ?? this.id,
      text: text ?? this.text,
      reference: reference ?? this.reference,
      referenceDisplay: referenceDisplay ?? this.referenceDisplay,
      translation: translation ?? this.translation,
      book: book ?? this.book,
      chapter: chapter ?? this.chapter,
      verseNumber: verseNumber ?? this.verseNumber,
      likes: likes ?? this.likes,
      votes: votes ?? this.votes,
      shares: shares ?? this.shares,
      isLiked: isLiked ?? this.isLiked,
      isVoted: isVoted ?? this.isVoted,
      theme: theme ?? this.theme,
      createdAt: createdAt ?? this.createdAt,
      date: date ?? this.date,
    );
  }

  factory Verse.fromJson(Map<String, dynamic> json) {
    // Handle type casting safely for fields that might be strings
    final id = json['id'];
    final chapter = json['chapter'];
    final verseNumber = json['verse'];
    final likes = json['likes'];
    final votes = json['votes'];
    final shares = json['shares'];

    return Verse(
      id: id is int
          ? id
          : (id is num ? id.toInt() : int.tryParse(id.toString()) ?? 0),
      text: json['text']?.toString() ?? '',
      reference:
          json['reference']?.toString() ??
          json['reference_display']?.toString() ??
          '',
      referenceDisplay: json['reference_display'] as String?,
      translation: json['translation']?.toString() ?? '',
      book: json['book']?.toString() ?? '',
      chapter: chapter is int
          ? chapter
          : (chapter is num
                ? chapter.toInt()
                : int.tryParse(chapter.toString()) ?? 1),
      verseNumber: verseNumber is int
          ? verseNumber
          : (verseNumber is num
                ? verseNumber.toInt()
                : int.tryParse(verseNumber.toString()) ?? 1),
      likes: likes is int
          ? likes
          : (likes is num
                ? likes.toInt()
                : int.tryParse(likes.toString()) ?? 0),
      votes: votes is int
          ? votes
          : (votes is num
                ? votes.toInt()
                : int.tryParse(votes.toString()) ?? 0),
      shares: shares is int
          ? shares
          : (shares is num
                ? shares.toInt()
                : int.tryParse(shares.toString()) ?? 0),
      isLiked: _boolFromJson(json['isLiked'] ?? json['is_liked']),
      isVoted: _boolFromJson(json['isVoted'] ?? json['is_voted']),
      theme: json['theme'] == null
          ? null
          : VerseTheme.fromJson(json['theme'] as Map<String, dynamic>),
      createdAt: _dateFromJson(json['created_at']) ?? DateTime.now(),
      date: _dateFromJson(json['date']),
    );
  }

  Map<String, dynamic> toJson() => _$VerseToJson(this);
}

bool _boolFromJson(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    return value.toLowerCase() == 'true' || value == '1';
  }
  return false;
}

DateTime? _dateFromJson(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  final normalized = value.toString().replaceFirst(' ', 'T');
  return DateTime.tryParse(normalized);
}

@JsonSerializable()
class VerseTheme {
  const VerseTheme({
    required this.id,
    required this.name,
    this.displayName,
    this.colorCode,
    this.isFoundational,
    this.summary,
    this.related,
    this.subtitle,
    this.description,
    this.practices,
    this.reflection,
    this.meta,
  });

  final int id;
  final String name;
  @JsonKey(name: 'display_name')
  final String? displayName;
  @JsonKey(name: 'color_code')
  final String? colorCode;
  @JsonKey(name: 'is_foundational')
  final bool? isFoundational;
  final String? summary;
  final dynamic related;
  final String? subtitle;
  final String? description;
  final dynamic practices;
  final dynamic reflection;
  final Map<String, dynamic>? meta;

  factory VerseTheme.fromJson(Map<String, dynamic> json) {
    // Handle type casting safely for id field that might be a string
    final id = json['id'];

    return VerseTheme(
      id: id is int
          ? id
          : (id is num ? id.toInt() : int.tryParse(id.toString()) ?? 0),
      name: json['name'] as String,
      displayName: json['display_name'] as String?,
      colorCode: json['color_code'] as String?,
      isFoundational: json['is_foundational'] as bool?,
      summary: json['summary'] as String?,
      related: json['related'],
      subtitle: json['subtitle'] as String?,
      description: json['description'] as String?,
      practices: json['practices'],
      reflection: json['reflection'],
      meta: json['meta'] as Map<String, dynamic>?,
    );
  }

  // Helper to get the best color
  String? get displayColor => colorCode;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'display_name': displayName,
    'color_code': colorCode,
    'is_foundational': isFoundational,
    'summary': summary,
    'related': related,
    'subtitle': subtitle,
    'description': description,
    'practices': practices,
    'reflection': reflection,
    'meta': meta,
  };
}
