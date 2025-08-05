import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/enums.dart';
import '../models/activity_log.dart';
import '../services/system_overlay_service.dart';
import '../widgets/system_alert_dialog.dart';
import '../widgets/system_notification.dart';
import '../providers/user_provider.dart';
import '../providers/activity_provider.dart';

/// Example integration patterns for System interface components
/// Shows how to integrate notifications and dialogs into existing app flows
class SystemIntegrationExamples {
  static final SystemOverlayService _systemOverlay = SystemOverlayService();

  /// Example: Enhanced UserProvider with System notifications
  /// This shows how to modify the existing UserProvider to use System notifications
  static void integrateWithUserProvider(UserProvider userProvider) {
    // Initialize the system overlay service
    _systemOverlay.initialize();

    // Example method to enhance level up handling
    _enhancedLevelUpHandler(userProvider);
  }

  /// Enhanced level up handler with System interface
  static void _enhancedLevelUpHandler(UserProvider userProvider) {
    // This would be integrated into the UserProvider's level up logic
    // Example of what the enhanced method might look like:
    
    /*
    Future<void> handleLevelUp(BuildContext context, int newLevel, double expGained) async {
      // Show immediate notification
      _systemOverlay.showLevelUp(
        newLevel: newLevel,
        expGained: expGained.toInt(),
        onTap: () {
          // Show detailed level up dialog when notification is tapped
          SystemAlerts.showLevelUp(
            context: context,
            newLevel: newLevel,
            expGained: expGained.toInt(),
            statGains: calculateStatGainsForLevel(newLevel),
            newAbilities: getNewAbilitiesForLevel(newLevel),
          );
        },
      );

      // Also trigger achievement checks
      await checkLevelUpAchievements(newLevel);
    }
    */
  }

  /// Example: Enhanced ActivityProvider with System notifications
  static Future<void> integrateWithActivityProvider(
    ActivityProvider activityProvider,
    BuildContext context,
  ) async {
    // Example of enhanced activity logging with System notifications
    /*
    Future<void> logActivityWithSystemNotifications(
      ActivityType activityType,
      Duration duration,
      DateTime startTime,
    ) async {
      try {
        // Log the activity (existing logic)
        final result = await activityProvider.logActivity(
          activityType: activityType,
          duration: duration,
          startTime: startTime,
        );

        // Show success notification
        _systemOverlay.showActivityLogged(
          activityName: getActivityDisplayName(activityType),
          expGained: result.expGained,
          duration: duration,
          statsAffected: result.statsAffected,
        );

        // Show stat gains if significant
        if (result.statGains.isNotEmpty) {
          _systemOverlay.showMultipleStatGains(
            result.statGains,
            result.newStatValues,
          );
        }

        // Check for achievements
        await checkActivityAchievements(activityType, result);

      } catch (e) {
        // Show error notification
        _systemOverlay.showError(
          title: 'ACTIVITY LOG FAILED',
          message: 'Could not log ${getActivityDisplayName(activityType)}: $e',
        );
      }
    }
    */
  }

  /// Example: Activity deletion with confirmation dialog
  static Future<bool> confirmActivityDeletion(
    BuildContext context,
    ActivityLog activity,
  ) async {
    final confirmed = await SystemAlerts.showConfirmation(
      context: context,
      title: 'DELETE ACTIVITY',
      message: 'Are you sure you want to delete this activity?\n\n'
          'Activity: ${_getActivityDisplayName(activity.activityTypeEnum)}\n'
          'Duration: ${activity.formattedDuration}\n'
          'Date: ${_formatDate(activity.timestamp)}\n\n'
          'This will reverse any stat gains and EXP earned.\n'
          'This action cannot be undone.',
      confirmText: 'DELETE',
      cancelText: 'CANCEL',
      destructive: true,
    );

    if (confirmed == true) {
      // Show processing notification
      _systemOverlay.showInfo(
        title: 'PROCESSING',
        message: 'Deleting activity and reversing stat changes...',
      );
    }

    return confirmed ?? false;
  }

  /// Example: Stat degradation warning integration
  static void showDegradationWarning(
    BuildContext context,
    List<ActivityType> missedActivities,
    int daysMissed,
  ) {
    final activityNames = missedActivities
        .map((type) => _getActivityDisplayName(type))
        .join(', ');
    
    if (daysMissed >= 3) {
      // Critical warning - show both notification and dialog
      _systemOverlay.showDegradationWarning(
        activities: [activityNames],
        daysMissed: daysMissed,
      );

      SystemAlerts.showWarning(
        context: context,
        title: 'STAT DEGRADATION ACTIVE',
        message: 'Your stats are now degrading!\n\n'
            'Missing activities: $activityNames\n'
            'Days missed: $daysMissed\n\n'
            'Log any of these activities to stop the degradation.',
        okText: 'I UNDERSTAND',
        showCancel: false,
      );
    } else {
      // Warning notification only
      _systemOverlay.showWarning(
        title: 'DEGRADATION WARNING',
        message: 'Missing $activityNames for $daysMissed days.\n'
            'Log an activity soon to prevent stat degradation!',
      );
    }
  }

  /// Example: Achievement unlock integration
  static Future<void> showAchievementUnlock(
    BuildContext context,
    String achievementName,
    String description,
    String rewardDescription,
  ) async {
    // Show immediate notification
    _systemOverlay.showAchievement(
      achievementName: achievementName,
      description: description,
      onTap: () {
        // Show detailed dialog when notification is tapped
        SystemAlerts.showAchievement(
          context: context,
          achievementName: achievementName,
          description: description,
          rewardDescription: rewardDescription,
        );
      },
    );

    // Also show the detailed dialog immediately for important achievements
    if (_isImportantAchievement(achievementName)) {
      await Future.delayed(const Duration(milliseconds: 500));
      await SystemAlerts.showAchievement(
        context: context,
        achievementName: achievementName,
        description: description,
        rewardDescription: rewardDescription,
      );
    }
  }

  /// Example: Backup/Restore integration
  static Future<void> handleBackupOperation(
    BuildContext context,
    Future<String> Function() backupFunction,
  ) async {
    try {
      // Show processing notification
      _systemOverlay.showInfo(
        title: 'BACKUP IN PROGRESS',
        message: 'Creating backup file...',
      );

      final fileName = await backupFunction();

      // Show success notification
      _systemOverlay.showBackupComplete(fileName: fileName);

    } catch (e) {
      // Show error dialog
      await SystemAlerts.showError(
        context: context,
        title: 'BACKUP FAILED',
        message: 'Could not create backup file:\n$e\n\n'
            'Please check your storage permissions and try again.',
      );
    }
  }

  /// Example: Restore operation with confirmation
  static Future<void> handleRestoreOperation(
    BuildContext context,
    Future<int> Function() restoreFunction,
  ) async {
    final confirmed = await SystemAlerts.showConfirmation(
      context: context,
      title: 'RESTORE DATA',
      message: 'This will replace all current data with the backup.\n\n'
          'Current progress will be permanently lost.\n'
          'Are you sure you want to continue?',
      confirmText: 'RESTORE',
      cancelText: 'CANCEL',
      destructive: true,
    );

    if (confirmed != true) return;

    try {
      // Show processing notification
      _systemOverlay.showInfo(
        title: 'RESTORE IN PROGRESS',
        message: 'Restoring data from backup...',
      );

      final activitiesRestored = await restoreFunction();

      // Show success notification
      _systemOverlay.showRestoreComplete(
        activitiesRestored: activitiesRestored,
      );

    } catch (e) {
      // Show error dialog
      await SystemAlerts.showError(
        context: context,
        title: 'RESTORE FAILED',
        message: 'Could not restore data from backup:\n$e\n\n'
            'Please check the backup file and try again.',
      );
    }
  }

  /// Example: Settings change confirmations
  static Future<bool> confirmDangerousSettingChange(
    BuildContext context,
    String settingName,
    String warningMessage,
  ) async {
    return await SystemAlerts.showWarning(
      context: context,
      title: 'SETTING CHANGE WARNING',
      message: 'You are about to change: $settingName\n\n$warningMessage',
      okText: 'CONFIRM',
      cancelText: 'CANCEL',
    ) ?? false;
  }

  /// Example: Daily streak notifications
  static void checkAndShowDailyStreak(int consecutiveDays) {
    if (consecutiveDays > 0 && consecutiveDays % 7 == 0) {
      // Weekly milestone
      _systemOverlay.showDailyStreak(streakDays: consecutiveDays);
    } else if (consecutiveDays == 30 || consecutiveDays == 100 || consecutiveDays == 365) {
      // Special milestones
      _systemOverlay.showDailyStreak(streakDays: consecutiveDays);
    }
  }

  /// Example: Error handling integration
  static void handleSystemError(
    BuildContext context,
    String operation,
    dynamic error,
    {bool showDialog = false}
  ) {
    final errorMessage = 'Failed to $operation: $error';
    
    if (showDialog) {
      SystemAlerts.showError(
        context: context,
        title: 'SYSTEM ERROR',
        message: errorMessage,
      );
    } else {
      _systemOverlay.showError(
        title: 'OPERATION FAILED',
        message: errorMessage,
      );
    }
  }

  // Helper methods
  static String _getActivityDisplayName(ActivityType activityType) {
    switch (activityType) {
      case ActivityType.workoutUpperBody:
        return 'Weight Training';
      case ActivityType.workoutCardio:
        return 'Cardio Workout';
      case ActivityType.workoutYoga:
        return 'Yoga Session';
      case ActivityType.studySerious:
        return 'Serious Study';
      case ActivityType.studyCasual:
        return 'Casual Study';
      case ActivityType.meditation:
        return 'Meditation';
      case ActivityType.socializing:
        return 'Socializing';
      case ActivityType.quitBadHabit:
        return 'Quit Bad Habit';
      case ActivityType.sleepTracking:
        return 'Sleep Tracking';
      case ActivityType.dietHealthy:
        return 'Healthy Diet';
    }
  }

  static String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static bool _isImportantAchievement(String achievementName) {
    // Define which achievements should show detailed dialogs immediately
    const importantAchievements = [
      'First Level Up',
      'Hunter Awakening',
      'Shadow Monarch',
      'Legendary Status',
    ];
    return importantAchievements.contains(achievementName);
  }
}

/// Example of how to integrate System overlay into main app widget
class SystemIntegratedApp extends StatefulWidget {
  final Widget child;

  const SystemIntegratedApp({
    super.key,
    required this.child,
  });

  @override
  State<SystemIntegratedApp> createState() => _SystemIntegratedAppState();
}

class _SystemIntegratedAppState extends State<SystemIntegratedApp> {
  final SystemOverlayService _systemOverlay = SystemOverlayService();

  @override
  void initState() {
    super.initState();
    _systemOverlay.initialize();
  }

  @override
  void dispose() {
    _systemOverlay.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main app content
        widget.child,
        
        // System notification overlay
        ListenableBuilder(
          listenable: _systemOverlay,
          builder: (context, child) {
            return SystemNotificationDisplay(
              notifications: _systemOverlay.notifications,
              onNotificationDismissed: (index) {
                _systemOverlay.dismissNotification(index);
              },
            );
          },
        ),
      ],
    );
  }
}

/// Example widget showing how to use System notifications in a screen
class ExampleScreen extends StatelessWidget {
  const ExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final systemOverlay = SystemOverlayService();

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // Example: Show level up when user levels up
                systemOverlay.showLevelUp(
                  newLevel: 25,
                  expGained: 1500,
                  onTap: () {
                    // Show detailed level up dialog
                    SystemAlerts.showLevelUp(
                      context: context,
                      newLevel: 25,
                      expGained: 1500,
                      statGains: {
                        'Strength': 2.5,
                        'Agility': 1.8,
                        'Intelligence': 1.2,
                      },
                    );
                  },
                );
              },
              child: const Text('Simulate Level Up'),
            ),
            
            const SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: () async {
                // Example: Confirm dangerous action
                final confirmed = await SystemAlerts.showConfirmation(
                  context: context,
                  title: 'RESET PROGRESS',
                  message: 'This will delete all progress and cannot be undone.',
                  destructive: true,
                );
                
                if (confirmed == true) {
                  systemOverlay.showSuccess(
                    message: 'Progress reset confirmed',
                  );
                }
              },
              child: const Text('Show Confirmation Dialog'),
            ),
          ],
        ),
      ),
    );
  }
}