// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SettingsAdapter extends TypeAdapter<Settings> {
  @override
  final int typeId = 4;

  @override
  Settings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Settings(
      isDarkMode: fields[0] as bool,
      notificationsEnabled: fields[1] as bool,
      enabledActivities: (fields[2] as List).cast<String>(),
      customStatIncrements: (fields[3] as Map).cast<String, double>(),
      relaxedWeekendMode: fields[4] as bool,
      lastBackupDate: fields[5] as DateTime,
      dailyReminderHour: fields[6] as int,
      dailyReminderMinute: fields[7] as int,
      degradationWarningsEnabled: fields[8] as bool,
      levelUpAnimationsEnabled: fields[9] as bool,
      hapticFeedbackEnabled: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Settings obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.isDarkMode)
      ..writeByte(1)
      ..write(obj.notificationsEnabled)
      ..writeByte(2)
      ..write(obj.enabledActivities)
      ..writeByte(3)
      ..write(obj.customStatIncrements)
      ..writeByte(4)
      ..write(obj.relaxedWeekendMode)
      ..writeByte(5)
      ..write(obj.lastBackupDate)
      ..writeByte(6)
      ..write(obj.dailyReminderHour)
      ..writeByte(7)
      ..write(obj.dailyReminderMinute)
      ..writeByte(8)
      ..write(obj.degradationWarningsEnabled)
      ..writeByte(9)
      ..write(obj.levelUpAnimationsEnabled)
      ..writeByte(10)
      ..write(obj.hapticFeedbackEnabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
