import 'package:freezed_annotation/freezed_annotation.dart';

part 'person_commitment.freezed.dart';
part 'person_commitment.g.dart';

@freezed
class PersonCommitment with _$PersonCommitment {
  const factory PersonCommitment({
    required String id,
    required String personProfileId,
    required String name,
    required String relationship,
    String? notes,
    String? needs,
    List<String>? tags,
    @Default(true) bool isActive,
    DateTime? lastContactAt,
    DateTime? nextFollowUpAt,
    List<String>? committedActionIds,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _PersonCommitment;

  factory PersonCommitment.fromJson(Map<String, dynamic> json) =>
      _$PersonCommitmentFromJson(json);

  factory PersonCommitment.fromMap(Map<String, dynamic> map) {
    return PersonCommitment(
      id: map['id'] as String,
      personProfileId: map['person_profile_id'] as String,
      name: map['name'] as String,
      relationship: map['relationship'] as String,
      notes: map['notes'] as String?,
      needs: map['needs'] as String?,
      tags: (map['tags'] as List<dynamic>?)?.cast<String>(),
      isActive: map['is_active'] as bool? ?? true,
      lastContactAt: map['last_contact_at'] != null
          ? DateTime.parse(map['last_contact_at'] as String)
          : null,
      nextFollowUpAt: map['next_follow_up_at'] != null
          ? DateTime.parse(map['next_follow_up_at'] as String)
          : null,
      committedActionIds:
          (map['committed_action_ids'] as List<dynamic>?)?.cast<String>(),
      metadata: map['metadata'] as Map<String, dynamic>?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }
}

/// Extension for PersonCommitment to add custom methods
extension PersonCommitmentExtension on PersonCommitment {
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'person_profile_id': personProfileId,
      'name': name,
      'relationship': relationship,
      'notes': notes,
      'needs': needs,
      'tags': tags,
      'is_active': isActive,
      'last_contact_at': lastContactAt?.toIso8601String(),
      'next_follow_up_at': nextFollowUpAt?.toIso8601String(),
      'committed_action_ids': committedActionIds,
      'metadata': metadata,
    };
  }

  bool get needsFollowUp {
    if (!isActive) return false;
    return nextFollowUpAt == null || nextFollowUpAt!.isBefore(DateTime.now());
  }

  int? get committedActionsCount => committedActionIds?.length;
}
