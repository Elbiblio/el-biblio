import 'mission_focus.dart';

class MissionAction {
  static const _unset = Object();

  const MissionAction({
    required this.id,
    required this.title,
    required this.description,
    required this.focus,
    required this.createdAt,
    this.completedAt,
    this.personName,
    this.notes,
    this.requiresFollowUp = false,
    this.followUpCompletedAt,
    this.evangelismContentId,
  });

  final String id;
  final String title;
  final String description;
  final MissionFocusType focus;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? personName;
  final String? notes;
  final bool requiresFollowUp;
  final DateTime? followUpCompletedAt;
  final String? evangelismContentId;

  bool get isCompleted => completedAt != null;

  factory MissionAction.fromMap(Map<String, dynamic> map) {
    return MissionAction(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      focus: MissionFocusTypeX.fromStorage(map['focus'] as String?),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      completedAt: map['completedAt'] == null
          ? null
          : DateTime.tryParse(map['completedAt'] as String),
      personName: map['personName'] as String?,
      notes: map['notes'] as String?,
      requiresFollowUp: map['requiresFollowUp'] as bool? ?? false,
      followUpCompletedAt: map['followUpCompletedAt'] == null
          ? null
          : DateTime.tryParse(map['followUpCompletedAt'] as String),
      evangelismContentId: map['evangelismContentId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'focus': focus.name,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'personName': personName,
      'notes': notes,
      'requiresFollowUp': requiresFollowUp,
      'followUpCompletedAt': followUpCompletedAt?.toIso8601String(),
      'evangelismContentId': evangelismContentId,
    };
  }

  MissionAction copyWith({
    String? id,
    String? title,
    String? description,
    MissionFocusType? focus,
    DateTime? createdAt,
    Object? completedAt = _unset,
    Object? personName = _unset,
    Object? notes = _unset,
    bool? requiresFollowUp,
    Object? followUpCompletedAt = _unset,
    Object? evangelismContentId = _unset,
  }) {
    return MissionAction(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      focus: focus ?? this.focus,
      createdAt: createdAt ?? this.createdAt,
      completedAt: identical(completedAt, _unset)
          ? this.completedAt
          : completedAt as DateTime?,
      personName: identical(personName, _unset)
          ? this.personName
          : personName as String?,
      notes: identical(notes, _unset)
          ? this.notes
          : notes as String?,
      requiresFollowUp: requiresFollowUp ?? this.requiresFollowUp,
      followUpCompletedAt: identical(followUpCompletedAt, _unset)
          ? this.followUpCompletedAt
          : followUpCompletedAt as DateTime?,
      evangelismContentId: identical(evangelismContentId, _unset)
          ? this.evangelismContentId
          : evangelismContentId as String?,
    );
  }
}
