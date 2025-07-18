import 'package:flutter_test/flutter_test.dart';
import 'package:yolvl/services/stats_service.dart';
import 'package:yolvl/models/enums.dart';

void main() {
  group('StatsService', () {
    group('calculateStatGains', () {
      test('should calculate correct gains for Workout - Weights', () {
        final gains = StatsService.calculateStatGains(ActivityType.workoutWeights, 60);
        
        expect(gains[StatType.strength], equals(0.06));
        expect(gains[StatType.endurance], equals(0.04));
        expect(gains.length, equals(2));
      });

      test('should calculate correct gains for Workout - Cardio', () {
        final gains = StatsService.calculateStatGains(ActivityType.workoutCardio, 60);
        
        expect(gains[StatType.agility], equals(0.06));
        expect(gains[StatType.endurance], equals(0.04));
        expect(gains.length, equals(2));
      });

      test('should calculate correct gains for Workout - Yoga', () {
        final gains = StatsService.calculateStatGains(ActivityType.workoutYoga, 60);
        
        expect(gains[StatType.agility], equals(0.05));
        expect(gains[StatType.focus], equals(0.03));
        expect(gains.length, equals(2));
      });

      test('should calculate correct gains for Study - Serious', () {
        final gains = StatsService.calculateStatGains(ActivityType.studySerious, 60);
        
        expect(gains[StatType.intelligence], equals(0.06));
        expect(gains[StatType.focus], equals(0.04));
        expect(gains.length, equals(2));
      });

      test('should calculate correct gains for Study - Casual', () {
        final gains = StatsService.calculateStatGains(ActivityType.studyCasual, 60);
        
        expect(gains[StatType.intelligence], equals(0.04));
        expect(gains[StatType.charisma], equals(0.03));
        expect(gains.length, equals(2));
      });

      test('should calculate correct gains for Meditation', () {
        final gains = StatsService.calculateStatGains(ActivityType.meditation, 60);
        
        expect(gains[StatType.focus], equals(0.05));
        expect(gains.length, equals(1));
      });

      test('should calculate correct gains for Socializing', () {
        final gains = StatsService.calculateStatGains(ActivityType.socializing, 60);
        
        expect(gains[StatType.charisma], equals(0.05));
        expect(gains[StatType.focus], equals(0.02));
        expect(gains.length, equals(2));
      });

      test('should calculate correct gains for Sleep Tracking', () {
        final gains = StatsService.calculateStatGains(ActivityType.sleepTracking, 60);
        
        expect(gains[StatType.endurance], equals(0.02));
        expect(gains.length, equals(1));
      });

      test('should calculate correct gains for Diet/Healthy Eating', () {
        final gains = StatsService.calculateStatGains(ActivityType.dietHealthy, 60);
        
        expect(gains[StatType.endurance], equals(0.03));
        expect(gains.length, equals(1));
      });

      test('should calculate correct gains for Quit Bad Habit (fixed amount)', () {
        // Test different durations - should always be 0.03
        final gains30 = StatsService.calculateStatGains(ActivityType.quitBadHabit, 30);
        final gains60 = StatsService.calculateStatGains(ActivityType.quitBadHabit, 60);
        final gains120 = StatsService.calculateStatGains(ActivityType.quitBadHabit, 120);
        
        expect(gains30[StatType.focus], equals(0.03));
        expect(gains60[StatType.focus], equals(0.03));
        expect(gains120[StatType.focus], equals(0.03));
        expect(gains30.length, equals(1));
      });

      test('should scale gains proportionally with duration', () {
        // Test 30 minutes (0.5 hours)
        final gains30 = StatsService.calculateStatGains(ActivityType.workoutWeights, 30);
        expect(gains30[StatType.strength], equals(0.03)); // 0.06 * 0.5
        expect(gains30[StatType.endurance], equals(0.02)); // 0.04 * 0.5

        // Test 120 minutes (2 hours)
        final gains120 = StatsService.calculateStatGains(ActivityType.workoutWeights, 120);
        expect(gains120[StatType.strength], equals(0.12)); // 0.06 * 2
        expect(gains120[StatType.endurance], equals(0.08)); // 0.04 * 2
      });

      test('should handle zero duration', () {
        final gains = StatsService.calculateStatGains(ActivityType.workoutWeights, 0);
        
        expect(gains[StatType.strength], equals(0.0));
        expect(gains[StatType.endurance], equals(0.0));
      });

      test('should handle zero duration for quit bad habit', () {
        final gains = StatsService.calculateStatGains(ActivityType.quitBadHabit, 0);
        
        expect(gains[StatType.focus], equals(0.03)); // Still fixed amount
      });

      test('should throw error for negative duration', () {
        expect(
          () => StatsService.calculateStatGains(ActivityType.workoutWeights, -1),
          throwsArgumentError,
        );
      });
    });

    group('applyStatGains', () {
      test('should apply gains to current stats', () {
        final currentStats = {
          StatType.strength: 2.0,
          StatType.agility: 1.5,
          StatType.endurance: 1.8,
          StatType.intelligence: 2.2,
          StatType.focus: 1.9,
          StatType.charisma: 1.3,
        };

        final gains = {
          StatType.strength: 0.06,
          StatType.endurance: 0.04,
        };

        final result = StatsService.applyStatGains(currentStats, gains);

        expect(result[StatType.strength], equals(2.06));
        expect(result[StatType.endurance], equals(1.84));
        expect(result[StatType.agility], equals(1.5)); // Unchanged
        expect(result[StatType.intelligence], equals(2.2)); // Unchanged
        expect(result[StatType.focus], equals(1.9)); // Unchanged
        expect(result[StatType.charisma], equals(1.3)); // Unchanged
      });

      test('should handle missing stats in current stats map', () {
        final currentStats = {
          StatType.strength: 2.0,
          // Missing other stats
        };

        final gains = {
          StatType.agility: 0.05,
        };

        final result = StatsService.applyStatGains(currentStats, gains);

        expect(result[StatType.strength], equals(2.0));
        expect(result[StatType.agility], equals(1.05)); // 1.0 default + 0.05 gain
        expect(result[StatType.endurance], equals(1.0)); // Default value
      });

      test('should handle empty gains', () {
        final currentStats = {
          StatType.strength: 2.0,
          StatType.agility: 1.5,
        };

        final gains = <StatType, double>{};

        final result = StatsService.applyStatGains(currentStats, gains);

        expect(result[StatType.strength], equals(2.0));
        expect(result[StatType.agility], equals(1.5));
      });
    });

    group('getAffectedStats', () {
      test('should return correct affected stats for workout weights', () {
        final affected = StatsService.getAffectedStats(ActivityType.workoutWeights);
        
        expect(affected, containsAll([StatType.strength, StatType.endurance]));
        expect(affected.length, equals(2));
      });

      test('should return correct affected stats for meditation', () {
        final affected = StatsService.getAffectedStats(ActivityType.meditation);
        
        expect(affected, contains(StatType.focus));
        expect(affected.length, equals(1));
      });

      test('should return correct affected stats for socializing', () {
        final affected = StatsService.getAffectedStats(ActivityType.socializing);
        
        expect(affected, containsAll([StatType.charisma, StatType.focus]));
        expect(affected.length, equals(2));
      });
    });

    group('getPrimaryStat', () {
      test('should return primary stat for workout weights', () {
        final primary = StatsService.getPrimaryStat(ActivityType.workoutWeights);
        expect(primary, equals(StatType.strength)); // 0.06 > 0.04
      });

      test('should return primary stat for study serious', () {
        final primary = StatsService.getPrimaryStat(ActivityType.studySerious);
        expect(primary, equals(StatType.intelligence)); // 0.06 > 0.04
      });

      test('should return primary stat for meditation', () {
        final primary = StatsService.getPrimaryStat(ActivityType.meditation);
        expect(primary, equals(StatType.focus)); // Only stat affected
      });

      test('should return primary stat for socializing', () {
        final primary = StatsService.getPrimaryStat(ActivityType.socializing);
        expect(primary, equals(StatType.charisma)); // 0.05 > 0.02
      });
    });

    group('calculateTotalStatGains', () {
      test('should calculate total gains from multiple activities', () {
        final activities = [
          ActivityLogEntry(
            activityType: ActivityType.workoutWeights,
            durationMinutes: 60,
            timestamp: DateTime.now(),
          ),
          ActivityLogEntry(
            activityType: ActivityType.studySerious,
            durationMinutes: 30,
            timestamp: DateTime.now(),
          ),
        ];

        final totalGains = StatsService.calculateTotalStatGains(activities);

        expect(totalGains[StatType.strength], equals(0.06)); // From weights
        expect(totalGains[StatType.endurance], equals(0.04)); // From weights
        expect(totalGains[StatType.intelligence], equals(0.03)); // From study (30 min)
        expect(totalGains[StatType.focus], equals(0.02)); // From study (30 min)
      });

      test('should handle overlapping stat gains', () {
        final activities = [
          ActivityLogEntry(
            activityType: ActivityType.workoutYoga,
            durationMinutes: 60,
            timestamp: DateTime.now(),
          ),
          ActivityLogEntry(
            activityType: ActivityType.meditation,
            durationMinutes: 60,
            timestamp: DateTime.now(),
          ),
        ];

        final totalGains = StatsService.calculateTotalStatGains(activities);

        expect(totalGains[StatType.agility], equals(0.05)); // From yoga only
        expect(totalGains[StatType.focus], equals(0.08)); // 0.03 (yoga) + 0.05 (meditation)
      });

      test('should handle empty activity list', () {
        final totalGains = StatsService.calculateTotalStatGains([]);
        expect(totalGains.isEmpty, isTrue);
      });
    });

    group('validateStats', () {
      test('should enforce minimum stat values', () {
        final stats = {
          StatType.strength: 2.0,
          StatType.agility: 0.5, // Below minimum
          StatType.endurance: -1.0, // Below minimum
        };

        final validated = StatsService.validateStats(stats);

        expect(validated[StatType.strength], equals(2.0)); // Unchanged
        expect(validated[StatType.agility], equals(1.0)); // Raised to minimum
        expect(validated[StatType.endurance], equals(1.0)); // Raised to minimum
      });

      test('should use custom minimum value', () {
        final stats = {
          StatType.strength: 1.5,
          StatType.agility: 0.5,
        };

        final validated = StatsService.validateStats(stats, minValue: 2.0);

        expect(validated[StatType.strength], equals(2.0)); // Raised to custom minimum
        expect(validated[StatType.agility], equals(2.0)); // Raised to custom minimum
      });
    });

    group('getStatGainRates', () {
      test('should return hourly rates for all activities', () {
        final rates = StatsService.getStatGainRates(ActivityType.workoutWeights);
        
        expect(rates[StatType.strength], equals(0.06));
        expect(rates[StatType.endurance], equals(0.04));
      });
    });

    group('calculateExpectedGains', () {
      test('should create preview with correct information', () {
        final preview = StatsService.calculateExpectedGains(ActivityType.workoutWeights, 60);

        expect(preview.activityType, equals(ActivityType.workoutWeights));
        expect(preview.durationMinutes, equals(60));
        expect(preview.statGains[StatType.strength], equals(0.06));
        expect(preview.statGains[StatType.endurance], equals(0.04));
        expect(preview.affectedStats, containsAll([StatType.strength, StatType.endurance]));
        expect(preview.primaryStat, equals(StatType.strength));
      });

      test('should handle quit bad habit correctly in preview', () {
        final preview = StatsService.calculateExpectedGains(ActivityType.quitBadHabit, 30);

        expect(preview.statGains[StatType.focus], equals(0.03));
        expect(preview.affectedStats, contains(StatType.focus));
        expect(preview.primaryStat, equals(StatType.focus));
      });
    });

    group('StatGainPreview', () {
      test('should format gain text correctly', () {
        final preview = StatsService.calculateExpectedGains(ActivityType.workoutWeights, 60);

        expect(preview.getGainText(StatType.strength), equals('+0.06'));
        expect(preview.getGainText(StatType.endurance), equals('+0.04'));
        expect(preview.getGainText(StatType.agility), equals('')); // Not affected
      });

      test('should check if activity affects stat', () {
        final preview = StatsService.calculateExpectedGains(ActivityType.meditation, 60);

        expect(preview.affectsStat(StatType.focus), isTrue);
        expect(preview.affectsStat(StatType.strength), isFalse);
      });
    });
  });
}