import '../models/enums.dart';
import '../models/user.dart';

/// Service for handling stat degradation due to missed activities
class DegradationService {
  /// Number of days after which degradation starts
  static const int degradationThresholdDays = 3;
  
  /// Amount of degradation per 3-day period
  static const double degradationPerPeriod = -0.01;
  
  /// Maximum degradation that can be applied at once
  static const double maxDegradationPerApplication = -0.05;
  
  /// Minimum stat value (floor)
  static const double minStatValue = 1.0;

  /// Check if degradation should be applied for a specific activity category
  static bool shouldApplyDegradation(
    ActivityCategory category,
    DateTime? lastActivityDate, {
    bool relaxedWeekendMode = false,
  }) {
    if (lastActivityDate == null) {
      return false; // No previous activity, no degradation
    }

    final now = DateTime.now();
    final daysSinceLastActivity = _calculateDaysSince(lastActivityDate, now, relaxedWeekendMode);
    
    return daysSinceLastActivity >= degradationThresholdDays;
  }

  /// Calculate degradation amount for a specific activity category
  static double calculateDegradation(
    ActivityCategory category,
    DateTime? lastActivityDate, {
    bool relaxedWeekendMode = false,
  }) {
    if (!shouldApplyDegradation(category, lastActivityDate, relaxedWeekendMode: relaxedWeekendMode)) {
      return 0.0;
    }

    final now = DateTime.now();
    final daysSinceLastActivity = _calculateDaysSince(lastActivityDate!, now, relaxedWeekendMode);
    
    // Calculate number of 3-day periods
    final threeDayPeriods = (daysSinceLastActivity / degradationThresholdDays).floor();
    
    // Calculate total degradation
    final totalDegradation = degradationPerPeriod * threeDayPeriods;
    
    // Cap at maximum degradation per application
    return totalDegradation < maxDegradationPerApplication 
        ? maxDegradationPerApplication 
        : totalDegradation;
  }

  /// Get all stats affected by a specific activity category
  static List<StatType> getAffectedStatsByCategory(ActivityCategory category) {
    switch (category) {
      case ActivityCategory.workout:
        return [StatType.strength, StatType.agility, StatType.endurance];
      case ActivityCategory.study:
        return [StatType.intelligence, StatType.focus];
      case ActivityCategory.other:
        return []; // Other activities don't cause degradation
    }
  }

  /// Calculate degradation for all relevant stats based on user's last activity dates
  static Map<StatType, double> calculateAllDegradation(
    User user, {
    bool relaxedWeekendMode = false,
  }) {
    final degradationMap = <StatType, double>{};
    
    // Get last activity dates for each category
    final lastWorkoutDate = _getLastActivityDateForCategory(user, ActivityCategory.workout);
    final lastStudyDate = _getLastActivityDateForCategory(user, ActivityCategory.study);
    
    // Calculate degradation for workout stats
    final workoutDegradation = calculateDegradation(
      ActivityCategory.workout,
      lastWorkoutDate,
      relaxedWeekendMode: relaxedWeekendMode,
    );
    
    if (workoutDegradation < 0) {
      for (final stat in getAffectedStatsByCategory(ActivityCategory.workout)) {
        degradationMap[stat] = workoutDegradation;
      }
    }
    
    // Calculate degradation for study stats
    final studyDegradation = calculateDegradation(
      ActivityCategory.study,
      lastStudyDate,
      relaxedWeekendMode: relaxedWeekendMode,
    );
    
    if (studyDegradation < 0) {
      for (final stat in getAffectedStatsByCategory(ActivityCategory.study)) {
        degradationMap[stat] = studyDegradation;
      }
    }
    
    return degradationMap;
  }

  /// Apply degradation to user stats and return updated user
  static User applyDegradation(
    User user, {
    bool relaxedWeekendMode = false,
  }) {
    final degradationMap = calculateAllDegradation(user, relaxedWeekendMode: relaxedWeekendMode);
    
    if (degradationMap.isEmpty) {
      return user; // No degradation to apply
    }
    
    final updatedStats = Map<String, double>.from(user.stats);
    
    // Apply degradation to each affected stat
    for (final entry in degradationMap.entries) {
      final statName = entry.key.name;
      final currentValue = updatedStats[statName] ?? minStatValue;
      final newValue = (currentValue + entry.value).clamp(minStatValue, double.infinity);
      updatedStats[statName] = newValue;
    }
    
    return user.copyWith(
      stats: updatedStats,
      lastActive: DateTime.now(),
    );
  }

  /// Check if any degradation is pending for the user
  static bool hasPendingDegradation(
    User user, {
    bool relaxedWeekendMode = false,
  }) {
    final degradationMap = calculateAllDegradation(user, relaxedWeekendMode: relaxedWeekendMode);
    return degradationMap.isNotEmpty;
  }

  /// Get degradation warnings for UI display
  static List<DegradationWarning> getDegradationWarnings(
    User user, {
    bool relaxedWeekendMode = false,
  }) {
    final warnings = <DegradationWarning>[];
    
    // Check workout category
    final lastWorkoutDate = _getLastActivityDateForCategory(user, ActivityCategory.workout);
    if (lastWorkoutDate != null) {
      final daysSince = _calculateDaysSince(lastWorkoutDate, DateTime.now(), relaxedWeekendMode);
      if (daysSince >= degradationThresholdDays - 1) { // Warn 1 day before degradation
        warnings.add(DegradationWarning(
          category: ActivityCategory.workout,
          daysSinceLastActivity: daysSince,
          affectedStats: getAffectedStatsByCategory(ActivityCategory.workout),
          isActive: daysSince >= degradationThresholdDays,
        ));
      }
    }
    
    // Check study category
    final lastStudyDate = _getLastActivityDateForCategory(user, ActivityCategory.study);
    if (lastStudyDate != null) {
      final daysSince = _calculateDaysSince(lastStudyDate, DateTime.now(), relaxedWeekendMode);
      if (daysSince >= degradationThresholdDays - 1) { // Warn 1 day before degradation
        warnings.add(DegradationWarning(
          category: ActivityCategory.study,
          daysSinceLastActivity: daysSince,
          affectedStats: getAffectedStatsByCategory(ActivityCategory.study),
          isActive: daysSince >= degradationThresholdDays,
        ));
      }
    }
    
    return warnings;
  }

  /// Calculate days since last activity, optionally excluding weekends
  static int _calculateDaysSince(
    DateTime lastActivity,
    DateTime currentDate, 
    bool relaxedWeekendMode,
  ) {
    if (relaxedWeekendMode) {
      return _calculateWeekdaysSince(lastActivity, currentDate);
    } else {
      return currentDate.difference(lastActivity).inDays;
    }
  }

  /// Calculate weekdays only (excluding weekends) between two dates
  static int _calculateWeekdaysSince(DateTime start, DateTime end) {
    int weekdays = 0;
    DateTime current = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);
    
    while (current.isBefore(endDate)) {
      current = current.add(const Duration(days: 1));
      // Monday = 1, Sunday = 7
      if (current.weekday >= 1 && current.weekday <= 5) {
        weekdays++;
      }
    }
    
    return weekdays;
  }

  /// Get the most recent activity date for a specific category
  static DateTime? _getLastActivityDateForCategory(User user, ActivityCategory category) {
    DateTime? lastDate;
    
    for (final activityType in ActivityType.values) {
      if (activityType.category == category) {
        final activityDate = user.getLastActivityDate(activityType);
        if (activityDate != null) {
          if (lastDate == null || activityDate.isAfter(lastDate)) {
            lastDate = activityDate;
          }
        }
      }
    }
    
    return lastDate;
  }

  /// Reset degradation timer for a specific activity category
  static User resetDegradationTimer(User user, ActivityType activityType) {
    final updatedUser = user.copyWith();
    updatedUser.setLastActivityDate(activityType, DateTime.now());
    return updatedUser;
  }

  /// Get next degradation date for a category
  static DateTime? getNextDegradationDate(
    User user,
    ActivityCategory category, {
    bool relaxedWeekendMode = false,
  }) {
    final lastActivityDate = _getLastActivityDateForCategory(user, category);
    if (lastActivityDate == null) return null;
    
    if (relaxedWeekendMode) {
      // Calculate next degradation date excluding weekends
      DateTime nextDate = lastActivityDate;
      int weekdaysAdded = 0;
      
      while (weekdaysAdded < degradationThresholdDays) {
        nextDate = nextDate.add(const Duration(days: 1));
        if (nextDate.weekday >= 1 && nextDate.weekday <= 5) {
          weekdaysAdded++;
        }
      }
      
      return nextDate;
    } else {
      return lastActivityDate.add(const Duration(days: degradationThresholdDays));
    }
  }
}

/// Warning about potential or active degradation
class DegradationWarning {
  final ActivityCategory category;
  final int daysSinceLastActivity;
  final List<StatType> affectedStats;
  final bool isActive; // True if degradation is already happening

  const DegradationWarning({
    required this.category,
    required this.daysSinceLastActivity,
    required this.affectedStats,
    required this.isActive,
  });

  /// Get user-friendly category name
  String get categoryName {
    switch (category) {
      case ActivityCategory.workout:
        return 'Workout';
      case ActivityCategory.study:
        return 'Study';
      case ActivityCategory.other:
        return 'Other';
    }
  }

  /// Get warning message
  String get message {
    if (isActive) {
      return '$categoryName: $daysSinceLastActivity days without activity - stats degrading!';
    } else {
      return '$categoryName: $daysSinceLastActivity days without activity - degradation starts tomorrow!';
    }
  }

  /// Get severity level
  DegradationSeverity get severity {
    if (daysSinceLastActivity >= DegradationService.degradationThresholdDays + 7) {
      return DegradationSeverity.critical;
    } else if (daysSinceLastActivity >= DegradationService.degradationThresholdDays + 3) {
      return DegradationSeverity.high;
    } else if (isActive) {
      return DegradationSeverity.medium;
    } else {
      return DegradationSeverity.low;
    }
  }

  @override
  String toString() {
    return 'DegradationWarning(category: $category, days: $daysSinceLastActivity, active: $isActive)';
  }
}

/// Severity levels for degradation warnings
enum DegradationSeverity {
  low,    // Warning about upcoming degradation
  medium, // Degradation just started
  high,   // Degradation ongoing for several days
  critical, // Long-term degradation
}