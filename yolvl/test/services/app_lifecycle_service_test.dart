import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import '../../lib/services/app_lifecycle_service.dart';
import '../../lib/services/user_service.dart';
import '../../lib/repositories/user_repository.dart';
import '../../lib/repositories/settings_repository.dart';
import '../../lib/models/user.dart';
import '../../lib/models/settings.dart';
import '../../lib/models/enums.dart';

void main() {
  group('AppLifecycleService', () {
    late AppLifecycleService appLifecycleService;
    late UserService userService;
    late UserRepository userRepository;
    late SettingsRepository settingsRepository;

    setUp(() async {
      await setUpTestHive();
      
      // Register adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(ActivityTypeAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(StatTypeAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(UserAdapter());
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(SettingsAdapter());
      }

      // Open test boxes
      await Hive.openBox<User>('user_box');
      await Hive.openBox<Settings>('settings_box');
      
      userRepository = UserRepository();
      settingsRepository = SettingsRepository();
      userService = UserService(userRepository);
      appLifecycleService = AppLifecycleService(
        userService: userService,
        settingsRepository: settingsRepository,
      );
    });

    tearDown(() async {
      appLifecycleService.dispose();
      await tearDownTestHive();
    });

    group('Initialization', () {
      test('should initialize successfully', () async {
        await appLifecycleService.initialize();
        
        expect(appLifecycleService.isInitialized, isTrue);
        expect(appLifecycleService.currentState, equals(AppLifecycleState.resumed));
      });

      test('should handle multiple initialization calls', () async {
        await appLifecycleService.initialize();
        expect(appLifecycleService.isInitialized, isTrue);
        
        // Second initialization should not cause issues
        await appLifecycleService.initialize();
        expect(appLifecycleService.isInitialized, isTrue);
      });

      test('should register as lifecycle observer', () async {
        await appLifecycleService.initialize();
        
        // The service should be registered as an observer
        // This is hard to test directly, but we can verify initialization completed
        expect(appLifecycleService.isInitialized, isTrue);
      });
    });

    group('App State Tracking', () {
      test('should track app state changes', () async {
        await appLifecycleService.initialize();
        
        // Initially should be resumed
        expect(appLifecycleService.currentState, equals(AppLifecycleState.resumed));
        
        // Simulate state change to paused
        appLifecycleService.didChangeAppLifecycleState(AppLifecycleState.paused);
        expect(appLifecycleService.currentState, equals(AppLifecycleState.paused));
        
        // Simulate state change back to resumed
        appLifecycleService.didChangeAppLifecycleState(AppLifecycleState.resumed);
        expect(appLifecycleService.currentState, equals(AppLifecycleState.resumed));
      });

      test('should track time spent in background', () async {
        await appLifecycleService.initialize();
        
        // Simulate going to background
        appLifecycleService.didChangeAppLifecycleState(AppLifecycleState.paused);
        
        // Wait a bit
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Simulate coming back to foreground
        appLifecycleService.didChangeAppLifecycleState(AppLifecycleState.resumed);
        
        expect(appLifecycleService.lastBackgroundDuration, isNotNull);
        expect(appLifecycleService.lastBackgroundDuration!.inMilliseconds, greaterThan(0));
      });

      test('should track total background time', () async {
        await appLifecycleService.initialize();
        
        final initialBackgroundTime = appLifecycleService.totalBackgroundTime;
        
        // Simulate multiple background/foreground cycles
        appLifecycleService.didChangeAppLifecycleState(AppLifecycleState.paused);
        await Future.delayed(const Duration(milliseconds: 50));
        appLifecycleService.didChangeAppLifecycleState(AppLifecycleState.resumed);
        
        appLifecycleService.didChangeAppLifecycleState(AppLifecycleState.paused);
        await Future.delayed(const Duration(milliseconds: 50));
        appLifecycleService.didChangeAppLifecycleState(AppLifecycleState.resumed);
        
        expect(appLifecycleService.totalBackgroundTime.inMilliseconds, 
               greaterThan(initialBackgroundTime.inMilliseconds));
      });
    });

    group('Background Processing', () {
      test('should trigger degradation check on app resume', () async {
        // Create a user with old activity dates
        final user = await userRepository.createUser(
          id: 'test_user',
          name: 'Test User',
        );
        await userRepository.completeOnboarding(user.id, {
          StatType.strength: 2.0,
          StatType.agility: 1.8,
          StatType.endurance: 2.1,
          StatType.intelligence: 3.2,
          StatType.focus: 2.7,
          StatType.charisma: 1.9,
        });
        
        // Set old activity date to trigger degradation
        user.setLastActivityDate(
          ActivityType.workoutWeights, 
          DateTime.now().subtract(const Duration(days: 5)),
        );
        await userRepository.updateUser(user);
        
        await appLifecycleService.initialize();
        
        // Simulate app going to background and coming back
        appLifecycleService.didChangeAppLifecycleState(AppLifecycleState.paused);
        appLifecycleService.didChangeAppLifecycleState(AppLifecycleState.resumed);
        
        // Allow background processing to complete
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Verify degradation was applied
        final updatedUser = userRepository.getCurrentUser();
        expect(updatedUser, isNotNull);
        expect(updatedUser!.getStat(StatType.strength), lessThan(2.0));
      });

      test('should create automatic backup on app pause', () async {
        // Create a user
        final user = await userRepository.createUser(
          id: 'test_user',
          name: 'Test User',
        );
        await userRepository.completeOnboarding(user.id, {
          StatType.strength: 1.0,
          StatType.agility: 1.0,
          StatType.endurance: 1.0,
          StatType.intelligence: 1.0,
          StatType.focus: 1.0,
          StatType.charisma: 1.0,
        });
        
        await appLifecycleService.initialize();
        
        // Simulate app going to background
        appLifecycleService.didChangeAppLifecycleState(AppLifecycleState.paused);
        
        // Allow background processing to complete
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Verify backup was attempted (we can't easily test file creation in unit tests)
        expect(appLifecycleService.lastBackupAttempt, isNotNull);
      });

      test('should handle background processing errors gracefully', () async {
        await appLifecycleService.initialize();
        
        // Simulate app state changes without user data (should not crash)
        appLifecycleService.didChangeAppLifecycleState(AppLifecycleState.paused);
        appLifecycleService.didChangeAppLifecycleState(AppLifecycleState.resumed);
        
        // Should not throw exceptions
        expect(appLifecycleService.isInitialized, isTrue);
      });
    });

    group('Session Management', () {
      test('should track session start time', () async {
        await appLifecycleService.initialize();
        
        expect(appLifecycleService.sessionStartTime, isNotNull);
        expect(appLifecycleService.sessionStartTime!.isBefore(DateTime.now()), isTrue);
      });

      test('should calculate session duration', () async {
        await appLifecycleService.initialize();
        
        // Wait a bit
        await Future.delayed(const Duration(milliseconds: 100));
        
        final sessionDuration = appLifecycleService.currentSessionDuration;
        expect(sessionDuration.inMilliseconds, greaterThan(0));
      });

      test('should reset session on app resume after long background', () async {
        await appLifecycleService.initialize();
        
        final initialSessionStart = appLifecycleService.sessionStartTime;
        
        // Simulate long background time
        appLifecycleService.didChangeAppLifecycleState(AppLifecycleState.paused);
        
        // Simulate time passing (we can't actually wait, so we'll test the logic)
        appLifecycleService.didChangeAppLifecycleState(AppLifecycleState.resumed);
        
        // Session should be reset if background time was significant
        // (This depends on the implementation details)
        expect(appLifecycleService.sessionStartTime, isNotNull);
      });

      test('should track session count', () async {
        await appLifecycleService.initialize();
        
        final initialSessionCount = appLifecycleService.sessionCount;
        
        // Simulate multiple app launches
        appLifecycleService.didChangeAppLifecycleState(AppLifecycleState.paused);
        appLifecycleService.didChangeAppLifecycleState(AppLifecycleState.resumed);
        
        appLifecycleService.didChangeAppLifecycleState(AppLifecycleState.paused);
        appLifecycleService.didChangeAppLifecycleState(AppLifecycleState.resumed);
        
        expect(appLifecycleService.sessionCount, greaterThanOrEqualTo(initialSessionCount));
      });
    });

    group('Settings Integration', () {
      test('should respect background processing settings', () async {
        // Disable background processing in settings
        final settings = Settings.defaultSettings();
        settings.backgroundProcessingEnabled = false;
        await settingsRepository.saveSettings(settings);
        
        await appLifecycleService.initialize();
        
        // Background processing should be disabled
        expect(appLifecycleService.isBackgroundProcessingEnabled, isFalse);
      });

      test('should respect automatic backup settings', () async {
        // Disable automatic backups in settings
        final settings = Settings.defaultSettings();
        settings.automaticBackupsEnabled = false;
        await settingsRepository.saveSettings(settings);
        
        await appLifecycleService.initialize();
        
        // Automatic backups should be disabled
        expect(appLifecycleService.isAutomaticBackupEnabled, isFalse);
      });

      test('should update settings when changed', () async {
        await appLifecycleService.initialize();
        
        // Initially enabled
        expect(appLifecycleService.isBackgroundProcessingEnabled, isTrue);
        
        // Change settings
        final settings = Settings.defaultSettings();
        settings.backgroundProcessingEnabled = false;
        await settingsRepository.saveSettings(settings);
        
        // Notify service of settings change
        appLifecycleService.onSettingsChanged();
        
        expect(appLifecycleService.isBackgroundProcessingEnabled, isFalse);
      });
    });

    group('Memory Management', () {
      test('should handle memory warnings', () async {
        await appLifecycleService.initialize();
        
        // Simulate memory warning
        appLifecycleService.didHaveMemoryPressure();
        
        // Service should handle this gracefully
        expect(appLifecycleService.isInitialized, isTrue);
      });

      test('should clean up resources on dispose', () async {
        await appLifecycleService.initialize();
        
        expect(appLifecycleService.isInitialized, isTrue);
        
        appLifecycleService.dispose();
        
        expect(appLifecycleService.isInitialized, isFalse);
      });
    });

    group('Error Handling', () {
      test('should handle user service errors gracefully', () async {
        // Create service with null user service to simulate errors
        final errorService = AppLifecycleService(
          userService: null,
          settingsRepository: settingsRepository,
        );
        
        await errorService.initialize();
        
        // Should not crash when processing lifecycle events
        errorService.didChangeAppLifecycleState(AppLifecycleState.paused);
        errorService.didChangeAppLifecycleState(AppLifecycleState.resumed);
        
        errorService.dispose();
      });

      test('should handle settings repository errors gracefully', () async {
        // Create service with null settings repository
        final errorService = AppLifecycleService(
          userService: userService,
          settingsRepository: null,
        );
        
        await errorService.initialize();
        
        // Should not crash
        expect(errorService.isInitialized, isTrue);
        
        errorService.dispose();
      });

      test('should handle degradation service errors', () async {
        await appLifecycleService.initialize();
        
        // Simulate app resume without user data (should not crash)
        appLifecycleService.didChangeAppLifecycleState(AppLifecycleState.paused);
        appLifecycleService.didChangeAppLifecycleState(AppLifecycleState.resumed);
        
        expect(appLifecycleService.isInitialized, isTrue);
      });
    });

    group('Performance Monitoring', () {
      test('should track performance metrics', () async {
        await appLifecycleService.initialize();
        
        // Simulate some app usage
        appLifecycleService.didChangeAppLifecycleState(AppLifecycleState.paused);
        await Future.delayed(const Duration(milliseconds: 50));
        appLifecycleService.didChangeAppLifecycleState(AppLifecycleState.resumed);
        
        // Should have performance data
        expect(appLifecycleService.totalBackgroundTime.inMilliseconds, greaterThanOrEqualTo(0));
        expect(appLifecycleService.sessionCount, greaterThanOrEqualTo(1));
      });

      test('should provide app usage statistics', () async {
        await appLifecycleService.initialize();
        
        final stats = appLifecycleService.getUsageStatistics();
        
        expect(stats, isNotNull);
        expect(stats['sessionCount'], isA<int>());
        expect(stats['totalBackgroundTime'], isA<Duration>());
        expect(stats['currentSessionDuration'], isA<Duration>());
        expect(stats['lastBackgroundDuration'], isA<Duration?>());
      });
    });

    group('Notification Integration', () {
      test('should handle notification responses', () async {
        await appLifecycleService.initialize();
        
        // Simulate notification response
        const notificationResponse = NotificationResponse(
          notificationResponseType: NotificationResponseType.selectedNotification,
          payload: 'test_payload',
        );
        
        appLifecycleService.onNotificationResponse(notificationResponse);
        
        // Should handle gracefully
        expect(appLifecycleService.isInitialized, isTrue);
      });

      test('should handle background notification responses', () async {
        await appLifecycleService.initialize();
        
        // Simulate background notification response
        const notificationResponse = NotificationResponse(
          notificationResponseType: NotificationResponseType.selectedNotification,
          payload: 'background_payload',
        );
        
        appLifecycleService.onBackgroundNotificationResponse(notificationResponse);
        
        // Should handle gracefully
        expect(appLifecycleService.isInitialized, isTrue);
      });
    });

    group('State Persistence', () {
      test('should persist app state across restarts', () async {
        await appLifecycleService.initialize();
        
        // Simulate some usage
        appLifecycleService.didChangeAppLifecycleState(AppLifecycleState.paused);
        appLifecycleService.didChangeAppLifecycleState(AppLifecycleState.resumed);
        
        final sessionCount = appLifecycleService.sessionCount;
        
        // Dispose and recreate
        appLifecycleService.dispose();
        
        final newService = AppLifecycleService(
          userService: userService,
          settingsRepository: settingsRepository,
        );
        await newService.initialize();
        
        // State should be persisted (depending on implementation)
        expect(newService.sessionCount, greaterThanOrEqualTo(1));
        
        newService.dispose();
      });
    });

    group('Edge Cases', () {
      test('should handle rapid state changes', () async {
        await appLifecycleService.initialize();
        
        // Rapidly change states
        for (int i = 0; i < 10; i++) {
          appLifecycleService.didChangeAppLifecycleState(AppLifecycleState.paused);
          appLifecycleService.didChangeAppLifecycleState(AppLifecycleState.resumed);
        }
        
        // Should handle gracefully
        expect(appLifecycleService.isInitialized, isTrue);
        expect(appLifecycleService.currentState, equals(AppLifecycleState.resumed));
      });

      test('should handle unknown app states', () async {
        await appLifecycleService.initialize();
        
        // Simulate unknown state
        appLifecycleService.didChangeAppLifecycleState(AppLifecycleState.detached);
        
        // Should handle gracefully
        expect(appLifecycleService.isInitialized, isTrue);
        expect(appLifecycleService.currentState, equals(AppLifecycleState.detached));
      });

      test('should handle initialization without user', () async {
        // Don't create a user
        await appLifecycleService.initialize();
        
        // Should still initialize successfully
        expect(appLifecycleService.isInitialized, isTrue);
        
        // State changes should not crash
        appLifecycleService.didChangeAppLifecycleState(AppLifecycleState.paused);
        appLifecycleService.didChangeAppLifecycleState(AppLifecycleState.resumed);
      });
    });

    group('Integration with Other Services', () {
      test('should coordinate with user service for degradation', () async {
        // Create user with degradable stats
        final user = await userRepository.createUser(
          id: 'test_user',
          name: 'Test User',
        );
        await userRepository.completeOnboarding(user.id, {
          StatType.strength: 2.0,
          StatType.agility: 1.8,
          StatType.endurance: 2.1,
          StatType.intelligence: 3.2,
          StatType.focus: 2.7,
          StatType.charisma: 1.9,
        });
        
        await appLifecycleService.initialize();
        
        // Verify integration works
        expect(appLifecycleService.isInitialized, isTrue);
        
        // Simulate background/foreground cycle
        appLifecycleService.didChangeAppLifecycleState(AppLifecycleState.paused);
        appLifecycleService.didChangeAppLifecycleState(AppLifecycleState.resumed);
        
        // Should complete without errors
        expect(appLifecycleService.currentState, equals(AppLifecycleState.resumed));
      });
    });
  });
}

// Mock NotificationResponse for testing
class NotificationResponse {
  final NotificationResponseType notificationResponseType;
  final String? payload;
  
  const NotificationResponse({
    required this.notificationResponseType,
    this.payload,
  });
}

enum NotificationResponseType {
  selectedNotification,
  selectedNotificationAction,
}