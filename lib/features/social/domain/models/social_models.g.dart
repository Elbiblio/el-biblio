// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'social_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Contact _$ContactFromJson(Map<String, dynamic> json) => Contact(
      id: (json['id'] as num?)?.toInt(),
      userId: (json['user_id'] as num?)?.toInt(),
      contactUserId: (json['contact_user_id'] as num?)?.toInt(),
      contactHash: json['contact_hash'] as String?,
      displayName: json['display_name'] as String,
      status: $enumDecodeNullable(_$ContactStatusEnumMap, json['status']) ??
          ContactStatus.unknown,
      isAnonymous: json['is_anonymous'] as bool? ?? true,
      sharePresence: json['share_presence'] as bool? ?? true,
      canSeePresence: json['can_see_presence'] as bool? ?? true,
      lastActiveAt: json['last_active_at'] == null
          ? null
          : DateTime.parse(json['last_active_at'] as String),
    );

Map<String, dynamic> _$ContactToJson(Contact instance) => <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'contact_user_id': instance.contactUserId,
      'contact_hash': instance.contactHash,
      'display_name': instance.displayName,
      'status': _$ContactStatusEnumMap[instance.status]!,
      'is_anonymous': instance.isAnonymous,
      'share_presence': instance.sharePresence,
      'can_see_presence': instance.canSeePresence,
      'last_active_at': instance.lastActiveAt?.toIso8601String(),
    };

const _$ContactStatusEnumMap = {
  ContactStatus.pending: 'pending',
  ContactStatus.connected: 'connected',
  ContactStatus.declined: 'declined',
  ContactStatus.blocked: 'blocked',
  ContactStatus.unknown: 'unknown',
};

ContactInvitation _$ContactInvitationFromJson(Map<String, dynamic> json) =>
    ContactInvitation(
      id: (json['id'] as num).toInt(),
      invitedEmail: json['invited_email'] as String?,
      invitedPhone: json['invited_phone'] as String?,
      status: json['status'] as String,
      invitationUrl: json['invitation_url'] as String?,
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );

Map<String, dynamic> _$ContactInvitationToJson(ContactInvitation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'invited_email': instance.invitedEmail,
      'invited_phone': instance.invitedPhone,
      'status': instance.status,
      'invitation_url': instance.invitationUrl,
      'expires_at': instance.expiresAt.toIso8601String(),
    };
