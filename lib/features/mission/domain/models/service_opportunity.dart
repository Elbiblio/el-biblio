import 'package:freezed_annotation/freezed_annotation.dart';

part 'service_opportunity.freezed.dart';
part 'service_opportunity.g.dart';

@freezed
class ServiceOpportunity with _$ServiceOpportunity {
  const factory ServiceOpportunity({
    required String id,
    required String title,
    required String description,
    required String category,
    required String timeCommitment,
    String? organization,
    String? contactInfo,
    List<String>? requiredSkills,
    List<String>? burdenTags,
    List<String>? tendencyTags,
    @Default('local') String locationType,
    @Default('active') String status,
    @Default(0) int volunteerCount,
    int? maxVolunteers,
    DateTime? startsAt,
    DateTime? endsAt,
    String? userMatchStatus,
    double? matchScore,
    List<String>? matchReasons,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _ServiceOpportunity;

  factory ServiceOpportunity.fromJson(Map<String, dynamic> json) =>
      _$ServiceOpportunityFromJson(json);

  factory ServiceOpportunity.fromMap(Map<String, dynamic> map) {
    return ServiceOpportunity(
      id: map['id']?.toString() ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? '',
      timeCommitment: map['time_commitment'] as String? ?? '',
      organization: map['organization'] as String?,
      contactInfo: map['contact_info'] as String?,
      requiredSkills: (map['required_skills'] as List<dynamic>?)?.cast<String>(),
      burdenTags: (map['burden_tags'] as List<dynamic>?)?.cast<String>(),
      tendencyTags: (map['tendency_tags'] as List<dynamic>?)?.cast<String>(),
      locationType: map['location_type'] as String? ?? 'local',
      status: map['status'] as String? ?? 'active',
      volunteerCount: map['volunteer_count'] as int? ?? 0,
      maxVolunteers: map['max_volunteers'] as int?,
      startsAt: map['starts_at'] != null
          ? DateTime.parse(map['starts_at'] as String)
          : null,
      endsAt: map['ends_at'] != null
          ? DateTime.parse(map['ends_at'] as String)
          : null,
      userMatchStatus: map['user_match_status'] as String?,
      matchScore: (map['match_score'] as num?)?.toDouble(),
      matchReasons: (map['match_reasons'] as List<dynamic>?)?.cast<String>(),
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

/// Extension for ServiceOpportunity to add custom methods
extension ServiceOpportunityExtension on ServiceOpportunity {
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'time_commitment': timeCommitment,
      'organization': organization,
      'contact_info': contactInfo,
      'required_skills': requiredSkills,
      'burden_tags': burdenTags,
      'tendency_tags': tendencyTags,
      'location_type': locationType,
      'status': status,
      'volunteer_count': volunteerCount,
      'max_volunteers': maxVolunteers,
      'starts_at': startsAt?.toIso8601String(),
      'ends_at': endsAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  bool get isFull =>
      maxVolunteers != null && volunteerCount >= maxVolunteers!;

  bool get isActive => status == 'active';

  bool get isCommitted => userMatchStatus == 'committed';

  bool get isCompleted => userMatchStatus == 'completed';
}
