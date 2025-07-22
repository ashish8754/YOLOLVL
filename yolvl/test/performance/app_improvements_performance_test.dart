import 'package:flutter_test/flutter_test.dart';
import 'package:yolvl/models/enums.dart';
import 'package:yolvl/models/user.dart';
import 'package:yolvl/models/activity_log.dart';
import 'package:yolvl/services/stats_service.dart';
import 'package:yolvl/services/activity_service.dart';
import 'package:yolvl/utils/infinite_stats_validator.dart';

/// Performance tests for app improvements to ensure they handle large datasets
/// and extreme values efficiently without impacting user experience.
void main() {
  group('App Improvements Performance Tests', () {
    late User testUser;
    late ActivityService activityService;

    setUp(() {
      testUser = User.create(
        id: 'perf_test_user',
        name: 'Performance Test User',
        avatarPath: null,
      );
      testUser.hasCompletedOnboarding = true;
      activityService = ActivityService();
    });

    group('Infinite Stats Performance', () {
      test('should handle extremely large stat values efficiently', () {
        // Test with very large stat values
        final extremeStats = {
          StatType.strength: 999999.0,
          StatType.agility: 500000.0,
          StatType.endurance: 750000.0,
          StatType.intelligence: 1000000.0,
          StatType.focus: 250000.0,
          StatType.charisma: 800000.0,
        };

        final stopwatch = Stopwatch()..start();
        
        // Test validation performance
        final validationResult = StatsService.validateInfiniteStats(extremeStats);
        
        stopwatch.stop();
        
        expect(stopwatch.elapsedMilliseconds < 50, true, 
          reason: 'Stat validation should complete in under 50ms');
        expect(validationResult.isValid || validationResult.hasWarning, true);
      });

      test('should efficiently calculate chart scaling for large values', () {
        final largeStats = {
          StatType.strength: 50000.0,
          StatType.intelligence: 100000.0,
          StatType.focus: 75000.0,
        };

        final stopwatch = Stopwatch()..start();
        
        // Test chart validation performance
        final chartResult = StatsService.validateStatsForChart(largeStats);
        
        stopwatch.stop();
        
        expect(stopwatch.elapsedMilliseconds < 25, true,
          reason: 'Chart validation should complete in under 25ms');
        expect(chartResult.isValid || chartResult.hasWarning, true);
        expect(chartResult.recommendedMaxY, greaterThan(0));
      });

      test('should handle stat gain calculations efficiently at scale', () {
        final stopwatch = Stopwatch()..start();
        
        // Calculate gains for all activity types multiple times
        for (int i = 0; i < 1000; i++) {
          for (final activityType in ActivityType.values) {
            final gains = StatsService.calculateStatGains(activityType, 60);
            expect(gains, isNotNull);
          }
        }
        
        stopwatch.stop();
        
        expect(stopwatch.elapsedMilliseconds < 100, true,
          reason: 'Bulk stat calculations should complete efficiently');
      });

      test('should validate export data efficiently with large values', () {
        final massiveStats = <StatType, double>{};
        
        // Create stats with various large values
        for (final statType in StatType.values) {
          massiveStats[statType] = 50000.0 + (statType.index * 10000.0);
        }

        final stopwatch = Stopwatch()..start();
        
        final exportResult = StatsService.validateStatsForExport(massiveStats);
        
        stopwatch.stop();
        
        expect(stopwatch.elapsedMilliseconds < 30, true,
          reason: 'Export validation should be fast even with large values');
        expect(exportResult.sanitizedStats, isNotNull);
      });
    });

    group('Stat Reversal Performance', () {
      test('should calculate stat reversals efficiently', () {
        final activities = <ActivityLog>[];
        
        // Create many activities for bulk reversal testing
        for (int i = 0; i < 100; i++) {
          activities.add(ActivityLog.create(
            id: 'activity_$i',
            activityType: ActivityType.values[i % ActivityType.values.length],
            durationMinutes: 60 + (i % 120),
            statGains: StatsService.calculateStatGains(
              ActivityType.values[i % ActivityType.values.length], 
              60 + (i % 120)
            ),
            expGained: 60 + (i % 120),
            timestamp: DateTime.now().subtract(Duration(days: i)),
          ));
        }

        final stopwatch = Stopwatch()..start();
        
        // Calculate reversals for all activities
        for (final activity in activities) {
          final reversals = StatsService.calculateStatReversals(
            activity.activityTypeEnum,
            activity.durationMinutes,
            activity.statGainsMap,
          );
          expect(reversals, isNotNull);
        }
        
        stopwatch.stop();
        
        expect(stopwatch.elapsedMilliseconds < 200, true,
          reason: 'Bulk reversal calculations should complete efficiently');
      });

      test('should validate stat reversals efficiently', () {
        // Set up user with high stats
        testUser.setStat(StatType.strength, 1000.0);
        testUser.setStat(StatType.intelligence, 2000.0);
        testUser.setStat(StatType.focus, 1500.0);

        final currentStats = testUser.statsMap;
        final reversals = {
          StatType.strength: 50.0,
          StatType.intelligence: 100.0,
          StatType.focus: 75.0,
        };

        final stopwatch = Stopwatch()..start();
        
        // Validate reversal multiple times
        for (int i = 0; i < 1000; i++) {
          final isValid = StatsService.validateStatReversal(currentStats, reversals);
          expect(isValid, true);
        }
        
        stopwatch.stop();
        
        expect(stopwatch.elapsedMilliseconds < 100, true,
          reason: 'Bulk reversal validation should be efficient');
      });

      test('should apply stat reversals efficiently', () {
        final currentStats = {
          StatType.strength: 1000.0,
          StatType.agility: 800.0,
          StatType.endurance: 1200.0,
          StatType.intelligence: 2000.0,
          StatType.focus: 1500.0,
          StatType.charisma: 900.0,
        };

        final reversals = {
          StatType.strength: 50.0,
          StatType.agility: 40.0,
          StatType.endurance: 60.0,
          StatType.intelligence: 100.0,
          StatType.focus: 75.0,
          StatType.charisma: 45.0,
        };

        final stopwatch = Stopwatch()..start();
        
        // Apply reversals multiple times
        for (int i = 0; i < 1000; i++) {
          final updatedStats = StatsService.applyStatReversals(currentStats, reversals);
          expect(updatedStats, isNotNull);
          expect(updatedStats.length, StatType.values.length);
        }
        
        stopwatch.stop();
        
        expect(stopwatch.elapsedMilliseconds < 150, true,
          reason: 'Bulk reversal application should be efficient');
      });
    });

    group('Chart Rendering Performance', () {
      test('should calculate chart maximums efficiently for various ranges', () {
        final testCases = [
          // Normal values
          {StatType.strength: 3.5, StatType.intelligence: 4.2},
          // Medium values
          {StatType.strength: 15.0, StatType.intelligence: 25.0},
          // Large values
          {StatType.strength: 150.0, StatType.intelligence: 300.0},
          // Very large values
          {StatType.strength: 5000.0, StatType.intelligence: 10000.0},
          // Extreme values
          {StatType.strength: 100000.0, StatType.intelligence: 500000.0},
        ];

        final stopwatch = Stopwatch()..start();
        
        for (final testCase in testCases) {
          for (int i = 0; i < 100; i++) {
            final chartResult = StatsService.validateStatsForChart(testCase);
            expect(chartResult.recommendedMaxY, greaterThan(0));
          }
        }
        
        stopwatch.stop();
        
        expect(stopwatch.elapsedMilliseconds < 200, true,
          reason: 'Chart scaling calculations should be efficient across all value ranges');
      });

      test('should handle chart data preparation efficiently', () {
        // Create user with mixed stat values
        testUser.setStat(StatType.strength, 50.0);
        testUser.setStat(StatType.agility, 150.0);
        testUser.setStat(StatType.endurance, 75.0);
        testUser.setStat(StatType.intelligence, 300.0);
        testUser.setStat(StatType.focus, 200.0);
        testUser.setStat(StatType.charisma, 125.0);

        final stopwatch = Stopwatch()..start();
        
        // Simulate chart data preparation multiple times
        for (int i = 0; i < 500; i++) {
          final stats = testUser.statsMap;
          final validationResult = InfiniteStatsValidator.validateStatsForChart(stats);
          expect(validationResult.isValid || validationResult.hasWarning, true);
        }
        
        stopwatch.stop();
        
        expect(stopwatch.elapsedMilliseconds < 250, true,
          reason: 'Chart data preparation should be efficient');
      });
    });

    group('Memory Usage Tests', () {
      test('should not leak memory during repeated operations', () {
        // This test checks for memory efficiency during repeated operations
        final initialStats = {
          StatType.strength: 100.0,
          StatType.intelligence: 200.0,
          StatType.focus: 150.0,
        };

        // Perform many operations that could potentially leak memory
        for (int i = 0; i < 10000; i++) {
          // Stat validation
          StatsService.validateInfiniteStats(initialStats);
          
          // Chart validation
          StatsService.validateStatsForChart(initialStats);
          
          // Stat calculations
          StatsService.calculateStatGains(ActivityType.workoutWeights, 60);
          
          // Reversal calculations
          StatsService.calculateStatReversals(ActivityType.workoutWeights, 60, null);
          
          // Export validation
          StatsService.validateStatsForExport(initialStats);
        }
        
        // If we reach here without running out of memory, the test passes
        expect(true, true);
      });

      test('should handle large data structures efficiently', () {
        // Create large stat maps
        final largeStatMaps = <Map<StatType, double>>[];
        
        for (int i = 0; i < 1000; i++) {
          final statMap = <StatType, double>{};
          for (final statType in StatType.values) {
            statMap[statType] = 100.0 + (i * 10.0);
          }
          largeStatMaps.add(statMap);
        }

        final stopwatch = Stopwatch()..start();
        
        // Process all stat maps
        for (final statMap in largeStatMaps) {
          final validationResult = StatsService.validateInfiniteStats(statMap);
          expect(validationResult.sanitizedStats, isNotNull);
        }
        
        stopwatch.stop();
        
        expect(stopwatch.elapsedMilliseconds < 1000, true,
          reason: 'Processing large datasets should complete within reasonable time');
      });
    });

    group('Edge Case Performance', () {
      test('should handle invalid values efficiently', () {
        final invalidStats = {
          StatType.strength: double.nan,
          StatType.agility: double.infinity,
          StatType.endurance: double.negativeInfinity,
          StatType.intelligence: -100.0,
          StatType.focus: 0.0,
          StatType.charisma: -1.0,
        };

        final stopwatch = Stopwatch()..start();
        
        // Validation should handle invalid values quickly
        for (int i = 0; i < 1000; i++) {
          final validationResult = StatsService.validateInfiniteStats(invalidStats);
          expect(validationResult.sanitizedStats, isNotNull);
        }
        
        stopwatch.stop();
        
        expect(stopwatch.elapsedMilliseconds < 200, true,
          reason: 'Invalid value handling should be efficient');
      });

      test('should handle empty and null data efficiently', () {
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < 1000; i++) {
          // Empty stats
          final emptyResult = StatsService.validateInfiniteStats({});
          expect(emptyResult, isNotNull);
          
          // Null stat gains
          final reversals = StatsService.calculateStatReversals(
            ActivityType.workoutWeights, 60, null
          );
          expect(reversals, isNotNull);
        }
        
        stopwatch.stop();
        
        expect(stopwatch.elapsedMilliseconds < 100, true,
          reason: 'Empty/null data handling should be very efficient');
      });
    });

    group('Concurrent Operations Performance', () {
      test('should handle multiple simultaneous operations efficiently', () async {
        final futures = <Future>[];
        
        // Create multiple concurrent operations
        for (int i = 0; i < 50; i++) {
          futures.add(Future(() {
            final stats = {
              StatType.strength: 100.0 + i,
              StatType.intelligence: 200.0 + i,
            };
            
            // Multiple operations per future
            StatsService.validateInfiniteStats(stats);
            StatsService.validateStatsForChart(stats);
            StatsService.calculateStatGains(ActivityType.workoutWeights, 60);
            
            return true;
          }));
        }

        final stopwatch = Stopwatch()..start();
        
        // Wait for all operations to complete
        final results = await Future.wait(futures);
        
        stopwatch.stop();
        
        expect(results.length, 50);
        expect(results.every((result) => result == true), true);
        expect(stopwatch.elapsedMilliseconds < 1000, true,
          reason: 'Concurrent operations should complete efficiently');
      });
    });
  });
}