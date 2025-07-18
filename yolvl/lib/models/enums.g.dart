// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enums.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ActivityTypeAdapter extends TypeAdapter<ActivityType> {
  @override
  final int typeId = 0;

  @override
  ActivityType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ActivityType.workoutWeights;
      case 1:
        return ActivityType.workoutCardio;
      case 2:
        return ActivityType.workoutYoga;
      case 3:
        return ActivityType.studySerious;
      case 4:
        return ActivityType.studyCasual;
      case 5:
        return ActivityType.meditation;
      case 6:
        return ActivityType.socializing;
      case 7:
        return ActivityType.quitBadHabit;
      case 8:
        return ActivityType.sleepTracking;
      case 9:
        return ActivityType.dietHealthy;
      default:
        return ActivityType.workoutWeights;
    }
  }

  @override
  void write(BinaryWriter writer, ActivityType obj) {
    switch (obj) {
      case ActivityType.workoutWeights:
        writer.writeByte(0);
        break;
      case ActivityType.workoutCardio:
        writer.writeByte(1);
        break;
      case ActivityType.workoutYoga:
        writer.writeByte(2);
        break;
      case ActivityType.studySerious:
        writer.writeByte(3);
        break;
      case ActivityType.studyCasual:
        writer.writeByte(4);
        break;
      case ActivityType.meditation:
        writer.writeByte(5);
        break;
      case ActivityType.socializing:
        writer.writeByte(6);
        break;
      case ActivityType.quitBadHabit:
        writer.writeByte(7);
        break;
      case ActivityType.sleepTracking:
        writer.writeByte(8);
        break;
      case ActivityType.dietHealthy:
        writer.writeByte(9);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StatTypeAdapter extends TypeAdapter<StatType> {
  @override
  final int typeId = 1;

  @override
  StatType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return StatType.strength;
      case 1:
        return StatType.agility;
      case 2:
        return StatType.endurance;
      case 3:
        return StatType.intelligence;
      case 4:
        return StatType.focus;
      case 5:
        return StatType.charisma;
      default:
        return StatType.strength;
    }
  }

  @override
  void write(BinaryWriter writer, StatType obj) {
    switch (obj) {
      case StatType.strength:
        writer.writeByte(0);
        break;
      case StatType.agility:
        writer.writeByte(1);
        break;
      case StatType.endurance:
        writer.writeByte(2);
        break;
      case StatType.intelligence:
        writer.writeByte(3);
        break;
      case StatType.focus:
        writer.writeByte(4);
        break;
      case StatType.charisma:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
