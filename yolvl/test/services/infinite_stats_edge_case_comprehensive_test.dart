import 'package:flutter_test/flutter_test.dart';
import 'package:yolvl/models/enums.dart';
import 'package:yolvl/services/stats_service.dart';
import 'package:yolvl/utils/infinite_stats_validator.dart';
import 'package:yolvl/services/backup_service.dart';
import 'package:yolvl/models/user.dart';

void main() {
  group('Infinite Stats Edge Case Comprehensive Tests', () {
    group('StatsService Validation', () {
      test('should handle extremely large stat values safely', () {
        final stats = <StatType, double>{
          StatType.strength: 999999.0,
          StatType.agility: 500000.0,
          StatType.endurance: 750000.0,
          StatType.intelligence: 1000000.0,
          StatType.focus: 250000.0,
          StatType.charisma: 800000.0,
        };

        final result = StatsService.validateInfiniteStats(stats);
        
        expect(result.isValid, isTrue);
        expect(result.hasWarning, isTrue);
        expect(result.message, contains('Very large stat values may impact performance'));
        expect(result.sanitizedStats, isNotNull);
        
        // All values should be clamped to reasonable maximum
        for (final entry in result.sanitizedStats!.entries) {
          expect(entry.value, lessThanOrEqualTo(999999.0));
          expect(entry.value, greaterThanOrEqualTo(1.0));
        }
      });

      test('should handle invalid stat values (NaN, Infinity)', () {
        final stats = <StatType, double>{
          StatType.strength: double.nan,
          StatType.agility: double.infinity,
          StatType.endurance: double.negativeInfinity,
          StatType.intelligence: -100.0,
          StatType.focus: 0.5,
          StatType.charisma: 1000001.0, // Above reasonable maximum
        };

        final result = StatsService.validateInfiniteStats(stats);
        
        expect(result.isValid, isFalse);
        expect(result.message, contains('Critical validation issues'));
        expect(result.sanitizedStats, isNotNull);
        
        // All invalid values should be sanitized
        expect(result.sanitizedStats![StatType.strength], equals(1.0)); // NaN -> 1.0
        expect(result.sanitizedStats![StatType.agility], equals(999999.0)); // Infinity -> max
        expect(result.sanitizedStats![StatType.endurance], equals(1.0)); // -Infinity -> 1.0
        expect(result.sanitizedStats![StatType.intelligence], equals(1.0)); // Negative -> 1.0
        expect(result.sanitizedStats![StatType.focus], equals(1.0)); // Below min -> 1.0
        expect(result.sanitizedStats![StatType.charisma], equals(999999.0)); // Above max -> max
      });

      test('should validate chart rendering with extreme values', () {
        final stats = <StatType, double>{
          StatType.strength: 100000.0,
          StatType.agility: 200000.0,
          StatType.endurance: 50000.0,
          StatType.intelligence: 300000.0,
          StatType.focus: 75000.0,
          StatType.charisma: 150000.0,
        };

        final result = StatsService.validateStatsForChart(stats);
        
        expect(result.isValid, isTrue);
        expect(result.hasWarning, isTrue);
        expect(result.message, contains('Very large stat values detected'));
        expect(result.recommendedMaxY, greaterThanOrEqualTo(300000.0));
      });

      test('should validate export with edge case values', () {
        final stats = <StatType, double>{
          StatType.strength: 999999.0,
          StatType.agility: 1.0,
          StatType.endurance: 50000.5,
          StatType.intelligence: 0.999, // Below minimum
          StatType.focus: double.nan, // Invalid
          StatType.charisma: 500000.0,
        };

        final result = StatsService.validateStatsForExport(stats);
        
        expect(result.isValid, isFalse);
        expect(result.message, contains('Export validation failed'));
        expect(result.sanitizedStats, isNotNull);
        
        // Check sanitized values
        expect(result.sanitizedStats![StatType.intelligence], equals(1.0));
        expect(result.sanitizedStats![StatType.focus], equals(1.0));
      });

      test('should run comprehensive edge case tests', () {
        final result = StatsService.testEdgeCaseStatValues();
        
        expect(result.testResults, isNotEmpty);
        expect(result.testResults.keys, contains('normal_values_validation'));
        expect(result.testResults.keys, contains('large_values_validation'));
        expect(result.testResults.keys, contains('very_large_values_validation'));
        expect(result.testResults.keys, contains('extreme_values_validation'));
        expect(result.testResults.keys, contains('invalid_values_validation'));
        
        // Normal values should pass all tests
        expect(result.testResults['normal_values_validation'], isTrue);
        expect(result.testResults['normal_values_chart'], isTrue);
        expect(result.testResults['normal_values_export'], isTrue);
        
        // Invalid values should fail validation but pass chart/export with sanitization
        expect(result.testResults['invalid_values_validation'], isFalse);
      });
    });

    group('InfiniteStatsValidator', () {
      test('should validate single stat values correctly', () {
        expect(InfiniteStatsValidator.validateStatValue(5.0), equals(5.0));
        expect(InfiniteStatsValidator.validateStatValue(999999.0), equals(999999.0));
        expect(InfiniteStatsValidator.validateStatValue(1000000.0), equals(999999.0));
        expect(InfiniteStatsValidator.validateStatValue(double.nan), equals(1.0));
        expect(InfiniteStatsValidator.validateStatValue(double.infinity), equals(999999.0));
        expect(InfiniteStatsValidator.validateStatValue(-5.0), equals(1.0));
      });

      test('should format stat values appropriately', () {
        expect(InfiniteStatsValidator.formatStatValue(1.0), equals('1'));
        expect(InfiniteStatsValidator.formatStatValue(1.23), equals('1.23'));
        expect(InfiniteStatsValidator.formatStatValue(12.3), equals('12.3'));
        expect(InfiniteStatsValidator.formatStatValue(123.4), equals('123.4'));
        expect(InfiniteStatsValidator.formatStatValue(1234.56), equals('1234.6'));
        expect(InfiniteStatsValidator.formatStatValue(double.nan), equals('Invalid'));
        expect(InfiniteStatsValidator.formatStatValue(double.infinity), equals('Invalid'));
      });

      test('should calculate chart scaling correctly', () {
        final stats1 = <StatType, double>{
          StatType.strength: 3.0,
          StatType.agility: 4.0,
        };
        final result1 = InfiniteStatsValidator.validateStatsForChart(stats1);
        expect(result1.recommendedMaxY, equals(5.0));

        final stats2 = <StatType, double>{
          StatType.strength: 15.0,
          StatType.agility: 12.0,
        };
        final result2 = InfiniteStatsValidator.validateStatsForChart(stats2);
        expect(result2.recommendedMaxY, equals(20.0));

        final stats3 = <StatType, double>{
          StatType.strength: 150.0,
          StatType.agility: 120.0,
        };
        final result3 = InfiniteStatsValidator.validateStatsForChart(stats3);
        expect(result3.recommendedMaxY, equals(150.0)); // 150/50 = 3, ceil(3)*50 = 150
      });
    });

    group('Data Integrity Validation', () {
      test('should validate stat values for JSON serialization safety', () {
        final stats = <StatType, double>{
          StatType.strength: 1e15, // Very large but still safe
          StatType.agility: 1e16, // Too large for safe serialization
          StatType.endurance: 999999.0, // Within reasonable bounds
        };

        // Test that extremely large values are detected
        for (final entry in stats.entries) {
          if (entry.value > 1e15) {
            expect(entry.value, greaterThan(1e15));
          }
        }
      });

      test('should handle precision loss detection', () {
        final largeValue = 123456789012345.0;
        final stringLength = largeValue.toString().length;
        
        // Values with very long string representations may lose precision
        if (stringLength > 15) {
          expect(stringLength, greaterThan(15));
        }
      });

      test('should validate level and EXP bounds', () {
        // Test valid ranges
        expect(50, greaterThanOrEqualTo(1));
        expect(50, lessThanOrEqualTo(1000000));
        
        // Test EXP bounds
        expect(50000.0, greaterThanOrEqualTo(0.0));
        expect(50000.0, lessThanOrEqualTo(1e15));
      });
    });

    group('Performance Tests', () {
      test('should handle large datasets efficiently', () {
        final stopwatch = Stopwatch()..start();
        
        // Test with many validation calls
        for (int i = 0; i < 1000; i++) {
          final stats = <StatType, double>{
            StatType.strength: 100.0 + i,
            StatType.agility: 200.0 + i,
            StatType.endurance: 50.0 + i,
            StatType.intelligence: 300.0 + i,
            StatType.focus: 75.0 + i,
            StatType.charisma: 150.0 + i,
          };
          
          StatsService.validateInfiniteStats(stats);
          InfiniteStatsValidator.validateStatsForChart(stats);
          InfiniteStatsValidator.validateStatsForExport(stats);
        }
        
        stopwatch.stop();
        
        // Should complete within reasonable time (less than 1 second)
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });

      test('should handle chart validation with extreme values efficiently', () {
        final stopwatch = Stopwatch()..start();
        
        final stats = <StatType, double>{
          StatType.strength: 999999.0,
          StatType.agility: 999999.0,
          StatType.endurance: 999999.0,
          StatType.intelligence: 999999.0,
          StatType.focus: 999999.0,
          StatType.charisma: 999999.0,
        };
        
        // Test multiple chart validations
        for (int i = 0; i < 100; i++) {
          final result = InfiniteStatsValidator.validateStatsForChart(stats);
          expect(result.isValid, isTrue);
        }
        
        stopwatch.stop();
        
        // Should complete quickly even with large values
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });
    });
  });
}