import '../models/enums.dart';
import 'dart:math' as math;

/// Utility class for validating infinite stats system
/// Provides comprehensive validation for stat values, ensuring they remain
/// within reasonable bounds while allowing for infinite progression
class InfiniteStatsValidator {
  /// Maximum reasonable stat value to prevent overflow and rendering issues
  /// This is a safety limit, not a gameplay limit
  static const double MAX_REASONABLE_VALUE = 999999.0; // 1 million - 1
  
  /// Minimum allowed stat value
  static const double MIN_STAT_VALUE = 1.0;
  
  /// Threshold for warning about very large values
  static const double LARGE_VALUE_WARNING = 100000.0;
  
  /// Threshold for warning about extremely large values
  static const double EXTREME_VALUE_WARNING = 500000.0;
  
  /// Validate a single stat value
  /// Returns a sanitized value that is safe for storage and display
  static double validateStatValue(double value) {
    // Handle special cases
    if (value.isNaN) {
      _logError('validateStatValue', 'NaN stat value detected, using minimum: $MIN_STAT_VALUE');
      return MIN_STAT_VALUE;
    }
    
    if (value.isInfinite) {
      _logError('validateStatValue', 'Infinite stat value detected, using maximum reasonable value');
      if (value.isNegative) {
        return MIN_STAT_VALUE;
      }
      return MAX_REASONABLE_VALUE;
    }
    
    // Handle negative values
    if (value < MIN_STAT_VALUE) {
      return MIN_STAT_VALUE;
    }
    
    // Handle extremely large values
    if (value > MAX_REASONABLE_VALUE) {
      _logWarning('validateStatValue', 'Extremely large stat value: $value, clamping to reasonable maximum');
      return MAX_REASONABLE_VALUE;
    }
    
    return value;
  }
  
  /// Validate a map of stats
  /// Returns a sanitized map with all values validated
  static Map<StatType, double> validateStats(Map<StatType, double> stats) {
    final validatedStats = <StatType, double>{};
    
    // Ensure all stat types are present
    for (final statType in StatType.values) {
      final value = stats[statType] ?? MIN_STAT_VALUE;
      validatedStats[statType] = validateStatValue(value);
    }
    
    return validatedStats;
  }
  
  /// Comprehensive validation for infinite stats system
  /// Validates stats for storage, calculation, and display safety
  static ValidationResult validateInfiniteStats(Map<StatType, double> stats) {
    try {
      if (stats.isEmpty) {
        return ValidationResult.invalid('Stats map is empty');
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
          sanitizedStats[statType] = MIN_STAT_VALUE;
        } else if (value.isInfinite) {
          issues.add('${statType.name} has infinite value');
          sanitizedStats[statType] = value.isNegative ? MIN_STAT_VALUE : MAX_REASONABLE_VALUE;
        } else if (value < MIN_STAT_VALUE) {
          warnings.add('${statType.name} below minimum (${value.toStringAsFixed(2)})');
          sanitizedStats[statType] = MIN_STAT_VALUE;
        } else if (value > MAX_REASONABLE_VALUE) {
          warnings.add('${statType.name} extremely large (${value.toStringAsFixed(0)})');
          sanitizedStats[statType] = MAX_REASONABLE_VALUE;
        } else {
          sanitizedStats[statType] = value;
        }
      }

      // Check for potential overflow in calculations
      if (sanitizedStats.isNotEmpty) {
        final maxValue = sanitizedStats.values.reduce((a, b) => a > b ? a : b);
        if (maxValue > LARGE_VALUE_WARNING) {
          warnings.add('Very large stat values may impact performance');
        }
      }

      if (issues.isNotEmpty) {
        return ValidationResult.invalid(
          'Critical validation issues: ${issues.join(', ')}',
          sanitizedStats: sanitizedStats,
          warnings: warnings,
        );
      }

      if (warnings.isNotEmpty) {
        return ValidationResult.warning(
          'Validation warnings: ${warnings.join(', ')}',
          sanitizedStats: sanitizedStats,
          warnings: warnings,
        );
      }

      return ValidationResult.valid(sanitizedStats: sanitizedStats);
    } catch (e) {
      _logError('validateForStorage', 'Exception during validation: $e');
      return ValidationResult.invalid('Validation failed: $e');
    }
  }
  
  /// Validate stats for chart rendering
  /// Returns validation result with recommendations for chart configuration
  static ChartValidationResult validateStatsForChart(Map<StatType, double> stats) {
    try {
      if (stats.isEmpty) {
        return ChartValidationResult.invalid('Stats map is empty');
      }

      final maxValue = stats.values.reduce((a, b) => a > b ? a : b);
      final minValue = stats.values.reduce((a, b) => a < b ? a : b);

      // Check for invalid values
      for (final entry in stats.entries) {
        if (entry.value.isNaN || entry.value.isInfinite) {
          return ChartValidationResult.invalid('Invalid stat value for ${entry.key.name}: ${entry.value}');
        }
      }

      // Check for extremely large values that might cause rendering issues
      if (maxValue > LARGE_VALUE_WARNING) {
        return ChartValidationResult.warning(
          'Very large stat values detected (max: ${maxValue.toStringAsFixed(0)}). Chart rendering may have performance issues.',
          recommendedMaxY: _calculateSafeChartMaximum(maxValue),
          scalingFactor: _calculateScalingFactor(maxValue),
        );
      }

      // Check for very small differences that might not render well
      if (maxValue > 0 && (maxValue - minValue) < 0.01) {
        return ChartValidationResult.warning(
          'Very small stat differences detected. Chart may not show clear distinctions.',
          recommendedMaxY: maxValue + 1.0,
          scalingFactor: 1.0,
        );
      }

      return ChartValidationResult.valid(
        recommendedMaxY: _calculateSafeChartMaximum(maxValue),
        scalingFactor: _calculateScalingFactor(maxValue),
      );
    } catch (e) {
      _logError('validateForChart', 'Exception during chart validation: $e');
      return ChartValidationResult.invalid('Chart validation failed: $e');
    }
  }
  
  /// Validate stats for export/import operations
  /// Ensures data integrity during backup/restore with infinite stats
  static ValidationResult validateStatsForExport(Map<StatType, double> stats) {
    try {
      if (stats.isEmpty) {
        return ValidationResult.invalid('No stats to export');
      }

      final issues = <String>[];
      final warnings = <String>[];
      final sanitizedStats = <StatType, double>{};

      for (final entry in stats.entries) {
        final statType = entry.key;
        final value = entry.value;

        if (value.isNaN || value.isInfinite) {
          issues.add('${statType.name}: Invalid value ($value)');
          sanitizedStats[statType] = MIN_STAT_VALUE;
        } else if (value < MIN_STAT_VALUE) {
          warnings.add('${statType.name}: Below minimum (${value.toStringAsFixed(2)})');
          sanitizedStats[statType] = MIN_STAT_VALUE;
        } else if (value > MAX_REASONABLE_VALUE) {
          warnings.add('${statType.name}: Extremely large value (${value.toStringAsFixed(0)})');
          sanitizedStats[statType] = value; // Keep large values for export
        } else {
          sanitizedStats[statType] = value;
        }
      }

      if (issues.isNotEmpty) {
        return ValidationResult.invalid(
          'Export validation failed: ${issues.join(', ')}',
          sanitizedStats: sanitizedStats,
          warnings: warnings,
        );
      }

      if (warnings.isNotEmpty) {
        return ValidationResult.warning(
          'Export validation warnings: ${warnings.join(', ')}',
          sanitizedStats: sanitizedStats,
          warnings: warnings,
        );
      }

      return ValidationResult.valid(sanitizedStats: sanitizedStats);
    } catch (e) {
      _logError('validateForExport', 'Exception during export validation: $e');
      return ValidationResult.invalid('Export validation failed: $e');
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
        // Test storage validation
        final storageResult = validateInfiniteStats(testStats);
        results['${testName}_validation'] = storageResult.isValid;

        // Test chart validation
        final chartResult = validateStatsForChart(testStats);
        results['${testName}_chart'] = chartResult.isValid;

        // Test export validation
        final exportResult = validateStatsForExport(testStats);
        results['${testName}_export'] = exportResult.isValid;

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
  
  /// Calculate safe chart maximum for rendering performance
  static double _calculateSafeChartMaximum(double maxStatValue) {
    // For very large values, use logarithmic scaling or reasonable increments
    if (maxStatValue <= 5.0) {
      return 5.0;
    } else if (maxStatValue <= 10.0) {
      return 10.0;
    } else if (maxStatValue <= 20.0) {
      return 20.0;
    } else if (maxStatValue <= 50.0) {
      return 50.0;
    } else if (maxStatValue <= 100.0) {
      // Use increments of 10 up to 100
      return ((maxStatValue / 10.0).ceil() * 10.0);
    } else if (maxStatValue <= 200.0) {
      // Use increments of 50 for values 100-200
      return ((maxStatValue / 50.0).ceil() * 50.0);
    } else if (maxStatValue <= 500.0) {
      // Use increments of 100 for values 200-500
      return ((maxStatValue / 100.0).ceil() * 100.0);
    } else if (maxStatValue <= 1000.0) {
      // Use increments of 100 for values 500-1000
      return ((maxStatValue / 100.0).ceil() * 100.0);
    } else if (maxStatValue <= 10000.0) {
      // Use increments of 1000 for values 1000-10000
      return ((maxStatValue / 1000.0).ceil() * 1000.0);
    } else {
      // Use increments of 10000 for very large values
      return ((maxStatValue / 10000.0).ceil() * 10000.0);
    }
  }
  
  /// Calculate scaling factor for chart rendering
  static double _calculateScalingFactor(double maxStatValue) {
    if (maxStatValue <= 5.0) {
      return 1.0;
    } else if (maxStatValue <= 100.0) {
      return 1.0;
    } else if (maxStatValue <= 1000.0) {
      return 0.1;
    } else if (maxStatValue <= 10000.0) {
      return 0.01;
    } else {
      return 0.001;
    }
  }
  
  /// Format stat value for display with appropriate precision
  static String formatStatValue(double value) {
    if (value.isNaN || value.isInfinite) {
      return 'Invalid';
    }
    
    // For whole numbers, show no decimal places
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    
    if (value >= 100) {
      return value.toStringAsFixed(1); // 123.4
    } else if (value >= 10) {
      return value.toStringAsFixed(1); // 12.3
    } else {
      return value.toStringAsFixed(2); // 1.23
    }
  }
  
  /// Log error messages with context
  static void _logError(String method, String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] ERROR InfiniteStatsValidator.$method: $message';
    print(logMessage); // In production, use proper logging framework
  }

  /// Log warning messages with context
  static void _logWarning(String method, String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] WARNING InfiniteStatsValidator.$method: $message';
    print(logMessage); // In production, use proper logging framework
  }
}

/// Result of validation operation
class ValidationResult {
  final bool isValid;
  final bool hasWarning;
  final String? message;
  final Map<StatType, double>? sanitizedStats;
  final List<String> warnings;

  const ValidationResult._({
    required this.isValid,
    required this.hasWarning,
    this.message,
    this.sanitizedStats,
    this.warnings = const [],
  });

  factory ValidationResult.valid({Map<StatType, double>? sanitizedStats}) {
    return ValidationResult._(
      isValid: true,
      hasWarning: false,
      sanitizedStats: sanitizedStats,
    );
  }

  factory ValidationResult.warning(
    String message, {
    Map<StatType, double>? sanitizedStats,
    List<String>? warnings,
  }) {
    return ValidationResult._(
      isValid: true,
      hasWarning: true,
      message: message,
      sanitizedStats: sanitizedStats,
      warnings: warnings ?? [],
    );
  }

  factory ValidationResult.invalid(
    String message, {
    Map<StatType, double>? sanitizedStats,
    List<String>? warnings,
  }) {
    return ValidationResult._(
      isValid: false,
      hasWarning: false,
      message: message,
      sanitizedStats: sanitizedStats,
      warnings: warnings ?? [],
    );
  }

  @override
  String toString() {
    return 'ValidationResult(isValid: $isValid, hasWarning: $hasWarning, message: $message, warnings: $warnings)';
  }
}

/// Result of chart validation
class ChartValidationResult {
  final bool isValid;
  final bool hasWarning;
  final String? message;
  final double recommendedMaxY;
  final double scalingFactor;

  const ChartValidationResult._({
    required this.isValid,
    required this.hasWarning,
    this.message,
    required this.recommendedMaxY,
    required this.scalingFactor,
  });

  factory ChartValidationResult.valid({
    required double recommendedMaxY,
    required double scalingFactor,
  }) {
    return ChartValidationResult._(
      isValid: true,
      hasWarning: false,
      recommendedMaxY: recommendedMaxY,
      scalingFactor: scalingFactor,
    );
  }

  factory ChartValidationResult.warning(
    String message, {
    required double recommendedMaxY,
    required double scalingFactor,
  }) {
    return ChartValidationResult._(
      isValid: true,
      hasWarning: true,
      message: message,
      recommendedMaxY: recommendedMaxY,
      scalingFactor: scalingFactor,
    );
  }

  factory ChartValidationResult.invalid(String message) {
    return ChartValidationResult._(
      isValid: false,
      hasWarning: false,
      message: message,
      recommendedMaxY: 5.0, // Safe default
      scalingFactor: 1.0,
    );
  }

  @override
  String toString() {
    return 'ChartValidationResult(isValid: $isValid, hasWarning: $hasWarning, message: $message, recommendedMaxY: $recommendedMaxY, scalingFactor: $scalingFactor)';
  }
}

/// Result of edge case testing
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
    return 'EdgeCaseTestResult(passed: $passed, issues: $issues, results: $testResults)';
  }
}