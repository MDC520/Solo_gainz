// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_stats.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserStatsAdapter extends TypeAdapter<UserStats> {
  @override
  final int typeId = 0;

  @override
  UserStats read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserStats(
      rank: fields[0] as String? ?? 'E',
      level: fields[1] as int? ?? 1,
      xp: fields[2] as int? ?? 0,
      coins: fields[3] as int? ?? 0,
      progress: fields[4] as int? ?? 0,
      lastDailyRefresh: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, UserStats obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.rank)
      ..writeByte(1)
      ..write(obj.level)
      ..writeByte(2)
      ..write(obj.xp)
      ..writeByte(3)
      ..write(obj.coins)
      ..writeByte(4)
      ..write(obj.progress)
      ..writeByte(5)
      ..write(obj.lastDailyRefresh);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserStatsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DailyQuestAdapter extends TypeAdapter<DailyQuest> {
  @override
  final int typeId = 1;

  @override
  DailyQuest read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyQuest(
      questName: fields[0] as String,
      questType: fields[1] as String,
      maxGoal: fields[2] as int,
      currentProgress: fields[3] as int? ?? 0,
      xpReward: fields[4] as int,
      completed: fields[5] as bool? ?? false,
      createdDate: fields[6] as DateTime?,
      system: fields[7] as String? ?? 'reps',
    );
  }

  @override
  void write(BinaryWriter writer, DailyQuest obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.questName)
      ..writeByte(1)
      ..write(obj.questType)
      ..writeByte(2)
      ..write(obj.maxGoal)
      ..writeByte(3)
      ..write(obj.currentProgress)
      ..writeByte(4)
      ..write(obj.xpReward)
      ..writeByte(5)
      ..write(obj.completed)
      ..writeByte(6)
      ..write(obj.createdDate)
      ..writeByte(7)
      ..write(obj.system);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyQuestAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
