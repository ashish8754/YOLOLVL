import 'package:hive/hive.dart';
import 'enums.dart';

part 'achievement.g.dart';

/// Achievement model representing unlockable badges and milestones
@HiveType(typeId: 5)
class Achievement extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String achievementType; // AchievementType.name

  @HiveField(2)
  DateTime unlockedAt;

  @HiveField(3)
  int? value; // Associated value (e.g., level reached, streak days)

  @HiveField(4)
  Map<String, dynamic>? metadata; // Additional data

  Achievement({
    required this.id,
    required this.achievementType,
    required this.unlockedAt,
    this.value,
    this.metadata,
  });

  /// Create a new achievement
  factory Achievement.create({
    required String id,
    required AchievementType achievementType,
    int? value,
    Map<String, dynamic>? metadata,
    DateTime? unlockedAt,
  }) {
    return Achievement(
      id: id,
      achievementType: achievementType.name,
      unlockedAt: unlockedAt ?? DateTime.now(),
      value: value,
      metadata: metadata,
    );
  }

  /// Get AchievementType enum from stored string
  AchievementType get achievementTypeEnum {
    return AchievementType.values.firstWhere(
      (type) => type.name == achievementType,
      orElse: () => AchievementType.firstActivity,
    );
  }

  /// Get formatted unlock time
  String get formattedUnlockTime {
    final now = DateTime.now();
    final difference = now.difference(unlockedAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  /// Convert to JSON for backup/export
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'achievementType': achievementType,
      'unlockedAt': unlockedAt.toIso8601String(),
      'value': value,
      'metadata': metadata,
    };
  }

  /// Create from JSON for backup/import
  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      achievementType: json['achievementType'],
      unlockedAt: DateTime.parse(json['unlockedAt']),
      value: json['value'],
      metadata: json['metadata'] != null 
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }

  @override
  String toString() {
    return 'Achievement(id: $id, type: $achievementType, value: $value)';
  }
}

/// Achievement progress tracking for locked achievements
class AchievementProgress {
  final AchievementType type;
  final int currentValue;
  final int targetValue;
  final double progress;
  final bool isUnlocked;

  AchievementProgress({
    required this.type,
    required this.currentValue,
    required this.targetValue,
    required this.isUnlocked,
  }) : progress = isUnlocked ? 1.0 : (currentValue / targetValue).clamp(0.0, 1.0);

  /// Get progress percentage (0-100)
  int get progressPercentage => (progress * 100).round();

  /// Check if achievement is ready to unlock
  bool get canUnlock => currentValue >= targetValue && !isUnlocked;
}

/// Achievement unlock result
class AchievementUnlockResult {
  final Achievement achievement;
  final bool isNewUnlock;
  final String message;

  AchievementUnlockResult({
    required this.achievement,
    required this.isNewUnlock,
    required this.message,
  });
}