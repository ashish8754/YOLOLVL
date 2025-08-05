import '../models/achievement.dart';
import '../models/enums.dart';
import 'base_repository.dart';

/// Repository for managing achievement data persistence
class AchievementRepository extends BaseRepository<Achievement> {
  static const String _boxName = 'achievement_box';
  
  AchievementRepository() : super(_boxName);

  /// Get all unlocked achievements
  List<Achievement> getUnlockedAchievements() {
    try {
      return findAll();
    } catch (e) {
      throw Exception('Failed to get unlocked achievements: $e');
    }
  }

  /// Get achievement by type
  Achievement? getAchievementByType(AchievementType type) {
    try {
      final achievements = findAll();
      return achievements.firstWhere(
        (achievement) => achievement.achievementTypeEnum == type,
        orElse: () => throw StateError('Achievement not found'),
      );
    } catch (e) {
      if (e is StateError) {
        return null; // Achievement not unlocked yet
      }
      throw Exception('Failed to get achievement by type: $e');
    }
  }

  /// Check if achievement is unlocked
  bool isAchievementUnlocked(AchievementType type) {
    try {
      final achievement = getAchievementByType(type);
      return achievement != null;
    } catch (e) {
      throw Exception('Failed to check achievement unlock status: $e');
    }
  }

  /// Unlock achievement
  Future<Achievement> unlockAchievement({
    required AchievementType type,
    int? value,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Check if already unlocked
      final existing = getAchievementByType(type);
      if (existing != null) {
        return existing;
      }

      final achievement = Achievement.create(
        id: '${type.name}_${DateTime.now().millisecondsSinceEpoch}',
        achievementType: type,
        value: value,
        metadata: metadata,
      );

      // Add to box first, then save
      box.add(achievement);
      await achievement.save();
      
      return achievement;
    } catch (e) {
      throw Exception('Failed to unlock achievement: $e');
    }
  }

  /// Get achievements by rarity level
  List<Achievement> getAchievementsByRarity(int rarity) {
    try {
      final achievements = getUnlockedAchievements();
      return achievements.where(
        (achievement) => achievement.achievementTypeEnum.rarity == rarity,
      ).toList();
    } catch (e) {
      throw Exception('Failed to get achievements by rarity: $e');
    }
  }

  /// Get total achievement count
  int getTotalAchievementCount() {
    try {
      return count();
    } catch (e) {
      throw Exception('Failed to get total achievement count: $e');
    }
  }

  /// Get achievement unlock rate (percentage)
  double getAchievementUnlockRate() {
    try {
      final unlockedCount = getTotalAchievementCount();
      final totalCount = AchievementType.values.length;
      return (unlockedCount / totalCount) * 100;
    } catch (e) {
      throw Exception('Failed to get achievement unlock rate: $e');
    }
  }

  /// Delete all achievements (for reset functionality)
  Future<void> deleteAllAchievements() async {
    try {
      await deleteAll();
    } catch (e) {
      throw Exception('Failed to delete all achievements: $e');
    }
  }

  /// Export achievements to JSON
  List<Map<String, dynamic>> exportAchievements() {
    try {
      final achievements = getUnlockedAchievements();
      return achievements.map((achievement) => achievement.toJson()).toList();
    } catch (e) {
      throw Exception('Failed to export achievements: $e');
    }
  }

  /// Import achievements from JSON
  Future<void> importAchievements(List<Map<String, dynamic>> achievementsJson) async {
    try {
      for (final achievementJson in achievementsJson) {
        final achievement = Achievement.fromJson(achievementJson);
        await save(achievement);
      }
    } catch (e) {
      throw Exception('Failed to import achievements: $e');
    }
  }

  /// Get recent achievements (last 10)
  List<Achievement> getRecentAchievements({int limit = 10}) {
    try {
      final achievements = getUnlockedAchievements();
      achievements.sort((a, b) => b.unlockedAt.compareTo(a.unlockedAt));
      return achievements.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to get recent achievements: $e');
    }
  }
}