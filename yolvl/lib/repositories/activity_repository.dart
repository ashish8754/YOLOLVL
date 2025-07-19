import '../models/activity_log.dart';
import '../models/enums.dart';
import '../utils/hive_config.dart';
import 'base_repository.dart';

/// Repository for ActivityLog data operations
class ActivityRepository extends BaseRepository<ActivityLog> {
  ActivityRepository() : super(HiveConfig.activityBoxName);

  /// Save a new activity log
  Future<void> logActivity(ActivityLog activityLog) async {
    try {
      await box.put(activityLog.id, activityLog);
    } catch (e) {
      throw RepositoryException('Failed to log activity: $e');
    }
  }

  /// Get activity logs by date range
  List<ActivityLog> findByDateRange(DateTime startDate, DateTime endDate) {
    try {
      return findAll()
          .where((log) =>
              log.timestamp.isAfter(startDate.subtract(const Duration(days: 1))) &&
              log.timestamp.isBefore(endDate.add(const Duration(days: 1))))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Most recent first
    } catch (e) {
      throw RepositoryException('Failed to find activities by date range: $e');
    }
  }

  /// Get activity logs by activity type
  List<ActivityLog> findByActivityType(ActivityType activityType) {
    try {
      return findAll()
          .where((log) => log.activityType == activityType.name)
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Most recent first
    } catch (e) {
      throw RepositoryException('Failed to find activities by type: $e');
    }
  }

  /// Get activity logs for today
  List<ActivityLog> findTodaysActivities() {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      return findByDateRange(startOfDay, endOfDay);
    } catch (e) {
      throw RepositoryException('Failed to find today\'s activities: $e');
    }
  }

  /// Get activity logs for this week
  List<ActivityLog> findThisWeeksActivities() {
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      
      return findByDateRange(startOfWeekDay, now);
    } catch (e) {
      throw RepositoryException('Failed to find this week\'s activities: $e');
    }
  }

  /// Get activity logs for this month
  List<ActivityLog> findThisMonthsActivities() {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      
      return findByDateRange(startOfMonth, now);
    } catch (e) {
      throw RepositoryException('Failed to find this month\'s activities: $e');
    }
  }

  /// Get recent activity logs (last N entries)
  List<ActivityLog> findRecentActivities({int limit = 10}) {
    try {
      final allActivities = findAll()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Most recent first
      
      return allActivities.take(limit).toList();
    } catch (e) {
      throw RepositoryException('Failed to find recent activities: $e');
    }
  }

  /// Get activity logs with pagination
  List<ActivityLog> findWithPagination({int page = 0, int pageSize = 20}) {
    try {
      final allActivities = findAll()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Most recent first
      
      final startIndex = page * pageSize;
      final endIndex = (startIndex + pageSize).clamp(0, allActivities.length);
      
      if (startIndex >= allActivities.length) {
        return [];
      }
      
      return allActivities.sublist(startIndex, endIndex);
    } catch (e) {
      throw RepositoryException('Failed to find activities with pagination: $e');
    }
  }

  /// Get activity statistics for a date range
  Map<ActivityType, ActivityStats> getActivityStats(DateTime startDate, DateTime endDate) {
    try {
      final activities = findByDateRange(startDate, endDate);
      final Map<ActivityType, ActivityStats> stats = {};
      
      for (final activity in activities) {
        final type = activity.activityTypeEnum;
        if (!stats.containsKey(type)) {
          stats[type] = ActivityStats(
            activityType: type,
            totalSessions: 0,
            totalDuration: 0,
            totalEXP: 0.0,
            averageDuration: 0.0,
          );
        }
        
        final stat = stats[type]!;
        stat.totalSessions++;
        stat.totalDuration += activity.durationMinutes;
        stat.totalEXP += activity.expGained;
        stat.averageDuration = stat.totalDuration / stat.totalSessions;
      }
      
      return stats;
    } catch (e) {
      throw RepositoryException('Failed to get activity stats: $e');
    }
  }

  /// Get streak count for activity type
  int getActivityStreak(ActivityType activityType) {
    try {
      final activities = findByActivityType(activityType);
      if (activities.isEmpty) return 0;
      
      int streak = 0;
      final now = DateTime.now();
      
      // Check each day going backwards
      for (int i = 0; i < 365; i++) { // Max 365 days streak
        final checkDate = now.subtract(Duration(days: i));
        final dayStart = DateTime(checkDate.year, checkDate.month, checkDate.day);
        final dayEnd = dayStart.add(const Duration(days: 1));
        
        final hasActivityOnDay = activities.any((activity) =>
            activity.timestamp.isAfter(dayStart) && activity.timestamp.isBefore(dayEnd));
        
        if (hasActivityOnDay) {
          streak++;
        } else {
          break;
        }
      }
      
      return streak;
    } catch (e) {
      throw RepositoryException('Failed to get activity streak: $e');
    }
  }

  /// Get last activity date for activity type
  DateTime? getLastActivityDate(ActivityType activityType) {
    try {
      final activities = findByActivityType(activityType);
      return activities.isNotEmpty ? activities.first.timestamp : null;
    } catch (e) {
      throw RepositoryException('Failed to get last activity date: $e');
    }
  }

  /// Delete activities older than specified days
  Future<int> deleteOldActivities({int olderThanDays = 365}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: olderThanDays));
      final oldActivities = findAll()
          .where((activity) => activity.timestamp.isBefore(cutoffDate))
          .toList();
      
      for (final activity in oldActivities) {
        await delete(activity);
      }
      
      return oldActivities.length;
    } catch (e) {
      throw RepositoryException('Failed to delete old activities: $e');
    }
  }

  /// Get all activities (for data integrity checks)
  Future<List<ActivityLog>> getAllActivities() async {
    try {
      return findAll();
    } catch (e) {
      throw RepositoryException('Failed to get all activities: $e');
    }
  }

  /// Clear all activities (for data integrity recovery)
  Future<void> clearAllActivities() async {
    try {
      final activities = findAll();
      for (final activity in activities) {
        await delete(activity);
      }
    } catch (e) {
      throw RepositoryException('Failed to clear all activities: $e');
    }
  }

  @override
  bool validateEntity(ActivityLog entity) {
    // Validate activity log data
    if (entity.id.isEmpty) {
      return false;
    }
    if (entity.durationMinutes <= 0) {
      return false;
    }
    if (entity.expGained < 0) {
      return false;
    }
    // Validate activity type exists
    try {
      ActivityType.values.firstWhere((type) => type.name == entity.activityType);
    } catch (e) {
      return false;
    }
    return true;
  }
}

/// Statistics for an activity type
class ActivityStats {
  final ActivityType activityType;
  int totalSessions;
  int totalDuration;
  double totalEXP;
  double averageDuration;
  
  ActivityStats({
    required this.activityType,
    required this.totalSessions,
    required this.totalDuration,
    required this.totalEXP,
    required this.averageDuration,
  });
  
  @override
  String toString() {
    return 'ActivityStats(type: ${activityType.displayName}, sessions: $totalSessions, duration: ${totalDuration}m, exp: $totalEXP)';
  }
}