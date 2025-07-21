import 'package:flutter_test/flutter_test.dart';
import 'package:yolvl/models/activity_log.dart';
import 'package:yolvl/models/enums.dart';
import 'package:yolvl/services/activity_migration_service.dart';
import 'package:yolvl/repositories/activity_repository.dart';

// Mock repository for testing
class MockActivityRepository extends ActivityRepository {
  final List<ActivityLog> _activities = [];
  final Map<String, ActivityLog> _activitiesById = {};

  @override
  Future<List<ActivityLog>> getAllActivities() async {
    return List.from(_activities);
  }

  @override
  ActivityLog? findByKey(dynamic key) {
    return _activitiesById[key.toString()];
  }

  @override
  Future<void> logActivity(ActivityLog activityLog) async {
    final existingIndex = _activities.indexWhere((a) => a.id == activityLog.id);
    if (existingIndex >= 0) {
      _activities[existingIndex] = activityLog;
    } else {
      _activities.add(activityLog);
    }
    _activitiesById[activityLog.id] = activityLog;
  }

  void addTestActivity(ActivityLog activity) {
    _activities.add(activity);
    _activitiesById[activity.id] = activity;
  }

  void clear() {
    _activities.clear();
    _activitiesById.clear();
  }
}

void main() {
  group('ActivityMigrationService Tests', () {
    late ActivityMigrationService migrationService;
    late MockActivityRepository mockRepository;

    setUp(() {
      mockRepository = MockActivityRepository();
      migrationService = ActivityMigrationService(
        activityRepository: mockRepository,
      );
    });

    tearDown(() {
      mockRepository.clear();
    });

    group('Migration Status Checks', () {
      test('should return zero when no activities exist', () async {
        final count = await migrationService.getActivitiesNeedingMigrationCount();
        expect(count, equals(0));

        final hasActivities = await migrationService.hasActivitiesNeedingMigration();
        expect(hasActivities, isFalse);
      });

      test('should count activities needing migration', () async {
        // Add activity with stat gains (doesn't need migration)
        final activityWithGains = ActivityLog(
          id: 'with_gains',
          activityType: ActivityType.workoutWeights.name,
          durationMinutes: 60,
          timestamp: DateTime.now(),
          statGains: {
            StatType.strength.name: 0.06,
            StatType.endurance.name: 0.04,
          },
          expGained: 60.0,
        );
        mockRepository.addTestActivity(activityWithGains);

        // Add activity without stat gains (needs migration)
        final activityWithoutGains = ActivityLog(
          id: 'without_gains',
          activityType: ActivityType.meditation.name,
          durationMinutes: 30,
          timestamp: DateTime.now(),
          statGains: {},
          expGained: 30.0,
        );
        mockRepository.addTestActivity(activityWithoutGains);

        final count = await migrationService.getActivitiesNeedingMigrationCount();
        expect(count, equals(1));

        final hasActivities = await migrationService.hasActivitiesNeedingMigration();
        expect(hasActivities, isTrue);
      });

      test('should get migration status correctly', () async {
        // Add activities with and without stat gains
        final activityWithGains = ActivityLog(
          id: 'with_gains',
          activityType: ActivityType.workoutWeights.name,
          durationMinutes: 60,
          timestamp: DateTime.now(),
          statGains: {StatType.strength.name: 0.06},
          expGained: 60.0,
        );
        mockRepository.addTestActivity(activityWithGains);

        final activityWithoutGains1 = ActivityLog(
          id: 'without_gains_1',
          activityType: ActivityType.meditation.name,
          durationMinutes: 30,
          timestamp: DateTime.now(),
          statGains: {},
          expGained: 30.0,
        );
        mockRepository.addTestActivity(activityWithoutGains1);

        final activityWithoutGains2 = ActivityLog(
          id: 'without_gains_2',
          activityType: ActivityType.studySerious.name,
          durationMinutes: 45,
          timestamp: DateTime.now(),
          statGains: {},
          expGained: 45.0,
        );
        mockRepository.addTestActivity(activityWithoutGains2);

        final status = await migrationService.getMigrationStatus();

        expect(status.totalActivities, equals(3));
        expect(status.migratedActivities, equals(1));
        expect(status.activitiesNeedingMigration, equals(2));
        expect(status.migrationComplete, isFalse);
        expect(status.completionPercentage, closeTo(33.33, 0.1));
      });
    });

    group('Single Activity Migration', () {
      test('should migrate single activity successfully', () async {
        final activityWithoutGains = ActivityLog(
          id: 'test_activity',
          activityType: ActivityType.workoutWeights.name,
          durationMinutes: 60,
          timestamp: DateTime.now(),
          statGains: {},
          expGained: 60.0,
        );
        mockRepository.addTestActivity(activityWithoutGains);

        expect(activityWithoutGains.needsStatGainMigration, isTrue);

        final result = await migrationService.migrateActivity('test_activity');
        expect(result, isTrue);

        // Verify the activity was migrated
        final migratedActivity = mockRepository.findByKey('test_activity');
        expect(migratedActivity, isNotNull);
        expect(migratedActivity!.hasStoredStatGains, isTrue);
        expect(migratedActivity.statGains[StatType.strength.name], equals(0.06));
        expect(migratedActivity.statGains[StatType.endurance.name], equals(0.04));
      });

      test('should return false for non-existent activity', () async {
        final result = await migrationService.migrateActivity('non_existent');
        expect(result, isFalse);
      });

      test('should return true for already migrated activity', () async {
        final activityWithGains = ActivityLog(
          id: 'already_migrated',
          activityType: ActivityType.meditation.name,
          durationMinutes: 30,
          timestamp: DateTime.now(),
          statGains: {StatType.focus.name: 0.025},
          expGained: 30.0,
        );
        mockRepository.addTestActivity(activityWithGains);

        final result = await migrationService.migrateActivity('already_migrated');
        expect(result, isTrue);
      });
    });

    group('Bulk Migration', () {
      test('should migrate all activities successfully', () async {
        // Add activities without stat gains
        final activities = [
          ActivityLog(
            id: 'activity_1',
            activityType: ActivityType.workoutWeights.name,
            durationMinutes: 60,
            timestamp: DateTime.now(),
            statGains: {},
            expGained: 60.0,
          ),
          ActivityLog(
            id: 'activity_2',
            activityType: ActivityType.meditation.name,
            durationMinutes: 30,
            timestamp: DateTime.now(),
            statGains: {},
            expGained: 30.0,
          ),
          ActivityLog(
            id: 'activity_3',
            activityType: ActivityType.studySerious.name,
            durationMinutes: 90,
            timestamp: DateTime.now(),
            statGains: {},
            expGained: 90.0,
          ),
        ];

        for (final activity in activities) {
          mockRepository.addTestActivity(activity);
        }

        final result = await migrationService.migrateAllActivities();

        expect(result.success, isTrue);
        expect(result.totalActivities, equals(3));
        expect(result.migratedActivities, equals(3));
        expect(result.completionPercentage, equals(100.0));

        // Verify all activities were migrated
        for (final activity in activities) {
          final migratedActivity = mockRepository.findByKey(activity.id);
          expect(migratedActivity, isNotNull);
          expect(migratedActivity!.hasStoredStatGains, isTrue);
        }
      });

      test('should handle no activities needing migration', () async {
        // Add activity that already has stat gains
        final activityWithGains = ActivityLog(
          id: 'already_migrated',
          activityType: ActivityType.workoutWeights.name,
          durationMinutes: 60,
          timestamp: DateTime.now(),
          statGains: {StatType.strength.name: 0.06},
          expGained: 60.0,
        );
        mockRepository.addTestActivity(activityWithGains);

        final result = await migrationService.migrateAllActivities();

        expect(result.success, isTrue);
        expect(result.totalActivities, equals(1));
        expect(result.migratedActivities, equals(0));
        expect(result.message, equals('No activities need migration'));
      });

      test('should handle empty activity list', () async {
        final result = await migrationService.migrateAllActivities();

        expect(result.success, isTrue);
        expect(result.totalActivities, equals(0));
        expect(result.migratedActivities, equals(0));
        expect(result.message, equals('No activities need migration'));
      });

      test('should handle mixed activities (some migrated, some not)', () async {
        // Add activity with stat gains (already migrated)
        final activityWithGains = ActivityLog(
          id: 'with_gains',
          activityType: ActivityType.workoutWeights.name,
          durationMinutes: 60,
          timestamp: DateTime.now(),
          statGains: {StatType.strength.name: 0.06},
          expGained: 60.0,
        );
        mockRepository.addTestActivity(activityWithGains);

        // Add activities without stat gains (need migration)
        final activitiesWithoutGains = [
          ActivityLog(
            id: 'without_gains_1',
            activityType: ActivityType.meditation.name,
            durationMinutes: 30,
            timestamp: DateTime.now(),
            statGains: {},
            expGained: 30.0,
          ),
          ActivityLog(
            id: 'without_gains_2',
            activityType: ActivityType.studySerious.name,
            durationMinutes: 45,
            timestamp: DateTime.now(),
            statGains: {},
            expGained: 45.0,
          ),
        ];

        for (final activity in activitiesWithoutGains) {
          mockRepository.addTestActivity(activity);
        }

        final result = await migrationService.migrateAllActivities();

        expect(result.success, isTrue);
        expect(result.totalActivities, equals(3));
        expect(result.migratedActivities, equals(2));
        expect(result.completionPercentage, closeTo(66.67, 0.1));

        // Verify only the activities without gains were migrated
        final migratedActivity1 = mockRepository.findByKey('without_gains_1');
        expect(migratedActivity1!.hasStoredStatGains, isTrue);

        final migratedActivity2 = mockRepository.findByKey('without_gains_2');
        expect(migratedActivity2!.hasStoredStatGains, isTrue);

        // Original activity should remain unchanged
        final originalActivity = mockRepository.findByKey('with_gains');
        expect(originalActivity!.statGains[StatType.strength.name], equals(0.06));
      });
    });

    group('Migration Result', () {
      test('should calculate completion percentage correctly', () {
        final result = ActivityMigrationResult.success(
          totalActivities: 10,
          migratedActivities: 7,
        );

        expect(result.completionPercentage, equals(70.0));
      });

      test('should handle zero total activities', () {
        final result = ActivityMigrationResult.success(
          totalActivities: 0,
          migratedActivities: 0,
        );

        expect(result.completionPercentage, equals(100.0));
      });

      test('should create error result correctly', () {
        final result = ActivityMigrationResult.error('Test error');

        expect(result.success, isFalse);
        expect(result.errorMessage, equals('Test error'));
        expect(result.totalActivities, equals(0));
        expect(result.migratedActivities, equals(0));
      });

      test('should create partial success result correctly', () {
        final errors = ['Error 1', 'Error 2'];
        final result = ActivityMigrationResult.partialSuccess(
          totalActivities: 5,
          migratedActivities: 3,
          errors: errors,
        );

        expect(result.success, isFalse);
        expect(result.errors, equals(errors));
        expect(result.errorMessage, equals('Migration completed with 2 errors'));
        expect(result.totalActivities, equals(5));
        expect(result.migratedActivities, equals(3));
      });
    });

    group('Migration Status', () {
      test('should calculate completion percentage correctly', () {
        final status = ActivityMigrationStatus(
          totalActivities: 20,
          migratedActivities: 15,
          activitiesNeedingMigration: 5,
          migrationComplete: false,
        );

        expect(status.completionPercentage, equals(75.0));
      });

      test('should handle zero total activities', () {
        final status = ActivityMigrationStatus(
          totalActivities: 0,
          migratedActivities: 0,
          activitiesNeedingMigration: 0,
          migrationComplete: true,
        );

        expect(status.completionPercentage, equals(100.0));
      });

      test('should indicate completion correctly', () {
        final completeStatus = ActivityMigrationStatus(
          totalActivities: 10,
          migratedActivities: 10,
          activitiesNeedingMigration: 0,
          migrationComplete: true,
        );

        expect(completeStatus.migrationComplete, isTrue);

        final incompleteStatus = ActivityMigrationStatus(
          totalActivities: 10,
          migratedActivities: 7,
          activitiesNeedingMigration: 3,
          migrationComplete: false,
        );

        expect(incompleteStatus.migrationComplete, isFalse);
      });
    });

    group('Error Handling', () {
      test('should handle repository errors gracefully', () async {
        // Create a repository that throws errors
        final errorRepository = _ErrorActivityRepository();
        final errorMigrationService = ActivityMigrationService(
          activityRepository: errorRepository,
        );

        expect(
          () => errorMigrationService.getActivitiesNeedingMigrationCount(),
          throwsA(isA<ActivityMigrationException>()),
        );

        expect(
          () => errorMigrationService.hasActivitiesNeedingMigration(),
          throwsA(isA<ActivityMigrationException>()),
        );

        expect(
          () => errorMigrationService.getMigrationStatus(),
          throwsA(isA<ActivityMigrationException>()),
        );

        expect(
          () => errorMigrationService.migrateActivity('test'),
          throwsA(isA<ActivityMigrationException>()),
        );
      });

      test('should return error result for migration failures', () async {
        final errorRepository = _ErrorActivityRepository();
        final errorMigrationService = ActivityMigrationService(
          activityRepository: errorRepository,
        );

        final result = await errorMigrationService.migrateAllActivities();

        expect(result.success, isFalse);
        expect(result.errorMessage, contains('Migration failed'));
      });
    });
  });
}

// Mock repository that throws errors for testing error handling
class _ErrorActivityRepository extends ActivityRepository {
  @override
  Future<List<ActivityLog>> getAllActivities() async {
    throw Exception('Repository error');
  }

  @override
  ActivityLog? findByKey(dynamic key) {
    throw Exception('Repository error');
  }

  @override
  Future<void> logActivity(ActivityLog activityLog) async {
    throw Exception('Repository error');
  }
}