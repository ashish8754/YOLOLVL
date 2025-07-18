// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ActivityLogAdapter extends TypeAdapter<ActivityLog> {
  @override
  final int typeId = 3;

  @override
  ActivityLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ActivityLog(
      id: fields[0] as String,
      activityType: fields[1] as String,
      durationMinutes: fields[2] as int,
      timestamp: fields[3] as DateTime,
      statGains: (fields[4] as Map).cast<String, double>(),
      expGained: fields[5] as double,
      notes: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ActivityLog obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.activityType)
      ..writeByte(2)
      ..write(obj.durationMinutes)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.statGains)
      ..writeByte(5)
      ..write(obj.expGained)
      ..writeByte(6)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
