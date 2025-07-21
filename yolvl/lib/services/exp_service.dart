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

  /// Handle EXP reversal for activity deletion
  /// Removes EXP and handles level-down scenarios if necessary
  static User handleEXPReversal(User user, double expToReverse) {
    if (expToReverse < 0) {
      throw ArgumentError('EXP to reverse must be non-negative');
    }

    if (expToReverse == 0) {
      return user; // No EXP to reverse
    }

    // Calculate new EXP after reversal
    double newEXP = user.currentEXP - expToReverse;
    int newLevel = user.level;

    // Handle level-down scenarios
    while (newEXP < 0 && newLevel > 1) {
      // Move to previous level
      newLevel--;
      final previousLevelThreshold = calculateEXPThreshold(newLevel);
      newEXP += previousLevelThreshold;
    }

    // Ensure EXP doesn't go below 0 and level doesn't go below 1
    newEXP = newEXP < 0 ? 0 : newEXP;
    newLevel = newLevel < 1 ? 1 : newLevel;

    return user.copyWith(
      level: newLevel,
      currentEXP: newEXP,
    );
  }

  /// Calculate level-down information for preview purposes
  /// Returns information about what would happen if EXP is reversed
  static LevelDownResult calculateLevelDown(User user, double expToReverse) {
    if (expToReverse < 0) {
      throw ArgumentError('EXP to reverse must be non-negative');
    }

    if (expToReverse == 0) {
      return LevelDownResult(
        willLevelDown: false,
        newLevel: user.level,
        newEXP: user.currentEXP,
        levelsLost: 0,
      );
    }

    double newEXP = user.currentEXP - expToReverse;
    int newLevel = user.level;
    int levelsLost = 0;

    // Calculate level-down scenarios
    while (newEXP < 0 && newLevel > 1) {
      newLevel--;
      levelsLost++;
      final previousLevelThreshold = calculateEXPThreshold(newLevel);
      newEXP += previousLevelThreshold;
    }

    // Ensure EXP doesn't go below 0 and level doesn't go below 1
    newEXP = newEXP < 0 ? 0 : newEXP;
    newLevel = newLevel < 1 ? 1 : newLevel;

    return LevelDownResult(
      willLevelDown: levelsLost > 0,
      newLevel: newLevel,
      newEXP: newEXP,
      levelsLost: levelsLost,
    );
  }

  /// Validate EXP reversal operation
  /// Returns true if reversal is safe to apply
  static bool validateEXPReversal(User user, double expToReverse) {
    try {
      // Validate input parameters
      if (expToReverse < 0) {
        _logError('validateEXPReversal', 'Negative EXP reversal amount: $expToReverse');
        return false;
      }

      if (expToReverse.isNaN || expToReverse.isInfinite) {
        _logError('validateEXPReversal', 'Invalid EXP reversal amount: $expToReverse');
        return false;
      }

      // Validate user data
      if (user.currentEXP.isNaN || user.currentEXP.isInfinite) {
        _logError('validateEXPReversal', 'Invalid current EXP value: ${user.currentEXP}');
        return false;
      }

      if (user.level < 1) {
        _logError('validateEXPReversal', 'Invalid user level: ${user.level}');
        return false;
      }

      // Check for extreme reversal amounts that might indicate data corruption
      if (expToReverse > 1000000) { // 1 million EXP seems excessive for a single activity
        _logWarning('validateEXPReversal', 'Very large EXP reversal amount: $expToReverse');
      }

      // Calculate what would happen after reversal
      final levelDownResult = calculateLevelDown(user, expToReverse);
      
      // Validate the calculated result
      if (levelDownResult.newLevel < 1) {
        _logError('validateEXPReversal', 'Level-down calculation resulted in invalid level: ${levelDownResult.newLevel}');
        return false;
      }

      if (levelDownResult.newEXP.isNaN || levelDownResult.newEXP.isInfinite) {
        _logError('validateEXPReversal', 'Level-down calculation resulted in invalid EXP: ${levelDownResult.newEXP}');
        return false;
      }

      // Log significant level-downs for monitoring
      if (levelDownResult.levelsLost > 5) {
        _logWarning('validateEXPReversal', 
          'Significant level-down detected: ${levelDownResult.levelsLost} levels (${user.level} -> ${levelDownResult.newLevel})');
      }

      return true; // EXP reversal is valid
    } catch (e) {
      _logError('validateEXPReversal', 'Exception during validation: $e');
      return false;
    }
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

/// Result of level-down calculation
class LevelDownResult {
  final bool willLevelDown;
  final int newLevel;
  final double newEXP;
  final int levelsLost;

  const LevelDownResult({
    required this.willLevelDown,
    required this.newLevel,
    required this.newEXP,
    required this.levelsLost,
  });

  @override
  String toString() {
    return 'LevelDownResult(willLevelDown: $willLevelDown, newLevel: $newLevel, newEXP: $newEXP, levelsLost: $levelsLost)';
  }

  /// Log error messages with context
  static void _logError(String method, String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] ERROR EXPService.$method: $message';
    print(logMessage); // In production, use proper logging framework
  }

  /// Log warning messages with context
  static void _logWarning(String method, String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] WARNING EXPService.$method: $message';
    print(logMessage); // In production, use proper logging framework
  }

  /// Log info messages with context
  static void _logInfo(String method, String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] INFO EXPService.$method: $message';
    print(logMessage); // In production, use proper logging framework
  }
}