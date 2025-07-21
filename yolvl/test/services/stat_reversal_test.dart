import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/stats_service.dart';
import '../../lib/services/exp_service.dart';
import '../../lib/models/enums.dart';
import '../../lib/models/user.dart';

void main() {
  group('StatsService Stat Reversal Tests', () {
    test('calculateStatReversals should use stored stat gains when available', () {
      // Arrange
      final storedGains = {
        StatType.strength: 0.12,
        StatType.endurance: 0.08,
      };

      // Act
      final reversals = StatsService.calculateStatReversals(
        ActivityType.workoutWeights,
        120, // 2 hours
        storedGains,
      );

      // Assert
      expect(reversals, equals(storedGains));
      expect(reversals[StatType.strength], equals(0.12));
      expect(reversals[StatType.endurance], equals(0.08));
    });

    test('calculateStatReversals should fallback to calculated gains when stored gains are null', () {
      // Act
      final reversals = StatsService.calculateStatReversals(
        ActivityType.workoutWeights,
        120, // 2 hours
        null,
      );

      // Assert - should match calculated gains for 2 hours of weight training
      expect(reversals[StatType.strength], equals(0.12)); // 0.06 * 2
      expect(reversals[StatType.endurance], equals(0.08)); // 0.04 * 2
    });

    test('calculateStatReversals should fallback to calculated gains when stored gains are empty', () {
      // Act
      final reversals = StatsService.calculateStatReversals(
        ActivityType.meditation,
        60, // 1 hour
        {},
      );

      // Assert - should match calculated gains for 1 hour of meditation
      expect(reversals[StatType.focus], equals(0.05)); // 0.05 * 1
      expect(reversals.length, equals(1));
    });

    test('calculateStatReversals should handle zero duration', () {
      // Act
      final reversals = StatsService.calculateStatReversals(
        ActivityType.workoutCardio,
        0,
        null,
      );

      // Assert - zero duration should result in zero gains for all stats
      expect(reversals[StatType.agility], equals(0.0));
      expect(reversals[StatType.endurance], equals(0.0));
    });

    test('calculateStatReversals should throw on negative duration', () {
      // Act & Assert
      expect(
        () => StatsService.calculateStatReversals(
          ActivityType.workoutCardio,
          -30,
          null,
        ),
        throwsArgumentError,
      );
    });

    test('applyStatReversals should correctly reverse stat gains', () {
      // Arrange
      final currentStats = {
        StatType.strength: 3.5,
        StatType.agility: 2.8,
        StatType.endurance: 4.2,
        StatType.intelligence: 2.1,
        StatType.focus: 3.0,
        StatType.charisma: 1.9,
      };

      final reversals = {
        StatType.strength: 0.12,
        StatType.endurance: 0.08,
      };

      // Act
      final updatedStats = StatsService.applyStatReversals(currentStats, reversals);

      // Assert
      expect(updatedStats[StatType.strength], equals(3.38)); // 3.5 - 0.12
      expect(updatedStats[StatType.endurance], equals(4.12)); // 4.2 - 0.08
      expect(updatedStats[StatType.agility], equals(2.8)); // Unchanged
      expect(updatedStats[StatType.intelligence], equals(2.1)); // Unchanged
      expect(updatedStats[StatType.focus], equals(3.0)); // Unchanged
      expect(updatedStats[StatType.charisma], equals(1.9)); // Unchanged
    });

    test('applyStatReversals should enforce minimum floor value', () {
      // Arrange
      final currentStats = {
        StatType.strength: 1.05,
        StatType.agility: 2.0,
        StatType.endurance: 1.0,
        StatType.intelligence: 1.5,
        StatType.focus: 3.0,
        StatType.charisma: 1.2,
      };

      final reversals = {
        StatType.strength: 0.1, // Would result in 0.95, should be clamped to 1.0
        StatType.endurance: 0.5, // Would result in 0.5, should be clamped to 1.0
        StatType.charisma: 0.3, // Would result in 0.9, should be clamped to 1.0
      };

      // Act
      final updatedStats = StatsService.applyStatReversals(currentStats, reversals);

      // Assert
      expect(updatedStats[StatType.strength], equals(1.0)); // Clamped to floor
      expect(updatedStats[StatType.endurance], equals(1.0)); // Clamped to floor
      expect(updatedStats[StatType.charisma], equals(1.0)); // Clamped to floor
      expect(updatedStats[StatType.agility], equals(2.0)); // Unchanged
      expect(updatedStats[StatType.intelligence], equals(1.5)); // Unchanged
      expect(updatedStats[StatType.focus], equals(3.0)); // Unchanged
    });

    test('applyStatReversals should handle custom minimum floor value', () {
      // Arrange
      final currentStats = {
        StatType.strength: 2.5,
        StatType.agility: 2.0,
        StatType.endurance: 1.8,
        StatType.intelligence: 1.5,
        StatType.focus: 3.0,
        StatType.charisma: 1.2,
      };

      final reversals = {
        StatType.strength: 1.0, // Would result in 1.5, but floor is 2.0, so should be 2.0
        StatType.endurance: 1.0, // Would result in 0.8, should be clamped to 2.0
      };

      // Act
      final updatedStats = StatsService.applyStatReversals(
        currentStats, 
        reversals, 
        minValue: 2.0,
      );

      // Assert
      expect(updatedStats[StatType.strength], equals(2.0)); // Clamped to custom floor
      expect(updatedStats[StatType.endurance], equals(2.0)); // Clamped to custom floor
    });

    test('applyStatReversals should handle missing stats in current stats map', () {
      // Arrange
      final currentStats = {
        StatType.strength: 3.0,
        // Missing other stats
      };

      final reversals = {
        StatType.strength: 0.5,
        StatType.agility: 0.3, // Not in current stats
      };

      // Act
      final updatedStats = StatsService.applyStatReversals(currentStats, reversals);

      // Assert
      expect(updatedStats[StatType.strength], equals(2.5)); // 3.0 - 0.5
      expect(updatedStats[StatType.agility], equals(1.0)); // Default 1.0 - 0.3, clamped to 1.0
      expect(updatedStats[StatType.endurance], equals(1.0)); // Default value
      expect(updatedStats[StatType.intelligence], equals(1.0)); // Default value
      expect(updatedStats[StatType.focus], equals(1.0)); // Default value
      expect(updatedStats[StatType.charisma], equals(1.0)); // Default value
    });

    test('validateStatReversal should return true for valid reversals', () {
      // Arrange
      final currentStats = {
        StatType.strength: 3.0,
        StatType.agility: 2.5,
        StatType.endurance: 4.0,
        StatType.intelligence: 2.0,
        StatType.focus: 3.5,
        StatType.charisma: 1.8,
      };

      final reversals = {
        StatType.strength: 0.5,
        StatType.endurance: 1.0,
      };

      // Act
      final isValid = StatsService.validateStatReversal(currentStats, reversals);

      // Assert
      expect(isValid, isTrue);
    });

    test('validateStatReversal should return true even when reversal would hit floor', () {
      // Arrange
      final currentStats = {
        StatType.strength: 1.2,
        StatType.agility: 2.0,
        StatType.endurance: 1.0,
        StatType.intelligence: 1.5,
        StatType.focus: 3.0,
        StatType.charisma: 1.1,
      };

      final reversals = {
        StatType.strength: 0.5, // Would result in 0.7, but gets clamped
        StatType.endurance: 0.2, // Would result in 0.8, but gets clamped
      };

      // Act
      final isValid = StatsService.validateStatReversal(currentStats, reversals);

      // Assert
      expect(isValid, isTrue); // Should be valid - we allow clamping to floor
    });
  });

  group('EXPService EXP Reversal Tests', () {
    test('handleEXPReversal should correctly reverse EXP without level change', () {
      // Arrange
      final user = User.create(id: 'test', name: 'Test User').copyWith(
        level: 5,
        currentEXP: 500.0,
      );

      // Act
      final updatedUser = EXPService.handleEXPReversal(user, 200.0);

      // Assert
      expect(updatedUser.level, equals(5));
      expect(updatedUser.currentEXP, equals(300.0));
    });

    test('handleEXPReversal should handle single level-down scenario', () {
      // Arrange
      final user = User.create(id: 'test', name: 'Test User').copyWith(
        level: 3,
        currentEXP: 100.0, // Level 3 threshold is 1440, so this is low EXP
      );

      // Act - reverse more EXP than current, should go to level 2
      final updatedUser = EXPService.handleEXPReversal(user, 300.0);

      // Assert
      expect(updatedUser.level, equals(2));
      // Level 2 threshold is 1200, so: 100 - 300 = -200, then +1200 = 1000
      expect(updatedUser.currentEXP, equals(1000.0));
    });

    test('handleEXPReversal should handle multiple level-down scenario', () {
      // Arrange
      final user = User.create(id: 'test', name: 'Test User').copyWith(
        level: 4,
        currentEXP: 200.0,
      );

      // Act - reverse a lot of EXP to trigger multiple level-downs
      final updatedUser = EXPService.handleEXPReversal(user, 2000.0);

      // Assert
      expect(updatedUser.level, equals(2)); // Goes from level 4 to level 2
      expect(updatedUser.currentEXP, equals(840.0)); // 200 - 2000 + 1440 + 1200
    });

    test('handleEXPReversal should handle extreme level-down to level 1', () {
      // Arrange
      final user = User.create(id: 'test', name: 'Test User').copyWith(
        level: 4,
        currentEXP: 200.0,
      );

      // Act - reverse extreme amount of EXP to go to level 1
      final updatedUser = EXPService.handleEXPReversal(user, 5000.0);

      // Assert
      expect(updatedUser.level, equals(1));
      expect(updatedUser.currentEXP, greaterThanOrEqualTo(0.0));
    });

    test('handleEXPReversal should not go below level 1', () {
      // Arrange
      final user = User.create(id: 'test', name: 'Test User').copyWith(
        level: 1,
        currentEXP: 50.0,
      );

      // Act - reverse more EXP than available
      final updatedUser = EXPService.handleEXPReversal(user, 100.0);

      // Assert
      expect(updatedUser.level, equals(1));
      expect(updatedUser.currentEXP, equals(0.0));
    });

    test('handleEXPReversal should handle zero EXP reversal', () {
      // Arrange
      final user = User.create(id: 'test', name: 'Test User').copyWith(
        level: 3,
        currentEXP: 500.0,
      );

      // Act
      final updatedUser = EXPService.handleEXPReversal(user, 0.0);

      // Assert
      expect(updatedUser.level, equals(3));
      expect(updatedUser.currentEXP, equals(500.0));
    });

    test('handleEXPReversal should throw on negative EXP reversal', () {
      // Arrange
      final user = User.create(id: 'test', name: 'Test User');

      // Act & Assert
      expect(
        () => EXPService.handleEXPReversal(user, -50.0),
        throwsArgumentError,
      );
    });

    test('calculateLevelDown should predict level-down correctly', () {
      // Arrange
      final user = User.create(id: 'test', name: 'Test User').copyWith(
        level: 3,
        currentEXP: 100.0,
      );

      // Act
      final result = EXPService.calculateLevelDown(user, 300.0);

      // Assert
      expect(result.willLevelDown, isTrue);
      expect(result.newLevel, equals(2));
      expect(result.levelsLost, equals(1));
      expect(result.newEXP, equals(1000.0)); // 100 - 300 + 1200 (level 2 threshold)
    });

    test('calculateLevelDown should predict no level-down when EXP is sufficient', () {
      // Arrange
      final user = User.create(id: 'test', name: 'Test User').copyWith(
        level: 5,
        currentEXP: 1000.0,
      );

      // Act
      final result = EXPService.calculateLevelDown(user, 500.0);

      // Assert
      expect(result.willLevelDown, isFalse);
      expect(result.newLevel, equals(5));
      expect(result.levelsLost, equals(0));
      expect(result.newEXP, equals(500.0));
    });

    test('calculateLevelDown should handle multiple level-downs', () {
      // Arrange
      final user = User.create(id: 'test', name: 'Test User').copyWith(
        level: 4,
        currentEXP: 100.0,
      );

      // Act
      final result = EXPService.calculateLevelDown(user, 3000.0);

      // Assert
      expect(result.willLevelDown, isTrue);
      expect(result.newLevel, equals(1));
      expect(result.levelsLost, equals(3));
      expect(result.newEXP, greaterThanOrEqualTo(0.0));
    });

    test('validateEXPReversal should return true for valid reversals', () {
      // Arrange
      final user = User.create(id: 'test', name: 'Test User');

      // Act & Assert
      expect(EXPService.validateEXPReversal(user, 100.0), isTrue);
      expect(EXPService.validateEXPReversal(user, 0.0), isTrue);
      expect(EXPService.validateEXPReversal(user, 10000.0), isTrue); // Even large reversals are valid
    });

    test('validateEXPReversal should return false for negative reversals', () {
      // Arrange
      final user = User.create(id: 'test', name: 'Test User');

      // Act & Assert
      expect(EXPService.validateEXPReversal(user, -50.0), isFalse);
    });
  });

  group('Integration Tests - Stat and EXP Reversal', () {
    test('should handle complete activity reversal scenario', () {
      // Arrange - simulate a user who logged a 2-hour weight training session
      final user = User.create(id: 'test', name: 'Test User').copyWith(
        level: 2,
        currentEXP: 500.0,
        stats: {
          StatType.strength.name: 2.12,
          StatType.agility.name: 1.0,
          StatType.endurance.name: 1.08,
          StatType.intelligence.name: 1.0,
          StatType.focus.name: 1.0,
          StatType.charisma.name: 1.0,
        },
      );

      final storedStatGains = {
        StatType.strength: 0.12, // 0.06 * 2 hours
        StatType.endurance: 0.08, // 0.04 * 2 hours
      };

      final expGained = 120.0; // 2 hours * 60 minutes

      // Act - reverse the activity
      final statReversals = StatsService.calculateStatReversals(
        ActivityType.workoutWeights,
        120,
        storedStatGains,
      );

      final updatedStatsMap = StatsService.applyStatReversals(
        user.stats.map((key, value) => MapEntry(
          StatType.values.firstWhere((type) => type.name == key),
          value,
        )),
        statReversals,
      );

      final updatedUser = EXPService.handleEXPReversal(user, expGained);

      // Assert
      expect(statReversals[StatType.strength], equals(0.12));
      expect(statReversals[StatType.endurance], equals(0.08));
      
      expect(updatedStatsMap[StatType.strength], equals(2.0)); // 2.12 - 0.12
      expect(updatedStatsMap[StatType.endurance], equals(1.0)); // 1.08 - 0.08
      expect(updatedStatsMap[StatType.agility], equals(1.0)); // Unchanged
      
      expect(updatedUser.currentEXP, equals(380.0)); // 500 - 120
      expect(updatedUser.level, equals(2)); // No level change
    });

    test('should handle activity reversal with level-down', () {
      // Arrange - user at low EXP who will level down
      final user = User.create(id: 'test', name: 'Test User').copyWith(
        level: 3,
        currentEXP: 50.0,
        stats: {
          StatType.strength.name: 2.5,
          StatType.agility.name: 1.0,
          StatType.endurance.name: 2.0,
          StatType.intelligence.name: 1.0,
          StatType.focus.name: 1.0,
          StatType.charisma.name: 1.0,
        },
      );

      final storedStatGains = {
        StatType.strength: 0.5,
        StatType.endurance: 0.3,
      };

      final expGained = 200.0;

      // Act
      final statReversals = StatsService.calculateStatReversals(
        ActivityType.workoutWeights,
        200, // Duration doesn't matter when using stored gains
        storedStatGains,
      );

      final updatedStatsMap = StatsService.applyStatReversals(
        user.stats.map((key, value) => MapEntry(
          StatType.values.firstWhere((type) => type.name == key),
          value,
        )),
        statReversals,
      );

      final updatedUser = EXPService.handleEXPReversal(user, expGained);

      // Assert
      expect(updatedStatsMap[StatType.strength], equals(2.0)); // 2.5 - 0.5
      expect(updatedStatsMap[StatType.endurance], equals(1.7)); // 2.0 - 0.3
      
      expect(updatedUser.level, equals(2)); // Should level down
      expect(updatedUser.currentEXP, equals(1050.0)); // 50 - 200 + 1200 (level 2 threshold)
    });
  });
}