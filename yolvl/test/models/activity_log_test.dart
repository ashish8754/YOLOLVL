import 'package:flutter_test/flutter_test.dart';
import 'package:yolvl/models/activity_log.dart';
import 'package:yolvl/models/enums.dart';

void main() {
  group('ActivityLog Model Tests', () {
    late ActivityLog testActivity;
    late DateTime testTimestamp;

    setUp(() {
      testTimestamp = DateTime(2024, 1, 15, 10, 30);
      testActivity = ActivityLog(
        id: 'test_activity_123',
        activityType: ActivityType.workoutUpperBody.name,
        durationMinutes: 60,
        timestamp: testTimestamp,
        statGains: {
          StatType.strength.name: 0.06,
          StatType.endurance.name: 0.04,
        },
        expGained: 60.0,
        notes: 'Test workout session',
      );
    });

    group('Basic Properties', () {
      test('should create activity log with all properties', () {
        expect(testActivity.id, equals('test_activity_123'));
        expect(testActivity.activityType, equals(ActivityType.workoutUpperBody.name));
        expect(testActivity.durationMinutes, equals(60));
        expect(testActivity.timestamp, equals(testTimestamp));
        expect(testActivity.expGained, equals(60.0));
        expect(testActivity.notes, equals('Test workout session'));
      });

      test('should get activity type enum correctly', () {
        expect(testActivity.activityTypeEnum, equals(ActivityType.workoutUpperBody));
      });

      test('should handle unknown activity type gracefully', () {
        final unknownActivity = ActivityLog(
          id: 'test',
          activityType: 'unknown_activity',
          durationMinutes: 30,
          timestamp: DateTime.now(),
          statGains: {},
          expGained: 30.0,
        );
        
        expect(unknownActivity.activityTypeEnum, equals(ActivityType.workoutUpperBody));
      });
    });

    group('Stat Gains Functionality', () {
      test('should return stat gains map with StatType keys', () {
        final statGainsMap = testActivity.statGainsMap;
        
        expect(statGainsMap[StatType.strength], equals(0.06));
        expect(statGainsMap[StatType.endurance], equals(0.04));
        expect(statGainsMap[StatType.agility], isNull);
      });

      test('should check if activity has stored stat gains', () {
        expect(testActivity.hasStoredStatGains, isTrue);
        
        final emptyGainsActivity = ActivityLog(
          id: 'test',
          activityType: ActivityType.meditation.name,
          durationMinutes: 30,
          timestamp: DateTime.now(),
          statGains: {},
          expGained: 30.0,
        );
        
        expect(emptyGainsActivity.hasStoredStatGains, isFalse);
      });

      test('should check if activity needs stat gain migration', () {
        expect(testActivity.needsStatGainMigration, isFalse);
        
        final emptyGainsActivity = ActivityLog(
          id: 'test',
          activityType: ActivityType.meditation.name,
          durationMinutes: 30,
          timestamp: DateTime.now(),
          statGains: {},
          expGained: 30.0,
        );
        
        expect(emptyGainsActivity.needsStatGainMigration, isTrue);
      });
    });

    group('Data Migration Logic', () {
      test('should calculate fallback stat gains for workout upper body', () {
        final activityWithoutGains = ActivityLog(
          id: 'test',
          activityType: ActivityType.workoutUpperBody.name,
          durationMinutes: 60,
          timestamp: DateTime.now(),
          statGains: {},
          expGained: 60.0,
        );
        
        final statGainsMap = activityWithoutGains.statGainsMap;
        
        expect(statGainsMap[StatType.strength], equals(0.06));
        expect(statGainsMap[StatType.endurance], equals(0.03));
      });

      test('should calculate fallback stat gains for cardio workout', () {
        final cardioActivity = ActivityLog(
          id: 'test',
          activityType: ActivityType.workoutCardio.name,
          durationMinutes: 90,
          timestamp: DateTime.now(),
          statGains: {},
          expGained: 90.0,
        );
        
        final statGainsMap = cardioActivity.statGainsMap;
        
        expect(statGainsMap[StatType.agility], closeTo(0.09, 0.0001)); // 0.06 * 1.5 hours
        expect(statGainsMap[StatType.endurance], closeTo(0.06, 0.0001)); // 0.04 * 1.5 hours
      });

      test('should calculate fallback stat gains for yoga', () {
        final yogaActivity = ActivityLog(
          id: 'test',
          activityType: ActivityType.workoutYoga.name,
          durationMinutes: 45,
          timestamp: DateTime.now(),
          statGains: {},
          expGained: 45.0,
        );
        
        final statGainsMap = yogaActivity.statGainsMap;
        
        expect(statGainsMap[StatType.agility], closeTo(0.0375, 0.0001)); // 0.05 * 0.75 hours
        expect(statGainsMap[StatType.focus], closeTo(0.0225, 0.0001)); // 0.03 * 0.75 hours
      });

      test('should calculate fallback stat gains for serious study', () {
        final studyActivity = ActivityLog(
          id: 'test',
          activityType: ActivityType.studySerious.name,
          durationMinutes: 120,
          timestamp: DateTime.now(),
          statGains: {},
          expGained: 120.0,
        );
        
        final statGainsMap = studyActivity.statGainsMap;
        
        expect(statGainsMap[StatType.intelligence], closeTo(0.12, 0.0001)); // 0.06 * 2 hours
        expect(statGainsMap[StatType.focus], closeTo(0.08, 0.0001)); // 0.04 * 2 hours
      });

      test('should calculate fallback stat gains for casual study', () {
        final casualStudyActivity = ActivityLog(
          id: 'test',
          activityType: ActivityType.studyCasual.name,
          durationMinutes: 60,
          timestamp: DateTime.now(),
          statGains: {},
          expGained: 60.0,
        );
        
        final statGainsMap = casualStudyActivity.statGainsMap;
        
        expect(statGainsMap[StatType.intelligence], equals(0.04));
        expect(statGainsMap[StatType.charisma], equals(0.03));
      });

      test('should calculate fallback stat gains for meditation', () {
        final meditationActivity = ActivityLog(
          id: 'test',
          activityType: ActivityType.meditation.name,
          durationMinutes: 30,
          timestamp: DateTime.now(),
          statGains: {},
          expGained: 30.0,
        );
        
        final statGainsMap = meditationActivity.statGainsMap;
        
        expect(statGainsMap[StatType.focus], closeTo(0.025, 0.0001)); // 0.05 * 0.5 hours
      });

      test('should calculate fallback stat gains for socializing', () {
        final socializingActivity = ActivityLog(
          id: 'test',
          activityType: ActivityType.socializing.name,
          durationMinutes: 90,
          timestamp: DateTime.now(),
          statGains: {},
          expGained: 90.0,
        );
        
        final statGainsMap = socializingActivity.statGainsMap;
        
        expect(statGainsMap[StatType.charisma], closeTo(0.075, 0.0001)); // 0.05 * 1.5 hours
        expect(statGainsMap[StatType.focus], closeTo(0.03, 0.0001)); // 0.02 * 1.5 hours
      });

      test('should calculate fallback stat gains for sleep tracking', () {
        final sleepActivity = ActivityLog(
          id: 'test',
          activityType: ActivityType.sleepTracking.name,
          durationMinutes: 480, // 8 hours
          timestamp: DateTime.now(),
          statGains: {},
          expGained: 480.0,
        );
        
        final statGainsMap = sleepActivity.statGainsMap;
        
        expect(statGainsMap[StatType.endurance], closeTo(0.16, 0.0001)); // 0.02 * 8 hours
      });

      test('should calculate fallback stat gains for healthy diet', () {
        final dietActivity = ActivityLog(
          id: 'test',
          activityType: ActivityType.dietHealthy.name,
          durationMinutes: 60,
          timestamp: DateTime.now(),
          statGains: {},
          expGained: 60.0,
        );
        
        final statGainsMap = dietActivity.statGainsMap;
        
        expect(statGainsMap[StatType.endurance], equals(0.03));
      });

      test('should calculate fallback stat gains for quit bad habit', () {
        final quitHabitActivity = ActivityLog(
          id: 'test',
          activityType: ActivityType.quitBadHabit.name,
          durationMinutes: 1, // Duration doesn't matter for this activity
          timestamp: DateTime.now(),
          statGains: {},
          expGained: 60.0,
        );
        
        final statGainsMap = quitHabitActivity.statGainsMap;
        
        expect(statGainsMap[StatType.focus], equals(0.03)); // Fixed amount
      });

      test('should migrate stat gains data', () {
        final activityWithoutGains = ActivityLog(
          id: 'test',
          activityType: ActivityType.workoutUpperBody.name,
          durationMinutes: 60,
          timestamp: DateTime.now(),
          statGains: {},
          expGained: 60.0,
        );
        
        expect(activityWithoutGains.hasStoredStatGains, isFalse);
        
        activityWithoutGains.migrateStatGains();
        
        expect(activityWithoutGains.hasStoredStatGains, isTrue);
        expect(activityWithoutGains.statGains[StatType.strength.name], equals(0.06));
        expect(activityWithoutGains.statGains[StatType.endurance.name], equals(0.03));
      });

      test('should not migrate if already has stat gains', () {
        final originalStatGains = Map<String, double>.from(testActivity.statGains);
        
        testActivity.migrateStatGains();
        
        expect(testActivity.statGains, equals(originalStatGains));
      });
    });

    group('Factory Methods', () {
      test('should create activity log using factory method', () {
        final statGains = {
          StatType.strength: 0.08,
          StatType.endurance: 0.05,
        };
        
        final activity = ActivityLog.create(
          id: 'factory_test',
          activityType: ActivityType.workoutUpperBody,
          durationMinutes: 45,
          statGains: statGains,
          expGained: 45.0,
          notes: 'Factory test',
          timestamp: testTimestamp,
        );
        
        expect(activity.id, equals('factory_test'));
        expect(activity.activityTypeEnum, equals(ActivityType.workoutUpperBody));
        expect(activity.durationMinutes, equals(45));
        expect(activity.statGainsMap[StatType.strength], equals(0.08));
        expect(activity.statGainsMap[StatType.endurance], equals(0.05));
        expect(activity.expGained, equals(45.0));
        expect(activity.notes, equals('Factory test'));
        expect(activity.timestamp, equals(testTimestamp));
      });

      test('should create activity log with default timestamp', () {
        final beforeCreation = DateTime.now();
        
        final activity = ActivityLog.create(
          id: 'timestamp_test',
          activityType: ActivityType.meditation,
          durationMinutes: 30,
          statGains: {StatType.focus: 0.025},
          expGained: 30.0,
        );
        
        final afterCreation = DateTime.now();
        
        expect(activity.timestamp.isAfter(beforeCreation) || 
               activity.timestamp.isAtSameMomentAs(beforeCreation), isTrue);
        expect(activity.timestamp.isBefore(afterCreation) || 
               activity.timestamp.isAtSameMomentAs(afterCreation), isTrue);
      });
    });

    group('Utility Methods', () {
      test('should format duration correctly', () {
        final shortActivity = ActivityLog(
          id: 'test',
          activityType: ActivityType.meditation.name,
          durationMinutes: 25,
          timestamp: DateTime.now(),
          statGains: {},
          expGained: 25.0,
        );
        
        expect(shortActivity.formattedDuration, equals('25m'));
        
        final hourActivity = ActivityLog(
          id: 'test',
          activityType: ActivityType.studySerious.name,
          durationMinutes: 60,
          timestamp: DateTime.now(),
          statGains: {},
          expGained: 60.0,
        );
        
        expect(hourActivity.formattedDuration, equals('1h'));
        
        final mixedActivity = ActivityLog(
          id: 'test',
          activityType: ActivityType.workoutUpperBody.name,
          durationMinutes: 90,
          timestamp: DateTime.now(),
          statGains: {},
          expGained: 90.0,
        );
        
        expect(mixedActivity.formattedDuration, equals('1h 30m'));
      });

      test('should check if activity is from today', () {
        final todayActivity = ActivityLog(
          id: 'test',
          activityType: ActivityType.meditation.name,
          durationMinutes: 30,
          timestamp: DateTime.now(),
          statGains: {},
          expGained: 30.0,
        );
        
        expect(todayActivity.isToday, isTrue);
        
        final yesterdayActivity = ActivityLog(
          id: 'test',
          activityType: ActivityType.meditation.name,
          durationMinutes: 30,
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          statGains: {},
          expGained: 30.0,
        );
        
        expect(yesterdayActivity.isToday, isFalse);
      });

      test('should check if activity is from this week', () {
        final now = DateTime.now();
        final daysFromStartOfWeek = now.weekday - 1; // Monday = 0, Sunday = 6
        
        // Create an activity from early this week (should be true)
        final thisWeekActivity = ActivityLog(
          id: 'test',
          activityType: ActivityType.meditation.name,
          durationMinutes: 30,
          timestamp: now.subtract(Duration(days: daysFromStartOfWeek, hours: -1)), // Start of this week + 1 hour
          statGains: {},
          expGained: 30.0,
        );
        
        expect(thisWeekActivity.isThisWeek, isTrue);
        
        // Create an activity from last week (should be false)
        final lastWeekActivity = ActivityLog(
          id: 'test',
          activityType: ActivityType.meditation.name,
          durationMinutes: 30,
          timestamp: now.subtract(Duration(days: daysFromStartOfWeek + 7)), // One week before start of this week
          statGains: {},
          expGained: 30.0,
        );
        
        expect(lastWeekActivity.isThisWeek, isFalse);
      });
    });

    group('Copy and Serialization', () {
      test('should copy activity with updated values', () {
        final copiedActivity = testActivity.copyWith(
          durationMinutes: 90,
          notes: 'Updated notes',
        );
        
        expect(copiedActivity.id, equals(testActivity.id));
        expect(copiedActivity.activityType, equals(testActivity.activityType));
        expect(copiedActivity.durationMinutes, equals(90));
        expect(copiedActivity.notes, equals('Updated notes'));
        expect(copiedActivity.timestamp, equals(testActivity.timestamp));
        expect(copiedActivity.expGained, equals(testActivity.expGained));
      });

      test('should convert to JSON correctly', () {
        final json = testActivity.toJson();
        
        expect(json['id'], equals('test_activity_123'));
        expect(json['activityType'], equals(ActivityType.workoutUpperBody.name));
        expect(json['durationMinutes'], equals(60));
        expect(json['timestamp'], equals(testTimestamp.toIso8601String()));
        expect(json['expGained'], equals(60.0));
        expect(json['notes'], equals('Test workout session'));
        expect(json['statGains'], isA<Map<String, double>>());
      });

      test('should create from JSON correctly', () {
        final json = {
          'id': 'json_test',
          'activityType': ActivityType.meditation.name,
          'durationMinutes': 30,
          'timestamp': testTimestamp.toIso8601String(),
          'expGained': 30.0,
          'notes': 'JSON test',
          'statGains': {StatType.focus.name: 0.025},
        };
        
        final activity = ActivityLog.fromJson(json);
        
        expect(activity.id, equals('json_test'));
        expect(activity.activityType, equals(ActivityType.meditation.name));
        expect(activity.durationMinutes, equals(30));
        expect(activity.timestamp, equals(testTimestamp));
        expect(activity.expGained, equals(30.0));
        expect(activity.notes, equals('JSON test'));
        expect(activity.statGains[StatType.focus.name], equals(0.025));
      });
    });

    group('Edge Cases', () {
      test('should handle null notes', () {
        final activityWithoutNotes = ActivityLog(
          id: 'test',
          activityType: ActivityType.meditation.name,
          durationMinutes: 30,
          timestamp: DateTime.now(),
          statGains: {},
          expGained: 30.0,
        );
        
        expect(activityWithoutNotes.notes, isNull);
      });

      test('should handle empty stat gains map', () {
        final activityWithoutGains = ActivityLog(
          id: 'test',
          activityType: ActivityType.meditation.name,
          durationMinutes: 30,
          timestamp: DateTime.now(),
          statGains: {},
          expGained: 30.0,
        );
        
        expect(activityWithoutGains.statGains, isEmpty);
        expect(activityWithoutGains.hasStoredStatGains, isFalse);
        expect(activityWithoutGains.needsStatGainMigration, isTrue);
      });

      test('should handle zero duration for quit bad habit', () {
        final quitHabitActivity = ActivityLog(
          id: 'test',
          activityType: ActivityType.quitBadHabit.name,
          durationMinutes: 0,
          timestamp: DateTime.now(),
          statGains: {},
          expGained: 60.0,
        );
        
        final statGainsMap = quitHabitActivity.statGainsMap;
        expect(statGainsMap[StatType.focus], equals(0.03)); // Fixed amount regardless of duration
      });
    });
  });
}