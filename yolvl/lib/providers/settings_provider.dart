import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/settings.dart';
import '../models/enums.dart';
import '../repositories/settings_repository.dart';

/// Provider for managing app configuration and theme settings
class SettingsProvider extends ChangeNotifier {
  final SettingsRepository _settingsRepository;
  
  Settings? _settings;
  bool _isLoading = false;
  String? _errorMessage;

  SettingsProvider({SettingsRepository? settingsRepository})
      : _settingsRepository = settingsRepository ?? SettingsRepository();

  // Getters
  Settings? get settings => _settings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Theme getters
  bool get isDarkMode => _settings?.isDarkMode ?? true;
  ThemeMode get themeMode => isDarkMode ? ThemeMode.dark : ThemeMode.light;

  // Notification getters
  bool get notificationsEnabled => _settings?.notificationsEnabled ?? true;
  int get dailyReminderHour => _settings?.dailyReminderHour ?? 20;
  int get dailyReminderMinute => _settings?.dailyReminderMinute ?? 0;
  String get formattedReminderTime => _settings?.formattedReminderTime ?? '20:00';
  bool get degradationWarningsEnabled => _settings?.degradationWarningsEnabled ?? true;

  // Activity settings getters
  List<ActivityType> get enabledActivityTypes => _settings?.enabledActivityTypes ?? ActivityType.values;
  bool get relaxedWeekendMode => _settings?.relaxedWeekendMode ?? false;

  // UI settings getters
  bool get levelUpAnimationsEnabled => _settings?.levelUpAnimationsEnabled ?? true;
  bool get hapticFeedbackEnabled => _settings?.hapticFeedbackEnabled ?? true;

  // Backup settings getters
  DateTime get lastBackupDate => _settings?.lastBackupDate ?? DateTime.now();
  bool get needsBackup => _settings?.needsBackup ?? false;

  /// Initialize settings
  Future<void> initialize() async {
    _setLoading(true);
    _clearError();

    try {
      _settings = _settingsRepository.getSettings();
      notifyListeners();
    } catch (e) {
      _setError('Failed to initialize settings: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Toggle dark mode
  Future<void> toggleDarkMode() async {
    if (_settings == null) return;

    try {
      final updatedSettings = _settings!.copyWith(isDarkMode: !_settings!.isDarkMode);
      await _updateSettings(updatedSettings);
    } catch (e) {
      _setError('Failed to toggle dark mode: $e');
    }
  }

  /// Set dark mode
  Future<void> setDarkMode(bool enabled) async {
    if (_settings == null || _settings!.isDarkMode == enabled) return;

    try {
      final updatedSettings = _settings!.copyWith(isDarkMode: enabled);
      await _updateSettings(updatedSettings);
    } catch (e) {
      _setError('Failed to set dark mode: $e');
    }
  }

  /// Toggle notifications
  Future<void> toggleNotifications() async {
    if (_settings == null) return;

    try {
      final updatedSettings = _settings!.copyWith(
        notificationsEnabled: !_settings!.notificationsEnabled,
      );
      await _updateSettings(updatedSettings);
    } catch (e) {
      _setError('Failed to toggle notifications: $e');
    }
  }

  /// Set notifications enabled
  Future<void> setNotificationsEnabled(bool enabled) async {
    if (_settings == null || _settings!.notificationsEnabled == enabled) return;

    try {
      final updatedSettings = _settings!.copyWith(notificationsEnabled: enabled);
      await _updateSettings(updatedSettings);
    } catch (e) {
      _setError('Failed to set notifications: $e');
    }
  }

  /// Set daily reminder time
  Future<void> setDailyReminderTime(int hour, int minute) async {
    if (_settings == null) return;

    try {
      final updatedSettings = _settings!.copyWith(
        dailyReminderHour: hour,
        dailyReminderMinute: minute,
      );
      await _updateSettings(updatedSettings);
    } catch (e) {
      _setError('Failed to set reminder time: $e');
    }
  }

  /// Toggle degradation warnings
  Future<void> toggleDegradationWarnings() async {
    if (_settings == null) return;

    try {
      final updatedSettings = _settings!.copyWith(
        degradationWarningsEnabled: !_settings!.degradationWarningsEnabled,
      );
      await _updateSettings(updatedSettings);
    } catch (e) {
      _setError('Failed to toggle degradation warnings: $e');
    }
  }

  /// Set activity enabled/disabled
  Future<void> setActivityEnabled(ActivityType activityType, bool enabled) async {
    if (_settings == null) return;

    try {
      final updatedSettings = _settings!.copyWith();
      updatedSettings.setActivityEnabled(activityType, enabled);
      await _updateSettings(updatedSettings);
    } catch (e) {
      _setError('Failed to set activity enabled: $e');
    }
  }

  /// Check if activity is enabled
  bool isActivityEnabled(ActivityType activityType) {
    return _settings?.isActivityEnabled(activityType) ?? true;
  }

  /// Toggle relaxed weekend mode
  Future<void> toggleRelaxedWeekendMode() async {
    if (_settings == null) return;

    try {
      final updatedSettings = _settings!.copyWith(
        relaxedWeekendMode: !_settings!.relaxedWeekendMode,
      );
      await _updateSettings(updatedSettings);
    } catch (e) {
      _setError('Failed to toggle relaxed weekend mode: $e');
    }
  }

  /// Set custom stat increment
  Future<void> setCustomStatIncrement(
    ActivityType activityType,
    StatType statType,
    double increment,
  ) async {
    if (_settings == null) return;

    try {
      final updatedSettings = _settings!.copyWith();
      updatedSettings.setCustomStatIncrement(activityType, statType, increment);
      await _updateSettings(updatedSettings);
    } catch (e) {
      _setError('Failed to set custom stat increment: $e');
    }
  }

  /// Remove custom stat increment
  Future<void> removeCustomStatIncrement(
    ActivityType activityType,
    StatType statType,
  ) async {
    if (_settings == null) return;

    try {
      final updatedSettings = _settings!.copyWith();
      updatedSettings.removeCustomStatIncrement(activityType, statType);
      await _updateSettings(updatedSettings);
    } catch (e) {
      _setError('Failed to remove custom stat increment: $e');
    }
  }

  /// Get custom stat increment
  double? getCustomStatIncrement(ActivityType activityType, StatType statType) {
    return _settings?.getCustomStatIncrement(activityType, statType);
  }

  /// Toggle level up animations
  Future<void> toggleLevelUpAnimations() async {
    if (_settings == null) return;

    try {
      final updatedSettings = _settings!.copyWith(
        levelUpAnimationsEnabled: !_settings!.levelUpAnimationsEnabled,
      );
      await _updateSettings(updatedSettings);
    } catch (e) {
      _setError('Failed to toggle level up animations: $e');
    }
  }

  /// Toggle haptic feedback
  Future<void> toggleHapticFeedback() async {
    if (_settings == null) return;

    try {
      final updatedSettings = _settings!.copyWith(
        hapticFeedbackEnabled: !_settings!.hapticFeedbackEnabled,
      );
      await _updateSettings(updatedSettings);
    } catch (e) {
      _setError('Failed to toggle haptic feedback: $e');
    }
  }

  /// Update last backup date
  Future<void> updateLastBackupDate() async {
    if (_settings == null) return;

    try {
      final updatedSettings = _settings!.copyWith(lastBackupDate: DateTime.now());
      await _updateSettings(updatedSettings);
    } catch (e) {
      _setError('Failed to update backup date: $e');
    }
  }

  /// Reset settings to defaults
  Future<void> resetToDefaults() async {
    _setLoading(true);
    _clearError();

    try {
      final defaultSettings = Settings.createDefault();
      await _updateSettings(defaultSettings);
    } catch (e) {
      _setError('Failed to reset settings: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Export settings as JSON
  Map<String, dynamic> exportSettings() {
    if (_settings == null) return {};

    return {
      'isDarkMode': _settings!.isDarkMode,
      'notificationsEnabled': _settings!.notificationsEnabled,
      'enabledActivities': _settings!.enabledActivities,
      'customStatIncrements': _settings!.customStatIncrements,
      'relaxedWeekendMode': _settings!.relaxedWeekendMode,
      'dailyReminderHour': _settings!.dailyReminderHour,
      'dailyReminderMinute': _settings!.dailyReminderMinute,
      'degradationWarningsEnabled': _settings!.degradationWarningsEnabled,
      'levelUpAnimationsEnabled': _settings!.levelUpAnimationsEnabled,
      'hapticFeedbackEnabled': _settings!.hapticFeedbackEnabled,
    };
  }

  /// Import settings from JSON
  Future<void> importSettings(Map<String, dynamic> settingsData) async {
    _setLoading(true);
    _clearError();

    try {
      final importedSettings = Settings(
        isDarkMode: settingsData['isDarkMode'] ?? true,
        notificationsEnabled: settingsData['notificationsEnabled'] ?? true,
        enabledActivities: List<String>.from(
          settingsData['enabledActivities'] ?? ActivityType.values.map((e) => e.name),
        ),
        customStatIncrements: Map<String, double>.from(
          settingsData['customStatIncrements'] ?? {},
        ),
        relaxedWeekendMode: settingsData['relaxedWeekendMode'] ?? false,
        lastBackupDate: DateTime.now(),
        dailyReminderHour: settingsData['dailyReminderHour'] ?? 20,
        dailyReminderMinute: settingsData['dailyReminderMinute'] ?? 0,
        degradationWarningsEnabled: settingsData['degradationWarningsEnabled'] ?? true,
        levelUpAnimationsEnabled: settingsData['levelUpAnimationsEnabled'] ?? true,
        hapticFeedbackEnabled: settingsData['hapticFeedbackEnabled'] ?? true,
      );

      await _updateSettings(importedSettings);
    } catch (e) {
      _setError('Failed to import settings: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Get all enabled activities as a list
  List<ActivityType> getEnabledActivities() {
    return enabledActivityTypes;
  }

  /// Get all disabled activities as a list
  List<ActivityType> getDisabledActivities() {
    final enabled = enabledActivityTypes;
    return ActivityType.values.where((type) => !enabled.contains(type)).toList();
  }

  /// Check if any custom stat increments are set
  bool hasCustomStatIncrements() {
    return _settings?.customStatIncrements.isNotEmpty ?? false;
  }

  /// Get all custom stat increments
  Map<String, double> getAllCustomStatIncrements() {
    return _settings?.customStatIncrements ?? {};
  }

  /// Clear error message
  void clearError() {
    _clearError();
  }

  // Private helper methods
  Future<void> _updateSettings(Settings newSettings) async {
    await _settingsRepository.saveSettings(newSettings);
    _settings = newSettings;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }
}