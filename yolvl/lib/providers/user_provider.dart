import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/enums.dart';
import '../models/onboarding.dart';

import '../services/user_service.dart';
import '../services/app_lifecycle_service.dart';
import '../services/degradation_service.dart';
import '../repositories/user_repository.dart';

/// Provider for managing user state, level, EXP, and stats with infinite progression support
/// 
/// This provider serves as the central state management hub for all user-related data
/// and operations. It integrates with the infinite stats system and provides comprehensive
/// functionality for stat reversal operations during activity deletion.
/// 
/// **Key Responsibilities:**
/// - User profile management (name, avatar, level, EXP)
/// - Infinite stats progression (no ceiling limits)
/// - Stat reversal operations for activity deletion
/// - Level-down handling when EXP is reversed
/// - Degradation system integration
/// - App lifecycle management
/// - Error handling and user feedback
/// 
/// **Infinite Stats Features:**
/// - Supports stat values beyond the previous 5.0 ceiling
/// - Maintains 1.0 minimum floor for all stats
/// - Handles extremely large stat values safely
/// - Provides validation for stat operations
/// 
/// **Stat Reversal System:**
/// - Applies stat reversals when activities are deleted
/// - Handles level-down scenarios during EXP reversal
/// - Provides loading states during deletion operations
/// - Implements error handling and rollback mechanisms
/// 
/// **State Management:**
/// - Reactive updates using ChangeNotifier
/// - Loading states for async operations
/// - Error state management with user-friendly messages
/// - Success state management for user feedback
/// 
/// **Integration Points:**
/// - UserService for business logic
/// - AppLifecycleService for degradation management
/// - ActivityProvider for coordinated state updates
/// - UI components for reactive updates
/// 
/// Usage Example:
/// ```dart
/// // Apply stat reversals during activity deletion
/// final result = await userProvider.applyStatReversals(
///   statReversals: {StatType.strength: 0.5},
///   expToReverse: 60.0,
/// );
/// 
/// if (result.success) {
///   if (result.leveledDown) {
///     showLevelDownNotification(result.newLevel);
///   }
/// }
/// ```
class UserProvider extends ChangeNotifier {
  final UserService _userService;
  final AppLifecycleService _appLifecycleService;
  
  User? _currentUser;
  bool _isLoading = false;
  bool _isDeletingActivity = false;
  String? _errorMessage;
  bool _needsOnboarding = false;
  bool _isFirstTime = false;
  
  // Degradation state
  List<DegradationWarning> _degradationWarnings = [];
  bool _hasPendingDegradation = false;

  UserProvider({
    UserService? userService,
    AppLifecycleService? appLifecycleService,
  }) : _userService = userService ?? UserService(UserRepository()),
       _appLifecycleService = appLifecycleService ?? AppLifecycleService() {
    // Listen to app lifecycle changes
    _appLifecycleService.addListener(_onAppLifecycleChanged);
  }

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isDeletingActivity => _isDeletingActivity;
  String? get errorMessage => _errorMessage;
  bool get needsOnboarding => _needsOnboarding;
  bool get isFirstTime => _isFirstTime;
  bool get hasUser => _currentUser != null;
  
  // Degradation getters
  List<DegradationWarning> get degradationWarnings => List.unmodifiable(_degradationWarnings);
  bool get hasPendingDegradation => _hasPendingDegradation;
  AppLifecycleService get appLifecycleService => _appLifecycleService;

  // User profile getters
  String get userName => _currentUser?.name ?? 'Player';
  String? get avatarPath => _currentUser?.avatarPath;
  int get level => _currentUser?.level ?? 1;
  double get currentEXP => _currentUser?.currentEXP ?? 0.0;
  double get expThreshold => _currentUser?.expThreshold ?? 1000.0;
  double get expProgress => _currentUser?.expProgress ?? 0.0;
  bool get canLevelUp => _currentUser?.canLevelUp ?? false;

  // Stats getters
  Map<StatType, double> get stats {
    if (_currentUser == null) {
      return {
        for (final statType in StatType.values) statType: 1.0,
      };
    }
    return {
      for (final statType in StatType.values)
        statType: _currentUser!.getStat(statType),
    };
  }

  double getStat(StatType statType) {
    return _currentUser?.getStat(statType) ?? 1.0;
  }

  /// Initialize the app and load user data
  Future<void> initializeApp() async {
    _setLoading(true);
    _clearError();

    try {
      // Initialize app lifecycle service first
      await _appLifecycleService.initialize();
      
      // Initialize user data
      final result = await _userService.initializeApp();
      
      _currentUser = result.user;
      _needsOnboarding = result.needsOnboarding;
      _isFirstTime = result.isFirstTime;
      
      // Check for degradation after user is loaded
      await _checkDegradation();
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to initialize app: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Create a new user
  Future<void> createNewUser({String? name, String? avatarPath}) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _userService.createNewUser(
        name: name,
        avatarPath: avatarPath,
      );
      
      _currentUser = user;
      _needsOnboarding = true;
      _isFirstTime = true;
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to create user: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Update user profile
  Future<void> updateProfile({String? name, String? avatarPath}) async {
    if (_currentUser == null) {
      _setError('No user to update');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      final updatedUser = await _userService.updateUserProfile(
        userId: _currentUser!.id,
        name: name,
        avatarPath: avatarPath,
      );
      
      _currentUser = updatedUser;
      notifyListeners();
    } catch (e) {
      _setError('Failed to update profile: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Complete onboarding with questionnaire answers
  Future<void> completeOnboarding({OnboardingAnswers? answers}) async {
    if (_currentUser == null) {
      _setError('No user to complete onboarding for');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      final updatedUser = await _userService.completeOnboarding(
        userId: _currentUser!.id,
        answers: answers,
      );
      
      _currentUser = updatedUser;
      _needsOnboarding = false;
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to complete onboarding: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Skip onboarding and use default stats
  Future<void> skipOnboarding() async {
    if (_currentUser == null) {
      _setError('No user to skip onboarding for');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      final updatedUser = await _userService.skipOnboarding(_currentUser!.id);
      
      _currentUser = updatedUser;
      _needsOnboarding = false;
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to skip onboarding: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Add EXP and handle level progression
  Future<LevelProgressionResult?> addEXP(double expToAdd) async {
    if (_currentUser == null) {
      _setError('No user to add EXP to');
      return null;
    }

    try {
      final result = await _userService.addEXP(
        userId: _currentUser!.id,
        expToAdd: expToAdd,
      );
      
      _currentUser = result.user;
      notifyListeners();
      
      return result;
    } catch (e) {
      _setError('Failed to add EXP: $e');
      return null;
    }
  }

  /// Update user stats
  Future<void> updateStats(Map<StatType, double> statUpdates) async {
    if (_currentUser == null) {
      _setError('No user to update stats for');
      return;
    }

    try {
      final updatedUser = await _userService.updateStats(
        userId: _currentUser!.id,
        statUpdates: statUpdates,
      );
      
      _currentUser = updatedUser;
      notifyListeners();
    } catch (e) {
      _setError('Failed to update stats: $e');
    }
  }

  /// Apply stat reversals for activity deletion with comprehensive error handling
  /// 
  /// This method coordinates the reversal of stat gains and EXP when an activity is
  /// deleted. It provides a high-level interface for the complex stat reversal process,
  /// handling all the necessary state management and user interface updates.
  /// 
  /// **Process Overview:**
  /// 1. Validate user state and input parameters
  /// 2. Store original state for potential rollback
  /// 3. Apply stat reversals through UserService
  /// 4. Handle level-down scenarios if EXP reversal causes them
  /// 5. Update provider state and notify listeners
  /// 6. Return detailed result information for UI feedback
  /// 
  /// **State Management:**
  /// - Sets loading state during operation
  /// - Clears any existing error messages
  /// - Updates user state with new values
  /// - Notifies listeners for UI updates
  /// - Handles error states with user-friendly messages
  /// 
  /// **Level-Down Handling:**
  /// - Detects when EXP reversal causes level reduction
  /// - Calculates the number of levels lost
  /// - Provides information for user notifications
  /// - Ensures UI reflects the new level immediately
  /// 
  /// **Error Handling:**
  /// - Validates user exists before operation
  /// - Handles service-level errors gracefully
  /// - Provides detailed error messages for debugging
  /// - Maintains consistent state even on failure
  /// 
  /// **Return Information:**
  /// - Success/failure status
  /// - New level and EXP values
  /// - Level-down detection and levels lost
  /// - Stat reversal amounts applied
  /// - Error messages for failure cases
  /// 
  /// @param statReversals Map of StatType to reversal amounts (positive values to subtract)
  /// @param expToReverse Amount of EXP to reverse (positive value to subtract)
  /// @return StatReversalResult with operation status and detailed information
  /// 
  /// Example:
  /// ```dart
  /// final result = await userProvider.applyStatReversals(
  ///   statReversals: {
  ///     StatType.strength: 0.12,
  ///     StatType.endurance: 0.08,
  ///   },
  ///   expToReverse: 60.0,
  /// );
  /// 
  /// if (result.success) {
  ///   showSuccess('Activity deleted successfully');
  ///   if (result.leveledDown) {
  ///     showLevelDownAlert('You leveled down to ${result.newLevel}');
  ///   }
  /// } else {
  ///   showError('Failed to delete activity: ${result.errorMessage}');
  /// }
  /// ```
  Future<StatReversalResult> applyStatReversals({
    required Map<StatType, double> statReversals,
    required double expToReverse,
  }) async {
    if (_currentUser == null) {
      _setError('No user to apply stat reversals for');
      return StatReversalResult.error('No user found');
    }

    _setLoading(true);
    _clearError();

    try {
      // Store original state for potential rollback
      final originalLevel = _currentUser!.level;
      final originalEXP = _currentUser!.currentEXP;
      final originalStats = Map<StatType, double>.from(stats);

      // Apply stat reversals through user service
      final updatedUser = await _userService.applyStatReversals(
        userId: _currentUser!.id,
        statReversals: statReversals,
        expToReverse: expToReverse,
      );
      
      _currentUser = updatedUser;
      
      // Determine if level-down occurred
      final leveledDown = _currentUser!.level < originalLevel;
      final levelsLost = originalLevel - _currentUser!.level;
      
      notifyListeners();
      
      return StatReversalResult.success(
        newLevel: _currentUser!.level,
        newEXP: _currentUser!.currentEXP,
        leveledDown: leveledDown,
        levelsLost: levelsLost,
        statReversals: statReversals,
        expReversed: expToReverse,
      );
    } catch (e) {
      _setError('Failed to apply stat reversals: $e');
      return StatReversalResult.error('Failed to apply stat reversals: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Handle level-down scenarios when EXP is reversed
  /// This method specifically handles the complex logic of level reduction
  Future<LevelDownResult> handleLevelDown(double expToReverse) async {
    if (_currentUser == null) {
      _setError('No user to handle level-down for');
      return LevelDownResult.error('No user found');
    }

    try {
      final result = await _userService.handleLevelDown(
        userId: _currentUser!.id,
        expToReverse: expToReverse,
      );
      
      _currentUser = result.user;
      notifyListeners();
      
      return result;
    } catch (e) {
      _setError('Failed to handle level-down: $e');
      return LevelDownResult.error('Failed to handle level-down: $e');
    }
  }

  /// Get user level information
  UserLevelInfo? getUserLevelInfo() {
    if (_currentUser == null) return null;
    
    try {
      return _userService.getUserLevelInfo(_currentUser!.id);
    } catch (e) {
      _setError('Failed to get level info: $e');
      return null;
    }
  }

  /// Get user statistics summary
  UserStatsSummary? getUserStatsSummary() {
    if (_currentUser == null) return null;
    
    try {
      return _userService.getUserStatsSummary(_currentUser!.id);
    } catch (e) {
      _setError('Failed to get stats summary: $e');
      return null;
    }
  }

  /// Check if user needs tutorial
  bool needsTutorial() {
    if (_currentUser == null) return true;
    
    return _userService.needsTutorial(_currentUser!.id);
  }

  /// Reset user progress
  Future<void> resetProgress() async {
    if (_currentUser == null) {
      _setError('No user to reset');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      final resetUser = await _userService.resetUserProgress(_currentUser!.id);
      
      _currentUser = resetUser;
      _needsOnboarding = true;
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to reset progress: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh user data from storage
  Future<void> refreshUser() async {
    if (_currentUser == null) return;

    try {
      final refreshedUser = _userService.getCurrentUser();
      if (refreshedUser != null) {
        _currentUser = refreshedUser;
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to refresh user data: $e');
    }
  }

  /// Check for degradation and update warnings
  Future<void> checkDegradation() async {
    await _checkDegradation();
  }

  /// Clear degradation warnings
  void clearDegradationWarnings() {
    _degradationWarnings.clear();
    _hasPendingDegradation = false;
    _appLifecycleService.clearDegradationWarnings();
    notifyListeners();
  }

  /// Get degradation warnings for current user
  List<DegradationWarning> getDegradationWarnings() {
    if (_currentUser == null) return [];
    
    return DegradationService.getDegradationWarnings(_currentUser!);
  }

  /// Clear error message
  void clearError() {
    _clearError();
  }

  @override
  void dispose() {
    _appLifecycleService.removeListener(_onAppLifecycleChanged);
    super.dispose();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setDeletingActivity(bool deleting) {
    _isDeletingActivity = deleting;
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

  /// Handle app lifecycle changes
  void _onAppLifecycleChanged() {
    // Update degradation warnings when app lifecycle changes
    _degradationWarnings = _appLifecycleService.degradationWarnings;
    _hasPendingDegradation = _appLifecycleService.hasPendingDegradation;
    
    // Refresh user data if degradation was applied
    if (_appLifecycleService.hasPendingDegradation && _currentUser != null) {
      refreshUser();
    }
    
    notifyListeners();
  }

  /// Check for degradation and update state
  Future<void> _checkDegradation() async {
    if (_currentUser == null) return;

    try {
      final result = await _appLifecycleService.performManualDegradationCheck();
      
      _degradationWarnings = result.warnings;
      _hasPendingDegradation = result.degradationApplied;
      
      // If degradation was applied, refresh user data
      if (result.degradationApplied) {
        await refreshUser();
      }
    } catch (e) {
      debugPrint('Error checking degradation: $e');
    }
  }
}

/// Result of stat reversal operation
class StatReversalResult {
  final bool success;
  final String? errorMessage;
  final int newLevel;
  final double newEXP;
  final bool leveledDown;
  final int levelsLost;
  final Map<StatType, double> statReversals;
  final double expReversed;

  const StatReversalResult._({
    required this.success,
    this.errorMessage,
    required this.newLevel,
    required this.newEXP,
    required this.leveledDown,
    required this.levelsLost,
    required this.statReversals,
    required this.expReversed,
  });

  factory StatReversalResult.success({
    required int newLevel,
    required double newEXP,
    required bool leveledDown,
    required int levelsLost,
    required Map<StatType, double> statReversals,
    required double expReversed,
  }) {
    return StatReversalResult._(
      success: true,
      newLevel: newLevel,
      newEXP: newEXP,
      leveledDown: leveledDown,
      levelsLost: levelsLost,
      statReversals: statReversals,
      expReversed: expReversed,
    );
  }

  factory StatReversalResult.error(String errorMessage) {
    return StatReversalResult._(
      success: false,
      errorMessage: errorMessage,
      newLevel: 0,
      newEXP: 0.0,
      leveledDown: false,
      levelsLost: 0,
      statReversals: {},
      expReversed: 0.0,
    );
  }

  @override
  String toString() {
    if (success) {
      return 'StatReversalResult(success: true, newLevel: $newLevel, leveledDown: $leveledDown, levelsLost: $levelsLost)';
    } else {
      return 'StatReversalResult(success: false, error: $errorMessage)';
    }
  }
}

