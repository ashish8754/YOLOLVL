import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import '../../lib/services/backup_service.dart';
import '../../lib/models/user.dart';
import '../../lib/models/activity_log.dart';
import '../../lib/models/settings.dart';
import '../../lib/models/enums.dart';
import '../../lib/repositories/user_repository.dart';
import '../../lib/repositories/activity_repository.dart';
import '../../lib/repositories/settings_repository.dart';

void main() {
  group('BackupService', () {
    late BackupService backupService;
    late UserRepository userRepository;
    late ActivityRepository activityRepository;
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
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(ActivityLogAdapter());
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(SettingsAdapter());
      }

      // Open test boxes
      await Hive.openBox<User>('user_box');
      await Hive.openBox<ActivityLog>('activity_box');
      await Hive.openBox<Settings>('settings_box');
      
      userRepository = UserRepository();
      activityRepository = ActivityRepository();
      settingsRepository = SettingsRepository();
      backupService = BackupService(
        userRepository: userRepository,
        activityRepository: activityRepository,
        settingsRepository: settingsRepository,
      );
    });

    tearDown(() async {
      await tearDownTestHive();
    });

    group('Data Export', () {
      test('should export user data successfully', () async {
        // Create test user
        final user = await userRepository.createUser(
          id: 'test_user',
          name: 'Test User',
        );
        await userRepository.completeOnboarding(user.id, {
          StatType.strength: 2.5,
          StatType.agility: 1.8,
          StatType.endurance: 2.1,
          StatType.intelligence: 3.2,
          StatType.focus: 2.7,
          StatType.charisma: 1.9,
        });

        // Create test activity
        final activity = ActivityLog.create(
          id: 'test_activity',
          activityType: ActivityType.workoutWeights,
          durationMinutes: 60,
          statGains: {StatType.strength: 0.06, StatType.endurance: 0.04},
          expGained: 60,
        );
        await activityRepository.logActivity(activity);

        // Export data
        final backupData = await backupService.exportData();

        expect(backupData.version, equals('1.0'));
        expect(backupData.user.id, equals('test_user'));
        expect(backupData.user.name, equals('Test User'));
        expect(backupData.activities.length, equals(1));
        expect(backupData.activities.first.id, equals('test_activity'));
        expect(backupData.settings, isNotNull);
      });

      test('should throw exception when no user data exists', () async {
        expect(
          () => backupService.exportData(),
          throwsA(isA<BackupException>()),
        );
      });

      test('should export to JSON string correctly', () async {
        // Create minimal test data
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

        final jsonString = await backupService.exportToJson();

        expect(jsonString, isA<String>());
        expect(jsonString.isNotEmpty, isTrue);

        // Verify JSON is valid
        final decoded = jsonDecode(jsonString);
        expect(decoded['version'], equals('1.0'));
        expect(decoded['user']['id'], equals('test_user'));
        expect(decoded['activities'], isA<List>());
        expect(decoded['settings'], isA<Map>());
      });
    });

    group('Data Import', () {
      test('should import from JSON string successfully', () async {
        // Create test backup data
        final testBackupJson = jsonEncode({
          'version': '1.0',
          'exportDate': DateTime.now().toIso8601String(),
          'user': {
            'id': 'imported_user',
            'name': 'Imported User',
            'level': 3,
            'currentEXP': 1500.0,
            'stats': {
              'strength': 2.5,
              'agility': 1.8,
              'endurance': 2.1,
              'intelligence': 3.2,
              'focus': 2.7,
              'charisma': 1.9,
            },
            'createdAt': DateTime.now().toIso8601String(),
            'lastActive': DateTime.now().toIso8601String(),
            'hasCompletedOnboarding': true,
            'lastActivityDates': {},
          },
          'activities': [
            {
              'id': 'imported_activity',
              'activityType': 'workoutWeights',
              'durationMinutes': 90,
              'timestamp': DateTime.now().toIso8601String(),
              'statGains': {'strength': 0.09, 'endurance': 0.06},
              'expGained': 90.0,
              'notes': null,
            }
          ],
          'settings': {
            'isDarkMode': true,
            'notificationsEnabled': true,
            'enabledActivities': ['workoutWeights', 'studySerious'],
            'customStatIncrements': {},
            'relaxedWeekendMode': false,
            'dailyReminderHour': 20,
            'dailyReminderMinute': 0,
            'degradationWarningsEnabled': true,
            'levelUpAnimationsEnabled': true,
            'hapticFeedbackEnabled': true,
          },
        });

        await backupService.importFromJson(testBackupJson, overwrite: true);

        // Verify imported data
        final importedUser = userRepository.getCurrentUser();
        expect(importedUser, isNotNull);
        expect(importedUser!.id, equals('imported_user'));
        expect(importedUser.name, equals('Imported User'));
        expect(importedUser.level, equals(3));
        expect(importedUser.currentEXP, equals(1500.0));

        final activities = activityRepository.findAll();
        expect(activities.length, equals(1));
        expect(activities.first.id, equals('imported_activity'));
      });

      test('should validate backup data before import', () async {
        // Test invalid backup data
        final invalidBackupJson = jsonEncode({
          'version': '',
          'user': {
            'id': '',
            'stats': {'strength': -1.0}, // Invalid negative stat
          },
          'activities': [],
          'settings': {},
        });

        expect(
          () => backupService.importFromJson(invalidBackupJson),
          throwsA(isA<BackupException>()),
        );
      });

      test('should prevent overwrite when user exists without overwrite flag', () async {
        // Create existing user
        await userRepository.createUser(id: 'existing_user', name: 'Existing');

        final testBackupJson = jsonEncode({
          'version': '1.0',
          'exportDate': DateTime.now().toIso8601String(),
          'user': {
            'id': 'new_user',
            'name': 'New User',
            'level': 1,
            'currentEXP': 0.0,
            'stats': {
              'strength': 1.0,
              'agility': 1.0,
              'endurance': 1.0,
              'intelligence': 1.0,
              'focus': 1.0,
              'charisma': 1.0,
            },
            'createdAt': DateTime.now().toIso8601String(),
            'lastActive': DateTime.now().toIso8601String(),
            'hasCompletedOnboarding': true,
            'lastActivityDates': {},
          },
          'activities': [],
          'settings': {
            'isDarkMode': true,
            'notificationsEnabled': true,
            'enabledActivities': [],
            'customStatIncrements': {},
            'relaxedWeekendMode': false,
            'dailyReminderHour': 20,
            'dailyReminderMinute': 0,
            'degradationWarningsEnabled': true,
            'levelUpAnimationsEnabled': true,
            'hapticFeedbackEnabled': true,
          },
        });

        expect(
          () => backupService.importFromJson(testBackupJson, overwrite: false),
          throwsA(isA<BackupException>()),
        );
      });
    });

    group('Backup Data Validation', () {
      test('should validate version field', () {
        final backupData = BackupData(
          version: '',
          exportDate: DateTime.now(),
          user: User.create(id: 'test', name: 'Test'),
          activities: [],
          settings: Settings.createDefault(),
        );

        expect(
          () => backupService.importData(backupData),
          throwsA(isA<BackupException>()),
        );
      });

      test('should validate user ID', () {
        final backupData = BackupData(
          version: '1.0',
          exportDate: DateTime.now(),
          user: User.create(id: '', name: 'Test'),
          activities: [],
          settings: Settings.createDefault(),
        );

        expect(
          () => backupService.importData(backupData),
          throwsA(isA<BackupException>()),
        );
      });

      test('should validate stat values', () {
        final user = User.create(id: 'test', name: 'Test');
        user.setStat(StatType.strength, -1.0); // Invalid negative stat

        final backupData = BackupData(
          version: '1.0',
          exportDate: DateTime.now(),
          user: user,
          activities: [],
          settings: Settings.createDefault(),
        );

        expect(
          () => backupService.importData(backupData),
          throwsA(isA<BackupException>()),
        );
      });

      test('should validate activity data', () {
        final activity = ActivityLog.create(
          id: 'test',
          activityType: ActivityType.workoutWeights,
          durationMinutes: -10, // Invalid negative duration
          statGains: {},
          expGained: 60,
        );

        final backupData = BackupData(
          version: '1.0',
          exportDate: DateTime.now(),
          user: User.create(id: 'test', name: 'Test'),
          activities: [activity],
          settings: Settings.createDefault(),
        );

        expect(
          () => backupService.importData(backupData),
          throwsA(isA<BackupException>()),
        );
      });

      test('should validate EXP values', () {
        final activity = ActivityLog.create(
          id: 'test',
          activityType: ActivityType.workoutWeights,
          durationMinutes: 60,
          statGains: {},
          expGained: -10, // Invalid negative EXP
        );

        final backupData = BackupData(
          version: '1.0',
          exportDate: DateTime.now(),
          user: User.create(id: 'test', name: 'Test'),
          activities: [activity],
          settings: Settings.createDefault(),
        );

        expect(
          () => backupService.importData(backupData),
          throwsA(isA<BackupException>()),
        );
      });
    });

    group('BackupData Model', () {
      test('should serialize to JSON correctly', () {
        final user = User.create(id: 'test_user', name: 'Test User');
        user.level = 2;
        user.currentEXP = 500.0;
        user.setStat(StatType.strength, 2.5);

        final activity = ActivityLog.create(
          id: 'test_activity',
          activityType: ActivityType.workoutWeights,
          durationMinutes: 60,
          statGains: {StatType.strength: 0.06},
          expGained: 60,
        );

        final settings = Settings.createDefault();

        final backupData = BackupData(
          version: '1.0',
          exportDate: DateTime.now(),
          user: user,
          activities: [activity],
          settings: settings,
        );

        final json = backupData.toJson();

        expect(json['version'], equals('1.0'));
        expect(json['user']['id'], equals('test_user'));
        expect(json['user']['level'], equals(2));
        expect(json['activities'], isA<List>());
        expect(json['activities'].length, equals(1));
        expect(json['settings'], isA<Map>());
      });

      test('should deserialize from JSON correctly', () {
        final jsonData = {
          'version': '1.0',
          'exportDate': DateTime.now().toIso8601String(),
          'user': {
            'id': 'test_user',
            'name': 'Test User',
            'level': 2,
            'currentEXP': 500.0,
            'stats': {
              'strength': 2.5,
              'agility': 1.0,
              'endurance': 1.0,
              'intelligence': 1.0,
              'focus': 1.0,
              'charisma': 1.0,
            },
            'createdAt': DateTime.now().toIso8601String(),
            'lastActive': DateTime.now().toIso8601String(),
            'hasCompletedOnboarding': true,
            'lastActivityDates': {},
          },
          'activities': [
            {
              'id': 'test_activity',
              'activityType': 'workoutWeights',
              'durationMinutes': 60,
              'timestamp': DateTime.now().toIso8601String(),
              'statGains': {'strength': 0.06},
              'expGained': 60.0,
              'notes': null,
            }
          ],
          'settings': {
            'isDarkMode': true,
            'notificationsEnabled': true,
            'enabledActivities': [],
            'customStatIncrements': {},
            'relaxedWeekendMode': false,
            'dailyReminderHour': 20,
            'dailyReminderMinute': 0,
            'degradationWarningsEnabled': true,
            'levelUpAnimationsEnabled': true,
            'hapticFeedbackEnabled': true,
          },
        };

        final backupData = BackupData.fromJson(jsonData);

        expect(backupData.version, equals('1.0'));
        expect(backupData.user.id, equals('test_user'));
        expect(backupData.user.level, equals(2));
        expect(backupData.activities.length, equals(1));
        expect(backupData.activities.first.id, equals('test_activity'));
        expect(backupData.settings.isDarkMode, isTrue);
      });
    });

    group('BackupFileInfo', () {
      test('should format file size correctly', () {
        final info = BackupFileInfo(
          file: File('test.json'),
          filename: 'test.json',
          size: 1024,
          createdDate: DateTime.now(),
          lastModified: DateTime.now(),
          version: '1.0',
          userLevel: 5,
          activityCount: 10,
        );

        expect(info.formattedSize, equals('1.0KB'));

        final infoMB = BackupFileInfo(
          file: File('test.json'),
          filename: 'test.json',
          size: 1024 * 1024,
          createdDate: DateTime.now(),
          lastModified: DateTime.now(),
          version: '1.0',
          userLevel: 5,
          activityCount: 10,
        );

        expect(infoMB.formattedSize, equals('1.0MB'));

        final infoBytes = BackupFileInfo(
          file: File('test.json'),
          filename: 'test.json',
          size: 512,
          createdDate: DateTime.now(),
          lastModified: DateTime.now(),
          version: '1.0',
          userLevel: 5,
          activityCount: 10,
        );

        expect(infoBytes.formattedSize, equals('512B'));
      });

      test('should format date correctly', () {
        final testDate = DateTime(2025, 1, 18, 14, 30);
        final info = BackupFileInfo(
          file: File('test.json'),
          filename: 'test.json',
          size: 1024,
          createdDate: testDate,
          lastModified: testDate,
          version: '1.0',
          userLevel: 5,
          activityCount: 10,
        );

        expect(info.formattedDate, equals('18/1/2025 14:30'));
      });
    });

    group('BackupException', () {
      test('should create exception with message', () {
        final exception = BackupException('Test error message');

        expect(exception.message, equals('Test error message'));
        expect(exception.toString(), equals('BackupException: Test error message'));
      });
    });

    group('Edge Cases', () {
      test('should handle empty activity list', () async {
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

        final backupData = await backupService.exportData();

        expect(backupData.activities, isEmpty);
        expect(backupData.user.id, equals('test_user'));
      });

      test('should handle large activity datasets', () async {
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

        // Create many activities
        for (int i = 0; i < 100; i++) {
          final activity = ActivityLog.create(
            id: 'activity_$i',
            activityType: ActivityType.workoutWeights,
            durationMinutes: 60,
            statGains: {StatType.strength: 0.06},
            expGained: 60,
            timestamp: DateTime.now().subtract(Duration(days: i)),
          );
          await activityRepository.logActivity(activity);
        }

        final backupData = await backupService.exportData();

        expect(backupData.activities.length, equals(100));
        expect(backupData.user.id, equals('test_user'));
      });

      test('should handle malformed JSON gracefully', () async {
        const malformedJson = '{"invalid": json}';

        expect(
          () => backupService.importFromJson(malformedJson),
          throwsA(isA<BackupException>()),
        );
      });

      test('should handle missing required fields in JSON', () async {
        final incompleteJson = jsonEncode({
          'version': '1.0',
          // Missing user, activities, settings
        });

        expect(
          () => backupService.importFromJson(incompleteJson),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Data Integrity', () {
      test('should preserve all user stats during export/import cycle', () async {
        // Create user with specific stats
        final user = await userRepository.createUser(
          id: 'test_user',
          name: 'Test User',
        );
        await userRepository.completeOnboarding(user.id, {
          StatType.strength: 2.5,
          StatType.agility: 1.8,
          StatType.endurance: 2.1,
          StatType.intelligence: 3.2,
          StatType.focus: 2.7,
          StatType.charisma: 1.9,
        });

        // Export and re-import
        final jsonString = await backupService.exportToJson();
        
        // Clear existing data
        await userRepository.deleteByKey(user.id);
        
        // Import back
        await backupService.importFromJson(jsonString, overwrite: true);

        // Verify stats are preserved
        final importedUser = userRepository.getCurrentUser();
        expect(importedUser, isNotNull);
        expect(importedUser!.getStat(StatType.strength), closeTo(2.5, 0.001));
        expect(importedUser.getStat(StatType.agility), closeTo(1.8, 0.001));
        expect(importedUser.getStat(StatType.endurance), closeTo(2.1, 0.001));
        expect(importedUser.getStat(StatType.intelligence), closeTo(3.2, 0.001));
        expect(importedUser.getStat(StatType.focus), closeTo(2.7, 0.001));
        expect(importedUser.getStat(StatType.charisma), closeTo(1.9, 0.001));
      });

      test('should preserve activity timestamps and metadata', () async {
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

        final specificTimestamp = DateTime(2025, 1, 15, 10, 30);
        final activity = ActivityLog.create(
          id: 'test_activity',
          activityType: ActivityType.workoutWeights,
          durationMinutes: 90,
          statGains: {StatType.strength: 0.09, StatType.endurance: 0.06},
          expGained: 90,
          timestamp: specificTimestamp,
          notes: 'Test workout notes',
        );
        await activityRepository.logActivity(activity);

        // Export and re-import
        final jsonString = await backupService.exportToJson();
        
        // Clear existing data
        await activityRepository.deleteByKey(activity.id);
        
        // Import back
        await backupService.importFromJson(jsonString, overwrite: true);

        // Verify activity is preserved
        final activities = activityRepository.findAll();
        expect(activities.length, equals(1));
        
        final importedActivity = activities.first;
        expect(importedActivity.timestamp, equals(specificTimestamp));
        expect(importedActivity.durationMinutes, equals(90));
        expect(importedActivity.notes, equals('Test workout notes'));
        expect(importedActivity.statGains[StatType.strength], equals(0.09));
      });
    });
  });
}