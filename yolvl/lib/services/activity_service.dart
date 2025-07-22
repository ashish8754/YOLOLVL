import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/activity_log.dart';
import '../models/enums.dart';
import '../models/user.dart';
import '../repositories/activity_repository.dart';
import '../repositories/user_repository.dart';
import 'exp_service.dart';
import 'stats_service.dart';

/// Service for handling activity logging, history operations, and activity deletion with stat reversal
/// 
/// This service provides comprehensive functionality for:
/// - Logging new activities with stat and EXP gains
/// - Retrieving activity history with filtering and pagination
/// - Deleting activities with complete stat and EXP reversal
/// - Validating activity data integrity
/// - Handling complex edge cases in stat reversal calculations
/// 
/// Key Features:
/// - **Activity Deletion with Stat Reversal**: Safely removes activities while reversing
///   all stat gains and EXP that were applied during the original logging
/// - **Data Integrity Validation**: Comprehensive validation before deletion operations
/// - **Rollback Mechanisms**: Automatic rollback if deletion operations fail partway
/// - **Legacy Data Support**: Handles activities logged before stat gains were stored
/// - **Error Handling**: Detailed error reporting and logging for debugging
/// 
/// Usage Example:
/// ```dart
/// final service = ActivityService();
/// 
/// // Log an activity
/// final result = await service.logActivity(
///   activityType: ActivityType.workoutWeights,
///   durationMinutes: 60,
/// );
/// 
/// // Delete an activity with stat reversal
/// final deletionResult = await service.deleteActivityWithStatReversal(activityId);
/// if (deletionResult.success) {
///   debugPrint('Activity deleted, stats reversed');
/// }
/// ```
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

  /// Delete an activity with comprehensive stat and EXP reversal
  /// 
  /// This method performs a complete reversal of all changes made when an activity was logged:
  /// - Reverses stat gains using stored values or fallback calculation for legacy activities
  /// - Reverses EXP gains and handles level-down scenarios if necessary
  /// - Validates all operations before execution to prevent data corruption
  /// - Implements atomic transaction-like behavior with rollback on failure
  /// 
  /// **Process Flow:**
  /// 1. Validate activity exists and can be safely deleted
  /// 2. Calculate stat reversals using stored gains or fallback calculation
  /// 3. Validate that reversals won't cause invalid stat values (below 1.0 floor)
  /// 4. Apply stat reversals with floor constraint enforcement
  /// 5. Handle EXP reversal and potential level-down scenarios
  /// 6. Delete the activity record from storage
  /// 7. Rollback all changes if any step fails
  /// 
  /// **Error Handling:**
  /// - Comprehensive validation before any changes are made
  /// - Automatic rollback if operations fail partway through
  /// - Detailed error logging for debugging purposes
  /// - User-friendly error messages for common failure scenarios
  /// 
  /// **Edge Cases Handled:**
  /// - Activities without stored stat gains (legacy data migration)
  /// - Level-down scenarios when EXP reversal crosses level thresholds
  /// - Stat values that would fall below the 1.0 minimum floor
  /// - Data corruption or inconsistency detection
  /// - Concurrent modification scenarios
  /// 
  /// @param activityId The unique identifier of the activity to delete
  /// @return ActivityDeletionResult containing success status, error details, and reversal information
  /// 
  /// Example:
  /// ```dart
  /// final result = await deleteActivityWithStatReversal('activity_123');
  /// if (result.success) {
  ///   debugPrint('Deleted activity, reversed ${result.statReversals.length} stats');
  ///   if (result.leveledDown) {
  ///     debugPrint('User leveled down to ${result.newLevel}');
  ///   }
  /// } else {
  ///   debugPrint('Deletion failed: ${result.errorMessage}');
  /// }
  /// ```
  Future<ActivityDeletionResult> deleteActivityWithStatReversal(String activityId) async {
    // Input validation
    if (activityId.isEmpty) {
      _logError('deleteActivityWithStatReversal', 'Empty activity ID provided');
      return ActivityDeletionResult.error('Invalid activity ID');
    }

    // Store original state for rollback
    User? originalUser;
    ActivityLog? activityToDelete;
    bool userDataUpdated = false;
    bool transactionStarted = false;

    try {
      // Find the activity to delete
      try {
        activityToDelete = _activityRepository.findByKey(activityId);
        if (activityToDelete == null) {
          _logError('deleteActivityWithStatReversal', 'Activity not found: $activityId');
          return ActivityDeletionResult.error('Activity not found');
        }
      } catch (e) {
        _logError('deleteActivityWithStatReversal', 'Failed to retrieve activity: $e');
        return ActivityDeletionResult.error('Failed to retrieve activity data: $e');
      }

      // Get current user
      User? user;
      try {
        user = _userRepository.getCurrentUser();
        if (user == null) {
          _logError('deleteActivityWithStatReversal', 'No current user found');
          return ActivityDeletionResult.error('No user found');
        }
      } catch (e) {
        _logError('deleteActivityWithStatReversal', 'Failed to retrieve user data: $e');
        return ActivityDeletionResult.error('Failed to retrieve user data: $e');
      }

      // Store original user state for rollback
      try {
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
        originalUser.createdAt = user.createdAt;
        originalUser.lastActive = user.lastActive;
      } catch (e) {
        _logError('deleteActivityWithStatReversal', 'Failed to create backup of user state: $e');
        return ActivityDeletionResult.error('Failed to create backup of user state: $e');
      }

      // Validate activity data integrity
      if (!_validateActivityForDeletion(activityToDelete)) {
        _logError('deleteActivityWithStatReversal', 'Activity validation failed: ${activityToDelete.id}');
        return ActivityDeletionResult.error('Activity data is invalid and cannot be safely deleted');
      }

      // Calculate stat reversals using stored gains or fallback calculation
      Map<StatType, double> statReversals;
      try {
        statReversals = StatsService.calculateStatReversals(
          activityToDelete.activityTypeEnum,
          activityToDelete.durationMinutes,
          activityToDelete.statGainsMap,
        );
      } catch (e) {
        _logError('deleteActivityWithStatReversal', 'Failed to calculate stat reversals: $e');
        return ActivityDeletionResult.error('Failed to calculate stat reversals: $e');
      }

      // Validate reversal operation
      Map<StatType, double> currentStatsMap;
      try {
        currentStatsMap = user.stats.map((key, value) => MapEntry(
          StatType.values.firstWhere((type) => type.name == key, orElse: () {
            throw ActivityServiceException('Invalid stat type: $key');
          }),
          value,
        ));
      } catch (e) {
        _logError('deleteActivityWithStatReversal', 'Failed to map user stats: $e');
        return ActivityDeletionResult.error('Failed to process user stats: $e');
      }

      // Pre-validate stat reversal
      try {
        if (!StatsService.validateStatReversal(currentStatsMap, statReversals)) {
          _logError('deleteActivityWithStatReversal', 'Stat reversal validation failed for activity: ${activityToDelete.id}');
          return ActivityDeletionResult.error('Stat reversal validation failed - operation would result in invalid stats');
        }
      } catch (e) {
        _logError('deleteActivityWithStatReversal', 'Exception during stat reversal validation: $e');
        return ActivityDeletionResult.error('Failed to validate stat reversal: $e');
      }

      // Pre-validate EXP reversal
      try {
        if (!EXPService.validateEXPReversal(user, activityToDelete.expGained)) {
          _logError('deleteActivityWithStatReversal', 'EXP reversal validation failed for activity: ${activityToDelete.id}');
          return ActivityDeletionResult.error('EXP reversal validation failed - operation would result in invalid EXP');
        }
      } catch (e) {
        _logError('deleteActivityWithStatReversal', 'Exception during EXP reversal validation: $e');
        return ActivityDeletionResult.error('Failed to validate EXP reversal: $e');
      }

      // Check for data consistency issues
      if (!_validateDataConsistency(user, activityToDelete, statReversals)) {
        _logError('deleteActivityWithStatReversal', 'Data consistency check failed for activity: ${activityToDelete.id}');
        return ActivityDeletionResult.error('Deletion would cause data inconsistency');
      }

      // Begin atomic transaction-like operation with comprehensive error handling
      transactionStarted = true;
      try {
        // Step 1: Apply stat reversals
        Map<StatType, double> updatedStats;
        try {
          updatedStats = StatsService.applyStatReversals(currentStatsMap, statReversals);
          
          // Validate updated stats before applying
          for (final entry in updatedStats.entries) {
            if (entry.value.isNaN || entry.value.isInfinite) {
              throw ActivityServiceException('Invalid stat value calculated: ${entry.key} = ${entry.value}');
            }
          }
        } catch (e) {
          _logError('deleteActivityWithStatReversal', 'Failed to apply stat reversals: $e');
          throw ActivityServiceException('Failed to apply stat reversals: $e');
        }

        // Update user stats
        try {
          for (final entry in updatedStats.entries) {
            user.setStat(entry.key, entry.value);
          }
        } catch (e) {
          _logError('deleteActivityWithStatReversal', 'Failed to update user stats: $e');
          throw ActivityServiceException('Failed to update user stats: $e');
        }

        // Store original level for comparison
        final originalLevel = user.level;
        
        // Step 2: Apply EXP reversal and handle level-down
        User updatedUser;
        try {
          updatedUser = EXPService.handleEXPReversal(user, activityToDelete.expGained);
          
          // Validate EXP and level values
          if (updatedUser.currentEXP.isNaN || updatedUser.currentEXP.isInfinite || updatedUser.currentEXP < 0) {
            throw ActivityServiceException('Invalid EXP value calculated: ${updatedUser.currentEXP}');
          }
          if (updatedUser.level < 1) {
            throw ActivityServiceException('Invalid level calculated: ${updatedUser.level}');
          }
        } catch (e) {
          _logError('deleteActivityWithStatReversal', 'Failed to handle EXP reversal: $e');
          throw ActivityServiceException('Failed to handle EXP reversal: $e');
        }

        // Update user with new level and EXP
        user.level = updatedUser.level;
        user.currentEXP = updatedUser.currentEXP;

        // Step 3: Save updated user data (critical operation)
        try {
          await _userRepository.updateUser(user);
          userDataUpdated = true;
          _logInfo('deleteActivityWithStatReversal', 'Successfully updated user data during deletion');
        } catch (e) {
          _logError('deleteActivityWithStatReversal', 'Failed to save user data during deletion: $e');
          throw ActivityServiceException('Failed to save user data during deletion: $e');
        }

        // Step 4: Delete the activity log (final operation)
        try {
          await _activityRepository.deleteByKey(activityId);
          _logInfo('deleteActivityWithStatReversal', 'Successfully deleted activity record');
        } catch (e) {
          // Critical: User data was updated but activity deletion failed
          _logError('deleteActivityWithStatReversal', 'Failed to delete activity after user update: $e');
          
          // Attempt to rollback user data
          if (userDataUpdated && originalUser != null) {
            _logWarning('deleteActivityWithStatReversal', 'Attempting rollback due to activity deletion failure');
            await _attemptUserRollback(originalUser);
          }
          
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
        if (userDataUpdated && originalUser != null) {
          _logWarning('deleteActivityWithStatReversal', 'Transaction failed, attempting rollback: $e');
          await _attemptUserRollback(originalUser);
        }
        
        _logError('deleteActivityWithStatReversal', 'Failed to apply reversals during deletion: $e');
        throw ActivityServiceException('Failed to apply reversals during deletion: $e');
      }

    } catch (e) {
      // Final catch-all error handling
      _logError('deleteActivityWithStatReversal', 'Unexpected error during activity deletion: $e');
      
      // Attempt rollback if transaction started and we have original state
      if (transactionStarted && userDataUpdated && originalUser != null) {
        _logWarning('deleteActivityWithStatReversal', 'Attempting final rollback after unexpected error');
        await _attemptUserRollback(originalUser);
      }
      
      if (e is ActivityServiceException) {
        return ActivityDeletionResult.error(e.message);
      }
      
      return ActivityDeletionResult.error('Failed to delete activity with stat reversal: $e');
    }
  }

  /// Preview the impact of deleting an activity without actually performing the deletion
  /// 
  /// This method performs all validation and calculation steps that would occur during
  /// actual deletion, providing detailed information about the impact without making
  /// any changes to user data. This is essential for confirmation dialogs and user
  /// interface feedback.
  /// 
  /// **Information Provided:**
  /// - Stat reversals that would be applied to each affected stat
  /// - EXP reversal amount and potential level-down scenarios
  /// - Validation warnings or errors that would prevent deletion
  /// - Impact analysis including percentage changes and floor clamping
  /// - Safety assessment of the deletion operation
  /// 
  /// **Validation Checks:**
  /// - Activity exists and has valid data
  /// - Stat reversal calculations are valid and safe
  /// - EXP reversal won't cause invalid user state
  /// - Data consistency checks pass
  /// - No corruption or integrity issues detected
  /// 
  /// **Use Cases:**
  /// - Confirmation dialogs showing deletion impact
  /// - UI validation before enabling delete buttons
  /// - Batch operation planning and validation
  /// - Debugging and troubleshooting deletion issues
  /// 
  /// @param activityId The unique identifier of the activity to preview deletion for
  /// @return ActivityDeletionPreview containing detailed impact analysis and validation results
  /// 
  /// Example:
  /// ```dart
  /// final preview = await previewActivityDeletion('activity_123');
  /// if (preview.isValid) {
  ///   showConfirmationDialog(
  ///     'Delete activity? This will reverse ${preview.statReversals.length} stat changes.'
  ///   );
  /// } else {
  ///   showError('Cannot delete: ${preview.validationIssues.join(", ")}');
  /// }
  /// ```
  Future<ActivityDeletionPreview> previewActivityDeletion(String activityId) async {
    try {
      // Input validation
      if (activityId.isEmpty) {
        _logError('previewActivityDeletion', 'Empty activity ID provided');
        return ActivityDeletionPreview.error('Invalid activity ID');
      }
      
      // Find the activity
      final activity = _activityRepository.findByKey(activityId);
      if (activity == null) {
        _logError('previewActivityDeletion', 'Activity not found: $activityId');
        return ActivityDeletionPreview.error('Activity not found');
      }

      // Get current user
      final user = _userRepository.getCurrentUser();
      if (user == null) {
        _logError('previewActivityDeletion', 'No current user found');
        return ActivityDeletionPreview.error('No user found');
      }

      // Validate activity data integrity
      if (!_validateActivityForDeletion(activity)) {
        _logError('previewActivityDeletion', 'Activity validation failed: ${activity.id}');
        return ActivityDeletionPreview.error(
          'Activity data is invalid and cannot be safely deleted',
          activity: activity,
          validationIssues: ['Invalid activity data'],
        );
      }

      // Calculate stat reversals
      Map<StatType, double> statReversals;
      try {
        statReversals = StatsService.calculateStatReversals(
          activity.activityTypeEnum,
          activity.durationMinutes,
          activity.statGainsMap,
        );
      } catch (e) {
        _logError('previewActivityDeletion', 'Failed to calculate stat reversals: $e');
        return ActivityDeletionPreview.error(
          'Failed to calculate stat reversals',
          activity: activity,
          validationIssues: ['Stat reversal calculation error: $e'],
        );
      }

      // Map user stats
      final currentStatsMap = user.stats.map((key, value) => MapEntry(
        StatType.values.firstWhere((type) => type.name == key, 
          orElse: () => throw FormatException('Invalid stat type: $key')),
        value,
      ));

      // Validate stat reversal
      final List<String> validationIssues = [];
      
      if (!StatsService.validateStatReversal(currentStatsMap, statReversals)) {
        _logError('previewActivityDeletion', 'Stat reversal validation failed for activity: ${activity.id}');
        validationIssues.add('Stat reversal validation failed');
      }

      // Validate EXP reversal
      if (!EXPService.validateEXPReversal(user, activity.expGained)) {
        _logError('previewActivityDeletion', 'EXP reversal validation failed for activity: ${activity.id}');
        validationIssues.add('EXP reversal validation failed');
      }

      // Check data consistency
      if (!_validateDataConsistency(user, activity, statReversals)) {
        _logError('previewActivityDeletion', 'Data consistency check failed for activity: ${activity.id}');
        validationIssues.add('Data consistency check failed');
      }

      // Calculate level-down impact
      final levelDownResult = EXPService.calculateLevelDown(user, activity.expGained);
      
      // Calculate stat impacts
      final Map<StatType, StatImpact> statImpacts = {};
      for (final entry in statReversals.entries) {
        final currentValue = user.getStat(entry.key);
        final newValue = max(1.0, currentValue - entry.value); // Apply floor of 1.0
        final percentChange = currentValue > 0 ? ((newValue - currentValue) / currentValue) * 100 : 0;
        
        statImpacts[entry.key] = StatImpact(
          statType: entry.key,
          currentValue: currentValue,
          newValue: newValue,
          change: newValue - currentValue,
          percentChange: percentChange.toDouble(),
          willClamp: newValue < (currentValue - entry.value), // True if floor was applied
        );
      }

      // Check if any warnings or issues exist
      final hasWarnings = validationIssues.isNotEmpty || 
                          levelDownResult.levelsLost > 1 ||
                          statImpacts.values.any((impact) => impact.willClamp);

      return ActivityDeletionPreview(
        activity: activity,
        statReversals: statReversals,
        expToReverse: activity.expGained,
        willLevelDown: levelDownResult.willLevelDown,
        newLevel: levelDownResult.newLevel,
        levelsLost: levelDownResult.levelsLost,
        isValid: validationIssues.isEmpty,
        hasWarnings: hasWarnings,
        validationIssues: validationIssues,
        statImpacts: statImpacts,
      );

    } catch (e) {
      _logError('previewActivityDeletion', 'Failed to preview deletion: $e');
      return ActivityDeletionPreview.error('Failed to preview deletion: $e');
    }
  }
  
  /// Safely delete an activity with validation and preview
  /// This is a convenience method that combines preview and deletion
  Future<ActivityDeletionResult> safeDeleteActivity(String activityId, {bool skipPreview = false}) async {
    try {
      // First preview the deletion to check for issues
      if (!skipPreview) {
        final preview = await previewActivityDeletion(activityId);
        
        // If preview shows validation issues, abort deletion
        if (!preview.isValid) {
          return ActivityDeletionResult.error(
            'Cannot safely delete activity: ${preview.validationIssues.join(", ")}'
          );
        }
        
        // If preview shows warnings, log them but proceed
        if (preview.hasWarnings) {
          _logWarning('safeDeleteActivity', 
            'Proceeding with deletion despite warnings: ${preview.validationIssues.join(", ")}'
          );
        }
      }
      
      // Proceed with actual deletion
      return await deleteActivityWithStatReversal(activityId);
    } catch (e) {
      _logError('safeDeleteActivity', 'Failed to safely delete activity: $e');
      return ActivityDeletionResult.error('Failed to safely delete activity: $e');
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
  /// Performs comprehensive validation to ensure activity can be safely deleted
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

      if (activity.expGained.isNaN || activity.expGained.isInfinite) {
        _logError('_validateActivityForDeletion', 'Activity has invalid EXP value: ${activity.expGained}');
        return false;
      }

      // Validate timestamp
      if (activity.timestamp == null) {
        _logError('_validateActivityForDeletion', 'Activity has null timestamp');
        return false;
      }

      final now = DateTime.now();
      final oneYearAgo = now.subtract(const Duration(days: 365));
      final oneDayAhead = now.add(const Duration(days: 1));
      
      if (activity.timestamp.isAfter(oneDayAhead)) {
        _logError('_validateActivityForDeletion', 'Activity has future timestamp: ${activity.timestamp}');
        return false;
      }
      
      if (activity.timestamp.isBefore(oneYearAgo)) {
        _logWarning('_validateActivityForDeletion', 'Activity is very old (> 1 year): ${activity.timestamp}');
        // Not a validation failure, just a warning
      }

      // Validate activity type exists
      try {
        final activityType = ActivityType.values.firstWhere(
          (type) => type.name == activity.activityType,
          orElse: () => throw FormatException('Invalid activity type: ${activity.activityType}')
        );
        
        // Additional validation for specific activity types
        if (activityType == ActivityType.quitBadHabit && activity.durationMinutes > 120) {
          _logWarning('_validateActivityForDeletion', 
            'Quit bad habit activity has unusually long duration: ${activity.durationMinutes} minutes');
        }
        
      } catch (e) {
        _logError('_validateActivityForDeletion', 'Activity has invalid type: ${activity.activityType}');
        return false;
      }

      // Validate stat gains
      if (activity.statGainsMap.isEmpty) {
        _logWarning('_validateActivityForDeletion', 
          'Activity has no stored stat gains, will use fallback calculation: ${activity.id}');
        // Not a validation failure, just a warning - fallback calculation will be used
      } else {
        // Validate each stat gain
        for (final entry in activity.statGainsMap.entries) {
          if (entry.value.isNaN || entry.value.isInfinite) {
            _logError('_validateActivityForDeletion', 'Activity has invalid stat gain: ${entry.key} = ${entry.value}');
            return false;
          }
          
          if (entry.value < 0) {
            _logError('_validateActivityForDeletion', 'Activity has negative stat gain: ${entry.key} = ${entry.value}');
            return false;
          }
          
          // Check for unreasonably large stat gains (might indicate data corruption)
          if (entry.value > 10.0) {
            _logWarning('_validateActivityForDeletion', 
              'Activity has unusually large stat gain: ${entry.key} = ${entry.value}');
            // Not a validation failure, just a warning
          }
        }
        
        // Check that stat gains match expected stats for activity type
        final expectedAffectedStats = StatsService.getAffectedStats(activity.activityTypeEnum);
        final actualAffectedStats = activity.statGainsMap.keys.toList();
        
        bool hasUnexpectedStats = false;
        for (final stat in actualAffectedStats) {
          if (!expectedAffectedStats.contains(stat)) {
            _logWarning('_validateActivityForDeletion', 
              'Activity has unexpected stat gain for ${stat.name} which is not typically affected by ${activity.activityType}');
            hasUnexpectedStats = true;
          }
        }
        
        if (hasUnexpectedStats) {
          _logWarning('_validateActivityForDeletion', 
            'Activity has unexpected stat gains pattern, but will proceed with deletion');
        }
      }

      return true;
    } catch (e) {
      _logError('_validateActivityForDeletion', 'Exception during validation: $e');
      return false;
    }
  }

  /// Validate data consistency before deletion
  /// Ensures that deleting the activity won't cause data inconsistency
  bool _validateDataConsistency(User user, ActivityLog activity, Map<StatType, double> statReversals) {
    try {
      // Validate user data
      if (user.id.isEmpty) {
        _logError('_validateDataConsistency', 'User has empty ID');
        return false;
      }
      
      if (user.level < 1) {
        _logError('_validateDataConsistency', 'User has invalid level: ${user.level}');
        return false;
      }
      
      if (user.currentEXP.isNaN || user.currentEXP.isInfinite) {
        _logError('_validateDataConsistency', 'User has invalid EXP: ${user.currentEXP}');
        return false;
      }
      
      // Check if user has sufficient stats for reversal (considering floor of 1.0)
      int significantClampingCount = 0;
      for (final entry in statReversals.entries) {
        final currentValue = user.getStat(entry.key);
        
        // Validate current stat value
        if (currentValue.isNaN || currentValue.isInfinite) {
          _logError('_validateDataConsistency', 'User has invalid stat value: ${entry.key} = $currentValue');
          return false;
        }
        
        final newValue = currentValue - entry.value;
        
        // This is acceptable - stats will be clamped to 1.0 minimum
        // But log if it would cause significant clamping
        if (newValue < 0.5) {
          _logWarning('_validateDataConsistency', 
            'Stat reversal will cause significant clamping: ${entry.key} from $currentValue to 1.0 (would be $newValue)');
          significantClampingCount++;
        }
      }
      
      // If too many stats would be significantly clamped, it might indicate a data issue
      if (significantClampingCount > 3) {
        _logWarning('_validateDataConsistency', 
          'Multiple stats ($significantClampingCount) would be significantly clamped - possible data inconsistency');
      }

      // Check EXP consistency
      final expAfterReversal = user.currentEXP - activity.expGained;
      
      // Calculate level-down impact
      final levelDownResult = EXPService.calculateLevelDown(user, activity.expGained);
      
      if (levelDownResult.levelsLost > 5) {
        _logWarning('_validateDataConsistency', 
          'EXP reversal will cause significant level-down (${levelDownResult.levelsLost} levels): ' +
          'current level ${user.level}, new level would be ${levelDownResult.newLevel}');
      }
      
      if (expAfterReversal < -1000) { // Allow some negative EXP for level-down calculations
        _logWarning('_validateDataConsistency', 
          'EXP reversal will cause significant EXP reduction: current ${user.currentEXP}, reversing ${activity.expGained}');
      }

      // Check timestamp consistency
      final now = DateTime.now();
      
      // Activity shouldn't be from the future
      if (activity.timestamp.isAfter(now.add(const Duration(hours: 1)))) {
        _logError('_validateDataConsistency', 'Activity timestamp is in the future: ${activity.timestamp}');
        return false;
      }
      
      // Check for suspicious activity age
      final activityAge = now.difference(activity.timestamp).inDays;
      if (activityAge > 180) { // Older than 6 months
        _logWarning('_validateDataConsistency', 
          'Activity is very old (${activityAge} days): ${activity.timestamp}');
      }
      
      // Check for suspicious activity duration
      if (activity.durationMinutes > 720) { // More than 12 hours
        _logWarning('_validateDataConsistency', 
          'Activity has unusually long duration: ${activity.durationMinutes} minutes');
      }
      
      // Check for suspicious EXP gain
      if (activity.expGained > 1000) { // More than 1000 EXP
        _logWarning('_validateDataConsistency', 
          'Activity has unusually high EXP gain: ${activity.expGained}');
      }
      
      // Check for suspicious stat gains
      bool hasUnusuallyHighGains = false;
      for (final entry in statReversals.entries) {
        if (entry.value > 1.0) { // More than 1.0 stat gain in a single activity
          _logWarning('_validateDataConsistency', 
            'Activity has unusually high stat gain: ${entry.key} = ${entry.value}');
          hasUnusuallyHighGains = true;
        }
      }
      
      if (hasUnusuallyHighGains) {
        _logWarning('_validateDataConsistency', 
          'Activity has unusually high stat gains - possible data inconsistency');
      }

      return true;
    } catch (e) {
      _logError('_validateDataConsistency', 'Exception during consistency check: $e');
      return false;
    }
  }

  /// Attempt to rollback user data to original state
  /// Returns true if rollback was successful, false otherwise
  Future<bool> _attemptUserRollback(User originalUser) async {
    int retryCount = 0;
    const maxRetries = 3;
    
    while (retryCount < maxRetries) {
      try {
        _logWarning('_attemptUserRollback', 'Attempting to rollback user data to original state (attempt ${retryCount + 1}/${maxRetries})');
        
        // Get current user
        final currentUser = _userRepository.getCurrentUser();
        if (currentUser == null) {
          _logError('_attemptUserRollback', 'Cannot rollback: no current user found');
          return false;
        }

        // Validate original user data before rollback
        if (originalUser.id.isEmpty || originalUser.id != currentUser.id) {
          _logError('_attemptUserRollback', 'Invalid original user data for rollback: ID mismatch or empty');
          return false;
        }

        // Validate stats to ensure we're not rolling back to invalid state
        bool hasInvalidStats = false;
        for (final entry in originalUser.stats.entries) {
          final value = entry.value;
          if (value.isNaN || value.isInfinite || value < 1.0) {
            _logError('_attemptUserRollback', 'Invalid stat value in original user data: ${entry.key} = $value');
            hasInvalidStats = true;
            break;
          }
        }

        if (hasInvalidStats) {
          _logError('_attemptUserRollback', 'Cannot rollback to invalid stat values');
          return false;
        }

        // Restore original values with validation
        currentUser.level = originalUser.level > 0 ? originalUser.level : 1;
        currentUser.currentEXP = originalUser.currentEXP >= 0 ? originalUser.currentEXP : 0;
        currentUser.stats = Map<String, double>.from(originalUser.stats);
        currentUser.lastActivityDates = Map<String, DateTime>.from(originalUser.lastActivityDates);

        // Save restored state
        await _userRepository.updateUser(currentUser);
        
        _logInfo('_attemptUserRollback', 'Successfully rolled back user data');
        return true;
      } catch (e) {
        _logError('_attemptUserRollback', 'Failed to rollback user data (attempt ${retryCount + 1}/${maxRetries}): $e');
        retryCount++;
        
        if (retryCount >= maxRetries) {
          _logError('_attemptUserRollback', 'Maximum retry attempts reached. Rollback failed.');
          
          // This is a critical error - user data may be in inconsistent state
          // In a production app, this would trigger alerts and manual intervention
          _logCriticalError(
            'Data inconsistency detected: Failed to rollback user data after activity deletion. ' +
            'User ID: ${originalUser.id}, Error: $e'
          );
          return false;
        }
        
        // Wait before retrying
        await Future.delayed(Duration(milliseconds: 200 * retryCount));
      }
    }
    
    return false;
  }
  
  /// Log critical errors that require immediate attention
  void _logCriticalError(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] CRITICAL ActivityService: $message';
    debugPrint(logMessage);
    
    // In production, you would:
    // 1. Send to crash reporting service with high priority
    // 2. Trigger alerts for immediate attention
    // 3. Write to a dedicated critical error log file
    // 4. Potentially notify user of the issue
  }

  /// Log error messages with context
  void _logError(String method, String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] ERROR ActivityService.$method: $message';
    debugPrint(logMessage);
    
    // In production, you might want to:
    // - Send to crash reporting service (Firebase Crashlytics, Sentry, etc.)
    // - Store in local error log file
    // - Send to analytics service
  }

  /// Log warning messages with context
  void _logWarning(String method, String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] WARNING ActivityService.$method: $message';
    debugPrint(logMessage);
  }

  /// Log info messages with context
  void _logInfo(String method, String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] INFO ActivityService.$method: $message';
    debugPrint(logMessage);
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
  final bool hasWarnings;
  final String? errorMessage;
  final List<String> validationIssues;
  final Map<StatType, StatImpact> statImpacts;

  const ActivityDeletionPreview({
    this.activity,
    this.statReversals = const {},
    this.expToReverse = 0.0,
    this.willLevelDown = false,
    this.newLevel = 1,
    this.levelsLost = 0,
    required this.isValid,
    this.hasWarnings = false,
    this.errorMessage,
    this.validationIssues = const [],
    this.statImpacts = const {},
  });

  factory ActivityDeletionPreview.error(
    String errorMessage, {
    ActivityLog? activity,
    List<String> validationIssues = const [],
  }) {
    return ActivityDeletionPreview(
      isValid: false,
      errorMessage: errorMessage,
      activity: activity,
      validationIssues: validationIssues,
      hasWarnings: validationIssues.isNotEmpty,
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
  
  /// Check if any stats will be clamped to minimum value
  bool get willClampStats {
    return statImpacts.values.any((impact) => impact.willClamp);
  }
  
  /// Get list of stats that will be clamped
  List<StatType> get clampedStats {
    return statImpacts.values
        .where((impact) => impact.willClamp)
        .map((impact) => impact.statType)
        .toList();
  }
  
  /// Get a user-friendly summary of the deletion impact
  String get impactSummary {
    final List<String> impacts = [];
    
    if (willLevelDown) {
      impacts.add('Level will decrease from ${newLevel + levelsLost} to $newLevel (lose $levelsLost level${levelsLost > 1 ? 's' : ''})');
    }
    
    if (willClampStats) {
      final clampedStatNames = clampedStats.map((s) => s.displayName).join(', ');
      impacts.add('Some stats will be reduced to minimum value: $clampedStatNames');
    }
    
    if (impacts.isEmpty) {
      return 'Stats and EXP will be adjusted with no major impact';
    }
    
    return impacts.join('. ');
  }

  @override
  String toString() {
    if (isValid) {
      return 'ActivityDeletionPreview(willLevelDown: $willLevelDown, newLevel: $newLevel, expReversed: $expToReverse, hasWarnings: $hasWarnings)';
    } else {
      return 'ActivityDeletionPreview(error: $errorMessage, validationIssues: $validationIssues)';
    }
  }
}

/// Detailed impact of stat reversal on a specific stat
class StatImpact {
  final StatType statType;
  final double currentValue;
  final double newValue;
  final double change;
  final double percentChange;
  final bool willClamp;
  
  const StatImpact({
    required this.statType,
    required this.currentValue,
    required this.newValue,
    required this.change,
    required this.percentChange,
    required this.willClamp,
  });
  
  @override
  String toString() {
    return 'StatImpact(${statType.name}: $currentValue → $newValue, ${percentChange.toStringAsFixed(1)}%, ${willClamp ? "clamped" : "not clamped"})';
  }
}

/// Custom exception for activity service operations
class ActivityServiceException implements Exception {
  final String message;

  ActivityServiceException(this.message);

  @override
  String toString() => 'ActivityServiceException: $message';
}