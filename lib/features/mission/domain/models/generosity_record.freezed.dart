// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'generosity_record.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

GenerosityRecord _$GenerosityRecordFromJson(Map<String, dynamic> json) {
  return _GenerosityRecord.fromJson(json);
}

/// @nodoc
mixin _$GenerosityRecord {
  String get id => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  double? get amount => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;
  String? get recipientName => throw _privateConstructorUsedError;
  String? get recipientType => throw _privateConstructorUsedError;
  String? get category => throw _privateConstructorUsedError;
  bool get isRecurring => throw _privateConstructorUsedError;
  String? get recurringFrequency => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  String? get impactDescription => throw _privateConstructorUsedError;
  Map<String, dynamic>? get metadata => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $GenerosityRecordCopyWith<GenerosityRecord> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GenerosityRecordCopyWith<$Res> {
  factory $GenerosityRecordCopyWith(
          GenerosityRecord value, $Res Function(GenerosityRecord) then) =
      _$GenerosityRecordCopyWithImpl<$Res, GenerosityRecord>;
  @useResult
  $Res call(
      {String id,
      String type,
      String description,
      DateTime date,
      double? amount,
      String currency,
      String? recipientName,
      String? recipientType,
      String? category,
      bool isRecurring,
      String? recurringFrequency,
      String? notes,
      String? impactDescription,
      Map<String, dynamic>? metadata,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class _$GenerosityRecordCopyWithImpl<$Res, $Val extends GenerosityRecord>
    implements $GenerosityRecordCopyWith<$Res> {
  _$GenerosityRecordCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? description = null,
    Object? date = null,
    Object? amount = freezed,
    Object? currency = null,
    Object? recipientName = freezed,
    Object? recipientType = freezed,
    Object? category = freezed,
    Object? isRecurring = null,
    Object? recurringFrequency = freezed,
    Object? notes = freezed,
    Object? impactDescription = freezed,
    Object? metadata = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      amount: freezed == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double?,
      currency: null == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
      recipientName: freezed == recipientName
          ? _value.recipientName
          : recipientName // ignore: cast_nullable_to_non_nullable
              as String?,
      recipientType: freezed == recipientType
          ? _value.recipientType
          : recipientType // ignore: cast_nullable_to_non_nullable
              as String?,
      category: freezed == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String?,
      isRecurring: null == isRecurring
          ? _value.isRecurring
          : isRecurring // ignore: cast_nullable_to_non_nullable
              as bool,
      recurringFrequency: freezed == recurringFrequency
          ? _value.recurringFrequency
          : recurringFrequency // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      impactDescription: freezed == impactDescription
          ? _value.impactDescription
          : impactDescription // ignore: cast_nullable_to_non_nullable
              as String?,
      metadata: freezed == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GenerosityRecordImplCopyWith<$Res>
    implements $GenerosityRecordCopyWith<$Res> {
  factory _$$GenerosityRecordImplCopyWith(_$GenerosityRecordImpl value,
          $Res Function(_$GenerosityRecordImpl) then) =
      __$$GenerosityRecordImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String type,
      String description,
      DateTime date,
      double? amount,
      String currency,
      String? recipientName,
      String? recipientType,
      String? category,
      bool isRecurring,
      String? recurringFrequency,
      String? notes,
      String? impactDescription,
      Map<String, dynamic>? metadata,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class __$$GenerosityRecordImplCopyWithImpl<$Res>
    extends _$GenerosityRecordCopyWithImpl<$Res, _$GenerosityRecordImpl>
    implements _$$GenerosityRecordImplCopyWith<$Res> {
  __$$GenerosityRecordImplCopyWithImpl(_$GenerosityRecordImpl _value,
      $Res Function(_$GenerosityRecordImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? description = null,
    Object? date = null,
    Object? amount = freezed,
    Object? currency = null,
    Object? recipientName = freezed,
    Object? recipientType = freezed,
    Object? category = freezed,
    Object? isRecurring = null,
    Object? recurringFrequency = freezed,
    Object? notes = freezed,
    Object? impactDescription = freezed,
    Object? metadata = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$GenerosityRecordImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      amount: freezed == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double?,
      currency: null == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
      recipientName: freezed == recipientName
          ? _value.recipientName
          : recipientName // ignore: cast_nullable_to_non_nullable
              as String?,
      recipientType: freezed == recipientType
          ? _value.recipientType
          : recipientType // ignore: cast_nullable_to_non_nullable
              as String?,
      category: freezed == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String?,
      isRecurring: null == isRecurring
          ? _value.isRecurring
          : isRecurring // ignore: cast_nullable_to_non_nullable
              as bool,
      recurringFrequency: freezed == recurringFrequency
          ? _value.recurringFrequency
          : recurringFrequency // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      impactDescription: freezed == impactDescription
          ? _value.impactDescription
          : impactDescription // ignore: cast_nullable_to_non_nullable
              as String?,
      metadata: freezed == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GenerosityRecordImpl implements _GenerosityRecord {
  const _$GenerosityRecordImpl(
      {required this.id,
      required this.type,
      required this.description,
      required this.date,
      this.amount,
      this.currency = 'USD',
      this.recipientName,
      this.recipientType,
      this.category,
      this.isRecurring = false,
      this.recurringFrequency,
      this.notes,
      this.impactDescription,
      final Map<String, dynamic>? metadata,
      this.createdAt,
      this.updatedAt})
      : _metadata = metadata;

  factory _$GenerosityRecordImpl.fromJson(Map<String, dynamic> json) =>
      _$$GenerosityRecordImplFromJson(json);

  @override
  final String id;
  @override
  final String type;
  @override
  final String description;
  @override
  final DateTime date;
  @override
  final double? amount;
  @override
  @JsonKey()
  final String currency;
  @override
  final String? recipientName;
  @override
  final String? recipientType;
  @override
  final String? category;
  @override
  @JsonKey()
  final bool isRecurring;
  @override
  final String? recurringFrequency;
  @override
  final String? notes;
  @override
  final String? impactDescription;
  final Map<String, dynamic>? _metadata;
  @override
  Map<String, dynamic>? get metadata {
    final value = _metadata;
    if (value == null) return null;
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'GenerosityRecord(id: $id, type: $type, description: $description, date: $date, amount: $amount, currency: $currency, recipientName: $recipientName, recipientType: $recipientType, category: $category, isRecurring: $isRecurring, recurringFrequency: $recurringFrequency, notes: $notes, impactDescription: $impactDescription, metadata: $metadata, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GenerosityRecordImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.recipientName, recipientName) ||
                other.recipientName == recipientName) &&
            (identical(other.recipientType, recipientType) ||
                other.recipientType == recipientType) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.isRecurring, isRecurring) ||
                other.isRecurring == isRecurring) &&
            (identical(other.recurringFrequency, recurringFrequency) ||
                other.recurringFrequency == recurringFrequency) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.impactDescription, impactDescription) ||
                other.impactDescription == impactDescription) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      type,
      description,
      date,
      amount,
      currency,
      recipientName,
      recipientType,
      category,
      isRecurring,
      recurringFrequency,
      notes,
      impactDescription,
      const DeepCollectionEquality().hash(_metadata),
      createdAt,
      updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GenerosityRecordImplCopyWith<_$GenerosityRecordImpl> get copyWith =>
      __$$GenerosityRecordImplCopyWithImpl<_$GenerosityRecordImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GenerosityRecordImplToJson(
      this,
    );
  }
}

abstract class _GenerosityRecord implements GenerosityRecord {
  const factory _GenerosityRecord(
      {required final String id,
      required final String type,
      required final String description,
      required final DateTime date,
      final double? amount,
      final String currency,
      final String? recipientName,
      final String? recipientType,
      final String? category,
      final bool isRecurring,
      final String? recurringFrequency,
      final String? notes,
      final String? impactDescription,
      final Map<String, dynamic>? metadata,
      final DateTime? createdAt,
      final DateTime? updatedAt}) = _$GenerosityRecordImpl;

  factory _GenerosityRecord.fromJson(Map<String, dynamic> json) =
      _$GenerosityRecordImpl.fromJson;

  @override
  String get id;
  @override
  String get type;
  @override
  String get description;
  @override
  DateTime get date;
  @override
  double? get amount;
  @override
  String get currency;
  @override
  String? get recipientName;
  @override
  String? get recipientType;
  @override
  String? get category;
  @override
  bool get isRecurring;
  @override
  String? get recurringFrequency;
  @override
  String? get notes;
  @override
  String? get impactDescription;
  @override
  Map<String, dynamic>? get metadata;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$GenerosityRecordImplCopyWith<_$GenerosityRecordImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
