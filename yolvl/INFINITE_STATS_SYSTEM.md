# Infinite Stats System - Developer Documentation

## Overview

The Infinite Stats System removes the previous 5.0 ceiling on user stats, allowing unlimited progression while maintaining data integrity and performance. This document provides comprehensive information for developers working with or maintaining this system.

## Key Components

### 1. StatsService (`lib/services/stats_service.dart`)

The core service handling all stat-related calculations and validations.

#### Key Methods:

- `calculateStatGains()`: Calculates stat gains for activities (no ceiling)
- `validateInfiniteStats()`: Comprehensive validation for infinite stat values
- `validateStatsForChart()`: Validates stats for chart rendering performance
- `calculateStatReversals()`: Handles stat reversal for activity deletion
- `applyStatReversals()`: Applies reversals with floor constraint (1.0 minimum)

#### Validation Levels:

1. **Valid**: All stats pass validation without issues
2. **Warning**: Stats are usable but have performance implications
3. **Invalid**: Critical issues detected, sanitized stats provided

### 2. User Model (`lib/models/user.dart`)

Enhanced to support infinite stat values while maintaining data integrity.

#### Key Changes:

- Removed stat ceiling validation (was 5.0 maximum)
- Maintains 1.0 minimum floor for all stats
- Type-safe stat access methods: `getStat()`, `setStat()`, `addToStat()`
- JSON serialization support for backup/export

### 3. Chart Auto-Scaling (`lib/widgets/stats_overview_chart.dart`)

Automatically scales charts to accommodate any stat value range.

#### Scaling Algorithm:

```dart
if (maxStatValue <= 5.0) return 5.0;           // Original behavior
if (maxStatValue <= 100.0) return ceil(max/5)*5;   // Increments of 5
if (maxStatValue <= 1000.0) return ceil(max/50)*50; // Increments of 50
else return ceil(max/500)*500;                  // Increments of 500
```

#### Performance Considerations:

- Uses `InfiniteStatsValidator` for rendering safety
- Handles extremely large values with logarithmic scaling warnings
- Provides fallback to safe defaults on validation failure

## Activity Deletion with Stat Reversal

### Process Flow

1. **Validation**: Check activity exists and can be safely deleted
2. **Calculation**: Calculate stat reversals using stored or fallback gains
3. **Preview**: Validate reversals won't cause invalid states
4. **Execution**: Apply reversals with atomic transaction-like behavior
5. **Rollback**: Restore original state if any step fails

### Key Classes

#### ActivityService
- `deleteActivityWithStatReversal()`: Main deletion method
- `previewActivityDeletion()`: Preview impact without changes
- `safeDeleteActivity()`: Combines preview and deletion

#### ActivityLog Model
- `statGainsMap`: Provides stored or calculated stat gains
- `needsStatGainMigration`: Detects legacy activities
- `migrateStatGains()`: Adds stored gains to legacy activities

### Data Migration

Legacy activities (logged before stat storage) use fallback calculation:

```dart
// Priority order for stat reversal:
1. Stored gains (preferred) - exact accuracy
2. Calculated gains (fallback) - reasonable accuracy for legacy data
```

## Validation Systems

### 1. Infinite Stats Validation

```dart
final result = StatsService.validateInfiniteStats(stats);
if (result.isValid) {
    // Use original stats
} else if (result.hasWarning) {
    // Use sanitized stats with warning
} else {
    // Critical issues, use sanitized stats
}
```

### 2. Chart Rendering Validation

```dart
final result = StatsService.validateStatsForChart(stats);
// Provides recommendedMaxY for optimal chart display
```

### 3. Export/Import Validation

```dart
final result = StatsService.validateStatsForExport(stats);
// Ensures data integrity during backup/restore
```

## Performance Considerations

### Chart Rendering

- **Small values (≤ 100)**: Standard rendering
- **Medium values (100-10,000)**: Performance monitoring
- **Large values (> 10,000)**: Logarithmic scaling consideration
- **Extreme values (> 100,000)**: Performance warnings

### Memory Usage

- Stat values stored as `double` (8 bytes each)
- Chart data optimized for large value ranges
- Validation results cached when possible

### Database Storage

- Hive handles large double values efficiently
- JSON export supports arbitrary precision
- Backup/restore maintains full precision

## Error Handling

### Common Error Scenarios

1. **Invalid Values**: NaN, infinite values → Sanitized to safe defaults
2. **Floor Violations**: Values < 1.0 → Clamped to 1.0 minimum
3. **Overflow**: Extremely large values → Clamped to reasonable maximum
4. **Chart Rendering**: Performance issues → Logarithmic scaling or warnings

### Error Recovery

- Automatic sanitization of invalid values
- Fallback to safe defaults on critical errors
- Comprehensive logging for debugging
- User-friendly error messages

## Testing Considerations

### Edge Cases to Test

1. **Stat Values**:
   - Normal values (1.0 - 100.0)
   - Large values (100.0 - 10,000.0)
   - Very large values (10,000.0 - 1,000,000.0)
   - Invalid values (NaN, infinite, negative)

2. **Chart Rendering**:
   - Various stat ranges
   - Performance with large values
   - Auto-scaling accuracy
   - Accessibility compliance

3. **Activity Deletion**:
   - Activities with stored gains
   - Legacy activities without stored gains
   - Level-down scenarios
   - Data corruption scenarios

### Test Utilities

```dart
// Test edge case stat values
final testResult = StatsService.testEdgeCaseStatValues();

// Validate chart rendering
final chartResult = StatsService.validateChartRendering(extremeStats);
```

## Migration Guide

### From Capped Stats (≤ 5.0) to Infinite Stats

1. **No data migration required**: Existing stats work unchanged
2. **Users can immediately progress beyond 5.0**
3. **Charts automatically scale to accommodate new values**
4. **All validation systems handle the transition seamlessly**

### Legacy Activity Migration

```dart
// Check if activity needs migration
if (activity.needsStatGainMigration) {
    // Add stored stat gains for accurate reversal
    activity.migrateStatGains();
}
```

## Best Practices

### For Developers

1. **Always validate stats** before display or calculation
2. **Use type-safe methods** for stat access (`getStat()`, `setStat()`)
3. **Handle validation warnings** appropriately in UI
4. **Test with extreme values** during development
5. **Monitor performance** with large stat values

### For UI Components

1. **Use auto-scaling charts** for stat display
2. **Format stat values** appropriately (remove trailing zeros)
3. **Provide accessibility labels** for large numbers
4. **Handle loading states** during validation

### For Data Operations

1. **Validate before storage** using `validateInfiniteStats()`
2. **Use sanitized values** when validation fails
3. **Log validation issues** for debugging
4. **Implement proper error handling** for edge cases

## Future Considerations

### Potential Enhancements

1. **Logarithmic Display**: For extremely large values
2. **Scientific Notation**: For values > 1,000,000
3. **Stat Categories**: Grouping related stats
4. **Performance Monitoring**: Real-time performance tracking

### Scalability

- Current system handles values up to ~1,000,000 efficiently
- Chart rendering optimized for values up to ~100,000
- Database storage scales to any reasonable value range
- Memory usage remains constant regardless of stat values

## Troubleshooting

### Common Issues

1. **Chart not scaling**: Check `validateStatsForChart()` result
2. **Performance issues**: Monitor for extremely large values
3. **Invalid stat values**: Check validation results and sanitization
4. **Activity deletion fails**: Verify stat reversal validation

### Debugging Tools

- Comprehensive logging in all validation methods
- Test utilities for edge case validation
- Error reporting with detailed context
- Performance monitoring for large values

## Conclusion

The Infinite Stats System provides unlimited progression while maintaining data integrity, performance, and user experience. The comprehensive validation systems ensure safe operation across all value ranges, while the auto-scaling features provide optimal display regardless of stat magnitude.

For questions or issues, refer to the inline documentation in the relevant service classes or consult the test files for usage examples.