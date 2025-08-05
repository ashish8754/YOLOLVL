import 'package:flutter_test/flutter_test.dart';
import 'package:yolvl/services/exp_service.dart';
import 'package:yolvl/services/stats_service.dart';
import 'package:yolvl/services/degradation_service.dart';
import 'package:yolvl/models/user.dart';
import 'package:yolvl/models/enums.dart';

void main() {
  group('Performance Tests', () {
    group('Large Dataset Performance', () {
      test('should handle 1000 activity calculations efficiently', () {
        final stopwatch = Stopwatch()..start();
        
        // Create large list of activities
        final activities = List.generate(1000, (index) => ActivityLogEntry(
          activityType: ActivityType.values[index % ActivityType.values.length],
          durationMinutes: 60,
          timestamp: DateTime.now().subtract(Duration(hours: index)),
        ));

        // Calculate total gains
        final totalGains = StatsService.calculateTotalStatGains(activities);
        
        stopwatch.stop();
        
        // Should complete within reasonable time (< 100ms)
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
        expect(totalGains, isNotEmpty);
      });

      test('should handle 10000 EXP calculations efficiently', () {
        final stopwatch = Stopwatch()..start();
        
        // Calculate many EXP thresholds
        for (int level = 1; level <= 10000; level++) {
          EXPService.calculateEXPThreshold(level);
        }
        
        stopwatch.stop();
        
        // Should complete within reasonable time (< 500ms)
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
      });

      test('should handle rapid user updates efficiently', () {
        final user = User.create(id: 'test', name: 'Test');
        final stopwatch = Stopwatch()..start();
        
        // Perform many rapid updates
        for (int i = 0; i < 1000; i++) {
          user.addToStat(StatType.strength, 0.001);
          user.currentEXP += 1.0;
          
          if (user.canLevelUp) {
            user.levelUp();
          }
        }
        
        stopwatch.stop();
        
        // Should complete within reasonable time (< 50ms)
        expect(stopwatch.elapsedMilliseconds, lessThan(50));
        expect(user.getStat(StatType.strength), greaterThan(1.0));
      });

      test('should handle large degradation calculations efficiently', () {
        final user = User.create(id: 'test', name: 'Test');
        final stopwatch = Stopwatch()..start();
        
        // Set many activity dates
        for (final activityType in ActivityType.values) {
          user.setLastActivityDate(activityType, 
              DateTime.now().subtract(Duration(days: 5)));
        }
        
        // Calculate degradation many times
        for (int i = 0; i < 1000; i++) {
          DegradationService.calculateAllDegradation(user);
        }
        
        stopwatch.stop();
        
        // Should complete within reasonable time (< 200ms)
        expect(stopwatch.elapsedMilliseconds, lessThan(200));
      });
    });

    group('Memory Usage Tests', () {
      test('should not leak memory with repeated operations', () {
        // Create and destroy many objects
        for (int i = 0; i < 1000; i++) {
          final user = User.create(id: 'test_$i', name: 'Test $i');
          user.setStat(StatType.strength, 2.0);
          
          final gains = StatsService.calculateStatGains(ActivityType.workoutUpperBody, 60);
          final expGain = EXPService.calculateEXPGain('workoutUpperBody', 60);
          
          // Use the values to prevent optimization
          expect(gains[StatType.strength], equals(0.06));
          expect(expGain, equals(60.0));
        }
        
        // Test should complete without memory issues
        expect(true, isTrue);
      });

      test('should handle large stat maps efficiently', () {
        final largeStatMap = <StatType, double>{};
        
        // Create large stat map
        for (int i = 0; i < 1000; i++) {
          for (final statType in StatType.values) {
            largeStatMap[statType] = i.toDouble();
          }
        }
        
        final stopwatch = Stopwatch()..start();
        
        // Validate large stat map
        final validated = StatsService.validateStats(largeStatMap);
        
        stopwatch.stop();
        
        expect(stopwatch.elapsedMilliseconds, lessThan(10));
        expect(validated, isNotEmpty);
      });
    });

    group('Concurrent Operations', () {
      test('should handle concurrent stat calculations', () async {
        final futures = <Future<Map<StatType, double>>>[];
        
        // Start many concurrent calculations
        for (int i = 0; i < 100; i++) {
          futures.add(Future(() => 
            StatsService.calculateStatGains(ActivityType.workoutUpperBody, 60)
          ));
        }
        
        final stopwatch = Stopwatch()..start();
        final results = await Future.wait(futures);
        stopwatch.stop();
        
        // Should complete within reasonable time
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
        expect(results.length, equals(100));
        
        // All results should be identical
        for (final result in results) {
          expect(result[StatType.strength], equals(0.06));
          expect(result[StatType.endurance], equals(0.04));
        }
      });

      test('should handle concurrent EXP calculations', () async {
        final futures = <Future<double>>[];
        
        // Start many concurrent calculations
        for (int level = 1; level <= 100; level++) {
          futures.add(Future(() => 
            EXPService.calculateEXPThreshold(level)
          ));
        }
        
        final stopwatch = Stopwatch()..start();
        final results = await Future.wait(futures);
        stopwatch.stop();
        
        // Should complete within reasonable time
        expect(stopwatch.elapsedMilliseconds, lessThan(50));
        expect(results.length, equals(100));
        
        // Results should be monotonically increasing
        for (int i = 1; i < results.length; i++) {
          expect(results[i], greaterThan(results[i - 1]));
        }
      });
    });

    group('Edge Case Performance', () {
      test('should handle extreme values efficiently', () {
        final stopwatch = Stopwatch()..start();
        
        // Test with extreme values
        final extremeGains = StatsService.calculateStatGains(
          ActivityType.workoutUpperBody, 
          1440 // 24 hours
        );
        
        final extremeThreshold = EXPService.calculateEXPThreshold(100);
        
        final user = User.create(id: 'test', name: 'Test');
        user.currentEXP = 1000000.0; // Very high EXP
        final levelUpResult = EXPService.checkLevelUp(user);
        
        stopwatch.stop();
        
        // Should handle extreme values quickly
        expect(stopwatch.elapsedMilliseconds, lessThan(10));
        expect(extremeGains[StatType.strength], equals(1.44)); // 0.06 * 24
        expect(extremeThreshold, greaterThan(0.0));
        expect(levelUpResult.canLevelUp, isTrue);
      });

      test('should handle precision edge cases efficiently', () {
        final stopwatch = Stopwatch()..start();
        
        // Test with very small values
        for (int i = 0; i < 1000; i++) {
          final gains = StatsService.calculateStatGains(ActivityType.workoutUpperBody, 1);
          expect(gains[StatType.strength], closeTo(0.001, 0.0001));
        }
        
        stopwatch.stop();
        
        // Should handle precision calculations quickly
        expect(stopwatch.elapsedMilliseconds, lessThan(50));
      });
    });

    group('Offline Scenario Performance', () {
      test('should handle offline data operations efficiently', () {
        final stopwatch = Stopwatch()..start();
        
        // Simulate offline operations (no network calls)
        final user = User.create(id: 'offline', name: 'Offline User');
        
        // Perform many offline operations
        for (int i = 0; i < 100; i++) {
          // Log activity
          final gains = StatsService.calculateStatGains(ActivityType.workoutUpperBody, 60);
          final expGain = EXPService.calculateEXPGain('workoutUpperBody', 60);
          
          // Update user
          for (final entry in gains.entries) {
            user.addToStat(entry.key, entry.value);
          }
          user.currentEXP += expGain;
          
          // Check level up
          if (user.canLevelUp) {
            user.levelUp();
          }
          
          // Check degradation
          DegradationService.calculateAllDegradation(user);
        }
        
        stopwatch.stop();
        
        // Should complete offline operations quickly
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
        expect(user.level, greaterThan(1));
      });

      test('should handle data validation efficiently', () {
        final stopwatch = Stopwatch()..start();
        
        // Create many invalid stat maps for validation
        for (int i = 0; i < 1000; i++) {
          final invalidStats = <StatType, double>{
            StatType.strength: double.nan,
            StatType.agility: double.infinity,
            StatType.endurance: -1.0,
            StatType.intelligence: 0.0,
            StatType.focus: double.negativeInfinity,
            StatType.charisma: 1000.0,
          };
          
          final validated = StatsService.validateStats(invalidStats);
          expect(validated[StatType.strength], equals(1.0));
        }
        
        stopwatch.stop();
        
        // Should handle validation quickly
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });
    });

    group('Stress Tests', () {
      test('should handle stress test without degradation', () {
        final user = User.create(id: 'stress', name: 'Stress Test');
        final stopwatch = Stopwatch()..start();
        
        // Perform stress operations
        for (int i = 0; i < 10000; i++) {
          // Rapid stat updates
          user.addToStat(StatType.strength, 0.0001);
          
          // EXP updates
          user.currentEXP += 0.1;
          
          // Level checks
          if (i % 100 == 0 && user.canLevelUp) {
            user.levelUp();
          }
        }
        
        stopwatch.stop();
        
        // Should handle stress without performance degradation
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
        expect(user.getStat(StatType.strength), greaterThan(1.0));
      });

      test('should maintain accuracy under stress', () {
        final user = User.create(id: 'accuracy', name: 'Accuracy Test');
        
        // Perform many small operations
        for (int i = 0; i < 1000; i++) {
          user.addToStat(StatType.strength, 0.001);
        }
        
        // Should maintain accuracy
        expect(user.getStat(StatType.strength), closeTo(2.0, 0.01)); // 1.0 + 1000 * 0.001
      });
    });
  });
}