import 'package:flutter_test/flutter_test.dart';
import 'package:yolvl/models/activity_log.dart';
import 'package:yolvl/models/enums.dart';

void main() {
  group('ActivityLog Deserialization Crash Fix Tests', () {
    group('Legacy Activity Type Handling', () {
      test('should handle legacy workoutWeights activity type', () {
        final json = {
          'id': 'legacy_test',
          'activityType': 'workoutWeights', // Legacy type that was removed
          'durationMinutes': 60,
          'timestamp': '2024-01-15T10:30:00.000Z',
          'statGains': {},
          'expGained': 60.0,
          'notes': 'Legacy workout',
        };

        expect(() => ActivityLog.fromJson(json), returnsNormally);
        
        final activity = ActivityLog.fromJson(json);
        expect(activity.activityType, equals('workoutUpperBody')); // Should be mapped
        expect(activity.activityTypeEnum, equals(ActivityType.workoutUpperBody));
        expect(activity.id, equals('legacy_test'));
        expect(activity.durationMinutes, equals(60));
      });

      test('should handle unknown activity types gracefully', () {
        final json = {
          'id': 'unknown_test',
          'activityType': 'unknownActivityType',
          'durationMinutes': 45,
          'timestamp': '2024-01-15T10:30:00.000Z',
          'statGains': {},
          'expGained': 45.0,
        };

        expect(() => ActivityLog.fromJson(json), returnsNormally);
        
        final activity = ActivityLog.fromJson(json);
        expect(activity.activityTypeEnum, equals(ActivityType.workoutUpperBody)); // Default fallback
      });
    });

    group('Missing Field Handling', () {
      test('should handle completely missing fields', () {
        final json = <String, dynamic>{};

        expect(() => ActivityLog.fromJson(json), returnsNormally);
        
        final activity = ActivityLog.fromJson(json);
        expect(activity.id, isNotEmpty);
        expect(activity.activityType, equals('workoutUpperBody'));
        expect(activity.durationMinutes, equals(0));
        expect(activity.timestamp, isA<DateTime>());
        expect(activity.statGains, isEmpty);
        expect(activity.expGained, equals(0.0));
        expect(activity.notes, isNull);
      });

      test('should handle null values gracefully', () {
        final json = {
          'id': null,
          'activityType': null,
          'durationMinutes': null,
          'timestamp': null,
          'statGains': null,
          'expGained': null,
          'notes': null,
        };

        expect(() => ActivityLog.fromJson(json), returnsNormally);
        
        final activity = ActivityLog.fromJson(json);
        expect(activity.id, isNotEmpty);
        expect(activity.activityType, equals('workoutUpperBody'));
        expect(activity.durationMinutes, equals(0));
        expect(activity.timestamp, isA<DateTime>());
        expect(activity.statGains, isEmpty);
        expect(activity.expGained, equals(0.0));
        expect(activity.notes, isNull);
      });

      test('should handle empty string values', () {
        final json = {
          'id': '',
          'activityType': '',
          'durationMinutes': 30,
          'timestamp': '2024-01-15T10:30:00.000Z',
          'statGains': {},
          'expGained': 30.0,
          'notes': '',
        };

        expect(() => ActivityLog.fromJson(json), returnsNormally);
        
        final activity = ActivityLog.fromJson(json);
        expect(activity.id, isNotEmpty); // Should generate a fallback ID
        expect(activity.activityType, equals('workoutUpperBody')); // Should use default
        expect(activity.notes, isNull); // Empty string should become null
      });
    });

    group('Invalid Data Type Handling', () {
      test('should handle wrong data types gracefully', () {
        final json = {
          'id': 12345, // Should be string
          'activityType': ['invalid', 'array'], // Should be string
          'durationMinutes': 'not_a_number', // Should be int
          'timestamp': 'invalid_date', // Should parse
          'statGains': 'not_a_map', // Should be map
          'expGained': 'not_a_number', // Should be double
          'notes': 42, // Should be string
        };

        expect(() => ActivityLog.fromJson(json), returnsNormally);
        
        final activity = ActivityLog.fromJson(json);
        expect(activity.id, equals('12345')); // Converted to string
        expect(activity.activityType, equals('workoutUpperBody')); // Default fallback
        expect(activity.durationMinutes, equals(0)); // Invalid number becomes 0
        expect(activity.timestamp, isA<DateTime>()); // Should have fallback timestamp
        expect(activity.statGains, isEmpty); // Invalid map becomes empty
        expect(activity.expGained, equals(0.0)); // Invalid number becomes 0
        expect(activity.notes, equals('42')); // Converted to string
      });

      test('should handle numeric strings properly', () {
        final json = {
          'id': 'string_test',
          'activityType': 'meditation',
          'durationMinutes': '45', // String number
          'timestamp': '2024-01-15T10:30:00.000Z',
          'statGains': {},
          'expGained': '45.5', // String double
          'notes': 'String numbers test',
        };

        expect(() => ActivityLog.fromJson(json), returnsNormally);
        
        final activity = ActivityLog.fromJson(json);
        expect(activity.durationMinutes, equals(45)); // Parsed correctly
        expect(activity.expGained, equals(45.5)); // Parsed correctly
      });
    });

    group('Timestamp Parsing Edge Cases', () {
      test('should handle various timestamp formats', () {
        final testCases = [
          {
            'timestamp': '2024-01-15T10:30:00.000Z', // ISO 8601
            'expected': true,
          },
          {
            'timestamp': '1705316200000', // Milliseconds since epoch as string
            'expected': true,
          },
          {
            'timestamp': 1705316200000, // Milliseconds since epoch as int
            'expected': true,
          },
          {
            'timestamp': 'invalid_date',
            'expected': false, // Should fallback to current time
          },
        ];

        for (final testCase in testCases) {
          final json = {
            'id': 'timestamp_test',
            'activityType': 'meditation',
            'durationMinutes': 30,
            'timestamp': testCase['timestamp'],
            'statGains': {},
            'expGained': 30.0,
          };

          expect(() => ActivityLog.fromJson(json), returnsNormally);
          
          final activity = ActivityLog.fromJson(json);
          expect(activity.timestamp, isA<DateTime>());
          
          if (testCase['expected'] as bool) {
            // For valid timestamps, should not be current time
            expect(activity.timestamp.year, equals(2024));
          }
        }
      });
    });

    group('StatGains Map Corruption Handling', () {
      test('should handle corrupted stat gains map', () {
        final json = {
          'id': 'stat_gains_test',
          'activityType': 'workoutUpperBody',
          'durationMinutes': 60,
          'timestamp': '2024-01-15T10:30:00.000Z',
          'statGains': {
            'strength': 'invalid_number',
            'endurance': null,
            123: 0.05, // Invalid key type
            'agility': double.infinity, // Invalid value
            'intelligence': -100.0, // Negative value
            'focus': 1000.0, // Extremely high value
          },
          'expGained': 60.0,
        };

        expect(() => ActivityLog.fromJson(json), returnsNormally);
        
        final activity = ActivityLog.fromJson(json);
        expect(activity.statGains, isA<Map<String, double>>());
        
        // Should only contain valid entries with clamped values
        for (final entry in activity.statGains.entries) {
          expect(entry.key, isA<String>());
          expect(entry.value, isA<double>());
          expect(entry.value, greaterThanOrEqualTo(0.0));
          expect(entry.value, lessThanOrEqualTo(10.0)); // Should be clamped
        }
      });
    });

    group('Boundary Value Testing', () {
      test('should clamp extreme duration values', () {
        final testCases = [
          {'duration': -100, 'expected': 0}, // Negative
          {'duration': 0, 'expected': 0}, // Zero
          {'duration': 1440, 'expected': 1440}, // 24 hours (max)
          {'duration': 2000, 'expected': 1440}, // Above max, should clamp
        ];

        for (final testCase in testCases) {
          final json = {
            'id': 'duration_test',
            'activityType': 'meditation',
            'durationMinutes': testCase['duration'],
            'timestamp': '2024-01-15T10:30:00.000Z',
            'statGains': {},
            'expGained': 30.0,
          };

          final activity = ActivityLog.fromJson(json);
          expect(activity.durationMinutes, equals(testCase['expected']));
        }
      });

      test('should clamp extreme EXP values', () {
        final testCases = [
          {'exp': -100.0, 'expected': 0.0}, // Negative
          {'exp': 0.0, 'expected': 0.0}, // Zero
          {'exp': 10000.0, 'expected': 10000.0}, // Max
          {'exp': 50000.0, 'expected': 10000.0}, // Above max, should clamp
        ];

        for (final testCase in testCases) {
          final json = {
            'id': 'exp_test',
            'activityType': 'meditation',
            'durationMinutes': 30,
            'timestamp': '2024-01-15T10:30:00.000Z',
            'statGains': {},
            'expGained': testCase['exp'],
          };

          final activity = ActivityLog.fromJson(json);
          expect(activity.expGained, equals(testCase['expected']));
        }
      });

      test('should limit notes length', () {
        final longNotes = 'x' * 2000; // 2000 characters
        final json = {
          'id': 'notes_test',
          'activityType': 'meditation',
          'durationMinutes': 30,
          'timestamp': '2024-01-15T10:30:00.000Z',
          'statGains': {},
          'expGained': 30.0,
          'notes': longNotes,
        };

        final activity = ActivityLog.fromJson(json);
        expect(activity.notes!.length, lessThanOrEqualTo(1000)); // Should be truncated
      });
    });

    group('Ultimate Recovery Test', () {
      test('should handle completely corrupted JSON', () {
        // Simulate completely malformed data that could crash the app
        final json = {
          'completely': 'wrong',
          'structure': 123,
          'array': [1, 2, 3],
          'nested': {'deep': {'data': 'corruption'}},
        };

        expect(() => ActivityLog.fromJson(json), returnsNormally);
        
        final activity = ActivityLog.fromJson(json);
        // The normal parsing flow will handle this gracefully, not the ultimate recovery
        expect(activity.id, startsWith('unknown_'));
        expect(activity.activityType, equals('workoutUpperBody'));
        expect(activity.durationMinutes, equals(0));
        expect(activity.timestamp, isA<DateTime>());
        expect(activity.statGains, isEmpty);
        expect(activity.expGained, equals(0.0));
        expect(activity.notes, isNull);
      });
    });

    group('Legacy Data Migration Integration', () {
      test('should handle legacy workoutWeights mapped to workoutUpperBody with fallback stat calculation', () {
        // This test verifies that legacy workoutWeights activity type is properly
        // mapped to workoutUpperBody with the correct stat calculations
        final json = {
          'id': 'legacy_migration_test',
          'activityType': 'workoutWeights',
          'durationMinutes': 60,
          'timestamp': '2024-01-15T10:30:00.000Z',
          'statGains': {}, // Empty, should trigger fallback calculation
          'expGained': 60.0,
          'notes': 'Legacy workout with migration',
        };

        final activity = ActivityLog.fromJson(json);
        
        // Should map to workoutUpperBody
        expect(activity.activityTypeEnum, equals(ActivityType.workoutUpperBody));
        
        // Should calculate fallback stat gains for workoutUpperBody
        final statGainsMap = activity.statGainsMap;
        expect(statGainsMap[StatType.strength], equals(0.06)); // 1 hour at 0.06/hr
        expect(statGainsMap[StatType.endurance], equals(0.03)); // 1 hour at 0.03/hr
      });
    });
  });
}