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

  /// Delete an activity with stat and EXP reversal
  /// This method reverses the stat gains and EXP that were applied when the activity was logged
  /// Includes comprehensive error handling, validation, and rollback mechanisms
  Future<ActivityDeletionResult> deleteActivityWithStatReversal(String activityId) async {
    // Input validation
    if (activityId.isEmpty) {
      _logError('deleteActivityWithStatReversal', 'Empty activity ID provided');
      return ActivityDeletionResult.error('Invalid activity ID');
    }

    // Store original state for rollback
    User? originalUser;
    ActivityLog? activityToDelete;

    try {
      // Find the activity to delete
      activityToDelete = _activityRepository.findByKey(activityId);
      if (activityToDelete == null) {
        _logError('deleteActivityWithStatReversal', 'Activity not found: $activityId');
        return ActivityDeletionResult.error('Activity not found');
      }

      // Get current user
      final user = _userRepository.getCurrentUser();
      if (user == null) {
        _logError('deleteActivityWithStatReversal', 'No current user found');
        return ActivityDeletionResult.error('No user found');
      }

      // Store original user state for rollback
      originalUser = User.create(
        id: user.id,
        name: user.name,
        avatarPath: user.avatarPath,
      );
      originalUser.level = user.level;
      originalUser.currentEXP = user.currentEXP;
      originalUser.stats = Map<String, double>.from(user.stats);
      originalUser.lastActivityDates = Map<String, DateTime>.from(user.lastActivityDates);
      originalUser.hasCompletedOnboarding = user.hasCompletedOnboarding;

      // Validate activity data integrity
      if (!_validateActivityForDeletion(activityToDelete)) {
        _logError('deleteActivityWithStatReversal', 'Activity validation failed: ${activityToDelete.id}');
        return ActivityDeletionResult.error('Activity data is invalid and cannot be safely deleted');
      }

      // Calculate stat reversals using stored gains or fallback calculation
      final statReversals = StatsService.calculateStatReversals(
        activityToDelete.activityTypeEnum,
        activityToDelete.durationMinutes,
        activityToDelete.statGainsMap,
      );

      // Validate reversal operation
      final currentStatsMap = user.stats.map((key, value) => MapEntry(
        StatType.values.firstWhere((type) => type.name == key),
        value,
      ));

      // Pre-validate stat reversal
      if (!StatsService.validateStatReversal(currentStatsMap, statReversals)) {
        _logError('deleteActivityWithStatReversal', 'Stat reversal validation failed for activity: ${activityToDelete.id}');
        return ActivityDeletionResult.error('Stat reversal validation failed');
      }

      // Pre-validate EXP reversal
      if (!EXPService.validateEXPReversal(user, activityToDelete.expGained)) {
        _logError('deleteActivityWithStatReversal', 'EXP reversal validation failed for activity: ${activityToDelete.id}');
        return ActivityDeletionResult.error('EXP reversal validation failed');
      }

      // Check for data consistency issues
      if (!_validateDataConsistency(user, activityToDelete, statReversals)) {
        _logError('deleteActivityWithStatReversal', 'Data consistency check failed for activity: ${activityToDelete.id}');
        return ActivityDeletionResult.error('Deletion would cause data inconsistency');
      }

      // Begin atomic transaction-like operation with comprehensive error handling
      try {
        // Step 1: Apply stat reversals
        final updatedStats = StatsService.applyStatReversals(currentStatsMap, statReversals);
        
        // Validate updated stats before applying
        for (final entry in updatedStats.entries) {
          if (entry.value.isNaN || entry.value.isInfinite) {
            throw ActivityServiceException('Invalid stat value calculated: ${entry.key} = ${entry.value}');
          }
        }

        // Update user stats
        for (final entry in updatedStats.entries) {
          user.setStat(entry.key, entry.value);
        }

        // Store original level for comparison
        final originalLevel = user.level;
        
        // Step 2: Apply EXP reversal and handle level-down
        final updatedUser = EXPService.handleEXPReversal(user, activityToDelete.expGained);
        
        // Validate EXP and level values
        if (updatedUser.currentEXP.isNaN || updatedUser.currentEXP.isInfinite || updatedUser.currentEXP < 0) {
          throw ActivityServiceException('Invalid EXP value calculated: ${updatedUser.currentEXP}');
        }
        if (updatedUser.level < 1) {
          throw ActivityServiceException('Invalid level calculated: ${updatedUser.level}');
        }

        // Update user with new level and EXP
        user.level = updatedUser.level;
        user.currentEXP = updatedUser.currentEXP;

        // Step 3: Save updated user data (critical operation)
        try {
          await _userRepository.updateUser(user);
        } catch (e) {
          throw ActivityServiceException('Failed to save user data during deletion: $e');
        }

        // Step 4: Delete the activity log (final operation)
        try {
          await _activityRepository.deleteByKey(activityId);
        } catch (e) {
          // Critical: User data was updated but activity deletion failed
          // Attempt to rollback user data
          await _attemptUserRollback(originalUser);
          throw ActivityServiceException('Failed to delete activity after user update: $e');
        }

        // Log successful deletion
        _logInfo('deleteActivityWithStatReversal', 'Successfully deleted activity: ${activityToDelete.id}');

        return ActivityDeletionResult.success(
          deletedActivity: activityToDelete,
          statReversals: statReversals,
          expReversed: activityToDelete.expGained,
          newLevel: user.level,
          leveledDown: user.level < originalLevel,
        );

      } catch (e) {
        // Rollback mechanism - attempt to restore original user state
        if (originalUser != null) {
          await _attemptUserRollback(originalUser);
        }
        
        _logError('deleteActivityWithStatReversal', 'Failed to apply reversals during deletion: $e');
        throw ActivityServiceException('Failed to apply reversals during deletion: $e');
      }

    } catch (e) {
      // Final catch-all error handling
      _logError('deleteActivityWithStatReversal', 'Unexpected error during activity deletion: $e');
      
      // Attempt rollback if we have original state
      if (originalUser != null) {
        await _attemptUserRollback(originalUser);
      }
      
      return ActivityDeletionResult.error('Failed to delete activity with stat reversal: $e');
    }
  }

  /// Preview what would happen if an activity is deleted (for confirmation dialogs)
  Future<ActivityDeletionPreview> previewActivityDeletion(String activityId) async {
    try {
      final activity = _activityRepository.findByKey(activityId);
      if (activity == null) {
        return ActivityDeletionPreview.error('Activity not found');
      }

      final user = _userRepository.getCurrentUser();
      if (user == null) {
        return ActivityDeletionPreview.error('No user found');
      }

      // Calculate what would be reversed
      final statReversals = StatsService.calculateStatReversals(
        activity.activityTypeEnum,
        activity.durationMinutes,
        activity.statGainsMap,
      );

      final levelDownResult = EXPService.calculateLevelDown(user, activity.expGained);

      return ActivityDeletionPreview(
        activity: activity,
        statReversals: statReversals,
        expToReverse: activity.expGained,
        willLevelDown: levelDownResult.willLevelDown,
        newLevel: levelDownResult.newLevel,
        levelsLost: levelDownResult.levelsLost,
        isValid: true,
      );

    } catch (e) {
      return ActivityDeletionPreview.error('Failed to preview deletion: $e');
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

  /// Validate activity data for safe deletion
  bool _validateActivityForDeletion(ActivityLog activity) {
    try {
      // Check basic activity data integrity
      if (activity.id.isEmpty) {
        _logError('_validateActivityForDeletion', 'Activity has empty ID');
        return false;
      }

      if (activity.durationMinutes <= 0) {
        _logError('_validateActivityForDeletion', 'Activity has invalid duration: ${activity.durationMinutes}');
        return false;
      }

      if (activity.expGained < 0) {
        _logError('_validateActivityForDeletion', 'Activity has negative EXP: ${activity.expGained}');
        return false;
      }

      // Validate activity type exists
      try {
        ActivityType.values.firstWhere((type) => type.name == activity.activityType);
      } catch (e) {
        _logError('_validateActivityForDeletion', 'Activity has invalid type: ${activity.activityType}');
        return false;
      }

      // Validate stat gains if present
      if (activity.statGainsMap.isNotEmpty) {
        for (final entry in activity.statGainsMap.entries) {
          if (entry.value.isNaN || entry.value.isInfinite || entry.value < 0) {
            _logError('_validateActivityForDeletion', 'Activity has invalid stat gain: ${entry.key} = ${entry.value}');
            return false;
          }
        }
      }

      return true;
    } catch (e) {
      _logError('_validateActivityForDeletion', 'Exception during validation: $e');
      return false;
    }
  }

  /// Validate data consistency before deletion
  bool _validateDataConsistency(User user, ActivityLog activity, Map<StatType, double> statReversals) {
    try {
      // Check if user has sufficient stats for reversal (considering floor of 1.0)
      for (final entry in statReversals.entries) {
        final currentValue = user.getStat(entry.key);
        final newValue = currentValue - entry.value;
        
        // This is acceptable - stats will be clamped to 1.0 minimum
        // But log if it would cause significant clamping
        if (newValue < 0.5) {
          _logWarning('_validateDataConsistency', 
            'Stat reversal will cause significant clamping: ${entry.key} from $currentValue to 1.0 (would be $newValue)');
        }
      }

      // Check EXP consistency
      final expAfterReversal = user.currentEXP - activity.expGained;
      if (expAfterReversal < -1000) { // Allow some negative EXP for level-down calculations
        _logWarning('_validateDataConsistency', 
          'EXP reversal will cause significant level-down: current ${user.currentEXP}, reversing ${activity.expGained}');
      }

      // Check timestamp consistency (activity shouldn't be from the future)
      if (activity.timestamp.isAfter(DateTime.now().add(const Duration(hours: 1)))) {
        _logError('_validateDataConsistency', 'Activity timestamp is in the future: ${activity.timestamp}');
        return false;
      }

      return true;
    } catch (e) {
      _logError('_validateDataConsistency', 'Exception during consistency check: $e');
      return false;
    }
  }

  /// Attempt to rollback user data to original state
  Future<void> _attemptUserRollback(User originalUser) async {
    try {
      _logWarning('_attemptUserRollback', 'Attempting to rollback user data to original state');
      
      // Get current user
      final currentUser = _userRepository.getCurrentUser();
      if (currentUser == null) {
        _logError('_attemptUserRollback', 'Cannot rollback: no current user found');
        return;
      }

      // Restore original values
      currentUser.level = originalUser.level;
      currentUser.currentEXP = originalUser.currentEXP;
      currentUser.stats = Map<String, double>.from(originalUser.stats);
      currentUser.lastActivityDates = Map<String, DateTime>.from(originalUser.lastActivityDates);

      // Save restored state
      await _userRepository.updateUser(currentUser);
      
      _logInfo('_attemptUserRollback', 'Successfully rolled back user data');
    } catch (e) {
      _logError('_attemptUserRollback', 'Failed to rollback user data: $e');
      // This is a critical error - user data may be in inconsistent state
      // In a production app, this would trigger alerts and manual intervention
    }
  }

  /// Log error messages with context
  void _logError(String method, String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] ERROR ActivityService.$method: $message';
    print(logMessage); // In production, use proper logging framework
    
    // In production, you might want to:
    // - Send to crash reporting service (Firebase Crashlytics, Sentry, etc.)
    // - Store in local error log file
    // - Send to analytics service
  }

  /// Log warning messages with context
  void _logWarning(String method, String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] WARNING ActivityService.$method: $message';
    print(logMessage); // In production, use proper logging framework
  }

  /// Log info messages with context
  void _logInfo(String method, String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] INFO ActivityService.$method: $message';
    print(logMessage); // In production, use proper logging framework
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

/// Result of activity deletion with stat reversal
class ActivityDeletionResult {
  final bool success;
  final String? errorMessage;
  final ActivityLog? deletedActivity;
  final Map<StatType, double> statReversals;
  final double expReversed;
  final int newLevel;
  final bool leveledDown;

  const ActivityDeletionResult._({
    required this.success,
    this.errorMessage,
    this.deletedActivity,
    this.statReversals = const {},
    this.expReversed = 0.0,
    this.newLevel = 1,
    this.leveledDown = false,
  });

  factory ActivityDeletionResult.success({
    required ActivityLog deletedActivity,
    required Map<StatType, double> statReversals,
    required double expReversed,
    required int newLevel,
    required bool leveledDown,
  }) {
    return ActivityDeletionResult._(
      success: true,
      deletedActivity: deletedActivity,
      statReversals: statReversals,
      expReversed: expReversed,
      newLevel: newLevel,
      leveledDown: leveledDown,
    );
  }

  factory ActivityDeletionResult.error(String errorMessage) {
    return ActivityDeletionResult._(
      success: false,
      errorMessage: errorMessage,
    );
  }

  @override
  String toString() {
    if (success) {
      return 'ActivityDeletionResult(success: true, leveledDown: $leveledDown, newLevel: $newLevel)';
    } else {
      return 'ActivityDeletionResult(success: false, error: $errorMessage)';
    }
  }
}

/// Preview of what would happen during activity deletion
class ActivityDeletionPreview {
  final ActivityLog? activity;
  final Map<StatType, double> statReversals;
  final double expToReverse;
  final bool willLevelDown;
  final int newLevel;
  final int levelsLost;
  final bool isValid;
  final String? errorMessage;

  const ActivityDeletionPreview({
    this.activity,
    this.statReversals = const {},
    this.expToReverse = 0.0,
    this.willLevelDown = false,
    this.newLevel = 1,
    this.levelsLost = 0,
    required this.isValid,
    this.errorMessage,
  });

  factory ActivityDeletionPreview.error(String errorMessage) {
    return ActivityDeletionPreview(
      isValid: false,
      errorMessage: errorMessage,
    );
  }

  /// Get formatted text for stat reversals
  String getStatReversalText(StatType statType) {
    final reversal = statReversals[statType];
    if (reversal == null || reversal == 0.0) return '';
    return '-${reversal.toStringAsFixed(2)}';
  }

  /// Get list of stats that will be affected
  List<StatType> get affectedStats {
    return statReversals.keys.where((stat) => statReversals[stat]! > 0.0).toList();
  }

  /// Get formatted EXP reversal text
  String get expReversalText {
    return '-${expToReverse.toStringAsFixed(0)} EXP';
  }

  @override
  String toString() {
    if (isValid) {
      return 'ActivityDeletionPreview(willLevelDown: $willLevelDown, newLevel: $newLevel, expReversed: $expToReverse)';
    } else {
      return 'ActivityDeletionPreview(error: $errorMessage)';
    }
  }
}

/// Custom exception for activity service operations
class ActivityServiceException implements Exception {
  final String message;

  ActivityServiceException(this.message);

  @override
  String toString() => 'ActivityServiceException: $message';
}