import 'dart:math';
import '../models/user.dart';

/// Service for handling EXP calculations, leveling mechanics, and EXP reversal
/// 
/// This service provides comprehensive functionality for:
/// - Calculating EXP thresholds using exponential growth formula
/// - Managing level progression and multi-level advancement
/// - Handling EXP reversal for activity deletion
/// - Managing level-down scenarios when EXP is reversed
/// - Validating EXP operations for data integrity
/// 
/// **Key Features:**
/// 
/// **EXP Threshold Calculation:**
/// - Uses formula: 1000 * (1.2^(level-1)) for exponential growth
/// - Ensures progressively challenging level requirements
/// - Maintains consistent progression curve across all levels
/// 
/// **Level Progression:**
/// - Handles single and multiple level-ups in one operation
/// - Calculates excess EXP correctly for level advancement
/// - Prevents infinite loops with safety checks
/// 
/// **EXP Reversal System:**
/// - Reverses EXP gains when activities are deleted
/// - Handles level-down scenarios when EXP falls below thresholds
/// - Maintains minimum level of 1 and EXP of 0
/// - Provides preview functionality for UI confirmation
/// 
/// **Validation and Safety:**
/// - Comprehensive validation before EXP operations
/// - Prevents invalid states (negative EXP, level below 1)
/// - Handles edge cases and data corruption scenarios
/// 
/// Usage Examples:
/// ```dart
/// // Calculate EXP threshold for level 5
/// final threshold = EXPService.calculateEXPThreshold(5); // 2073.6
/// 
/// // Handle EXP reversal with level-down
/// final updatedUser = EXPService.handleEXPReversal(user, 500.0);
/// 
/// // Preview level-down impact
/// final preview = EXPService.calculateLevelDown(user, 1000.0);
/// if (preview.willLevelDown) {
///   debugPrint('Will level down ${preview.levelsLost} levels');
/// }
/// ```
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
  /// 
  /// **FIXED:** Corrected EXP threshold interpretation. calculateEXPThreshold(level)
  /// returns the TOTAL cumulative EXP needed to REACH that level, not the EXP
  /// needed to advance FROM that level to the next.
  /// 
  /// **Correct Logic:**
  /// - To advance from level N to level N+1, you need:
  ///   calculateEXPThreshold(N+1) - calculateEXPThreshold(N) EXP
  /// - User's current EXP is compared against the next level's total threshold
  /// - Excess EXP is calculated as: currentEXP - totalEXPNeededForNewLevel
  static LevelUpResult checkLevelUp(User user) {
    int newLevel = user.level;
    int levelsGained = 0;
    
    // Check if user can level up by comparing current EXP to next level's threshold
    while (newLevel < 1000) { // Safety limit to prevent infinite loops
      final nextLevelThreshold = calculateEXPThreshold(newLevel + 1);
      
      if (user.currentEXP >= nextLevelThreshold) {
        newLevel++;
        levelsGained++;
      } else {
        break;
      }
    }
    
    // If no level-up occurred
    if (levelsGained == 0) {
      return LevelUpResult(
        canLevelUp: false,
        newLevel: user.level,
        excessEXP: 0.0,
        levelsGained: 0,
      );
    }
    
    // Calculate excess EXP: current EXP minus the total EXP needed to reach the new level
    final totalEXPNeededForNewLevel = calculateEXPThreshold(newLevel);
    final excessEXP = user.currentEXP - totalEXPNeededForNewLevel;

    return LevelUpResult(
      canLevelUp: true,
      newLevel: newLevel,
      excessEXP: excessEXP,
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

  /// Handle EXP reversal for activity deletion with level-down support
  /// 
  /// This method reverses EXP gains when an activity is deleted, handling the complex
  /// scenario where EXP reversal might cause the user to level down. It ensures that
  /// the user's level and EXP remain in a valid state after the reversal.
  /// 
  /// **Process Flow:**
  /// 1. Subtract the EXP amount from current EXP
  /// 2. If EXP becomes negative, "borrow" from previous levels
  /// 3. Continue borrowing until EXP is non-negative or level reaches 1
  /// 4. Ensure final state has EXP >= 0 and level >= 1
  /// 
  /// **Level-Down Logic:**
  /// - When EXP goes negative, move to the previous level
  /// - Add the previous level's threshold to the negative EXP
  /// - Repeat until EXP is non-negative or minimum level is reached
  /// - Prevents level from going below 1 (minimum level)
  /// - Prevents EXP from going below 0 (minimum EXP)
  /// 
  /// **Edge Cases Handled:**
  /// - EXP reversal larger than total EXP earned
  /// - Multiple level-downs in a single operation
  /// - User already at minimum level (level 1)
  /// - Zero or negative EXP reversal amounts
  /// 
  /// **Safety Guarantees:**
  /// - User level will never go below 1
  /// - User EXP will never go below 0
  /// - Final state will always be mathematically consistent
  /// - Original user object is not modified (returns new instance)
  /// 
  /// @param user The user whose EXP should be reversed
  /// @param expToReverse The amount of EXP to remove (must be non-negative)
  /// @return New User instance with reversed EXP and adjusted level
  /// @throws ArgumentError if expToReverse is negative
  /// 
  /// Example:
  /// ```dart
  /// // User at level 3 with 500 EXP, reverse 1000 EXP
  /// final updatedUser = EXPService.handleEXPReversal(user, 1000.0);
  /// // Result: User might be at level 2 with appropriate EXP
  /// 
  /// // User at level 1 with 100 EXP, reverse 200 EXP
  /// final updatedUser = EXPService.handleEXPReversal(user, 200.0);
  /// // Result: User at level 1 with 0 EXP (minimum constraints applied)
  /// ```
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

  /// Calculate level-down impact for preview and confirmation purposes
  /// 
  /// This method performs the same calculations as handleEXPReversal but without
  /// modifying the user object. It provides detailed information about what would
  /// happen if the EXP reversal were applied, which is essential for user interface
  /// confirmation dialogs and impact assessment.
  /// 
  /// **Information Provided:**
  /// - Whether a level-down will occur
  /// - The new level after reversal
  /// - The new EXP amount after reversal
  /// - The total number of levels that would be lost
  /// 
  /// **Use Cases:**
  /// - Confirmation dialogs before activity deletion
  /// - UI validation and user feedback
  /// - Batch operation planning and impact assessment
  /// - Debugging and troubleshooting EXP calculations
  /// 
  /// **Calculation Accuracy:**
  /// - Uses identical logic to handleEXPReversal for accuracy
  /// - Handles all the same edge cases and constraints
  /// - Provides exact preview of what the actual operation would do
  /// - No side effects - original user object is not modified
  /// 
  /// **Edge Cases Handled:**
  /// - Zero EXP reversal (no change)
  /// - EXP reversal larger than total EXP earned
  /// - User already at minimum level
  /// - Multiple level-downs in a single operation
  /// 
  /// @param user The user to calculate level-down impact for
  /// @param expToReverse The amount of EXP that would be removed
  /// @return LevelDownResult with detailed impact information
  /// @throws ArgumentError if expToReverse is negative
  /// 
  /// Example:
  /// ```dart
  /// final preview = EXPService.calculateLevelDown(user, 1500.0);
  /// if (preview.willLevelDown) {
  ///   showConfirmation(
  ///     'This will cause you to level down ${preview.levelsLost} levels '
  ///     'from ${user.level} to ${preview.newLevel}. Continue?'
  ///   );
  /// }
  /// ```
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
        return false;
      }

      if (expToReverse.isNaN || expToReverse.isInfinite) {
        return false;
      }

      // Validate user data
      if (user.currentEXP.isNaN || user.currentEXP.isInfinite) {
        return false;
      }

      if (user.level < 1) {
        return false;
      }

      // Calculate what would happen after reversal
      final levelDownResult = calculateLevelDown(user, expToReverse);
      
      // Validate the calculated result
      if (levelDownResult.newLevel < 1) {
        return false;
      }

      if (levelDownResult.newEXP.isNaN || levelDownResult.newEXP.isInfinite) {
        return false;
      }

      return true; // EXP reversal is valid
    } catch (e) {
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
}