import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../lib/services/activity_service.dart';
import '../../lib/repositories/activity_repository.dart';
import '../../lib/repositories/user_repository.dart';
import '../../lib/models/user.dart';
import '../../lib/models/activity_log.dart';
import '../../lib/models/enums.dart';
import '../../lib/utils/hive_config.dart';

void main() {
  group('Activity Deletion with Stat Reversal Integration Tests', () {
    late ActivityService activityService;
    late UserRepository userRepository;
    late ActivityRepository activityRepository;
    late User testUser;

    setUpAll(() async {
      // Initialize Hive for testing
      await HiveConfig.initialize();
    });

    setUp(() async {
      // Clear existing data
      await HiveConfig.clearAllData();
      
      // Create repositories and service
      userRepository = UserRepository();
      activityRepository = ActivityRepository();
      activityService = ActivityService(
        userRepository: userRepository,
        activityRepository: activityRepository,
      );

      // Create test user
      testUser = await userRepository.createUser(
        id: 'test_user',
        name: 'Test User',
      );

      // Set initial stats for testing
      testUser.stats = {
        StatType.strength.name: 2.5,
        StatType.agility.name: 1.8,
        StatType.endurance.name: 3.2,
        StatType.intelligence.name: 2.1,
        StatType.focus.name: 2.8,
        StatType.charisma.name: 1.9,
      };
      testUser.level = 3;
      testUser.currentEXP = 500.0;
      await userRepository.updateUser(testUser);
    });

    tearDown(() async {
      // Clean up
      await HiveConfig.clearAllData();
    });

    test('deleteActivityWithStatReversal should successfully delete activity and reverse stats', () async {
      // Arrange - create an activity log with known stat gains
      final activityLog = ActivityLog.create(
        id: 'test_activity',
        activityType: ActivityType.workoutWeights,
        durationMinutes: 120, // 2 hours
        statGains: {
          StatType.strength: 0.12, // 0.06 * 2 hours
          StatType.endurance: 0.08, // 0.04 * 2 hours
        },
        expGained: 120.0, // 2 hours * 60 minutes
      );

      await activityRepository.logActivity(activityLog);

      // Act
      final result = await activityService.deleteActivityWithStatReversal('test_activity');

      // Assert
      expect(result.success, isTrue);
      expect(result.deletedActivity?.id, equals('test_activity'));
      expect(result.statReversals[StatType.strength], equals(0.12));
      expect(result.statReversals[StatType.endurance], equals(0.08));
      expect(result.expReversed, equals(120.0));
      expect(result.leveledDown, isFalse);

      // Verify user stats were updated
      final updatedUser = userRepository.getCurrentUser()!;
      expect(updatedUser.getStat(StatType.strength), equals(2.38)); // 2.5 - 0.12
      expect(updatedUser.getStat(StatType.endurance), equals(3.12)); // 3.2 - 0.08
      expect(updatedUser.getStat(StatType.agility), equals(1.8)); // Unchanged
      expect(updatedUser.currentEXP, equals(380.0)); // 500 - 120
      expect(updatedUser.level, equals(3)); // No level change

      // Verify activity was deleted
      final deletedActivity = activityRepository.findByKey('test_activity');
      expect(deletedActivity, isNull);
    });

    test('deleteActivityWithStatReversal should handle level-down scenario', () async {
      // Arrange - set user to low EXP that will cause level-down
      testUser.level = 3;
      testUser.currentEXP = 50.0;
      await userRepository.updateUser(testUser);

      final activityLog = ActivityLog.create(
        id: 'test_activity_leveldown',
        activityType: ActivityType.studySerious,
        durationMinutes: 180, // 3 hours
        statGains: {
          StatType.intelligence: 0.18, // 0.06 * 3 hours
          StatType.focus: 0.12, // 0.04 * 3 hours
        },
        expGained: 180.0, // 3 hours * 60 minutes
      );

      await activityRepository.logActivity(activityLog);

      // Act
      final result = await activityService.deleteActivityWithStatReversal('test_activity_leveldown');

      // Assert
      expect(result.success, isTrue);
      expect(result.leveledDown, isTrue);
      expect(result.newLevel, equals(2)); // Should level down from 3 to 2

      // Verify user was leveled down
      final updatedUser = userRepository.getCurrentUser()!;
      expect(updatedUser.level, equals(2));
      expect(updatedUser.currentEXP, equals(1070.0)); // 50 - 180 + 1200 (level 2 threshold)

      // Verify stats were reversed
      expect(updatedUser.getStat(StatType.intelligence), equals(1.92)); // 2.1 - 0.18
      expect(updatedUser.getStat(StatType.focus), equals(2.68)); // 2.8 - 0.12
    });

    test('deleteActivityWithStatReversal should enforce stat floor constraints', () async {
      // Arrange - set user stats close to minimum
      testUser.stats = {
        StatType.strength.name: 1.05,
        StatType.agility.name: 1.0,
        StatType.endurance.name: 1.02,
        StatType.intelligence.name: 1.5,
        StatType.focus.name: 2.0,
        StatType.charisma.name: 1.1,
      };
      await userRepository.updateUser(testUser);

      final activityLog = ActivityLog.create(
        id: 'test_activity_floor',
        activityType: ActivityType.workoutWeights,
        durationMinutes: 120,
        statGains: {
          StatType.strength: 0.1, // Would result in 0.95, should be clamped to 1.0
          StatType.endurance: 0.05, // Would result in 0.97, should be clamped to 1.0
        },
        expGained: 120.0,
      );

      await activityRepository.logActivity(activityLog);

      // Act
      final result = await activityService.deleteActivityWithStatReversal('test_activity_floor');

      // Assert
      expect(result.success, isTrue);

      // Verify stats were clamped to floor
      final updatedUser = userRepository.getCurrentUser()!;
      expect(updatedUser.getStat(StatType.strength), equals(1.0)); // Clamped to floor
      expect(updatedUser.getStat(StatType.endurance), equals(1.0)); // Clamped to floor
      expect(updatedUser.getStat(StatType.agility), equals(1.0)); // Unchanged
    });

    test('deleteActivityWithStatReversal should handle quit bad habit activity', () async {
      // Arrange - quit bad habit has fixed EXP and focus gain
      final activityLog = ActivityLog.create(
        id: 'test_quit_habit',
        activityType: ActivityType.quitBadHabit,
        durationMinutes: 1, // Duration doesn't matter for quit bad habit
        statGains: {
          StatType.focus: 0.03, // Fixed gain
        },
        expGained: 60.0, // Fixed EXP
      );

      await activityRepository.logActivity(activityLog);

      // Act
      final result = await activityService.deleteActivityWithStatReversal('test_quit_habit');

      // Assert
      expect(result.success, isTrue);
      expect(result.statReversals[StatType.focus], equals(0.03));
      expect(result.expReversed, equals(60.0));

      // Verify user stats
      final updatedUser = userRepository.getCurrentUser()!;
      expect(updatedUser.getStat(StatType.focus), equals(2.77)); // 2.8 - 0.03
      expect(updatedUser.currentEXP, equals(440.0)); // 500 - 60
    });

    test('deleteActivityWithStatReversal should handle legacy activity without stored gains', () async {
      // Arrange - create activity log without stored stat gains (simulating legacy data)
      final activityLog = ActivityLog(
        id: 'legacy_activity',
        activityType: ActivityType.meditation.name,
        durationMinutes: 60,
        timestamp: DateTime.now(),
        statGains: {}, // Empty - simulating legacy activity
        expGained: 60.0,
      );

      await activityRepository.logActivity(activityLog);

      // Act
      final result = await activityService.deleteActivityWithStatReversal('legacy_activity');

      // Assert
      expect(result.success, isTrue);
      // Should use fallback calculation: 1 hour of meditation = 0.05 focus
      expect(result.statReversals[StatType.focus], equals(0.05));

      // Verify user stats
      final updatedUser = userRepository.getCurrentUser()!;
      expect(updatedUser.getStat(StatType.focus), equals(2.75)); // 2.8 - 0.05
    });

    test('deleteActivityWithStatReversal should return error for non-existent activity', () async {
      // Act
      final result = await activityService.deleteActivityWithStatReversal('non_existent');

      // Assert
      expect(result.success, isFalse);
      expect(result.errorMessage, contains('Activity not found'));
    });

    test('previewActivityDeletion should provide accurate preview', () async {
      // Arrange
      final activityLog = ActivityLog.create(
        id: 'preview_test',
        activityType: ActivityType.workoutCardio,
        durationMinutes: 90,
        statGains: {
          StatType.agility: 0.09, // 0.06 * 1.5 hours
          StatType.endurance: 0.06, // 0.04 * 1.5 hours
        },
        expGained: 90.0,
      );

      await activityRepository.logActivity(activityLog);

      // Act
      final preview = await activityService.previewActivityDeletion('preview_test');

      // Assert
      expect(preview.isValid, isTrue);
      expect(preview.activity?.id, equals('preview_test'));
      expect(preview.statReversals[StatType.agility], equals(0.09));
      expect(preview.statReversals[StatType.endurance], equals(0.06));
      expect(preview.expToReverse, equals(90.0));
      expect(preview.willLevelDown, isFalse);
      expect(preview.newLevel, equals(3));
      expect(preview.levelsLost, equals(0));
    });

    test('previewActivityDeletion should predict level-down', () async {
      // Arrange - set user to low EXP
      testUser.level = 3;
      testUser.currentEXP = 30.0;
      await userRepository.updateUser(testUser);

      final activityLog = ActivityLog.create(
        id: 'preview_leveldown',
        activityType: ActivityType.socializing,
        durationMinutes: 120,
        statGains: {
          StatType.charisma: 0.1,
          StatType.focus: 0.04,
        },
        expGained: 120.0,
      );

      await activityRepository.logActivity(activityLog);

      // Act
      final preview = await activityService.previewActivityDeletion('preview_leveldown');

      // Assert
      expect(preview.isValid, isTrue);
      expect(preview.willLevelDown, isTrue);
      expect(preview.newLevel, equals(2));
      expect(preview.levelsLost, equals(1));
    });

    test('integration with UserProvider should trigger UI updates', () async {
      // This test verifies that the deletion method properly updates the user
      // which should trigger UI updates through the provider pattern

      // Arrange
      final activityLog = ActivityLog.create(
        id: 'ui_update_test',
        activityType: ActivityType.workoutYoga,
        durationMinutes: 60,
        statGains: {
          StatType.agility: 0.05,
          StatType.focus: 0.03,
        },
        expGained: 60.0,
      );

      await activityRepository.logActivity(activityLog);

      // Get initial user state
      final initialUser = userRepository.getCurrentUser()!;
      final initialAgility = initialUser.getStat(StatType.agility);
      final initialFocus = initialUser.getStat(StatType.focus);
      final initialEXP = initialUser.currentEXP;

      // Act
      final result = await activityService.deleteActivityWithStatReversal('ui_update_test');

      // Assert
      expect(result.success, isTrue);

      // Verify user was updated in repository (which should trigger provider updates)
      final updatedUser = userRepository.getCurrentUser()!;
      expect(updatedUser.getStat(StatType.agility), equals(initialAgility - 0.05));
      expect(updatedUser.getStat(StatType.focus), equals(initialFocus - 0.03));
      expect(updatedUser.currentEXP, equals(initialEXP - 60.0));

      // Verify lastActive was updated (indicates user was properly saved)
      expect(updatedUser.lastActive.isAfter(initialUser.lastActive), isTrue);
    });
  });
}