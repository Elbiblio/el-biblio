import 'package:freezed_annotation/freezed_annotation.dart';

part 'accountability_check_in.freezed.dart';
part 'accountability_check_in.g.dart';

@freezed
class AccountabilityCheckIn with _$AccountabilityCheckIn {
  const factory AccountabilityCheckIn({
    required String id,
    required String requesterUserId,
    required String partnerUserId,
    required DateTime weekStartDate,
    String? requesterNote,
    List<String>? verifiedCommitmentIds,
    required DateTime requestedAt,
    DateTime? confirmedAt,
    String? confirmationNote,
    List<String>? partnerVerifiedCommitments,
    @Default('pending') String status,
    @Default(0) int weekStreak,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    // Nested user info (populated when fetching)
    Map<String, dynamic>? requester,
    Map<String, dynamic>? partner,
  }) = _AccountabilityCheckIn;

  factory AccountabilityCheckIn.fromJson(Map<String, dynamic> json) =>
      _$AccountabilityCheckInFromJson(json);

  factory AccountabilityCheckIn.fromMap(Map<String, dynamic> map) {
    return AccountabilityCheckIn(
      id: map['id']?.toString() ?? '',
      requesterUserId: map['requester_user_id']?.toString() ?? '',
      partnerUserId: map['partner_user_id']?.toString() ?? '',
      weekStartDate: DateTime.tryParse(map['week_start_date']?.toString() ?? '') ?? DateTime.now(),
      requesterNote: map['requester_note'] as String?,
      verifiedCommitmentIds:
          (map['verified_commitment_ids'] as List<dynamic>?)?.cast<String>(),
      requestedAt: DateTime.tryParse(map['requested_at']?.toString() ?? '') ?? DateTime.now(),
      confirmedAt: map['confirmed_at'] != null
          ? DateTime.parse(map['confirmed_at'] as String)
          : null,
      confirmationNote: map['confirmation_note'] as String?,
      partnerVerifiedCommitments:
          (map['partner_verified_commitments'] as List<dynamic>?)
              ?.cast<String>(),
      status: map['status'] as String? ?? 'pending',
      weekStreak: map['week_streak'] as int? ?? 0,
      metadata: map['metadata'] as Map<String, dynamic>?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      requester: map['requester'] as Map<String, dynamic>?,
      partner: map['partner'] as Map<String, dynamic>?,
    );
  }
}

/// Extension for AccountabilityCheckIn to add toMap method
extension AccountabilityCheckInExtension on AccountabilityCheckIn {
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'requester_user_id': requesterUserId,
      'partner_user_id': partnerUserId,
      'week_start_date': weekStartDate.toIso8601String(),
      'requester_note': requesterNote,
      'verified_commitment_ids': verifiedCommitmentIds,
      'requested_at': requestedAt.toIso8601String(),
      'confirmed_at': confirmedAt?.toIso8601String(),
      'confirmation_note': confirmationNote,
      'partner_verified_commitments': partnerVerifiedCommitments,
      'status': status,
      'week_streak': weekStreak,
      'metadata': metadata,
    };
  }

  bool get isPending => status == 'pending' && confirmedAt == null;

  bool get isConfirmed => status == 'confirmed' && confirmedAt != null;

  bool get isDeclined => status == 'declined';
}
