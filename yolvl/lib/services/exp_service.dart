import 'dart:math';
import '../models/user.dart';

/// Service for handling EXP calculations and leveling mechanics
class EXPService {
  /// Calculate EXP threshold for a given level using formula: 1000 * (1.2^(level-1))
  static double calculateEXPThreshold(int level) {
    if (level <= 0) {
      throw ArgumentError('Level must be greater than 0');
    }
    return 1000.0 * pow(1.2, level - 1).toDouble();
  }

  /// Calculate EXP gain based on activity type and duration
  /// Standard activities: 1 EXP per minute
  /// Quit Bad Habit: Fixed 60 EXP regardless of duration
  static double calculateEXPGain(String activityType, int durationMinutes) {
    if (durationMinutes < 0) {
      throw ArgumentError('Duration must be non-negative');
    }
    
    if (activityType == 'quitBadHabit') {
      return 60.0; // Fixed EXP for quit bad habit
    }
    
    return durationMinutes.toDouble(); // 1 EXP per minute
  }

  /// Check if user can level up and return level-up information
  static LevelUpResult checkLevelUp(User user) {
    final currentThreshold = calculateEXPThreshold(user.level);
    
    if (user.currentEXP < currentThreshold) {
      return LevelUpResult(
        canLevelUp: false,
        newLevel: user.level,
        excessEXP: 0.0,
        levelsGained: 0,
      );
    }

    // Handle multiple level-ups
    int newLevel = user.level;
    double remainingEXP = user.currentEXP;
    int levelsGained = 0;

    while (remainingEXP >= calculateEXPThreshold(newLevel)) {
      final threshold = calculateEXPThreshold(newLevel);
      remainingEXP -= threshold;
      newLevel++;
      levelsGained++;
      
      // Safety check to prevent infinite loops
      if (levelsGained > 100) {
        break;
      }
    }

    return LevelUpResult(
      canLevelUp: true,
      newLevel: newLevel,
      excessEXP: remainingEXP,
      levelsGained: levelsGained,
    );
  }

  /// Apply level-up to user and return updated user
  static User applyLevelUp(User user) {
    final levelUpResult = checkLevelUp(user);
    
    if (!levelUpResult.canLevelUp) {
      return user;
    }

    return user.copyWith(
      level: levelUpResult.newLevel,
      currentEXP: levelUpResult.excessEXP,
    );
  }

  /// Add EXP to user and handle automatic level-ups
  static User addEXP(User user, double expToAdd) {
    if (expToAdd < 0) {
      throw ArgumentError('EXP to add must be non-negative');
    }

    final updatedUser = user.copyWith(
      currentEXP: user.currentEXP + expToAdd,
    );

    return applyLevelUp(updatedUser);
  }

  /// Calculate EXP progress percentage for current level
  static double calculateEXPProgress(User user) {
    final threshold = calculateEXPThreshold(user.level);
    return (user.currentEXP / threshold).clamp(0.0, 1.0);
  }

  /// Get EXP needed for next level
  static double getEXPNeededForNextLevel(User user) {
    final threshold = calculateEXPThreshold(user.level);
    return (threshold - user.currentEXP).clamp(0.0, threshold);
  }
}

/// Result of level-up check
class LevelUpResult {
  final bool canLevelUp;
  final int newLevel;
  final double excessEXP;
  final int levelsGained;

  const LevelUpResult({
    required this.canLevelUp,
    required this.newLevel,
    required this.excessEXP,
    required this.levelsGained,
  });

  @override
  String toString() {
    return 'LevelUpResult(canLevelUp: $canLevelUp, newLevel: $newLevel, excessEXP: $excessEXP, levelsGained: $levelsGained)';
  }
}