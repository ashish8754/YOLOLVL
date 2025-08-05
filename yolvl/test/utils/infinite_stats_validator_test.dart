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

    test('validateStatValue handles edge cases correctly', () {
      // Below minimum
      expect(InfiniteStatsValidator.validateStatValue(0.5), 1.0);
      expect(InfiniteStatsValidator.validateStatValue(-10.0), 1.0);
      
      // Special values
      expect(InfiniteStatsValidator.validateStatValue(double.nan), 1.0);
      expect(InfiniteStatsValidator.validateStatValue(double.infinity), 999999.0);
      expect(InfiniteStatsValidator.validateStatValue(double.negativeInfinity), 1.0);
      
      // Extremely large values
      expect(InfiniteStatsValidator.validateStatValue(1000000.0), 999999.0);
    });

    test('validateStats handles all stat types', () {
      final stats = <StatType, double>{
        StatType.strength: 5.0,
        StatType.agility: 3.5,
      };
      
      final validated = InfiniteStatsValidator.validateStats(stats);
      
      // Should include all stat types
      for (final statType in StatType.values) {
        expect(validated.containsKey(statType), true);
      }
      
      // Original values should be preserved
      expect(validated[StatType.strength], 5.0);
      expect(validated[StatType.agility], 3.5);
      
      // Missing values should be set to minimum
      expect(validated[StatType.endurance], 1.0);
    });

    test('validateForStorage handles valid stats', () {
      final stats = <StatType, double>{
        StatType.strength: 5.0,
        StatType.agility: 3.5,
        StatType.endurance: 7.2,
        StatType.intelligence: 4.8,
        StatType.focus: 6.1,
        StatType.charisma: 2.9,
      };
      
      final result = InfiniteStatsValidator.validateForStorage(stats);
      
      expect(result.isValid, true);
      expect(result.hasWarning, false);
      expect(result.sanitizedStats, isNotNull);
    });

    test('validateForStorage handles invalid stats', () {
      final stats = <StatType, double>{
        StatType.strength: double.nan,
        StatType.agility: 3.5,
        StatType.endurance: double.infinity,
        StatType.intelligence: -1.0,
        StatType.focus: 0.5,
        StatType.charisma: 2.9,
      };
      
      final result = InfiniteStatsValidator.validateForStorage(stats);
      
      expect(result.isValid, false);
      expect(result.sanitizedStats, isNotNull);
      
      // Check that invalid values were sanitized
      expect(result.sanitizedStats![StatType.strength], 1.0); // NaN -> 1.0
      expect(result.sanitizedStats![StatType.endurance], 999999.0); // Infinity -> MAX
      expect(result.sanitizedStats![StatType.intelligence], 1.0); // -1.0 -> 1.0
      expect(result.sanitizedStats![StatType.focus], 1.0); // 0.5 -> 1.0
      expect(result.sanitizedStats![StatType.charisma], 2.9); // Valid value preserved
    });

    test('validateForChart calculates appropriate chart maximum', () {
      // Small values
      final smallStats = <StatType, double>{
        StatType.strength: 3.0,
        StatType.agility: 4.5,
        StatType.endurance: 2.2,
      };
      
      final smallResult = InfiniteStatsValidator.validateForChart(smallStats);
      expect(smallResult.isValid, true);
      expect(smallResult.recommendedMaxY, 5.0);
      
      // Medium values
      final mediumStats = <StatType, double>{
        StatType.strength: 8.0,
        StatType.agility: 12.5,
        StatType.endurance: 7.2,
      };
      
      final mediumResult = InfiniteStatsValidator.validateForChart(mediumStats);
      expect(mediumResult.isValid, true);
      expect(mediumResult.recommendedMaxY, 20.0);
      
      // Large values
      final largeStats = <StatType, double>{
        StatType.strength: 80.0,
        StatType.agility: 125.5,
        StatType.endurance: 72.2,
      };
      
      final largeResult = InfiniteStatsValidator.validateForChart(largeStats);
      expect(largeResult.isValid, true);
      expect(largeResult.recommendedMaxY, 130.0);
    });

    test('validateForChart handles invalid values', () {
      final invalidStats = <StatType, double>{
        StatType.strength: double.nan,
        StatType.agility: double.infinity,
      };
      
      final result = InfiniteStatsValidator.validateForChart(invalidStats);
      expect(result.isValid, false);
      expect(result.message, isNotEmpty);
    });
  });
}