import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/activity_service.dart';
import '../../lib/models/user.dart';
import '../../lib/models/activity_log.dart';
import '../../lib/models/enums.dart';

void main() {
  group('Activity Deletion Service Unit Tests', () {
    late User testUser;

    setUp(() {
      // Create test user
      testUser = User.create(id: 'test_user', name: 'Test User').copyWith(
        level: 3,
        currentEXP: 500.0,
        stats: {
          StatType.strength.name: 2.5,
          StatType.agility.name: 1.8,
          StatType.endurance.name: 3.2,
          StatType.intelligence.name: 2.1,
          StatType.focus.name: 2.8,
          StatType.charisma.name: 1.9,
        },
      );
    });

    // Note: Full service tests would require mocking repositories
    // For now, we'll test the result classes and core logic

    test('ActivityDeletionResult should format correctly', () {
      // Test success result
      final successResult = ActivityDeletionResult.success(
        deletedActivity: ActivityLog.create(
          id: 'test',
          activityType: ActivityType.workoutUpperBody,
          durationMinutes: 60,
          statGains: {StatType.strength: 0.06},
          expGained: 60.0,
        ),
        statReversals: {StatType.strength: 0.06},
        expReversed: 60.0,
        newLevel: 3,
        leveledDown: false,
      );

      expect(successResult.success, isTrue);
      expect(successResult.toString(), contains('success: true'));
      expect(successResult.toString(), contains('leveledDown: false'));
      expect(successResult.toString(), contains('newLevel: 3'));

      // Test error result
      final errorResult = ActivityDeletionResult.error('Test error');
      expect(errorResult.success, isFalse);
      expect(errorResult.toString(), contains('success: false'));
      expect(errorResult.toString(), contains('Test error'));
    });

    test('ActivityDeletionPreview should format correctly', () {
      // Test valid preview
      final validPreview = ActivityDeletionPreview(
        activity: ActivityLog.create(
          id: 'test',
          activityType: ActivityType.meditation,
          durationMinutes: 30,
          statGains: {StatType.focus: 0.025},
          expGained: 30.0,
        ),
        statReversals: {StatType.focus: 0.025},
        expToReverse: 30.0,
        willLevelDown: false,
        newLevel: 3,
        levelsLost: 0,
        isValid: true,
      );

      expect(validPreview.getStatReversalText(StatType.focus), equals('-0.03'));
      expect(validPreview.getStatReversalText(StatType.strength), equals(''));
      expect(validPreview.expReversalText, equals('-30 EXP'));
      expect(validPreview.affectedStats, contains(StatType.focus));
      expect(validPreview.toString(), contains('willLevelDown: false'));

      // Test error preview
      final errorPreview = ActivityDeletionPreview.error('Test error');
      expect(errorPreview.isValid, isFalse);
      expect(errorPreview.toString(), contains('Test error'));
    });
  });
}