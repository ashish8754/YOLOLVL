import 'package:flutter_test/flutter_test.dart';
import 'package:yolvl/services/stats_service.dart';
import 'package:yolvl/models/enums.dart';

void main() {
  group('StatsService - Comprehensive Edge Case Testing for Infinite Stats', () {
    group('Extreme Value Validation', () {
      test('should handle maximum safe values correctly', () {
        final maxSafeStats = {
          StatType.strength: 999999.0,
          StatType.agility: 999999.0,
          StatType.endurance: 999999.0,
          StatType.intelligence: 999999.0,
          StatType.focus: 999999.0,
          StatType.charisma: 999999.0,
        };

        final result = StatsService.validateInfiniteStats(maxSafeStats);
        expect(result.isValid, isTrue);
        expect(result.hasWarning, isTrue);
        expect(result.sanitizedStats, isNotNull);
        
        // All values should be preserved at maximum safe level
        for (final statType in StatType.values) {
          expect(result.sanitizedStats![statType], equals(999999.0));
        }
      });

      test('should clamp values above maximum safe threshold', () {
        final oversizedStats = {
          StatType.strength: 2000000.0,
          StatType.agility: 5000000.0,
          StatType.endurance: 10000000.0,
          StatType.intelligence: double.maxFinite,
          StatType.focus: 1500000.0,
          StatType.charisma: 3000000.0,
        };

        final result = StatsService.validateInfiniteStats(oversizedStats);
        expect(result.isValid, isTrue);
        expect(result.hasWarning, isTrue);
        expect(result.warnings, isNotEmpty);
        
        // All values should be clamped to maximum safe level
        for (final statType in StatType.values) {
          expect(result.sanitizedStats![statType], equals(999999.0));
        }
      });

      test('should handle mixed extreme and normal values', () {
        final mixedStats = {
          StatType.strength: 1.5,           // Normal
          StatType.agility: 2000000.0,      // Extreme (should be clamped)
          StatType.endurance: 0.5,          // Below minimum (should be floored)
          StatType.intelligence: double.nan, // Invalid (should be reset)
          StatType.focus: 50000.0,          // Large but acceptable
          StatType.charisma: double.infinity, // Invalid (should be clamped)
        };

        final result = StatsService.validateInfiniteStats(mixedStats);
        expect(result.isValid, isFalse); // Invalid due to NaN and infinity
        expect(result.sanitizedStats, isNotNull);
        
        expect(result.sanitizedStats![StatType.strength], equals(1.5));
        expect(result.sanitizedStats![StatType.agility], equals(999999.0));
        expect(result.sanitizedStats![StatType.endurance], equals(1.0));
        expect(result.sanitizedStats![StatType.intelligence], equals(1.0));
        expect(result.sanitizedStats![StatType.focus], equals(50000.0));
        expect(result.sanitizedStats![StatType.charisma], equals(999999.0));
      });
    });

    group('Chart Rendering Validation with Extreme Values', () {
      test('should provide appropriate scaling for very large values', () {
        final largeStats = {
          StatType.strength: 500000.0,
          StatType.agility: 750000.0,
          StatType.endurance: 1000000.0,
        };

        final result = StatsService.validateChartRendering(largeStats);
        expect(result.isValid, isTrue);
        expect(result.hasWarning, isTrue);
        expect(result.warnings, contains(matches(r'Very large values.*performance|Extremely large values.*performance')));
        expect(result.recommendations, contains(matches(r'logarithmic scaling|Monitor chart rendering performance')));
        expect(result.recommendedMaxY, greaterThan(1000000.0));
      });

      test('should handle chart validation with precision edge cases', () {
        final precisionStats = {
          StatType.strength: 1.0000000001,
          StatType.agility: 1.0000000002,
          StatType.endurance: 1.0000000003,
        };

        final result = StatsService.validateChartRendering(precisionStats);
        expect(result.isValid, isTrue);
        expect(result.warnings, contains(matches(r'small value differences')));
        expect(result.recommendations, contains(matches(r'chart scale')));
      });

      test('should reject chart rendering for invalid values', () {
        final invalidStats = {
          StatType.strength: double.nan,
          StatType.agility: double.negativeInfinity,
          StatType.endurance: double.infinity,
        };

        final result = StatsService.validateChartRendering(invalidStats);
        expect(result.isValid, isFalse);
        expect(result.message, contains('invalid value'));
      });
    });

    group('Export/Import Validation with Infinite Stats', () {
      test('should validate normal export with high values', () {
        final exportStats = {
          StatType.strength: 15000.0,
          StatType.agility: 25000.0,
          StatType.endurance: 50000.0,
          StatType.intelligence: 100000.0,
          StatType.focus: 75000.0,
          StatType.charisma: 30000.0,
        };

        final result = StatsService.validateStatsForExport(exportStats);
        expect(result.isValid, isTrue);
        expect(result.sanitizedStats, isNotNull);
        
        // All values should be preserved for export
        for (final entry in exportStats.entries) {
          expect(result.sanitizedStats![entry.key], equals(entry.value));
        }
      });

      test('should warn about extremely large export values', () {
        final extremeExportStats = {
          StatType.strength: 1500000.0,
          StatType.agility: 2000000.0,
        };

        final result = StatsService.validateStatsForExport(extremeExportStats);
        expect(result.isValid, isTrue);
        expect(result.hasWarning, isTrue);
        expect(result.warnings, isNotEmpty);
        
        // Values should still be preserved for export (no clamping)
        expect(result.sanitizedStats![StatType.strength], equals(1500000.0));
        expect(result.sanitizedStats![StatType.agility], equals(2000000.0));
      });

      test('should sanitize invalid values for export', () {
        final invalidExportStats = {
          StatType.strength: double.nan,
          StatType.agility: double.infinity,
          StatType.endurance: -100.0,
          StatType.intelligence: 0.5,
        };

        final result = StatsService.validateStatsForExport(invalidExportStats);
        expect(result.isValid, isFalse);
        expect(result.sanitizedStats, isNotNull);
        
        // Invalid values should be sanitized
        expect(result.sanitizedStats![StatType.strength], equals(1.0));
        expect(result.sanitizedStats![StatType.agility], equals(1.0));
        expect(result.sanitizedStats![StatType.endurance], equals(1.0));
        expect(result.sanitizedStats![StatType.intelligence], equals(1.0));
      });
    });

    group('Performance and Memory Impact Testing', () {
      test('should validate performance implications of large datasets', () {
        final performanceStats = {
          StatType.strength: 999999.0,
          StatType.agility: 888888.0,
          StatType.endurance: 777777.0,
          StatType.intelligence: 666666.0,
          StatType.focus: 555555.0,
          StatType.charisma: 444444.0,
        };

        // Test all validation methods with large values
        final infiniteResult = StatsService.validateInfiniteStats(performanceStats);
        final chartResult = StatsService.validateChartRendering(performanceStats);
        final exportResult = StatsService.validateStatsForExport(performanceStats);

        expect(infiniteResult.isValid, isTrue);
        expect(chartResult.isValid, isTrue);
        expect(exportResult.isValid, isTrue);

        // Should have warnings about performance (at least infinite and chart)
        expect(infiniteResult.hasWarning, isTrue);
        expect(chartResult.hasWarning, isTrue);
        // Export may or may not have warnings depending on threshold
      });

      test('should provide memory usage recommendations', () {
        final memoryTestStats = {
          StatType.strength: 50000.0,
          StatType.agility: 75000.0,
          StatType.endurance: 100000.0,
        };

        final chartResult = StatsService.validateChartRendering(memoryTestStats);
        expect(chartResult.recommendations, contains(matches(r'chart intervals.*memory')));
      });
    });

    group('Edge Case Test Suite Execution', () {
      test('should execute comprehensive edge case test suite', () {
        final testResult = StatsService.testEdgeCaseStatValues();
        
        expect(testResult, isNotNull);
        expect(testResult.testResults, isNotEmpty);
        expect(testResult.issues, isA<List<String>>());
        
        // Verify all test categories are present
        expect(testResult.testResults.containsKey('normal_values_validation'), isTrue);
        expect(testResult.testResults.containsKey('large_values_validation'), isTrue);
        expect(testResult.testResults.containsKey('very_large_values_validation'), isTrue);
        expect(testResult.testResults.containsKey('extreme_values_validation'), isTrue);
        expect(testResult.testResults.containsKey('invalid_values_validation'), isTrue);

        // Normal values should pass all validations
        expect(testResult.testResults['normal_values_validation'], isTrue);
        expect(testResult.testResults['normal_values_chart'], isTrue);
        expect(testResult.testResults['normal_values_export'], isTrue);
        expect(testResult.testResults['normal_values_application'], isTrue);

        // Large values should pass validation
        expect(testResult.testResults['large_values_validation'], isTrue);
        expect(testResult.testResults['large_values_application'], isTrue);

        // Very large values should pass validation with warnings
        expect(testResult.testResults['very_large_values_validation'], isTrue);
        expect(testResult.testResults['very_large_values_application'], isTrue);

        // Extreme values should be handled (may have warnings)
        expect(testResult.testResults['extreme_values_validation'], isTrue);
        expect(testResult.testResults['extreme_values_application'], isTrue);

        // Invalid values should be handled gracefully
        expect(testResult.testResults['invalid_values_validation'], isFalse);
        expect(testResult.testResults['invalid_values_application'], isTrue); // Should work with sanitized values
      });

      test('should handle test suite failures gracefully', () {
        // This test ensures the edge case test suite doesn't crash
        expect(() => StatsService.testEdgeCaseStatValues(), returnsNormally);
        
        final result = StatsService.testEdgeCaseStatValues();
        expect(result.passed, isA<bool>());
        
        // Even if some tests fail, the suite should complete
        if (!result.passed) {
          expect(result.issues, isNotEmpty);
          print('Edge case test issues: ${result.issues}');
        }
      });
    });

    group('Data Integrity and Consistency', () {
      test('should maintain data integrity across all validation methods', () {
        final testStats = {
          StatType.strength: 12345.67,
          StatType.agility: 98765.43,
          StatType.endurance: 55555.55,
          StatType.intelligence: 77777.77,
          StatType.focus: 33333.33,
          StatType.charisma: 11111.11,
        };

        final infiniteResult = StatsService.validateInfiniteStats(testStats);
        final chartResult = StatsService.validateChartRendering(testStats);
        final exportResult = StatsService.validateStatsForExport(testStats);

        // All validations should pass
        expect(infiniteResult.isValid, isTrue);
        expect(chartResult.isValid, isTrue);
        expect(exportResult.isValid, isTrue);

        // Values should be preserved exactly
        for (final entry in testStats.entries) {
          expect(infiniteResult.sanitizedStats![entry.key], equals(entry.value));
          expect(exportResult.sanitizedStats![entry.key], equals(entry.value));
        }
      });

      test('should handle precision preservation in large values', () {
        final precisionStats = {
          StatType.strength: 123456.789012,
          StatType.agility: 987654.321098,
        };

        final result = StatsService.validateInfiniteStats(precisionStats);
        expect(result.isValid, isTrue);
        expect(result.sanitizedStats![StatType.strength], equals(123456.789012));
        expect(result.sanitizedStats![StatType.agility], equals(987654.321098));
      });

      test('should validate consistency between different validation methods', () {
        final consistencyStats = {
          StatType.strength: 50000.0,
          StatType.agility: 75000.0,
          StatType.endurance: 100000.0,
        };

        final infiniteResult = StatsService.validateInfiniteStats(consistencyStats);
        final exportResult = StatsService.validateStatsForExport(consistencyStats);

        // Both should be valid and preserve values
        expect(infiniteResult.isValid, isTrue);
        expect(exportResult.isValid, isTrue);

        for (final entry in consistencyStats.entries) {
          expect(infiniteResult.sanitizedStats![entry.key], equals(entry.value));
          expect(exportResult.sanitizedStats![entry.key], equals(entry.value));
        }
      });
    });

    group('Error Recovery and Resilience', () {
      test('should recover from completely corrupted stat data', () {
        final corruptedStats = {
          StatType.strength: double.nan,
          StatType.agility: double.infinity,
          StatType.endurance: double.negativeInfinity,
          StatType.intelligence: -double.maxFinite,
          StatType.focus: double.maxFinite,
          StatType.charisma: 0.0,
        };

        final result = StatsService.validateInfiniteStats(corruptedStats);
        expect(result.isValid, isFalse);
        expect(result.sanitizedStats, isNotNull);

        // All values should be sanitized to safe values
        for (final statType in StatType.values) {
          final sanitizedValue = result.sanitizedStats![statType]!;
          expect(sanitizedValue, greaterThanOrEqualTo(1.0));
          expect(sanitizedValue, lessThanOrEqualTo(999999.0));
          expect(sanitizedValue.isFinite, isTrue);
          expect(sanitizedValue.isNaN, isFalse);
        }
      });

      test('should provide meaningful error messages for validation failures', () {
        final emptyStats = <StatType, double>{};
        
        final infiniteResult = StatsService.validateInfiniteStats(emptyStats);
        final chartResult = StatsService.validateChartRendering(emptyStats);
        final exportResult = StatsService.validateStatsForExport(emptyStats);

        expect(infiniteResult.isValid, isFalse);
        expect(chartResult.isValid, isFalse);
        expect(exportResult.isValid, isFalse);

        expect(infiniteResult.message, contains('empty'));
        expect(chartResult.message, contains('chart'));
        expect(exportResult.message, contains('export'));
      });

      test('should handle validation exceptions without crashing', () {
        // Test that validation methods don't throw exceptions
        expect(() => StatsService.validateInfiniteStats({}), returnsNormally);
        expect(() => StatsService.validateChartRendering({}), returnsNormally);
        expect(() => StatsService.validateStatsForExport({}), returnsNormally);
        expect(() => StatsService.testEdgeCaseStatValues(), returnsNormally);
      });
    });

    group('Boundary Value Testing', () {
      test('should handle exact boundary values correctly', () {
        final boundaryStats = {
          StatType.strength: 1.0,        // Minimum boundary
          StatType.agility: 999999.0,    // Maximum safe boundary
          StatType.endurance: 1000000.0, // Just above warning threshold
          StatType.intelligence: 0.9999999, // Just below minimum
          StatType.focus: 1000000.0001,  // Just above maximum safe
          StatType.charisma: 5.0,        // Old ceiling boundary
        };

        final result = StatsService.validateInfiniteStats(boundaryStats);
        expect(result.isValid, isTrue);
        expect(result.sanitizedStats, isNotNull);

        expect(result.sanitizedStats![StatType.strength], equals(1.0));
        expect(result.sanitizedStats![StatType.agility], equals(999999.0));
        expect(result.sanitizedStats![StatType.endurance], equals(999999.0)); // Clamped
        expect(result.sanitizedStats![StatType.intelligence], equals(1.0)); // Floored
        expect(result.sanitizedStats![StatType.focus], equals(999999.0)); // Clamped
        expect(result.sanitizedStats![StatType.charisma], equals(5.0));
      });

      test('should handle floating point precision edge cases', () {
        final precisionStats = {
          StatType.strength: 1.0000000000000002, // Near machine epsilon
          StatType.agility: 999999.9999999999,   // Near maximum with precision
        };

        final result = StatsService.validateInfiniteStats(precisionStats);
        expect(result.isValid, isTrue);
        expect(result.sanitizedStats![StatType.strength], closeTo(1.0000000000000002, 1e-15));
        expect(result.sanitizedStats![StatType.agility], closeTo(999999.9999999999, 1e-10));
      });
    });
  });
}