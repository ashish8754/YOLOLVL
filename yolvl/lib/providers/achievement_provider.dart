import 'package:flutter/foundation.dart';
import '../models/achievement.dart';
import '../models/enums.dart';
import '../models/user.dart';
import '../models/activity_log.dart';
import '../services/achievement_service.dart';
import '../repositories/achievement_repository.dart';
import '../repositories/activity_repository.dart';

/// Provider for managing achievement state and progress
class AchievementProvider extends ChangeNotifier {
  final AchievementService _achievementService;
  
  List<Achievement> _unlockedAchievements = [];
  List<Achievement> _recentAchievements = [];
  List<AchievementProgress> _achievementProgress = [];
  AchievementStats? _achievementStats;
  
  bool _isLoading = false;
  String? _errorMessage;
  
  // Notification callbacks
  Function(Achievement achievement)? _onAchievementUnlocked;

  AchievementProvider({
    AchievementService? achievementService,
  }) : _achievementService = achievementService ?? AchievementService(
          achievementRepository: AchievementRepository(),
          activityRepository: ActivityRepository(),
        );

  // Getters
  List<Achievement> get unlockedAchievements => List.unmodifiable(_unlockedAchievements);
  List<Achievement> get recentAchievements => List.unmodifiable(_recentAchievements);
  List<AchievementProgress> get achievementProgress => List.unmodifiable(_achievementProgress);
  AchievementStats? get achievementStats => _achievementStats;
  
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  int get unlockedCount => _unlockedAchievements.length;
  int get totalCount => AchievementType.values.length;
  double get completionRate => totalCount > 0 ? (unlockedCount / totalCount) * 100 : 0.0;

  /// Load all achievement data
  Future<void> loadAchievements() async {
    _setLoading(true);
    _clearError();

    try {
      await Future.wait([
        _loadUnlockedAchievements(),
        _loadRecentAchievements(),
        _loadAchievementStats(),
      ]);
    } catch (e) {
      _setError('Failed to load achievements: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load achievement progress for a specific user
  Future<void> loadAchievementProgress(User user) async {
    try {
      _achievementProgress = await _achievementService.getAchievementProgress(user);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load achievement progress: $e');
    }
  }

  /// Check and unlock achievements for user
  Future<List<AchievementUnlockResult>> checkAndUnlockAchievements({
    required User user,
    ActivityLog? newActivity,
  }) async {
    try {
      final results = await _achievementService.checkAndUnlockAchievements(
        user: user,
        newActivity: newActivity,
      );

      // If any achievements were unlocked, refresh data
      if (results.isNotEmpty) {
        await Future.wait([
          _loadUnlockedAchievements(),
          _loadRecentAchievements(),
          _loadAchievementStats(),
        ]);
        
        // Trigger callbacks for newly unlocked achievements
        for (final result in results) {
          if (result.isNewUnlock && _onAchievementUnlocked != null) {
            _onAchievementUnlocked!(result.achievement);
          }
        }
      }

      return results;
    } catch (e) {
      _setError('Failed to check achievements: $e');
      return [];
    }
  }

  /// Get achievement by type
  Achievement? getAchievementByType(AchievementType type) {
    try {
      return _unlockedAchievements.firstWhere(
        (achievement) => achievement.achievementTypeEnum == type,
      );
    } catch (e) {
      return null; // Achievement not unlocked
    }
  }

  /// Check if achievement is unlocked
  bool isAchievementUnlocked(AchievementType type) {
    return getAchievementByType(type) != null;
  }

  /// Get achievement progress for specific type
  AchievementProgress? getProgressForType(AchievementType type) {
    try {
      return _achievementProgress.firstWhere(
        (progress) => progress.type == type,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get achievements by rarity level
  List<Achievement> getAchievementsByRarity(int rarity) {
    return _unlockedAchievements.where(
      (achievement) => achievement.achievementTypeEnum.rarity == rarity,
    ).toList();
  }

  /// Get next achievement to unlock (closest to completion)
  AchievementProgress? getNextAchievementToUnlock() {
    final lockedProgress = _achievementProgress.where((p) => !p.isUnlocked).toList();
    if (lockedProgress.isEmpty) return null;

    lockedProgress.sort((a, b) => b.progress.compareTo(a.progress));
    return lockedProgress.first;
  }

  /// Get achievements unlocked today
  List<Achievement> getTodaysAchievements() {
    final today = DateTime.now();
    return _unlockedAchievements.where((achievement) {
      return achievement.unlockedAt.year == today.year &&
             achievement.unlockedAt.month == today.month &&
             achievement.unlockedAt.day == today.day;
    }).toList();
  }

  /// Get achievements unlocked this week
  List<Achievement> getThisWeeksAchievements() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    
    return _unlockedAchievements.where((achievement) {
      return achievement.unlockedAt.isAfter(startOfWeek);
    }).toList();
  }

  /// Reset all achievements (for user reset functionality)
  Future<void> resetAllAchievements() async {
    _setLoading(true);
    _clearError();

    try {
      await _achievementService.resetAllAchievements();
      
      // Clear local state
      _unlockedAchievements.clear();
      _recentAchievements.clear();
      _achievementProgress.clear();
      _achievementStats = null;
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to reset achievements: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Export achievements for backup
  List<Map<String, dynamic>> exportAchievements() {
    try {
      return _achievementService.exportAchievements();
    } catch (e) {
      _setError('Failed to export achievements: $e');
      return [];
    }
  }

  /// Import achievements from backup
  Future<void> importAchievements(List<Map<String, dynamic>> achievementsJson) async {
    _setLoading(true);
    _clearError();

    try {
      await _achievementService.importAchievements(achievementsJson);
      await loadAchievements(); // Refresh data after import
    } catch (e) {
      _setError('Failed to import achievements: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Set callback for achievement unlock notifications
  void setAchievementUnlockedCallback(Function(Achievement achievement)? callback) {
    _onAchievementUnlocked = callback;
  }

  /// Refresh all achievement data
  Future<void> refreshAchievements() async {
    await loadAchievements();
  }

  /// Clear error message
  void clearError() {
    _clearError();
  }

  // Private helper methods
  Future<void> _loadUnlockedAchievements() async {
    _unlockedAchievements = _achievementService.getUnlockedAchievements();
  }

  Future<void> _loadRecentAchievements() async {
    _recentAchievements = _achievementService.getRecentAchievements();
  }

  Future<void> _loadAchievementStats() async {
    _achievementStats = _achievementService.getAchievementStats();
  }

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
}