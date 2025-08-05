// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_reward.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RewardItemAdapter extends TypeAdapter<RewardItem> {
  @override
  final int typeId = 11;

  @override
  RewardItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RewardItem(
      type: fields[0] as RewardType,
      value: fields[1] as double,
      statType: fields[2] as StatType?,
      itemName: fields[3] as String?,
      description: fields[4] as String?,
      isRare: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, RewardItem obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.value)
      ..writeByte(2)
      ..write(obj.statType)
      ..writeByte(3)
      ..write(obj.itemName)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.isRare);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RewardItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DailyRewardAdapter extends TypeAdapter<DailyReward> {
  @override
  final int typeId = 12;

  @override
  DailyReward read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyReward(
      date: fields[0] as DateTime,
      dayOfMonth: fields[1] as int,
      streakDay: fields[2] as int,
      rewards: (fields[3] as List).cast<RewardItem>(),
      isClaimed: fields[4] as bool,
      claimedAt: fields[5] as DateTime?,
      isMilestone: fields[6] as bool,
      isWeekendBonus: fields[7] as bool,
      isHolidayBonus: fields[8] as bool,
      streakMultiplier: fields[9] as double,
    );
  }

  @override
  void write(BinaryWriter writer, DailyReward obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.dayOfMonth)
      ..writeByte(2)
      ..write(obj.streakDay)
      ..writeByte(3)
      ..write(obj.rewards)
      ..writeByte(4)
      ..write(obj.isClaimed)
      ..writeByte(5)
      ..write(obj.claimedAt)
      ..writeByte(6)
      ..write(obj.isMilestone)
      ..writeByte(7)
      ..write(obj.isWeekendBonus)
      ..writeByte(8)
      ..write(obj.isHolidayBonus)
      ..writeByte(9)
      ..write(obj.streakMultiplier);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyRewardAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RewardTypeAdapter extends TypeAdapter<RewardType> {
  @override
  final int typeId = 10;

  @override
  RewardType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RewardType.exp;
      case 1:
        return RewardType.statBoost;
      case 2:
        return RewardType.achievementProgress;
      case 3:
        return RewardType.specialItem;
      case 4:
        return RewardType.streakMultiplier;
      case 5:
        return RewardType.hunterRankBonus;
      default:
        return RewardType.exp;
    }
  }

  @override
  void write(BinaryWriter writer, RewardType obj) {
    switch (obj) {
      case RewardType.exp:
        writer.writeByte(0);
        break;
      case RewardType.statBoost:
        writer.writeByte(1);
        break;
      case RewardType.achievementProgress:
        writer.writeByte(2);
        break;
      case RewardType.specialItem:
        writer.writeByte(3);
        break;
      case RewardType.streakMultiplier:
        writer.writeByte(4);
        break;
      case RewardType.hunterRankBonus:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RewardTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
