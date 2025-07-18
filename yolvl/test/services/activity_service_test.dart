import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import '../../lib/models/enums.dart';
import '../../lib/models/user.dart';
import '../../lib/models/activity_log.dart';
import '../../lib/services/activity_service.dart';
import '../../lib/repositories/activity_repository.dart';
import '../../lib/repositories/user_repository.dart';

void main() {
  group('ActivityService Tests', () {
    late ActivityService activityService;
    late UserRepository userRepository;
    late ActivityRepository activityRepository;

    setUp(() async {
      await setUpTestHive();
      
      // Register adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(ActivityTypeAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(StatTypeAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(UserAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(ActivityLogAdapter());
      }

      // Open test boxes
      await Hive.openBox<User>('user_box');
      await Hive.openBox<ActivityLog>('activity_box');
      
      userRepository = UserRepository();
      activityRepository = ActivityRepository();
      activityService = ActivityService(
        activityRepository: activityRepository,
        userRepository: userRepository,
      );
    });

    tearDown(() async {
      await tearDownTestHive();
    });

    group('Input Validation', () {
      test('should validate input correctly', () async {
        // Test negative duration
        var result = await activityService.logActivity(
          activityType: ActivityType.workoutWeights,
          durationMinutes: -10,
        );
        expect(result.success, isFalse);
        expect(result.errorMessage, contains('Duration must be greater than 0'));

        // Test zero duration
        result = await activityService.logActivity(
          activityType: ActivityType.workoutWeights,
          durationMinutes: 0,
        );
        expect(result.success, isFalse);
        expect(result.errorMessage, contains('Duration must be greater than 0'));

        // Test excessive duration
        result = await activityService.logActivity(
          activityType: ActivityType.workoutWeights,
          durationMinutes: 1500, // More than 24 hours
        );
        expect(result.success, isFalse);
        expect(result.errorMessage, contains('Duration cannot exceed 24 hours'));
      });
    });

    group('Expected Gains Preview', () {
      test('should calculate expected gains correctly', () {
        // Act
        final preview = activityService.calculateExpectedGains(
          activityType: ActivityType.workoutWeights,
          durationMinutes: 90,
        );

        // Assert
        expect(preview.isValid, isTrue);
        expect(preview.activityType, equals(ActivityType.workoutWeights));
        expect(preview.durationMinutes, equals(90));
        expect(preview.expGained, equals(90.0)); // 1 EXP per minute
        expect(preview.statGains[StatType.strength], equals(0.09)); // 0.06/hour * 1.5 hours
        expect(preview.statGains[StatType.endurance], equals(0.06)); // 0.04/hour * 1.5 hours
      });

      test('should handle quit bad habit preview correctly', () {
        // Act
        final preview = activityService.calculateExpectedGains(
          activityType: ActivityType.quitBadHabit,
          durationMinutes: 30,
        );

        // Assert
        expect(preview.isValid, isTrue);
        expect(preview.expGained, equals(60.0)); // Fixed 60 EXP
        expect(preview.statGains[StatType.focus], equals(0.03)); // Fixed 0.03 focus
      });

      test('should validate preview input', () {
        // Act
        final preview = activityService.calculateExpectedGains(
          activityType: ActivityType.workoutWeights,
          durationMinutes: -10,
        );

        // Assert
        expect(preview.isValid, isFalse);
        expect(preview.errorMessage, contains('Duration must be greater than 0'));
      });

      test('should format gain text correctly', () {
        // Act
        final preview = activityService.calculateExpectedGains(
          activityType: ActivityType.workoutWeights,
          durationMinutes: 60,
        );

        // Assert
        expect(preview.getStatGainText(StatType.strength), equals('+0.06'));
        expect(preview.getStatGainText(StatType.endurance), equals('+0.04'));
        expect(preview.getStatGainText(StatType.intelligence), equals('')); // Not affected
        expect(preview.expGainText, equals('+60 EXP'));
      });

      test('should identify affected stats correctly', () {
        // Act
        final preview = activityService.calculateExpectedGains(
          activityType: ActivityType.workoutWeights,
          durationMinutes: 60,
        );

        // Assert
        final affectedStats = preview.affectedStats;
        expect(affectedStats.length, equals(2));
        expect(affectedStats.contains(StatType.strength), isTrue);
        expect(affectedStats.contains(StatType.endurance), isTrue);
        expect(affectedStats.contains(StatType.intelligence), isFalse);
      });
    });

    group('Activity Logging Integration', () {
      test('should log activity successfully with user', () async {
        // Create a user first
        final user = await userRepository.createUser(
          id: 'test_user',
          name: 'Test User',
        );
        await userRepository.completeOnboarding(user.id, {
          StatType.strength: 1.0,
          StatType.agility: 1.0,
          StatType.endurance: 1.0,
          StatType.intelligence: 1.0,
          StatType.focus: 1.0,
          StatType.charisma: 1.0,
        });

        // Log an activity
        final result = await activityService.logActivity(
          activityType: ActivityType.workoutWeights,
          durationMinutes: 60,
        );

        expect(result.success, isTrue);
        expect(result.expGained, equals(60.0));
        expect(result.leveledUp, isFalse);
        expect(result.activityLog, isNotNull);
        expect(result.activityLog!.activityType, equals(ActivityType.workoutWeights.name));
        expect(result.activityLog!.durationMinutes, equals(60));
      });

      test('should fail to log activity without user', () async {
        // Try to log activity without creating a user first
        final result = await activityService.logActivity(
          activityType: ActivityType.workoutWeights,
          durationMinutes: 60,
        );

        expect(result.success, isFalse);
        expect(result.errorMessage, contains('No user found'));
      });

      test('should handle level up during activity logging', () async {
        // Create a user with high EXP close to level up
        final user = await userRepository.createUser(
          id: 'test_user',
          name: 'Test User',
        );
        await userRepository.completeOnboarding(user.id, {
          StatType.strength: 1.0,
          StatType.agility: 1.0,
          StatType.endurance: 1.0,
          StatType.intelligence: 1.0,
          StatType.focus: 1.0,
          StatType.charisma: 1.0,
        });

        // Add EXP close to level up threshold
        await userRepository.addEXP(user.id, 950.0); // Close to 1000 threshold

        // Log activity that should trigger level up
        final result = await activityService.logActivity(
          activityType: ActivityType.workoutWeights,
          durationMinutes: 60, // 60 EXP should trigger level up
        );

        expect(result.success, isTrue);
        expect(result.leveledUp, isTrue);
        expect(result.expGained, equals(60.0));
      });

      test('should get activity history', () async {
        // Create a user and log some activities
        final user = await userRepository.createUser(
          id: 'test_user',
          name: 'Test User',
        );
        await userRepository.completeOnboarding(user.id, {
          StatType.strength: 1.0,
          StatType.agility: 1.0,
          StatType.endurance: 1.0,
          StatType.intelligence: 1.0,
          StatType.focus: 1.0,
          StatType.charisma: 1.0,
        });

        // Log multiple activities
        await activityService.logActivity(
          activityType: ActivityType.workoutWeights,
          durationMinutes: 60,
        );
        await activityService.logActivity(
          activityType: ActivityType.studySerious,
          durationMinutes: 90,
        );

        // Get activity history
        final history = await activityService.getActivityHistory();

        expect(history.length, equals(2));
        expect(history[0].activityType, equals(ActivityType.studySerious.name)); // Most recent first
        expect(history[1].activityType, equals(ActivityType.workoutWeights.name));
      });

      test('should get todays activities', () async {
        // Create a user and log an activity
        final user = await userRepository.createUser(
          id: 'test_user',
          name: 'Test User',
        );
        await userRepository.completeOnboarding(user.id, {
          StatType.strength: 1.0,
          StatType.agility: 1.0,
          StatType.endurance: 1.0,
          StatType.intelligence: 1.0,
          StatType.focus: 1.0,
          StatType.charisma: 1.0,
        });

        await activityService.logActivity(
          activityType: ActivityType.meditation,
          durationMinutes: 30,
        );

        // Get today's activities
        final todaysActivities = await activityService.getTodaysActivities();

        expect(todaysActivities.length, equals(1));
        expect(todaysActivities[0].activityType, equals(ActivityType.meditation.name));
      });
    });
  });
}