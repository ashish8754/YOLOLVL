// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 2;

  @override
  User read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return User(
      id: fields[0] as String,
      name: fields[1] as String,
      avatarPath: fields[2] as String?,
      level: fields[3] as int,
      currentEXP: fields[4] as double,
      stats: (fields[5] as Map).cast<String, double>(),
      createdAt: fields[6] as DateTime,
      lastActive: fields[7] as DateTime,
      hasCompletedOnboarding: fields[8] as bool,
      lastActivityDates: (fields[9] as Map?)?.cast<String, DateTime>(),
    );
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.avatarPath)
      ..writeByte(3)
      ..write(obj.level)
      ..writeByte(4)
      ..write(obj.currentEXP)
      ..writeByte(5)
      ..write(obj.stats)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.lastActive)
      ..writeByte(8)
      ..write(obj.hasCompletedOnboarding)
      ..writeByte(9)
      ..write(obj.lastActivityDates);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
