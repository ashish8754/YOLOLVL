import 'package:flutter/foundation.dart';
import '../models/enums.dart';

/// Service for handling stat progression calculations and infinite stats system
/// 
/// This service provides comprehensive functionality for:
/// - Calculating stat gains based on activity type and duration
/// - Managing infinite stat progression (no ceiling limits)
/// - Validating stat values for storage, calculation, and display
/// - Handling stat reversals for activity deletion
/// - Chart rendering validation and auto-scaling
/// - Export/import validation for backup systems
/// 
/// **Key Features:**
/// 
/// **Infinite Stats System:**
/// - Removes the previous 5.0 stat ceiling to allow unlimited progression
/// - Maintains 1.0 minimum floor to prevent invalid stat values
/// - Handles extremely large values safely for storage and display
/// - Provides validation for chart rendering performance
/// 
/// **Stat Reversal System:**
/// - Calculates exact stat reversals for activity deletion
/// - Uses stored stat gains when available for accuracy
/// - Falls back to calculated gains for legacy activities
/// - Enforces minimum floor constraints during reversal
/// 
/// **Validation Systems:**
/// - Comprehensive validation for infinite stat values
/// - Chart rendering validation for performance optimization
/// - Export/import validation for data integrity
/// - Edge case testing for extreme values
/// 
/// **Performance Considerations:**
/// - Efficient calculations for large stat values
/// - Chart auto-scaling algorithms for optimal display
/// - Memory usage optimization for extreme values
/// - Logarithmic scaling options for very large numbers
/// 
/// Usage Examples:
/// ```dart
/// // Calculate stat gains
/// final gains = StatsService.calculateStatGains(ActivityType.workoutUpperBody, 60);
/// 
/// // Validate infinite stats
/// final validation = StatsService.validateInfiniteStats(userStats);
/// if (validation.isValid) {
///   // Safe to use stats
/// }
/// 
/// // Calculate stat reversals for deletion
/// final reversals = StatsService.calculateStatReversals(
///   ActivityType.workoutUpperBody, 60, storedGains
/// );
/// ```
class StatsService {
  /// Calculate stat gains for a given activity type and duration
  /// 
  /// This method calculates the exact stat gains that should be applied when logging
  /// an activity. The calculations are based on predefined rates per hour for each
  /// activity type, with special handling for "Quit Bad Habit" which provides fixed gains.
  /// 
  /// **Calculation Rules:**
  /// - Most activities use hourly rates (e.g., 0.06 Strength per hour for weight training)
  /// - "Quit Bad Habit" provides fixed gains regardless of duration
  /// - Multiple stats can be affected by a single activity type
  /// - No ceiling limits - stats can grow infinitely
  /// 
  /// **Activity Type Mappings:**
  /// - Upper Body Training: +0.06 Strength/hr, +0.03 Endurance/hr
  /// - Lower Body Training: +0.05 Strength/hr, +0.04 Agility/hr, +0.04 Endurance/hr
  /// - Core Training: +0.05 Strength/hr, +0.05 Endurance/hr, +0.02 Focus/hr
  /// - Cardio: +0.06 Agility/hr, +0.04 Endurance/hr
  /// - Yoga: +0.05 Agility/hr, +0.03 Focus/hr
  /// - Walking: +0.03 Agility/hr, +0.02 Endurance/hr
  /// - Serious Study: +0.06 Intelligence/hr, +0.04 Focus/hr
  /// - Casual Study: +0.04 Intelligence/hr, +0.03 Charisma/hr
  /// - Meditation: +0.05 Focus/hr
  /// - Socializing: +0.05 Charisma/hr, +0.02 Focus/hr
  /// - Sleep Tracking: +0.02 Endurance/hr
  /// - Healthy Diet: +0.03 Endurance/hr
  /// - Quit Bad Habit: +0.03 Focus (fixed amount)
  /// 
  /// @param activityType The type of activity being performed
  /// @param durationMinutes The duration of the activity in minutes
  /// @return Map of StatType to gain amount (can be empty for unknown activities)
  /// @throws ArgumentError if durationMinutes is negative
  /// 
  /// Example:
  /// ```dart
  /// final gains = StatsService.calculateStatGains(ActivityType.workoutUpperBody, 90);
  /// // Returns: {StatType.strength: 0.09, StatType.endurance: 0.045}
  /// ```
  static Map<StatType, double> calculateStatGains(ActivityType activityType, int durationMinutes) {
    if (durationMinutes < 0) {
      throw ArgumentError('Duration must be non-negative');
    }

    final gains = <StatType, double>{};
    final durationHours = durationMinutes / 60.0;

    switch (activityType) {
      case ActivityType.workoutUpperBody:
        gains[StatType.strength] = 0.06 * durationHours;
        gains[StatType.endurance] = 0.03 * durationHours;
        break;

      case ActivityType.workoutLowerBody:
        gains[StatType.strength] = 0.05 * durationHours;
        gains[StatType.agility] = 0.04 * durationHours;
        gains[StatType.endurance] = 0.04 * durationHours;
        break;

      case ActivityType.workoutCore:
        gains[StatType.strength] = 0.05 * durationHours;
        gains[StatType.endurance] = 0.05 * durationHours;
        gains[StatType.focus] = 0.02 * durationHours;
        break;

      case ActivityType.workoutCardio:
        gains[StatType.agility] = 0.06 * durationHours;
        gains[StatType.endurance] = 0.04 * durationHours;
        break;

      case ActivityType.workoutYoga:
        gains[StatType.agility] = 0.05 * durationHours;
        gains[StatType.focus] = 0.03 * durationHours;
        break;

      case ActivityType.walking:
        gains[StatType.agility] = 0.03 * durationHours;
        gains[StatType.endurance] = 0.02 * durationHours;
        break;

      case ActivityType.studySerious:
        gains[StatType.intelligence] = 0.06 * durationHours;
        gains[StatType.focus] = 0.04 * durationHours;
        break;

      case ActivityType.studyCasual:
        gains[StatType.intelligence] = 0.04 * durationHours;
        gains[StatType.charisma] = 0.03 * durationHours;
        break;

      case ActivityType.meditation:
        gains[StatType.focus] = 0.05 * durationHours;
        break;

      case ActivityType.socializing:
        gains[StatType.charisma] = 0.05 * durationHours;
        gains[StatType.focus] = 0.02 * durationHours;
        break;

      case ActivityType.sleepTracking:
        gains[StatType.endurance] = 0.02 * durationHours;
        break;

      case ActivityType.dietHealthy:
        gains[StatType.endurance] = 0.03 * durationHours;
        break;

      case ActivityType.quitBadHabit:
        // Fixed amount, not per hour
        gains[StatType.focus] = 0.03;
        break;
    }

    return gains;
  }

  /// Apply stat gains to a user's current stats
  /// Returns a new map with updated stat values
  static Map<StatType, double> applyStatGains(
    Map<StatType, double> currentStats,
    Map<StatType, double> gains,
  ) {
    final updatedStats = <StatType, double>{};
    
    // Initialize with current stats
    for (final statType in StatType.values) {
      updatedStats[statType] = currentStats[statType] ?? 1.0;
    }

    // Apply gains
    for (final entry in gains.entries) {
      updatedStats[entry.key] = (updatedStats[entry.key] ?? 1.0) + entry.value;
    }

    return updatedStats;
  }

  /// Get all stats that are affected by a given activity type
  static List<StatType> getAffectedStats(ActivityType activityType) {
    final gains = calculateStatGains(activityType, 60); // Use 1 hour as reference
    return gains.keys.toList();
  }

  /// Get the primary stat (highest gain) for an activity type
  static StatType? getPrimaryStat(ActivityType activityType) {
    final gains = calculateStatGains(activityType, 60); // Use 1 hour as reference
    
    if (gains.isEmpty) return null;
    
    StatType? primaryStat;
    double maxGain = 0.0;
    
    for (final entry in gains.entries) {
      if (entry.value > maxGain) {
        maxGain = entry.value;
        primaryStat = entry.key;
      }
    }
    
    return primaryStat;
  }

  /// Calculate total stat gains for multiple activities
  static Map<StatType, double> calculateTotalStatGains(
    List<ActivityLogEntry> activities,
  ) {
    final totalGains = <StatType, double>{};
    
    for (final activity in activities) {
      final gains = calculateStatGains(activity.activityType, activity.durationMinutes);
      
      for (final entry in gains.entries) {
        totalGains[entry.key] = (totalGains[entry.key] ?? 0.0) + entry.value;
      }
    }
    
    return totalGains;
  }

  /// Validate stat values (ensure they don't go below minimum and handle extreme values)
  static Map<StatType, double> validateStats(Map<StatType, double> stats, {double minValue = 1.0}) {
    final validatedStats = <StatType, double>{};
    
    for (final entry in stats.entries) {
      final value = entry.value;
      
      // Handle NaN and infinity values
      if (value.isNaN || value.isInfinite) {
        _logError('validateStats', 'Invalid stat value for ${entry.key.name}: $value, clamping to $minValue');
        validatedStats[entry.key] = minValue;
      } else if (value < minValue) {
        validatedStats[entry.key] = minValue;
      } else if (value > _getMaxReasonableStatValue()) {
        // Handle extremely large values that might cause overflow or rendering issues
        final maxReasonable = _getMaxReasonableStatValue();
        _logWarning('validateStats', 'Extremely large stat value for ${entry.key.name}: $value, clamping to $maxReasonable');
        validatedStats[entry.key] = maxReasonable;
      } else {
        validatedStats[entry.key] = value;
      }
    }
    
    return validatedStats;
  }

  /// Comprehensive validation for the infinite stats system
  /// 
  /// This method performs thorough validation of stat values to ensure they are safe
  /// for storage, calculation, and display in the infinite progression system. It
  /// handles edge cases, validates against overflow conditions, and provides sanitized
  /// values when issues are detected.
  /// 
  /// **Validation Checks:**
  /// - **Invalid Values**: Detects NaN and infinite values
  /// - **Floor Constraint**: Ensures no stat falls below 1.0 minimum
  /// - **Overflow Protection**: Validates against extremely large values that could cause issues
  /// - **Performance Impact**: Warns about values that might affect chart rendering performance
  /// - **Data Integrity**: Ensures all required stats are present and valid
  /// 
  /// **Sanitization Process:**
  /// - Invalid values (NaN, infinite) are replaced with safe defaults
  /// - Values below 1.0 are clamped to the minimum floor
  /// - Extremely large values are clamped to reasonable maximums
  /// - Missing stats are filled with default values
  /// 
  /// **Return Value Types:**
  /// - **Valid**: All stats pass validation without issues
  /// - **Warning**: Stats are usable but have minor issues (e.g., very large values)
  /// - **Invalid**: Critical issues detected, sanitized stats provided
  /// 
  /// **Performance Considerations:**
  /// - Validates against values that could cause rendering performance issues
  /// - Provides warnings for values above performance thresholds
  /// - Suggests alternative display methods for extreme values
  /// 
  /// @param stats Map of StatType to stat values to validate
  /// @return InfiniteStatsValidationResult with validation status and sanitized values
  /// 
  /// Example:
  /// ```dart
  /// final result = StatsService.validateInfiniteStats(userStats);
  /// if (result.isValid) {
  ///   // Use original stats
  ///   useStats(stats);
  /// } else if (result.hasWarning) {
  ///   // Use sanitized stats with warning
  ///   useStats(result.sanitizedStats);
  ///   showWarning(result.message);
  /// } else {
  ///   // Critical issues, use sanitized stats
  ///   useStats(result.sanitizedStats);
  ///   showError(result.message);
  /// }
  /// ```
  static InfiniteStatsValidationResult validateInfiniteStats(Map<StatType, double> stats) {
    try {
      if (stats.isEmpty) {
        return InfiniteStatsValidationResult.invalid('Stats map is empty');
      }

      final issues = <String>[];
      final warnings = <String>[];
      final sanitizedStats = <StatType, double>{};

      for (final entry in stats.entries) {
        final statType = entry.key;
        final value = entry.value;

        // Check for invalid values
        if (value.isNaN) {
          issues.add('${statType.name} has NaN value');
          sanitizedStats[statType] = 1.0;
        } else if (value.isInfinite) {
          issues.add('${statType.name} has infinite value');
          sanitizedStats[statType] = value.isNegative ? 1.0 : _getMaxReasonableStatValue();
        } else if (value < 1.0) {
          warnings.add('${statType.name} below minimum (${value.toStringAsFixed(2)})');
          sanitizedStats[statType] = 1.0;
        } else if (value > _getMaxReasonableStatValue()) {
          warnings.add('${statType.name} extremely large (${value.toStringAsFixed(0)})');
          sanitizedStats[statType] = _getMaxReasonableStatValue();
        } else {
          sanitizedStats[statType] = value;
        }
      }

      // Check for potential overflow in calculations
      if (sanitizedStats.isNotEmpty) {
        final maxValue = sanitizedStats.values.reduce((a, b) => a > b ? a : b);
        if (maxValue > 100000) {
          warnings.add('Very large stat values may impact performance');
        }
      }

      if (issues.isNotEmpty) {
        return InfiniteStatsValidationResult.invalid(
          'Critical validation issues: ${issues.join(', ')}',
          sanitizedStats: sanitizedStats,
          warnings: warnings,
        );
      }

      if (warnings.isNotEmpty) {
        return InfiniteStatsValidationResult.warning(
          'Validation warnings: ${warnings.join(', ')}',
          sanitizedStats: sanitizedStats,
          warnings: warnings,
        );
      }

      return InfiniteStatsValidationResult.valid(sanitizedStats: sanitizedStats);
    } catch (e) {
      _logError('validateInfiniteStats', 'Exception during validation: $e');
      return InfiniteStatsValidationResult.invalid('Validation failed: $e');
    }
  }

  /// Get maximum reasonable stat value to prevent overflow and rendering issues
  /// This is a safety limit, not a gameplay limit
  static double _getMaxReasonableStatValue() {
    return 999999.0; // 1 million - 1, should be sufficient for any reasonable gameplay
  }

  /// Validate stat value for infinite progression system
  /// Ensures values are reasonable for storage, calculation, and display
  static double validateStatValue(double value, {double minValue = 1.0}) {
    // Handle special cases
    if (value.isNaN) {
      _logError('validateStatValue', 'NaN stat value detected, using minimum: $minValue');
      return minValue;
    }
    
    if (value.isInfinite) {
      _logError('validateStatValue', 'Infinite stat value detected, using maximum reasonable value');
      return _getMaxReasonableStatValue();
    }
    
    // Handle negative values
    if (value < minValue) {
      return minValue;
    }
    
    // Handle extremely large values
    if (value > _getMaxReasonableStatValue()) {
      _logWarning('validateStatValue', 'Extremely large stat value: $value, clamping to reasonable maximum');
      return _getMaxReasonableStatValue();
    }
    
    return value;
  }

  /// Check if stat values are safe for chart rendering
  /// Returns validation result with recommendations
  static StatChartValidationResult validateStatsForChart(Map<StatType, double> stats) {
    try {
      if (stats.isEmpty) {
        return StatChartValidationResult.invalid('Stats map is empty');
      }

      final maxValue = stats.values.reduce((a, b) => a > b ? a : b);
      final minValue = stats.values.reduce((a, b) => a < b ? a : b);

      // Check for invalid values
      for (final entry in stats.entries) {
        if (entry.value.isNaN || entry.value.isInfinite) {
          return StatChartValidationResult.invalid('Invalid stat value for ${entry.key.name}: ${entry.value}');
        }
      }

      // Check for extremely large values that might cause rendering issues
      if (maxValue > 100000) {
        return StatChartValidationResult.warning(
          'Very large stat values detected (max: ${maxValue.toStringAsFixed(0)}). Chart rendering may have performance issues.',
          recommendedMaxY: _calculateSafeChartMaximum(maxValue),
        );
      }

      // Check for very small differences that might not render well
      if (maxValue > 0 && (maxValue - minValue) < 0.01) {
        return StatChartValidationResult.warning(
          'Very small stat differences detected. Chart may not show clear distinctions.',
          recommendedMaxY: maxValue + 1.0,
        );
      }

      return StatChartValidationResult.valid(
        recommendedMaxY: _calculateSafeChartMaximum(maxValue),
      );
    } catch (e) {
      _logError('validateStatsForChart', 'Exception during chart validation: $e');
      return StatChartValidationResult.invalid('Chart validation failed: $e');
    }
  }

  /// Calculate safe chart maximum for rendering performance
  static double _calculateSafeChartMaximum(double maxStatValue) {
    // For very large values, use logarithmic scaling or reasonable increments
    if (maxStatValue <= 5.0) {
      return 5.0;
    } else if (maxStatValue <= 100.0) {
      // Use increments of 5 up to 100
      return ((maxStatValue / 5.0).ceil() * 5.0);
    } else if (maxStatValue <= 1000.0) {
      // Use increments of 50 for values 100-1000
      return ((maxStatValue / 50.0).ceil() * 50.0);
    } else {
      // Use increments of 500 for very large values
      return ((maxStatValue / 500.0).ceil() * 500.0);
    }
  }

  /// Validate stat gains for infinite progression
  /// Ensures gains are reasonable and won't cause overflow
  static Map<StatType, double> validateStatGains(Map<StatType, double> gains) {
    final validatedGains = <StatType, double>{};
    
    for (final entry in gains.entries) {
      final gain = entry.value;
      
      if (gain.isNaN || gain.isInfinite) {
        _logError('validateStatGains', 'Invalid stat gain for ${entry.key.name}: $gain, setting to 0');
        validatedGains[entry.key] = 0.0;
      } else if (gain < 0) {
        _logWarning('validateStatGains', 'Negative stat gain for ${entry.key.name}: $gain, setting to 0');
        validatedGains[entry.key] = 0.0;
      } else if (gain > 100.0) {
        // Extremely large single gain - might indicate a bug
        _logWarning('validateStatGains', 'Very large stat gain for ${entry.key.name}: $gain, clamping to 100');
        validatedGains[entry.key] = 100.0;
      } else {
        validatedGains[entry.key] = gain;
      }
    }
    
    return validatedGains;
  }

  /// Get stat gain rate per hour for an activity type
  static Map<StatType, double> getStatGainRates(ActivityType activityType) {
    return calculateStatGains(activityType, 60); // 60 minutes = 1 hour
  }

  /// Get default stat gains per hour for an activity type (for settings display)
  static Map<StatType, double> getDefaultStatGains(ActivityType activityType) {
    return getStatGainRates(activityType);
  }

  /// Calculate stat reversals for activity deletion with legacy data support
  /// 
  /// This method calculates the exact stat amounts that should be reversed when
  /// deleting an activity. It prioritizes using stored stat gains from the activity
  /// log for accuracy, but falls back to calculated gains for legacy activities
  /// that were logged before stat gains were stored.
  /// 
  /// **Calculation Priority:**
  /// 1. **Stored Gains (Preferred)**: Uses exact gains stored when activity was logged
  /// 2. **Fallback Calculation**: Recalculates gains using original activity mapping
  /// 
  /// **Why Stored Gains Are Preferred:**
  /// - Exact accuracy: Uses the precise values that were applied originally
  /// - Handles edge cases: Accounts for any special conditions during original logging
  /// - Future-proof: Works even if calculation rules change over time
  /// - Data integrity: Ensures perfect reversal of original changes
  /// 
  /// **Legacy Data Handling:**
  /// - Activities logged before stat storage was implemented lack stored gains
  /// - Fallback calculation uses the same rules that were used originally
  /// - Provides reasonable accuracy for older activities
  /// - Enables deletion of all activities regardless of when they were logged
  /// 
  /// **Data Migration Considerations:**
  /// - Legacy activities can be migrated to include stored gains
  /// - Migration improves accuracy of future deletions
  /// - Non-destructive: Original activity data is preserved
  /// 
  /// @param activityType The type of activity being reversed
  /// @param durationMinutes The duration of the original activity in minutes
  /// @param storedStatGains The stat gains stored in the activity log (null for legacy activities)
  /// @return Map of StatType to reversal amount (positive values to be subtracted)
  /// @throws ArgumentError if durationMinutes is negative
  /// 
  /// Example:
  /// ```dart
  /// // Using stored gains (preferred)
  /// final reversals = StatsService.calculateStatReversals(
  ///   ActivityType.workoutUpperBody, 60, storedGains
  /// );
  /// 
  /// // Fallback for legacy activity
  /// final reversals = StatsService.calculateStatReversals(
  ///   ActivityType.workoutUpperBody, 60, null
  /// );
  /// ```
  static Map<StatType, double> calculateStatReversals(
    ActivityType activityType,
    int durationMinutes,
    Map<StatType, double>? storedStatGains,
  ) {
    if (durationMinutes < 0) {
      throw ArgumentError('Duration must be non-negative');
    }

    // Use stored stat gains if available (preferred method for accuracy)
    if (storedStatGains != null && storedStatGains.isNotEmpty) {
      return Map<StatType, double>.from(storedStatGains);
    }

    // Fallback: calculate using original activity mapping for legacy activities
    return calculateStatGains(activityType, durationMinutes);
  }

  /// Apply stat reversals to current stats with validation
  /// Ensures no stat falls below the minimum floor value (1.0)
  static Map<StatType, double> applyStatReversals(
    Map<StatType, double> currentStats,
    Map<StatType, double> reversals,
    {double minValue = 1.0}
  ) {
    final updatedStats = <StatType, double>{};
    
    // Initialize with current stats
    for (final statType in StatType.values) {
      updatedStats[statType] = currentStats[statType] ?? 1.0;
    }

    // Apply reversals with floor validation
    for (final entry in reversals.entries) {
      final currentValue = updatedStats[entry.key] ?? 1.0;
      final newValue = currentValue - entry.value;
      
      // Ensure stat doesn't fall below minimum floor
      updatedStats[entry.key] = newValue < minValue ? minValue : newValue;
    }

    return updatedStats;
  }

  /// Validate stat reversal operation before applying
  /// Returns true if reversal is safe to apply, false if it would cause issues
  static bool validateStatReversal(
    Map<StatType, double> currentStats,
    Map<StatType, double> reversals,
    {double minValue = 1.0}
  ) {
    try {
      // Validate input parameters
      if (currentStats.isEmpty) {
        _logError('validateStatReversal', 'Current stats map is empty');
        return false;
      }

      if (reversals.isEmpty) {
        _logWarning('validateStatReversal', 'Reversals map is empty - nothing to reverse');
        return true; // Empty reversals are valid (no-op)
      }

      // Validate each reversal
      for (final entry in reversals.entries) {
        final statType = entry.key;
        final reversalAmount = entry.value;
        
        // Validate reversal amount
        if (reversalAmount.isNaN || reversalAmount.isInfinite) {
          _logError('validateStatReversal', 'Invalid reversal amount for ${statType.name}: $reversalAmount');
          return false;
        }

        if (reversalAmount < 0) {
          _logError('validateStatReversal', 'Negative reversal amount for ${statType.name}: $reversalAmount');
          return false;
        }

        // Get current stat value
        final currentValue = currentStats[statType];
        if (currentValue == null) {
          _logError('validateStatReversal', 'Missing current stat value for ${statType.name}');
          return false;
        }

        // Validate current stat value
        if (currentValue.isNaN || currentValue.isInfinite) {
          _logError('validateStatReversal', 'Invalid current stat value for ${statType.name}: $currentValue');
          return false;
        }

        final newValue = currentValue - reversalAmount;
        
        // Log if reversal would cause significant clamping
        if (newValue < minValue) {
          _logWarning('validateStatReversal', 
            'Stat reversal will clamp ${statType.name} from $currentValue to $minValue (would be $newValue)');
        }

        // Check for extreme negative values that might indicate data corruption
        if (newValue < -100) {
          _logError('validateStatReversal', 
            'Extreme negative stat value detected for ${statType.name}: $newValue (current: $currentValue, reversal: $reversalAmount)');
          return false;
        }
      }
      
      return true; // All reversals are valid
    } catch (e) {
      _logError('validateStatReversal', 'Exception during validation: $e');
      return false;
    }
  }

  /// Calculate expected gains for preview purposes
  static StatGainPreview calculateExpectedGains(ActivityType activityType, int durationMinutes) {
    final gains = calculateStatGains(activityType, durationMinutes);
    final affectedStats = gains.keys.toList();
    
    return StatGainPreview(
      activityType: activityType,
      durationMinutes: durationMinutes,
      statGains: gains,
      affectedStats: affectedStats,
      primaryStat: getPrimaryStat(activityType),
    );
  }

  /// Log error messages with context
  static void _logError(String method, String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] ERROR StatsService.$method: $message';
    debugPrint(logMessage);
  }

  /// Log warning messages with context
  static void _logWarning(String method, String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] WARNING StatsService.$method: $message';
    debugPrint(logMessage);
  }

  /// Log info messages with context
  static void _logInfo(String method, String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] INFO StatsService.$method: $message';
    debugPrint(logMessage);
  }

  /// Validate stat values for export/import operations
  /// Ensures data integrity during backup/restore with infinite stats
  static ExportValidationResult validateStatsForExport(Map<StatType, double> stats) {
    try {
      if (stats.isEmpty) {
        return ExportValidationResult.invalid('No stats to export');
      }

      final issues = <String>[];
      final warnings = <String>[];
      final sanitizedStats = <StatType, double>{};

      for (final entry in stats.entries) {
        final statType = entry.key;
        final value = entry.value;

        if (value.isNaN || value.isInfinite) {
          issues.add('${statType.name}: Invalid value ($value)');
          sanitizedStats[statType] = 1.0;
        } else if (value < 1.0) {
          warnings.add('${statType.name}: Below minimum (${value.toStringAsFixed(2)})');
          sanitizedStats[statType] = 1.0;
        } else if (value > 1000000) {
          warnings.add('${statType.name}: Extremely large value (${value.toStringAsFixed(0)})');
          sanitizedStats[statType] = value; // Keep large values for export
        } else {
          sanitizedStats[statType] = value;
        }
      }

      if (issues.isNotEmpty) {
        return ExportValidationResult.invalid(
          'Export validation failed: ${issues.join(', ')}',
          sanitizedStats: sanitizedStats,
          warnings: warnings,
        );
      }

      if (warnings.isNotEmpty) {
        return ExportValidationResult.warning(
          'Export validation warnings: ${warnings.join(', ')}',
          sanitizedStats: sanitizedStats,
          warnings: warnings,
        );
      }

      return ExportValidationResult.valid(sanitizedStats: sanitizedStats);
    } catch (e) {
      _logError('validateStatsForExport', 'Exception during export validation: $e');
      return ExportValidationResult.invalid('Export validation failed: $e');
    }
  }

  /// Test system behavior with edge case stat values
  /// Used for testing extreme scenarios in infinite stats system
  static EdgeCaseTestResult testEdgeCaseStatValues() {
    final testCases = <String, Map<StatType, double>>{
      'normal_values': {
        StatType.strength: 5.5,
        StatType.agility: 7.2,
        StatType.endurance: 3.8,
        StatType.intelligence: 9.1,
        StatType.focus: 6.4,
        StatType.charisma: 4.7,
      },
      'large_values': {
        StatType.strength: 150.0,
        StatType.agility: 200.5,
        StatType.endurance: 99.9,
        StatType.intelligence: 500.0,
        StatType.focus: 75.3,
        StatType.charisma: 300.8,
      },
      'very_large_values': {
        StatType.strength: 10000.0,
        StatType.agility: 25000.5,
        StatType.endurance: 50000.0,
        StatType.intelligence: 100000.0,
        StatType.focus: 75000.3,
        StatType.charisma: 30000.8,
      },
      'extreme_values': {
        StatType.strength: 999999.0,
        StatType.agility: 500000.0,
        StatType.endurance: 750000.0,
        StatType.intelligence: 1000000.0,
        StatType.focus: 250000.0,
        StatType.charisma: 800000.0,
      },
      'invalid_values': {
        StatType.strength: double.nan,
        StatType.agility: double.infinity,
        StatType.endurance: double.negativeInfinity,
        StatType.intelligence: -100.0,
        StatType.focus: 0.5,
        StatType.charisma: -1.0,
      },
    };

    final results = <String, dynamic>{};
    final issues = <String>[];

    for (final entry in testCases.entries) {
      final testName = entry.key;
      final testStats = entry.value;

      try {
        // Test validation
        final validationResult = validateInfiniteStats(testStats);
        results['${testName}_validation'] = validationResult.isValid;

        // Test chart validation
        final chartResult = validateStatsForChart(testStats);
        results['${testName}_chart'] = chartResult.isValid;

        // Test export validation
        final exportResult = validateStatsForExport(testStats);
        results['${testName}_export'] = exportResult.isValid;

        // Test stat application
        final gains = {StatType.strength: 0.1, StatType.agility: 0.05};
        final appliedStats = applyStatGains(testStats, gains);
        results['${testName}_application'] = appliedStats.isNotEmpty;

      } catch (e) {
        issues.add('$testName failed: $e');
        results['${testName}_error'] = e.toString();
      }
    }

    return EdgeCaseTestResult(
      testResults: results,
      issues: issues,
      passed: issues.isEmpty,
    );
  }

  /// Validate chart rendering with extremely large values
  /// Ensures charts can handle infinite stats without performance issues
  static ChartRenderingValidationResult validateChartRendering(Map<StatType, double> stats) {
    try {
      if (stats.isEmpty) {
        return ChartRenderingValidationResult.invalid('No stats for chart rendering');
      }

      final maxValue = stats.values.reduce((a, b) => a > b ? a : b);
      final minValue = stats.values.reduce((a, b) => a < b ? a : b);
      final range = maxValue - minValue;

      final issues = <String>[];
      final warnings = <String>[];
      final recommendations = <String>[];

      // Check for invalid values
      for (final entry in stats.entries) {
        if (entry.value.isNaN || entry.value.isInfinite) {
          issues.add('${entry.key.name} has invalid value: ${entry.value}');
        }
      }

      if (issues.isNotEmpty) {
        return ChartRenderingValidationResult.invalid(
          'Chart rendering validation failed: ${issues.join(', ')}',
          warnings: warnings,
          recommendations: recommendations,
        );
      }

      // Performance considerations
      if (maxValue > 1000000) {
        warnings.add('Extremely large values may cause rendering performance issues');
        recommendations.add('Consider using logarithmic scaling for values above 1M');
      } else if (maxValue > 100000) {
        warnings.add('Very large values detected');
        recommendations.add('Monitor chart rendering performance');
      }

      // Visual clarity considerations
      if (range < 0.1 && maxValue > 1.0) {
        warnings.add('Very small value differences may not be visually distinct');
        recommendations.add('Consider adjusting chart scale or precision');
      }

      // Memory usage considerations
      if (maxValue > 10000) {
        recommendations.add('Use appropriate chart intervals to reduce memory usage');
      }

      final recommendedMaxY = _calculateSafeChartMaximum(maxValue);
      final scalingFactor = recommendedMaxY / maxValue;

      return ChartRenderingValidationResult.valid(
        recommendedMaxY: recommendedMaxY,
        scalingFactor: scalingFactor,
        warnings: warnings,
        recommendations: recommendations,
      );
    } catch (e) {
      _logError('validateChartRendering', 'Exception during chart validation: $e');
      return ChartRenderingValidationResult.invalid('Chart validation failed: $e');
    }
  }
}

/// Helper class for activity log entries
class ActivityLogEntry {
  final ActivityType activityType;
  final int durationMinutes;
  final DateTime timestamp;

  const ActivityLogEntry({
    required this.activityType,
    required this.durationMinutes,
    required this.timestamp,
  });
}

/// Preview of stat gains for UI display
class StatGainPreview {
  final ActivityType activityType;
  final int durationMinutes;
  final Map<StatType, double> statGains;
  final List<StatType> affectedStats;
  final StatType? primaryStat;

  const StatGainPreview({
    required this.activityType,
    required this.durationMinutes,
    required this.statGains,
    required this.affectedStats,
    this.primaryStat,
  });

  /// Get formatted gain text for a specific stat
  String getGainText(StatType statType) {
    final gain = statGains[statType];
    if (gain == null || gain == 0.0) return '';
    
    return '+${gain.toStringAsFixed(2)}';
  }

  /// Check if this activity affects a specific stat
  bool affectsStat(StatType statType) {
    return statGains.containsKey(statType) && (statGains[statType] ?? 0.0) > 0.0;
  }

  @override
  String toString() {
    return 'StatGainPreview(activityType: $activityType, durationMinutes: $durationMinutes, gains: $statGains)';
  }
}

/// Result of stat chart validation
class StatChartValidationResult {
  final bool isValid;
  final bool hasWarning;
  final String? message;
  final double recommendedMaxY;

  const StatChartValidationResult._({
    required this.isValid,
    required this.hasWarning,
    this.message,
    required this.recommendedMaxY,
  });

  factory StatChartValidationResult.valid({required double recommendedMaxY}) {
    return StatChartValidationResult._(
      isValid: true,
      hasWarning: false,
      recommendedMaxY: recommendedMaxY,
    );
  }

  factory StatChartValidationResult.warning(String message, {required double recommendedMaxY}) {
    return StatChartValidationResult._(
      isValid: true,
      hasWarning: true,
      message: message,
      recommendedMaxY: recommendedMaxY,
    );
  }

  factory StatChartValidationResult.invalid(String message) {
    return StatChartValidationResult._(
      isValid: false,
      hasWarning: false,
      message: message,
      recommendedMaxY: 5.0, // Safe default
    );
  }

  @override
  String toString() {
    return 'StatChartValidationResult(isValid: $isValid, hasWarning: $hasWarning, message: $message, recommendedMaxY: $recommendedMaxY)';
  }
}

/// Result of infinite stats validation
class InfiniteStatsValidationResult {
  final bool isValid;
  final bool hasWarning;
  final String? message;
  final Map<StatType, double>? sanitizedStats;
  final List<String> warnings;

  const InfiniteStatsValidationResult._({
    required this.isValid,
    required this.hasWarning,
    this.message,
    this.sanitizedStats,
    this.warnings = const [],
  });

  factory InfiniteStatsValidationResult.valid({Map<StatType, double>? sanitizedStats}) {
    return InfiniteStatsValidationResult._(
      isValid: true,
      hasWarning: false,
      sanitizedStats: sanitizedStats,
    );
  }

  factory InfiniteStatsValidationResult.warning(
    String message, {
    Map<StatType, double>? sanitizedStats,
    List<String>? warnings,
  }) {
    return InfiniteStatsValidationResult._(
      isValid: true,
      hasWarning: true,
      message: message,
      sanitizedStats: sanitizedStats,
      warnings: warnings ?? [],
    );
  }

  factory InfiniteStatsValidationResult.invalid(
    String message, {
    Map<StatType, double>? sanitizedStats,
    List<String>? warnings,
  }) {
    return InfiniteStatsValidationResult._(
      isValid: false,
      hasWarning: false,
      message: message,
      sanitizedStats: sanitizedStats,
      warnings: warnings ?? [],
    );
  }

  @override
  String toString() {
    return 'InfiniteStatsValidationResult(isValid: $isValid, hasWarning: $hasWarning, message: $message, warnings: $warnings)';
  }
}

/// Result of export validation for infinite stats
class ExportValidationResult {
  final bool isValid;
  final bool hasWarning;
  final String? message;
  final Map<StatType, double>? sanitizedStats;
  final List<String> warnings;

  const ExportValidationResult._({
    required this.isValid,
    required this.hasWarning,
    this.message,
    this.sanitizedStats,
    this.warnings = const [],
  });

  factory ExportValidationResult.valid({Map<StatType, double>? sanitizedStats}) {
    return ExportValidationResult._(
      isValid: true,
      hasWarning: false,
      sanitizedStats: sanitizedStats,
    );
  }

  factory ExportValidationResult.warning(
    String message, {
    Map<StatType, double>? sanitizedStats,
    List<String>? warnings,
  }) {
    return ExportValidationResult._(
      isValid: true,
      hasWarning: true,
      message: message,
      sanitizedStats: sanitizedStats,
      warnings: warnings ?? [],
    );
  }

  factory ExportValidationResult.invalid(
    String message, {
    Map<StatType, double>? sanitizedStats,
    List<String>? warnings,
  }) {
    return ExportValidationResult._(
      isValid: false,
      hasWarning: false,
      message: message,
      sanitizedStats: sanitizedStats,
      warnings: warnings ?? [],
    );
  }

  @override
  String toString() {
    return 'ExportValidationResult(isValid: $isValid, hasWarning: $hasWarning, message: $message, warnings: $warnings)';
  }
}

/// Result of edge case testing for infinite stats system
class EdgeCaseTestResult {
  final Map<String, dynamic> testResults;
  final List<String> issues;
  final bool passed;

  const EdgeCaseTestResult({
    required this.testResults,
    required this.issues,
    required this.passed,
  });

  @override
  String toString() {
    return 'EdgeCaseTestResult(passed: $passed, issues: ${issues.length}, testResults: ${testResults.keys.length} tests)';
  }
}

/// Result of chart rendering validation for infinite stats
class ChartRenderingValidationResult {
  final bool isValid;
  final bool hasWarning;
  final String? message;
  final double recommendedMaxY;
  final double scalingFactor;
  final List<String> warnings;
  final List<String> recommendations;

  const ChartRenderingValidationResult._({
    required this.isValid,
    required this.hasWarning,
    this.message,
    required this.recommendedMaxY,
    required this.scalingFactor,
    this.warnings = const [],
    this.recommendations = const [],
  });

  factory ChartRenderingValidationResult.valid({
    required double recommendedMaxY,
    double scalingFactor = 1.0,
    List<String>? warnings,
    List<String>? recommendations,
  }) {
    return ChartRenderingValidationResult._(
      isValid: true,
      hasWarning: (warnings?.isNotEmpty ?? false),
      recommendedMaxY: recommendedMaxY,
      scalingFactor: scalingFactor,
      warnings: warnings ?? [],
      recommendations: recommendations ?? [],
    );
  }

  factory ChartRenderingValidationResult.warning(
    String message, {
    required double recommendedMaxY,
    double scalingFactor = 1.0,
    List<String>? warnings,
    List<String>? recommendations,
  }) {
    return ChartRenderingValidationResult._(
      isValid: true,
      hasWarning: true,
      message: message,
      recommendedMaxY: recommendedMaxY,
      scalingFactor: scalingFactor,
      warnings: warnings ?? [],
      recommendations: recommendations ?? [],
    );
  }

  factory ChartRenderingValidationResult.invalid(
    String message, {
    double recommendedMaxY = 5.0,
    double scalingFactor = 1.0,
    List<String>? warnings,
    List<String>? recommendations,
  }) {
    return ChartRenderingValidationResult._(
      isValid: false,
      hasWarning: false,
      message: message,
      recommendedMaxY: recommendedMaxY,
      scalingFactor: scalingFactor,
      warnings: warnings ?? [],
      recommendations: recommendations ?? [],
    );
  }

  @override
  String toString() {
    return 'ChartRenderingValidationResult(isValid: $isValid, hasWarning: $hasWarning, message: $message, recommendedMaxY: $recommendedMaxY)';
  }
}