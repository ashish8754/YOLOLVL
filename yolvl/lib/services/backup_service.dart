import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/user.dart';
import '../models/activity_log.dart';
import '../models/settings.dart';
import '../repositories/user_repository.dart';
import '../repositories/activity_repository.dart';
import '../repositories/settings_repository.dart';

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

  /// Export all user data to JSON format
  Future<BackupData> exportData() async {
    try {
      // Get current user
      final user = _userRepository.getCurrentUser();
      if (user == null) {
        throw BackupException('No user data found to export');
      }

      // Get all activity logs
      final activities = _activityRepository.findAll();

      // Get settings
      final settings = _settingsRepository.getSettings();

      // Create backup data
      final backupData = BackupData(
        version: '1.0',
        exportDate: DateTime.now(),
        user: user,
        activities: activities,
        settings: settings,
      );

      return backupData;
    } catch (e) {
      throw BackupException('Failed to export data: $e');
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

  /// Import backup data
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

      // Import user data
      await _userRepository.save(backupData.user);

      // Import activities
      for (final activity in backupData.activities) {
        await _activityRepository.save(activity);
      }

      // Import settings
      await _settingsRepository.saveSettings(backupData.settings);

    } catch (e) {
      throw BackupException('Failed to import data: $e');
    }
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
      print('Automatic backup failed: $e');
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

  /// Validate backup data integrity
  void _validateBackupData(BackupData backupData) {
    if (backupData.version.isEmpty) {
      throw BackupException('Invalid backup: missing version');
    }

    if (backupData.user.id.isEmpty) {
      throw BackupException('Invalid backup: missing user ID');
    }

    // Validate user stats
    for (final statValue in backupData.user.stats.values) {
      if (statValue < 0) {
        throw BackupException('Invalid backup: negative stat values');
      }
    }

    // Validate activities
    for (final activity in backupData.activities) {
      if (activity.durationMinutes < 0) {
        throw BackupException('Invalid backup: negative activity duration');
      }
      if (activity.expGained < 0) {
        throw BackupException('Invalid backup: negative EXP gained');
      }
    }
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
      print('Backup cleanup failed: $e');
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
}

/// Exception for backup operations
class BackupException implements Exception {
  final String message;
  
  const BackupException(this.message);
  
  @override
  String toString() => 'BackupException: $message';
}