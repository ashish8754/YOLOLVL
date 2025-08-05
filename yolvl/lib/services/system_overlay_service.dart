import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../widgets/system_notification.dart';

/// Service for managing system notifications overlay
/// Handles queuing, display timing, and dismissal of system notifications
class SystemOverlayService extends ChangeNotifier {
  static final SystemOverlayService _instance = SystemOverlayService._internal();
  factory SystemOverlayService() => _instance;
  SystemOverlayService._internal();

  final List<SystemNotificationData> _notifications = [];
  final int _maxSimultaneousNotifications = 3;
  Timer? _cleanupTimer;
  bool _isInitialized = false;

  /// Initialize the service
  void initialize() {
    if (_isInitialized) return;
    
    // Start periodic cleanup
    _cleanupTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _cleanupExpiredNotifications();
    });
    
    _isInitialized = true;
    debugPrint('SystemOverlayService: Initialized');
  }

  /// Dispose of the service
  @override
  void dispose() {
    _cleanupTimer?.cancel();
    _notifications.clear();
    super.dispose();
  }

  /// Get current notifications
  List<SystemNotificationData> get notifications => List.unmodifiable(_notifications);

  /// Get number of active notifications
  int get notificationCount => _notifications.length;

  /// Check if service is at capacity
  bool get isAtCapacity => _notifications.length >= _maxSimultaneousNotifications;

  /// Show a system notification
  void showNotification(SystemNotificationData notification) {
    // Remove oldest notification if at capacity
    if (isAtCapacity) {
      _notifications.removeAt(0);
    }

    // Add timestamp for tracking
    final notificationWithTimestamp = SystemNotificationData(
      title: notification.title,
      message: notification.message,
      type: notification.type,
      customIcon: notification.customIcon,
      customContent: notification.customContent,
      displayDuration: notification.displayDuration,
      onTap: notification.onTap,
      onDismiss: notification.onDismiss,
      metadata: {
        ...?notification.metadata,
        'showTime': DateTime.now(),
      },
    );

    _notifications.add(notificationWithTimestamp);
    notifyListeners();

    debugPrint('SystemOverlayService: Showing notification - ${notification.title}');
  }

  /// Show a level up notification
  void showLevelUp({
    required int newLevel,
    int? expGained,
    VoidCallback? onTap,
  }) {
    showNotification(SystemNotificationData.levelUp(
      newLevel: newLevel,
      expGained: expGained,
      onTap: onTap ?? () => debugPrint('Level up notification tapped'),
    ));
  }

  /// Show a stat gain notification
  void showStatGain({
    required String statName,
    required double gainAmount,
    required double newValue,
    VoidCallback? onTap,
  }) {
    showNotification(SystemNotificationData.statGain(
      statName: statName,
      gainAmount: gainAmount,
      newValue: newValue,
      onTap: onTap,
    ));
  }

  /// Show an achievement unlock notification
  void showAchievement({
    required String achievementName,
    required String description,
    VoidCallback? onTap,
  }) {
    showNotification(SystemNotificationData.achievement(
      achievementName: achievementName,
      description: description,
      onTap: onTap ?? () => debugPrint('Achievement notification tapped'),
    ));
  }

  /// Show a quest completion notification
  void showQuestComplete({
    required String questName,
    required int expGained,
    List<String>? statsAffected,
    VoidCallback? onTap,
  }) {
    showNotification(SystemNotificationData.questComplete(
      questName: questName,
      expGained: expGained,
      statsAffected: statsAffected,
      onTap: onTap,
    ));
  }

  /// Show a system error notification
  void showError({
    required String message,
    String title = 'SYSTEM ERROR',
    VoidCallback? onTap,
  }) {
    showNotification(SystemNotificationData.error(
      title: title,
      message: message,
      onTap: onTap,
    ));
  }

  /// Show a system warning notification
  void showWarning({
    required String message,
    String title = 'WARNING',
    VoidCallback? onTap,
  }) {
    showNotification(SystemNotificationData.warning(
      title: title,
      message: message,
      onTap: onTap,
    ));
  }

  /// Show a system info notification
  void showInfo({
    required String message,
    String title = 'SYSTEM',
    VoidCallback? onTap,
  }) {
    showNotification(SystemNotificationData.info(
      title: title,
      message: message,
      onTap: onTap,
    ));
  }

  /// Show a success notification
  void showSuccess({
    required String message,
    String title = 'SUCCESS',
    VoidCallback? onTap,
  }) {
    final successNotification = SystemNotificationData(
      title: title,
      message: message,
      type: SystemNotificationType.success,
      onTap: onTap,
    );
    showNotification(successNotification);
  }

  /// Show multiple stat gains at once (batched)
  void showMultipleStatGains(Map<String, double> statGains, Map<String, double> newValues) {
    if (statGains.isEmpty) return;

    // If only one stat, show individual notification
    if (statGains.length == 1) {
      final entry = statGains.entries.first;
      showStatGain(
        statName: entry.key,
        gainAmount: entry.value,
        newValue: newValues[entry.key] ?? 0.0,
      );
      return;
    }

    // For multiple stats, create a batched notification
    final statTexts = statGains.entries.map((entry) {
      final statName = entry.key;
      final gain = entry.value;
      final newValue = newValues[statName] ?? 0.0;
      return '$statName: +${gain.toStringAsFixed(2)} (${newValue.toStringAsFixed(2)})';
    }).join('\n');

    final batchedNotification = SystemNotificationData(
      title: 'MULTIPLE STATS INCREASED',
      message: statTexts,
      type: SystemNotificationType.statGain,
      displayDuration: const Duration(seconds: 5),
      metadata: {'stats': statGains, 'newValues': newValues},
    );

    showNotification(batchedNotification);
  }

  /// Dismiss a notification by index
  void dismissNotification(int index) {
    if (index >= 0 && index < _notifications.length) {
      final notification = _notifications[index];
      notification.onDismiss?.call();
      _notifications.removeAt(index);
      notifyListeners();
      debugPrint('SystemOverlayService: Dismissed notification at index $index');
    }
  }

  /// Dismiss all notifications
  void dismissAll() {
    for (final notification in _notifications) {
      notification.onDismiss?.call();
    }
    _notifications.clear();
    notifyListeners();
    debugPrint('SystemOverlayService: Dismissed all notifications');
  }

  /// Clean up expired notifications
  void _cleanupExpiredNotifications() {
    final now = DateTime.now();
    bool needsUpdate = false;

    _notifications.removeWhere((notification) {
      final showTime = notification.metadata?['showTime'] as DateTime?;
      if (showTime != null) {
        final elapsed = now.difference(showTime);
        if (elapsed >= notification.displayDuration) {
          notification.onDismiss?.call();
          needsUpdate = true;
          return true;
        }
      }
      return false;
    });

    if (needsUpdate) {
      notifyListeners();
    }
  }

  /// Check if a specific type of notification is already showing
  bool hasNotificationType(SystemNotificationType type) {
    return _notifications.any((notification) => notification.type == type);
  }

  /// Get count of specific notification type
  int getNotificationTypeCount(SystemNotificationType type) {
    return _notifications.where((notification) => notification.type == type).length;
  }

  /// Show a notification only if the same type isn't already showing  
  void showUniqueTypeNotification(SystemNotificationData notification) {
    if (!hasNotificationType(notification.type)) {
      showNotification(notification);
    }
  }

  /// Create a service-wide configuration
  void configure({
    int? maxSimultaneousNotifications,
  }) {
    // Note: Currently maxSimultaneousNotifications is final
    // This method is prepared for future configuration options
    debugPrint('SystemOverlayService: Configuration updated');
  }

  /// Get service statistics
  Map<String, dynamic> getStatistics() {
    final typeCount = <SystemNotificationType, int>{};
    
    for (final notification in _notifications) {
      typeCount[notification.type] = (typeCount[notification.type] ?? 0) + 1;
    }

    return {
      'activeNotifications': _notifications.length,
      'maxCapacity': _maxSimultaneousNotifications,
      'isAtCapacity': isAtCapacity,
      'typeBreakdown': typeCount,
      'isInitialized': _isInitialized,
    };
  }
}

/// Extension for easier access to the service
extension SystemOverlayServiceExtension on BuildContext {
  /// Get the system overlay service
  SystemOverlayService get systemOverlay => SystemOverlayService();
}

/// Convenience methods for common notification patterns
extension SystemOverlayConvenience on SystemOverlayService {
  /// Show activity logged notification
  void showActivityLogged({
    required String activityName,
    required int expGained,
    required Duration duration,
    List<String>? statsAffected,
  }) {
    showQuestComplete(
      questName: activityName,
      expGained: expGained,
      statsAffected: statsAffected,
      onTap: () => debugPrint('Activity logged: $activityName'),
    );
  }

  /// Show degradation warning
  void showDegradationWarning({
    required List<String> activities,
    required int daysMissed,
  }) {
    final activityText = activities.join(', ');
    showWarning(
      title: 'STAT DEGRADATION WARNING',
      message: 'Missing $activityText for $daysMissed days.\nYour stats may decline soon!',
    );
  }

  /// Show backup complete notification
  void showBackupComplete({
    required String fileName,
  }) {
    showSuccess(
      title: 'BACKUP COMPLETE',
      message: 'Data saved to $fileName',
    );
  }

  /// Show restore complete notification
  void showRestoreComplete({
    required int activitiesRestored,
  }) {
    showSuccess(
      title: 'RESTORE COMPLETE',
      message: 'Successfully restored $activitiesRestored activities',
    );
  }

  /// Show daily streak notification
  void showDailyStreak({
    required int streakDays,
  }) {
    showSuccess(
      title: 'DAILY STREAK',
      message: '$streakDays consecutive days!\nKeep up the momentum!',
    );
  }
}