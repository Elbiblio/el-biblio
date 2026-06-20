import 'package:freezed_annotation/freezed_annotation.dart';

part 'generosity_record.freezed.dart';
part 'generosity_record.g.dart';

@freezed
class GenerosityRecord with _$GenerosityRecord {
  const factory GenerosityRecord({
    required String id,
    required String type,
    required String description,
    required DateTime date,
    double? amount,
    @Default('USD') String currency,
    String? recipientName,
    String? recipientType,
    String? category,
    @Default(false) bool isRecurring,
    String? recurringFrequency,
    String? notes,
    String? impactDescription,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _GenerosityRecord;

  factory GenerosityRecord.fromJson(Map<String, dynamic> json) =>
      _$GenerosityRecordFromJson(json);

  factory GenerosityRecord.fromMap(Map<String, dynamic> map) {
    return GenerosityRecord(
      id: map['id'] as String,
      type: map['type'] as String,
      description: map['description'] as String,
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      amount: (map['amount'] as num?)?.toDouble(),
      currency: map['currency'] as String? ?? 'USD',
      recipientName: map['recipient_name'] as String?,
      recipientType: map['recipient_type'] as String?,
      category: map['category'] as String?,
      isRecurring: map['is_recurring'] as bool? ?? false,
      recurringFrequency: map['recurring_frequency'] as String?,
      notes: map['notes'] as String?,
      impactDescription: map['impact_description'] as String?,
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

/// Extension for GenerosityRecord to add custom methods
extension GenerosityRecordExtension on GenerosityRecord {
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'description': description,
      'date': date.toIso8601String(),
      'amount': amount,
      'currency': currency,
      'recipient_name': recipientName,
      'recipient_type': recipientType,
      'category': category,
      'is_recurring': isRecurring,
      'recurring_frequency': recurringFrequency,
      'notes': notes,
      'impact_description': impactDescription,
      'metadata': metadata,
    };
  }

  bool get isFinancial => type == 'financial' && amount != null;
  bool get isTime => type == 'time';
  bool get isResource => type == 'resource';
  bool get isService => type == 'service';
}
