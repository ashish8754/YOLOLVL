import '../models/enums.dart';

/// Service for handling stat progression calculations
class StatsService {
  /// Calculate stat gains for a given activity type and duration
  /// Returns a map of StatType to gain amount
  static Map<StatType, double> calculateStatGains(ActivityType activityType, int durationMinutes) {
    if (durationMinutes < 0) {
      throw ArgumentError('Duration must be non-negative');
    }

    final gains = <StatType, double>{};
    final durationHours = durationMinutes / 60.0;

    switch (activityType) {
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

  /// Apply stat gains to a user's current stats
  /// Returns a new map with updated stat values
  static Map<StatType, double> applyStatGains(
    Map<StatType, double> currentStats,
    Map<StatType, double> gains,
  ) {
    final updatedStats = <StatType, double>{};
    
    // Initialize with current stats
    for (final statType in StatType.values) {
      updatedStats[statType] = currentStats[statType] ?? 1.0;
    }

    // Apply gains
    for (final entry in gains.entries) {
      updatedStats[entry.key] = (updatedStats[entry.key] ?? 1.0) + entry.value;
    }

    return updatedStats;
  }

  /// Get all stats that are affected by a given activity type
  static List<StatType> getAffectedStats(ActivityType activityType) {
    final gains = calculateStatGains(activityType, 60); // Use 1 hour as reference
    return gains.keys.toList();
  }

  /// Get the primary stat (highest gain) for an activity type
  static StatType? getPrimaryStat(ActivityType activityType) {
    final gains = calculateStatGains(activityType, 60); // Use 1 hour as reference
    
    if (gains.isEmpty) return null;
    
    StatType? primaryStat;
    double maxGain = 0.0;
    
    for (final entry in gains.entries) {
      if (entry.value > maxGain) {
        maxGain = entry.value;
        primaryStat = entry.key;
      }
    }
    
    return primaryStat;
  }

  /// Calculate total stat gains for multiple activities
  static Map<StatType, double> calculateTotalStatGains(
    List<ActivityLogEntry> activities,
  ) {
    final totalGains = <StatType, double>{};
    
    for (final activity in activities) {
      final gains = calculateStatGains(activity.activityType, activity.durationMinutes);
      
      for (final entry in gains.entries) {
        totalGains[entry.key] = (totalGains[entry.key] ?? 0.0) + entry.value;
      }
    }
    
    return totalGains;
  }

  /// Validate stat values (ensure they don't go below minimum)
  static Map<StatType, double> validateStats(Map<StatType, double> stats, {double minValue = 1.0}) {
    final validatedStats = <StatType, double>{};
    
    for (final entry in stats.entries) {
      validatedStats[entry.key] = entry.value < minValue ? minValue : entry.value;
    }
    
    return validatedStats;
  }

  /// Get stat gain rate per hour for an activity type
  static Map<StatType, double> getStatGainRates(ActivityType activityType) {
    return calculateStatGains(activityType, 60); // 60 minutes = 1 hour
  }

  /// Get default stat gains per hour for an activity type (for settings display)
  static Map<StatType, double> getDefaultStatGains(ActivityType activityType) {
    return getStatGainRates(activityType);
  }

  /// Calculate expected gains for preview purposes
  static StatGainPreview calculateExpectedGains(ActivityType activityType, int durationMinutes) {
    final gains = calculateStatGains(activityType, durationMinutes);
    final affectedStats = gains.keys.toList();
    
    return StatGainPreview(
      activityType: activityType,
      durationMinutes: durationMinutes,
      statGains: gains,
      affectedStats: affectedStats,
      primaryStat: getPrimaryStat(activityType),
    );
  }
}

/// Helper class for activity log entries
class ActivityLogEntry {
  final ActivityType activityType;
  final int durationMinutes;
  final DateTime timestamp;

  const ActivityLogEntry({
    required this.activityType,
    required this.durationMinutes,
    required this.timestamp,
  });
}

/// Preview of stat gains for UI display
class StatGainPreview {
  final ActivityType activityType;
  final int durationMinutes;
  final Map<StatType, double> statGains;
  final List<StatType> affectedStats;
  final StatType? primaryStat;

  const StatGainPreview({
    required this.activityType,
    required this.durationMinutes,
    required this.statGains,
    required this.affectedStats,
    this.primaryStat,
  });

  /// Get formatted gain text for a specific stat
  String getGainText(StatType statType) {
    final gain = statGains[statType];
    if (gain == null || gain == 0.0) return '';
    
    return '+${gain.toStringAsFixed(2)}';
  }

  /// Check if this activity affects a specific stat
  bool affectsStat(StatType statType) {
    return statGains.containsKey(statType) && (statGains[statType] ?? 0.0) > 0.0;
  }

  @override
  String toString() {
    return 'StatGainPreview(activityType: $activityType, durationMinutes: $durationMinutes, gains: $statGains)';
  }
}