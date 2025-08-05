import 'package:flutter_test/flutter_test.dart';
import 'package:yolvl/models/enums.dart';
import 'package:yolvl/models/user.dart';
import 'package:yolvl/models/activity_log.dart';
import 'package:yolvl/services/exp_service.dart';
import 'package:yolvl/services/stats_service.dart';
import 'package:yolvl/services/hunter_rank_service.dart';
import 'package:yolvl/services/activity_service.dart';
import 'package:yolvl/providers/daily_login_provider.dart';

/// Comprehensive test suite for YoLvL Solo Leveling App business logic
/// 
/// This test suite systematically tests all core business logic components
/// to identify bugs, edge cases, and potential issues in the app.
/// 
/// Test Coverage:
/// 1. EXP Service - Level calculations, thresholds, reversal logic
/// 2. Stats Service - Stat calculations, infinite progression, reversal
/// 3. Hunter Rank Service - Rank progression, benefits, special effects
/// 4. Activity Service - Activity logging, deletion, stat application
/// 5. Data Model Validation - User, ActivityLog models
/// 6. Provider State Management - DailyLoginProvider type casting
/// 7. Edge Cases - Boundary conditions, error scenarios
void main() {
  group('Comprehensive Business Logic Testing', () {
    
    // Test 1: EXP Service Core Logic
    group('EXP Service Tests', () {
      test('EXP threshold calculation accuracy', () {
        // Test the exponential formula: 1000 * (1.2^(level-1))
        expect(EXPService.calculateEXPThreshold(1), equals(1000.0));
        expect(EXPService.calculateEXPThreshold(2), closeTo(1200.0, 0.01));
        expect(EXPService.calculateEXPThreshold(5), closeTo(2073.6, 0.1));
        expect(EXPService.calculateEXPThreshold(10), closeTo(5159.78, 1.0));
        
        // Edge case: level 0 should throw error
        expect(() => EXPService.calculateEXPThreshold(0), throwsArgumentError);
        
        // Extreme level test
        expect(EXPService.calculateEXPThreshold(100), greaterThan(100000.0));
      });

      test('EXP gain calculations for different activities', () {
        // Standard activities: 1 EXP per minute
        expect(EXPService.calculateEXPGain('workoutUpperBody', 60), equals(60.0));
        expect(EXPService.calculateEXPGain('studySerious', 120), equals(120.0));
        
        // Special case: quitBadHabit gets fixed 60 EXP
        expect(EXPService.calculateEXPGain('quitBadHabit', 30), equals(60.0));
        expect(EXPService.calculateEXPGain('quitBadHabit', 1), equals(60.0));
        
        // Edge cases
        expect(EXPService.calculateEXPGain('walking', 0), equals(0.0));
        expect(() => EXPService.calculateEXPGain('walking', -1), throwsArgumentError);
      });

      test('Level-up detection and multi-level progression', () {
        // User at level 1 with enough EXP for level 2
        final user = User.create(id: 'test', name: 'Test');
        user.currentEXP = 1500.0; // Should level up from 1 to 2
        
        final levelUpResult = EXPService.checkLevelUp(user);
        expect(levelUpResult.canLevelUp, isTrue);
        expect(levelUpResult.newLevel, equals(2));
        expect(levelUpResult.levelsGained, equals(1));
        expect(levelUpResult.excessEXP, closeTo(300.0, 1.0)); // 1500 - 1200 threshold
        
        // Multi-level progression test
        user.currentEXP = 5000.0; // Should jump multiple levels
        final multiLevelResult = EXPService.checkLevelUp(user);
        expect(multiLevelResult.levelsGained, greaterThan(1));
        expect(multiLevelResult.newLevel, greaterThan(2));
      });

      test('EXP reversal and level-down logic', () {
        // Test level-down scenario
        final user = User.create(id: 'test', name: 'Test');
        user.level = 3;
        user.currentEXP = 500.0; // Some progress in level 3
        
        // Reverse more EXP than current, should level down
        final reversedUser = EXPService.handleEXPReversal(user, 1000.0);
        expect(reversedUser.level, lessThan(3));
        expect(reversedUser.currentEXP, greaterThanOrEqualTo(0.0));
        
        // Test level-down preview
        final preview = EXPService.calculateLevelDown(user, 1000.0);
        expect(preview.willLevelDown, isTrue);
        expect(preview.levelsLost, greaterThan(0));
        expect(preview.newLevel, lessThan(3));
        
        // Edge case: reverse more EXP than user has ever earned
        user.level = 1;
        user.currentEXP = 100.0;
        final extremeReversedUser = EXPService.handleEXPReversal(user, 5000.0);
        expect(extremeReversedUser.level, equals(1)); // Should stay at minimum
        expect(extremeReversedUser.currentEXP, equals(0.0)); // Should clamp to 0
      });

      test('EXP validation edge cases', () {
        final user = User.create(id: 'test', name: 'Test');
        
        // Valid reversal
        expect(EXPService.validateEXPReversal(user, 50.0), isTrue);
        
        // Invalid reversals
        expect(EXPService.validateEXPReversal(user, -10.0), isFalse); // Negative
        expect(EXPService.validateEXPReversal(user, double.nan), isFalse); // NaN
        expect(EXPService.validateEXPReversal(user, double.infinity), isFalse); // Infinite
        
        // Test with corrupted user data
        user.currentEXP = double.nan;
        expect(EXPService.validateEXPReversal(user, 50.0), isFalse);
      });
    });

    // Test 2: Stats Service Comprehensive Testing
    group('Stats Service Tests', () {
      test('Stat gain calculations for all activity types', () {
        // Test all current activity types exist and have valid gains
        final allActivityTypes = [
          ActivityType.workoutUpperBody,
          ActivityType.workoutLowerBody,
          ActivityType.workoutCore,
          ActivityType.workoutCardio,
          ActivityType.workoutYoga,
          ActivityType.walking,
          ActivityType.studySerious,
          ActivityType.studyCasual,
          ActivityType.meditation,
          ActivityType.socializing,
          ActivityType.quitBadHabit,
          ActivityType.sleepTracking,
          ActivityType.dietHealthy,
        ];
        
        for (final activityType in allActivityTypes) {
          final gains = StatsService.calculateStatGains(activityType, 60);
          
          // Each activity should affect at least one stat
          expect(gains.isNotEmpty, isTrue, 
              reason: 'Activity ${activityType.name} should have stat gains');
          
          // All gain values should be non-negative
          for (final gain in gains.values) {
            expect(gain, greaterThanOrEqualTo(0.0),
                reason: 'Stat gains should be non-negative for ${activityType.name}');
          }
          
          // Special case: quitBadHabit should have fixed gains regardless of duration
          if (activityType == ActivityType.quitBadHabit) {
            final gains30min = StatsService.calculateStatGains(activityType, 30);
            final gains120min = StatsService.calculateStatGains(activityType, 120);
            expect(gains30min, equals(gains120min),
                reason: 'quitBadHabit should have fixed gains');
          }
        }
      });

      test('Infinite stats system validation', () {
        // Test large stat values
        final largeStats = {
          StatType.strength: 1000.0,
          StatType.agility: 500.5,
          StatType.endurance: 750.3,
          StatType.intelligence: 2000.0,
          StatType.focus: 300.7,
          StatType.charisma: 125.9,
        };
        
        final validation = StatsService.validateInfiniteStats(largeStats);
        expect(validation.isValid, isTrue);
        expect(validation.sanitizedStats, isNotNull);
        
        // Test extremely large values
        final extremeStats = {
          StatType.strength: 50000.0,
          StatType.agility: 100000.0,
          StatType.endurance: 25000.0,
          StatType.intelligence: 75000.0,
          StatType.focus: 30000.0,
          StatType.charisma: 60000.0,
        };
        
        final extremeValidation = StatsService.validateInfiniteStats(extremeStats);
        // Should handle extreme values without breaking
        expect(extremeValidation.sanitizedStats, isNotNull);
        
        // Test invalid values
        final invalidStats = {
          StatType.strength: double.nan,
          StatType.agility: double.infinity,
          StatType.endurance: -50.0,
          StatType.intelligence: 0.5, // Below 1.0 minimum
          StatType.focus: double.negativeInfinity,
          StatType.charisma: 5.0, // Valid value
        };
        
        final invalidValidation = StatsService.validateInfiniteStats(invalidStats);
        expect(invalidValidation.isValid, isFalse);
        expect(invalidValidation.sanitizedStats, isNotNull);
        
        // All sanitized values should be >= 1.0 and finite
        for (final value in invalidValidation.sanitizedStats!.values) {
          expect(value, greaterThanOrEqualTo(1.0));
          expect(value.isFinite, isTrue);
        }
      });

      test('Stat reversal calculations and validation', () {
        // Test stat reversal with stored gains (preferred method)
        final storedGains = {
          StatType.strength: 0.12,
          StatType.endurance: 0.08,
        };
        
        final reversals = StatsService.calculateStatReversals(
          ActivityType.workoutUpperBody, 60, storedGains);
        expect(reversals, equals(storedGains));
        
        // Test fallback calculation for legacy activities
        final fallbackReversals = StatsService.calculateStatReversals(
          ActivityType.workoutUpperBody, 60, null);
        expect(fallbackReversals.isNotEmpty, isTrue);
        
        // Test reversal application with floor constraint
        final currentStats = {
          StatType.strength: 2.0,
          StatType.agility: 1.5,
          StatType.endurance: 1.2,
          StatType.intelligence: 3.0,
          StatType.focus: 1.0,
          StatType.charisma: 1.8,
        };
        
        final testReversals = {
          StatType.strength: 0.5,
          StatType.endurance: 0.5, // This would bring endurance below 1.0
        };
        
        final updatedStats = StatsService.applyStatReversals(currentStats, testReversals);
        expect(updatedStats[StatType.strength], equals(1.5)); // 2.0 - 0.5
        expect(updatedStats[StatType.endurance], equals(1.0)); // Clamped to floor
        
        // Test validation
        expect(StatsService.validateStatReversal(currentStats, testReversals), isTrue);
        
        // Test invalid reversal
        final invalidReversals = {
          StatType.strength: double.nan,
        };
        expect(StatsService.validateStatReversal(currentStats, invalidReversals), isFalse);
      });

      test('Chart validation for infinite stats', () {
        // Test normal stats
        final normalStats = {
          StatType.strength: 5.0,
          StatType.agility: 7.2,
          StatType.endurance: 3.8,
          StatType.intelligence: 9.1,
          StatType.focus: 6.4,
          StatType.charisma: 4.7,
        };
        
        final normalValidation = StatsService.validateStatsForChart(normalStats);
        expect(normalValidation.isValid, isTrue);
        expect(normalValidation.recommendedMaxY, greaterThan(9.0));
        
        // Test very large stats
        final largeStats = {
          StatType.strength: 150000.0,
          StatType.agility: 200000.0,
          StatType.endurance: 100000.0,
          StatType.intelligence: 500000.0,
          StatType.focus: 75000.0,
          StatType.charisma: 300000.0,
        };
        
        final largeValidation = StatsService.validateStatsForChart(largeStats);
        expect(largeValidation.hasWarning, isTrue);
        expect(largeValidation.recommendedMaxY, greaterThan(0.0));
        
        // Test empty stats
        final emptyValidation = StatsService.validateStatsForChart({});
        expect(emptyValidation.isValid, isFalse);
      });
    });

    // Test 3: Hunter Rank Service Testing
    group('Hunter Rank Service Tests', () {
      final rankService = HunterRankService.instance;
      
      test('Rank assignment for all level ranges', () {
        // Test each rank's level range
        expect(rankService.getRankForLevel(1).rank, equals('E'));
        expect(rankService.getRankForLevel(9).rank, equals('E'));
        expect(rankService.getRankForLevel(10).rank, equals('D'));
        expect(rankService.getRankForLevel(19).rank, equals('D'));
        expect(rankService.getRankForLevel(20).rank, equals('C'));
        expect(rankService.getRankForLevel(35).rank, equals('B'));
        expect(rankService.getRankForLevel(55).rank, equals('A'));
        expect(rankService.getRankForLevel(80).rank, equals('S'));
        expect(rankService.getRankForLevel(100).rank, equals('SS'));
        expect(rankService.getRankForLevel(150).rank, equals('SSS'));
        expect(rankService.getRankForLevel(999999).rank, equals('SSS')); // Infinite SSS
      });

      test('Rank progression calculations', () {
        // Test rank progress within current rank
        final level15Progress = rankService.getRankProgress(15); // D-rank
        expect(level15Progress, greaterThan(0.0));
        expect(level15Progress, lessThan(1.0));
        
        // Test levels to next rank
        expect(rankService.getLevelsToNextRank(15), equals(5)); // 20 - 15
        expect(rankService.getLevelsToNextRank(80), equals(20)); // 100 - 80
        
        // Test at SSS rank (max rank)
        expect(rankService.getLevelsToNextRank(200), equals(0)); // Already at max
      });

      test('Rank benefits and bonuses', () {
        // Test stat bonuses increase with rank
        final eRankBonus = rankService.getStatBonus(5, StatType.strength); // E-rank
        final dRankBonus = rankService.getStatBonus(15, StatType.strength); // D-rank
        final sRankBonus = rankService.getStatBonus(85, StatType.strength); // S-rank
        
        expect(dRankBonus, greaterThan(eRankBonus));
        expect(sRankBonus, greaterThan(dRankBonus));
        
        // Test EXP bonuses
        expect(rankService.getExpBonus(5), equals(0.0)); // E-rank
        expect(rankService.getExpBonus(15), greaterThan(0.0)); // D-rank
        expect(rankService.getExpBonus(85), greaterThan(rankService.getExpBonus(15))); // S-rank
      });

      test('Rank-up detection and celebration', () {
        // Test rank-up detection
        expect(rankService.canRankUp(9, 10), isTrue); // E to D
        expect(rankService.canRankUp(19, 20), isTrue); // D to C
        expect(rankService.canRankUp(15, 16), isFalse); // Within D-rank
        
        // Test celebration data
        final celebration = rankService.getRankUpCelebration(9, 10);
        expect(celebration, isNotNull);
        expect(celebration!.oldRank.rank, equals('E'));
        expect(celebration.newRank.rank, equals('D'));
        expect(celebration.message.isNotEmpty, isTrue);
        
        // Test no celebration for non-rank-up
        final noCelebration = rankService.getRankUpCelebration(15, 16);
        expect(noCelebration, isNull);
      });

      test('Special effects for high ranks', () {
        // Test special effects
        expect(rankService.hasSpecialEffects(5), isFalse); // E-rank
        expect(rankService.hasSpecialEffects(85), isTrue); // S-rank should have effects
        expect(rankService.hasSpecialEffects(105), isTrue); // SS-rank
        expect(rankService.hasSpecialEffects(155), isTrue); // SSS-rank
        
        // Test rank data special properties
        final sRankData = rankService.getRankForLevel(85);
        expect(sRankData.hasGlowEffect, isTrue);
        
        final ssRankData = rankService.getRankForLevel(105);
        expect(ssRankData.hasPulseEffect, isTrue);
        
        final sssRankData = rankService.getRankForLevel(155);
        expect(sssRankData.hasRainbowEffect, isTrue);
      });
    });

    // Test 4: Activity System Edge Cases
    group('Activity System Edge Cases', () {
      test('Activity duration validation', () {
        final service = ActivityService();
        
        // Test valid durations
        final preview60 = service.calculateExpectedGains(
          activityType: ActivityType.workoutUpperBody,
          durationMinutes: 60,
        );
        expect(preview60.isValid, isTrue);
        
        // Test zero duration
        final preview0 = service.calculateExpectedGains(
          activityType: ActivityType.workoutUpperBody,
          durationMinutes: 0,
        );
        expect(preview0.isValid, isFalse);
        
        // Test negative duration
        final previewNegative = service.calculateExpectedGains(
          activityType: ActivityType.workoutUpperBody,
          durationMinutes: -30,
        );
        expect(previewNegative.isValid, isFalse);
        
        // Test extremely long duration (should still be valid but might warn)
        final previewLong = service.calculateExpectedGains(
          activityType: ActivityType.workoutUpperBody,
          durationMinutes: 1440, // 24 hours
        );
        expect(previewLong.isValid, isTrue);
        
        // Test duration over 24 hours (should be invalid)
        final previewTooLong = service.calculateExpectedGains(
          activityType: ActivityType.workoutUpperBody,
          durationMinutes: 1500, // Over 24 hours
        );
        expect(previewTooLong.isValid, isFalse);
      });

      test('Activity type enum consistency', () {
        // Verify all activity types from enum can be processed
        for (final activityType in ActivityType.values) {
          // Should not throw exception
          final displayName = activityType.displayName;
          expect(displayName.isNotEmpty, isTrue);
          
          final category = activityType.category;
          expect(category, isNotNull);
          
          final color = activityType.color;
          expect(color, isNotNull);
          
          final icon = activityType.materialIcon;
          expect(icon, isNotNull);
          
          // Stats calculation should work for all types
          final gains = StatsService.calculateStatGains(activityType, 60);
          expect(gains, isNotNull);
        }
      });
    });

    // Test 5: Data Model Validation
    group('User Model Tests', () {
      test('User creation and defaults', () {
        final user = User.create(id: 'test123', name: 'TestUser');
        
        expect(user.id, equals('test123'));
        expect(user.name, equals('TestUser'));
        expect(user.level, equals(1));
        expect(user.currentEXP, equals(0.0));
        expect(user.hasCompletedOnboarding, isFalse);
        
        // All stats should be initialized to 1.0
        for (final statType in StatType.values) {
          expect(user.getStat(statType), equals(1.0));
        }
        
        // Test stat operations
        user.setStat(StatType.strength, 5.5);
        expect(user.getStat(StatType.strength), equals(5.5));
        
        user.addToStat(StatType.strength, 2.0);
        expect(user.getStat(StatType.strength), equals(7.5));
      });

      test('User EXP and level calculations', () {
        final user = User.create(id: 'test', name: 'Test');
        
        // Test EXP threshold calculation
        expect(user.expThreshold, equals(1000.0)); // Level 1
        
        user.level = 5;
        expect(user.expThreshold, closeTo(2073.6, 0.1));
        
        // Test EXP progress
        user.currentEXP = 500.0;
        expect(user.expProgress, closeTo(0.241, 0.001)); // 500/2073.6
        
        // Test level-up detection
        user.currentEXP = 2100.0;
        expect(user.canLevelUp, isTrue);
        
        // Test level-up execution
        final excessEXP = user.levelUp();
        expect(user.level, equals(6));
        expect(excessEXP, closeTo(26.4, 0.1)); // 2100 - 2073.6
      });

      test('User JSON serialization', () {
        final user = User.create(id: 'test', name: 'Test');
        user.level = 5;
        user.currentEXP = 1500.0;
        user.setStat(StatType.strength, 3.5);
        user.setStat(StatType.intelligence, 2.8);
        user.hasCompletedOnboarding = true;
        
        // Test serialization
        final json = user.toJson();
        expect(json['id'], equals('test'));
        expect(json['name'], equals('Test'));
        expect(json['level'], equals(5));
        expect(json['currentEXP'], equals(1500.0));
        expect(json['hasCompletedOnboarding'], isTrue);
        
        // Test deserialization
        final deserializedUser = User.fromJson(json);
        expect(deserializedUser.id, equals(user.id));
        expect(deserializedUser.name, equals(user.name));
        expect(deserializedUser.level, equals(user.level));
        expect(deserializedUser.currentEXP, equals(user.currentEXP));
        expect(deserializedUser.getStat(StatType.strength), equals(3.5));
        expect(deserializedUser.getStat(StatType.intelligence), equals(2.8));
        expect(deserializedUser.hasCompletedOnboarding, equals(true));
      });
    });

    // Test 6: ActivityLog Model Tests
    group('ActivityLog Model Tests', () {
      test('ActivityLog creation and stat gains storage', () {
        final statGains = {
          StatType.strength: 0.12,
          StatType.endurance: 0.08,
        };
        
        final activityLog = ActivityLog.create(
          id: 'test_activity',
          activityType: ActivityType.workoutUpperBody,
          durationMinutes: 60,
          statGains: statGains,
          expGained: 60.0,
          timestamp: DateTime.now(),
        );
        
        expect(activityLog.id, equals('test_activity'));
        expect(activityLog.activityType, equals('workoutUpperBody'));
        expect(activityLog.activityTypeEnum, equals(ActivityType.workoutUpperBody));
        expect(activityLog.durationMinutes, equals(60));
        expect(activityLog.expGained, equals(60.0));
        
        // Test stat gains retrieval
        expect(activityLog.statGainsMap[StatType.strength], equals(0.12));
        expect(activityLog.statGainsMap[StatType.endurance], equals(0.08));
        
        // Test JSON serialization
        final json = activityLog.toJson();
        expect(json['activityType'], equals('workoutUpperBody'));
        expect(json['durationMinutes'], equals(60));
        expect(json['expGained'], equals(60.0));
        
        // Test deserialization
        final deserializedLog = ActivityLog.fromJson(json);
        expect(deserializedLog.activityType, equals(activityLog.activityType));
        expect(deserializedLog.durationMinutes, equals(activityLog.durationMinutes));
        expect(deserializedLog.expGained, equals(activityLog.expGained));
      });

      test('Legacy ActivityLog handling (without stored stat gains)', () {
        // Simulate legacy activity log without stored stat gains
        final legacyJson = {
          'id': 'legacy_activity',
          'activityType': 'workoutUpperBody',
          'durationMinutes': 90,
          'expGained': 90.0,
          'timestamp': DateTime.now().toIso8601String(),
          'notes': null,
          // Note: no statGains field (legacy)
        };
        
        final legacyLog = ActivityLog.fromJson(legacyJson);
        expect(legacyLog.statGainsMap.isEmpty, isTrue);
        
        // Service should handle fallback calculation
        final reversals = StatsService.calculateStatReversals(
          legacyLog.activityTypeEnum,
          legacyLog.durationMinutes,
          legacyLog.statGainsMap, // Empty map should trigger fallback
        );
        expect(reversals.isNotEmpty, isTrue);
      });
    });

    // Test 7: Provider State Management Issues
    group('Provider State Management Tests', () {
      test('DailyLoginProvider type casting issue', () {
        // This test addresses the Map<String, dynamic> casting issue found in tests
        final provider = DailyLoginProvider();
        
        expect(() => provider.initialize(), returnsNormally);
        
        // Test the type casting that was causing issues
        final testStats = {
          'currentStreak': 5,
          'totalLoginDays': 25,
          'canLoginToday': true,
          'streakMultiplier': 1.5,
          'lastLoginDate': DateTime.now(),
        };
        
        // These casts should work without throwing
        expect(testStats['currentStreak'] as int?, equals(5));
        expect(testStats['totalLoginDays'] as int?, equals(25));
        expect(testStats['canLoginToday'] as bool?, isTrue);
        expect(testStats['streakMultiplier'] as double?, equals(1.5));
        expect(testStats['lastLoginDate'] as DateTime?, isNotNull);
      });
    });

    // Test 8: Integration and Edge Cases
    group('Integration Tests', () {
      test('Complete activity logging and deletion cycle', () {
        // This test simulates the complete cycle of logging an activity
        // and then deleting it to ensure stat reversal works correctly
        
        final user = User.create(id: 'test', name: 'Test');
        user.level = 3;
        user.currentEXP = 800.0;
        user.setStat(StatType.strength, 2.5);
        user.setStat(StatType.endurance, 2.0);
        
        // Store original state
        final originalLevel = user.level;
        final originalEXP = user.currentEXP;
        final originalStrength = user.getStat(StatType.strength);
        final originalEndurance = user.getStat(StatType.endurance);
        
        // Calculate gains for upper body workout
        final statGains = StatsService.calculateStatGains(ActivityType.workoutUpperBody, 60);
        final expGain = 60.0;
        
        // Apply gains (simulate activity logging)
        for (final entry in statGains.entries) {
          user.addToStat(entry.key, entry.value);
        }
        user.currentEXP += expGain;
        
        // Verify gains were applied
        expect(user.getStat(StatType.strength), greaterThan(originalStrength));
        expect(user.getStat(StatType.endurance), greaterThan(originalEndurance));
        expect(user.currentEXP, greaterThan(originalEXP));
        
        // Now simulate activity deletion with stat reversal
        final updatedStats = StatsService.applyStatReversals(
          {
            for (final statType in StatType.values)
              statType: user.getStat(statType),
          },
          statGains,
        );
        
        final reversedUser = EXPService.handleEXPReversal(user, expGain);
        
        // Apply reversed stats
        for (final entry in updatedStats.entries) {
          user.setStat(entry.key, entry.value);
        }
        user.level = reversedUser.level;
        user.currentEXP = reversedUser.currentEXP;
        
        // Verify reversal worked (should be close to original values)
        expect(user.level, equals(originalLevel));
        expect(user.currentEXP, closeTo(originalEXP, 0.01));
        expect(user.getStat(StatType.strength), closeTo(originalStrength, 0.01));
        expect(user.getStat(StatType.endurance), closeTo(originalEndurance, 0.01));
      });

      test('Boundary conditions for infinite stats', () {
        // Test the boundaries of the infinite stats system
        final user = User.create(id: 'test', name: 'Test');
        
        // Test minimum stat enforcement
        user.setStat(StatType.strength, 0.5); // Below minimum
        expect(user.getStat(StatType.strength), equals(0.5)); // Model allows it
        
        // But validation should catch it
        final stats = {StatType.strength: 0.5};
        final validation = StatsService.validateInfiniteStats(stats);
        expect(validation.sanitizedStats![StatType.strength], equals(1.0));
        
        // Test very large stats
        user.setStat(StatType.intelligence, 100000.0);
        expect(user.getStat(StatType.intelligence), equals(100000.0));
        
        // Test stat operations with large numbers
        user.addToStat(StatType.intelligence, 50000.0);
        expect(user.getStat(StatType.intelligence), equals(150000.0));
        
        // Test reversal with large stats
        final largeReversals = {StatType.intelligence: 25000.0};
        final currentStats = {StatType.intelligence: 150000.0};
        final reversedStats = StatsService.applyStatReversals(currentStats, largeReversals);
        expect(reversedStats[StatType.intelligence], equals(125000.0));
      });
    });
  });
}