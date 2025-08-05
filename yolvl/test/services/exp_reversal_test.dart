import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/exp_service.dart';
import '../../lib/models/user.dart';

void main() {
  group('EXPService EXP Reversal and Level-Down Tests', () {
    test('handleEXPReversal should maintain user data integrity', () {
      // Arrange
      final originalUser = User.create(id: 'test', name: 'Test User').copyWith(
        level: 3,
        currentEXP: 500.0,
        stats: {
          'strength': 2.5,
          'agility': 1.8,
          'endurance': 3.2,
          'intelligence': 1.5,
          'focus': 2.1,
          'charisma': 1.9,
        },
      );

      // Act
      final updatedUser = EXPService.handleEXPReversal(originalUser, 200.0);

      // Assert - only level and EXP should change, other data should remain intact
      expect(updatedUser.id, equals(originalUser.id));
      expect(updatedUser.name, equals(originalUser.name));
      expect(updatedUser.stats, equals(originalUser.stats));
      expect(updatedUser.createdAt, equals(originalUser.createdAt));
      expect(updatedUser.hasCompletedOnboarding, equals(originalUser.hasCompletedOnboarding));
      
      // Only EXP should change
      expect(updatedUser.currentEXP, equals(300.0));
      expect(updatedUser.level, equals(3));
    });

    test('handleEXPReversal should handle exact level threshold reversal', () {
      // Arrange - user at exact level threshold (ready to level up)
      final user = User.create(id: 'test', name: 'Test User').copyWith(
        level: 3,
        currentEXP: 1440.0, // Exact threshold for level 3 (ready to level up to 4)
      );

      // Act - reverse exactly the threshold amount
      final updatedUser = EXPService.handleEXPReversal(user, 1440.0);

      // Assert - should stay at level 3 with 0 EXP (since 1440 - 1440 = 0, no level down needed)
      expect(updatedUser.level, equals(3));
      expect(updatedUser.currentEXP, equals(0.0));
    });

    test('handleEXPReversal should handle fractional EXP values', () {
      // Arrange
      final user = User.create(id: 'test', name: 'Test User').copyWith(
        level: 2,
        currentEXP: 500.5,
      );

      // Act
      final updatedUser = EXPService.handleEXPReversal(user, 200.25);

      // Assert
      expect(updatedUser.level, equals(2));
      expect(updatedUser.currentEXP, equals(300.25));
    });

    test('calculateLevelDown should handle edge case at level 1', () {
      // Arrange
      final user = User.create(id: 'test', name: 'Test User').copyWith(
        level: 1,
        currentEXP: 999.0,
      );

      // Act
      final result = EXPService.calculateLevelDown(user, 1500.0);

      // Assert - can't go below level 1
      expect(result.willLevelDown, isFalse);
      expect(result.newLevel, equals(1));
      expect(result.levelsLost, equals(0));
      expect(result.newEXP, equals(0.0));
    });

    test('calculateLevelDown should handle zero EXP reversal', () {
      // Arrange
      final user = User.create(id: 'test', name: 'Test User').copyWith(
        level: 5,
        currentEXP: 1000.0,
      );

      // Act
      final result = EXPService.calculateLevelDown(user, 0.0);

      // Assert
      expect(result.willLevelDown, isFalse);
      expect(result.newLevel, equals(5));
      expect(result.levelsLost, equals(0));
      expect(result.newEXP, equals(1000.0));
    });

    test('calculateLevelDown should throw on negative EXP reversal', () {
      // Arrange
      final user = User.create(id: 'test', name: 'Test User');

      // Act & Assert
      expect(
        () => EXPService.calculateLevelDown(user, -100.0),
        throwsArgumentError,
      );
    });

    test('handleEXPReversal should handle complex multi-level scenario', () {
      // Arrange - user at high level with complex reversal
      final user = User.create(id: 'test', name: 'Test User').copyWith(
        level: 6,
        currentEXP: 100.0,
      );

      // Act - reverse enough to go down 3 levels
      final updatedUser = EXPService.handleEXPReversal(user, 4000.0);

      // Assert
      expect(updatedUser.level, lessThan(6));
      expect(updatedUser.currentEXP, greaterThanOrEqualTo(0.0));
      expect(updatedUser.level, greaterThanOrEqualTo(1));
    });

    test('EXP threshold calculations should be consistent', () {
      // Test that our EXP threshold calculations match the formula
      expect(EXPService.calculateEXPThreshold(1), equals(1000.0));
      expect(EXPService.calculateEXPThreshold(2), equals(1200.0));
      expect(EXPService.calculateEXPThreshold(3), equals(1440.0));
      expect(EXPService.calculateEXPThreshold(4), equals(1728.0));
      expect(EXPService.calculateEXPThreshold(5), equals(2073.6));
    });

    test('handleEXPReversal should work with User model methods', () {
      // Arrange
      final user = User.create(id: 'test', name: 'Test User').copyWith(
        level: 3,
        currentEXP: 800.0,
      );

      // Act
      final updatedUser = EXPService.handleEXPReversal(user, 300.0);

      // Assert - test integration with User model methods
      expect(updatedUser.expThreshold, equals(1440.0)); // Level 3 threshold
      expect(updatedUser.expProgress, equals(500.0 / 1440.0)); // 500 EXP / 1440 threshold
      expect(updatedUser.canLevelUp, isFalse);
    });

    test('validateEXPReversal should handle edge cases', () {
      // Arrange
      final user = User.create(id: 'test', name: 'Test User');

      // Act & Assert
      expect(EXPService.validateEXPReversal(user, 0.0), isTrue);
      expect(EXPService.validateEXPReversal(user, 0.1), isTrue);
      expect(EXPService.validateEXPReversal(user, 999999.0), isTrue);
      expect(EXPService.validateEXPReversal(user, -0.1), isFalse);
      expect(EXPService.validateEXPReversal(user, -999.0), isFalse);
    });

    test('level-down should preserve EXP calculation accuracy', () {
      // Arrange - test with precise EXP values
      final user = User.create(id: 'test', name: 'Test User').copyWith(
        level: 4,
        currentEXP: 1728.0, // Exact level 4 threshold (ready to level up to 5)
      );

      // Act - reverse exactly one level's worth
      final updatedUser = EXPService.handleEXPReversal(user, 1728.0);

      // Assert - should stay at level 4 with 0 EXP (since 1728 - 1728 = 0, no level down needed)
      expect(updatedUser.level, equals(4));
      expect(updatedUser.currentEXP, equals(0.0));
    });
  });

  group('EXP Reversal Integration with Activity Types', () {
    test('should handle quit bad habit EXP reversal', () {
      // Arrange - quit bad habit gives fixed 60 EXP
      final user = User.create(id: 'test', name: 'Test User').copyWith(
        level: 2,
        currentEXP: 100.0,
      );

      // Act - reverse the fixed EXP from quit bad habit
      final expGain = EXPService.calculateEXPGain('quitBadHabit', 0);
      final updatedUser = EXPService.handleEXPReversal(user, expGain);

      // Assert
      expect(expGain, equals(60.0));
      expect(updatedUser.currentEXP, equals(40.0));
      expect(updatedUser.level, equals(2));
    });

    test('should handle standard activity EXP reversal', () {
      // Arrange - standard activities give 1 EXP per minute
      final user = User.create(id: 'test', name: 'Test User').copyWith(
        level: 2,
        currentEXP: 200.0,
      );

      // Act - reverse EXP from 90-minute workout
      final expGain = EXPService.calculateEXPGain('workoutUpperBody', 90);
      final updatedUser = EXPService.handleEXPReversal(user, expGain);

      // Assert
      expect(expGain, equals(90.0));
      expect(updatedUser.currentEXP, equals(110.0));
      expect(updatedUser.level, equals(2));
    });

    test('should handle activity EXP reversal with level-down', () {
      // Arrange - user with low EXP who will level down
      final user = User.create(id: 'test', name: 'Test User').copyWith(
        level: 3,
        currentEXP: 50.0,
      );

      // Act - reverse EXP from long study session
      final expGain = EXPService.calculateEXPGain('studySerious', 180); // 3 hours
      final updatedUser = EXPService.handleEXPReversal(user, expGain);

      // Assert
      expect(expGain, equals(180.0));
      expect(updatedUser.level, equals(2)); // Should level down
      expect(updatedUser.currentEXP, equals(1070.0)); // 50 - 180 + 1200
    });
  });
}