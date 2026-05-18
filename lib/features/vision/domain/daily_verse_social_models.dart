import '../../auth/domain/models/auth_models.dart';

class DailyVerseAuthor {
  const DailyVerseAuthor({this.id, required this.displayName, this.avatar});

  final int? id;
  final String displayName;
  final String? avatar;

  bool get isAnonymousFallback =>
      id == null && displayName == DailyVerseAuthor.anonymous.displayName;

  String get initial {
    final trimmed = displayName.trim();
    return trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
  }

  factory DailyVerseAuthor.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return DailyVerseAuthor.anonymous;

    final firstName = json['first_name']?.toString().trim();
    final lastName = json['last_name']?.toString().trim();
    final fullName = [
      if (firstName?.isNotEmpty == true) firstName,
      if (lastName?.isNotEmpty == true) lastName,
    ].join(' ').trim();

    final displayName =
        _firstNonEmpty([json['display_name'], fullName, firstName]) ??
        'ElBiblio friend';

    return DailyVerseAuthor(
      id: _intFromJson(json['id']),
      displayName: displayName,
      avatar: _stringOrNull(json['avatar']),
    );
  }

  factory DailyVerseAuthor.fromUser(User user) {
    final firstName = user.firstName?.trim();
    final lastName = user.lastName?.trim();
    final fullName = [
      if (firstName?.isNotEmpty == true) firstName,
      if (lastName?.isNotEmpty == true) lastName,
    ].join(' ').trim();

    return DailyVerseAuthor(
      id: int.tryParse(user.id),
      displayName: fullName.isNotEmpty
          ? fullName
          : (firstName?.isNotEmpty == true ? firstName! : 'ElBiblio friend'),
      avatar: user.avatar,
    );
  }

  static const anonymous = DailyVerseAuthor(displayName: 'ElBiblio friend');
}

class DailyVerseComment {
  const DailyVerseComment({
    required this.id,
    required this.reflectionId,
    this.parentId,
    required this.content,
    this.likes = 0,
    this.createdAt,
    required this.author,
    this.isPending = false,
  });

  final int id;
  final int reflectionId;
  final int? parentId;
  final String content;
  final int likes;
  final DateTime? createdAt;
  final DailyVerseAuthor author;
  final bool isPending;

  DailyVerseComment copyWith({
    int? id,
    int? reflectionId,
    int? parentId,
    String? content,
    int? likes,
    DateTime? createdAt,
    DailyVerseAuthor? author,
    bool? isPending,
  }) {
    return DailyVerseComment(
      id: id ?? this.id,
      reflectionId: reflectionId ?? this.reflectionId,
      parentId: parentId ?? this.parentId,
      content: content ?? this.content,
      likes: likes ?? this.likes,
      createdAt: createdAt ?? this.createdAt,
      author: author ?? this.author,
      isPending: isPending ?? this.isPending,
    );
  }

  factory DailyVerseComment.fromJson(Map<String, dynamic> json) {
    return DailyVerseComment(
      id: _intFromJson(json['id']) ?? 0,
      reflectionId: _intFromJson(json['reflection_id']) ?? 0,
      parentId: _intFromJson(json['parent_id']),
      content: json['content']?.toString() ?? '',
      likes: _intFromJson(json['likes']) ?? 0,
      createdAt: _dateFromJson(json['created_at']),
      author: DailyVerseAuthor.fromJson(_mapFromJson(json['user'])),
    );
  }
}

class DailyVerseReflection {
  const DailyVerseReflection({
    required this.id,
    required this.verseId,
    required this.content,
    this.type = 2,
    this.likes = 0,
    this.shares = 0,
    this.createdAt,
    required this.author,
    this.comments = const [],
    this.isPending = false,
  });

  final int id;
  final int verseId;
  final String content;
  final int type;
  final int likes;
  final int shares;
  final DateTime? createdAt;
  final DailyVerseAuthor author;
  final List<DailyVerseComment> comments;
  final bool isPending;

  DailyVerseReflection copyWith({
    int? id,
    int? verseId,
    String? content,
    int? type,
    int? likes,
    int? shares,
    DateTime? createdAt,
    DailyVerseAuthor? author,
    List<DailyVerseComment>? comments,
    bool? isPending,
  }) {
    return DailyVerseReflection(
      id: id ?? this.id,
      verseId: verseId ?? this.verseId,
      content: content ?? this.content,
      type: type ?? this.type,
      likes: likes ?? this.likes,
      shares: shares ?? this.shares,
      createdAt: createdAt ?? this.createdAt,
      author: author ?? this.author,
      comments: comments ?? this.comments,
      isPending: isPending ?? this.isPending,
    );
  }

  factory DailyVerseReflection.fromJson(Map<String, dynamic> json) {
    final comments = payloadList(json['comments'])
        .whereType<Map>()
        .map(
          (item) => DailyVerseComment.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();

    return DailyVerseReflection(
      id: _intFromJson(json['id']) ?? 0,
      verseId: _intFromJson(json['verse_id']) ?? 0,
      content: json['content']?.toString() ?? '',
      type: _intFromJson(json['type']) ?? 2,
      likes: _intFromJson(json['likes']) ?? 0,
      shares: _intFromJson(json['shares']) ?? 0,
      createdAt: _dateFromJson(json['created_at']),
      author: DailyVerseAuthor.fromJson(_mapFromJson(json['user'])),
      comments: comments,
    );
  }
}

class DailyVerseLikeResult {
  const DailyVerseLikeResult({required this.liked});

  final bool liked;

  factory DailyVerseLikeResult.fromJson(Map<String, dynamic> json) {
    return DailyVerseLikeResult(liked: _boolFromJson(json['liked']));
  }
}

class DailyVerseVoteResult {
  const DailyVerseVoteResult({required this.voted, required this.votes});

  final bool voted;
  final int votes;

  factory DailyVerseVoteResult.fromJson(Map<String, dynamic> json) {
    return DailyVerseVoteResult(
      voted: _boolFromJson(json['voted']),
      votes: _intFromJson(json['votes']) ?? 0,
    );
  }
}

class DailyVerseShareResult {
  const DailyVerseShareResult({this.shareUrl, this.platform});

  final String? shareUrl;
  final String? platform;

  factory DailyVerseShareResult.fromJson(Map<String, dynamic> json) {
    return DailyVerseShareResult(
      shareUrl: _stringOrNull(json['share_url']),
      platform: _stringOrNull(json['platform']),
    );
  }
}

List<dynamic> payloadList(dynamic payload) {
  if (payload is List) return payload;
  if (payload is Map && payload['data'] is List) {
    return payload['data'] as List<dynamic>;
  }
  return const [];
}

Map<String, dynamic> payloadMap(dynamic payload) {
  if (payload is Map && payload['data'] is Map) {
    return Map<String, dynamic>.from(payload['data'] as Map);
  }
  if (payload is Map) return Map<String, dynamic>.from(payload);
  return <String, dynamic>{};
}

Map<String, dynamic>? _mapFromJson(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

int? _intFromJson(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

bool _boolFromJson(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.toLowerCase();
    return normalized == 'true' || normalized == '1';
  }
  return false;
}

DateTime? _dateFromJson(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString().replaceFirst(' ', 'T'));
}

String? _stringOrNull(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

String? _firstNonEmpty(List<dynamic> values) {
  for (final value in values) {
    final text = value?.toString().trim();
    if (text != null && text.isNotEmpty) return text;
  }
  return null;
}
