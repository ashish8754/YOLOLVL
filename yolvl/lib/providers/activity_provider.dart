import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../models/activity_log.dart';
import '../models/enums.dart';
import '../models/achievement.dart';
import '../services/activity_service.dart';
import '../services/app_lifecycle_service.dart';
import '../repositories/activity_repository.dart';
import '../repositories/user_repository.dart';

/// Provider for managing activity logging, history, and deletion with stat reversal
/// 
/// This provider serves as the central state management hub for all activity-related
/// operations, including the complex activity deletion process with stat reversal.
/// It coordinates with ActivityService and UserProvider to ensure consistent state
/// across the application.
/// 
/// **Key Responsibilities:**
/// - Activity logging with stat and EXP gain calculation
/// - Activity history management with filtering and pagination
/// - Activity deletion with comprehensive stat reversal
/// - Real-time UI updates during deletion operations
/// - Error handling and user feedback for all operations
/// - Integration with notification systems for achievements
/// 
/// **Activity Deletion Features:**
/// - Preview deletion impact before execution
/// - Safe deletion with validation and rollback
/// - Immediate UI updates for responsive user experience
/// - Comprehensive error handling with user-friendly messages
/// - Integration with UserProvider for stat reversal coordination
/// 
/// **State Management:**
/// - Reactive updates using ChangeNotifier
/// - Loading states for all async operations
/// - Error and success message management
/// - Optimistic UI updates for better user experience
/// - Automatic data refresh after operations
/// 
/// **Integration Points:**
/// - ActivityService for business logic and validation
/// - UserProvider for stat reversal coordination
/// - NotificationService for achievement alerts
/// - UI components for reactive state updates
/// 
/// **Performance Optimizations:**
/// - Immediate local state updates for UI responsiveness
/// - Background data refresh for consistency
/// - Efficient list management for large activity histories
/// - Pagination support for memory optimization
/// 
/// Usage Example:
/// ```dart
/// // Delete activity with full stat reversal
/// final result = await activityProvider.deleteActivity('activity_123');
/// if (result.success) {
///   // UI automatically updates, UserProvider handles stat reversal
///   showSuccess('Activity deleted and stats reversed');
/// } else {
///   showError(activityProvider.getDeletionErrorMessage(result));
/// }
/// ```
class ActivityProvider extends ChangeNotifier {
  final ActivityService _activityService;
  final AppLifecycleService? _appLifecycleService;
  
  List<ActivityLog> _activityHistory = [];
  List<ActivityLog> _todaysActivities = [];
  List<ActivityLog> _recentActivities = [];
  Map<ActivityType, ActivityStats> _activityStats = {};
  
  bool _isLoading = false;
  bool _isLoggingActivity = false;
  bool _isDeletingActivity = false;
  String? _errorMessage;
  String? _successMessage;
  
  // Activity logging state
  ActivityType _selectedActivityType = ActivityType.workoutWeights;
  int _selectedDuration = 60;
  String _activityNotes = '';
  ActivityGainPreview? _gainPreview;
  
  // Notification callbacks
  Function(int newLevel)? _onLevelUp;
  Function(int streakDays)? _onStreakMilestone;
  Function(List<AchievementUnlockResult> achievements)? _onAchievementsUnlocked;

  ActivityProvider({
    ActivityService? activityService,
    AppLifecycleService? appLifecycleService,
  }) : _activityService = activityService ?? ActivityService(
          activityRepository: ActivityRepository(),
          userRepository: UserRepository(),
        ),
       _appLifecycleService = appLifecycleService {
    // Listen to app lifecycle changes if service is provided
    _appLifecycleService?.addListener(_onAppLifecycleChanged);
  }

  // Getters
  List<ActivityLog> get activityHistory => List.unmodifiable(_activityHistory);
  List<ActivityLog> get todaysActivities => List.unmodifiable(_todaysActivities);
  List<ActivityLog> get recentActivities => List.unmodifiable(_recentActivities);
  Map<ActivityType, ActivityStats> get activityStats => Map.unmodifiable(_activityStats);
  
  bool get isLoading => _isLoading;
  bool get isLoggingActivity => _isLoggingActivity;
  bool get isDeletingActivity => _isDeletingActivity;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  
  // Activity logging getters
  ActivityType get selectedActivityType => _selectedActivityType;
  int get selectedDuration => _selectedDuration;
  String get activityNotes => _activityNotes;
  ActivityGainPreview? get gainPreview => _gainPreview;

  /// Initialize activity data
  Future<void> initialize() async {
    _setLoading(true);
    _clearError();

    try {
      await Future.wait([
        loadTodaysActivities(),
        loadRecentActivities(),
        loadActivityStats(),
      ]);
    } catch (e) {
      _setError('Failed to initialize activity data: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Log a new activity
  Future<ActivityLogResult?> logActivity({
    ActivityType? activityType,
    int? durationMinutes,
    String? notes,
    DateTime? timestamp,
  }) async {
    _setLoggingActivity(true);
    _clearError();

    try {
      final result = await _activityService.logActivity(
        activityType: activityType ?? _selectedActivityType,
        durationMinutes: durationMinutes ?? _selectedDuration,
        notes: notes ?? (_activityNotes.isNotEmpty ? _activityNotes : null),
        timestamp: timestamp,
      );

      if (result.success) {
        // Handle level up notification
        if (result.leveledUp && _onLevelUp != null) {
          _onLevelUp!(result.newLevel);
        }
        
        // Check for streak milestones
        if (result.activityLog != null) {
          final streak = await getActivityStreak(result.activityLog!.activityTypeEnum);
          if (streak > 0 && (streak % 7 == 0 || streak % 30 == 0) && _onStreakMilestone != null) {
            _onStreakMilestone!(streak);
          }
        }
        
        // Refresh activity data after successful logging
        await Future.wait([
          loadTodaysActivities(),
          loadRecentActivities(),
        ]);
        
        // Reset logging form
        resetLoggingForm();
      } else {
        _setError(result.errorMessage ?? 'Failed to log activity');
      }

      return result;
    } catch (e) {
      _setError('Failed to log activity: $e');
      return null;
    } finally {
      _setLoggingActivity(false);
    }
  }

  /// Load activity history with optional filtering
  Future<void> loadActivityHistory({
    DateTime? startDate,
    DateTime? endDate,
    ActivityType? activityType,
    int? limit,
    int page = 0,
    int pageSize = 20,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final activities = await _activityService.getActivityHistory(
        startDate: startDate,
        endDate: endDate,
        activityType: activityType,
        limit: limit,
        page: page,
        pageSize: pageSize,
      );
      
      _activityHistory = activities;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load activity history: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load today's activities
  Future<void> loadTodaysActivities() async {
    try {
      final activities = await _activityService.getTodaysActivities();
      _todaysActivities = activities;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load today\'s activities: $e');
    }
  }

  /// Load recent activities
  Future<void> loadRecentActivities({int limit = 10}) async {
    try {
      final activities = await _activityService.getRecentActivities(limit: limit);
      _recentActivities = activities;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load recent activities: $e');
    }
  }

  /// Load activity statistics
  Future<void> loadActivityStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final stats = await _activityService.getActivityStats(
        startDate: startDate,
        endDate: endDate,
      );
      _activityStats = stats;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load activity stats: $e');
    }
  }

  /// Get activity streak for specific type
  Future<int> getActivityStreak(ActivityType activityType) async {
    try {
      return await _activityService.getActivityStreak(activityType);
    } catch (e) {
      _setError('Failed to get activity streak: $e');
      return 0;
    }
  }

  /// Delete an activity with comprehensive stat reversal and UI coordination
  /// 
  /// This method provides a high-level interface for activity deletion that coordinates
  /// between ActivityService for the deletion logic and the UI for immediate feedback.
  /// It implements optimistic UI updates for responsiveness while ensuring data consistency.
  /// 
  /// **Process Flow:**
  /// 1. Set loading state and clear previous messages
  /// 2. Preview deletion to validate safety and show warnings
  /// 3. Perform safe deletion through ActivityService
  /// 4. Immediately update local state for UI responsiveness
  /// 5. Refresh data from repository for consistency
  /// 6. Provide user feedback through success/error messages
  /// 
  /// **UI Coordination:**
  /// - Immediate removal from local activity lists for instant UI update
  /// - Loading state management during deletion process
  /// - Error and success message management for user feedback
  /// - Automatic data refresh to ensure consistency with repository
  /// 
  /// **Safety Features:**
  /// - Preview validation before actual deletion
  /// - Warning handling for edge cases
  /// - Comprehensive error handling with user-friendly messages
  /// - Rollback support if deletion fails partway through
  /// 
  /// **Performance Optimizations:**
  /// - Optimistic UI updates for immediate feedback
  /// - Background data refresh for consistency
  /// - Efficient state management to minimize re-renders
  /// 
  /// **Integration with UserProvider:**
  /// - Stat reversal is handled by ActivityService and UserProvider
  /// - This provider focuses on activity-specific state management
  /// - Coordinates with UserProvider for consistent state updates
  /// 
  /// **Error Handling:**
  /// - Validation errors from preview phase
  /// - Service-level errors during deletion
  /// - Network or storage errors during data refresh
  /// - User-friendly error message generation
  /// 
  /// @param activityId The unique identifier of the activity to delete
  /// @return ActivityDeletionResult with detailed operation status and information
  /// 
  /// Example:
  /// ```dart
  /// final result = await activityProvider.deleteActivity('activity_123');
  /// 
  /// if (result.success) {
  ///   // UI already updated optimistically
  ///   showSnackbar('Activity deleted successfully');
  ///   
  ///   if (result.leveledDown) {
  ///     showDialog('You leveled down to ${result.newLevel}');
  ///   }
  /// } else {
  ///   // Show user-friendly error message
  ///   final errorMsg = activityProvider.getDeletionErrorMessage(result);
  ///   showError(errorMsg);
  /// }
  /// ```
  Future<ActivityDeletionResult> deleteActivity(String activityId) async {
    _setDeletingActivity(true);
    _clearError();
    _clearSuccess();

    try {
      // First preview the deletion to check for issues
      final preview = await _activityService.previewActivityDeletion(activityId);
      
      if (!preview.isValid) {
        final errorMessage = preview.errorMessage ?? 'Cannot safely delete activity due to validation issues';
        _setError(errorMessage);
        return ActivityDeletionResult.error(errorMessage);
      }
      
      // If there are warnings, log them but proceed
      if (preview.hasWarnings) {
        _logWarning('Proceeding with deletion despite warnings: ${preview.validationIssues.join(", ")}');
      }
      
      // Proceed with actual deletion using the safe delete method
      final result = await _activityService.safeDeleteActivity(activityId, skipPreview: true);
      
      if (result.success) {
        // Immediately remove the activity from local lists for instant UI update
        _activityHistory.removeWhere((activity) => activity.id == activityId);
        _todaysActivities.removeWhere((activity) => activity.id == activityId);
        _recentActivities.removeWhere((activity) => activity.id == activityId);
        
        // Notify listeners immediately for instant UI update
        notifyListeners();
        
        // Then refresh data from repository to ensure consistency
        await refreshAfterDeletion();
        
        // Set success message
        _setSuccess(getDeletionSuccessMessage(result));
        
        return result;
      } else {
        final errorMessage = result.errorMessage ?? 'Failed to delete activity';
        _setError(errorMessage);
        return result;
      }
    } catch (e) {
      final errorMessage = 'Failed to delete activity: $e';
      _setError(errorMessage);
      return ActivityDeletionResult.error(errorMessage);
    } finally {
      _setDeletingActivity(false);
    }
  }

  /// Delete an activity with stat reversal (legacy method for backward compatibility)
  /// Returns a simple boolean for existing code that expects this signature
  Future<bool> deleteActivitySimple(String activityId) async {
    final result = await deleteActivity(activityId);
    return result.success;
  }
  
  /// Preview activity deletion without actually deleting
  Future<ActivityDeletionPreview> previewActivityDeletion(String activityId) async {
    try {
      return await _activityService.previewActivityDeletion(activityId);
    } catch (e) {
      _setError('Failed to preview activity deletion: $e');
      return ActivityDeletionPreview.error('Failed to preview deletion: $e');
    }
  }
  
  /// Log warning messages
  void _logWarning(String message) {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('[$timestamp] WARNING ActivityProvider: $message');
  }

  /// Set selected activity type for logging
  void setSelectedActivityType(ActivityType activityType) {
    if (_selectedActivityType != activityType) {
      _selectedActivityType = activityType;
      _updateGainPreview();
      notifyListeners();
    }
  }

  /// Set selected duration for logging
  void setSelectedDuration(int durationMinutes) {
    if (_selectedDuration != durationMinutes) {
      _selectedDuration = durationMinutes;
      _updateGainPreview();
      notifyListeners();
    }
  }

  /// Set activity notes
  void setActivityNotes(String notes) {
    if (_activityNotes != notes) {
      _activityNotes = notes;
      notifyListeners();
    }
  }

  /// Update gain preview based on current selections
  void _updateGainPreview() {
    _gainPreview = _activityService.calculateExpectedGains(
      activityType: _selectedActivityType,
      durationMinutes: _selectedDuration,
    );
  }

  /// Reset logging form to defaults
  void resetLoggingForm() {
    _selectedActivityType = ActivityType.workoutWeights;
    _selectedDuration = 60;
    _activityNotes = '';
    _gainPreview = null;
    notifyListeners();
  }

  /// Get activities for a specific date
  List<ActivityLog> getActivitiesForDate(DateTime date) {
    return _activityHistory.where((activity) {
      return activity.timestamp.year == date.year &&
             activity.timestamp.month == date.month &&
             activity.timestamp.day == date.day;
    }).toList();
  }

  /// Get activities for current week
  List<ActivityLog> getThisWeeksActivities() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    
    return _activityHistory.where((activity) {
      return activity.timestamp.isAfter(startOfWeek);
    }).toList();
  }

  /// Get total EXP gained today
  double getTodaysEXP() {
    return _todaysActivities.fold(0.0, (sum, activity) => sum + activity.expGained);
  }

  /// Get total EXP gained this week
  double getThisWeeksEXP() {
    return getThisWeeksActivities().fold(0.0, (sum, activity) => sum + activity.expGained);
  }

  /// Get activity count for today
  int getTodaysActivityCount() {
    return _todaysActivities.length;
  }

  /// Get activity count for this week
  int getThisWeeksActivityCount() {
    return getThisWeeksActivities().length;
  }

  /// Get most frequent activity type
  ActivityType? getMostFrequentActivityType() {
    if (_activityHistory.isEmpty) return null;
    
    final activityCounts = <ActivityType, int>{};
    for (final activity in _activityHistory) {
      final type = activity.activityTypeEnum;
      activityCounts[type] = (activityCounts[type] ?? 0) + 1;
    }
    
    return activityCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Get longest streak for any activity
  Future<Map<ActivityType, int>> getAllActivityStreaks() async {
    final streaks = <ActivityType, int>{};
    
    for (final activityType in ActivityType.values) {
      try {
        final streak = await _activityService.getActivityStreak(activityType);
        streaks[activityType] = streak;
      } catch (e) {
        streaks[activityType] = 0;
      }
    }
    
    return streaks;
  }

  /// Get a specific activity by ID
  ActivityLog? getActivityById(String activityId) {
    // Check in activity history first
    for (final activity in _activityHistory) {
      if (activity.id == activityId) {
        return activity;
      }
    }
    
    // Check in today's activities
    for (final activity in _todaysActivities) {
      if (activity.id == activityId) {
        return activity;
      }
    }
    
    // Check in recent activities
    for (final activity in _recentActivities) {
      if (activity.id == activityId) {
        return activity;
      }
    }
    
    return null;
  }

  /// Check if an activity exists in any of the loaded lists
  bool hasActivity(String activityId) {
    return getActivityById(activityId) != null;
  }

  /// Refresh activity lists after deletion to ensure UI consistency
  Future<void> refreshAfterDeletion() async {
    try {
      // Reload all activity data to ensure consistency
      await Future.wait([
        loadTodaysActivities(),
        loadRecentActivities(),
        loadActivityHistory(),
        loadActivityStats(),
      ]);
    } catch (e) {
      _setError('Failed to refresh activities after deletion: $e');
    }
  }

  /// Get user-friendly error message for deletion failures
  String getDeletionErrorMessage(ActivityDeletionResult result) {
    if (result.success) {
      return '';
    }

    final errorMessage = result.errorMessage ?? 'Unknown error occurred';
    
    // Provide user-friendly messages for common error scenarios
    if (errorMessage.contains('Activity not found')) {
      return 'This activity has already been deleted or does not exist.';
    } else if (errorMessage.contains('validation failed')) {
      return 'This activity cannot be safely deleted due to data integrity issues.';
    } else if (errorMessage.contains('stat reversal')) {
      return 'Unable to reverse the stat changes from this activity. Please try again.';
    } else if (errorMessage.contains('EXP reversal')) {
      return 'Unable to reverse the experience points from this activity. Please try again.';
    } else if (errorMessage.contains('No user found')) {
      return 'User data not found. Please restart the app and try again.';
    } else {
      return 'Failed to delete activity. Please try again later.';
    }
  }

  /// Get success message for deletion
  String getDeletionSuccessMessage(ActivityDeletionResult result) {
    if (!result.success || result.deletedActivity == null) {
      return '';
    }

    final activity = result.deletedActivity!;
    final activityName = _getActivityDisplayName(activity.activityTypeEnum);
    
    String message = 'Successfully deleted $activityName activity';
    
    if (result.leveledDown) {
      message += ' (Level reduced to ${result.newLevel})';
    }
    
    return message;
  }

  /// Get display name for activity type
  String _getActivityDisplayName(ActivityType activityType) {
    switch (activityType) {
      case ActivityType.workoutWeights:
        return 'Weight Training';
      case ActivityType.workoutCardio:
        return 'Cardio';
      case ActivityType.workoutYoga:
        return 'Yoga/Flexibility';
      case ActivityType.studySerious:
        return 'Serious Study';
      case ActivityType.studyCasual:
        return 'Casual Study';
      case ActivityType.meditation:
        return 'Meditation';
      case ActivityType.socializing:
        return 'Socializing';
      case ActivityType.quitBadHabit:
        return 'Quit Bad Habit';
      case ActivityType.sleepTracking:
        return 'Sleep Tracking';
      case ActivityType.dietHealthy:
        return 'Healthy Diet';
    }
  }

  /// Set callback for level up notifications
  void setLevelUpCallback(Function(int newLevel)? callback) {
    _onLevelUp = callback;
  }

  /// Set callback for streak milestone notifications
  void setStreakMilestoneCallback(Function(int streakDays)? callback) {
    _onStreakMilestone = callback;
  }

  /// Set callback for achievement unlock notifications
  void setAchievementUnlockedCallback(Function(List<AchievementUnlockResult> achievements)? callback) {
    _onAchievementsUnlocked = callback;
  }

  /// Refresh all activity data
  Future<void> refreshAll() async {
    await initialize();
  }

  /// Clear error message
  void clearError() {
    _clearError();
  }

  /// Clear success message
  void clearSuccess() {
    _clearSuccess();
  }

  /// Clear all messages
  void clearMessages() {
    _clearError();
    _clearSuccess();
  }

  @override
  void dispose() {
    _appLifecycleService?.removeListener(_onAppLifecycleChanged);
    super.dispose();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setLoggingActivity(bool logging) {
    _isLoggingActivity = logging;
    notifyListeners();
  }

  void _setDeletingActivity(bool deleting) {
    _isDeletingActivity = deleting;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _successMessage = null; // Clear success message when error occurs
    notifyListeners();
  }

  void _setSuccess(String success) {
    _successMessage = success;
    _errorMessage = null; // Clear error message when success occurs
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  void _clearSuccess() {
    if (_successMessage != null) {
      _successMessage = null;
      notifyListeners();
    }
  }

  /// Handle app lifecycle changes
  void _onAppLifecycleChanged() {
    // Refresh activity data when app resumes to ensure sync
    if (_appLifecycleService?.currentState == AppLifecycleState.resumed) {
      refreshAll().catchError((error) {
        debugPrint('Error refreshing activities on app resume: $error');
      });
    }
  }
}