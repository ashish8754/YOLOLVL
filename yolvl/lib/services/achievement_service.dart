import '../models/achievement.dart';
import '../models/enums.dart';
import '../models/user.dart';
import '../models/activity_log.dart';
import '../repositories/achievement_repository.dart';
import '../repositories/activity_repository.dart';

/// Service for managing achievements and milestone tracking
class AchievementService {
  final AchievementRepository _achievementRepository;
  final ActivityRepository _activityRepository;

  AchievementService({
    AchievementRepository? achievementRepository,
    ActivityRepository? activityRepository,
  }) : _achievementRepository = achievementRepository ?? AchievementRepository(),
       _activityRepository = activityRepository ?? ActivityRepository();

  /// Check and unlock achievements based on current user state
  Future<List<AchievementUnlockResult>> checkAndUnlockAchievements({
    required User user,
    ActivityLog? newActivity,
  }) async {
    final results = <AchievementUnlockResult>[];

    try {
      // Get all activity logs for comprehensive checking
      final allActivities = _activityRepository.findAll();
      
      // Check each achievement type
      for (final achievementType in AchievementType.values) {
        final result = await _checkSpecificAchievement(
          achievementType,
          user,
          allActivities,
          newActivity,
        );
        
        if (result != null) {
          results.add(result);
        }
      }

      return results;
    } catch (e) {
      throw Exception('Failed to check achievements: $e');
    }
  }

  /// Get achievement progress for all achievement types
  Future<List<AchievementProgress>> getAchievementProgress(User user) async {
    try {
      final allActivities = _activityRepository.findAll();
      final progressList = <AchievementProgress>[];

      for (final achievementType in AchievementType.values) {
        final isUnlocked = _achievementRepository.isAchievementUnlocked(achievementType);
        final currentValue = await _getCurrentValueForAchievement(
          achievementType,
          user,
          allActivities,
        );

        progressList.add(AchievementProgress(
          type: achievementType,
          currentValue: currentValue,
          targetValue: achievementType.targetValue,
          isUnlocked: isUnlocked,
        ));
      }

      return progressList;
    } catch (e) {
      throw Exception('Failed to get achievement progress: $e');
    }
  }

  /// Get all unlocked achievements
  List<Achievement> getUnlockedAchievements() {
    try {
      return _achievementRepository.getUnlockedAchievements();
    } catch (e) {
      throw Exception('Failed to get unlocked achievements: $e');
    }
  }

  /// Get recent achievements
  List<Achievement> getRecentAchievements({int limit = 5}) {
    try {
      return _achievementRepository.getRecentAchievements(limit: limit);
    } catch (e) {
      throw Exception('Failed to get recent achievements: $e');
    }
  }

  /// Get achievement statistics
  AchievementStats getAchievementStats() {
    try {
      final unlockedCount = _achievementRepository.getTotalAchievementCount();
      final totalCount = AchievementType.values.length;
      final unlockRate = _achievementRepository.getAchievementUnlockRate();
      
      final achievementsByRarity = <int, int>{};
      for (int rarity = 1; rarity <= 5; rarity++) {
        final achievements = _achievementRepository.getAchievementsByRarity(rarity);
        achievementsByRarity[rarity] = achievements.length;
      }

      return AchievementStats(
        unlockedCount: unlockedCount,
        totalCount: totalCount,
        unlockRate: unlockRate,
        achievementsByRarity: achievementsByRarity,
      );
    } catch (e) {
      throw Exception('Failed to get achievement stats: $e');
    }
  }

  /// Reset all achievements (for user reset functionality)
  Future<void> resetAllAchievements() async {
    try {
      await _achievementRepository.deleteAllAchievements();
    } catch (e) {
      throw Exception('Failed to reset achievements: $e');
    }
  }

  /// Export achievements for backup
  List<Map<String, dynamic>> exportAchievements() {
    try {
      return _achievementRepository.exportAchievements();
    } catch (e) {
      throw Exception('Failed to export achievements: $e');
    }
  }

  /// Import achievements from backup
  Future<void> importAchievements(List<Map<String, dynamic>> achievementsJson) async {
    try {
      await _achievementRepository.importAchievements(achievementsJson);
    } catch (e) {
      throw Exception('Failed to import achievements: $e');
    }
  }

  // Private helper methods

  /// Check a specific achievement and unlock if conditions are met
  Future<AchievementUnlockResult?> _checkSpecificAchievement(
    AchievementType type,
    User user,
    List<ActivityLog> allActivities,
    ActivityLog? newActivity,
  ) async {
    // Skip if already unlocked
    final isUnlocked = _achievementRepository.isAchievementUnlocked(type);
    if (isUnlocked) return null;

    final currentValue = await _getCurrentValueForAchievement(type, user, allActivities);
    
    if (currentValue >= type.targetValue) {
      final achievement = await _achievementRepository.unlockAchievement(
        type: type,
        value: currentValue,
        metadata: _getAchievementMetadata(type, user, allActivities),
      );

      return AchievementUnlockResult(
        achievement: achievement,
        isNewUnlock: true,
        message: _getUnlockMessage(type, currentValue),
      );
    }

    return null;
  }

  /// Get current value for a specific achievement type
  Future<int> _getCurrentValueForAchievement(
    AchievementType type,
    User user,
    List<ActivityLog> allActivities,
  ) async {
    switch (type) {
      case AchievementType.firstActivity:
        return allActivities.isNotEmpty ? 1 : 0;
        
      case AchievementType.streak7Days:
      case AchievementType.streak30Days:
        return await _calculateCurrentStreak(allActivities);
        
      case AchievementType.level5Reached:
      case AchievementType.level10Reached:
      case AchievementType.level25Reached:
        return user.level;
        
      case AchievementType.totalActivities50:
      case AchievementType.totalActivities100:
      case AchievementType.totalActivities500:
        return allActivities.length;
        
      case AchievementType.workoutWarrior:
        return _countActivitiesByCategory(allActivities, ActivityCategory.workout);
        
      case AchievementType.studyScholar:
        return _countActivitiesByCategory(allActivities, ActivityCategory.study);
        
      case AchievementType.wellRounded:
        return _getMinActivityTypeCount(allActivities);
    }
  }

  /// Calculate current activity streak
  Future<int> _calculateCurrentStreak(List<ActivityLog> activities) async {
    if (activities.isEmpty) return 0;

    // Sort activities by date (newest first)
    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    int streak = 0;
    DateTime currentDate = DateTime.now();
    
    // Check if there's an activity today or yesterday (to account for late logging)
    final today = DateTime(currentDate.year, currentDate.month, currentDate.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    bool hasRecentActivity = activities.any((activity) {
      final activityDate = DateTime(
        activity.timestamp.year,
        activity.timestamp.month,
        activity.timestamp.day,
      );
      return activityDate.isAtSameMomentAs(today) || activityDate.isAtSameMomentAs(yesterday);
    });

    if (!hasRecentActivity) return 0;

    // Count consecutive days with activities
    final activityDates = activities.map((activity) => DateTime(
      activity.timestamp.year,
      activity.timestamp.month,
      activity.timestamp.day,
    )).toSet().toList();
    
    activityDates.sort((a, b) => b.compareTo(a));

    DateTime checkDate = today;
    for (final activityDate in activityDates) {
      if (activityDate.isAtSameMomentAs(checkDate) || 
          activityDate.isAtSameMomentAs(checkDate.subtract(const Duration(days: 1)))) {
        streak++;
        checkDate = activityDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  /// Count activities by category
  int _countActivitiesByCategory(List<ActivityLog> activities, ActivityCategory category) {
    return activities.where((activity) {
      return activity.activityTypeEnum.category == category;
    }).length;
  }

  /// Get minimum count across all activity types (for well-rounded achievement)
  int _getMinActivityTypeCount(List<ActivityLog> activities) {
    final typeCounts = <ActivityType, int>{};
    
    for (final activity in activities) {
      final type = activity.activityTypeEnum;
      typeCounts[type] = (typeCounts[type] ?? 0) + 1;
    }

    if (typeCounts.isEmpty) return 0;
    
    // Return the minimum count across all activity types
    return typeCounts.values.reduce((a, b) => a < b ? a : b);
  }

  /// Get achievement metadata for storage
  Map<String, dynamic>? _getAchievementMetadata(
    AchievementType type,
    User user,
    List<ActivityLog> allActivities,
  ) {
    switch (type) {
      case AchievementType.streak7Days:
      case AchievementType.streak30Days:
        return {
          'streakDays': _calculateCurrentStreak(allActivities),
          'totalActivities': allActivities.length,
        };
      case AchievementType.workoutWarrior:
        return {
          'workoutCount': _countActivitiesByCategory(allActivities, ActivityCategory.workout),
        };
      case AchievementType.studyScholar:
        return {
          'studyCount': _countActivitiesByCategory(allActivities, ActivityCategory.study),
        };
      default:
        return null;
    }
  }

  /// Get unlock message for achievement
  String _getUnlockMessage(AchievementType type, int value) {
    switch (type) {
      case AchievementType.firstActivity:
        return 'Congratulations on logging your first activity!';
      case AchievementType.streak7Days:
        return 'Amazing! You\'ve maintained a 7-day streak!';
      case AchievementType.streak30Days:
        return 'Incredible! 30 days of consistency!';
      case AchievementType.level5Reached:
        return 'You\'ve reached Level 5! Keep growing!';
      case AchievementType.level10Reached:
        return 'Level 10 achieved! You\'re getting stronger!';
      case AchievementType.level25Reached:
        return 'Level 25! You\'re becoming elite!';
      case AchievementType.totalActivities50:
        return '50 activities logged! You\'re building great habits!';
      case AchievementType.totalActivities100:
        return '100 activities! Your consistency is paying off!';
      case AchievementType.totalActivities500:
        return '500 activities! You\'re a true legend!';
      case AchievementType.workoutWarrior:
        return 'Workout Warrior unlocked! Your fitness journey is strong!';
      case AchievementType.studyScholar:
        return 'Study Scholar achieved! Knowledge is power!';
      case AchievementType.wellRounded:
        return 'Well Rounded! You\'re developing in all areas!';
    }
  }
}

/// Achievement statistics summary
class AchievementStats {
  final int unlockedCount;
  final int totalCount;
  final double unlockRate;
  final Map<int, int> achievementsByRarity;

  AchievementStats({
    required this.unlockedCount,
    required this.totalCount,
    required this.unlockRate,
    required this.achievementsByRarity,
  });

  /// Get completion percentage
  int get completionPercentage => ((unlockedCount / totalCount) * 100).round();
}