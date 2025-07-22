# API Documentation - Enhanced Services and Providers

## Overview

This document provides comprehensive API documentation for the enhanced services and providers that support activity deletion with stat reversal, infinite stats progression, and improved UI layout.

## Services

### ActivityService

#### `deleteActivityWithStatReversal(String activityId)`

Deletes an activity with comprehensive stat and EXP reversal.

**Parameters:**
- `activityId` (String): Unique identifier of the activity to delete

**Returns:**
- `Future<ActivityDeletionResult>`: Result containing success status and reversal details

**Process:**
1. Validates activity exists and can be safely deleted
2. Calculates stat reversals using stored gains or fallback calculation
3. Validates reversals won't cause invalid stat values
4. Applies stat reversals with floor constraint enforcement
5. Handles EXP reversal and potential level-down scenarios
6. Deletes activity record with rollback on failure

**Example:**
```dart
final result = await activityService.deleteActivityWithStatReversal('activity_123');
if (result.success) {
  print('Deleted activity, reversed ${result.statReversals.length} stats');
  if (result.leveledDown) {
    print('User leveled down to ${result.newLevel}');
  }
} else {
  print('Deletion failed: ${result.errorMessage}');
}
```

#### `previewActivityDeletion(String activityId)`

Previews the impact of deleting an activity without performing the deletion.

**Parameters:**
- `activityId` (String): Unique identifier of the activity to preview

**Returns:**
- `Future<ActivityDeletionPreview>`: Detailed impact analysis and validation results

**Use Cases:**
- Confirmation dialogs showing deletion impact
- UI validation before enabling delete buttons
- Batch operation planning and validation

**Example:**
```dart
final preview = await activityService.previewActivityDeletion('activity_123');
if (preview.isValid) {
  showConfirmationDialog(
    'Delete activity? This will reverse ${preview.statReversals.length} stat changes.'
  );
} else {
  showError('Cannot delete: ${preview.validationIssues.join(", ")}');
}
```

### StatsService

#### `calculateStatGains(ActivityType activityType, int durationMinutes)`

Calculates stat gains for a given activity type and duration.

**Parameters:**
- `activityType` (ActivityType): Type of activity being performed
- `durationMinutes` (int): Duration in minutes (must be non-negative)

**Returns:**
- `Map<StatType, double>`: Map of stat types to gain amounts

**Activity Mappings:**
- Weight Training: +0.06 Strength/hr, +0.04 Endurance/hr
- Cardio: +0.06 Agility/hr, +0.04 Endurance/hr
- Yoga: +0.05 Agility/hr, +0.03 Focus/hr
- Serious Study: +0.06 Intelligence/hr, +0.04 Focus/hr
- Quit Bad Habit: +0.03 Focus (fixed amount)

**Example:**
```dart
final gains = StatsService.calculateStatGains(ActivityType.workoutWeights, 90);
// Returns: {StatType.strength: 0.09, StatType.endurance: 0.06}
```

#### `validateInfiniteStats(Map<StatType, double> stats)`

Comprehensive validation for the infinite stats system.

**Parameters:**
- `stats` (Map<StatType, double>): Map of stat types to values

**Returns:**
- `InfiniteStatsValidationResult`: Validation status and sanitized values

**Validation Checks:**
- Invalid values (NaN, infinite)
- Floor constraint (minimum 1.0)
- Overflow protection
- Performance impact assessment

**Example:**
```dart
final result = StatsService.validateInfiniteStats(userStats);
if (result.isValid) {
  useStats(stats);
} else if (result.hasWarning) {
  useStats(result.sanitizedStats);
  showWarning(result.message);
} else {
  useStats(result.sanitizedStats);
  showError(result.message);
}
```

#### `calculateStatReversals(ActivityType activityType, int durationMinutes, Map<StatType, double>? storedStatGains)`

Calculates stat reversals for activity deletion with legacy data support.

**Parameters:**
- `activityType` (ActivityType): Type of activity being reversed
- `durationMinutes` (int): Duration of original activity
- `storedStatGains` (Map<StatType, double>?): Stored gains from activity log (null for legacy)

**Returns:**
- `Map<StatType, double>`: Map of stat types to reversal amounts

**Priority:**
1. Stored gains (preferred) - exact accuracy
2. Fallback calculation - reasonable accuracy for legacy data

**Example:**
```dart
// Using stored gains (preferred)
final reversals = StatsService.calculateStatReversals(
  ActivityType.workoutWeights, 60, storedGains
);

// Fallback for legacy activity
final reversals = StatsService.calculateStatReversals(
  ActivityType.workoutWeights, 60, null
);
```

### EXPService

#### `handleEXPReversal(User user, double expToReverse)`

Handles EXP reversal for activity deletion with level-down support.

**Parameters:**
- `user` (User): User whose EXP should be reversed
- `expToReverse` (double): Amount of EXP to remove (must be non-negative)

**Returns:**
- `User`: New User instance with reversed EXP and adjusted level

**Process:**
1. Subtract EXP amount from current EXP
2. If EXP becomes negative, "borrow" from previous levels
3. Continue until EXP is non-negative or level reaches 1
4. Ensure final state has EXP >= 0 and level >= 1

**Example:**
```dart
// User at level 3 with 500 EXP, reverse 1000 EXP
final updatedUser = EXPService.handleEXPReversal(user, 1000.0);
// Result: User might be at level 2 with appropriate EXP
```

#### `calculateLevelDown(User user, double expToReverse)`

Calculates level-down impact for preview and confirmation purposes.

**Parameters:**
- `user` (User): User to calculate impact for
- `expToReverse` (double): Amount of EXP that would be removed

**Returns:**
- `LevelDownResult`: Detailed impact information

**Information Provided:**
- Whether level-down will occur
- New level after reversal
- New EXP amount after reversal
- Total number of levels lost

**Example:**
```dart
final preview = EXPService.calculateLevelDown(user, 1500.0);
if (preview.willLevelDown) {
  showConfirmation(
    'This will cause you to level down ${preview.levelsLost} levels '
    'from ${user.level} to ${preview.newLevel}. Continue?'
  );
}
```

## Providers

### UserProvider

#### `applyStatReversals({required Map<StatType, double> statReversals, required double expToReverse})`

Applies stat reversals for activity deletion with comprehensive error handling.

**Parameters:**
- `statReversals` (Map<StatType, double>): Map of stat types to reversal amounts
- `expToReverse` (double): Amount of EXP to reverse

**Returns:**
- `Future<StatReversalResult>`: Operation status and detailed information

**Process:**
1. Validate user state and input parameters
2. Store original state for potential rollback
3. Apply stat reversals through UserService
4. Handle level-down scenarios if EXP reversal causes them
5. Update provider state and notify listeners

**Example:**
```dart
final result = await userProvider.applyStatReversals(
  statReversals: {
    StatType.strength: 0.12,
    StatType.endurance: 0.08,
  },
  expToReverse: 60.0,
);

if (result.success) {
  showSuccess('Activity deleted successfully');
  if (result.leveledDown) {
    showLevelDownAlert('You leveled down to ${result.newLevel}');
  }
} else {
  showError('Failed to delete activity: ${result.errorMessage}');
}
```

### ActivityProvider

#### `deleteActivity(String activityId)`

Deletes an activity with comprehensive stat reversal and UI coordination.

**Parameters:**
- `activityId` (String): Unique identifier of the activity to delete

**Returns:**
- `Future<ActivityDeletionResult>`: Detailed operation status and information

**Process:**
1. Set loading state and clear previous messages
2. Preview deletion to validate safety and show warnings
3. Perform safe deletion through ActivityService
4. Immediately update local state for UI responsiveness
5. Refresh data from repository for consistency
6. Provide user feedback through success/error messages

**Example:**
```dart
final result = await activityProvider.deleteActivity('activity_123');

if (result.success) {
  showSnackbar('Activity deleted successfully');
  
  if (result.leveledDown) {
    showDialog('You leveled down to ${result.newLevel}');
  }
} else {
  final errorMsg = activityProvider.getDeletionErrorMessage(result);
  showError(errorMsg);
}
```

#### `previewActivityDeletion(String activityId)`

Previews activity deletion without actually deleting.

**Parameters:**
- `activityId` (String): Unique identifier of the activity to preview

**Returns:**
- `Future<ActivityDeletionPreview>`: Preview result with impact analysis

**Use Cases:**
- Confirmation dialogs
- UI validation
- Impact assessment

## Data Models

### ActivityLog

Enhanced with stat reversal support and data migration capabilities.

#### Key Properties:
- `statGainsMap`: Provides stored or calculated stat gains for reversal
- `needsStatGainMigration`: Detects legacy activities without stored gains
- `hasStoredStatGains`: Checks if activity has stored gains

#### Key Methods:

##### `migrateStatGains()`

Migrates stat gains data for activities that don't have stored gains.

**Usage:**
```dart
if (activity.needsStatGainMigration) {
  activity.migrateStatGains();
  // Now activity supports accurate stat reversal
}
```

### User

Enhanced with infinite stats progression support.

#### Key Features:
- No ceiling limits on stat values (removed 5.0 maximum)
- Maintains 1.0 minimum floor for all stats
- Type-safe stat access methods

#### Key Methods:

##### `getStat(StatType statType)`

Gets stat value by StatType.

**Parameters:**
- `statType` (StatType): The stat type to retrieve

**Returns:**
- `double`: Current stat value (minimum 1.0)

##### `setStat(StatType statType, double value)`

Sets stat value by StatType.

**Parameters:**
- `statType` (StatType): The stat type to set
- `value` (double): New stat value

##### `addToStat(StatType statType, double value)`

Adds to stat value by StatType.

**Parameters:**
- `statType` (StatType): The stat type to modify
- `value` (double): Amount to add (can be negative for subtraction)

## Result Classes

### ActivityDeletionResult

Result of activity deletion operation.

**Properties:**
- `success` (bool): Whether deletion succeeded
- `errorMessage` (String?): Error message if deletion failed
- `deletedActivity` (ActivityLog?): The deleted activity
- `statReversals` (Map<StatType, double>): Stat reversals applied
- `expReversed` (double): EXP amount reversed
- `newLevel` (int): User's new level after deletion
- `leveledDown` (bool): Whether user leveled down

### ActivityDeletionPreview

Preview of activity deletion impact.

**Properties:**
- `activity` (ActivityLog): The activity being previewed
- `statReversals` (Map<StatType, double>): Stat reversals that would be applied
- `expToReverse` (double): EXP that would be reversed
- `willLevelDown` (bool): Whether level-down would occur
- `newLevel` (int): New level after deletion
- `isValid` (bool): Whether deletion is safe to perform
- `validationIssues` (List<String>): List of validation issues

### InfiniteStatsValidationResult

Result of infinite stats validation.

**Properties:**
- `isValid` (bool): Whether stats are valid
- `hasWarning` (bool): Whether there are warnings
- `message` (String?): Validation message
- `sanitizedStats` (Map<StatType, double>?): Sanitized stat values
- `warnings` (List<String>): List of warning messages

## Error Handling

### Common Error Scenarios

1. **Activity Not Found**: Activity ID doesn't exist
2. **Validation Failed**: Activity data is invalid or corrupted
3. **Stat Reversal Failed**: Reversal would cause invalid stat values
4. **EXP Reversal Failed**: EXP reversal would cause invalid user state
5. **Data Corruption**: Inconsistent data detected

### Error Recovery

- Automatic sanitization of invalid values
- Fallback to safe defaults on critical errors
- Comprehensive logging for debugging
- User-friendly error messages
- Rollback mechanisms for failed operations

## Performance Considerations

### Chart Rendering
- Validation for rendering safety
- Auto-scaling for optimal display
- Performance warnings for large values
- Logarithmic scaling for extreme values

### Memory Usage
- Efficient stat storage and calculation
- Optimized chart data preparation
- Minimal memory overhead for large values

### Database Operations
- Atomic transaction-like behavior for deletions
- Efficient Hive storage for all value ranges
- Optimized queries for activity history

## Best Practices

### For API Usage

1. **Always validate inputs** before calling service methods
2. **Handle all result types** (success, warning, error)
3. **Use preview methods** before destructive operations
4. **Implement proper error handling** with user feedback
5. **Test with edge cases** including extreme values

### For UI Integration

1. **Show loading states** during async operations
2. **Provide confirmation dialogs** for destructive actions
3. **Display meaningful error messages** to users
4. **Update UI optimistically** for better user experience
5. **Handle validation warnings** appropriately

### For Data Management

1. **Migrate legacy data** when possible for accuracy
2. **Validate stats** before storage and display
3. **Use sanitized values** when validation fails
4. **Implement proper backup/restore** for data safety