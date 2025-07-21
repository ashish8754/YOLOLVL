import 'package:hive/hive.dart';
import 'enums.dart';

part 'activity_log.g.dart';

/// Activity log model representing a logged activity session
@HiveType(typeId: 3)
class ActivityLog extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String activityType; // ActivityType.name

  @HiveField(2)
  int durationMinutes;

  @HiveField(3)
  DateTime timestamp;

  @HiveField(4)
  Map<String, double> statGains; // StatType.name -> exact gain value (used for stat reversal)

  @HiveField(5)
  double expGained;

  @HiveField(6)
  String? notes;

  ActivityLog({
    required this.id,
    required this.activityType,
    required this.durationMinutes,
    required this.timestamp,
    required this.statGains,
    required this.expGained,
    this.notes,
  });

  /// Create a new activity log
  factory ActivityLog.create({
    required String id,
    required ActivityType activityType,
    required int durationMinutes,
    required Map<StatType, double> statGains,
    required double expGained,
    String? notes,
    DateTime? timestamp,
  }) {
    return ActivityLog(
      id: id,
      activityType: activityType.name,
      durationMinutes: durationMinutes,
      timestamp: timestamp ?? DateTime.now(),
      statGains: statGains.map((key, value) => MapEntry(key.name, value)),
      expGained: expGained,
      notes: notes,
    );
  }

  /// Get ActivityType enum from stored string
  ActivityType get activityTypeEnum {
    return ActivityType.values.firstWhere(
      (type) => type.name == activityType,
      orElse: () => ActivityType.workoutWeights,
    );
  }

  /// Get stat gains as Map with StatType keys and double values
  /// Includes data migration logic for activities without stored gains
  Map<StatType, double> get statGainsMap {
    final Map<StatType, double> result = {};
    
    // If statGains is empty or null, calculate gains using original activity mapping
    if (statGains.isEmpty) {
      return _calculateFallbackStatGains();
    }
    
    for (final entry in statGains.entries) {
      final statType = StatType.values.firstWhere(
        (type) => type.name == entry.key,
        orElse: () => StatType.strength,
      );
      result[statType] = entry.value;
    }
    return result;
  }

  /// Calculate stat gains using original activity mapping for data migration
  /// This is used for activities logged before stat gains were stored
  Map<StatType, double> _calculateFallbackStatGains() {
    // Import StatsService to calculate gains
    // Note: This creates a circular dependency, so we'll implement the calculation inline
    final gains = <StatType, double>{};
    final durationHours = durationMinutes / 60.0;
    final activityTypeEnum = this.activityTypeEnum;

    switch (activityTypeEnum) {
      case ActivityType.workoutWeights:
        gains[StatType.strength] = 0.06 * durationHours;
        gains[StatType.endurance] = 0.04 * durationHours;
        break;

      case ActivityType.workoutCardio:
        gains[StatType.agility] = 0.06 * durationHours;
        gains[StatType.endurance] = 0.04 * durationHours;
        break;

      case ActivityType.workoutYoga:
        gains[StatType.agility] = 0.05 * durationHours;
        gains[StatType.focus] = 0.03 * durationHours;
        break;

      case ActivityType.studySerious:
        gains[StatType.intelligence] = 0.06 * durationHours;
        gains[StatType.focus] = 0.04 * durationHours;
        break;

      case ActivityType.studyCasual:
        gains[StatType.intelligence] = 0.04 * durationHours;
        gains[StatType.charisma] = 0.03 * durationHours;
        break;

      case ActivityType.meditation:
        gains[StatType.focus] = 0.05 * durationHours;
        break;

      case ActivityType.socializing:
        gains[StatType.charisma] = 0.05 * durationHours;
        gains[StatType.focus] = 0.02 * durationHours;
        break;

      case ActivityType.sleepTracking:
        gains[StatType.endurance] = 0.02 * durationHours;
        break;

      case ActivityType.dietHealthy:
        gains[StatType.endurance] = 0.03 * durationHours;
        break;

      case ActivityType.quitBadHabit:
        // Fixed amount, not per hour
        gains[StatType.focus] = 0.03;
        break;
    }

    return gains;
  }

  /// Get formatted duration string
  String get formattedDuration {
    if (durationMinutes < 60) {
      return '${durationMinutes}m';
    } else {
      final hours = durationMinutes ~/ 60;
      final minutes = durationMinutes % 60;
      if (minutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${minutes}m';
      }
    }
  }

  /// Get formatted timestamp string
  String get formattedTimestamp {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
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

  /// Check if this log is from today
  bool get isToday {
    final now = DateTime.now();
    return timestamp.year == now.year &&
           timestamp.month == now.month &&
           timestamp.day == now.day;
  }

  /// Check if this log is from this week
  bool get isThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return timestamp.isAfter(startOfWeek);
  }

  /// Check if this activity has stored stat gains (for data migration purposes)
  bool get hasStoredStatGains {
    return statGains.isNotEmpty;
  }

  /// Check if this activity needs stat gain migration
  bool get needsStatGainMigration {
    return !hasStoredStatGains;
  }

  /// Migrate stat gains data for activities that don't have stored gains
  /// This updates the activity log with calculated stat gains for stat reversal support
  void migrateStatGains() {
    if (hasStoredStatGains) {
      return; // Already has stored gains, no migration needed
    }

    final calculatedGains = _calculateFallbackStatGains();
    statGains = calculatedGains.map((key, value) => MapEntry(key.name, value));
  }

  /// Copy activity log with updated values
  ActivityLog copyWith({
    String? id,
    String? activityType,
    int? durationMinutes,
    DateTime? timestamp,
    Map<String, double>? statGains,
    double? expGained,
    String? notes,
  }) {
    return ActivityLog(
      id: id ?? this.id,
      activityType: activityType ?? this.activityType,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      timestamp: timestamp ?? this.timestamp,
      statGains: statGains ?? Map<String, double>.from(this.statGains),
      expGained: expGained ?? this.expGained,
      notes: notes ?? this.notes,
    );
  }

  /// Convert to JSON for backup/export
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activityType': activityType,
      'durationMinutes': durationMinutes,
      'timestamp': timestamp.toIso8601String(),
      'statGains': statGains,
      'expGained': expGained,
      'notes': notes,
    };
  }

  /// Create from JSON for backup/import
  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id'],
      activityType: json['activityType'],
      durationMinutes: json['durationMinutes'],
      timestamp: DateTime.parse(json['timestamp']),
      statGains: Map<String, double>.from(json['statGains']),
      expGained: json['expGained'].toDouble(),
      notes: json['notes'],
    );
  }

  @override
  String toString() {
    return 'ActivityLog(id: $id, type: $activityType, duration: ${durationMinutes}m, exp: $expGained)';
  }
}