import 'package:flutter_test/flutter_test.dart';
import 'package:yolvl/services/stats_service.dart';
import 'package:yolvl/models/enums.dart';

void main() {
  group('StatsService - Infinite Stats Validation', () {
    group('validateInfiniteStats', () {
      test('should validate normal stat values', () {
        final stats = {
          StatType.strength: 5.5,
          StatType.agility: 7.2,
          StatType.endurance: 3.8,
          StatType.intelligence: 9.1,
          StatType.focus: 6.4,
          StatType.charisma: 4.7,
        };

        final result = StatsService.validateInfiniteStats(stats);

        expect(result.isValid, isTrue);
        expect(result.hasWarning, isFalse);
        expect(result.sanitizedStats, isNotNull);
        expect(result.sanitizedStats![StatType.strength], equals(5.5));
        expect(result.sanitizedStats![StatType.agility], equals(7.2));
      });

      test('should validate large stat values without ceiling constraints', () {
        final stats = {
          StatType.strength: 150.0,
          StatType.agility: 200.5,
          StatType.endurance: 99.9,
          StatType.intelligence: 500.0,
          StatType.focus: 75.3,
          StatType.charisma: 300.8,
        };

        final result = StatsService.validateInfiniteStats(stats);

        expect(result.isValid, isTrue);
        expect(result.sanitizedStats![StatType.strength], equals(150.0));
        expect(result.sanitizedStats![StatType.intelligence], equals(500.0));
        expect(result.sanitizedStats![StatType.charisma], equals(300.8));
      });

      test('should handle very large stat values with warnings', () {
        final stats = {
          StatType.strength: 150000.0,
          StatType.agility: 200000.0,
        };

        final result = StatsService.validateInfiniteStats(stats);

        expect(result.isValid, isTrue);
        expect(result.hasWarning, isTrue);
        expect(result.warnings, contains('Very large stat values may impact performance'));
        expect(result.sanitizedStats![StatType.strength], equals(150000.0));
        expect(result.sanitizedStats![StatType.agility], equals(200000.0));
      });

      test('should clamp extremely large values to reasonable maximum', () {
        final stats = {
          StatType.strength: 2000000.0, // Above reasonable maximum
          StatType.agility: 1500000.0,
          StatType.endurance: 999999.0, // At reasonable maximum
        };

        final result = StatsService.validateInfiniteStats(stats);

        expect(result.isValid, isTrue);
        expect(result.hasWarning, isTrue);
        expect(result.sanitizedStats![StatType.strength], equals(999999.0));
        expect(result.sanitizedStats![StatType.agility], equals(999999.0));
        expect(result.sanitizedStats![StatType.endurance], equals(999999.0));
      });

      test('should handle NaN values by setting to minimum', () {
        final stats = {
          StatType.strength: double.nan,
          StatType.agility: 5.5,
          StatType.endurance: double.nan,
        };

        final result = StatsService.validateInfiniteStats(stats);

        expect(result.isValid, isFalse);
        expect(result.sanitizedStats![StatType.strength], equals(1.0));
        expect(result.sanitizedStats![StatType.agility], equals(5.5));
        expect(result.sanitizedStats![StatType.endurance], equals(1.0));
      });

      test('should handle infinity values by setting to reasonable maximum', () {
        final stats = {
          StatType.strength: double.infinity,
          StatType.agility: double.negativeInfinity,
          StatType.endurance: 5.5,
        };

        final result = StatsService.validateInfiniteStats(stats);

        expect(result.isValid, isFalse);
        expect(result.sanitizedStats![StatType.strength], equals(999999.0));
        expect(result.sanitizedStats![StatType.agility], equals(999999.0));
        expect(result.sanitizedStats![StatType.endurance], equals(5.5));
      });

      test('should handle values below minimum by clamping to 1.0', () {
        final stats = {
          StatType.strength: 0.5,
          StatType.agility: -1.0,
          StatType.endurance: 0.0,
          StatType.intelligence: 2.5,
        };

        final result = StatsService.validateInfiniteStats(stats);

        expect(result.isValid, isTrue);
        expect(result.hasWarning, isTrue);
        expect(result.sanitizedStats![StatType.strength], equals(1.0));
        expect(result.sanitizedStats![StatType.agility], equals(1.0));
        expect(result.sanitizedStats![StatType.endurance], equals(1.0));
        expect(result.sanitizedStats![StatType.intelligence], equals(2.5));
      });

      test('should handle empty stats map', () {
        final stats = <StatType, double>{};

        final result = StatsService.validateInfiniteStats(stats);

        expect(result.isValid, isFalse);
        expect(result.message, contains('Stats map is empty'));
      });

      test('should provide detailed warnings for multiple issues', () {
        final stats = {
          StatType.strength: 0.5, // Below minimum
          StatType.agility: double.nan, // Invalid
          StatType.endurance: 150000.0, // Very large
          StatType.intelligence: double.infinity, // Invalid
          StatType.focus: 2.5, // Normal
          StatType.charisma: -1.0, // Below minimum
        };

        final result = StatsService.validateInfiniteStats(stats);

        expect(result.isValid, isFalse);
        expect(result.warnings, isNotEmpty);
        expect(result.sanitizedStats, isNotNull);
        expect(result.sanitizedStats![StatType.strength], equals(1.0));
        expect(result.sanitizedStats![StatType.agility], equals(1.0));
        expect(result.sanitizedStats![StatType.endurance], equals(150000.0));
        expect(result.sanitizedStats![StatType.intelligence], equals(999999.0));
        expect(result.sanitizedStats![StatType.focus], equals(2.5));
        expect(result.sanitizedStats![StatType.charisma], equals(1.0));
      });
    });

    group('validateStatsForExport', () {
      test('should validate normal stats for export', () {
        final stats = {
          StatType.strength: 5.5,
          StatType.agility: 7.2,
          StatType.endurance: 15.8,
          StatType.intelligence: 25.1,
          StatType.focus: 6.4,
          StatType.charisma: 12.7,
        };

        final result = StatsService.validateStatsForExport(stats);

        expect(result.isValid, isTrue);
        expect(result.hasWarning, isFalse);
        expect(result.sanitizedStats, isNotNull);
      });

      test('should allow very large values for export with warnings', () {
        final stats = {
          StatType.strength: 500000.0,
          StatType.agility: 750000.0,
          StatType.endurance: 1200000.0, // Above 1M threshold
        };

        final result = StatsService.validateStatsForExport(stats);

        expect(result.isValid, isTrue);
        expect(result.hasWarning, isTrue);
        expect(result.warnings, isNotEmpty);
        expect(result.sanitizedStats![StatType.strength], equals(500000.0));
        expect(result.sanitizedStats![StatType.endurance], equals(1200000.0));
      });

      test('should reject invalid values for export', () {
        final stats = {
          StatType.strength: double.nan,
          StatType.agility: double.infinity,
          StatType.endurance: 5.5,
        };

        final result = StatsService.validateStatsForExport(stats);

        expect(result.isValid, isFalse);
        expect(result.sanitizedStats![StatType.strength], equals(1.0));
        expect(result.sanitizedStats![StatType.agility], equals(1.0));
        expect(result.sanitizedStats![StatType.endurance], equals(5.5));
      });

      test('should handle empty stats for export', () {
        final stats = <StatType, double>{};

        final result = StatsService.validateStatsForExport(stats);

        expect(result.isValid, isFalse);
        expect(result.message, contains('No stats to export'));
      });
    });

    group('validateChartRendering', () {
      test('should validate normal stats for chart rendering', () {
        final stats = {
          StatType.strength: 5.5,
          StatType.agility: 7.2,
          StatType.endurance: 3.8,
          StatType.intelligence: 9.1,
          StatType.focus: 6.4,
          StatType.charisma: 4.7,
        };

        final result = StatsService.validateChartRendering(stats);

        expect(result.isValid, isTrue);
        expect(result.recommendedMaxY, isNotNull);
        expect(result.scalingFactor, isNotNull);
      });

      test('should provide warnings for very large values', () {
        final stats = {
          StatType.strength: 150000.0,
          StatType.agility: 200000.0,
        };

        final result = StatsService.validateChartRendering(stats);

        expect(result.isValid, isTrue);
        expect(result.hasWarning, isTrue);
        expect(result.warnings, isNotEmpty);
        expect(result.recommendations, isNotEmpty);
      });

      test('should provide recommendations for extremely large values', () {
        final stats = {
          StatType.strength: 2000000.0,
          StatType.agility: 1500000.0,
        };

        final result = StatsService.validateChartRendering(stats);

        expect(result.isValid, isTrue);
        expect(result.warnings, contains(matches(r'Extremely large values.*performance')));
        expect(result.recommendations, contains(matches(r'logarithmic scaling')));
      });

      test('should handle small value differences', () {
        final stats = {
          StatType.strength: 10.001,
          StatType.agility: 10.002,
          StatType.endurance: 10.003,
        };

        final result = StatsService.validateChartRendering(stats);

        expect(result.isValid, isTrue);
        expect(result.warnings, contains(matches(r'small value differences')));
        expect(result.recommendations, contains(matches(r'chart scale')));
      });

      test('should reject invalid values for chart rendering', () {
        final stats = {
          StatType.strength: double.nan,
          StatType.agility: double.infinity,
        };

        final result = StatsService.validateChartRendering(stats);

        expect(result.isValid, isFalse);
      });

      test('should handle empty stats for chart rendering', () {
        final stats = <StatType, double>{};

        final result = StatsService.validateChartRendering(stats);

        expect(result.isValid, isFalse);
        expect(result.message, contains('No stats for chart rendering'));
      });
    });

    group('testEdgeCaseStatValues', () {
      test('should run comprehensive edge case tests', () {
        final result = StatsService.testEdgeCaseStatValues();

        expect(result.testResults, isNotEmpty);
        expect(result.testResults.containsKey('normal_values_validation'), isTrue);
        expect(result.testResults.containsKey('large_values_validation'), isTrue);
        expect(result.testResults.containsKey('very_large_values_validation'), isTrue);
        expect(result.testResults.containsKey('extreme_values_validation'), isTrue);
        expect(result.testResults.containsKey('invalid_values_validation'), isTrue);

        // Normal values should pass all tests
        expect(result.testResults['normal_values_validation'], isTrue);
        expect(result.testResults['normal_values_chart'], isTrue);
        expect(result.testResults['normal_values_export'], isTrue);
        expect(result.testResults['normal_values_application'], isTrue);

        // Large values should pass validation but may have warnings
        expect(result.testResults['large_values_validation'], isTrue);
        expect(result.testResults['large_values_application'], isTrue);

        // Invalid values should be handled gracefully
        expect(result.testResults['invalid_values_validation'], isFalse);
        expect(result.testResults['invalid_values_application'], isTrue); // Should still work with sanitized values
      });

      test('should handle edge case test failures gracefully', () {
        final result = StatsService.testEdgeCaseStatValues();

        // Test should complete without throwing exceptions
        expect(result, isNotNull);
        expect(result.testResults, isA<Map<String, dynamic>>());
        expect(result.issues, isA<List<String>>());
      });
    });

    group('Chart Auto-scaling with Infinite Stats', () {
      test('should calculate appropriate chart maximum for various stat ranges', () {
        // Test normal range (up to 5)
        final normalStats = {StatType.strength: 4.5, StatType.agility: 3.2};
        final normalResult = StatsService.validateStatsForChart(normalStats);
        expect(normalResult.recommendedMaxY, equals(5.0));

        // Test medium range (5-100)
        final mediumStats = {StatType.strength: 45.0, StatType.agility: 32.0};
        final mediumResult = StatsService.validateStatsForChart(mediumStats);
        expect(mediumResult.recommendedMaxY, equals(45.0)); // Uses safe chart maximum calculation

        // Test large range (100-1000)
        final largeStats = {StatType.strength: 450.0, StatType.agility: 320.0};
        final largeResult = StatsService.validateStatsForChart(largeStats);
        expect(largeResult.recommendedMaxY, equals(450.0)); // Uses safe chart maximum calculation

        // Test very large range (1000+)
        final veryLargeStats = {StatType.strength: 4500.0, StatType.agility: 3200.0};
        final veryLargeResult = StatsService.validateStatsForChart(veryLargeStats);
        expect(veryLargeResult.recommendedMaxY, equals(4500.0)); // Uses safe chart maximum calculation
      });

      test('should handle edge cases in chart scaling', () {
        // Test exactly at boundaries
        final boundaryStats = {
          StatType.strength: 5.0,
          StatType.agility: 100.0,
          StatType.endurance: 1000.0,
        };
        final result = StatsService.validateStatsForChart(boundaryStats);
        expect(result.isValid, isTrue);
        expect(result.recommendedMaxY, equals(1000.0));
      });
    });

    group('Performance and Memory Validation', () {
      test('should validate performance implications of large stat values', () {
        final performanceTestStats = {
          StatType.strength: 999999.0,
          StatType.agility: 888888.0,
          StatType.endurance: 777777.0,
          StatType.intelligence: 666666.0,
          StatType.focus: 555555.0,
          StatType.charisma: 444444.0,
        };

        final chartResult = StatsService.validateChartRendering(performanceTestStats);
        expect(chartResult.isValid, isTrue);
        expect(chartResult.warnings, isNotEmpty);
        expect(chartResult.recommendations, isNotEmpty);

        final infiniteResult = StatsService.validateInfiniteStats(performanceTestStats);
        expect(infiniteResult.isValid, isTrue);
        expect(infiniteResult.hasWarning, isTrue);
      });

      test('should provide memory usage recommendations', () {
        final memoryTestStats = {
          StatType.strength: 50000.0,
          StatType.agility: 60000.0,
        };

        final result = StatsService.validateChartRendering(memoryTestStats);
        expect(result.recommendations, contains(matches(r'chart intervals.*memory')));
      });
    });

    group('Data Integrity Validation', () {
      test('should maintain data integrity during validation', () {
        final originalStats = {
          StatType.strength: 15.5,
          StatType.agility: 22.3,
          StatType.endurance: 8.7,
        };

        final result = StatsService.validateInfiniteStats(originalStats);
        
        expect(result.isValid, isTrue);
        expect(result.sanitizedStats![StatType.strength], equals(15.5));
        expect(result.sanitizedStats![StatType.agility], equals(22.3));
        expect(result.sanitizedStats![StatType.endurance], equals(8.7));
      });

      test('should preserve precision in large values', () {
        final precisionStats = {
          StatType.strength: 12345.67,
          StatType.agility: 98765.43,
        };

        final result = StatsService.validateInfiniteStats(precisionStats);
        
        expect(result.isValid, isTrue);
        expect(result.sanitizedStats![StatType.strength], equals(12345.67));
        expect(result.sanitizedStats![StatType.agility], equals(98765.43));
      });
    });

    group('Error Handling and Recovery', () {
      test('should handle validation exceptions gracefully', () {
        // This test ensures that even if something goes wrong internally,
        // the validation methods don't crash the app
        expect(() => StatsService.validateInfiniteStats({}), returnsNormally);
        expect(() => StatsService.validateStatsForExport({}), returnsNormally);
        expect(() => StatsService.validateChartRendering({}), returnsNormally);
        expect(() => StatsService.testEdgeCaseStatValues(), returnsNormally);
      });

      test('should provide meaningful error messages', () {
        final emptyResult = StatsService.validateInfiniteStats({});
        expect(emptyResult.message, isNotNull);
        expect(emptyResult.message, contains('empty'));

        final exportResult = StatsService.validateStatsForExport({});
        expect(exportResult.message, isNotNull);
        expect(exportResult.message, contains('export'));

        final chartResult = StatsService.validateChartRendering({});
        expect(chartResult.message, isNotNull);
        expect(chartResult.message, contains('chart'));
      });
    });
  });
}