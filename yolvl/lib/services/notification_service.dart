import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/settings.dart';
import '../models/enums.dart';

/// Service for managing local push notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Android initialization settings
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Request permissions for iOS
      if (Platform.isIOS) {
        await _requestIOSPermissions();
      }

      _isInitialized = true;
      debugPrint('NotificationService: Initialized successfully');
    } catch (e) {
      debugPrint('NotificationService: Failed to initialize - $e');
    }
  }

  /// Request iOS notification permissions
  Future<void> _requestIOSPermissions() async {
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse notificationResponse) {
    debugPrint('Notification tapped: ${notificationResponse.payload}');
    // Handle navigation based on payload if needed
  }

  /// Schedule daily reminder notification
  Future<void> scheduleDailyReminder(Settings settings) async {
    if (!_isInitialized || !settings.notificationsEnabled) return;

    try {
      // Cancel existing daily reminder
      await _flutterLocalNotificationsPlugin.cancel(1);

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'daily_reminder',
        'Daily Activity Reminder',
        channelDescription: 'Daily reminder to log your activities',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        categoryIdentifier: 'daily_reminder',
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        1, // Notification ID
        'Time to Level Up! 🎮',
        'Log your daily activities and continue your progression journey',
        tz.TZDateTime.from(_nextInstanceOfTime(settings.dailyReminderHour, settings.dailyReminderMinute), tz.local),
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'daily_reminder',
      );

      debugPrint('NotificationService: Daily reminder scheduled for ${settings.formattedReminderTime}');
    } catch (e) {
      debugPrint('NotificationService: Failed to schedule daily reminder - $e');
    }
  }

  /// Schedule degradation warning notification
  Future<void> scheduleDegradationWarning({
    required List<ActivityType> missedActivities,
    required int daysMissed,
  }) async {
    if (!_isInitialized) return;

    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'degradation_warning',
        'Stat Degradation Warning',
        channelDescription: 'Warnings about potential stat degradation',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFFF85149), // Warning red color
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        categoryIdentifier: 'degradation_warning',
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      final String activityNames = missedActivities
          .map((activity) => _getActivityDisplayName(activity))
          .join(', ');

      final String title = daysMissed >= 3 
          ? '⚠️ Stats Degrading!' 
          : '⏰ Degradation Warning';
      
      final String body = daysMissed >= 3
          ? 'Your stats are degrading due to $daysMissed days without $activityNames. Log an activity to stop the decline!'
          : 'You haven\'t logged $activityNames for $daysMissed days. One more day and your stats will start degrading!';

      await _flutterLocalNotificationsPlugin.show(
        2, // Notification ID
        title,
        body,
        platformChannelSpecifics,
        payload: 'degradation_warning',
      );

      debugPrint('NotificationService: Degradation warning sent for $activityNames ($daysMissed days)');
    } catch (e) {
      debugPrint('NotificationService: Failed to send degradation warning - $e');
    }
  }

  /// Send level up celebration notification
  Future<void> sendLevelUpNotification(int newLevel) async {
    if (!_isInitialized) return;

    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'level_up',
        'Level Up Celebration',
        channelDescription: 'Notifications for level up achievements',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF238636), // Success green color
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        categoryIdentifier: 'level_up',
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.show(
        3, // Notification ID
        '🎉 Level Up!',
        'Congratulations! You\'ve reached Level $newLevel. Keep up the great work!',
        platformChannelSpecifics,
        payload: 'level_up:$newLevel',
      );

      debugPrint('NotificationService: Level up notification sent for level $newLevel');
    } catch (e) {
      debugPrint('NotificationService: Failed to send level up notification - $e');
    }
  }

  /// Send activity streak notification
  Future<void> sendStreakNotification(int streakDays) async {
    if (!_isInitialized || streakDays < 7) return; // Only notify for weekly milestones

    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'streak_milestone',
        'Activity Streak Milestone',
        channelDescription: 'Notifications for activity streak achievements',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF1F6FEB), // Blue color
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        categoryIdentifier: 'streak_milestone',
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      String title;
      String body;

      if (streakDays % 30 == 0) {
        title = '🔥 Monthly Streak!';
        body = 'Amazing! You\'ve maintained a $streakDays-day activity streak. You\'re unstoppable!';
      } else if (streakDays % 7 == 0) {
        title = '🔥 Weekly Streak!';
        body = 'Great job! You\'ve kept up your activities for $streakDays days straight!';
      } else {
        return; // Only send for weekly/monthly milestones
      }

      await _flutterLocalNotificationsPlugin.show(
        4, // Notification ID
        title,
        body,
        platformChannelSpecifics,
        payload: 'streak:$streakDays',
      );

      debugPrint('NotificationService: Streak notification sent for $streakDays days');
    } catch (e) {
      debugPrint('NotificationService: Failed to send streak notification - $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) return;

    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      debugPrint('NotificationService: All notifications cancelled');
    } catch (e) {
      debugPrint('NotificationService: Failed to cancel notifications - $e');
    }
  }

  /// Cancel daily reminder notification
  Future<void> cancelDailyReminder() async {
    if (!_isInitialized) return;

    try {
      await _flutterLocalNotificationsPlugin.cancel(1);
      debugPrint('NotificationService: Daily reminder cancelled');
    } catch (e) {
      debugPrint('NotificationService: Failed to cancel daily reminder - $e');
    }
  }

  /// Get next instance of specified time
  DateTime _nextInstanceOfTime(int hour, int minute) {
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }

  /// Get display name for activity type
  String _getActivityDisplayName(ActivityType activityType) {
    switch (activityType) {
      case ActivityType.workoutUpperBody:
        return 'Upper Body Training';
      case ActivityType.workoutLowerBody:
        return 'Lower Body Training';
      case ActivityType.workoutCore:
        return 'Core Training';
      case ActivityType.workoutCardio:
        return 'Cardio';
      case ActivityType.workoutYoga:
        return 'Yoga';
      case ActivityType.walking:
        return 'Walking';
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
        return 'Healthy Eating';
    }
  }

  /// Check if notifications are supported on this platform
  bool get isSupported {
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Get pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_isInitialized) return [];
    
    try {
      return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
    } catch (e) {
      debugPrint('NotificationService: Failed to get pending notifications - $e');
      return [];
    }
  }
}