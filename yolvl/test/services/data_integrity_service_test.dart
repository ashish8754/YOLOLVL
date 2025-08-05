import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import '../../lib/services/data_integrity_service.dart';
import '../../lib/repositories/user_repository.dart';
import '../../lib/repositories/activity_repository.dart';
import '../../lib/repositories/settings_repository.dart';
import '../../lib/models/user.dart';
import '../../lib/models/activity_log.dart';
import '../../lib/models/settings.dart';
import '../../lib/models/enums.dart';

void main() {
  group('DataIntegrityService', () {
    late DataIntegrityService dataIntegrityService;
    late UserRepository userRepository;
    late ActivityRepository activityRepository;
    late SettingsRepository settingsRepository;

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
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(SettingsAdapter());
      }

      // Open test boxes
      await Hive.openBox<User>('user_box');
      await Hive.openBox<ActivityLog>('activity_box');
      await Hive.openBox<Settings>('settings_box');
      
      userRepository = UserRepository();
      activityRepository = ActivityRepository();
      settingsRepository = SettingsRepository();
      dataIntegrityService = DataIntegrityService(
        userRepository: userRepository,
        activityRepository: activityRepository,
        settingsRepository: settingsRepository,
      );
    });

    tearDown(() async {
      await tearDownTestHive();
    });

    group('Data Validation', () {
      test('should validate user data successfully', () async {
        // Create valid user
        final user = await userRepository.createUser(
          id: 'test_user',
          name: 'Test User',
        );
        await userRepository.completeOnboarding(user.id, {
          StatType.strength: 2.5,
          StatType.agility: 1.8,
          StatType.endurance: 2.1,
          StatType.intelligence: 3.2,
          StatType.focus: 2.7,
          StatType.charisma: 1.9,
        });

        final result = await dataIntegrityService.validateUserData();

        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
        expect(result.warnings, isEmpty);
      });

      test('should detect invalid user stats', () async {
        // Create user with invalid stats
        final user = await userRepository.createUser(
          id: 'test_user',
          name: 'Test User',
        );
        await userRepository.completeOnboarding(user.id, {
          StatType.strength: -1.0, // Invalid negative stat
          StatType.agility: 1.8,
          StatType.endurance: 2.1,
          StatType.intelligence: 3.2,
          StatType.focus: 2.7,
          StatType.charisma: 1.9,
        });

        final result = await dataIntegrityService.validateUserData();

        expect(result.isValid, isFalse);
        expect(result.errors.length, greaterThan(0));
        expect(result.errors.any((error) => error.contains('negative')), isTrue);
      });

      test('should detect missing user stats', () async {
        // Create user with incomplete stats
        final user = await userRepository.createUser(
          id: 'test_user',
          name: 'Test User',
        );
        // Don't complete onboarding to have missing stats
        
        final result = await dataIntegrityService.validateUserData();

        expect(result.isValid, isFalse);
        expect(result.errors.any((error) => error.contains('onboarding')), isTrue);
      });

      test('should validate activity data successfully', () async {
        // Create valid activities
        final activity1 = ActivityLog.create(
          id: 'activity_1',
          activityType: ActivityType.workoutUpperBody,
          durationMinutes: 60,
          statGains: {StatType.strength: 0.06, StatType.endurance: 0.04},
          expGained: 60,
        );
        
        final activity2 = ActivityLog.create(
          id: 'activity_2',
          activityType: ActivityType.studySerious,
          durationMinutes: 90,
          statGains: {StatType.intelligence: 0.09, StatType.focus: 0.06},
          expGained: 90,
        );

        await activityRepository.logActivity(activity1);
        await activityRepository.logActivity(activity2);

        final result = await dataIntegrityService.validateActivityData();

        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('should detect invalid activity durations', () async {
        // Create activity with invalid duration
        final activity = ActivityLog.create(
          id: 'invalid_activity',
          activityType: ActivityType.workoutUpperBody,
          durationMinutes: -30, // Invalid negative duration
          statGains: {StatType.strength: 0.06},
          expGained: 60,
        );

        await activityRepository.logActivity(activity);

        final result = await dataIntegrityService.validateActivityData();

        expect(result.isValid, isFalse);
        expect(result.errors.any((error) => error.contains('duration')), isTrue);
      });

      test('should detect invalid EXP values', () async {
        // Create activity with invalid EXP
        final activity = ActivityLog.create(
          id: 'invalid_exp_activity',
          activityType: ActivityType.workoutUpperBody,
          durationMinutes: 60,
          statGains: {StatType.strength: 0.06},
          expGained: -10, // Invalid negative EXP
        );

        await activityRepository.logActivity(activity);

        final result = await dataIntegrityService.validateActivityData();

        expect(result.isValid, isFalse);
        expect(result.errors.any((error) => error.contains('EXP')), isTrue);
      });

      test('should detect inconsistent stat gains', () async {
        // Create activity with inconsistent stat gains
        final activity = ActivityLog.create(
          id: 'inconsistent_activity',
          activityType: ActivityType.workoutUpperBody,
          durationMinutes: 60,
          statGains: {StatType.intelligence: 0.06}, // Wrong stat for workout
          expGained: 60,
        );

        await activityRepository.logActivity(activity);

        final result = await dataIntegrityService.validateActivityData();

        expect(result.isValid, isFalse);
        expect(result.warnings.any((warning) => warning.contains('inconsistent')), isTrue);
      });

      test('should validate settings data successfully', () async {
        // Create valid settings
        final settings = Settings.defaultSettings();
        await settingsRepository.saveSettings(settings);

        final result = await dataIntegrityService.validateSettingsData();

        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('should detect invalid settings values', () async {
        // Create settings with invalid values
        final settings = Settings(
          isDarkMode: true,
          notificationsEnabled: true,
          enabledActivities: [],
          customStatIncrements: {'invalid_stat': -1.0}, // Invalid negative increment
          relaxedWeekendMode: false,
          lastBackupDate: DateTime.now(),
          dailyReminderHour: 25, // Invalid hour
          dailyReminderMinute: 0,
          degradationWarningsEnabled: true,
          levelUpAnimationsEnabled: true,
          hapticFeedbackEnabled: true,
        );

        await settingsRepository.saveSettings(settings);

        final result = await dataIntegrityService.validateSettingsData();

        expect(result.isValid, isFalse);
        expect(result.errors.any((error) => error.contains('hour')), isTrue);
      });
    });

    group('Data Repair', () {
      test('should repair negative user stats', () async {
        // Create user with negative stats
        final user = await userRepository.createUser(
          id: 'test_user',
          name: 'Test User',
        );
        await userRepository.completeOnboarding(user.id, {
          StatType.strength: -1.0,
          StatType.agility: 1.8,
          StatType.endurance: -0.5,
          StatType.intelligence: 3.2,
          StatType.focus: 2.7,
          StatType.charisma: 1.9,
        });

        final result = await dataIntegrityService.repairUserData();

        expect(result.repairsApplied, greaterThan(0));
        expect(result.success, isTrue);

        // Verify stats were repaired
        final repairedUser = userRepository.getCurrentUser();
        expect(repairedUser!.getStat(StatType.strength), equals(1.0));
        expect(repairedUser.getStat(StatType.endurance), equals(1.0));
        expect(repairedUser.getStat(StatType.agility), equals(1.8)); // Should be unchanged
      });

      test('should repair missing user stats', () async {
        // Create user without completing onboarding
        final user = await userRepository.createUser(
          id: 'test_user',
          name: 'Test User',
        );

        final result = await dataIntegrityService.repairUserData();

        expect(result.repairsApplied, greaterThan(0));
        expect(result.success, isTrue);

        // Verify stats were added
        final repairedUser = userRepository.getCurrentUser();
        expect(repairedUser!.getStat(StatType.strength), equals(1.0));
        expect(repairedUser.getStat(StatType.agility), equals(1.0));
        expect(repairedUser.getStat(StatType.endurance), equals(1.0));
        expect(repairedUser.getStat(StatType.intelligence), equals(1.0));
        expect(repairedUser.getStat(StatType.focus), equals(1.0));
        expect(repairedUser.getStat(StatType.charisma), equals(1.0));
      });

      test('should repair invalid activity data', () async {
        // Create activities with invalid data
        final activity1 = ActivityLog.create(
          id: 'activity_1',
          activityType: ActivityType.workoutUpperBody,
          durationMinutes: -30, // Invalid
          statGains: {StatType.strength: 0.06},
          expGained: 60,
        );

        final activity2 = ActivityLog.create(
          id: 'activity_2',
          activityType: ActivityType.studySerious,
          durationMinutes: 90,
          statGains: {StatType.intelligence: 0.09},
          expGained: -10, // Invalid
        );

        await activityRepository.logActivity(activity1);
        await activityRepository.logActivity(activity2);

        final result = await dataIntegrityService.repairActivityData();

        expect(result.repairsApplied, greaterThan(0));
        expect(result.success, isTrue);

        // Verify activities were repaired or removed
        final activities = activityRepository.findAll();
        for (final activity in activities) {
          expect(activity.durationMinutes, greaterThan(0));
          expect(activity.expGained, greaterThanOrEqualTo(0));
        }
      });

      test('should repair invalid settings', () async {
        // Create settings with invalid values
        final settings = Settings(
          isDarkMode: true,
          notificationsEnabled: true,
          enabledActivities: [],
          customStatIncrements: {},
          relaxedWeekendMode: false,
          lastBackupDate: DateTime.now(),
          dailyReminderHour: 25, // Invalid
          dailyReminderMinute: 70, // Invalid
          degradationWarningsEnabled: true,
          levelUpAnimationsEnabled: true,
          hapticFeedbackEnabled: true,
        );

        await settingsRepository.saveSettings(settings);

        final result = await dataIntegrityService.repairSettingsData();

        expect(result.repairsApplied, greaterThan(0));
        expect(result.success, isTrue);

        // Verify settings were repaired
        final repairedSettings = settingsRepository.getSettings();
        expect(repairedSettings.dailyReminderHour, lessThan(24));
        expect(repairedSettings.dailyReminderMinute, lessThan(60));
      });
    });

    group('Comprehensive Data Check', () {
      test('should perform full data integrity check', () async {
        // Create mixed valid and invalid data
        final user = await userRepository.createUser(
          id: 'test_user',
          name: 'Test User',
        );
        await userRepository.completeOnboarding(user.id, {
          StatType.strength: -1.0, // Invalid
          StatType.agility: 1.8,
          StatType.endurance: 2.1,
          StatType.intelligence: 3.2,
          StatType.focus: 2.7,
          StatType.charisma: 1.9,
        });

        final activity = ActivityLog.create(
          id: 'test_activity',
          activityType: ActivityType.workoutUpperBody,
          durationMinutes: -30, // Invalid
          statGains: {StatType.strength: 0.06},
          expGained: 60,
        );
        await activityRepository.logActivity(activity);

        final result = await dataIntegrityService.performFullIntegrityCheck();

        expect(result.overallValid, isFalse);
        expect(result.userDataResult.isValid, isFalse);
        expect(result.activityDataResult.isValid, isFalse);
        expect(result.settingsDataResult.isValid, isTrue);
      });

      test('should perform full data repair', () async {
        // Create invalid data
        final user = await userRepository.createUser(
          id: 'test_user',
          name: 'Test User',
        );
        await userRepository.completeOnboarding(user.id, {
          StatType.strength: -1.0,
          StatType.agility: 1.8,
          StatType.endurance: 2.1,
          StatType.intelligence: 3.2,
          StatType.focus: 2.7,
          StatType.charisma: 1.9,
        });

        final activity = ActivityLog.create(
          id: 'test_activity',
          activityType: ActivityType.workoutUpperBody,
          durationMinutes: -30,
          statGains: {StatType.strength: 0.06},
          expGained: 60,
        );
        await activityRepository.logActivity(activity);

        final result = await dataIntegrityService.performFullDataRepair();

        expect(result.overallSuccess, isTrue);
        expect(result.totalRepairsApplied, greaterThan(0));

        // Verify data was repaired
        final repairedUser = userRepository.getCurrentUser();
        expect(repairedUser!.getStat(StatType.strength), equals(1.0));

        final activities = activityRepository.findAll();
        for (final activity in activities) {
          expect(activity.durationMinutes, greaterThan(0));
        }
      });
    });

    group('Data Consistency Checks', () {
      test('should detect EXP/level inconsistencies', () async {
        // Create user with inconsistent EXP and level
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

        // Manually set inconsistent values
        user.level = 5;
        user.currentEXP = 100.0; // Too low for level 5
        await userRepository.updateUser(user);

        final result = await dataIntegrityService.checkDataConsistency();

        expect(result.isConsistent, isFalse);
        expect(result.inconsistencies.any((issue) => issue.contains('EXP')), isTrue);
      });

      test('should detect activity/stat inconsistencies', () async {
        // Create user and activities
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

        // Create many activities that should have increased stats significantly
        for (int i = 0; i < 100; i++) {
          final activity = ActivityLog.create(
            id: 'activity_$i',
            activityType: ActivityType.workoutUpperBody,
            durationMinutes: 60,
            statGains: {StatType.strength: 0.06, StatType.endurance: 0.04},
            expGained: 60,
            timestamp: DateTime.now().subtract(Duration(days: i)),
          );
          await activityRepository.logActivity(activity);
        }

        final result = await dataIntegrityService.checkDataConsistency();

        expect(result.isConsistent, isFalse);
        expect(result.inconsistencies.any((issue) => issue.contains('stat')), isTrue);
      });

      test('should validate timestamp consistency', () async {
        // Create activities with future timestamps
        final futureActivity = ActivityLog.create(
          id: 'future_activity',
          activityType: ActivityType.workoutUpperBody,
          durationMinutes: 60,
          statGains: {StatType.strength: 0.06},
          expGained: 60,
          timestamp: DateTime.now().add(const Duration(days: 1)), // Future timestamp
        );

        await activityRepository.logActivity(futureActivity);

        final result = await dataIntegrityService.validateActivityData();

        expect(result.isValid, isFalse);
        expect(result.errors.any((error) => error.contains('future')), isTrue);
      });
    });

    group('Data Recovery', () {
      test('should create data recovery point', () async {
        // Create some data
        final user = await userRepository.createUser(
          id: 'test_user',
          name: 'Test User',
        );
        await userRepository.completeOnboarding(user.id, {
          StatType.strength: 2.5,
          StatType.agility: 1.8,
          StatType.endurance: 2.1,
          StatType.intelligence: 3.2,
          StatType.focus: 2.7,
          StatType.charisma: 1.9,
        });

        final result = await dataIntegrityService.createRecoveryPoint();

        expect(result.success, isTrue);
        expect(result.recoveryPointId, isNotNull);
        expect(result.recoveryPointId!.isNotEmpty, isTrue);
      });

      test('should restore from recovery point', () async {
        // Create initial data
        final user = await userRepository.createUser(
          id: 'test_user',
          name: 'Test User',
        );
        await userRepository.completeOnboarding(user.id, {
          StatType.strength: 2.5,
          StatType.agility: 1.8,
          StatType.endurance: 2.1,
          StatType.intelligence: 3.2,
          StatType.focus: 2.7,
          StatType.charisma: 1.9,
        });

        // Create recovery point
        final recoveryResult = await dataIntegrityService.createRecoveryPoint();
        expect(recoveryResult.success, isTrue);

        // Modify data
        user.setStat(StatType.strength, 5.0);
        await userRepository.updateUser(user);

        // Restore from recovery point
        final restoreResult = await dataIntegrityService.restoreFromRecoveryPoint(
          recoveryResult.recoveryPointId!,
        );

        expect(restoreResult.success, isTrue);

        // Verify data was restored
        final restoredUser = userRepository.getCurrentUser();
        expect(restoredUser!.getStat(StatType.strength), equals(2.5));
      });

      test('should handle invalid recovery point ID', () async {
        final result = await dataIntegrityService.restoreFromRecoveryPoint('invalid_id');

        expect(result.success, isFalse);
        expect(result.errorMessage, isNotNull);
      });
    });

    group('Performance and Scalability', () {
      test('should handle large datasets efficiently', () async {
        // Create user
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

        // Create many activities
        for (int i = 0; i < 1000; i++) {
          final activity = ActivityLog.create(
            id: 'activity_$i',
            activityType: ActivityType.workoutUpperBody,
            durationMinutes: 60,
            statGains: {StatType.strength: 0.06},
            expGained: 60,
            timestamp: DateTime.now().subtract(Duration(minutes: i)),
          );
          await activityRepository.logActivity(activity);
        }

        final stopwatch = Stopwatch()..start();
        final result = await dataIntegrityService.validateActivityData();
        stopwatch.stop();

        expect(result.isValid, isTrue);
        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // Should complete within 5 seconds
      });

      test('should provide progress updates for long operations', () async {
        // Create large dataset
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

        for (int i = 0; i < 100; i++) {
          final activity = ActivityLog.create(
            id: 'activity_$i',
            activityType: ActivityType.workoutUpperBody,
            durationMinutes: 60,
            statGains: {StatType.strength: 0.06},
            expGained: 60,
          );
          await activityRepository.logActivity(activity);
        }

        final progressUpdates = <double>[];
        
        await dataIntegrityService.performFullIntegrityCheck(
          onProgress: (progress) {
            progressUpdates.add(progress);
          },
        );

        expect(progressUpdates.isNotEmpty, isTrue);
        expect(progressUpdates.last, equals(1.0)); // Should reach 100%
      });
    });

    group('Error Handling', () {
      test('should handle repository errors gracefully', () async {
        // Create service with null repositories to simulate errors
        final errorService = DataIntegrityService(
          userRepository: null,
          activityRepository: activityRepository,
          settingsRepository: settingsRepository,
        );

        final result = await errorService.validateUserData();

        expect(result.isValid, isFalse);
        expect(result.errors.any((error) => error.contains('error')), isTrue);
      });

      test('should handle corrupted data gracefully', () async {
        // This would require more complex setup to simulate corrupted data
        // For now, we'll test that the service doesn't crash with unexpected data
        
        final result = await dataIntegrityService.validateUserData();
        
        // Should not throw exceptions even with no data
        expect(result, isNotNull);
      });

      test('should provide detailed error information', () async {
        // Create multiple types of invalid data
        final user = await userRepository.createUser(
          id: 'test_user',
          name: 'Test User',
        );
        await userRepository.completeOnboarding(user.id, {
          StatType.strength: -1.0, // Invalid
          StatType.agility: 1.8,
          StatType.endurance: -0.5, // Invalid
          StatType.intelligence: 3.2,
          StatType.focus: 2.7,
          StatType.charisma: 1.9,
        });

        final result = await dataIntegrityService.validateUserData();

        expect(result.isValid, isFalse);
        expect(result.errors.length, greaterThanOrEqualTo(2)); // Should detect both invalid stats
        
        // Each error should be descriptive
        for (final error in result.errors) {
          expect(error.length, greaterThan(10)); // Should be descriptive
        }
      });
    });

    group('Data Integrity Models', () {
      test('should create ValidationResult correctly', () {
        final result = ValidationResult(
          isValid: false,
          errors: ['Error 1', 'Error 2'],
          warnings: ['Warning 1'],
        );

        expect(result.isValid, isFalse);
        expect(result.errors.length, equals(2));
        expect(result.warnings.length, equals(1));
        expect(result.hasErrors, isTrue);
        expect(result.hasWarnings, isTrue);
      });

      test('should create RepairResult correctly', () {
        final result = RepairResult(
          success: true,
          repairsApplied: 5,
          details: ['Repair 1', 'Repair 2'],
        );

        expect(result.success, isTrue);
        expect(result.repairsApplied, equals(5));
        expect(result.details.length, equals(2));
      });

      test('should create ConsistencyCheckResult correctly', () {
        final result = ConsistencyCheckResult(
          isConsistent: false,
          inconsistencies: ['Issue 1', 'Issue 2'],
        );

        expect(result.isConsistent, isFalse);
        expect(result.inconsistencies.length, equals(2));
      });

      test('should create FullIntegrityResult correctly', () {
        final userResult = ValidationResult(isValid: true, errors: [], warnings: []);
        final activityResult = ValidationResult(isValid: false, errors: ['Error'], warnings: []);
        final settingsResult = ValidationResult(isValid: true, errors: [], warnings: []);

        final result = FullIntegrityResult(
          userDataResult: userResult,
          activityDataResult: activityResult,
          settingsDataResult: settingsResult,
        );

        expect(result.overallValid, isFalse); // Should be false if any component is invalid
        expect(result.userDataResult.isValid, isTrue);
        expect(result.activityDataResult.isValid, isFalse);
        expect(result.settingsDataResult.isValid, isTrue);
      });
    });
  });
}