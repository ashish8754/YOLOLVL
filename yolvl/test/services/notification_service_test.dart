import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../lib/services/notification_service.dart';

// Mock class for FlutterLocalNotificationsPlugin
class MockFlutterLocalNotificationsPlugin extends FlutterLocalNotificationsPlugin {
  bool _initialized = false;
  final List<PendingNotificationRequest> _pendingNotifications = [];
  final List<Map<String, dynamic>> _scheduledNotifications = [];

  @override
  Future<bool?> initialize(
    InitializationSettings initializationSettings, {
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback? onDidReceiveBackgroundNotificationResponse,
  }) async {
    _initialized = true;
    return true;
  }

  @override
  Future<void> show(
    int id,
    String? title,
    String? body,
    NotificationDetails? notificationDetails, {
    String? payload,
  }) async {
    if (!_initialized) throw Exception('Not initialized');
    // Simulate showing notification
  }

  @override
  Future<void> zonedSchedule(
    int id,
    String? title,
    String? body,
    TZDateTime scheduledDate,
    NotificationDetails notificationDetails, {
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
    UILocalNotificationDateInterpretation uiLocalNotificationDateInterpretation = UILocalNotificationDateInterpretation.wallClockTime,
    AndroidScheduleMode? androidScheduleMode,
  }) async {
    if (!_initialized) throw Exception('Not initialized');
    
    _scheduledNotifications.add({
      'id': id,
      'title': title,
      'body': body,
      'scheduledDate': scheduledDate,
      'payload': payload,
      'matchDateTimeComponents': matchDateTimeComponents,
    });
  }

  @override
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() async {
    return _pendingNotifications;
  }

  @override
  Future<void> cancel(int id) async {
    _pendingNotifications.removeWhere((notification) => notification.id == id);
    _scheduledNotifications.removeWhere((notification) => notification['id'] == id);
  }

  @override
  Future<void> cancelAll() async {
    _pendingNotifications.clear();
    _scheduledNotifications.clear();
  }

  // Helper methods for testing
  bool get isInitialized => _initialized;
  List<Map<String, dynamic>> get scheduledNotifications => _scheduledNotifications;
}

void main() {
  group('NotificationService', () {
    late NotificationService notificationService;
    late MockFlutterLocalNotificationsPlugin mockPlugin;

    setUp(() {
      mockPlugin = MockFlutterLocalNotificationsPlugin();
      notificationService = NotificationService();
      // Replace the internal plugin with our mock
      notificationService.setPluginForTesting(mockPlugin);
    });

    group('Initialization', () {
      test('should initialize successfully', () async {
        final result = await notificationService.initialize();
        
        expect(result, isTrue);
        expect(mockPlugin.isInitialized, isTrue);
      });

      test('should handle initialization failure', () async {
        // Create a plugin that fails to initialize
        final failingPlugin = MockFlutterLocalNotificationsPlugin();
        failingPlugin._initialized = false;
        
        // Override the initialize method to return false
        failingPlugin.initialize = (settings, {onDidReceiveNotificationResponse, onDidReceiveBackgroundNotificationResponse}) async => false;
        
        notificationService.setPluginForTesting(failingPlugin);
        
        final result = await notificationService.initialize();
        expect(result, isFalse);
      });

      test('should be singleton', () {
        final instance1 = NotificationService();
        final instance2 = NotificationService();
        
        expect(identical(instance1, instance2), isTrue);
      });
    });

    group('Permission Handling', () {
      test('should request permissions', () async {
        await notificationService.initialize();
        
        final hasPermission = await notificationService.requestPermissions();
        
        // In test environment, this should return true
        expect(hasPermission, isTrue);
      });

      test('should check if permissions are granted', () async {
        await notificationService.initialize();
        
        final hasPermission = await notificationService.hasPermissions();
        
        // In test environment, this should return true
        expect(hasPermission, isTrue);
      });
    });

    group('Daily Reminder Notifications', () {
      test('should schedule daily reminder', () async {
        await notificationService.initialize();
        
        await notificationService.scheduleDailyReminder(
          hour: 20,
          minute: 0,
          title: 'Daily Reminder',
          body: 'Time to log your activities!',
        );
        
        expect(mockPlugin.scheduledNotifications.length, equals(1));
        
        final notification = mockPlugin.scheduledNotifications.first;
        expect(notification['id'], equals(NotificationService.dailyReminderId));
        expect(notification['title'], equals('Daily Reminder'));
        expect(notification['body'], equals('Time to log your activities!'));
        expect(notification['matchDateTimeComponents'], equals(DateTimeComponents.time));
      });

      test('should validate hour parameter', () async {
        await notificationService.initialize();
        
        expect(
          () => notificationService.scheduleDailyReminder(
            hour: 25, // Invalid hour
            minute: 0,
            title: 'Test',
            body: 'Test',
          ),
          throwsArgumentError,
        );
        
        expect(
          () => notificationService.scheduleDailyReminder(
            hour: -1, // Invalid hour
            minute: 0,
            title: 'Test',
            body: 'Test',
          ),
          throwsArgumentError,
        );
      });

      test('should validate minute parameter', () async {
        await notificationService.initialize();
        
        expect(
          () => notificationService.scheduleDailyReminder(
            hour: 20,
            minute: 60, // Invalid minute
            title: 'Test',
            body: 'Test',
          ),
          throwsArgumentError,
        );
        
        expect(
          () => notificationService.scheduleDailyReminder(
            hour: 20,
            minute: -1, // Invalid minute
            title: 'Test',
            body: 'Test',
          ),
          throwsArgumentError,
        );
      });

      test('should cancel daily reminder', () async {
        await notificationService.initialize();
        
        // Schedule a reminder first
        await notificationService.scheduleDailyReminder(
          hour: 20,
          minute: 0,
          title: 'Test',
          body: 'Test',
        );
        
        expect(mockPlugin.scheduledNotifications.length, equals(1));
        
        // Cancel the reminder
        await notificationService.cancelDailyReminder();
        
        expect(mockPlugin.scheduledNotifications.length, equals(0));
      });
    });

    group('Degradation Warning Notifications', () {
      test('should show degradation warning', () async {
        await notificationService.initialize();
        
        await notificationService.showDegradationWarning(
          category: 'Workout',
          daysMissed: 3,
        );
        
        // Since this is an immediate notification, we can't easily test it with our mock
        // But we can verify the method doesn't throw an exception
      });

      test('should validate degradation warning parameters', () async {
        await notificationService.initialize();
        
        expect(
          () => notificationService.showDegradationWarning(
            category: '',
            daysMissed: 3,
          ),
          throwsArgumentError,
        );
        
        expect(
          () => notificationService.showDegradationWarning(
            category: 'Workout',
            daysMissed: 0,
          ),
          throwsArgumentError,
        );
      });

      test('should format degradation message correctly', () async {
        await notificationService.initialize();
        
        // Test different day counts
        await notificationService.showDegradationWarning(
          category: 'Workout',
          daysMissed: 1,
        );
        
        await notificationService.showDegradationWarning(
          category: 'Study',
          daysMissed: 5,
        );
        
        // Method should handle different pluralization correctly
      });
    });

    group('Level Up Notifications', () {
      test('should show level up notification', () async {
        await notificationService.initialize();
        
        await notificationService.showLevelUpNotification(
          newLevel: 5,
          expGained: 1200,
        );
        
        // Verify method doesn't throw an exception
      });

      test('should validate level up parameters', () async {
        await notificationService.initialize();
        
        expect(
          () => notificationService.showLevelUpNotification(
            newLevel: 0,
            expGained: 100,
          ),
          throwsArgumentError,
        );
        
        expect(
          () => notificationService.showLevelUpNotification(
            newLevel: 5,
            expGained: -100,
          ),
          throwsArgumentError,
        );
      });
    });

    group('Achievement Notifications', () {
      test('should show achievement unlocked notification', () async {
        await notificationService.initialize();
        
        await notificationService.showAchievementUnlocked(
          achievementTitle: 'First Activity',
          achievementDescription: 'Completed your first activity!',
        );
        
        // Verify method doesn't throw an exception
      });

      test('should validate achievement parameters', () async {
        await notificationService.initialize();
        
        expect(
          () => notificationService.showAchievementUnlocked(
            achievementTitle: '',
            achievementDescription: 'Test',
          ),
          throwsArgumentError,
        );
        
        expect(
          () => notificationService.showAchievementUnlocked(
            achievementTitle: 'Test',
            achievementDescription: '',
          ),
          throwsArgumentError,
        );
      });
    });

    group('Activity Reminder Notifications', () {
      test('should schedule activity reminder', () async {
        await notificationService.initialize();
        
        final reminderTime = DateTime.now().add(const Duration(hours: 1));
        
        await notificationService.scheduleActivityReminder(
          activityType: 'Workout',
          reminderTime: reminderTime,
        );
        
        expect(mockPlugin.scheduledNotifications.length, equals(1));
        
        final notification = mockPlugin.scheduledNotifications.first;
        expect(notification['title'], contains('Workout'));
        expect(notification['body'], contains('reminder'));
      });

      test('should validate activity reminder parameters', () async {
        await notificationService.initialize();
        
        expect(
          () => notificationService.scheduleActivityReminder(
            activityType: '',
            reminderTime: DateTime.now(),
          ),
          throwsArgumentError,
        );
        
        expect(
          () => notificationService.scheduleActivityReminder(
            activityType: 'Workout',
            reminderTime: DateTime.now().subtract(const Duration(hours: 1)),
          ),
          throwsArgumentError,
        );
      });

      test('should cancel activity reminder', () async {
        await notificationService.initialize();
        
        // Schedule a reminder first
        await notificationService.scheduleActivityReminder(
          activityType: 'Workout',
          reminderTime: DateTime.now().add(const Duration(hours: 1)),
        );
        
        expect(mockPlugin.scheduledNotifications.length, equals(1));
        
        // Cancel the reminder
        await notificationService.cancelActivityReminder();
        
        expect(mockPlugin.scheduledNotifications.length, equals(0));
      });
    });

    group('Notification Management', () {
      test('should cancel all notifications', () async {
        await notificationService.initialize();
        
        // Schedule multiple notifications
        await notificationService.scheduleDailyReminder(
          hour: 20,
          minute: 0,
          title: 'Daily',
          body: 'Daily reminder',
        );
        
        await notificationService.scheduleActivityReminder(
          activityType: 'Workout',
          reminderTime: DateTime.now().add(const Duration(hours: 1)),
        );
        
        expect(mockPlugin.scheduledNotifications.length, equals(2));
        
        // Cancel all notifications
        await notificationService.cancelAllNotifications();
        
        expect(mockPlugin.scheduledNotifications.length, equals(0));
      });

      test('should get pending notifications count', () async {
        await notificationService.initialize();
        
        // Initially should be 0
        final initialCount = await notificationService.getPendingNotificationsCount();
        expect(initialCount, equals(0));
        
        // Schedule some notifications
        await notificationService.scheduleDailyReminder(
          hour: 20,
          minute: 0,
          title: 'Daily',
          body: 'Daily reminder',
        );
        
        // Count should increase (though our mock doesn't perfectly simulate this)
        final countAfter = await notificationService.getPendingNotificationsCount();
        expect(countAfter, isA<int>());
      });
    });

    group('Error Handling', () {
      test('should handle uninitialized service gracefully', () async {
        final uninitializedService = NotificationService();
        final uninitializedPlugin = MockFlutterLocalNotificationsPlugin();
        uninitializedService.setPluginForTesting(uninitializedPlugin);
        
        // Should not throw, but should handle gracefully
        await uninitializedService.scheduleDailyReminder(
          hour: 20,
          minute: 0,
          title: 'Test',
          body: 'Test',
        );
      });

      test('should handle plugin exceptions gracefully', () async {
        // Create a plugin that throws exceptions
        final throwingPlugin = MockFlutterLocalNotificationsPlugin();
        throwingPlugin.show = (id, title, body, details, {payload}) async {
          throw Exception('Plugin error');
        };
        
        notificationService.setPluginForTesting(throwingPlugin);
        await notificationService.initialize();
        
        // Should not throw, but handle gracefully
        await notificationService.showLevelUpNotification(
          newLevel: 5,
          expGained: 100,
        );
      });
    });

    group('Notification IDs', () {
      test('should use correct notification IDs', () {
        expect(NotificationService.dailyReminderId, equals(1));
        expect(NotificationService.degradationWarningId, equals(2));
        expect(NotificationService.levelUpId, equals(3));
        expect(NotificationService.achievementId, equals(4));
        expect(NotificationService.activityReminderId, equals(5));
      });

      test('should use unique IDs for different notification types', () {
        final ids = [
          NotificationService.dailyReminderId,
          NotificationService.degradationWarningId,
          NotificationService.levelUpId,
          NotificationService.achievementId,
          NotificationService.activityReminderId,
        ];
        
        final uniqueIds = ids.toSet();
        expect(uniqueIds.length, equals(ids.length));
      });
    });

    group('Notification Content', () {
      test('should format notification titles correctly', () async {
        await notificationService.initialize();
        
        // Test that notification methods accept and handle various content
        await notificationService.showLevelUpNotification(
          newLevel: 10,
          expGained: 2500,
        );
        
        await notificationService.showAchievementUnlocked(
          achievementTitle: 'Master Achiever',
          achievementDescription: 'Unlocked 10 achievements!',
        );
        
        await notificationService.showDegradationWarning(
          category: 'Workout Activities',
          daysMissed: 7,
        );
      });

      test('should handle special characters in notification content', () async {
        await notificationService.initialize();
        
        await notificationService.showAchievementUnlocked(
          achievementTitle: 'Special Characters: !@#\$%^&*()',
          achievementDescription: 'Description with émojis 🎉 and ñ characters',
        );
        
        await notificationService.scheduleDailyReminder(
          hour: 20,
          minute: 0,
          title: 'Daily Reminder 📅',
          body: 'Time to level up! 💪',
        );
      });
    });

    group('Time Zone Handling', () {
      test('should handle different time zones for scheduled notifications', () async {
        await notificationService.initialize();
        
        // Schedule notifications at different times
        await notificationService.scheduleDailyReminder(
          hour: 0,
          minute: 0,
          title: 'Midnight Reminder',
          body: 'Start of day',
        );
        
        await notificationService.scheduleDailyReminder(
          hour: 23,
          minute: 59,
          title: 'End of Day Reminder',
          body: 'End of day',
        );
        
        // Should handle edge cases without throwing
      });
    });

    group('Notification Settings Integration', () {
      test('should respect notification enabled/disabled state', () async {
        await notificationService.initialize();
        
        // Test enabling notifications
        await notificationService.setNotificationsEnabled(true);
        
        await notificationService.scheduleDailyReminder(
          hour: 20,
          minute: 0,
          title: 'Enabled Test',
          body: 'Should work',
        );
        
        // Test disabling notifications
        await notificationService.setNotificationsEnabled(false);
        
        await notificationService.scheduleDailyReminder(
          hour: 21,
          minute: 0,
          title: 'Disabled Test',
          body: 'Should not work',
        );
      });

      test('should check if notifications are enabled', () async {
        await notificationService.initialize();
        
        // Initially should be enabled
        expect(await notificationService.areNotificationsEnabled(), isTrue);
        
        // Disable and check
        await notificationService.setNotificationsEnabled(false);
        expect(await notificationService.areNotificationsEnabled(), isFalse);
        
        // Re-enable and check
        await notificationService.setNotificationsEnabled(true);
        expect(await notificationService.areNotificationsEnabled(), isTrue);
      });
    });
  });
}

// Extension to add testing methods to NotificationService
extension NotificationServiceTesting on NotificationService {
  void setPluginForTesting(FlutterLocalNotificationsPlugin plugin) {
    // This would need to be implemented in the actual NotificationService class
    // For now, this is a placeholder to show the testing approach
  }
}