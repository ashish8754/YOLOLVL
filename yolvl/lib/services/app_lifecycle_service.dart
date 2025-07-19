import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import '../models/user.dart';
import '../models/enums.dart';
import '../services/degradation_service.dart';
import '../services/user_service.dart';
import '../services/backup_service.dart';
import '../services/notification_service.dart';
import '../services/data_integrity_service.dart';
import '../repositories/user_repository.dart';
import '../repositories/settings_repository.dart';

/// Service for managing app lifecycle events and background processing
class AppLifecycleService extends ChangeNotifier with WidgetsBindingObserver {
  final UserService _userService;
  final SettingsRepository _settingsRepository;
  final BackupService _backupService;
  final NotificationService _notificationService;
  final DataIntegrityService _dataIntegrityService;
  
  AppLifecycleState _currentState = AppLifecycleState.resumed;
  DateTime? _lastPausedTime;
  bool _isInitialized = false;
  
  // Degradation check results
  bool _hasPendingDegradation = false;
  List<DegradationWarning> _degradationWarnings = [];
  Map<StatType, double> _pendingDegradation = {};
  
  // Data integrity results
  DataIntegrityResult? _lastIntegrityCheck;

  AppLifecycleService({
    UserService? userService,
    SettingsRepository? settingsRepository,
    BackupService? backupService,
    NotificationService? notificationService,
    DataIntegrityService? dataIntegrityService,
  }) : _userService = userService ?? UserService(UserRepository()),
       _settingsRepository = settingsRepository ?? SettingsRepository(),
       _backupService = backupService ?? BackupService(),
       _notificationService = notificationService ?? NotificationService(),
       _dataIntegrityService = dataIntegrityService ?? DataIntegrityService();

  // Getters
  AppLifecycleState get currentState => _currentState;
  DateTime? get lastPausedTime => _lastPausedTime;
  bool get isInitialized => _isInitialized;
  bool get hasPendingDegradation => _hasPendingDegradation;
  List<DegradationWarning> get degradationWarnings => List.unmodifiable(_degradationWarnings);
  Map<StatType, double> get pendingDegradation => Map.unmodifiable(_pendingDegradation);
  DataIntegrityResult? get lastIntegrityCheck => _lastIntegrityCheck;

  /// Initialize the app lifecycle service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Add this as an observer for app lifecycle changes
      WidgetsBinding.instance.addObserver(this);
      
      // Perform data integrity check and recovery on startup
      await _performStartupIntegrityCheck();
      
      // Perform initial degradation check
      await _performDegradationCheck();
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to initialize AppLifecycleService: $e');
    }
  }

  /// Dispose of the service
  @override
  void dispose() {
    if (_isInitialized) {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }

  /// Handle app lifecycle state changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    final previousState = _currentState;
    _currentState = state;
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _handleAppPaused();
        break;
      case AppLifecycleState.resumed:
        _handleAppResumed(previousState);
        break;
      case AppLifecycleState.inactive:
        // App is transitioning between states, no action needed
        break;
      case AppLifecycleState.hidden:
        // App is hidden but still running, treat similar to paused
        _handleAppPaused();
        break;
    }
    
    notifyListeners();
  }

  /// Handle app being paused or sent to background
  void _handleAppPaused() {
    _lastPausedTime = DateTime.now();
    debugPrint('App paused at: $_lastPausedTime');
    
    // Create automatic backup when app is paused
    _createAutomaticBackup().catchError((error) {
      debugPrint('Error during automatic backup: $error');
    });
  }

  /// Create automatic backup if needed
  Future<void> _createAutomaticBackup() async {
    try {
      final backupFile = await _backupService.createAutomaticBackup();
      if (backupFile != null) {
        debugPrint('Automatic backup created: ${backupFile.path}');
        
        // Clean up old backups to save space
        await _backupService.cleanupOldBackups(keepCount: 5);
      }
    } catch (e) {
      debugPrint('Failed to create automatic backup: $e');
    }
  }

  /// Handle app being resumed from background
  void _handleAppResumed(AppLifecycleState previousState) {
    debugPrint('App resumed from: $previousState');
    
    // Only perform degradation check if app was actually paused
    if (previousState == AppLifecycleState.paused || 
        previousState == AppLifecycleState.detached ||
        previousState == AppLifecycleState.hidden) {
      
      // Perform degradation check asynchronously
      _performDegradationCheck().catchError((error) {
        debugPrint('Error during degradation check on resume: $error');
        return DegradationCheckResult.error(error.toString());
      });
    }
  }

  /// Perform degradation check and apply if necessary
  Future<DegradationCheckResult> _performDegradationCheck() async {
    try {
      // Get current user
      final user = _userService.getCurrentUser();
      if (user == null) {
        return DegradationCheckResult.noUser();
      }

      // Get settings for relaxed weekend mode
      final settings = _settingsRepository.getSettings();
      final relaxedWeekendMode = settings.relaxedWeekendMode;

      // Check for pending degradation
      final hasPending = DegradationService.hasPendingDegradation(
        user,
        relaxedWeekendMode: relaxedWeekendMode,
      );

      // Get degradation warnings
      final warnings = DegradationService.getDegradationWarnings(
        user,
        relaxedWeekendMode: relaxedWeekendMode,
      );

      // Calculate pending degradation amounts
      final pendingDegradation = DegradationService.calculateAllDegradation(
        user,
        relaxedWeekendMode: relaxedWeekendMode,
      );

      // Update internal state
      _hasPendingDegradation = hasPending;
      _degradationWarnings = warnings;
      _pendingDegradation = pendingDegradation;

      // Send degradation warning notifications if enabled
      if (warnings.isNotEmpty && settings.degradationWarningsEnabled && settings.notificationsEnabled) {
        await _sendDegradationWarningNotifications(warnings);
      }

      // Apply degradation if necessary
      if (hasPending && pendingDegradation.isNotEmpty) {
        await _applyDegradation(user, pendingDegradation, relaxedWeekendMode);
        
        return DegradationCheckResult.applied(
          degradationApplied: pendingDegradation,
          warnings: warnings,
        );
      } else {
        return DegradationCheckResult.checked(
          warnings: warnings,
        );
      }
    } catch (e) {
      debugPrint('Error during degradation check: $e');
      return DegradationCheckResult.error(e.toString());
    }
  }

  /// Apply degradation to user stats
  Future<void> _applyDegradation(
    User user,
    Map<StatType, double> degradationMap,
    bool relaxedWeekendMode,
  ) async {
    try {
      // Apply degradation using the service
      DegradationService.applyDegradation(
        user,
        relaxedWeekendMode: relaxedWeekendMode,
      );

      // Update user stats through the user service
      await _userService.updateStats(
        userId: user.id,
        statUpdates: degradationMap,
      );

      debugPrint('Applied degradation: $degradationMap');
    } catch (e) {
      debugPrint('Failed to apply degradation: $e');
      rethrow;
    }
  }

  /// Manually trigger degradation check (for testing or manual refresh)
  Future<DegradationCheckResult> performManualDegradationCheck() async {
    return await _performDegradationCheck();
  }

  /// Check if enough time has passed since last pause to warrant degradation check
  bool shouldCheckDegradation() {
    if (_lastPausedTime == null) return true;
    
    final timeSincePause = DateTime.now().difference(_lastPausedTime!);
    // Check degradation if app was paused for more than 1 hour
    return timeSincePause.inHours >= 1;
  }

  /// Get time since app was last paused
  Duration? getTimeSinceLastPause() {
    if (_lastPausedTime == null) return null;
    return DateTime.now().difference(_lastPausedTime!);
  }

  /// Clear degradation warnings (after user acknowledges them)
  void clearDegradationWarnings() {
    _degradationWarnings.clear();
    _hasPendingDegradation = false;
    _pendingDegradation.clear();
    notifyListeners();
  }

  /// Send degradation warning notifications
  Future<void> _sendDegradationWarningNotifications(List<DegradationWarning> warnings) async {
    try {
      for (final warning in warnings) {
        final missedActivities = _getActivityTypesForWarning(warning);
        await _notificationService.scheduleDegradationWarning(
          missedActivities: missedActivities,
          daysMissed: warning.daysSinceLastActivity,
        );
      }
    } catch (e) {
      debugPrint('Failed to send degradation warning notifications: $e');
    }
  }

  /// Get activity types that are causing degradation warning
  List<ActivityType> _getActivityTypesForWarning(DegradationWarning warning) {
    // Map stat types back to activity types that affect them
    final activityTypes = <ActivityType>[];
    
    for (final statType in warning.affectedStats) {
      switch (statType) {
        case StatType.strength:
        case StatType.endurance:
          if (!activityTypes.contains(ActivityType.workoutWeights)) {
            activityTypes.add(ActivityType.workoutWeights);
          }
          if (!activityTypes.contains(ActivityType.workoutCardio)) {
            activityTypes.add(ActivityType.workoutCardio);
          }
          break;
        case StatType.agility:
          if (!activityTypes.contains(ActivityType.workoutCardio)) {
            activityTypes.add(ActivityType.workoutCardio);
          }
          if (!activityTypes.contains(ActivityType.workoutYoga)) {
            activityTypes.add(ActivityType.workoutYoga);
          }
          break;
        case StatType.intelligence:
          if (!activityTypes.contains(ActivityType.studySerious)) {
            activityTypes.add(ActivityType.studySerious);
          }
          if (!activityTypes.contains(ActivityType.studyCasual)) {
            activityTypes.add(ActivityType.studyCasual);
          }
          break;
        case StatType.focus:
          if (!activityTypes.contains(ActivityType.studySerious)) {
            activityTypes.add(ActivityType.studySerious);
          }
          if (!activityTypes.contains(ActivityType.workoutYoga)) {
            activityTypes.add(ActivityType.workoutYoga);
          }
          break;
        case StatType.charisma:
          // Charisma doesn't degrade according to requirements
          break;
      }
    }
    
    return activityTypes;
  }

  /// Perform startup data integrity check and recovery
  Future<void> _performStartupIntegrityCheck() async {
    try {
      debugPrint('Performing startup data integrity check...');
      
      // Run comprehensive integrity check
      final integrityResult = await _dataIntegrityService.performIntegrityCheck();
      _lastIntegrityCheck = integrityResult;
      
      if (!integrityResult.success) {
        debugPrint('Data integrity check failed: ${integrityResult.issues.length} issues found');
        
        // Log critical issues
        for (final issue in integrityResult.issues) {
          if (issue.severity == DataIntegritySeverity.critical) {
            debugPrint('CRITICAL: ${issue.description}');
          }
        }
        
        // If there are critical issues that couldn't be auto-fixed, 
        // the app should handle this gracefully (e.g., show recovery UI)
        if (integrityResult.requiresUserAction) {
          debugPrint('Data integrity issues require user action');
        }
      } else {
        debugPrint('Data integrity check passed');
        if (integrityResult.fixesApplied.isNotEmpty) {
          debugPrint('Applied ${integrityResult.fixesApplied.length} automatic fixes');
          for (final fix in integrityResult.fixesApplied) {
            debugPrint('  - $fix');
          }
        }
      }
    } catch (e) {
      debugPrint('Startup integrity check failed: $e');
      // Continue with app initialization even if integrity check fails
      // The app should still be usable, though data might be inconsistent
    }
  }

  /// Get the result of the last data integrity check
  DataIntegrityResult? getLastIntegrityCheckResult() {
    return _lastIntegrityCheck;
  }

  /// Manually trigger data integrity check
  Future<DataIntegrityResult> performManualIntegrityCheck() async {
    final result = await _dataIntegrityService.performIntegrityCheck();
    _lastIntegrityCheck = result;
    notifyListeners();
    return result;
  }

  /// Check if the app has recovered from a crash
  bool get hasRecoveredFromCrash {
    return _lastIntegrityCheck?.fixesApplied.isNotEmpty ?? false;
  }

  /// Check if there are unresolved data integrity issues
  bool get hasUnresolvedDataIssues {
    return _lastIntegrityCheck?.requiresUserAction ?? false;
  }

  /// Force refresh degradation status
  Future<void> refreshDegradationStatus() async {
    await _performDegradationCheck();
    notifyListeners();
  }
}

/// Result of a degradation check operation
class DegradationCheckResult {
  final bool success;
  final bool degradationApplied;
  final Map<StatType, double> degradationAmounts;
  final List<DegradationWarning> warnings;
  final String? errorMessage;

  const DegradationCheckResult._({
    required this.success,
    required this.degradationApplied,
    required this.degradationAmounts,
    required this.warnings,
    this.errorMessage,
  });

  factory DegradationCheckResult.applied({
    required Map<StatType, double> degradationApplied,
    required List<DegradationWarning> warnings,
  }) {
    return DegradationCheckResult._(
      success: true,
      degradationApplied: true,
      degradationAmounts: degradationApplied,
      warnings: warnings,
    );
  }

  factory DegradationCheckResult.checked({
    required List<DegradationWarning> warnings,
  }) {
    return DegradationCheckResult._(
      success: true,
      degradationApplied: false,
      degradationAmounts: const {},
      warnings: warnings,
    );
  }

  factory DegradationCheckResult.noUser() {
    return const DegradationCheckResult._(
      success: true,
      degradationApplied: false,
      degradationAmounts: {},
      warnings: [],
    );
  }

  factory DegradationCheckResult.error(String errorMessage) {
    return DegradationCheckResult._(
      success: false,
      degradationApplied: false,
      degradationAmounts: const {},
      warnings: const [],
      errorMessage: errorMessage,
    );
  }

  @override
  String toString() {
    return 'DegradationCheckResult(success: $success, applied: $degradationApplied, warnings: ${warnings.length})';
  }
}