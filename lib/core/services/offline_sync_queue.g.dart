// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_sync_queue.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OfflineActionAdapter extends TypeAdapter<OfflineAction> {
  @override
  final int typeId = 50;

  @override
  OfflineAction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OfflineAction(
      actionType: fields[1] as String,
      endpoint: fields[2] as String,
      data: (fields[3] as Map).cast<String, dynamic>(),
      userId: fields[7] as String?,
      metadata: (fields[8] as Map?)?.cast<String, dynamic>(),
      retryCount: fields[5] as int,
      lastRetryAt: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, OfflineAction obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.actionType)
      ..writeByte(2)
      ..write(obj.endpoint)
      ..writeByte(3)
      ..write(obj.data)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.retryCount)
      ..writeByte(6)
      ..write(obj.lastRetryAt)
      ..writeByte(7)
      ..write(obj.userId)
      ..writeByte(8)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfflineActionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
