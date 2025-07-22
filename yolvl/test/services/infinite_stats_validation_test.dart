import 'package:flutter_test/flutter_test.dart';
import 'package:yolvl/models/enums.dart';
import 'package:yolvl/utils/infinite_stats_validator.dart';

void main() {
  group('InfiniteStatsValidator', () {
    test('validateStatValue handles normal values correctly', () {
      expect(InfiniteStatsValidator.validateStatValue(5.0), 5.0);
      expect(InfiniteStatsValidator.validateStatValue(10.5), 10.5);
      expect(InfiniteStatsValidator.validateStatValue(100.0), 100.0);
    });

    test('validateStatValue handles invalid values correctly', () {
      expect(InfiniteStatsValidator.validateStatValue(double.nan), 1.0);
      expect(InfiniteStatsValidator.validateStatValue(double.infinity), 999999.0);
      expect(InfiniteStatsValidator.validateStatValue(double.negativeInfinity), 1.0);
      expect(InfiniteStatsValidator.validateStatValue(-5.0), 1.0);
      expect(InfiniteStatsValidator.validateStatValue(0.5), 1.0);
    });

    test('validateStatValue handles extremely large values correctly', () {
      expect(InfiniteStatsValidator.validateStatValue(1000000.0), 999999.0);
      expect(InfiniteStatsValidator.validateStatValue(9999999.0), 999999.0);
    });

    test('validateStats handles map of stats correctly', () {
      final stats = <StatType, double>{
        StatType.strength: 5.0,
        StatType.agility: double.nan,
        StatType.endurance: -1.0,
        StatType.intelligence: 1000000.0,
        StatType.focus: 10.5,
        StatType.charisma: double.infinity,
      };

      final sanitized = InfiniteStatsValidator.validateStats(stats);
      
      expect(sanitized[StatType.strength], 5.0);
      expect(sanitized[StatType.agility], 1.0);
      expect(sanitized[StatType.endurance], 1.0);
      expect(sanitized[StatType.intelligence], 999999.0);
      expect(sanitized[StatType.focus], 10.5);
      expect(sanitized[StatType.charisma], 999999.0);
    });

    test('validateInfiniteStats returns valid result for normal stats', () {
      final stats = <StatType, double>{
        StatType.strength: 5.0,
        StatType.agility: 7.2,
        StatType.endurance: 3.8,
        StatType.intelligence: 9.1,
        StatType.focus: 6.4,
        StatType.charisma: 4.7,
      };

      final result = InfiniteStatsValidator.validateInfiniteStats(stats);
      
      expect(result.isValid, true);
      expect(result.hasWarning, false);
      expect(result.message, null);
    });

    test('validateInfiniteStats returns warning for very large stats', () {
      final stats = <StatType, double>{
        StatType.strength: 150000.0,
        StatType.agility: 200000.0,
        StatType.endurance: 99000.0,
        StatType.intelligence: 500000.0,
        StatType.focus: 75000.0,
        StatType.charisma: 300000.0,
      };

      final result = InfiniteStatsValidator.validateInfiniteStats(stats);
      
      expect(result.isValid, true);
      expect(result.hasWarning, true);
      expect(result.message, contains('Very large stat values may impact performance'));
    });

    test('validateInfiniteStats returns invalid for NaN or infinite stats', () {
      final stats = <StatType, double>{
        StatType.strength: 5.0,
        StatType.agility: double.nan,
        StatType.endurance: 3.8,
        StatType.intelligence: 9.1,
        StatType.focus: 6.4,
        StatType.charisma: 4.7,
      };

      final result = InfiniteStatsValidator.validateInfiniteStats(stats);
      
      expect(result.isValid, false);
      expect(result.message, contains('Critical validation issues'));
      expect(result.sanitizedStats, isNotNull);
      expect(result.sanitizedStats![StatType.agility], 1.0);
    });

    test('validateStatsForChart returns valid result with recommended maxY', () {
      final stats = <StatType, double>{
        StatType.strength: 5.0,
        StatType.agility: 7.2,
        StatType.endurance: 3.8,
        StatType.intelligence: 9.1,
        StatType.focus: 6.4,
        StatType.charisma: 4.7,
      };

      final result = InfiniteStatsValidator.validateStatsForChart(stats);
      
      expect(result.isValid, true);
      expect(result.recommendedMaxY, 10.0);
    });

    test('validateStatsForChart handles very large values', () {
      final stats = <StatType, double>{
        StatType.strength: 150.0,
        StatType.agility: 200.0,
        StatType.endurance: 99.0,
        StatType.intelligence: 500.0,
        StatType.focus: 75.0,
        StatType.charisma: 300.0,
      };

      final result = InfiniteStatsValidator.validateStatsForChart(stats);
      
      expect(result.isValid, true);
      expect(result.recommendedMaxY, 500.0);
    });

    test('validateStatsForExport handles normal values correctly', () {
      final stats = <StatType, double>{
        StatType.strength: 5.0,
        StatType.agility: 7.2,
        StatType.endurance: 3.8,
        StatType.intelligence: 9.1,
        StatType.focus: 6.4,
        StatType.charisma: 4.7,
      };

      final result = InfiniteStatsValidator.validateStatsForExport(stats);
      
      expect(result.isValid, true);
      expect(result.hasWarning, false);
    });

    test('validateStatsForExport handles invalid values correctly', () {
      final stats = <StatType, double>{
        StatType.strength: 5.0,
        StatType.agility: double.nan,
        StatType.endurance: 3.8,
        StatType.intelligence: 9.1,
        StatType.focus: 6.4,
        StatType.charisma: 4.7,
      };

      final result = InfiniteStatsValidator.validateStatsForExport(stats);
      
      expect(result.isValid, false);
      expect(result.message, contains('Export validation failed'));
      expect(result.sanitizedStats, isNotNull);
      expect(result.sanitizedStats![StatType.agility], 1.0);
    });

    test('testEdgeCaseStatValues runs all test cases', () {
      final result = InfiniteStatsValidator.testEdgeCaseStatValues();
      
      expect(result.passed, true);
      expect(result.issues, isEmpty);
      expect(result.testResults['normal_values_validation'], true);
      expect(result.testResults['large_values_validation'], true);
      expect(result.testResults['very_large_values_validation'], true);
      expect(result.testResults['extreme_values_validation'], true);
      expect(result.testResults['invalid_values_validation'], false);
    });
  });
}