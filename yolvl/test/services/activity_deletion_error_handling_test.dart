import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import '../../lib/models/activity_log.dart';
import '../../lib/models/user.dart';
import '../../lib/models/enums.dart';
import '../../lib/services/activity_service.dart';
import '../../lib/services/stats_service.dart';
import '../../lib/services/exp_service.dart';
import '../../lib/repositories/activity_repository.dart';
import '../../lib/repositories/user_repository.dart';

@GenerateMocks([ActivityRepository, UserRepository])
import 'activity_deletion_error_handling_test.mocks.dart';

void main() {
  group('Activity Deletion Error Handling Tests', () {
    late ActivityService activityService;
    late MockActivityRepository mockActivityRepository;
    late MockUserRepository mockUserRepository;
    late User testUser;
    late ActivityLog testActivity;

    setUp(() async {
      // Initialize Hive for testing
      await Hive.initFlutter();
      
      // Register adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(UserAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(ActivityLogAdapter());
      }

      // Create mocks
      mockActivityRepository = MockActivityRepository();
      mockUserRepository = MockUserRepository();

      // Create service with mocks
      activityService = ActivityService(
        activityRepository: mockActivityRepository,
        userRepository: mockUserRepository,
      );

      // Create test user
      testUser = User.create(
        id: 'test_user',
        name: 'Test User',
      );
      testUser.level = 5;
      testUser.currentEXP = 500.0;
      testUser.setStat(StatType.strength, 3.5);
      testUser.setStat(StatType.endurance, 2.8);

      // Create test activity
      testActivity = ActivityLog.create(
        id: 'test_activity',
        activityType: ActivityType.workoutUpperBody,
        durationMinutes: 60,
        statGains: {
          StatType.strength: 0.06,
          StatType.endurance: 0.04,
        },
        expGained: 60.0,
      );
    });

    tearDown(() async {
      await Hive.close();
    });

    group('Input Validation Tests', () {
      test('should reject empty activity ID', () async {
        // Arrange
        when(mockUserRepository.getCurrentUser()).thenReturn(testUser);

        // Act
        final result = await activityService.deleteActivityWithStatReversal('');

        // Assert
        expect(result.success, false);
        expect(result.errorMessage, contains('Invalid activity ID'));
      });

      test('should reject non-existent activity', () async {
        // Arrange
        when(mockActivityRepository.findByKey('non_existent')).thenReturn(null);
        when(mockUserRepository.getCurrentUser()).thenReturn(testUser);

        // Act
        final result = await activityService.deleteActivityWithStatReversal('non_existent');

        // Assert
        expect(result.success, false);
        expect(result.errorMessage, contains('Activity not found'));
      });

      test('should reject when no current user', () async {
        // Arrange
        when(mockActivityRepository.findByKey('test_activity')).thenReturn(testActivity);
        when(mockUserRepository.getCurrentUser()).thenReturn(null);

        // Act
        final result = await activityService.deleteActivityWithStatReversal('test_activity');

        // Assert
        expect(result.success, false);
        expect(result.errorMessage, contains('No user found'));
      });
    });

    group('Activity Validation Tests', () {
      test('should reject activity with invalid duration', () async {
        // Arrange
        final invalidActivity = ActivityLog.create(
          id: 'invalid_activity',
          activityType: ActivityType.workoutUpperBody,
          durationMinutes: -10, // Invalid negative duration
          statGains: {},
          expGained: 0.0,
        );

        when(mockActivityRepository.findByKey('invalid_activity')).thenReturn(invalidActivity);
        when(mockUserRepository.getCurrentUser()).thenReturn(testUser);

        // Act
        final result = await activityService.deleteActivityWithStatReversal('invalid_activity');

        // Assert
        expect(result.success, false);
        expect(result.errorMessage, contains('invalid and cannot be safely deleted'));
      });

      test('should reject activity with negative EXP', () async {
        // Arrange
        final invalidActivity = ActivityLog.create(
          id: 'invalid_activity',
          activityType: ActivityType.workoutUpperBody,
          durationMinutes: 60,
          statGains: {},
          expGained: -50.0, // Invalid negative EXP
        );

        when(mockActivityRepository.findByKey('invalid_activity')).thenReturn(invalidActivity);
        when(mockUserRepository.getCurrentUser()).thenReturn(testUser);

        // Act
        final result = await activityService.deleteActivityWithStatReversal('invalid_activity');

        // Assert
        expect(result.success, false);
        expect(result.errorMessage, contains('invalid and cannot be safely deleted'));
      });

      test('should reject activity with invalid stat gains', () async {
        // Arrange
        final invalidActivity = ActivityLog.create(
          id: 'invalid_activity',
          activityType: ActivityType.workoutUpperBody,
          durationMinutes: 60,
          statGains: {
            StatType.strength: double.nan, // Invalid NaN value
          },
          expGained: 60.0,
        );

        when(mockActivityRepository.findByKey('invalid_activity')).thenReturn(invalidActivity);
        when(mockUserRepository.getCurrentUser()).thenReturn(testUser);

        // Act
        final result = await activityService.deleteActivityWithStatReversal('invalid_activity');

        // Assert
        expect(result.success, false);
        expect(result.errorMessage, contains('invalid and cannot be safely deleted'));
      });
    });

    group('Rollback Mechanism Tests', () {
      test('should rollback user data when activity deletion fails', () async {
        // Arrange
        when(mockActivityRepository.findByKey('test_activity')).thenReturn(testActivity);
        when(mockUserRepository.getCurrentUser()).thenReturn(testUser);
        when(mockUserRepository.updateUser(any)).thenAnswer((_) async {});
        when(mockActivityRepository.deleteByKey('test_activity'))
            .thenThrow(Exception('Database error'));

        final originalLevel = testUser.level;
        final originalEXP = testUser.currentEXP;
        final originalStrength = testUser.getStat(StatType.strength);

        // Act
        final result = await activityService.deleteActivityWithStatReversal('test_activity');

        // Assert
        expect(result.success, false);
        expect(result.errorMessage, contains('Failed to delete activity after user update'));
        
        // Verify rollback was attempted (user data should be restored)
        verify(mockUserRepository.updateUser(any)).called(greaterThan(1));
      });

      test('should handle rollback failure gracefully', () async {
        // Arrange
        when(mockActivityRepository.findByKey('test_activity')).thenReturn(testActivity);
        when(mockUserRepository.getCurrentUser()).thenReturn(testUser);
        when(mockUserRepository.updateUser(any))
            .thenThrow(Exception('Database connection lost'));

        // Act
        final result = await activityService.deleteActivityWithStatReversal('test_activity');

        // Assert
        expect(result.success, false);
        expect(result.errorMessage, contains('Failed to save user data during deletion'));
      });
    });

    group('Data Consistency Validation Tests', () {
      test('should handle extreme stat reversal values', () async {
        // Arrange
        final extremeActivity = ActivityLog.create(
          id: 'extreme_activity',
          activityType: ActivityType.workoutUpperBody,
          durationMinutes: 60,
          statGains: {
            StatType.strength: 1000.0, // Extreme value that would cause negative stats
          },
          expGained: 60.0,
        );

        when(mockActivityRepository.findByKey('extreme_activity')).thenReturn(extremeActivity);
        when(mockUserRepository.getCurrentUser()).thenReturn(testUser);

        // Act
        final result = await activityService.deleteActivityWithStatReversal('extreme_activity');

        // Assert
        // Should still succeed but clamp stats to minimum
        expect(result.success, true);
        expect(result.statReversals[StatType.strength], 1000.0);
      });

      test('should handle future timestamp activities', () async {
        // Arrange
        final futureActivity = ActivityLog.create(
          id: 'future_activity',
          activityType: ActivityType.workoutUpperBody,
          durationMinutes: 60,
          statGains: {StatType.strength: 0.06},
          expGained: 60.0,
          timestamp: DateTime.now().add(const Duration(days: 1)), // Future timestamp
        );

        when(mockActivityRepository.findByKey('future_activity')).thenReturn(futureActivity);
        when(mockUserRepository.getCurrentUser()).thenReturn(testUser);

        // Act
        final result = await activityService.deleteActivityWithStatReversal('future_activity');

        // Assert
        expect(result.success, false);
        expect(result.errorMessage, contains('data inconsistency'));
      });
    });

    group('Stat Reversal Validation Tests', () {
      test('should validate stat reversal with empty current stats', () {
        // Arrange
        final emptyStats = <StatType, double>{};
        final reversals = {StatType.strength: 0.5};

        // Act
        final isValid = StatsService.validateStatReversal(emptyStats, reversals);

        // Assert
        expect(isValid, false);
      });

      test('should validate stat reversal with NaN values', () {
        // Arrange
        final currentStats = {StatType.strength: 3.0};
        final reversals = {StatType.strength: double.nan};

        // Act
        final isValid = StatsService.validateStatReversal(currentStats, reversals);

        // Assert
        expect(isValid, false);
      });

      test('should validate stat reversal with negative values', () {
        // Arrange
        final currentStats = {StatType.strength: 3.0};
        final reversals = {StatType.strength: -0.5};

        // Act
        final isValid = StatsService.validateStatReversal(currentStats, reversals);

        // Assert
        expect(isValid, false);
      });

      test('should validate stat reversal with extreme negative results', () {
        // Arrange
        final currentStats = {StatType.strength: 1.0};
        final reversals = {StatType.strength: 200.0}; // Would result in -199

        // Act
        final isValid = StatsService.validateStatReversal(currentStats, reversals);

        // Assert
        expect(isValid, false);
      });
    });

    group('EXP Reversal Validation Tests', () {
      test('should validate EXP reversal with negative amount', () {
        // Act
        final isValid = EXPService.validateEXPReversal(testUser, -50.0);

        // Assert
        expect(isValid, false);
      });

      test('should validate EXP reversal with NaN amount', () {
        // Act
        final isValid = EXPService.validateEXPReversal(testUser, double.nan);

        // Assert
        expect(isValid, false);
      });

      test('should validate EXP reversal with infinite amount', () {
        // Act
        final isValid = EXPService.validateEXPReversal(testUser, double.infinity);

        // Assert
        expect(isValid, false);
      });

      test('should validate EXP reversal with invalid user level', () {
        // Arrange
        final invalidUser = User.create(id: 'invalid', name: 'Invalid');
        invalidUser.level = 0; // Invalid level

        // Act
        final isValid = EXPService.validateEXPReversal(invalidUser, 50.0);

        // Assert
        expect(isValid, false);
      });

      test('should validate EXP reversal with invalid current EXP', () {
        // Arrange
        final invalidUser = User.create(id: 'invalid', name: 'Invalid');
        invalidUser.currentEXP = double.nan; // Invalid EXP

        // Act
        final isValid = EXPService.validateEXPReversal(invalidUser, 50.0);

        // Assert
        expect(isValid, false);
      });

      test('should handle extreme EXP reversal amounts', () {
        // Act
        final isValid = EXPService.validateEXPReversal(testUser, 2000000.0); // 2 million EXP

        // Assert
        expect(isValid, true); // Should be valid but logged as warning
      });
    });

    group('Error Recovery Tests', () {
      test('should handle corrupted user data gracefully', () async {
        // Arrange
        final corruptedUser = User.create(id: 'corrupted', name: 'Corrupted');
        corruptedUser.currentEXP = double.nan;
        corruptedUser.setStat(StatType.strength, double.infinity);

        when(mockActivityRepository.findByKey('test_activity')).thenReturn(testActivity);
        when(mockUserRepository.getCurrentUser()).thenReturn(corruptedUser);

        // Act
        final result = await activityService.deleteActivityWithStatReversal('test_activity');

        // Assert
        expect(result.success, false);
        expect(result.errorMessage, isNotEmpty);
      });

      test('should handle repository exceptions gracefully', () async {
        // Arrange
        when(mockActivityRepository.findByKey('test_activity'))
            .thenThrow(Exception('Repository connection failed'));

        // Act
        final result = await activityService.deleteActivityWithStatReversal('test_activity');

        // Assert
        expect(result.success, false);
        expect(result.errorMessage, contains('Failed to delete activity with stat reversal'));
      });
    });

    group('Successful Deletion with Edge Cases', () {
      test('should successfully delete activity with minimal stat gains', () async {
        // Arrange
        final minimalActivity = ActivityLog.create(
          id: 'minimal_activity',
          activityType: ActivityType.meditation,
          durationMinutes: 1,
          statGains: {StatType.focus: 0.001}, // Very small gain
          expGained: 1.0,
        );

        when(mockActivityRepository.findByKey('minimal_activity')).thenReturn(minimalActivity);
        when(mockUserRepository.getCurrentUser()).thenReturn(testUser);
        when(mockUserRepository.updateUser(any)).thenAnswer((_) async {});
        when(mockActivityRepository.deleteByKey('minimal_activity')).thenAnswer((_) async {});

        // Act
        final result = await activityService.deleteActivityWithStatReversal('minimal_activity');

        // Assert
        expect(result.success, true);
        expect(result.statReversals[StatType.focus], 0.001);
      });

      test('should successfully delete activity causing level-down', () async {
        // Arrange
        final highEXPActivity = ActivityLog.create(
          id: 'high_exp_activity',
          activityType: ActivityType.workoutUpperBody,
          durationMinutes: 600, // 10 hours
          statGains: {StatType.strength: 0.6},
          expGained: 600.0, // High EXP that might cause level-down
        );

        // Set user to have low EXP for current level
        testUser.currentEXP = 100.0;

        when(mockActivityRepository.findByKey('high_exp_activity')).thenReturn(highEXPActivity);
        when(mockUserRepository.getCurrentUser()).thenReturn(testUser);
        when(mockUserRepository.updateUser(any)).thenAnswer((_) async {});
        when(mockActivityRepository.deleteByKey('high_exp_activity')).thenAnswer((_) async {});

        // Act
        final result = await activityService.deleteActivityWithStatReversal('high_exp_activity');

        // Assert
        expect(result.success, true);
        expect(result.leveledDown, true);
        expect(result.newLevel, lessThan(testUser.level));
      });
    });
  });
}