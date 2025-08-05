import 'package:hive/hive.dart';
import 'enums.dart';

part 'settings.g.dart';

/// Settings model for app configuration and user preferences
@HiveType(typeId: 4)
class Settings extends HiveObject {
  @HiveField(0)
  bool isDarkMode;

  @HiveField(1)
  bool notificationsEnabled;

  @HiveField(2)
  List<String> enabledActivities; // ActivityType.name list

  @HiveField(3)
  Map<String, double> customStatIncrements; // ActivityType.name -> StatType.name -> increment

  @HiveField(4)
  bool relaxedWeekendMode;

  @HiveField(5)
  DateTime lastBackupDate;

  @HiveField(6)
  int dailyReminderHour;

  @HiveField(7)
  int dailyReminderMinute;

  @HiveField(8)
  bool degradationWarningsEnabled;

  @HiveField(9)
  bool levelUpAnimationsEnabled;

  @HiveField(10)
  bool hapticFeedbackEnabled;

  Settings({
    required this.isDarkMode,
    required this.notificationsEnabled,
    required this.enabledActivities,
    required this.customStatIncrements,
    required this.relaxedWeekendMode,
    required this.lastBackupDate,
    required this.dailyReminderHour,
    required this.dailyReminderMinute,
    required this.degradationWarningsEnabled,
    required this.levelUpAnimationsEnabled,
    required this.hapticFeedbackEnabled,
  });

  /// Create default settings
  factory Settings.createDefault() {
    return Settings(
      isDarkMode: true,
      notificationsEnabled: true,
      enabledActivities: ActivityType.values.map((type) => type.name).toList(),
      customStatIncrements: {},
      relaxedWeekendMode: false,
      lastBackupDate: DateTime.now(),
      dailyReminderHour: 20, // 8 PM
      dailyReminderMinute: 0,
      degradationWarningsEnabled: true,
      levelUpAnimationsEnabled: true,
      hapticFeedbackEnabled: true,
    );
  }

  /// Get enabled activity types as enums
  List<ActivityType> get enabledActivityTypes {
    return enabledActivities
        .map((name) => ActivityType.values.firstWhere(
              (type) => type.name == name,
              orElse: () => ActivityType.workoutUpperBody,
            ))
        .toList();
  }

  /// Check if an activity type is enabled
  bool isActivityEnabled(ActivityType activityType) {
    return enabledActivities.contains(activityType.name);
  }

  /// Enable or disable an activity type
  void setActivityEnabled(ActivityType activityType, bool enabled) {
    if (enabled && !enabledActivities.contains(activityType.name)) {
      enabledActivities.add(activityType.name);
    } else if (!enabled && enabledActivities.contains(activityType.name)) {
      enabledActivities.remove(activityType.name);
    }
  }

  /// Get custom stat increment for activity and stat type
  double? getCustomStatIncrement(ActivityType activityType, StatType statType) {
    final key = '${activityType.name}_${statType.name}';
    return customStatIncrements[key];
  }

  /// Set custom stat increment for activity and stat type
  void setCustomStatIncrement(ActivityType activityType, StatType statType, double increment) {
    final key = '${activityType.name}_${statType.name}';
    customStatIncrements[key] = increment;
  }

  /// Remove custom stat increment for activity and stat type
  void removeCustomStatIncrement(ActivityType activityType, StatType statType) {
    final key = '${activityType.name}_${statType.name}';
    customStatIncrements.remove(key);
  }

  /// Get formatted daily reminder time
  String get formattedReminderTime {
    final hour = dailyReminderHour.toString().padLeft(2, '0');
    final minute = dailyReminderMinute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Set daily reminder time
  void setReminderTime(int hour, int minute) {
    dailyReminderHour = hour;
    dailyReminderMinute = minute;
  }

  /// Update last backup date
  void updateLastBackupDate() {
    lastBackupDate = DateTime.now();
  }

  /// Check if backup is needed (older than 7 days)
  bool get needsBackup {
    final daysSinceBackup = DateTime.now().difference(lastBackupDate).inDays;
    return daysSinceBackup >= 7;
  }

  /// Copy settings with updated values
  Settings copyWith({
    bool? isDarkMode,
    bool? notificationsEnabled,
    List<String>? enabledActivities,
    Map<String, double>? customStatIncrements,
    bool? relaxedWeekendMode,
    DateTime? lastBackupDate,
    int? dailyReminderHour,
    int? dailyReminderMinute,
    bool? degradationWarningsEnabled,
    bool? levelUpAnimationsEnabled,
    bool? hapticFeedbackEnabled,
  }) {
    return Settings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      enabledActivities: enabledActivities ?? List<String>.from(this.enabledActivities),
      customStatIncrements: customStatIncrements ?? Map<String, double>.from(this.customStatIncrements),
      relaxedWeekendMode: relaxedWeekendMode ?? this.relaxedWeekendMode,
      lastBackupDate: lastBackupDate ?? this.lastBackupDate,
      dailyReminderHour: dailyReminderHour ?? this.dailyReminderHour,
      dailyReminderMinute: dailyReminderMinute ?? this.dailyReminderMinute,
      degradationWarningsEnabled: degradationWarningsEnabled ?? this.degradationWarningsEnabled,
      levelUpAnimationsEnabled: levelUpAnimationsEnabled ?? this.levelUpAnimationsEnabled,
      hapticFeedbackEnabled: hapticFeedbackEnabled ?? this.hapticFeedbackEnabled,
    );
  }

  @override
  String toString() {
    return 'Settings(darkMode: $isDarkMode, notifications: $notificationsEnabled, relaxedWeekend: $relaxedWeekendMode)';
  }
}