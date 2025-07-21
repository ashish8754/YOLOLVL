import '../models/activity_log.dart';
import '../repositories/activity_repository.dart';

/// Service for handling data migration of activity logs
class ActivityMigrationService {
  final ActivityRepository _activityRepository;

  ActivityMigrationService({
    ActivityRepository? activityRepository,
  }) : _activityRepository = activityRepository ?? ActivityRepository();

  /// Migrate all activities that don't have stored stat gains
  /// This is needed for stat reversal functionality
  Future<ActivityMigrationResult> migrateAllActivities() async {
    try {
      final allActivities = await _activityRepository.getAllActivities();
      final activitiesNeedingMigration = allActivities
          .where((activity) => activity.needsStatGainMigration)
          .toList();

      if (activitiesNeedingMigration.isEmpty) {
        return ActivityMigrationResult.success(
          totalActivities: allActivities.length,
          migratedActivities: 0,
          message: 'No activities need migration',
        );
      }

      int migratedCount = 0;
      final List<String> errors = [];

      for (final activity in activitiesNeedingMigration) {
        try {
          activity.migrateStatGains();
          await _activityRepository.logActivity(activity); // Update the stored activity
          migratedCount++;
        } catch (e) {
          errors.add('Failed to migrate activity ${activity.id}: $e');
        }
      }

      if (errors.isNotEmpty) {
        return ActivityMigrationResult.partialSuccess(
          totalActivities: allActivities.length,
          migratedActivities: migratedCount,
          errors: errors,
        );
      }

      return ActivityMigrationResult.success(
        totalActivities: allActivities.length,
        migratedActivities: migratedCount,
        message: 'Successfully migrated $migratedCount activities',
      );
    } catch (e) {
      return ActivityMigrationResult.error('Migration failed: $e');
    }
  }

  /// Check how many activities need migration
  Future<int> getActivitiesNeedingMigrationCount() async {
    try {
      final allActivities = await _activityRepository.getAllActivities();
      return allActivities
          .where((activity) => activity.needsStatGainMigration)
          .length;
    } catch (e) {
      throw ActivityMigrationException('Failed to count activities needing migration: $e');
    }
  }

  /// Check if any activities need migration
  Future<bool> hasActivitiesNeedingMigration() async {
    try {
      final count = await getActivitiesNeedingMigrationCount();
      return count > 0;
    } catch (e) {
      throw ActivityMigrationException('Failed to check migration status: $e');
    }
  }

  /// Migrate a specific activity by ID
  Future<bool> migrateActivity(String activityId) async {
    try {
      final activity = _activityRepository.findByKey(activityId);
      if (activity == null) {
        return false;
      }

      if (!activity.needsStatGainMigration) {
        return true; // Already migrated
      }

      activity.migrateStatGains();
      await _activityRepository.logActivity(activity);
      return true;
    } catch (e) {
      throw ActivityMigrationException('Failed to migrate activity $activityId: $e');
    }
  }

  /// Get migration status for all activities
  Future<ActivityMigrationStatus> getMigrationStatus() async {
    try {
      final allActivities = await _activityRepository.getAllActivities();
      final needingMigration = allActivities
          .where((activity) => activity.needsStatGainMigration)
          .toList();

      return ActivityMigrationStatus(
        totalActivities: allActivities.length,
        migratedActivities: allActivities.length - needingMigration.length,
        activitiesNeedingMigration: needingMigration.length,
        migrationComplete: needingMigration.isEmpty,
      );
    } catch (e) {
      throw ActivityMigrationException('Failed to get migration status: $e');
    }
  }
}

/// Result of activity migration operation
class ActivityMigrationResult {
  final bool success;
  final String? errorMessage;
  final int totalActivities;
  final int migratedActivities;
  final List<String> errors;
  final String? message;

  const ActivityMigrationResult._({
    required this.success,
    this.errorMessage,
    required this.totalActivities,
    required this.migratedActivities,
    this.errors = const [],
    this.message,
  });

  factory ActivityMigrationResult.success({
    required int totalActivities,
    required int migratedActivities,
    String? message,
  }) {
    return ActivityMigrationResult._(
      success: true,
      totalActivities: totalActivities,
      migratedActivities: migratedActivities,
      message: message,
    );
  }

  factory ActivityMigrationResult.partialSuccess({
    required int totalActivities,
    required int migratedActivities,
    required List<String> errors,
  }) {
    return ActivityMigrationResult._(
      success: false,
      totalActivities: totalActivities,
      migratedActivities: migratedActivities,
      errors: errors,
      errorMessage: 'Migration completed with ${errors.length} errors',
    );
  }

  factory ActivityMigrationResult.error(String errorMessage) {
    return ActivityMigrationResult._(
      success: false,
      errorMessage: errorMessage,
      totalActivities: 0,
      migratedActivities: 0,
    );
  }

  /// Get migration completion percentage
  double get completionPercentage {
    if (totalActivities == 0) return 100.0;
    return (migratedActivities / totalActivities) * 100.0;
  }

  @override
  String toString() {
    if (success) {
      return 'ActivityMigrationResult(success: true, migrated: $migratedActivities/$totalActivities)';
    } else {
      return 'ActivityMigrationResult(success: false, error: $errorMessage)';
    }
  }
}

/// Status of activity migration
class ActivityMigrationStatus {
  final int totalActivities;
  final int migratedActivities;
  final int activitiesNeedingMigration;
  final bool migrationComplete;

  const ActivityMigrationStatus({
    required this.totalActivities,
    required this.migratedActivities,
    required this.activitiesNeedingMigration,
    required this.migrationComplete,
  });

  /// Get migration completion percentage
  double get completionPercentage {
    if (totalActivities == 0) return 100.0;
    return (migratedActivities / totalActivities) * 100.0;
  }

  @override
  String toString() {
    return 'ActivityMigrationStatus(total: $totalActivities, migrated: $migratedActivities, needingMigration: $activitiesNeedingMigration, complete: $migrationComplete)';
  }
}

/// Custom exception for activity migration operations
class ActivityMigrationException implements Exception {
  final String message;

  ActivityMigrationException(this.message);

  @override
  String toString() => 'ActivityMigrationException: $message';
}