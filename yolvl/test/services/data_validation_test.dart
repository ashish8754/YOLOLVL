import 'package:flutter_test/flutter_test.dart';
import 'package:yolvl/services/exp_service.dart';
import 'package:yolvl/services/stats_service.dart';
import 'package:yolvl/services/degradation_service.dart';
import 'package:yolvl/models/user.dart';
import 'package:yolvl/models/enums.dart';

void main() {
  group('Data Validation and Error Handling', () {
    group('Input Validation', () {
      test('should validate EXP service inputs', () {
        // Test invalid level inputs
        expect(() => EXPService.calculateEXPThreshold(0), throwsArgumentError);
        expect(() => EXPService.calculateEXPThreshold(-1), throwsArgumentError);
        expect(() => EXPService.calculateEXPThreshold(-100), throwsArgumentError);

        // Test invalid EXP inputs
        expect(() => EXPService.calculateEXPGain('workoutUpperBody', -1), throwsArgumentError);
        expect(() => EXPService.calculateEXPGain('workoutUpperBody', -100), throwsArgumentError);

        // Test invalid EXP addition
        final user = User.create(id: 'test', name: 'Test');
        expect(() => EXPService.addEXP(user, -1.0), throwsArgumentError);
        expect(() => EXPService.addEXP(user, -100.0), throwsArgumentError);
      });

      test('should validate stats service inputs', () {
        // Test invalid duration inputs
        expect(() => StatsService.calculateStatGains(ActivityType.workoutUpperBody, -1), 
               throwsArgumentError);
        expect(() => StatsService.calculateStatGains(ActivityType.workoutUpperBody, -100), 
               throwsArgumentError);

        // Test with all activity types to ensure consistency
        for (final activityType in ActivityType.values) {
          expect(() => StatsService.calculateStatGains(activityType, -1), 
                 throwsArgumentError);
        }
      });

      test('should handle null and empty inputs gracefully', () {
        // Test empty stat maps
        final emptyStats = <StatType, double>{};
        final emptyGains = <StatType, double>{};
        
        final result = StatsService.applyStatGains(emptyStats, emptyGains);
        expect(result.length, equals(StatType.values.length));
        
        // All stats should default to 1.0
        for (final statType in StatType.values) {
          expect(result[statType], equals(1.0));
        }

        // Test empty activity list
        final totalGains = StatsService.calculateTotalStatGains([]);
        expect(totalGains, isEmpty);
      });

      test('should validate stat boundaries', () {
        // Test extreme stat values
        final extremeStats = <StatType, double>{
          StatType.strength: double.maxFinite,
          StatType.agility: double.minPositive,
          StatType.endurance: -double.maxFinite,
          StatType.intelligence: 0.0,
          StatType.focus: -1.0,
          StatType.charisma: 1000000.0,
        };

        final validated = StatsService.validateStats(extremeStats);
        
        // Values below minimum should be raised to minimum
        expect(validated[StatType.endurance], equals(1.0));
        expect(validated[StatType.intelligence], equals(1.0));
        expect(validated[StatType.focus], equals(1.0));
        
        // Valid values should be preserved
        expect(validated[StatType.strength], equals(double.maxFinite));
        expect(validated[StatType.charisma], equals(1000000.0));
      });
    });

    group('Data Consistency Validation', () {
      test('should maintain EXP calculation consistency', () {
        // Test that EXP thresholds are monotonically increasing
        for (int level = 1; level < 20; level++) {
          final currentThreshold = EXPService.calculateEXPThreshold(level);
          final nextThreshold = EXPService.calculateEXPThreshold(level + 1);
          
          expect(nextThreshold, greaterThan(currentThreshold));
          expect(currentThreshold.isFinite, isTrue);
          expect(nextThreshold.isFinite, isTrue);
        }
      });

      test('should maintain stat gain consistency across durations', () {
        // Test that stat gains scale linearly with duration
        for (final activityType in ActivityType.values) {
          final gains30 = StatsService.calculateStatGains(activityType, 30);
          final gains60 = StatsService.calculateStatGains(activityType, 60);
          final gains120 = StatsService.calculateStatGains(activityType, 120);

          if (activityType == ActivityType.quitBadHabit) {
            // Quit bad habit should have fixed gains
            for (final statType in gains30.keys) {
              expect(gains30[statType], equals(gains60[statType]));
              expect(gains60[statType], equals(gains120[statType]));
            }
          } else {
            // Other activities should scale linearly
            for (final statType in gains30.keys) {
              expect(gains60[statType], closeTo(gains30[statType]! * 2, 0.001));
              expect(gains120[statType], closeTo(gains30[statType]! * 4, 0.001));
            }
          }
        }
      });

      test('should validate degradation calculation consistency', () {
        // Test that degradation increases with time
        final baseDate = DateTime.now();
        
        for (int days = 3; days <= 15; days += 3) {
          final activityDate = baseDate.subtract(Duration(days: days));
          final degradation = DegradationService.calculateDegradation(
            ActivityCategory.workout,
            activityDate,
          );
          
          expect(degradation, lessThanOrEqualTo(0.0));
          expect(degradation, greaterThanOrEqualTo(-0.05)); // Capped at max
        }
      });

      test('should validate user model consistency', () {
        final user = User.create(id: 'test', name: 'Test');
        
        // Test initial state
        expect(user.level, equals(1));
        expect(user.currentEXP, equals(0.0));
        expect(user.hasCompletedOnboarding, isFalse);
        
        // Test stat operations
        user.setStat(StatType.strength, 2.5);
        expect(user.getStat(StatType.strength), equals(2.5));
        
        user.addToStat(StatType.strength, 0.5);
        expect(user.getStat(StatType.strength), equals(3.0));
        
        // Test EXP operations
        user.currentEXP = 1200.0;
        expect(user.canLevelUp, isTrue);
        
        final excess = user.levelUp();
        expect(user.level, equals(2));
        expect(excess, equals(200.0)); // 1200 - 1000 = 200
      });
    });

    group('Error State Recovery', () {
      test('should recover from invalid user states', () {
        final user = User.create(id: 'test', name: 'Test');
        
        // Set invalid state
        user.level = 0;
        user.currentEXP = -100.0;
        
        // Services should handle gracefully or throw appropriate errors
        expect(() => EXPService.calculateEXPThreshold(user.level), throwsArgumentError);
        
        // Reset to valid state
        user.level = 1;
        user.currentEXP = 0.0;
        
        // Should work normally now
        final threshold = EXPService.calculateEXPThreshold(user.level);
        expect(threshold, equals(1000.0));
      });

      test('should handle corrupted stat data', () {
        final user = User.create(id: 'test', name: 'Test');
        
        // Create stats map with invalid values for validation
        final invalidStats = <StatType, double>{
          StatType.strength: double.nan,
          StatType.agility: double.infinity,
          StatType.endurance: double.negativeInfinity,
          StatType.intelligence: 1.5,
          StatType.focus: 2.0,
          StatType.charisma: 1.8,
        };
        
        final validatedStats = StatsService.validateStats(invalidStats);
        
        // NaN and infinite values should be corrected
        expect(validatedStats[StatType.strength], equals(1.0));
        expect(validatedStats[StatType.agility], equals(1.0));
        expect(validatedStats[StatType.endurance], equals(1.0));
        
        // Valid values should be preserved
        expect(validatedStats[StatType.intelligence], equals(1.5));
        expect(validatedStats[StatType.focus], equals(2.0));
        expect(validatedStats[StatType.charisma], equals(1.8));
      });

      test('should handle missing activity data gracefully', () {
        final user = User.create(id: 'test', name: 'Test');
        
        // User with no activity history
        final degradation = DegradationService.calculateAllDegradation(user);
        expect(degradation, isEmpty);
        
        final warnings = DegradationService.getDegradationWarnings(user);
        expect(warnings, isEmpty);
        
        final hasPending = DegradationService.hasPendingDegradation(user);
        expect(hasPending, isFalse);
      });
    });

    group('Precision and Rounding', () {
      test('should handle floating point precision correctly', () {
        // Test with values that might cause precision issues
        final gains = StatsService.calculateStatGains(ActivityType.workoutUpperBody, 1);
        expect(gains[StatType.strength], closeTo(0.001, 0.0001));
        
        // Test accumulation of small values
        var totalGain = 0.0;
        for (int i = 0; i < 1000; i++) {
          totalGain += 0.001;
        }
        expect(totalGain, closeTo(1.0, 0.01));
      });

      test('should handle EXP precision correctly', () {
        final user = User.create(id: 'test', name: 'Test');
        user.currentEXP = 999.999999;
        user.level = 1;
        
        // Adding tiny amount should trigger level up
        final result = EXPService.addEXP(user, 0.000001);
        expect(result.level, equals(2));
      });

      test('should handle degradation precision', () {
        final user = User.create(id: 'test', name: 'Test');
        user.setStat(StatType.strength, 1.001); // Just above minimum
        
        // Set activity date to trigger degradation
        user.setLastActivityDate(ActivityType.workoutUpperBody, 
            DateTime.now().subtract(const Duration(days: 5)));
        
        final result = DegradationService.applyDegradation(user);
        
        // Should be clamped to minimum
        expect(result.getStat(StatType.strength), equals(1.0));
      });
    });

    group('Concurrent Operations', () {
      test('should handle rapid successive operations', () {
        final user = User.create(id: 'test', name: 'Test');
        user.currentEXP = 0.0;
        user.level = 1;
        
        // Perform many operations in sequence
        var currentUser = user;
        for (int i = 0; i < 100; i++) {
          currentUser = EXPService.addEXP(currentUser, 50.0);
          
          // Verify state remains consistent
          expect(currentUser.level, greaterThanOrEqualTo(1));
          expect(currentUser.currentEXP, greaterThanOrEqualTo(0.0));
          expect(currentUser.currentEXP, 
                 lessThan(EXPService.calculateEXPThreshold(currentUser.level)));
        }
      });

      test('should handle mixed stat operations', () {
        final user = User.create(id: 'test', name: 'Test');
        
        // Perform mixed operations
        for (int i = 0; i < 50; i++) {
          user.addToStat(StatType.strength, 0.01);
          user.addToStat(StatType.agility, 0.02);
          user.addToStat(StatType.endurance, 0.015);
        }
        
        // Verify final values
        expect(user.getStat(StatType.strength), closeTo(1.5, 0.01));
        expect(user.getStat(StatType.agility), closeTo(2.0, 0.01));
        expect(user.getStat(StatType.endurance), closeTo(1.75, 0.01));
      });
    });

    group('Memory and Performance', () {
      test('should handle large datasets efficiently', () {
        // Create large activity list
        final activities = <ActivityLogEntry>[];
        for (int i = 0; i < 10000; i++) {
          activities.add(ActivityLogEntry(
            activityType: ActivityType.values[i % ActivityType.values.length],
            durationMinutes: 60,
            timestamp: DateTime.now().subtract(Duration(hours: i)),
          ));
        }
        
        // This should complete without memory issues
        final totalGains = StatsService.calculateTotalStatGains(activities);
        expect(totalGains, isNotEmpty);
      });

      test('should handle high level calculations efficiently', () {
        // Test high level threshold calculations
        for (int level = 1; level <= 100; level++) {
          final threshold = EXPService.calculateEXPThreshold(level);
          expect(threshold.isFinite, isTrue);
          expect(threshold, greaterThan(0.0));
        }
      });
    });

    group('Edge Case Combinations', () {
      test('should handle user at exact level threshold', () {
        final user = User.create(id: 'test', name: 'Test');
        user.currentEXP = 1000.0; // Exactly at threshold
        user.level = 1;
        
        expect(user.canLevelUp, isTrue);
        
        final excess = user.levelUp();
        expect(user.level, equals(2));
        expect(user.currentEXP, equals(0.0));
        expect(excess, equals(0.0));
      });

      test('should handle stat at exact minimum after degradation', () {
        final user = User.create(id: 'test', name: 'Test');
        user.setStat(StatType.strength, 1.01); // Just above minimum
        
        // Set activity date to trigger maximum degradation
        user.setLastActivityDate(ActivityType.workoutUpperBody, 
            DateTime.now().subtract(const Duration(days: 20)));
        
        final result = DegradationService.applyDegradation(user);
        
        // Should be clamped to minimum
        expect(result.getStat(StatType.strength), equals(1.0));
      });

      test('should handle activity type edge cases', () {
        // Test all activity types with various durations
        final testDurations = [1, 30, 60, 90, 120, 180, 360, 720, 1440];
        
        for (final activityType in ActivityType.values) {
          for (final duration in testDurations) {
            final gains = StatsService.calculateStatGains(activityType, duration);
            
            // All gains should be non-negative
            for (final gain in gains.values) {
              expect(gain, greaterThanOrEqualTo(0.0));
              expect(gain.isFinite, isTrue);
            }
            
            // EXP calculation should work
            final expGain = EXPService.calculateEXPGain(activityType.name, duration);
            expect(expGain, greaterThanOrEqualTo(0.0));
            expect(expGain.isFinite, isTrue);
          }
        }
      });
    });
  });
}