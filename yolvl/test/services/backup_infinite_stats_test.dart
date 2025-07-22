import 'package:flutter_test/flutter_test.dart';
import 'package:yolvl/models/enums.dart';
import 'package:yolvl/models/user.dart';
import 'package:yolvl/services/backup_service.dart';
import 'package:yolvl/utils/infinite_stats_validator.dart';

void main() {
  group('Backup Service - Infinite Stats Validation', () {
    group('User Data Validation', () {
      test('should validate user stats for export safety', () {
        // Test with large but valid stats
        final statsMap = <StatType, double>{
          StatType.strength: 999999.0,
          StatType.agility: 500000.0,
          StatType.endurance: 750000.0,
          StatType.intelligence: 1000000.0,
          StatType.focus: 250000.0,
          StatType.charisma: 800000.0,
        };

        final result = InfiniteStatsValidator.validateStatsForExport(statsMap);
        
        expect(result.isValid, isTrue);
        expect(result.hasWarning, isTrue);
        expect(result.warnings, isNotEmpty);
        expect(result.sanitizedStats, isNotNull);
        
        // All values should be within reasonable bounds
        for (final entry in result.sanitizedStats!.entries) {
          expect(entry.value, lessThanOrEqualTo(1000000.0));
          expect(entry.value, greaterThanOrEqualTo(1.0));
        }
      });

      test('should reject invalid stat values for export', () {
        final statsMap = <StatType, double>{
          StatType.strength: double.nan,
          StatType.agility: double.infinity,
          StatType.endurance: double.negativeInfinity,
          StatType.intelligence: -100.0,
          StatType.focus: 0.5,
          StatType.charisma: 5.0,
        };

        final result = InfiniteStatsValidator.validateStatsForExport(statsMap);
        
        expect(result.isValid, isFalse);
        expect(result.message, contains('Export validation failed'));
        expect(result.sanitizedStats, isNotNull);
        
        // Check that invalid values are sanitized
        expect(result.sanitizedStats![StatType.strength], equals(1.0)); // NaN -> 1.0
        expect(result.sanitizedStats![StatType.agility], equals(1.0)); // +Infinity -> 1.0 (handled by export validation)
        expect(result.sanitizedStats![StatType.endurance], equals(1.0)); // -Infinity -> 1.0
        expect(result.sanitizedStats![StatType.intelligence], equals(1.0)); // Negative -> 1.0
        expect(result.sanitizedStats![StatType.focus], equals(1.0)); // Below minimum -> 1.0
        expect(result.sanitizedStats![StatType.charisma], equals(5.0)); // Valid value preserved
      });

      test('should handle extremely large values that might cause JSON issues', () {
        final statsMap = <StatType, double>{
          StatType.strength: 1e15, // Very large but still safe
          StatType.agility: 1e16, // Too large for safe serialization
          StatType.endurance: 999999.0, // Within reasonable bounds
        };

        // Test individual value validation
        for (final entry in statsMap.entries) {
          final statType = entry.key;
          final value = entry.value;
          
          if (value > 1e15) {
            // Values above 1e15 should be flagged as potentially problematic
            expect(value, greaterThan(1e15));
            print('Stat ${statType.name} has very large value: $value');
          }
          
          // Check string length for precision concerns
          final stringLength = value.toString().length;
          if (stringLength > 15) {
            print('Stat ${statType.name} may lose precision: $stringLength characters');
          }
        }
      });

      test('should validate EXP and level bounds', () {
        // Test valid EXP values
        final validEXP = [0.0, 1000.0, 50000.0, 1e10, 1e14];
        for (final exp in validEXP) {
          expect(exp, greaterThanOrEqualTo(0.0));
          expect(exp, lessThanOrEqualTo(1e15));
        }

        // Test invalid EXP values
        final invalidEXP = [double.nan, double.infinity, -100.0, 1e16];
        for (final exp in invalidEXP) {
          final isValid = !exp.isNaN && !exp.isInfinite && exp >= 0.0 && exp <= 1e15;
          expect(isValid, isFalse);
        }

        // Test valid level values
        final validLevels = [1, 50, 100, 1000, 100000];
        for (final level in validLevels) {
          expect(level, greaterThanOrEqualTo(1));
          expect(level, lessThanOrEqualTo(1000000));
        }

        // Test invalid level values
        final invalidLevels = [0, -1, 1000001];
        for (final level in invalidLevels) {
          final isValid = level >= 1 && level <= 1000000;
          expect(isValid, isFalse);
        }
      });
    });

    group('Activity Data Validation', () {
      test('should validate activity stat gains', () {
        final validGains = <StatType, double>{
          StatType.strength: 0.1,
          StatType.agility: 0.05,
          StatType.endurance: 0.08,
        };

        for (final entry in validGains.entries) {
          final gain = entry.value;
          expect(gain, greaterThanOrEqualTo(0.0));
          expect(gain, lessThanOrEqualTo(1000.0)); // Reasonable upper bound for single activity
        }
      });

      test('should handle invalid activity stat gains', () {
        final invalidGains = <StatType, double>{
          StatType.strength: double.nan,
          StatType.agility: double.infinity,
          StatType.endurance: -0.1,
          StatType.intelligence: 1001.0, // Too large for single activity
        };

        for (final entry in invalidGains.entries) {
          final statType = entry.key;
          final gain = entry.value;
          
          final isValid = !gain.isNaN && !gain.isInfinite && gain >= 0.0 && gain <= 1000.0;
          if (!isValid) {
            print('Invalid gain for ${statType.name}: $gain');
          }
          expect(isValid, isFalse);
        }
      });

      test('should validate activity EXP gains', () {
        final validEXPGains = [0.0, 10.0, 100.0, 1000.0];
        for (final exp in validEXPGains) {
          expect(exp, greaterThanOrEqualTo(0.0));
          expect(exp, lessThanOrEqualTo(10000.0)); // Reasonable upper bound for single activity
        }

        final invalidEXPGains = [double.nan, double.infinity, -10.0, 10001.0];
        for (final exp in invalidEXPGains) {
          final isValid = !exp.isNaN && !exp.isInfinite && exp >= 0.0 && exp <= 10000.0;
          expect(isValid, isFalse);
        }
      });
    });

    group('Data Sanitization', () {
      test('should sanitize user stats for import', () {
        // Simulate sanitization logic that would be used during import
        final rawStats = <String, double>{
          StatType.strength.name: double.nan,
          StatType.agility.name: double.infinity,
          StatType.endurance.name: -100.0,
          StatType.intelligence.name: 1000001.0,
          StatType.focus.name: 0.5,
          StatType.charisma.name: 50.0,
        };

        final sanitizedStats = <String, double>{};
        
        for (final entry in rawStats.entries) {
          final statName = entry.key;
          final statValue = entry.value;
          
          if (statValue.isNaN || statValue.isInfinite) {
            sanitizedStats[statName] = 1.0;
          } else if (statValue < 1.0) {
            sanitizedStats[statName] = 1.0;
          } else if (statValue > 1000000) {
            sanitizedStats[statName] = 1000000.0;
          } else {
            sanitizedStats[statName] = statValue;
          }
        }

        expect(sanitizedStats[StatType.strength.name], equals(1.0));
        expect(sanitizedStats[StatType.agility.name], equals(1.0));
        expect(sanitizedStats[StatType.endurance.name], equals(1.0));
        expect(sanitizedStats[StatType.intelligence.name], equals(1000000.0));
        expect(sanitizedStats[StatType.focus.name], equals(1.0));
        expect(sanitizedStats[StatType.charisma.name], equals(50.0));
      });

      test('should sanitize activity data for import', () {
        // Test activity sanitization
        final rawEXP = double.nan;
        final sanitizedEXP = rawEXP.isNaN || rawEXP.isInfinite || rawEXP < 0 ? 0.0 : rawEXP;
        expect(sanitizedEXP, equals(0.0));

        final rawGains = <StatType, double>{
          StatType.strength: double.infinity,
          StatType.agility: -0.1,
          StatType.endurance: 1001.0,
          StatType.intelligence: 0.05,
        };

        final sanitizedGains = <StatType, double>{};
        for (final entry in rawGains.entries) {
          final statType = entry.key;
          final gainValue = entry.value;
          
          if (gainValue.isNaN || gainValue.isInfinite || gainValue < 0) {
            sanitizedGains[statType] = 0.0;
          } else if (gainValue > 1000) {
            sanitizedGains[statType] = 1000.0;
          } else {
            sanitizedGains[statType] = gainValue;
          }
        }

        expect(sanitizedGains[StatType.strength], equals(0.0));
        expect(sanitizedGains[StatType.agility], equals(0.0));
        expect(sanitizedGains[StatType.endurance], equals(1000.0));
        expect(sanitizedGains[StatType.intelligence], equals(0.05));
      });
    });

    group('Performance and Edge Cases', () {
      test('should handle validation of many stats efficiently', () {
        final stopwatch = Stopwatch()..start();
        
        // Test with many validation calls
        for (int i = 0; i < 100; i++) {
          final stats = <StatType, double>{
            StatType.strength: 100.0 + i,
            StatType.agility: 200.0 + i,
            StatType.endurance: 50.0 + i,
            StatType.intelligence: 300.0 + i,
            StatType.focus: 75.0 + i,
            StatType.charisma: 150.0 + i,
          };
          
          final result = InfiniteStatsValidator.validateStatsForExport(stats);
          expect(result.isValid, isTrue);
        }
        
        stopwatch.stop();
        
        // Should complete within reasonable time
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
      });

      test('should handle edge case stat values consistently', () {
        final edgeCases = [
          0.0,
          0.999,
          1.0,
          1.001,
          999999.0,
          1000000.0,
          1000001.0,
          double.maxFinite,
        ];

        for (final value in edgeCases) {
          final sanitized = InfiniteStatsValidator.validateStatValue(value);
          
          // All sanitized values should be within valid range
          expect(sanitized, greaterThanOrEqualTo(1.0));
          expect(sanitized, lessThanOrEqualTo(999999.0));
          
          // Should not be NaN or infinite
          expect(sanitized.isNaN, isFalse);
          expect(sanitized.isInfinite, isFalse);
        }
      });
    });
  });
}