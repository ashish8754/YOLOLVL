import 'package:flutter/foundation.dart';
import '../models/activity_log.dart';
import '../models/enums.dart';
import '../services/activity_service.dart';
import '../repositories/activity_repository.dart';
import '../repositories/user_repository.dart';

/// Provider for managing activity logging state and history
class ActivityProvider extends ChangeNotifier {
  final ActivityService _activityService;
  
  List<ActivityLog> _activityHistory = [];
  List<ActivityLog> _todaysActivities = [];
  List<ActivityLog> _recentActivities = [];
  Map<ActivityType, ActivityStats> _activityStats = {};
  
  bool _isLoading = false;
  bool _isLoggingActivity = false;
  String? _errorMessage;
  
  // Activity logging state
  ActivityType _selectedActivityType = ActivityType.workoutWeights;
  int _selectedDuration = 60;
  String _activityNotes = '';
  ActivityGainPreview? _gainPreview;

  ActivityProvider({ActivityService? activityService})
      : _activityService = activityService ?? ActivityService(
          activityRepository: ActivityRepository(),
          userRepository: UserRepository(),
        );

  // Getters
  List<ActivityLog> get activityHistory => List.unmodifiable(_activityHistory);
  List<ActivityLog> get todaysActivities => List.unmodifiable(_todaysActivities);
  List<ActivityLog> get recentActivities => List.unmodifiable(_recentActivities);
  Map<ActivityType, ActivityStats> get activityStats => Map.unmodifiable(_activityStats);
  
  bool get isLoading => _isLoading;
  bool get isLoggingActivity => _isLoggingActivity;
  String? get errorMessage => _errorMessage;
  
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

  /// Delete an activity
  Future<bool> deleteActivity(String activityId) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _activityService.deleteActivity(activityId);
      
      if (success) {
        // Refresh activity data after deletion
        await Future.wait([
          loadTodaysActivities(),
          loadRecentActivities(),
          loadActivityHistory(),
        ]);
      }
      
      return success;
    } catch (e) {
      _setError('Failed to delete activity: $e');
      return false;
    } finally {
      _setLoading(false);
    }
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

  /// Refresh all activity data
  Future<void> refreshAll() async {
    await initialize();
  }

  /// Clear error message
  void clearError() {
    _clearError();
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

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }
}