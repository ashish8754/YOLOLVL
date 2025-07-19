import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/activity_log.dart';
import '../models/settings.dart';
import '../repositories/user_repository.dart';
import '../repositories/activity_repository.dart';
import '../repositories/settings_repository.dart';
import '../services/backup_service.dart';

/// Service for validating and recovering data integrity
class DataIntegrityService {
  final UserRepository _userRepository;
  final ActivityRepository _activityRepository;
  final SettingsRepository _settingsRepository;
  final BackupService _backupService;

  DataIntegrityService({
    UserRepository? userRepository,
    ActivityRepository? activityRepository,
    SettingsRepository? settingsRepository,
    BackupService? backupService,
  }) : _userRepository = userRepository ?? UserRepository(),
       _activityRepository = activityRepository ?? ActivityRepository(),
       _settingsRepository = settingsRepository ?? SettingsRepository(),
       _backupService = backupService ?? BackupService();

  /// Perform comprehensive data integrity check and recovery
  Future<DataIntegrityResult> performIntegrityCheck() async {
    final issues = <DataIntegrityIssue>[];
    final fixes = <String>[];

    try {
      // Check user data integrity
      final userIssues = await _checkUserDataIntegrity();
      issues.addAll(userIssues);

      // Check activity data integrity
      final activityIssues = await _checkActivityDataIntegrity();
      issues.addAll(activityIssues);

      // Check settings data integrity
      final settingsIssues = await _checkSettingsDataIntegrity();
      issues.addAll(settingsIssues);

      // Attempt to fix critical issues
      for (final issue in issues) {
        if (issue.severity == DataIntegritySeverity.critical) {
          final fixResult = await _attemptFix(issue);
          if (fixResult != null) {
            fixes.add(fixResult);
          }
        }
      }

      return DataIntegrityResult(
        success: true,
        issues: issues,
        fixesApplied: fixes,
        requiresUserAction: issues.any((issue) => 
          issue.severity == DataIntegritySeverity.critical && 
          !fixes.any((fix) => fix.contains(issue.description))
        ),
      );
    } catch (e) {
      debugPrint('Data integrity check failed: $e');
      return DataIntegrityResult(
        success: false,
        issues: [
          DataIntegrityIssue(
            type: DataIntegrityIssueType.systemError,
            severity: DataIntegritySeverity.critical,
            description: 'Integrity check failed: $e',
            affectedData: 'System',
          ),
        ],
        fixesApplied: [],
        requiresUserAction: true,
      );
    }
  }

  /// Check user data integrity
  Future<List<DataIntegrityIssue>> _checkUserDataIntegrity() async {
    final issues = <DataIntegrityIssue>[];

    try {
      final user = _userRepository.getCurrentUser();
      
      if (user == null) {
        issues.add(DataIntegrityIssue(
          type: DataIntegrityIssueType.missingData,
          severity: DataIntegritySeverity.critical,
          description: 'No user data found',
          affectedData: 'User profile',
        ));
        return issues;
      }

      // Check for invalid level/EXP combinations
      if (user.level < 1) {
        issues.add(DataIntegrityIssue(
          type: DataIntegrityIssueType.invalidData,
          severity: DataIntegritySeverity.high,
          description: 'User level is less than 1',
          affectedData: 'User level',
        ));
      }

      if (user.currentEXP < 0) {
        issues.add(DataIntegrityIssue(
          type: DataIntegrityIssueType.invalidData,
          severity: DataIntegritySeverity.high,
          description: 'User EXP is negative',
          affectedData: 'User EXP',
        ));
      }

      // Check for invalid stat values
      for (final entry in user.stats.entries) {
        if (entry.value < 1.0) {
          issues.add(DataIntegrityIssue(
            type: DataIntegrityIssueType.invalidData,
            severity: DataIntegritySeverity.medium,
            description: 'Stat ${entry.key} is below minimum value (1.0)',
            affectedData: 'User stats',
          ));
        }
        
        if (entry.value > 1000.0) {
          issues.add(DataIntegrityIssue(
            type: DataIntegrityIssueType.invalidData,
            severity: DataIntegritySeverity.low,
            description: 'Stat ${entry.key} is unusually high (${entry.value})',
            affectedData: 'User stats',
          ));
        }
      }

      // Check for future timestamps
      if (user.createdAt.isAfter(DateTime.now())) {
        issues.add(DataIntegrityIssue(
          type: DataIntegrityIssueType.invalidData,
          severity: DataIntegritySeverity.medium,
          description: 'User creation date is in the future',
          affectedData: 'User timestamps',
        ));
      }

    } catch (e) {
      issues.add(DataIntegrityIssue(
        type: DataIntegrityIssueType.corruptedData,
        severity: DataIntegritySeverity.critical,
        description: 'Failed to read user data: $e',
        affectedData: 'User data',
      ));
    }

    return issues;
  }

  /// Check activity data integrity
  Future<List<DataIntegrityIssue>> _checkActivityDataIntegrity() async {
    final issues = <DataIntegrityIssue>[];

    try {
      final activities = await _activityRepository.getAllActivities();
      
      for (final activity in activities) {
        // Check for invalid durations
        if (activity.durationMinutes <= 0) {
          issues.add(DataIntegrityIssue(
            type: DataIntegrityIssueType.invalidData,
            severity: DataIntegritySeverity.medium,
            description: 'Activity ${activity.id} has invalid duration: ${activity.durationMinutes}',
            affectedData: 'Activity logs',
          ));
        }

        // Check for unreasonable durations (more than 24 hours)
        if (activity.durationMinutes > 1440) {
          issues.add(DataIntegrityIssue(
            type: DataIntegrityIssueType.invalidData,
            severity: DataIntegritySeverity.low,
            description: 'Activity ${activity.id} has unusually long duration: ${activity.durationMinutes} minutes',
            affectedData: 'Activity logs',
          ));
        }

        // Check for future timestamps
        if (activity.timestamp.isAfter(DateTime.now())) {
          issues.add(DataIntegrityIssue(
            type: DataIntegrityIssueType.invalidData,
            severity: DataIntegritySeverity.medium,
            description: 'Activity ${activity.id} has future timestamp',
            affectedData: 'Activity timestamps',
          ));
        }

        // Check for negative EXP or stat gains
        if (activity.expGained < 0) {
          issues.add(DataIntegrityIssue(
            type: DataIntegrityIssueType.invalidData,
            severity: DataIntegritySeverity.medium,
            description: 'Activity ${activity.id} has negative EXP gain',
            affectedData: 'Activity rewards',
          ));
        }

        for (final entry in activity.statGains.entries) {
          if (entry.value < 0) {
            issues.add(DataIntegrityIssue(
              type: DataIntegrityIssueType.invalidData,
              severity: DataIntegritySeverity.medium,
              description: 'Activity ${activity.id} has negative stat gain for ${entry.key}',
              affectedData: 'Activity rewards',
            ));
          }
        }
      }

      // Check for duplicate activity IDs
      final activityIds = activities.map((a) => a.id).toList();
      final uniqueIds = activityIds.toSet();
      if (activityIds.length != uniqueIds.length) {
        issues.add(DataIntegrityIssue(
          type: DataIntegrityIssueType.duplicateData,
          severity: DataIntegritySeverity.high,
          description: 'Duplicate activity IDs found',
          affectedData: 'Activity logs',
        ));
      }

    } catch (e) {
      issues.add(DataIntegrityIssue(
        type: DataIntegrityIssueType.corruptedData,
        severity: DataIntegritySeverity.critical,
        description: 'Failed to read activity data: $e',
        affectedData: 'Activity data',
      ));
    }

    return issues;
  }

  /// Check settings data integrity
  Future<List<DataIntegrityIssue>> _checkSettingsDataIntegrity() async {
    final issues = <DataIntegrityIssue>[];

    try {
      final settings = _settingsRepository.getSettings();
      
      // Check for invalid reminder time
      if (settings.dailyReminderHour < 0 || settings.dailyReminderHour > 23) {
        issues.add(DataIntegrityIssue(
          type: DataIntegrityIssueType.invalidData,
          severity: DataIntegritySeverity.medium,
          description: 'Invalid daily reminder hour: ${settings.dailyReminderHour}',
          affectedData: 'Settings',
        ));
      }

      if (settings.dailyReminderMinute < 0 || settings.dailyReminderMinute > 59) {
        issues.add(DataIntegrityIssue(
          type: DataIntegrityIssueType.invalidData,
          severity: DataIntegritySeverity.medium,
          description: 'Invalid daily reminder minute: ${settings.dailyReminderMinute}',
          affectedData: 'Settings',
        ));
      }

      // Check for invalid custom stat increments
      for (final entry in settings.customStatIncrements.entries) {
        if (entry.value < 0 || entry.value > 10.0) {
          issues.add(DataIntegrityIssue(
            type: DataIntegrityIssueType.invalidData,
            severity: DataIntegritySeverity.low,
            description: 'Invalid custom stat increment: ${entry.key} = ${entry.value}',
            affectedData: 'Settings',
          ));
        }
      }

    } catch (e) {
      issues.add(DataIntegrityIssue(
        type: DataIntegrityIssueType.corruptedData,
        severity: DataIntegritySeverity.critical,
        description: 'Failed to read settings data: $e',
        affectedData: 'Settings data',
      ));
    }

    return issues;
  }

  /// Attempt to fix a data integrity issue
  Future<String?> _attemptFix(DataIntegrityIssue issue) async {
    try {
      switch (issue.type) {
        case DataIntegrityIssueType.missingData:
          return await _fixMissingData(issue);
        case DataIntegrityIssueType.invalidData:
          return await _fixInvalidData(issue);
        case DataIntegrityIssueType.corruptedData:
          return await _fixCorruptedData(issue);
        case DataIntegrityIssueType.duplicateData:
          return await _fixDuplicateData(issue);
        case DataIntegrityIssueType.systemError:
          return null; // Cannot auto-fix system errors
      }
    } catch (e) {
      debugPrint('Failed to fix issue: ${issue.description} - $e');
      return null;
    }
  }

  /// Fix missing data issues
  Future<String?> _fixMissingData(DataIntegrityIssue issue) async {
    if (issue.affectedData == 'User profile') {
      // Try to restore from backup first
      final backupRestored = await _tryRestoreFromBackup();
      if (backupRestored) {
        return 'Restored user data from backup';
      }
      
      // Create new user with default values
      final newUser = User.createDefault();
      await _userRepository.save(newUser);
      return 'Created new user profile with default values';
    }
    
    return null;
  }

  /// Fix invalid data issues
  Future<String?> _fixInvalidData(DataIntegrityIssue issue) async {
    if (issue.affectedData == 'User level') {
      final user = _userRepository.getCurrentUser();
      if (user != null && user.level < 1) {
        final fixedUser = user.copyWith(level: 1);
        await _userRepository.save(fixedUser);
        return 'Reset user level to minimum value (1)';
      }
    }
    
    if (issue.affectedData == 'User EXP') {
      final user = _userRepository.getCurrentUser();
      if (user != null && user.currentEXP < 0) {
        final fixedUser = user.copyWith(currentEXP: 0.0);
        await _userRepository.save(fixedUser);
        return 'Reset user EXP to 0';
      }
    }
    
    if (issue.affectedData == 'User stats') {
      final user = _userRepository.getCurrentUser();
      if (user != null) {
        final fixedStats = <String, double>{};
        bool needsFix = false;
        
        for (final entry in user.stats.entries) {
          if (entry.value < 1.0) {
            fixedStats[entry.key] = 1.0;
            needsFix = true;
          } else {
            fixedStats[entry.key] = entry.value;
          }
        }
        
        if (needsFix) {
          final fixedUser = user.copyWith(stats: fixedStats);
          await _userRepository.save(fixedUser);
          return 'Reset invalid stats to minimum value (1.0)';
        }
      }
    }
    
    return null;
  }

  /// Fix corrupted data issues
  Future<String?> _fixCorruptedData(DataIntegrityIssue issue) async {
    // Try to restore from backup
    final backupRestored = await _tryRestoreFromBackup();
    if (backupRestored) {
      return 'Restored corrupted data from backup';
    }
    
    // If no backup available, reset to defaults for critical data
    if (issue.affectedData.contains('User')) {
      final newUser = User.createDefault();
      await _userRepository.save(newUser);
      return 'Reset corrupted user data to defaults';
    }
    
    if (issue.affectedData.contains('Settings')) {
      final newSettings = Settings.createDefault();
      _settingsRepository.saveSettings(newSettings);
      return 'Reset corrupted settings to defaults';
    }
    
    return null;
  }

  /// Fix duplicate data issues
  Future<String?> _fixDuplicateData(DataIntegrityIssue issue) async {
    if (issue.affectedData == 'Activity logs') {
      final activities = await _activityRepository.getAllActivities();
      final uniqueActivities = <String, ActivityLog>{};
      
      // Keep the most recent activity for each ID
      for (final activity in activities) {
        if (!uniqueActivities.containsKey(activity.id) ||
            activity.timestamp.isAfter(uniqueActivities[activity.id]!.timestamp)) {
          uniqueActivities[activity.id] = activity;
        }
      }
      
      // Clear and re-save unique activities
      await _activityRepository.clearAllActivities();
      for (final activity in uniqueActivities.values) {
        await _activityRepository.save(activity);
      }
      
      return 'Removed duplicate activity logs';
    }
    
    return null;
  }

  /// Try to restore data from the most recent backup
  Future<bool> _tryRestoreFromBackup() async {
    try {
      final backups = await _backupService.getAvailableBackups();
      if (backups.isEmpty) return false;
      
      // Get the most recent backup
      backups.sort((a, b) => b.lastModified.compareTo(a.lastModified));
      final latestBackup = backups.first;
      
      // Attempt to restore by reading and importing the backup
      final content = await latestBackup.file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final backupData = BackupData.fromJson(json);
      
      await _backupService.importData(backupData, overwrite: true);
      return true;
    } catch (e) {
      debugPrint('Failed to restore from backup: $e');
      return false;
    }
  }

  /// Create emergency backup before attempting fixes
  Future<void> createEmergencyBackup() async {
    try {
      await _backupService.createEmergencyBackup();
      debugPrint('Emergency backup created before data integrity fixes');
    } catch (e) {
      debugPrint('Failed to create emergency backup: $e');
    }
  }
}

/// Result of data integrity check
class DataIntegrityResult {
  final bool success;
  final List<DataIntegrityIssue> issues;
  final List<String> fixesApplied;
  final bool requiresUserAction;

  const DataIntegrityResult({
    required this.success,
    required this.issues,
    required this.fixesApplied,
    required this.requiresUserAction,
  });

  /// Check if there are any critical issues
  bool get hasCriticalIssues {
    return issues.any((issue) => issue.severity == DataIntegritySeverity.critical);
  }

  /// Get summary of issues by severity
  Map<DataIntegritySeverity, int> get issueSummary {
    final summary = <DataIntegritySeverity, int>{};
    for (final issue in issues) {
      summary[issue.severity] = (summary[issue.severity] ?? 0) + 1;
    }
    return summary;
  }

  @override
  String toString() {
    return 'DataIntegrityResult(success: $success, issues: ${issues.length}, fixes: ${fixesApplied.length})';
  }
}

/// Data integrity issue
class DataIntegrityIssue {
  final DataIntegrityIssueType type;
  final DataIntegritySeverity severity;
  final String description;
  final String affectedData;

  const DataIntegrityIssue({
    required this.type,
    required this.severity,
    required this.description,
    required this.affectedData,
  });

  @override
  String toString() {
    return 'DataIntegrityIssue(${severity.name}: $description)';
  }
}

/// Types of data integrity issues
enum DataIntegrityIssueType {
  missingData,
  invalidData,
  corruptedData,
  duplicateData,
  systemError,
}

/// Severity levels for data integrity issues
enum DataIntegritySeverity {
  low,
  medium,
  high,
  critical,
}