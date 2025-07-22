import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/user.dart';
import '../models/activity_log.dart';
import '../models/settings.dart';
import '../models/enums.dart';
import '../repositories/user_repository.dart';
import '../repositories/activity_repository.dart';
import '../repositories/settings_repository.dart';
import 'stats_service.dart';
import '../utils/infinite_stats_validator.dart';

/// Service for handling data backup and restore operations
class BackupService {
  final UserRepository _userRepository;
  final ActivityRepository _activityRepository;
  final SettingsRepository _settingsRepository;

  BackupService({
    UserRepository? userRepository,
    ActivityRepository? activityRepository,
    SettingsRepository? settingsRepository,
  })  : _userRepository = userRepository ?? UserRepository(),
        _activityRepository = activityRepository ?? ActivityRepository(),
        _settingsRepository = settingsRepository ?? SettingsRepository();

  /// Export all user data to JSON format with infinite stats validation
  Future<BackupData> exportData() async {
    try {
      // Get current user
      final user = _userRepository.getCurrentUser();
      if (user == null) {
        throw BackupException('No user data found to export');
      }

      // Validate user data before export
      _validateUserDataForExport(user);

      // Get all activity logs
      final activities = _activityRepository.findAll();

      // Validate activities before export
      _validateActivitiesForExport(activities);

      // Get settings
      final settings = _settingsRepository.getSettings();

      // Create backup data
      final backupData = BackupData(
        version: '1.1', // Updated version to support infinite stats
        exportDate: DateTime.now(),
        user: user,
        activities: activities,
        settings: settings,
      );

      _logInfo('exportData', 'Successfully exported data: ${activities.length} activities, user level ${user.level}');
      return backupData;
    } catch (e) {
      _logError('exportData', 'Failed to export data: $e');
      throw BackupException('Failed to export data: $e');
    }
  }

  /// Validate user data before export using enhanced infinite stats validation
  void _validateUserDataForExport(User user) {
    // Convert user stats to StatType map for validation
    final statsMap = <StatType, double>{};
    for (final entry in user.stats.entries) {
      try {
        final statType = StatType.values.firstWhere((st) => st.name == entry.key);
        statsMap[statType] = entry.value;
      } catch (e) {
        _logWarning('_validateUserDataForExport', 'Unknown stat type: ${entry.key}');
      }
    }

    // Use dedicated InfiniteStatsValidator for export validation
    final validationResult = InfiniteStatsValidator.validateStatsForExport(statsMap);
    
    if (!validationResult.isValid) {
      throw BackupException('Cannot export user stats: ${validationResult.message}');
    }
    
    if (validationResult.hasWarning) {
      _logWarning('_validateUserDataForExport', 'Export validation warnings: ${validationResult.warnings.join(', ')}');
    }

    // Additional validation for extremely large values that might cause issues
    for (final entry in statsMap.entries) {
      final statType = entry.key;
      final value = entry.value;
      
      // Check for values that might cause JSON serialization issues
      if (value > 1e15) { // 1 quadrillion - beyond reasonable gameplay
        throw BackupException('Cannot export: stat ${statType.name} is too large for safe export: $value');
      }
      
      // Check for precision loss in JSON serialization
      if (value.toString().length > 15) {
        _logWarning('_validateUserDataForExport', 'Stat ${statType.name} may lose precision during export: $value');
      }
    }

    // Check EXP and level with enhanced validation
    if (user.currentEXP.isNaN || user.currentEXP.isInfinite) {
      throw BackupException('Cannot export: user has invalid EXP value: ${user.currentEXP}');
    }
    
    if (user.currentEXP > 1e15) {
      throw BackupException('Cannot export: user EXP is too large for safe export: ${user.currentEXP}');
    }

    if (user.level < 1 || user.level > 1000000) {
      throw BackupException('Cannot export: user has invalid level: ${user.level}');
    }
  }

  /// Validate activities before export
  void _validateActivitiesForExport(List<ActivityLog> activities) {
    for (int i = 0; i < activities.length; i++) {
      final activity = activities[i];
      
      // Check for invalid values
      if (activity.expGained.isNaN || activity.expGained.isInfinite) {
        throw BackupException('Cannot export: activity $i has invalid EXP value: ${activity.expGained}');
      }
      
      // Check stat gains
      for (final entry in activity.statGainsMap.entries) {
        if (entry.value.isNaN || entry.value.isInfinite) {
          throw BackupException('Cannot export: activity $i has invalid stat gain for ${entry.key}: ${entry.value}');
        }
      }
    }
  }

  /// Export data to JSON string
  Future<String> exportToJson() async {
    try {
      final backupData = await exportData();
      return jsonEncode(backupData.toJson());
    } catch (e) {
      throw BackupException('Failed to export to JSON: $e');
    }
  }

  /// Save backup to device storage
  Future<File> saveBackupToDevice({String? filename}) async {
    try {
      final jsonData = await exportToJson();
      final directory = await getApplicationDocumentsDirectory();
      
      final backupFilename = filename ?? 'yolvl_backup_${_getTimestamp()}.json';
      final file = File('${directory.path}/$backupFilename');
      
      await file.writeAsString(jsonData);
      
      // Update last backup date in settings
      await _settingsRepository.updateLastBackupDate();
      
      return file;
    } catch (e) {
      throw BackupException('Failed to save backup to device: $e');
    }
  }

  /// Share backup file
  Future<void> shareBackup({String? filename}) async {
    try {
      final file = await saveBackupToDevice(filename: filename);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'YOLVL App Backup - ${DateTime.now().toIso8601String()}',
        subject: 'YOLVL Backup Export',
      );
    } catch (e) {
      throw BackupException('Failed to share backup: $e');
    }
  }

  /// Import data from JSON string
  Future<void> importFromJson(String jsonData, {bool overwrite = false}) async {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonData);
      final backupData = BackupData.fromJson(data);
      
      await importData(backupData, overwrite: overwrite);
    } catch (e) {
      throw BackupException('Failed to import from JSON: $e');
    }
  }

  /// Import data from backup file
  Future<void> importFromFile(File file, {bool overwrite = false}) async {
    try {
      final jsonData = await file.readAsString();
      await importFromJson(jsonData, overwrite: overwrite);
    } catch (e) {
      throw BackupException('Failed to import from file: $e');
    }
  }

  /// Import backup data with infinite stats support and data sanitization
  Future<void> importData(BackupData backupData, {bool overwrite = false}) async {
    try {
      // Validate backup data
      _validateBackupData(backupData);

      if (!overwrite) {
        // Check if user data already exists
        final existingUser = _userRepository.getCurrentUser();
        if (existingUser != null) {
          throw BackupException('User data already exists. Use overwrite option to replace.');
        }
      }

      // Sanitize user data before import
      final sanitizedUser = _sanitizeUserData(backupData.user);

      // Sanitize activities before import
      final sanitizedActivities = _sanitizeActivities(backupData.activities);

      // Import user data
      await _userRepository.save(sanitizedUser);

      // Import activities
      for (final activity in sanitizedActivities) {
        await _activityRepository.save(activity);
      }

      // Import settings
      await _settingsRepository.saveSettings(backupData.settings);

      _logInfo('importData', 'Successfully imported data: ${sanitizedActivities.length} activities, user level ${sanitizedUser.level}');
    } catch (e) {
      _logError('importData', 'Failed to import data: $e');
      throw BackupException('Failed to import data: $e');
    }
  }

  /// Sanitize user data for safe import with infinite stats support
  User _sanitizeUserData(User user) {
    final sanitizedStats = <String, double>{};
    
    // Sanitize each stat value
    for (final entry in user.stats.entries) {
      final statName = entry.key;
      final statValue = entry.value;
      
      if (statValue.isNaN || statValue.isInfinite) {
        _logWarning('_sanitizeUserData', 'Sanitizing invalid stat $statName: $statValue -> 1.0');
        sanitizedStats[statName] = 1.0;
      } else if (statValue < 1.0) {
        _logWarning('_sanitizeUserData', 'Sanitizing low stat $statName: $statValue -> 1.0');
        sanitizedStats[statName] = 1.0;
      } else if (statValue > 1000000) {
        _logWarning('_sanitizeUserData', 'Sanitizing extremely large stat $statName: $statValue -> 1000000');
        sanitizedStats[statName] = 1000000.0;
      } else {
        sanitizedStats[statName] = statValue;
      }
    }

    // Sanitize EXP and level
    double sanitizedEXP = user.currentEXP;
    if (sanitizedEXP.isNaN || sanitizedEXP.isInfinite || sanitizedEXP < 0) {
      _logWarning('_sanitizeUserData', 'Sanitizing invalid EXP: ${user.currentEXP} -> 0.0');
      sanitizedEXP = 0.0;
    }

    int sanitizedLevel = user.level;
    if (sanitizedLevel < 1) {
      _logWarning('_sanitizeUserData', 'Sanitizing invalid level: ${user.level} -> 1');
      sanitizedLevel = 1;
    }

    return user.copyWith(
      stats: sanitizedStats,
      currentEXP: sanitizedEXP,
      level: sanitizedLevel,
    );
  }

  /// Sanitize activities for safe import
  List<ActivityLog> _sanitizeActivities(List<ActivityLog> activities) {
    final sanitizedActivities = <ActivityLog>[];
    
    for (int i = 0; i < activities.length; i++) {
      final activity = activities[i];
      
      try {
        // Sanitize EXP gained
        double sanitizedEXP = activity.expGained;
        if (sanitizedEXP.isNaN || sanitizedEXP.isInfinite || sanitizedEXP < 0) {
          _logWarning('_sanitizeActivities', 'Sanitizing invalid EXP for activity $i: ${activity.expGained} -> 0.0');
          sanitizedEXP = 0.0;
        }

        // Sanitize stat gains
        final sanitizedStatGains = <StatType, double>{};
        for (final entry in activity.statGainsMap.entries) {
          final statType = entry.key;
          final gainValue = entry.value;
          
          if (gainValue.isNaN || gainValue.isInfinite || gainValue < 0) {
            _logWarning('_sanitizeActivities', 'Sanitizing invalid stat gain for activity $i, $statType: $gainValue -> 0.0');
            sanitizedStatGains[statType] = 0.0;
          } else if (gainValue > 1000) {
            _logWarning('_sanitizeActivities', 'Sanitizing large stat gain for activity $i, $statType: $gainValue -> 1000.0');
            sanitizedStatGains[statType] = 1000.0;
          } else {
            sanitizedStatGains[statType] = gainValue;
          }
        }

        // Create sanitized activity
        final sanitizedActivity = ActivityLog.create(
          id: activity.id,
          activityType: activity.activityTypeEnum,
          durationMinutes: activity.durationMinutes,
          statGains: sanitizedStatGains,
          expGained: sanitizedEXP,
          notes: activity.notes,
          timestamp: activity.timestamp,
        );

        sanitizedActivities.add(sanitizedActivity);
      } catch (e) {
        _logWarning('_sanitizeActivities', 'Skipping corrupted activity $i: $e');
        // Skip corrupted activities rather than failing the entire import
      }
    }
    
    return sanitizedActivities;
  }

  /// Create automatic backup
  Future<File?> createAutomaticBackup() async {
    try {
      final settings = _settingsRepository.getSettings();
      
      // Check if backup is needed
      if (!settings.needsBackup) {
        return null;
      }

      return await saveBackupToDevice(
        filename: 'yolvl_auto_backup_${_getTimestamp()}.json',
      );
    } catch (e) {
      // Don't throw for automatic backups, just log
      debugPrint('BackupService: Automatic backup failed: $e');
      return null;
    }
  }

  /// Get list of backup files in device storage
  Future<List<File>> getBackupFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync()
          .whereType<File>()
          .where((file) => file.path.contains('yolvl_backup_') && file.path.endsWith('.json'))
          .toList();
      
      // Sort by modification date (newest first)
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      
      return files;
    } catch (e) {
      throw BackupException('Failed to get backup files: $e');
    }
  }

  /// Delete backup file
  Future<void> deleteBackupFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw BackupException('Failed to delete backup file: $e');
    }
  }

  /// Validate backup data integrity with infinite stats support
  void _validateBackupData(BackupData backupData) {
    if (backupData.version.isEmpty) {
      throw BackupException('Invalid backup: missing version');
    }

    if (backupData.user.id.isEmpty) {
      throw BackupException('Invalid backup: missing user ID');
    }

    // Validate user level and EXP
    if (backupData.user.level < 1) {
      throw BackupException('Invalid backup: user level must be at least 1');
    }

    if (backupData.user.currentEXP < 0) {
      throw BackupException('Invalid backup: negative current EXP');
    }

    if (backupData.user.currentEXP.isNaN || backupData.user.currentEXP.isInfinite) {
      throw BackupException('Invalid backup: invalid current EXP value');
    }

    // Validate user stats with infinite progression support
    for (final entry in backupData.user.stats.entries) {
      final statName = entry.key;
      final statValue = entry.value;
      
      if (statValue < 1.0) {
        throw BackupException('Invalid backup: stat $statName below minimum (1.0): $statValue');
      }

      if (statValue.isNaN || statValue.isInfinite) {
        throw BackupException('Invalid backup: invalid stat value for $statName: $statValue');
      }

      // Check for extremely large values that might indicate corruption
      if (statValue > 1000000) {
        _logWarning('_validateBackupData', 'Very large stat value for $statName: $statValue');
        // Don't throw - allow large values but log warning
      }
    }

    // Validate activities
    for (int i = 0; i < backupData.activities.length; i++) {
      final activity = backupData.activities[i];
      
      if (activity.id.isEmpty) {
        throw BackupException('Invalid backup: activity $i has empty ID');
      }

      if (activity.durationMinutes < 0) {
        throw BackupException('Invalid backup: activity $i has negative duration: ${activity.durationMinutes}');
      }

      if (activity.expGained < 0) {
        throw BackupException('Invalid backup: activity $i has negative EXP: ${activity.expGained}');
      }

      if (activity.expGained.isNaN || activity.expGained.isInfinite) {
        throw BackupException('Invalid backup: activity $i has invalid EXP value: ${activity.expGained}');
      }

      // Validate stat gains if present
      if (activity.statGainsMap.isNotEmpty) {
        for (final entry in activity.statGainsMap.entries) {
          final statType = entry.key;
          final gainValue = entry.value;
          
          if (gainValue < 0) {
            throw BackupException('Invalid backup: activity $i has negative stat gain for $statType: $gainValue');
          }

          if (gainValue.isNaN || gainValue.isInfinite) {
            throw BackupException('Invalid backup: activity $i has invalid stat gain for $statType: $gainValue');
          }

          // Check for extremely large gains that might indicate corruption
          if (gainValue > 1000) {
            _logWarning('_validateBackupData', 'Very large stat gain for activity $i, $statType: $gainValue');
          }
        }
      }

      // Validate timestamp
      if (activity.timestamp.isAfter(DateTime.now().add(const Duration(hours: 1)))) {
        throw BackupException('Invalid backup: activity $i has future timestamp: ${activity.timestamp}');
      }
    }

    _logInfo('_validateBackupData', 'Backup validation completed successfully');
  }

  /// Get timestamp string for filenames
  String _getTimestamp() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
           '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
  }

  /// Get backup file info
  Future<BackupFileInfo> getBackupFileInfo(File file) async {
    try {
      final stat = await file.stat();
      final jsonData = await file.readAsString();
      final data = jsonDecode(jsonData);
      
      return BackupFileInfo(
        file: file,
        filename: file.path.split('/').last,
        size: stat.size,
        createdDate: stat.modified,
        lastModified: stat.modified,
        version: data['version'] ?? 'Unknown',
        userLevel: data['user']?['level'] ?? 0,
        activityCount: (data['activities'] as List?)?.length ?? 0,
      );
    } catch (e) {
      throw BackupException('Failed to get backup file info: $e');
    }
  }

  /// Clean up old backup files (keep only the most recent N files)
  Future<void> cleanupOldBackups({int keepCount = 5}) async {
    try {
      final backupFiles = await getBackupFiles();
      
      if (backupFiles.length > keepCount) {
        final filesToDelete = backupFiles.skip(keepCount);
        
        for (final file in filesToDelete) {
          await deleteBackupFile(file);
        }
      }
    } catch (e) {
      // Don't throw for cleanup operations
      debugPrint('BackupService: Backup cleanup failed: $e');
    }
  }

  /// Create emergency backup (for data integrity recovery)
  Future<File?> createEmergencyBackup() async {
    try {
      final backupData = await exportData();
      final backupJson = jsonEncode(backupData.toJson());
      
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups/emergency');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'emergency_backup_$timestamp.json';
      final file = File('${backupDir.path}/$filename');
      
      await file.writeAsString(backupJson);
      return file;
    } catch (e) {
      throw BackupException('Failed to create emergency backup: $e');
    }
  }

  /// Get available backups (including emergency backups)
  Future<List<BackupFileInfo>> getAvailableBackups() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups');
      
      if (!await backupDir.exists()) {
        return [];
      }
      
      final backupFiles = <BackupFileInfo>[];
      
      // Check regular backups
      final regularDir = Directory('${backupDir.path}');
      if (await regularDir.exists()) {
        await for (final entity in regularDir.list()) {
          if (entity is File && entity.path.endsWith('.json')) {
            final info = await _getBackupFileInfo(entity);
            if (info != null) {
              backupFiles.add(info);
            }
          }
        }
      }
      
      // Check emergency backups
      final emergencyDir = Directory('${backupDir.path}/emergency');
      if (await emergencyDir.exists()) {
        await for (final entity in emergencyDir.list()) {
          if (entity is File && entity.path.endsWith('.json')) {
            final info = await _getBackupFileInfo(entity);
            if (info != null) {
              backupFiles.add(info);
            }
          }
        }
      }
      
      return backupFiles;
    } catch (e) {
      throw BackupException('Failed to get available backups: $e');
    }
  }

  /// Get backup file information
  Future<BackupFileInfo?> _getBackupFileInfo(File file) async {
    try {
      final stat = await file.stat();
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      
      return BackupFileInfo(
        file: file,
        filename: file.path.split('/').last,
        size: stat.size,
        createdDate: stat.modified,
        lastModified: stat.modified,
        version: json['version'] ?? '1.0',
        userLevel: json['user']?['level'] ?? 1,
        activityCount: (json['activities'] as List?)?.length ?? 0,
      );
    } catch (e) {
      // Return null for invalid backup files
      return null;
    }
  }

  /// Log error messages with context
  void _logError(String method, String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] ERROR BackupService.$method: $message';
    debugPrint(logMessage);
  }

  /// Log warning messages with context
  void _logWarning(String method, String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] WARNING BackupService.$method: $message';
    debugPrint(logMessage);
  }

  /// Log info messages with context
  void _logInfo(String method, String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] INFO BackupService.$method: $message';
    debugPrint(logMessage);
  }
}

/// Backup data structure
class BackupData {
  final String version;
  final DateTime exportDate;
  final User user;
  final List<ActivityLog> activities;
  final Settings settings;

  const BackupData({
    required this.version,
    required this.exportDate,
    required this.user,
    required this.activities,
    required this.settings,
  });

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'exportDate': exportDate.toIso8601String(),
      'user': user.toJson(),
      'activities': activities.map((a) => a.toJson()).toList(),
      'settings': {
        'isDarkMode': settings.isDarkMode,
        'notificationsEnabled': settings.notificationsEnabled,
        'enabledActivities': settings.enabledActivities,
        'customStatIncrements': settings.customStatIncrements,
        'relaxedWeekendMode': settings.relaxedWeekendMode,
        'dailyReminderHour': settings.dailyReminderHour,
        'dailyReminderMinute': settings.dailyReminderMinute,
        'degradationWarningsEnabled': settings.degradationWarningsEnabled,
        'levelUpAnimationsEnabled': settings.levelUpAnimationsEnabled,
        'hapticFeedbackEnabled': settings.hapticFeedbackEnabled,
      },
    };
  }

  factory BackupData.fromJson(Map<String, dynamic> json) {
    return BackupData(
      version: json['version'] ?? '1.0',
      exportDate: DateTime.parse(json['exportDate']),
      user: User.fromJson(json['user']),
      activities: (json['activities'] as List)
          .map((a) => ActivityLog.fromJson(a))
          .toList(),
      settings: Settings(
        isDarkMode: json['settings']['isDarkMode'] ?? true,
        notificationsEnabled: json['settings']['notificationsEnabled'] ?? true,
        enabledActivities: List<String>.from(json['settings']['enabledActivities'] ?? []),
        customStatIncrements: Map<String, double>.from(json['settings']['customStatIncrements'] ?? {}),
        relaxedWeekendMode: json['settings']['relaxedWeekendMode'] ?? false,
        lastBackupDate: DateTime.now(),
        dailyReminderHour: json['settings']['dailyReminderHour'] ?? 20,
        dailyReminderMinute: json['settings']['dailyReminderMinute'] ?? 0,
        degradationWarningsEnabled: json['settings']['degradationWarningsEnabled'] ?? true,
        levelUpAnimationsEnabled: json['settings']['levelUpAnimationsEnabled'] ?? true,
        hapticFeedbackEnabled: json['settings']['hapticFeedbackEnabled'] ?? true,
      ),
    );
  }
}

/// Information about a backup file
class BackupFileInfo {
  final File file;
  final String filename;
  final int size;
  final DateTime createdDate;
  final DateTime lastModified;
  final String version;
  final int userLevel;
  final int activityCount;

  const BackupFileInfo({
    required this.file,
    required this.filename,
    required this.size,
    required this.createdDate,
    required this.lastModified,
    required this.version,
    required this.userLevel,
    required this.activityCount,
  });

  String get formattedSize {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  String get formattedDate {
    return '${createdDate.day}/${createdDate.month}/${createdDate.year} '
           '${createdDate.hour.toString().padLeft(2, '0')}:${createdDate.minute.toString().padLeft(2, '0')}';
  }

  /// Log error messages with context
  void _logError(String method, String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] ERROR BackupService.$method: $message';
    debugPrint(logMessage);
  }

  /// Log warning messages with context
  void _logWarning(String method, String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] WARNING BackupService.$method: $message';
    debugPrint(logMessage);
  }

  /// Log info messages with context
  void _logInfo(String method, String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] INFO BackupService.$method: $message';
    debugPrint(logMessage);
  }
}

/// Exception for backup operations
class BackupException implements Exception {
  final String message;
  
  const BackupException(this.message);
  
  @override
  String toString() => 'BackupException: $message';
}