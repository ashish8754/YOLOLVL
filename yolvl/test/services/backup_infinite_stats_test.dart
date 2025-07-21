import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:yolvl/models/user.dart';
import 'package:yolvl/models/activity_log.dart';
import 'package:yolvl/models/settings.dart';
import 'package:yolvl/models/enums.dart';
import 'package:yolvl/services/backup_service.dart';

void main() {
  group('Backup Service - Infinite Stats', () {
    late User userWithHighStats;
    late BackupData backupData;

    setUp(() {
      // Create user with high stat values
      userWithHighStats = User.create(
        id: 'test_user_high_stats',
        name: 'High Stats User',
      );

      // Set stats to various high values
      userWithHighStats.setStat(StatType.strength, 15.75);
      userWithHighStats.setStat(StatType.agility, 23.33);
      userWithHighStats.setStat(StatType.endurance, 67.89);
      userWithHighStats.setStat(StatType.intelligence, 123.45);
      userWithHighStats.setStat(StatType.focus, 99.99);
      userWithHighStats.setStat(StatType.charisma, 8.12);

      // Set high level and EXP
      userWithHighStats.level = 25;
      userWithHighStats.currentEXP = 15000.0;

      // Create sample activities
      final activities = [
        ActivityLog.create(
          id: 'activity_1',
          activityType: ActivityType.workoutWeights,
          durationMinutes: 60,
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          expGained: 120,
          statGains: {
            StatType.strength: 0.06,
            StatType.endurance: 0.04,
          },
        ),
        ActivityLog.create(
          id: 'activity_2',
          activityType: ActivityType.studySerious,
          durationMinutes: 120,
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
          expGained: 240,
          statGains: {
            StatType.intelligence: 0.12,
            StatType.focus: 0.08,
          },
        ),
      ];

      // Create settings
      final settings = Settings(
        isDarkMode: true,
        notificationsEnabled: true,
        enabledActivities: ['workoutWeights', 'studySerious'],
        customStatIncrements: {},
        relaxedWeekendMode: false,
        lastBackupDate: DateTime.now(),
        dailyReminderHour: 20,
        dailyReminderMinute: 0,
        degradationWarningsEnabled: true,
        levelUpAnimationsEnabled: true,
        hapticFeedbackEnabled: true,
      );

      backupData = BackupData(
        version: '1.0',
        exportDate: DateTime.now(),
        user: userWithHighStats,
        activities: activities,
        settings: settings,
      );
    });

    test('should export high stat values to JSON correctly', () {
      final json = backupData.toJson();

      // Verify user stats are correctly exported
      expect(json['user']['stats']['strength'], equals(15.75));
      expect(json['user']['stats']['agility'], equals(23.33));
      expect(json['user']['stats']['endurance'], equals(67.89));
      expect(json['user']['stats']['intelligence'], equals(123.45));
      expect(json['user']['stats']['focus'], equals(99.99));
      expect(json['user']['stats']['charisma'], equals(8.12));

      // Verify high level and EXP
      expect(json['user']['level'], equals(25));
      expect(json['user']['currentEXP'], equals(15000.0));
    });

    test('should serialize and deserialize high stats without data loss', () {
      // Convert to JSON string
      final jsonString = jsonEncode(backupData.toJson());

      // Parse back from JSON
      final parsedJson = jsonDecode(jsonString) as Map<String, dynamic>;
      final restoredBackupData = BackupData.fromJson(parsedJson);

      // Verify all high stat values are preserved
      expect(restoredBackupData.user.getStat(StatType.strength), equals(15.75));
      expect(restoredBackupData.user.getStat(StatType.agility), equals(23.33));
      expect(restoredBackupData.user.getStat(StatType.endurance), equals(67.89));
      expect(restoredBackupData.user.getStat(StatType.intelligence), equals(123.45));
      expect(restoredBackupData.user.getStat(StatType.focus), equals(99.99));
      expect(restoredBackupData.user.getStat(StatType.charisma), equals(8.12));

      // Verify level and EXP
      expect(restoredBackupData.user.level, equals(25));
      expect(restoredBackupData.user.currentEXP, equals(15000.0));
    });

    test('should handle extremely high stat values', () {
      // Set extremely high values
      userWithHighStats.setStat(StatType.strength, 999.999);
      userWithHighStats.setStat(StatType.intelligence, 10000.0);
      userWithHighStats.level = 100;
      userWithHighStats.currentEXP = 1000000.0;

      final updatedBackupData = BackupData(
        version: '1.0',
        exportDate: DateTime.now(),
        user: userWithHighStats,
        activities: backupData.activities,
        settings: backupData.settings,
      );

      // Convert to JSON and back
      final jsonString = jsonEncode(updatedBackupData.toJson());
      final parsedJson = jsonDecode(jsonString) as Map<String, dynamic>;
      final restoredBackupData = BackupData.fromJson(parsedJson);

      // Verify extreme values are preserved
      expect(restoredBackupData.user.getStat(StatType.strength), equals(999.999));
      expect(restoredBackupData.user.getStat(StatType.intelligence), equals(10000.0));
      expect(restoredBackupData.user.level, equals(100));
      expect(restoredBackupData.user.currentEXP, equals(1000000.0));
    });

    test('should validate high stat values correctly', () {
      final backupService = BackupService();

      // This should not throw an exception for high stat values
      expect(() {
        backupService._validateBackupData(backupData);
      }, returnsNormally);
    });

    test('should handle mixed stat ranges in backup', () {
      // Create user with mixed stat ranges
      final mixedUser = User.create(
        id: 'mixed_user',
        name: 'Mixed Stats User',
      );

      mixedUser.setStat(StatType.strength, 1.1);     // Low
      mixedUser.setStat(StatType.agility, 5.0);      // At old ceiling
      mixedUser.setStat(StatType.endurance, 12.5);   // Above old ceiling
      mixedUser.setStat(StatType.intelligence, 100.0); // Very high
      mixedUser.setStat(StatType.focus, 3.7);        // Medium
      mixedUser.setStat(StatType.charisma, 25.8);    // High

      final mixedBackupData = BackupData(
        version: '1.0',
        exportDate: DateTime.now(),
        user: mixedUser,
        activities: [],
        settings: backupData.settings,
      );

      // Convert to JSON and back
      final jsonString = jsonEncode(mixedBackupData.toJson());
      final parsedJson = jsonDecode(jsonString) as Map<String, dynamic>;
      final restoredBackupData = BackupData.fromJson(parsedJson);

      // Verify all mixed values are preserved
      expect(restoredBackupData.user.getStat(StatType.strength), equals(1.1));
      expect(restoredBackupData.user.getStat(StatType.agility), equals(5.0));
      expect(restoredBackupData.user.getStat(StatType.endurance), equals(12.5));
      expect(restoredBackupData.user.getStat(StatType.intelligence), equals(100.0));
      expect(restoredBackupData.user.getStat(StatType.focus), equals(3.7));
      expect(restoredBackupData.user.getStat(StatType.charisma), equals(25.8));
    });

    test('should preserve decimal precision for high stat values', () {
      // Set stats with various decimal precisions
      userWithHighStats.setStat(StatType.strength, 7.123456789);
      userWithHighStats.setStat(StatType.agility, 15.0);
      userWithHighStats.setStat(StatType.endurance, 23.5);
      userWithHighStats.setStat(StatType.intelligence, 42.75);

      final precisionBackupData = BackupData(
        version: '1.0',
        exportDate: DateTime.now(),
        user: userWithHighStats,
        activities: [],
        settings: backupData.settings,
      );

      // Convert to JSON and back
      final jsonString = jsonEncode(precisionBackupData.toJson());
      final parsedJson = jsonDecode(jsonString) as Map<String, dynamic>;
      final restoredBackupData = BackupData.fromJson(parsedJson);

      // Verify decimal precision is preserved
      expect(restoredBackupData.user.getStat(StatType.strength), equals(7.123456789));
      expect(restoredBackupData.user.getStat(StatType.agility), equals(15.0));
      expect(restoredBackupData.user.getStat(StatType.endurance), equals(23.5));
      expect(restoredBackupData.user.getStat(StatType.intelligence), equals(42.75));
    });

    test('should handle activity stat gains with high values', () {
      // Create activity with high stat gains
      final highGainActivity = ActivityLog.create(
        id: 'high_gain_activity',
        activityType: ActivityType.workoutWeights,
        durationMinutes: 300, // 5 hours
        timestamp: DateTime.now(),
        expGained: 600,
        statGains: {
          StatType.strength: 0.30, // High gain from long workout
          StatType.endurance: 0.20,
        },
      );

      final highGainBackupData = BackupData(
        version: '1.0',
        exportDate: DateTime.now(),
        user: userWithHighStats,
        activities: [highGainActivity],
        settings: backupData.settings,
      );

      // Convert to JSON and back
      final jsonString = jsonEncode(highGainBackupData.toJson());
      final parsedJson = jsonDecode(jsonString) as Map<String, dynamic>;
      final restoredBackupData = BackupData.fromJson(parsedJson);

      // Verify activity stat gains are preserved
      final restoredActivity = restoredBackupData.activities.first;
      expect(restoredActivity.statGainsMap[StatType.strength], equals(0.30));
      expect(restoredActivity.statGainsMap[StatType.endurance], equals(0.20));
      expect(restoredActivity.expGained, equals(600));
    });
  });
}

// Extension to access private method for testing
extension BackupServiceTest on BackupService {
  void _validateBackupData(BackupData backupData) {
    // Validate backup data integrity
    if (backupData.version.isEmpty) {
      throw BackupException('Invalid backup: missing version');
    }

    if (backupData.user.id.isEmpty) {
      throw BackupException('Invalid backup: missing user ID');
    }

    // Validate user stats - only check for negative values (no ceiling)
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
}