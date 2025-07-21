import 'package:flutter_test/flutter_test.dart';
import 'package:yolvl/services/stats_service.dart';
import 'package:yolvl/models/enums.dart';

void main() {
  group('StatsService - Infinite Stats Validation (Simple)', () {
    test('should validate normal stat values', () {
      final stats = {
        StatType.strength: 5.5,
        StatType.agility: 7.2,
      };

      final result = StatsService.validateInfiniteStats(stats);
      print('Normal stats result: $result');
      
      expect(result.isValid, isTrue);
    });

    test('should handle large stat values', () {
      final stats = {
        StatType.strength: 150000.0,
        StatType.agility: 200000.0,
      };

      final result = StatsService.validateInfiniteStats(stats);
      print('Large stats result: $result');
      print('Sanitized stats: ${result.sanitizedStats}');
      print('Warnings: ${result.warnings}');
    });

    test('should test chart validation', () {
      final stats = {
        StatType.strength: 45.0,
        StatType.agility: 32.0,
      };

      final result = StatsService.validateStatsForChart(stats);
      print('Chart validation result: $result');
      print('Recommended maxY: ${result.recommendedMaxY}');
    });

    test('should test edge case values', () {
      final result = StatsService.testEdgeCaseStatValues();
      print('Edge case test result: $result');
      print('Test results keys: ${result.testResults.keys}');
    });
  });
}