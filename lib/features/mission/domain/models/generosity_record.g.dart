// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generosity_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GenerosityRecordImpl _$$GenerosityRecordImplFromJson(
        Map<String, dynamic> json) =>
    _$GenerosityRecordImpl(
      id: json['id'] as String,
      type: json['type'] as String,
      description: json['description'] as String,
      date: DateTime.parse(json['date'] as String),
      amount: (json['amount'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      recipientName: json['recipientName'] as String?,
      recipientType: json['recipientType'] as String?,
      category: json['category'] as String?,
      isRecurring: json['isRecurring'] as bool? ?? false,
      recurringFrequency: json['recurringFrequency'] as String?,
      notes: json['notes'] as String?,
      impactDescription: json['impactDescription'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$GenerosityRecordImplToJson(
        _$GenerosityRecordImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'description': instance.description,
      'date': instance.date.toIso8601String(),
      'amount': instance.amount,
      'currency': instance.currency,
      'recipientName': instance.recipientName,
      'recipientType': instance.recipientType,
      'category': instance.category,
      'isRecurring': instance.isRecurring,
      'recurringFrequency': instance.recurringFrequency,
      'notes': instance.notes,
      'impactDescription': instance.impactDescription,
      'metadata': instance.metadata,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
