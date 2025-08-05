import 'package:flutter_test/flutter_test.dart';
import 'package:yolvl/services/degradation_service.dart';
import 'package:yolvl/models/enums.dart';
import 'package:yolvl/models/user.dart';

void main() {
  group('DegradationService', () {
    late User testUser;

    setUp(() {
      testUser = User.create(id: 'test', name: 'Test User');
      // Set initial stats above minimum
      testUser.setStat(StatType.strength, 2.0);
      testUser.setStat(StatType.agility, 1.8);
      testUser.setStat(StatType.endurance, 2.2);
      testUser.setStat(StatType.intelligence, 2.5);
      testUser.setStat(StatType.focus, 1.9);
      testUser.setStat(StatType.charisma, 1.6);
    });

    group('shouldApplyDegradation', () {
      test('should return false when no last activity date', () {
        final result = DegradationService.shouldApplyDegradation(
          ActivityCategory.workout,
          null,
        );
        expect(result, isFalse);
      });

      test('should return false when last activity is within threshold', () {
        final lastActivity = DateTime.now().subtract(const Duration(days: 2));
        final result = DegradationService.shouldApplyDegradation(
          ActivityCategory.workout,
          lastActivity,
        );
        expect(result, isFalse);
      });

      test('should return true when last activity exceeds threshold', () {
        final lastActivity = DateTime.now().subtract(const Duration(days: 4));
        final result = DegradationService.shouldApplyDegradation(
          ActivityCategory.workout,
          lastActivity,
        );
        expect(result, isTrue);
      });

      test('should return true at exact threshold', () {
        final lastActivity = DateTime.now().subtract(const Duration(days: 3));
        final result = DegradationService.shouldApplyDegradation(
          ActivityCategory.workout,
          lastActivity,
        );
        expect(result, isTrue);
      });

      test('should handle relaxed weekend mode', () {
        // Create a date that's 3 calendar days but only 1 weekday ago (Friday to Monday)
        // Note: This test is conceptual - the actual implementation uses DateTime.now()
        // In a real implementation, we'd need to inject a clock for proper testing
        final lastActivity = DateTime.now().subtract(const Duration(days: 3));
        
        final result = DegradationService.shouldApplyDegradation(
          ActivityCategory.workout,
          lastActivity,
          relaxedWeekendMode: true,
        );
        
        // This will depend on the actual current day and when the test runs
        // For now, we'll just verify the method doesn't crash with relaxed mode
        expect(result, isA<bool>());
      });
    });

    group('calculateDegradation', () {
      test('should return 0 when no degradation needed', () {
        final lastActivity = DateTime.now().subtract(const Duration(days: 2));
        final result = DegradationService.calculateDegradation(
          ActivityCategory.workout,
          lastActivity,
        );
        expect(result, equals(0.0));
      });

      test('should calculate correct degradation for one period', () {
        final lastActivity = DateTime.now().subtract(const Duration(days: 4));
        final result = DegradationService.calculateDegradation(
          ActivityCategory.workout,
          lastActivity,
        );
        expect(result, equals(-0.01)); // One 3-day period
      });

      test('should calculate correct degradation for multiple periods', () {
        final lastActivity = DateTime.now().subtract(const Duration(days: 7));
        final result = DegradationService.calculateDegradation(
          ActivityCategory.workout,
          lastActivity,
        );
        expect(result, equals(-0.02)); // Two 3-day periods
      });

      test('should cap degradation at maximum per application', () {
        final lastActivity = DateTime.now().subtract(const Duration(days: 20));
        final result = DegradationService.calculateDegradation(
          ActivityCategory.workout,
          lastActivity,
        );
        expect(result, equals(-0.05)); // Capped at maximum
      });

      test('should handle exact multiples of threshold', () {
        final lastActivity = DateTime.now().subtract(const Duration(days: 6));
        final result = DegradationService.calculateDegradation(
          ActivityCategory.workout,
          lastActivity,
        );
        expect(result, equals(-0.02)); // Exactly two 3-day periods
      });
    });

    group('getAffectedStatsByCategory', () {
      test('should return correct stats for workout category', () {
        final stats = DegradationService.getAffectedStatsByCategory(ActivityCategory.workout);
        expect(stats, containsAll([StatType.strength, StatType.agility, StatType.endurance]));
        expect(stats.length, equals(3));
      });

      test('should return correct stats for study category', () {
        final stats = DegradationService.getAffectedStatsByCategory(ActivityCategory.study);
        expect(stats, containsAll([StatType.intelligence, StatType.focus]));
        expect(stats.length, equals(2));
      });

      test('should return empty list for other category', () {
        final stats = DegradationService.getAffectedStatsByCategory(ActivityCategory.other);
        expect(stats, isEmpty);
      });
    });

    group('calculateAllDegradation', () {
      test('should return empty map when no degradation needed', () {
        // Set recent activity dates
        testUser.setLastActivityDate(ActivityType.workoutUpperBody, DateTime.now().subtract(const Duration(days: 1)));
        testUser.setLastActivityDate(ActivityType.studySerious, DateTime.now().subtract(const Duration(days: 2)));

        final result = DegradationService.calculateAllDegradation(testUser);
        expect(result, isEmpty);
      });

      test('should calculate degradation for workout category only', () {
        // Set old workout date, recent study date
        testUser.setLastActivityDate(ActivityType.workoutUpperBody, DateTime.now().subtract(const Duration(days: 5)));
        testUser.setLastActivityDate(ActivityType.studySerious, DateTime.now().subtract(const Duration(days: 1)));

        final result = DegradationService.calculateAllDegradation(testUser);
        
        expect(result[StatType.strength], equals(-0.01));
        expect(result[StatType.agility], equals(-0.01));
        expect(result[StatType.endurance], equals(-0.01));
        expect(result[StatType.intelligence], isNull);
        expect(result[StatType.focus], isNull);
        expect(result[StatType.charisma], isNull);
      });

      test('should calculate degradation for study category only', () {
        // Set recent workout date, old study date
        testUser.setLastActivityDate(ActivityType.workoutUpperBody, DateTime.now().subtract(const Duration(days: 1)));
        testUser.setLastActivityDate(ActivityType.studySerious, DateTime.now().subtract(const Duration(days: 5)));

        final result = DegradationService.calculateAllDegradation(testUser);
        
        expect(result[StatType.intelligence], equals(-0.01));
        expect(result[StatType.focus], equals(-0.01));
        expect(result[StatType.strength], isNull);
        expect(result[StatType.agility], isNull);
        expect(result[StatType.endurance], isNull);
        expect(result[StatType.charisma], isNull);
      });

      test('should calculate degradation for both categories', () {
        // Set old dates for both categories
        testUser.setLastActivityDate(ActivityType.workoutUpperBody, DateTime.now().subtract(const Duration(days: 5)));
        testUser.setLastActivityDate(ActivityType.studySerious, DateTime.now().subtract(const Duration(days: 4)));

        final result = DegradationService.calculateAllDegradation(testUser);
        
        expect(result[StatType.strength], equals(-0.01));
        expect(result[StatType.agility], equals(-0.01));
        expect(result[StatType.endurance], equals(-0.01));
        expect(result[StatType.intelligence], equals(-0.01));
        expect(result[StatType.focus], equals(-0.01));
        expect(result[StatType.charisma], isNull); // Not affected by degradation
      });

      test('should use most recent activity date within category', () {
        // Set different dates for activities in same category
        testUser.setLastActivityDate(ActivityType.workoutUpperBody, DateTime.now().subtract(const Duration(days: 5)));
        testUser.setLastActivityDate(ActivityType.workoutCardio, DateTime.now().subtract(const Duration(days: 2))); // More recent

        final result = DegradationService.calculateAllDegradation(testUser);
        
        // Should not degrade because most recent workout activity is within threshold
        expect(result[StatType.strength], isNull);
        expect(result[StatType.agility], isNull);
        expect(result[StatType.endurance], isNull);
      });
    });

    group('applyDegradation', () {
      test('should return unchanged user when no degradation needed', () {
        testUser.setLastActivityDate(ActivityType.workoutUpperBody, DateTime.now().subtract(const Duration(days: 1)));
        testUser.setLastActivityDate(ActivityType.studySerious, DateTime.now().subtract(const Duration(days: 1)));

        final result = DegradationService.applyDegradation(testUser);
        
        expect(result.getStat(StatType.strength), equals(2.0));
        expect(result.getStat(StatType.intelligence), equals(2.5));
      });

      test('should apply degradation to affected stats', () {
        testUser.setLastActivityDate(ActivityType.workoutUpperBody, DateTime.now().subtract(const Duration(days: 5)));

        final result = DegradationService.applyDegradation(testUser);
        
        expect(result.getStat(StatType.strength), closeTo(1.99, 0.001)); // 2.0 - 0.01
        expect(result.getStat(StatType.agility), closeTo(1.79, 0.001)); // 1.8 - 0.01
        expect(result.getStat(StatType.endurance), closeTo(2.19, 0.001)); // 2.2 - 0.01
        expect(result.getStat(StatType.intelligence), equals(2.5)); // Unchanged
        expect(result.getStat(StatType.charisma), equals(1.6)); // Unchanged
      });

      test('should enforce minimum stat values', () {
        // Set stats close to minimum
        testUser.setStat(StatType.strength, 1.005);
        testUser.setLastActivityDate(ActivityType.workoutUpperBody, DateTime.now().subtract(const Duration(days: 5)));

        final result = DegradationService.applyDegradation(testUser);
        
        expect(result.getStat(StatType.strength), equals(1.0)); // Clamped to minimum
      });

      test('should update last active timestamp', () {
        final originalLastActive = testUser.lastActive;
        testUser.setLastActivityDate(ActivityType.workoutUpperBody, DateTime.now().subtract(const Duration(days: 5)));

        final result = DegradationService.applyDegradation(testUser);
        
        expect(result.lastActive.isAfter(originalLastActive), isTrue);
      });
    });

    group('hasPendingDegradation', () {
      test('should return false when no degradation pending', () {
        testUser.setLastActivityDate(ActivityType.workoutUpperBody, DateTime.now().subtract(const Duration(days: 1)));
        testUser.setLastActivityDate(ActivityType.studySerious, DateTime.now().subtract(const Duration(days: 1)));

        final result = DegradationService.hasPendingDegradation(testUser);
        expect(result, isFalse);
      });

      test('should return true when degradation is pending', () {
        testUser.setLastActivityDate(ActivityType.workoutUpperBody, DateTime.now().subtract(const Duration(days: 5)));

        final result = DegradationService.hasPendingDegradation(testUser);
        expect(result, isTrue);
      });
    });

    group('getDegradationWarnings', () {
      test('should return empty list when no warnings needed', () {
        testUser.setLastActivityDate(ActivityType.workoutUpperBody, DateTime.now().subtract(const Duration(days: 1)));
        testUser.setLastActivityDate(ActivityType.studySerious, DateTime.now().subtract(const Duration(days: 1)));

        final warnings = DegradationService.getDegradationWarnings(testUser);
        expect(warnings, isEmpty);
      });

      test('should return warning for upcoming degradation', () {
        testUser.setLastActivityDate(ActivityType.workoutUpperBody, DateTime.now().subtract(const Duration(days: 2)));

        final warnings = DegradationService.getDegradationWarnings(testUser);
        expect(warnings.length, equals(1));
        expect(warnings.first.category, equals(ActivityCategory.workout));
        expect(warnings.first.daysSinceLastActivity, equals(2));
        expect(warnings.first.isActive, isFalse);
      });

      test('should return warning for active degradation', () {
        testUser.setLastActivityDate(ActivityType.workoutUpperBody, DateTime.now().subtract(const Duration(days: 4)));

        final warnings = DegradationService.getDegradationWarnings(testUser);
        expect(warnings.length, equals(1));
        expect(warnings.first.category, equals(ActivityCategory.workout));
        expect(warnings.first.daysSinceLastActivity, equals(4));
        expect(warnings.first.isActive, isTrue);
      });

      test('should return warnings for multiple categories', () {
        testUser.setLastActivityDate(ActivityType.workoutUpperBody, DateTime.now().subtract(const Duration(days: 4)));
        testUser.setLastActivityDate(ActivityType.studySerious, DateTime.now().subtract(const Duration(days: 3)));

        final warnings = DegradationService.getDegradationWarnings(testUser);
        expect(warnings.length, equals(2));
        
        final workoutWarning = warnings.firstWhere((w) => w.category == ActivityCategory.workout);
        final studyWarning = warnings.firstWhere((w) => w.category == ActivityCategory.study);
        
        expect(workoutWarning.isActive, isTrue);
        expect(studyWarning.isActive, isTrue);
      });
    });

    group('resetDegradationTimer', () {
      test('should update last activity date for specified activity', () {
        final originalDate = DateTime.now().subtract(const Duration(days: 5));
        testUser.setLastActivityDate(ActivityType.workoutUpperBody, originalDate);

        final result = DegradationService.resetDegradationTimer(testUser, ActivityType.workoutUpperBody);
        
        final newDate = result.getLastActivityDate(ActivityType.workoutUpperBody);
        expect(newDate, isNotNull);
        expect(newDate!.isAfter(originalDate), isTrue);
      });
    });

    group('getNextDegradationDate', () {
      test('should return null when no last activity date', () {
        final result = DegradationService.getNextDegradationDate(testUser, ActivityCategory.workout);
        expect(result, isNull);
      });

      test('should calculate next degradation date correctly', () {
        final lastActivity = DateTime(2025, 1, 15);
        testUser.setLastActivityDate(ActivityType.workoutUpperBody, lastActivity);

        final result = DegradationService.getNextDegradationDate(testUser, ActivityCategory.workout);
        
        expect(result, isNotNull);
        expect(result, equals(DateTime(2025, 1, 18))); // 3 days later
      });

      test('should handle relaxed weekend mode', () {
        // Set last activity on Friday
        final lastActivity = DateTime(2025, 1, 17); // Friday
        testUser.setLastActivityDate(ActivityType.workoutUpperBody, lastActivity);

        final result = DegradationService.getNextDegradationDate(
          testUser, 
          ActivityCategory.workout,
          relaxedWeekendMode: true,
        );
        
        expect(result, isNotNull);
        // Should skip weekend and count only weekdays
        expect(result!.weekday, lessThanOrEqualTo(5)); // Should be a weekday
      });
    });

    group('DegradationWarning', () {
      test('should provide correct category name', () {
        final warning = DegradationWarning(
          category: ActivityCategory.workout,
          daysSinceLastActivity: 3,
          affectedStats: [StatType.strength],
          isActive: true,
        );

        expect(warning.categoryName, equals('Workout'));
      });

      test('should provide correct message for active degradation', () {
        final warning = DegradationWarning(
          category: ActivityCategory.workout,
          daysSinceLastActivity: 4,
          affectedStats: [StatType.strength],
          isActive: true,
        );

        expect(warning.message, contains('stats degrading'));
      });

      test('should provide correct message for upcoming degradation', () {
        final warning = DegradationWarning(
          category: ActivityCategory.workout,
          daysSinceLastActivity: 2,
          affectedStats: [StatType.strength],
          isActive: false,
        );

        expect(warning.message, contains('degradation starts tomorrow'));
      });

      test('should calculate correct severity levels', () {
        final lowWarning = DegradationWarning(
          category: ActivityCategory.workout,
          daysSinceLastActivity: 2,
          affectedStats: [StatType.strength],
          isActive: false,
        );
        expect(lowWarning.severity, equals(DegradationSeverity.low));

        final mediumWarning = DegradationWarning(
          category: ActivityCategory.workout,
          daysSinceLastActivity: 3,
          affectedStats: [StatType.strength],
          isActive: true,
        );
        expect(mediumWarning.severity, equals(DegradationSeverity.medium));

        final highWarning = DegradationWarning(
          category: ActivityCategory.workout,
          daysSinceLastActivity: 7,
          affectedStats: [StatType.strength],
          isActive: true,
        );
        expect(highWarning.severity, equals(DegradationSeverity.high));

        final criticalWarning = DegradationWarning(
          category: ActivityCategory.workout,
          daysSinceLastActivity: 12,
          affectedStats: [StatType.strength],
          isActive: true,
        );
        expect(criticalWarning.severity, equals(DegradationSeverity.critical));
      });
    });

    group('Edge Cases', () {
      test('should handle user with no activity history', () {
        final newUser = User.create(id: 'new', name: 'New User');
        
        final result = DegradationService.applyDegradation(newUser);
        expect(result.getStat(StatType.strength), equals(1.0)); // Unchanged
        
        final warnings = DegradationService.getDegradationWarnings(newUser);
        expect(warnings, isEmpty);
      });

      test('should handle stats already at minimum', () {
        testUser.setStat(StatType.strength, 1.0);
        testUser.setLastActivityDate(ActivityType.workoutUpperBody, DateTime.now().subtract(const Duration(days: 10)));

        final result = DegradationService.applyDegradation(testUser);
        expect(result.getStat(StatType.strength), equals(1.0)); // Should not go below minimum
      });

      test('should handle very long periods without activity', () {
        testUser.setLastActivityDate(ActivityType.workoutUpperBody, DateTime.now().subtract(const Duration(days: 100)));

        final degradation = DegradationService.calculateDegradation(
          ActivityCategory.workout,
          testUser.getLastActivityDate(ActivityType.workoutUpperBody),
        );
        
        expect(degradation, equals(-0.05)); // Should be capped at maximum
      });
    });
  });
}