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

class AchievementTypeAdapter extends TypeAdapter<AchievementType> {
  @override
  final int typeId = 6;

  @override
  AchievementType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AchievementType.firstActivity;
      case 1:
        return AchievementType.streak7Days;
      case 2:
        return AchievementType.streak30Days;
      case 3:
        return AchievementType.level5Reached;
      case 4:
        return AchievementType.level10Reached;
      case 5:
        return AchievementType.level25Reached;
      case 6:
        return AchievementType.totalActivities50;
      case 7:
        return AchievementType.totalActivities100;
      case 8:
        return AchievementType.totalActivities500;
      case 9:
        return AchievementType.workoutWarrior;
      case 10:
        return AchievementType.studyScholar;
      case 11:
        return AchievementType.wellRounded;
      default:
        return AchievementType.firstActivity;
    }
  }

  @override
  void write(BinaryWriter writer, AchievementType obj) {
    switch (obj) {
      case AchievementType.firstActivity:
        writer.writeByte(0);
        break;
      case AchievementType.streak7Days:
        writer.writeByte(1);
        break;
      case AchievementType.streak30Days:
        writer.writeByte(2);
        break;
      case AchievementType.level5Reached:
        writer.writeByte(3);
        break;
      case AchievementType.level10Reached:
        writer.writeByte(4);
        break;
      case AchievementType.level25Reached:
        writer.writeByte(5);
        break;
      case AchievementType.totalActivities50:
        writer.writeByte(6);
        break;
      case AchievementType.totalActivities100:
        writer.writeByte(7);
        break;
      case AchievementType.totalActivities500:
        writer.writeByte(8);
        break;
      case AchievementType.workoutWarrior:
        writer.writeByte(9);
        break;
      case AchievementType.studyScholar:
        writer.writeByte(10);
        break;
      case AchievementType.wellRounded:
        writer.writeByte(11);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AchievementTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
