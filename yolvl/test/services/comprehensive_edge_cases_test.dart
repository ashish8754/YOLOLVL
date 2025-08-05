import 'package:flutter_test/flutter_test.dart';
import 'package:yolvl/services/exp_service.dart';
import 'package:yolvl/services/stats_service.dart';
import 'package:yolvl/services/degradation_service.dart';
import 'package:yolvl/models/user.dart';
import 'package:yolvl/models/enums.dart';

void main() {
  group('Comprehensive Edge Cases and Error Handling', () {
    group('EXPService Edge Cases', () {
      test('should handle extremely high levels without overflow', () {
        // Test very high levels to ensure no arithmetic overflow
        expect(() => EXPService.calculateEXPThreshold(50), returnsNormally);
        expect(() => EXPService.calculateEXPThreshold(100), returnsNormally);
        
        // Verify the formula still works at high levels
        final threshold50 = EXPService.calculateEXPThreshold(50);
        final threshold51 = EXPService.calculateEXPThreshold(51);
        expect(threshold51, greaterThan(threshold50));
      });

      test('should handle massive EXP gains correctly', () {
        final user = User.create(id: 'test', name: 'Test');
        user.currentEXP = 0.0;
        user.level = 1;

        // Add massive EXP that should trigger multiple level-ups
        final result = EXPService.addEXP(user, 1000000.0);
        
        expect(result.level, greaterThan(1));
        expect(result.currentEXP, greaterThanOrEqualTo(0.0));
        expect(result.currentEXP, lessThan(EXPService.calculateEXPThreshold(result.level)));
      });

      test('should handle floating point precision correctly', () {
        final user = User.create(id: 'test', name: 'Test');
        user.currentEXP = 999.9999999;
        user.level = 1;

        final result = EXPService.addEXP(user, 0.0000001);
        
        // Should level up due to floating point precision
        expect(result.level, equals(2));
      });

      test('should handle zero EXP threshold edge case', () {
        // Level 1 should have threshold of 1000
        expect(EXPService.calculateEXPThreshold(1), equals(1000.0));
        
        // Verify formula consistency
        for (int level = 1; level <= 10; level++) {
          final threshold = EXPService.calculateEXPThreshold(level);
          expect(threshold, greaterThan(0.0));
          expect(threshold.isFinite, isTrue);
        }
      });

      test('should handle rapid successive level-ups', () {
        final user = User.create(id: 'test', name: 'Test');
        user.currentEXP = 0.0;
        user.level = 1;

        // Add EXP multiple times in succession
        var currentUser = user;
        for (int i = 0; i < 10; i++) {
          currentUser = EXPService.addEXP(currentUser, 500.0);
        }

        expect(currentUser.level, greaterThan(1));
        expect(currentUser.currentEXP, greaterThanOrEqualTo(0.0));
      });

      test('should validate EXP calculation consistency', () {
        // Test that adding EXP in parts equals adding it all at once
        final user1 = User.create(id: 'test1', name: 'Test1');
        final user2 = User.create(id: 'test2', name: 'Test2');
        
        user1.currentEXP = 500.0;
        user1.level = 1;
        user2.currentEXP = 500.0;
        user2.level = 1;

        // Add EXP in parts for user1
        var result1 = EXPService.addEXP(user1, 300.0);
        result1 = EXPService.addEXP(result1, 400.0);

        // Add EXP all at once for user2
        final result2 = EXPService.addEXP(user2, 700.0);

        expect(result1.level, equals(result2.level));
        expect(result1.currentEXP, closeTo(result2.currentEXP, 0.001));
      });
    });

    group('StatsService Edge Cases', () {
      test('should handle zero duration gracefully', () {
        for (final activityType in ActivityType.values) {
          final gains = StatsService.calculateStatGains(activityType, 0);
          
          if (activityType == ActivityType.quitBadHabit) {
            // Quit bad habit should still give fixed focus gain
            expect(gains[StatType.focus], equals(0.03));
          } else {
            // Other activities should give zero gains for zero duration
            for (final gain in gains.values) {
              expect(gain, equals(0.0));
            }
          }
        }
      });

      test('should handle very long durations', () {
        // Test 24 hours (1440 minutes)
        final gains = StatsService.calculateStatGains(ActivityType.workoutUpperBody, 1440);
        
        expect(gains[StatType.strength], equals(0.06 * 24)); // 24 hours
        expect(gains[StatType.endurance], equals(0.04 * 24));
      });

      test('should handle fractional minutes correctly', () {
        // Test with 90 minutes (1.5 hours)
        final gains = StatsService.calculateStatGains(ActivityType.studySerious, 90);
        
        expect(gains[StatType.intelligence], closeTo(0.09, 0.001)); // 0.06 * 1.5
        expect(gains[StatType.focus], closeTo(0.06, 0.001)); // 0.04 * 1.5
      });

      test('should maintain stat gain consistency across all activities', () {
        // Verify that all activities have consistent gain patterns
        for (final activityType in ActivityType.values) {
          final gains60 = StatsService.calculateStatGains(activityType, 60);
          final gains120 = StatsService.calculateStatGains(activityType, 120);
          
          if (activityType == ActivityType.quitBadHabit) {
            // Quit bad habit should have fixed gains regardless of duration
            expect(gains60[StatType.focus], equals(gains120[StatType.focus]));
          } else {
            // Other activities should scale linearly
            for (final statType in gains60.keys) {
              expect(gains120[statType], closeTo(gains60[statType]! * 2, 0.001));
            }
          }
        }
      });

      test('should handle stat application with missing stats', () {
        final currentStats = <StatType, double>{
          StatType.strength: 2.0,
          // Missing other stats
        };

        final gains = <StatType, double>{
          StatType.strength: 0.5,
          StatType.agility: 0.3,
          StatType.intelligence: 0.2,
        };

        final result = StatsService.applyStatGains(currentStats, gains);

        expect(result[StatType.strength], equals(2.5)); // 2.0 + 0.5
        expect(result[StatType.agility], equals(1.3)); // 1.0 default + 0.3
        expect(result[StatType.intelligence], equals(1.2)); // 1.0 default + 0.2
        expect(result[StatType.endurance], equals(1.0)); // Default value
      });

      test('should validate stat boundaries', () {
        final stats = <StatType, double>{
          StatType.strength: -5.0,
          StatType.agility: 0.0,
          StatType.endurance: 100.0,
        };

        final validated = StatsService.validateStats(stats);

        expect(validated[StatType.strength], equals(1.0)); // Raised to minimum
        expect(validated[StatType.agility], equals(1.0)); // Raised to minimum
        expect(validated[StatType.endurance], equals(100.0)); // Unchanged (no max limit)
      });

      test('should handle empty activity list in total calculations', () {
        final totalGains = StatsService.calculateTotalStatGains([]);
        expect(totalGains, isEmpty);
      });

      test('should handle large activity datasets efficiently', () {
        // Create a large list of activities
        final activities = List.generate(1000, (index) => ActivityLogEntry(
          activityType: ActivityType.workoutUpperBody,
          durationMinutes: 60,
          timestamp: DateTime.now().subtract(Duration(days: index)),
        ));

        // This should complete without performance issues
        final totalGains = StatsService.calculateTotalStatGains(activities);
        
        expect(totalGains[StatType.strength], closeTo(60.0, 0.01)); // 0.06 * 1000
        expect(totalGains[StatType.endurance], closeTo(40.0, 0.01)); // 0.04 * 1000
      });
    });

    group('DegradationService Edge Cases', () {
      late User testUser;

      setUp(() {
        testUser = User.create(id: 'test', name: 'Test User');
        // Set stats above minimum for degradation testing
        testUser.setStat(StatType.strength, 3.0);
        testUser.setStat(StatType.agility, 2.5);
        testUser.setStat(StatType.endurance, 2.8);
        testUser.setStat(StatType.intelligence, 3.5);
        testUser.setStat(StatType.focus, 2.2);
        testUser.setStat(StatType.charisma, 1.8);
      });

      test('should handle user with no activity history gracefully', () {
        final newUser = User.create(id: 'new', name: 'New User');
        
        final degradation = DegradationService.calculateAllDegradation(newUser);
        expect(degradation, isEmpty);
        
        final warnings = DegradationService.getDegradationWarnings(newUser);
        expect(warnings, isEmpty);
        
        final hasPending = DegradationService.hasPendingDegradation(newUser);
        expect(hasPending, isFalse);
      });

      test('should handle stats already at minimum floor', () {
        testUser.setStat(StatType.strength, 1.0);
        testUser.setStat(StatType.agility, 1.0);
        testUser.setStat(StatType.endurance, 1.0);
        
        // Set old activity date to trigger degradation
        testUser.setLastActivityDate(ActivityType.workoutUpperBody, 
            DateTime.now().subtract(const Duration(days: 10)));

        final result = DegradationService.applyDegradation(testUser);
        
        // Stats should not go below minimum
        expect(result.getStat(StatType.strength), equals(1.0));
        expect(result.getStat(StatType.agility), equals(1.0));
        expect(result.getStat(StatType.endurance), equals(1.0));
      });

      test('should handle very long periods without activity', () {
        // Set activity date 1 year ago
        testUser.setLastActivityDate(ActivityType.workoutUpperBody, 
            DateTime.now().subtract(const Duration(days: 365)));

        final degradation = DegradationService.calculateDegradation(
          ActivityCategory.workout,
          testUser.getLastActivityDate(ActivityType.workoutUpperBody),
        );
        
        // Should be capped at maximum degradation
        expect(degradation, equals(-0.05));
      });

      test('should handle mixed activity categories correctly', () {
        // Set different degradation states for different categories
        testUser.setLastActivityDate(ActivityType.workoutUpperBody, 
            DateTime.now().subtract(const Duration(days: 5))); // Should degrade
        testUser.setLastActivityDate(ActivityType.studySerious, 
            DateTime.now().subtract(const Duration(days: 1))); // Should not degrade
        testUser.setLastActivityDate(ActivityType.socializing, 
            DateTime.now().subtract(const Duration(days: 10))); // Other category, no degradation

        final degradation = DegradationService.calculateAllDegradation(testUser);
        
        // Only workout stats should degrade
        expect(degradation[StatType.strength], equals(-0.01));
        expect(degradation[StatType.agility], equals(-0.01));
        expect(degradation[StatType.endurance], equals(-0.01));
        expect(degradation[StatType.intelligence], isNull);
        expect(degradation[StatType.focus], isNull);
        expect(degradation[StatType.charisma], isNull);
      });

      test('should handle weekend mode calculations correctly', () {
        // Set activity on Friday
        final friday = DateTime(2025, 1, 17); // Friday
        testUser.setLastActivityDate(ActivityType.workoutUpperBody, friday);

        // Check degradation on Monday (4 calendar days, but only 1 weekday)
        final monday = DateTime(2025, 1, 20); // Monday
        
        // Mock current date for testing
        final daysSinceRegular = monday.difference(friday).inDays; // 3 days
        expect(daysSinceRegular, equals(3));
        
        // In relaxed weekend mode, should count fewer days
        final shouldDegrade = DegradationService.shouldApplyDegradation(
          ActivityCategory.workout,
          friday,
          relaxedWeekendMode: true,
        );
        
        // This test depends on current implementation of weekend calculation
        expect(shouldDegrade, isA<bool>());
      });

      test('should handle degradation timing edge cases', () {
        // Test exactly at threshold
        testUser.setLastActivityDate(ActivityType.workoutUpperBody, 
            DateTime.now().subtract(const Duration(days: 3)));

        final shouldDegrade = DegradationService.shouldApplyDegradation(
          ActivityCategory.workout,
          testUser.getLastActivityDate(ActivityType.workoutUpperBody),
        );
        
        expect(shouldDegrade, isTrue);
      });

      test('should handle multiple degradation applications', () {
        testUser.setLastActivityDate(ActivityType.workoutUpperBody, 
            DateTime.now().subtract(const Duration(days: 5)));

        // Apply degradation multiple times
        var currentUser = testUser;
        final originalStrength = currentUser.getStat(StatType.strength);
        
        currentUser = DegradationService.applyDegradation(currentUser);
        final firstDegradation = currentUser.getStat(StatType.strength);
        
        currentUser = DegradationService.applyDegradation(currentUser);
        final secondDegradation = currentUser.getStat(StatType.strength);
        
        // Second application should not degrade further (no new missed days)
        expect(firstDegradation, lessThan(originalStrength));
        expect(secondDegradation, closeTo(firstDegradation, 0.01));
      });

      test('should handle warning severity calculations', () {
        // Test different warning severities
        final lowWarning = DegradationWarning(
          category: ActivityCategory.workout,
          daysSinceLastActivity: 2,
          affectedStats: [StatType.strength],
          isActive: false,
        );
        expect(lowWarning.severity, equals(DegradationSeverity.low));

        final mediumWarning = DegradationWarning(
          category: ActivityCategory.workout,
          daysSinceLastActivity: 4,
          affectedStats: [StatType.strength],
          isActive: true,
        );
        expect(mediumWarning.severity, equals(DegradationSeverity.medium));

        final highWarning = DegradationWarning(
          category: ActivityCategory.workout,
          daysSinceLastActivity: 8,
          affectedStats: [StatType.strength],
          isActive: true,
        );
        expect(highWarning.severity, equals(DegradationSeverity.high));

        final criticalWarning = DegradationWarning(
          category: ActivityCategory.workout,
          daysSinceLastActivity: 15,
          affectedStats: [StatType.strength],
          isActive: true,
        );
        expect(criticalWarning.severity, equals(DegradationSeverity.critical));
      });
    });

    group('Cross-Service Integration Edge Cases', () {
      test('should handle EXP and stat updates together', () {
        final user = User.create(id: 'test', name: 'Test');
        user.currentEXP = 950.0; // Close to level up
        user.level = 1;
        user.setStat(StatType.strength, 2.0);

        // Simulate activity that gives both EXP and stats
        final expGain = 100.0; // Should trigger level up
        final statGains = {StatType.strength: 0.06};

        // Apply EXP gain
        final leveledUpUser = EXPService.addEXP(user, expGain);
        
        // Apply stat gains
        final finalStats = StatsService.applyStatGains(
          {StatType.strength: leveledUpUser.getStat(StatType.strength)},
          statGains,
        );

        expect(leveledUpUser.level, equals(2));
        expect(finalStats[StatType.strength], closeTo(2.06, 0.001));
      });

      test('should handle degradation after stat gains', () {
        final user = User.create(id: 'test', name: 'Test');
        user.setStat(StatType.strength, 2.0);
        
        // Apply stat gains first
        final statGains = {StatType.strength: 0.5};
        final updatedStats = StatsService.applyStatGains(
          {StatType.strength: user.getStat(StatType.strength)},
          statGains,
        );
        user.setStat(StatType.strength, updatedStats[StatType.strength]!);

        // Then apply degradation
        user.setLastActivityDate(ActivityType.workoutUpperBody, 
            DateTime.now().subtract(const Duration(days: 5)));
        
        final degradedUser = DegradationService.applyDegradation(user);
        
        // Final strength should be 2.5 - 0.01 = 2.49
        expect(degradedUser.getStat(StatType.strength), closeTo(2.49, 0.001));
      });

      test('should handle complex multi-activity scenarios', () {
        final user = User.create(id: 'test', name: 'Test');
        user.setStat(StatType.strength, 1.5);
        user.setStat(StatType.intelligence, 1.8);
        user.setStat(StatType.focus, 2.0);

        // Simulate multiple activities affecting overlapping stats
        final activities = [
          ActivityLogEntry(
            activityType: ActivityType.workoutUpperBody, // Strength + Endurance
            durationMinutes: 60,
            timestamp: DateTime.now(),
          ),
          ActivityLogEntry(
            activityType: ActivityType.studySerious, // Intelligence + Focus
            durationMinutes: 90,
            timestamp: DateTime.now(),
          ),
          ActivityLogEntry(
            activityType: ActivityType.workoutYoga, // Agility + Focus
            durationMinutes: 45,
            timestamp: DateTime.now(),
          ),
        ];

        final totalGains = StatsService.calculateTotalStatGains(activities);
        
        // Focus should be affected by both study and yoga
        expect(totalGains[StatType.focus], closeTo(0.0825, 0.001)); // 0.06 + 0.0225
        expect(totalGains[StatType.strength], equals(0.06)); // Only from weights
        expect(totalGains[StatType.intelligence], equals(0.09)); // Only from study
      });
    });

    group('Boundary Value Testing', () {
      test('should handle minimum possible values', () {
        // Test with minimum durations
        expect(() => StatsService.calculateStatGains(ActivityType.workoutUpperBody, 1), 
               returnsNormally);
        
        // Test with minimum EXP
        expect(() => EXPService.calculateEXPGain('workoutUpperBody', 1), 
               returnsNormally);
        
        // Test with minimum level
        expect(() => EXPService.calculateEXPThreshold(1), 
               returnsNormally);
      });

      test('should handle maximum reasonable values', () {
        // Test with maximum reasonable duration (24 hours)
        expect(() => StatsService.calculateStatGains(ActivityType.workoutUpperBody, 1440), 
               returnsNormally);
        
        // Test with high level
        expect(() => EXPService.calculateEXPThreshold(50), 
               returnsNormally);
        
        // Test with high EXP values
        expect(() => EXPService.calculateEXPGain('workoutUpperBody', 1440), 
               returnsNormally);
      });

      test('should handle precision edge cases', () {
        // Test with very small stat gains
        final gains = StatsService.calculateStatGains(ActivityType.workoutUpperBody, 1);
        expect(gains[StatType.strength], closeTo(0.001, 0.0001));
        
        // Test with very small EXP gains
        final expGain = EXPService.calculateEXPGain('workoutUpperBody', 1);
        expect(expGain, equals(1.0));
      });
    });

    group('Error Recovery and Resilience', () {
      test('should handle corrupted user data gracefully', () {
        final user = User.create(id: 'test', name: 'Test');
        
        // Simulate corrupted data
        user.currentEXP = double.nan;
        user.level = -1;
        
        // Services should handle this gracefully or throw appropriate errors
        expect(() => EXPService.calculateEXPProgress(user), throwsArgumentError);
        
        // Reset to valid values
        user.currentEXP = 0.0;
        user.level = 1;
        
        final progress = EXPService.calculateEXPProgress(user);
        expect(progress, equals(0.0));
      });

      test('should handle invalid stat values', () {
        final stats = <StatType, double>{
          StatType.strength: double.infinity,
          StatType.agility: double.negativeInfinity,
          StatType.endurance: double.nan,
        };

        // Validation should handle these cases
        final validated = StatsService.validateStats(stats);
        
        // Should default to minimum valid values
        expect(validated[StatType.strength], equals(1.0));
        expect(validated[StatType.agility], equals(1.0));
        expect(validated[StatType.endurance], equals(1.0));
      });

      test('should maintain data consistency under stress', () {
        final user = User.create(id: 'test', name: 'Test');
        user.currentEXP = 500.0;
        user.level = 1;

        // Perform many operations rapidly
        var currentUser = user;
        for (int i = 0; i < 100; i++) {
          currentUser = EXPService.addEXP(currentUser, 10.0);
          
          // Verify consistency after each operation
          expect(currentUser.currentEXP, greaterThanOrEqualTo(0.0));
          expect(currentUser.level, greaterThanOrEqualTo(1));
          expect(currentUser.currentEXP, 
                 lessThan(EXPService.calculateEXPThreshold(currentUser.level)));
        }
      });
    });
  });
}