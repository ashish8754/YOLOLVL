import '../models/settings.dart';
import '../models/enums.dart';
import '../utils/hive_config.dart';
import 'base_repository.dart';

/// Repository for Settings data operations
class SettingsRepository extends BaseRepository<Settings> {
  static const String _defaultSettingsKey = 'app_settings';
  
  SettingsRepository() : super(HiveConfig.settingsBoxName);

  /// Get current app settings
  Settings getSettings() {
    try {
      final settings = findByKey(_defaultSettingsKey);
      return settings ?? _createDefaultSettings();
    } catch (e) {
      throw RepositoryException('Failed to get settings: $e');
    }
  }

  /// Save app settings
  Future<void> saveSettings(Settings settings) async {
    try {
      await box.put(_defaultSettingsKey, settings);
    } catch (e) {
      throw RepositoryException('Failed to save settings: $e');
    }
  }

  /// Update specific setting
  Future<void> updateSetting<T>(String key, T value) async {
    try {
      final settings = getSettings();
      final updatedSettings = _updateSettingValue(settings, key, value);
      await saveSettings(updatedSettings);
    } catch (e) {
      throw RepositoryException('Failed to update setting $key: $e');
    }
  }

  /// Toggle dark mode
  Future<void> toggleDarkMode() async {
    try {
      final settings = getSettings();
      final updatedSettings = settings.copyWith(isDarkMode: !settings.isDarkMode);
      await saveSettings(updatedSettings);
    } catch (e) {
      throw RepositoryException('Failed to toggle dark mode: $e');
    }
  }

  /// Toggle notifications
  Future<void> toggleNotifications() async {
    try {
      final settings = getSettings();
      final updatedSettings = settings.copyWith(notificationsEnabled: !settings.notificationsEnabled);
      await saveSettings(updatedSettings);
    } catch (e) {
      throw RepositoryException('Failed to toggle notifications: $e');
    }
  }

  /// Toggle relaxed weekend mode
  Future<void> toggleRelaxedWeekendMode() async {
    try {
      final settings = getSettings();
      final updatedSettings = settings.copyWith(relaxedWeekendMode: !settings.relaxedWeekendMode);
      await saveSettings(updatedSettings);
    } catch (e) {
      throw RepositoryException('Failed to toggle relaxed weekend mode: $e');
    }
  }

  /// Set activity enabled/disabled
  Future<void> setActivityEnabled(ActivityType activityType, bool enabled) async {
    try {
      final settings = getSettings();
      settings.setActivityEnabled(activityType, enabled);
      await saveSettings(settings);
    } catch (e) {
      throw RepositoryException('Failed to set activity enabled: $e');
    }
  }

  /// Set custom stat increment
  Future<void> setCustomStatIncrement(ActivityType activityType, StatType statType, double increment) async {
    try {
      final settings = getSettings();
      settings.setCustomStatIncrement(activityType, statType, increment);
      await saveSettings(settings);
    } catch (e) {
      throw RepositoryException('Failed to set custom stat increment: $e');
    }
  }

  /// Remove custom stat increment
  Future<void> removeCustomStatIncrement(ActivityType activityType, StatType statType) async {
    try {
      final settings = getSettings();
      settings.removeCustomStatIncrement(activityType, statType);
      await saveSettings(settings);
    } catch (e) {
      throw RepositoryException('Failed to remove custom stat increment: $e');
    }
  }

  /// Set daily reminder time
  Future<void> setReminderTime(int hour, int minute) async {
    try {
      final settings = getSettings();
      final updatedSettings = settings.copyWith(
        dailyReminderHour: hour,
        dailyReminderMinute: minute,
      );
      await saveSettings(updatedSettings);
    } catch (e) {
      throw RepositoryException('Failed to set reminder time: $e');
    }
  }

  /// Update last backup date
  Future<void> updateLastBackupDate() async {
    try {
      final settings = getSettings();
      settings.updateLastBackupDate();
      await saveSettings(settings);
    } catch (e) {
      throw RepositoryException('Failed to update last backup date: $e');
    }
  }

  /// Reset settings to default
  Future<void> resetToDefaults() async {
    try {
      final defaultSettings = Settings.createDefault();
      await saveSettings(defaultSettings);
    } catch (e) {
      throw RepositoryException('Failed to reset settings to defaults: $e');
    }
  }

  /// Export settings as Map for backup
  Map<String, dynamic> exportSettings() {
    try {
      final settings = getSettings();
      return {
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
      };
    } catch (e) {
      throw RepositoryException('Failed to export settings: $e');
    }
  }

  /// Import settings from Map (for backup restore)
  Future<void> importSettings(Map<String, dynamic> settingsData) async {
    try {
      final settings = Settings(
        isDarkMode: settingsData['isDarkMode'] ?? true,
        notificationsEnabled: settingsData['notificationsEnabled'] ?? true,
        enabledActivities: List<String>.from(settingsData['enabledActivities'] ?? 
            ActivityType.values.map((type) => type.name).toList()),
        customStatIncrements: Map<String, double>.from(settingsData['customStatIncrements'] ?? {}),
        relaxedWeekendMode: settingsData['relaxedWeekendMode'] ?? false,
        lastBackupDate: DateTime.now(),
        dailyReminderHour: settingsData['dailyReminderHour'] ?? 20,
        dailyReminderMinute: settingsData['dailyReminderMinute'] ?? 0,
        degradationWarningsEnabled: settingsData['degradationWarningsEnabled'] ?? true,
        levelUpAnimationsEnabled: settingsData['levelUpAnimationsEnabled'] ?? true,
        hapticFeedbackEnabled: settingsData['hapticFeedbackEnabled'] ?? true,
      );
      
      await saveSettings(settings);
    } catch (e) {
      throw RepositoryException('Failed to import settings: $e');
    }
  }

  /// Create default settings and save them
  Settings _createDefaultSettings() {
    try {
      final defaultSettings = Settings.createDefault();
      // Save asynchronously without waiting
      saveSettings(defaultSettings);
      return defaultSettings;
    } catch (e) {
      throw RepositoryException('Failed to create default settings: $e');
    }
  }

  /// Update a specific setting value
  Settings _updateSettingValue<T>(Settings settings, String key, T value) {
    switch (key) {
      case 'isDarkMode':
        return settings.copyWith(isDarkMode: value as bool);
      case 'notificationsEnabled':
        return settings.copyWith(notificationsEnabled: value as bool);
      case 'relaxedWeekendMode':
        return settings.copyWith(relaxedWeekendMode: value as bool);
      case 'degradationWarningsEnabled':
        return settings.copyWith(degradationWarningsEnabled: value as bool);
      case 'levelUpAnimationsEnabled':
        return settings.copyWith(levelUpAnimationsEnabled: value as bool);
      case 'hapticFeedbackEnabled':
        return settings.copyWith(hapticFeedbackEnabled: value as bool);
      case 'dailyReminderHour':
        return settings.copyWith(dailyReminderHour: value as int);
      case 'dailyReminderMinute':
        return settings.copyWith(dailyReminderMinute: value as int);
      default:
        throw RepositoryException('Unknown setting key: $key');
    }
  }

  @override
  bool validateEntity(Settings entity) {
    // Validate settings data
    if (entity.dailyReminderHour < 0 || entity.dailyReminderHour > 23) {
      return false;
    }
    if (entity.dailyReminderMinute < 0 || entity.dailyReminderMinute > 59) {
      return false;
    }
    // Validate enabled activities are valid
    for (final activityName in entity.enabledActivities) {
      try {
        ActivityType.values.firstWhere((type) => type.name == activityName);
      } catch (e) {
        return false;
      }
    }
    return true;
  }
}