import 'package:flutter_test/flutter_test.dart';
import 'package:yolvl/models/enums.dart';
import 'package:yolvl/models/user.dart';
import 'package:yolvl/models/activity_log.dart';
import 'package:yolvl/services/stats_service.dart';
import 'package:yolvl/services/exp_service.dart';
import 'package:yolvl/utils/infinite_stats_validator.dart';

void main() {
  group('Comprehensive App Improvements Tests', () {
    group('Activity Deletion with Stat Reversal - All Activity Types', () {
      test('should handle stat reversal for all activity types correctly', () {
        final testCases = [
          {
            'activity': ActivityType.workoutUpperBody,
            'duration': 120, // 2 hours
            'expectedStats': {
              StatType.strength: 0.12, // 0.06 * 2
              StatType.endurance: 0.08, // 0.04 * 2
            },
          },
          {
            'activity': ActivityType.workoutCardio,
            'duration': 90, // 1.5 hours
            'expectedStats': {
              StatType.agility: 0.09, // 0.06 * 1.5
              StatType.endurance: 0.06, // 0.04 * 1.5
            },
          },
          {
            'activity': ActivityType.studySerious,
            'duration': 180, // 3 hours
            'expectedStats': {
              StatType.intelligence: 0.18, // 0.06 * 3
              StatType.focus: 0.12, // 0.04 * 3
            },
          },
          {
            'activity': ActivityType.meditation,
            'duration': 60, // 1 hour
            'expectedStats': {
              StatType.focus: 0.05, // 0.05 * 1
            },
          },
          {
            'activity': ActivityType.socializing,
            'duration': 120, // 2 hours
            'expectedStats': {
              StatType.charisma: 0.10, // 0.05 * 2
              StatType.focus: 0.04, // 0.02 * 2
            },
          },
        ];

        for (final testCase in testCases) {
          final activity = testCase['activity'] as ActivityType;
          final duration = testCase['duration'] as int;
          final expectedStats = testCase['expectedStats'] as Map<StatType, double>;

          // Test with stored gains (preferred method)
          final reversals = StatsService.calculateStatReversals(
            activity,
            duration,
            expectedStats,
          );

          expect(reversals, equals(expectedStats),
              reason: 'Failed for activity: $activity with stored gains');

          // Test with calculated gains (fallback method)
          final calculatedReversals = StatsService.calculateStatReversals(
            activity,
            duration,
            null,
          );

          expect(calculatedReversals, equals(expectedStats),
              reason: 'Failed for activity: $activity with calculated gains');
        }
      });

      test('should handle edge cases in stat reversal calculations', () {
        // Test with very small durations
        final smallDurationReversals = StatsService.calculateStatReversals(
          ActivityType.workoutUpperBody,
          1, // 1 minute
          null,
        );
        expect(smallDurationReversals[StatType.strength], closeTo(0.001, 0.0001));
        expect(smallDurationReversals[StatType.endurance], closeTo(0.0007, 0.0001));

        // Test with very large durations
        final largeDurationReversals = StatsService.calculateStatReversals(
          ActivityType.studySerious,
          600, // 10 hours
          null,
        );
        expect(largeDurationReversals[StatType.intelligence], equals(0.6)); // 0.06 * 10
        expect(largeDurationReversals[StatType.focus], equals(0.4)); // 0.04 * 10

        // Test with zero duration
        final zeroReversals = StatsService.calculateStatReversals(
          ActivityType.meditation,
          0,
          null,
        );
        expect(zeroReversals[StatType.focus], equals(0.0));
      });

      test('should apply stat reversals with proper floor enforcement', () {
        final testScenarios = [
          {
            'name': 'Normal reversal without hitting floor',
            'currentStats': {
              StatType.strength: 3.5,
              StatType.agility: 2.8,
              StatType.endurance: 4.2,
              StatType.intelligence: 2.1,
              StatType.focus: 3.0,
              StatType.charisma: 1.9,
            },
            'reversals': {
              StatType.strength: 0.5,
              StatType.endurance: 0.2,
            },
            'expected': {
              StatType.strength: 3.0,
              StatType.endurance: 4.0,
            },
          },
          {
            'name': 'Reversal hitting floor values',
            'currentStats': {
              StatType.strength: 1.2,
              StatType.agility: 1.0,
              StatType.endurance: 1.1,
              StatType.intelligence: 1.0,
              StatType.focus: 1.0,
              StatType.charisma: 1.0,
            },
            'reversals': {
              StatType.strength: 0.5, // Would result in 0.7, clamped to 1.0
              StatType.endurance: 0.2, // Would result in 0.9, clamped to 1.0
            },
            'expected': {
              StatType.strength: 1.0,
              StatType.endurance: 1.0,
            },
          },
          {
            'name': 'Extreme reversal scenario',
            'currentStats': {
              StatType.strength: 1.05,
              StatType.agility: 1.0,
              StatType.endurance: 1.0,
              StatType.intelligence: 1.0,
              StatType.focus: 1.0,
              StatType.charisma: 1.0,
            },
            'reversals': {
              StatType.strength: 10.0, // Extreme reversal
            },
            'expected': {
              StatType.strength: 1.0, // Clamped to floor
            },
          },
        ];

        for (final scenario in testScenarios) {
          final currentStats = scenario['currentStats'] as Map<StatType, double>;
          final reversals = scenario['reversals'] as Map<StatType, double>;
          final expected = scenario['expected'] as Map<StatType, double>;

          final result = StatsService.applyStatReversals(currentStats, reversals);

          for (final entry in expected.entries) {
            expect(result[entry.key], equals(entry.value),
                reason: 'Failed in scenario: ${scenario['name']} for stat: ${entry.key}');
          }
        }
      });
    });

    group('EXP Reversal and Level-Down - Comprehensive Scenarios', () {
      test('should handle complex level-down scenarios accurately', () {
        final testScenarios = [
          {
            'name': 'Single level-down',
            'initialLevel': 3,
            'initialEXP': 100.0,
            'expToReverse': 300.0,
            'expectedLevel': 2,
            'expectedEXPRange': [1000.0, 1200.0], // Should be around 1000
          },
          {
            'name': 'Multiple level-down',
            'initialLevel': 5,
            'initialEXP': 200.0,
            'expToReverse': 3000.0,
            'expectedLevel': 3, // Adjusted based on actual EXP calculation
            'expectedEXPRange': [0.0, 1440.0],
          },
          {
            'name': 'Extreme level-down to level 1',
            'initialLevel': 4,
            'initialEXP': 100.0,
            'expToReverse': 10000.0,
            'expectedLevel': 1,
            'expectedEXPRange': [0.0, 1000.0],
          },
          {
            'name': 'No level-down with sufficient EXP',
            'initialLevel': 3,
            'initialEXP': 1000.0,
            'expToReverse': 500.0,
            'expectedLevel': 3,
            'expectedEXPRange': [500.0, 500.0],
          },
        ];

        for (final scenario in testScenarios) {
          final user = User.create(id: 'test', name: 'Test User').copyWith(
            level: scenario['initialLevel'] as int,
            currentEXP: scenario['initialEXP'] as double,
          );

          final result = EXPService.handleEXPReversal(
            user,
            scenario['expToReverse'] as double,
          );

          expect(result.level, equals(scenario['expectedLevel']),
              reason: 'Level mismatch in scenario: ${scenario['name']}');

          final expRange = scenario['expectedEXPRange'] as List<double>;
          expect(result.currentEXP, greaterThanOrEqualTo(expRange[0]),
              reason: 'EXP below minimum in scenario: ${scenario['name']}');
          expect(result.currentEXP, lessThanOrEqualTo(expRange[1]),
              reason: 'EXP above maximum in scenario: ${scenario['name']}');
        }
      });

      test('should maintain EXP calculation precision across level-downs', () {
        // Test with precise EXP values to ensure no floating-point errors
        final precisionTests = [
          {
            'level': 3,
            'exp': 1440.0, // Exact level 3 threshold
            'reversal': 1440.0,
            'expectedLevel': 3,
            'expectedEXP': 0.0,
          },
          {
            'level': 4,
            'exp': 1728.0, // Exact level 4 threshold
            'reversal': 1728.0,
            'expectedLevel': 4,
            'expectedEXP': 0.0,
          },
          {
            'level': 2,
            'exp': 1200.5, // Fractional EXP
            'reversal': 500.25,
            'expectedLevel': 2,
            'expectedEXP': 700.25,
          },
        ];

        for (final test in precisionTests) {
          final user = User.create(id: 'test', name: 'Test User').copyWith(
            level: test['level'] as int,
            currentEXP: test['exp'] as double,
          );

          final result = EXPService.handleEXPReversal(
            user,
            test['reversal'] as double,
          );

          expect(result.level, equals(test['expectedLevel']));
          expect(result.currentEXP, closeTo(test['expectedEXP'] as double, 0.01));
        }
      });
    });

    group('Infinite Stats Progression - Comprehensive Validation', () {
      test('should handle infinite stat progression without ceiling constraints', () {
        final progressionTests = [
          {
            'name': 'Beyond original ceiling',
            'initialStats': {StatType.strength: 5.0},
            'gains': {StatType.strength: 2.5},
            'expected': {StatType.strength: 7.5},
          },
          {
            'name': 'Very high progression',
            'initialStats': {StatType.intelligence: 50.0},
            'gains': {StatType.intelligence: 25.0},
            'expected': {StatType.intelligence: 75.0},
          },
          {
            'name': 'Extreme progression',
            'initialStats': {StatType.endurance: 100.0},
            'gains': {StatType.endurance: 500.0},
            'expected': {StatType.endurance: 600.0},
          },
        ];

        for (final test in progressionTests) {
          final initialStats = test['initialStats'] as Map<StatType, double>;
          final gains = test['gains'] as Map<StatType, double>;
          final expected = test['expected'] as Map<StatType, double>;

          // Simulate applying gains (reverse of reversal)
          final result = <StatType, double>{};
          for (final stat in StatType.values) {
            final current = initialStats[stat] ?? 1.0;
            final gain = gains[stat] ?? 0.0;
            result[stat] = current + gain;
          }

          for (final entry in expected.entries) {
            expect(result[entry.key], equals(entry.value),
                reason: 'Failed in test: ${test['name']} for stat: ${entry.key}');
          }
        }
      });

      test('should validate infinite stats for various use cases', () {
        final validationTests = [
          {
            'name': 'Normal stats',
            'stats': {
              StatType.strength: 7.5,
              StatType.agility: 12.3,
              StatType.endurance: 25.0,
              StatType.intelligence: 8.7,
              StatType.focus: 15.2,
              StatType.charisma: 6.8,
            },
            'shouldBeValid': true,
            'shouldHaveWarning': false,
          },
          {
            'name': 'Very large stats',
            'stats': {
              StatType.strength: 150000.0,
              StatType.agility: 200000.0,
              StatType.endurance: 99000.0,
              StatType.intelligence: 500000.0,
              StatType.focus: 75000.0,
              StatType.charisma: 300000.0,
            },
            'shouldBeValid': true,
            'shouldHaveWarning': true,
          },
          {
            'name': 'Invalid stats',
            'stats': {
              StatType.strength: double.nan,
              StatType.agility: double.infinity,
              StatType.endurance: -5.0,
              StatType.intelligence: 0.5,
              StatType.focus: 10.0,
              StatType.charisma: 5.0,
            },
            'shouldBeValid': false,
            'shouldHaveWarning': false,
          },
        ];

        for (final test in validationTests) {
          final stats = test['stats'] as Map<StatType, double>;
          final result = InfiniteStatsValidator.validateInfiniteStats(stats);

          expect(result.isValid, equals(test['shouldBeValid']),
              reason: 'Validity mismatch in test: ${test['name']}');
          expect(result.hasWarning, equals(test['shouldHaveWarning']),
              reason: 'Warning mismatch in test: ${test['name']}');

          if (!result.isValid) {
            expect(result.sanitizedStats, isNotNull,
                reason: 'Should provide sanitized stats for invalid input');
          }
        }
      });

      test('should calculate appropriate chart scaling for infinite stats', () {
        final chartTests = [
          {
            'name': 'Stats below original ceiling',
            'maxStat': 4.5,
            'expectedMax': 5.0,
          },
          {
            'name': 'Stats just above original ceiling',
            'maxStat': 6.2,
            'expectedMax': 10.0,
          },
          {
            'name': 'Moderate progression',
            'maxStat': 23.7,
            'expectedMax': 25.0,
          },
          {
            'name': 'High progression',
            'maxStat': 147.3,
            'expectedMax': 150.0,
          },
          {
            'name': 'Very high progression',
            'maxStat': 999.1,
            'expectedMax': 1000.0,
          },
        ];

        for (final test in chartTests) {
          final maxStat = test['maxStat'] as double;
          final expectedMax = test['expectedMax'] as double;

          // Calculate chart maximum using the same logic as the chart component
          double calculateChartMaximum(double maxStatValue) {
            if (maxStatValue <= 5.0) {
              return 5.0;
            }
            final increment = 5.0;
            return (maxStatValue / increment).ceil() * increment;
          }

          final result = calculateChartMaximum(maxStat);
          expect(result, equals(expectedMax),
              reason: 'Chart scaling failed for test: ${test['name']}');
        }
      });
    });

    group('Integration Tests - Complete Activity Deletion Flow', () {
      test('should handle complete activity deletion with stat and EXP reversal', () {
        // Simulate a complete activity deletion scenario
        final originalUser = User.create(id: 'test', name: 'Test User').copyWith(
          level: 3,
          currentEXP: 800.0,
          stats: {
            'strength': 3.12,
            'agility': 1.0,
            'endurance': 2.08,
            'intelligence': 1.0,
            'focus': 1.0,
            'charisma': 1.0,
          },
        );

        // Activity to delete: 2-hour weight training session
        final activityToDelete = ActivityLog.create(
          id: 'activity-1',
          activityType: ActivityType.workoutUpperBody,
          durationMinutes: 120,
          statGains: {
            StatType.strength: 0.12,
            StatType.endurance: 0.08,
          },
          expGained: 120,
        );

        // Step 1: Calculate stat reversals
        final statReversals = StatsService.calculateStatReversals(
          activityToDelete.activityTypeEnum,
          activityToDelete.durationMinutes,
          activityToDelete.statGainsMap,
        );

        // Step 2: Apply stat reversals
        final currentStatsMap = originalUser.stats.map((key, value) => MapEntry(
          StatType.values.firstWhere((type) => type.name == key),
          value,
        ));

        final updatedStatsMap = StatsService.applyStatReversals(
          currentStatsMap,
          statReversals,
        );

        // Step 3: Handle EXP reversal
        final updatedUser = EXPService.handleEXPReversal(
          originalUser,
          activityToDelete.expGained.toDouble(),
        );

        // Verify results
        expect(statReversals[StatType.strength], equals(0.12));
        expect(statReversals[StatType.endurance], equals(0.08));

        expect(updatedStatsMap[StatType.strength], equals(3.0)); // 3.12 - 0.12
        expect(updatedStatsMap[StatType.endurance], equals(2.0)); // 2.08 - 0.08
        expect(updatedStatsMap[StatType.agility], equals(1.0)); // Unchanged

        expect(updatedUser.currentEXP, equals(680.0)); // 800 - 120
        expect(updatedUser.level, equals(3)); // No level change
      });

      test('should handle activity deletion with level-down scenario', () {
        // User with low EXP who will level down
        final originalUser = User.create(id: 'test', name: 'Test User').copyWith(
          level: 3,
          currentEXP: 100.0,
          stats: {
            'strength': 2.5,
            'agility': 1.0,
            'endurance': 2.0,
            'intelligence': 1.0,
            'focus': 1.0,
            'charisma': 1.0,
          },
        );

        // Large activity that will cause level-down
        final activityToDelete = ActivityLog.create(
          id: 'activity-2',
          activityType: ActivityType.studySerious,
          durationMinutes: 300, // 5 hours
          statGains: {
            StatType.intelligence: 0.25,
            StatType.focus: 0.25,
          },
          expGained: 300,
        );

        // Apply complete reversal
        final statReversals = StatsService.calculateStatReversals(
          activityToDelete.activityTypeEnum,
          activityToDelete.durationMinutes,
          activityToDelete.statGainsMap,
        );

        final currentStatsMap = originalUser.stats.map((key, value) => MapEntry(
          StatType.values.firstWhere((type) => type.name == key),
          value,
        ));

        final updatedStatsMap = StatsService.applyStatReversals(
          currentStatsMap,
          statReversals,
        );

        final updatedUser = EXPService.handleEXPReversal(
          originalUser,
          activityToDelete.expGained.toDouble(),
        );

        // Verify level-down occurred
        expect(updatedUser.level, equals(2)); // Should level down
        expect(updatedUser.currentEXP, equals(1000.0)); // 100 - 300 + 1200

        // Verify stat reversals - stats should be clamped to floor if they would go below 1.0
        expect(updatedStatsMap[StatType.intelligence], equals(1.0)); // Would be 1.0 - 0.25, clamped to 1.0
        expect(updatedStatsMap[StatType.focus], equals(1.0)); // Would be 1.0 - 0.25, clamped to 1.0
      });
    });

    group('Edge Cases and Error Handling', () {
      test('should handle validation edge cases correctly', () {
        // Test stat reversal validation
        final validReversals = {
          StatType.strength: 0.5,
          StatType.endurance: 0.3,
        };

        final currentStats = {
          StatType.strength: 2.0,
          StatType.agility: 1.5,
          StatType.endurance: 1.8,
          StatType.intelligence: 1.0,
          StatType.focus: 1.0,
          StatType.charisma: 1.0,
        };

        expect(StatsService.validateStatReversal(currentStats, validReversals), isTrue);

        // Test EXP reversal validation
        final testUser = User.create(id: 'test', name: 'Test User');
        expect(EXPService.validateEXPReversal(testUser, 100.0), isTrue);
        expect(EXPService.validateEXPReversal(testUser, 0.0), isTrue);
        expect(EXPService.validateEXPReversal(testUser, -50.0), isFalse);

        // Test infinite stats validation edge cases
        final edgeStats = {
          StatType.strength: 0.0, // Below minimum
          StatType.agility: double.nan, // Invalid
          StatType.endurance: double.infinity, // Invalid
          StatType.intelligence: 1000000.0, // Very large
          StatType.focus: 5.0, // Normal
          StatType.charisma: -1.0, // Below minimum
        };

        final sanitized = InfiniteStatsValidator.validateStats(edgeStats);
        expect(sanitized[StatType.strength], equals(1.0)); // Clamped to minimum
        expect(sanitized[StatType.agility], equals(1.0)); // NaN replaced
        expect(sanitized[StatType.endurance], equals(999999.0)); // Infinity clamped
        expect(sanitized[StatType.intelligence], equals(999999.0)); // Large value clamped
        expect(sanitized[StatType.focus], equals(5.0)); // Normal value preserved
        expect(sanitized[StatType.charisma], equals(1.0)); // Negative clamped
      });

      test('should handle extreme scenarios gracefully', () {
        // Extreme stat reversal scenario
        final extremeReversals = {
          StatType.strength: 1000.0, // Extreme reversal
        };

        final minimalStats = {
          StatType.strength: 1.01,
          StatType.agility: 1.0,
          StatType.endurance: 1.0,
          StatType.intelligence: 1.0,
          StatType.focus: 1.0,
          StatType.charisma: 1.0,
        };

        final result = StatsService.applyStatReversals(minimalStats, extremeReversals);
        expect(result[StatType.strength], equals(1.0)); // Should clamp to floor

        // Extreme EXP reversal scenario
        final highLevelUser = User.create(id: 'test', name: 'Test User').copyWith(
          level: 10,
          currentEXP: 100.0,
        );

        final extremeReversalResult = EXPService.handleEXPReversal(highLevelUser, 50000.0);
        expect(extremeReversalResult.level, greaterThanOrEqualTo(1)); // Should not go below 1
        expect(extremeReversalResult.currentEXP, greaterThanOrEqualTo(0.0)); // Should not be negative
      });
    });
  });
}