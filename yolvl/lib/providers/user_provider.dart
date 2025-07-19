import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/enums.dart';
import '../models/onboarding.dart';

import '../services/user_service.dart';
import '../services/app_lifecycle_service.dart';
import '../services/degradation_service.dart';
import '../repositories/user_repository.dart';

/// Provider for managing user state, level, EXP, and stats
class UserProvider extends ChangeNotifier {
  final UserService _userService;
  final AppLifecycleService _appLifecycleService;
  
  User? _currentUser;
  bool _isLoading = false;
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