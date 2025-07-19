import 'dart:math';
import 'package:hive/hive.dart';
import 'enums.dart';

part 'user.g.dart';

/// User model representing the player's profile and progression
@HiveType(typeId: 2)
class User extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? avatarPath;

  @HiveField(3)
  int level;

  @HiveField(4)
  double currentEXP;

  @HiveField(5)
  Map<String, double> stats; // StatType.name -> value

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime lastActive;

  @HiveField(8)
  bool hasCompletedOnboarding;

  @HiveField(9)
  Map<String, DateTime> lastActivityDates; // ActivityType.name -> DateTime

  User({
    required this.id,
    required this.name,
    this.avatarPath,
    required this.level,
    required this.currentEXP,
    required this.stats,
    required this.createdAt,
    required this.lastActive,
    required this.hasCompletedOnboarding,
    Map<String, DateTime>? lastActivityDates,
  }) : lastActivityDates = lastActivityDates ?? {};

  /// Create a new user with default values
  factory User.create({
    required String id,
    required String name,
    String? avatarPath,
  }) {
    return User(
      id: id,
      name: name,
      avatarPath: avatarPath,
      level: 1,
      currentEXP: 0.0,
      stats: {
        StatType.strength.name: 1.0,
        StatType.agility.name: 1.0,
        StatType.endurance.name: 1.0,
        StatType.intelligence.name: 1.0,
        StatType.focus.name: 1.0,
        StatType.charisma.name: 1.0,
      },
      createdAt: DateTime.now(),
      lastActive: DateTime.now(),
      hasCompletedOnboarding: false,
    );
  }

  /// Get stat value by StatType
  double getStat(StatType statType) {
    return stats[statType.name] ?? 1.0;
  }

  /// Set stat value by StatType
  void setStat(StatType statType, double value) {
    stats[statType.name] = value;
  }

  /// Add to stat value by StatType
  void addToStat(StatType statType, double value) {
    final currentValue = getStat(statType);
    setStat(statType, currentValue + value);
  }

  /// Get last activity date for ActivityType
  DateTime? getLastActivityDate(ActivityType activityType) {
    return lastActivityDates[activityType.name];
  }

  /// Set last activity date for ActivityType
  void setLastActivityDate(ActivityType activityType, DateTime date) {
    lastActivityDates[activityType.name] = date;
  }

  /// Calculate EXP threshold for current level
  double get expThreshold {
    return 1000.0 * pow(1.2, level - 1).toDouble();
  }

  /// Calculate EXP progress percentage
  double get expProgress {
    return currentEXP / expThreshold;
  }

  /// Check if user can level up
  bool get canLevelUp {
    return currentEXP >= expThreshold;
  }

  /// Level up the user and return excess EXP
  double levelUp() {
    if (!canLevelUp) return 0.0;
    
    final excess = currentEXP - expThreshold;
    level++;
    currentEXP = excess;
    return excess;
  }

  /// Update last active timestamp
  void updateLastActive() {
    lastActive = DateTime.now();
  }

  /// Copy user with updated values
  User copyWith({
    String? id,
    String? name,
    String? avatarPath,
    int? level,
    double? currentEXP,
    Map<String, double>? stats,
    DateTime? createdAt,
    DateTime? lastActive,
    bool? hasCompletedOnboarding,
    Map<String, DateTime>? lastActivityDates,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarPath: avatarPath ?? this.avatarPath,
      level: level ?? this.level,
      currentEXP: currentEXP ?? this.currentEXP,
      stats: stats ?? Map<String, double>.from(this.stats),
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      lastActivityDates: lastActivityDates ?? Map<String, DateTime>.from(this.lastActivityDates),
    );
  }

  /// Convert to JSON for backup/export
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarPath': avatarPath,
      'level': level,
      'currentEXP': currentEXP,
      'stats': stats,
      'createdAt': createdAt.toIso8601String(),
      'lastActive': lastActive.toIso8601String(),
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'lastActivityDates': lastActivityDates.map(
        (key, value) => MapEntry(key, value.toIso8601String()),
      ),
    };
  }

  /// Create from JSON for backup/import
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      avatarPath: json['avatarPath'],
      level: json['level'],
      currentEXP: json['currentEXP'].toDouble(),
      stats: Map<String, double>.from(json['stats']),
      createdAt: DateTime.parse(json['createdAt']),
      lastActive: DateTime.parse(json['lastActive']),
      hasCompletedOnboarding: json['hasCompletedOnboarding'],
      lastActivityDates: (json['lastActivityDates'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, DateTime.parse(value))) ?? {},
    );
  }

  /// Create a default user for data recovery
  factory User.createDefault() {
    final now = DateTime.now();
    return User(
      id: 'user_${now.millisecondsSinceEpoch}',
      name: 'Player',
      avatarPath: null,
      level: 1,
      currentEXP: 0.0,
      stats: {
        StatType.strength.name: 1.0,
        StatType.agility.name: 1.0,
        StatType.endurance.name: 1.0,
        StatType.intelligence.name: 1.0,
        StatType.focus.name: 1.0,
        StatType.charisma.name: 1.0,
      },
      createdAt: now,
      lastActive: now,
      hasCompletedOnboarding: false,
      lastActivityDates: {},
    );
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, level: $level, currentEXP: $currentEXP)';
  }
}