import 'package:flutter_test/flutter_test.dart';
import 'package:yolvl/models/achievement.dart';
import 'package:yolvl/models/enums.dart';
import 'package:yolvl/models/user.dart';
import 'package:yolvl/models/activity_log.dart';
import 'package:yolvl/services/achievement_service.dart';
import 'package:yolvl/repositories/achievement_repository.dart';
import 'package:yolvl/repositories/activity_repository.dart';

class MockAchievementRepository extends AchievementRepository {
  final List<Achievement> _achievements = [];

  @override
  List<Achievement> getUnlockedAchievements() => _achievements;

  @override
  Achievement? getAchievementByType(AchievementType type) {
    try {
      return _achievements.firstWhere(
        (achievement) => achievement.achievementTypeEnum == type,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  bool isAchievementUnlocked(AchievementType type) {
    return getAchievementByType(type) != null;
  }

  @override
  Future<Achievement> unlockAchievement({
    required AchievementType type,
    int? value,
    Map<String, dynamic>? metadata,
  }) async {
    final existing = getAchievementByType(type);
    if (existing != null) return existing;

    final achievement = Achievement.create(
      id: '${type.name}_${DateTime.now().millisecondsSinceEpoch}',
      achievementType: type,
      value: value,
      metadata: metadata,
    );

    _achievements.add(achievement);
    return achievement;
  }

  @override
  int getTotalAchievementCount() => _achievements.length;

  @override
  double getAchievementUnlockRate() {
    final totalCount = AchievementType.values.length;
    return (_achievements.length / totalCount) * 100;
  }
}

class MockActivityRepository extends ActivityRepository {
  final List<ActivityLog> _activities = [];

  @override
  List<ActivityLog> findAll() => _activities;

  void addActivity(ActivityLog activity) {
    _activities.add(activity);
  }

  void clear() {
    _activities.clear();
  }
}

void main() {
  group('AchievementService', () {
    late AchievementService achievementService;
    late MockAchievementRepository mockAchievementRepo;
    late MockActivityRepository mockActivityRepo;
    late User testUser;

    setUp(() {
      mockAchievementRepo = MockAchievementRepository();
      mockActivityRepo = MockActivityRepository();
      achievementService = AchievementService(
        achievementRepository: mockAchievementRepo,
        activityRepository: mockActivityRepo,
      );
      
      testUser = User.create(id: 'test_user', name: 'Test User');
    });

    test('should unlock first activity achievement', () async {
      // Add first activity
      final activity = ActivityLog.create(
        id: 'test_activity',
        activityType: ActivityType.workoutWeights,
        durationMinutes: 60,
        statGains: {StatType.strength: 0.06, StatType.endurance: 0.04},
        expGained: 60,
      );
      mockActivityRepo.addActivity(activity);

      // Check achievements
      final results = await achievementService.checkAndUnlockAchievements(
        user: testUser,
        newActivity: activity,
      );

      expect(results.length, 1);
      expect(results.first.achievement.achievementTypeEnum, AchievementType.firstActivity);
      expect(results.first.isNewUnlock, true);
    });

    test('should unlock level achievement when user reaches level 5', () async {
      // Set user to level 5
      testUser = testUser.copyWith(level: 5);

      // Check achievements
      final results = await achievementService.checkAndUnlockAchievements(
        user: testUser,
      );

      expect(results.any((r) => r.achievement.achievementTypeEnum == AchievementType.level5Reached), true);
    });

    test('should unlock total activities achievement', () async {
      // Add 50 activities
      for (int i = 0; i < 50; i++) {
        final activity = ActivityLog.create(
          id: 'activity_$i',
          activityType: ActivityType.workoutWeights,
          durationMinutes: 60,
          statGains: {StatType.strength: 0.06},
          expGained: 60,
          timestamp: DateTime.now().subtract(Duration(days: i)),
        );
        mockActivityRepo.addActivity(activity);
      }

      // Check achievements
      final results = await achievementService.checkAndUnlockAchievements(
        user: testUser,
      );

      expect(results.any((r) => r.achievement.achievementTypeEnum == AchievementType.totalActivities50), true);
    });

    test('should get achievement progress correctly', () async {
      // Add some activities
      for (int i = 0; i < 25; i++) {
        final activity = ActivityLog.create(
          id: 'activity_$i',
          activityType: ActivityType.workoutWeights,
          durationMinutes: 60,
          statGains: {StatType.strength: 0.06},
          expGained: 60,
        );
        mockActivityRepo.addActivity(activity);
      }

      final progress = await achievementService.getAchievementProgress(testUser);

      // Find total activities progress
      final totalActivitiesProgress = progress.firstWhere(
        (p) => p.type == AchievementType.totalActivities50,
      );

      expect(totalActivitiesProgress.currentValue, 25);
      expect(totalActivitiesProgress.targetValue, 50);
      expect(totalActivitiesProgress.progress, 0.5);
      expect(totalActivitiesProgress.progressPercentage, 50);
    });

    test('should not unlock same achievement twice', () async {
      // Add first activity
      final activity = ActivityLog.create(
        id: 'test_activity',
        activityType: ActivityType.workoutWeights,
        durationMinutes: 60,
        statGains: {StatType.strength: 0.06},
        expGained: 60,
      );
      mockActivityRepo.addActivity(activity);

      // Check achievements first time
      final results1 = await achievementService.checkAndUnlockAchievements(
        user: testUser,
        newActivity: activity,
      );

      expect(results1.length, 1);

      // Check achievements second time
      final results2 = await achievementService.checkAndUnlockAchievements(
        user: testUser,
        newActivity: activity,
      );

      expect(results2.length, 0); // Should not unlock again
    });

    test('should get achievement stats correctly', () {
      // Unlock a few achievements manually
      mockAchievementRepo.unlockAchievement(type: AchievementType.firstActivity);
      mockAchievementRepo.unlockAchievement(type: AchievementType.level5Reached);

      final stats = achievementService.getAchievementStats();

      expect(stats.unlockedCount, 2);
      expect(stats.totalCount, AchievementType.values.length);
      expect(stats.completionPercentage, (2 / AchievementType.values.length * 100).round());
    });
  });
}