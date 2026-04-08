// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accountability_check_in.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AccountabilityCheckInImpl _$$AccountabilityCheckInImplFromJson(
        Map<String, dynamic> json) =>
    _$AccountabilityCheckInImpl(
      id: json['id'] as String,
      requesterUserId: json['requesterUserId'] as String,
      partnerUserId: json['partnerUserId'] as String,
      weekStartDate: DateTime.parse(json['weekStartDate'] as String),
      requesterNote: json['requesterNote'] as String?,
      verifiedCommitmentIds: (json['verifiedCommitmentIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      requestedAt: DateTime.parse(json['requestedAt'] as String),
      confirmedAt: json['confirmedAt'] == null
          ? null
          : DateTime.parse(json['confirmedAt'] as String),
      confirmationNote: json['confirmationNote'] as String?,
      partnerVerifiedCommitments:
          (json['partnerVerifiedCommitments'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
      status: json['status'] as String? ?? 'pending',
      weekStreak: (json['weekStreak'] as num?)?.toInt() ?? 0,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      requester: json['requester'] as Map<String, dynamic>?,
      partner: json['partner'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$AccountabilityCheckInImplToJson(
        _$AccountabilityCheckInImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'requesterUserId': instance.requesterUserId,
      'partnerUserId': instance.partnerUserId,
      'weekStartDate': instance.weekStartDate.toIso8601String(),
      'requesterNote': instance.requesterNote,
      'verifiedCommitmentIds': instance.verifiedCommitmentIds,
      'requestedAt': instance.requestedAt.toIso8601String(),
      'confirmedAt': instance.confirmedAt?.toIso8601String(),
      'confirmationNote': instance.confirmationNote,
      'partnerVerifiedCommitments': instance.partnerVerifiedCommitments,
      'status': instance.status,
      'weekStreak': instance.weekStreak,
      'metadata': instance.metadata,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'requester': instance.requester,
      'partner': instance.partner,
    };
