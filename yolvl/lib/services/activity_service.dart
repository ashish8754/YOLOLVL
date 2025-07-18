import 'dart:math';
import '../models/activity_log.dart';
import '../models/enums.dart';
import '../models/user.dart';
import '../repositories/activity_repository.dart';
import '../repositories/user_repository.dart';
import 'exp_service.dart';
import 'stats_service.dart';

/// Service for handling activity logging and history operations
class ActivityService {
  final ActivityRepository _activityRepository;
  final UserRepository _userRepository;

  ActivityService({
    ActivityRepository? activityRepository,
    UserRepository? userRepository,
  })  : _activityRepository = activityRepository ?? ActivityRepository(),
        _userRepository = userRepository ?? UserRepository();

  /// Log an activity for the current user
  /// Returns ActivityLogResult with success status and level-up information
  Future<ActivityLogResult> logActivity({
    required ActivityType activityType,
    required int durationMinutes,
    String? notes,
    DateTime? timestamp,
  }) async {
    try {
      // Validate input
      final validationResult = _validateActivityInput(activityType, durationMinutes);
      if (!validationResult.isValid) {
        return ActivityLogResult.error(validationResult.errorMessage!);
      }

      // Get current user
      final user = _userRepository.getCurrentUser();
      if (user == null) {
        return ActivityLogResult.error('No user found. Please complete onboarding first.');
      }

      // Calculate gains
      final statGains = StatsService.calculateStatGains(activityType, durationMinutes);
      final expGain = _calculateEXPGain(activityType, durationMinutes);

      // Create activity log
      final activityLog = ActivityLog.create(
        id: _generateActivityId(),
        activityType: activityType,
        durationMinutes: durationMinutes,
        statGains: statGains,
        expGained: expGain,
        notes: notes,
        timestamp: timestamp ?? DateTime.now(),
      );

      // Update user stats and EXP
      final leveledUp = await _updateUserProgress(user, statGains, expGain, activityType);

      // Save activity log
      await _activityRepository.logActivity(activityLog);

      return ActivityLogResult.success(
        activityLog: activityLog,
        leveledUp: leveledUp,
        newLevel: user.level,
        statGains: statGains,
        expGained: expGain,
      );
    } catch (e) {
      return ActivityLogResult.error('Failed to log activity: $e');
    }
  }

  /// Get activity history with optional filtering
  Future<List<ActivityLog>> getActivityHistory({
    DateTime? startDate,
    DateTime? endDate,
    ActivityType? activityType,
    int? limit,
    int page = 0,
    int pageSize = 20,
  }) async {
    try {
      List<ActivityLog> activities;

      if (startDate != null && endDate != null) {
        // Filter by date range
        activities = _activityRepository.findByDateRange(startDate, endDate);
      } else if (activityType != null) {
        // Filter by activity type
        activities = _activityRepository.findByActivityType(activityType);
      } else {
        // Get all activities with pagination
        activities = _activityRepository.findWithPagination(
          page: page,
          pageSize: pageSize,
        );
      }

      // Apply activity type filter if specified along with date range
      if (activityType != null && (startDate != null || endDate != null)) {
        activities = activities
            .where((log) => log.activityTypeEnum == activityType)
            .toList();
      }

      // Apply limit if specified
      if (limit != null && limit > 0) {
        activities = activities.take(limit).toList();
      }

      return activities;
    } catch (e) {
      throw ActivityServiceException('Failed to get activity history: $e');
    }
  }

  /// Get today's activities
  Future<List<ActivityLog>> getTodaysActivities() async {
    try {
      return _activityRepository.findTodaysActivities();
    } catch (e) {
      throw ActivityServiceException('Failed to get today\'s activities: $e');
    }
  }

  /// Get this week's activities
  Future<List<ActivityLog>> getThisWeeksActivities() async {
    try {
      return _activityRepository.findThisWeeksActivities();
    } catch (e) {
      throw ActivityServiceException('Failed to get this week\'s activities: $e');
    }
  }

  /// Get activity statistics for a date range
  Future<Map<ActivityType, ActivityStats>> getActivityStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();
      
      return _activityRepository.getActivityStats(start, end);
    } catch (e) {
      throw ActivityServiceException('Failed to get activity stats: $e');
    }
  }

  /// Get activity streak for a specific activity type
  Future<int> getActivityStreak(ActivityType activityType) async {
    try {
      return _activityRepository.getActivityStreak(activityType);
    } catch (e) {
      throw ActivityServiceException('Failed to get activity streak: $e');
    }
  }

  /// Get recent activities (last N entries)
  Future<List<ActivityLog>> getRecentActivities({int limit = 10}) async {
    try {
      return _activityRepository.findRecentActivities(limit: limit);
    } catch (e) {
      throw ActivityServiceException('Failed to get recent activities: $e');
    }
  }

  /// Delete an activity log
  Future<bool> deleteActivity(String activityId) async {
    try {
      final activity = _activityRepository.findByKey(activityId);
      if (activity == null) {
        return false;
      }

      await _activityRepository.deleteByKey(activityId);
      return true;
    } catch (e) {
      throw ActivityServiceException('Failed to delete activity: $e');
    }
  }

  /// Calculate expected gains for preview purposes
  ActivityGainPreview calculateExpectedGains({
    required ActivityType activityType,
    required int durationMinutes,
  }) {
    final validationResult = _validateActivityInput(activityType, durationMinutes);
    if (!validationResult.isValid) {
      return ActivityGainPreview.invalid(validationResult.errorMessage!);
    }

    final statGains = StatsService.calculateStatGains(activityType, durationMinutes);
    final expGain = _calculateEXPGain(activityType, durationMinutes);

    return ActivityGainPreview(
      activityType: activityType,
      durationMinutes: durationMinutes,
      statGains: statGains,
      expGained: expGain,
      isValid: true,
    );
  }

  /// Validate activity input
  ActivityValidationResult _validateActivityInput(ActivityType activityType, int durationMinutes) {
    // Check duration is positive
    if (durationMinutes <= 0) {
      return ActivityValidationResult.invalid('Duration must be greater than 0 minutes');
    }

    // Check reasonable duration limits (max 24 hours)
    if (durationMinutes > 1440) {
      return ActivityValidationResult.invalid('Duration cannot exceed 24 hours (1440 minutes)');
    }

    // Special validation for "Quit Bad Habit" - typically should be short duration
    if (activityType == ActivityType.quitBadHabit && durationMinutes > 60) {
      // This is just a warning, not an error - allow but could show warning in UI
    }

    return ActivityValidationResult.valid();
  }

  /// Calculate EXP gain based on activity type and duration
  double _calculateEXPGain(ActivityType activityType, int durationMinutes) {
    if (activityType == ActivityType.quitBadHabit) {
      return 60.0; // Fixed 60 EXP for quit bad habit
    }
    return durationMinutes.toDouble(); // 1 EXP per minute for other activities
  }

  /// Update user progress with stat gains and EXP
  Future<bool> _updateUserProgress(
    User user,
    Map<StatType, double> statGains,
    double expGain,
    ActivityType activityType,
  ) async {
    // Apply stat gains
    for (final entry in statGains.entries) {
      user.addToStat(entry.key, entry.value);
    }

    // Add EXP and check for level up
    final leveledUp = await _userRepository.addEXP(user.id, expGain);

    // Update last activity date
    await _userRepository.updateLastActivityDate(user.id, activityType);

    return leveledUp;
  }

  /// Generate unique activity ID
  String _generateActivityId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(1000);
    return 'activity_${timestamp}_$random';
  }
}

/// Result of activity logging operation
class ActivityLogResult {
  final bool success;
  final String? errorMessage;
  final ActivityLog? activityLog;
  final bool leveledUp;
  final int newLevel;
  final Map<StatType, double> statGains;
  final double expGained;

  const ActivityLogResult._({
    required this.success,
    this.errorMessage,
    this.activityLog,
    this.leveledUp = false,
    this.newLevel = 1,
    this.statGains = const {},
    this.expGained = 0.0,
  });

  factory ActivityLogResult.success({
    required ActivityLog activityLog,
    required bool leveledUp,
    required int newLevel,
    required Map<StatType, double> statGains,
    required double expGained,
  }) {
    return ActivityLogResult._(
      success: true,
      activityLog: activityLog,
      leveledUp: leveledUp,
      newLevel: newLevel,
      statGains: statGains,
      expGained: expGained,
    );
  }

  factory ActivityLogResult.error(String errorMessage) {
    return ActivityLogResult._(
      success: false,
      errorMessage: errorMessage,
    );
  }

  @override
  String toString() {
    if (success) {
      return 'ActivityLogResult(success: true, leveledUp: $leveledUp, newLevel: $newLevel)';
    } else {
      return 'ActivityLogResult(success: false, error: $errorMessage)';
    }
  }
}

/// Validation result for activity input
class ActivityValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ActivityValidationResult._(this.isValid, this.errorMessage);

  factory ActivityValidationResult.valid() {
    return const ActivityValidationResult._(true, null);
  }

  factory ActivityValidationResult.invalid(String errorMessage) {
    return ActivityValidationResult._(false, errorMessage);
  }
}

/// Preview of activity gains for UI display
class ActivityGainPreview {
  final ActivityType activityType;
  final int durationMinutes;
  final Map<StatType, double> statGains;
  final double expGained;
  final bool isValid;
  final String? errorMessage;

  const ActivityGainPreview({
    required this.activityType,
    required this.durationMinutes,
    required this.statGains,
    required this.expGained,
    required this.isValid,
    this.errorMessage,
  });

  factory ActivityGainPreview.invalid(String errorMessage) {
    return ActivityGainPreview(
      activityType: ActivityType.workoutWeights,
      durationMinutes: 0,
      statGains: const {},
      expGained: 0.0,
      isValid: false,
      errorMessage: errorMessage,
    );
  }

  /// Get formatted gain text for a specific stat
  String getStatGainText(StatType statType) {
    final gain = statGains[statType];
    if (gain == null || gain == 0.0) return '';
    return '+${gain.toStringAsFixed(2)}';
  }

  /// Get list of affected stats
  List<StatType> get affectedStats {
    return statGains.keys.where((stat) => statGains[stat]! > 0.0).toList();
  }

  /// Get formatted EXP gain text
  String get expGainText {
    return '+${expGained.toStringAsFixed(0)} EXP';
  }

  @override
  String toString() {
    return 'ActivityGainPreview(type: ${activityType.displayName}, duration: ${durationMinutes}m, exp: +$expGained)';
  }
}

/// Custom exception for activity service operations
class ActivityServiceException implements Exception {
  final String message;

  ActivityServiceException(this.message);

  @override
  String toString() => 'ActivityServiceException: $message';
}