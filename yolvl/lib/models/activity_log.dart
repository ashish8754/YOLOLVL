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
  Map<String, double> statGains; // StatType.name -> gain value

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
  Map<StatType, double> get statGainsMap {
    final Map<StatType, double> result = {};
    for (final entry in statGains.entries) {
      final statType = StatType.values.firstWhere(
        (type) => type.name == entry.key,
        orElse: () => StatType.strength,
      );
      result[statType] = entry.value;
    }
    return result;
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