import 'package:flutter_test/flutter_test.dart';
import 'package:yolvl/providers/activity_provider.dart';
import 'package:yolvl/models/enums.dart';

void main() {
  group('ActivityProvider Tests', () {
    late ActivityProvider activityProvider;

    setUp(() {
      activityProvider = ActivityProvider();
    });

    test('should initialize with default values', () {
      expect(activityProvider.activityHistory, isEmpty);
      expect(activityProvider.todaysActivities, isEmpty);
      expect(activityProvider.recentActivities, isEmpty);
      expect(activityProvider.activityStats, isEmpty);
      expect(activityProvider.isLoading, isFalse);
      expect(activityProvider.isLoggingActivity, isFalse);
      expect(activityProvider.errorMessage, isNull);
    });

    test('should have default activity logging values', () {
      expect(activityProvider.selectedActivityType, equals(ActivityType.workoutUpperBody));
      expect(activityProvider.selectedDuration, equals(60));
      expect(activityProvider.activityNotes, isEmpty);
      expect(activityProvider.gainPreview, isNull);
    });

    test('should update selected activity type', () {
      activityProvider.setSelectedActivityType(ActivityType.studySerious);
      expect(activityProvider.selectedActivityType, equals(ActivityType.studySerious));
    });

    test('should update selected duration', () {
      activityProvider.setSelectedDuration(90);
      expect(activityProvider.selectedDuration, equals(90));
    });

    test('should update activity notes', () {
      const testNotes = 'Test activity notes';
      activityProvider.setActivityNotes(testNotes);
      expect(activityProvider.activityNotes, equals(testNotes));
    });

    test('should reset logging form to defaults', () {
      // Change values first
      activityProvider.setSelectedActivityType(ActivityType.studySerious);
      activityProvider.setSelectedDuration(90);
      activityProvider.setActivityNotes('Test notes');
      
      // Reset form
      activityProvider.resetLoggingForm();
      
      // Check defaults are restored
      expect(activityProvider.selectedActivityType, equals(ActivityType.workoutUpperBody));
      expect(activityProvider.selectedDuration, equals(60));
      expect(activityProvider.activityNotes, isEmpty);
      expect(activityProvider.gainPreview, isNull);
    });

    test('should clear error message', () {
      activityProvider.clearError();
      expect(activityProvider.errorMessage, isNull);
    });

    test('should return empty activities for date when no history', () {
      final today = DateTime.now();
      final activities = activityProvider.getActivitiesForDate(today);
      expect(activities, isEmpty);
    });

    test('should return empty activities for this week when no history', () {
      final activities = activityProvider.getThisWeeksActivities();
      expect(activities, isEmpty);
    });

    test('should return zero EXP for today when no activities', () {
      expect(activityProvider.getTodaysEXP(), equals(0.0));
    });

    test('should return zero EXP for this week when no activities', () {
      expect(activityProvider.getThisWeeksEXP(), equals(0.0));
    });

    test('should return zero activity count for today when no activities', () {
      expect(activityProvider.getTodaysActivityCount(), equals(0));
    });

    test('should return zero activity count for this week when no activities', () {
      expect(activityProvider.getThisWeeksActivityCount(), equals(0));
    });

    test('should return null for most frequent activity when no history', () {
      expect(activityProvider.getMostFrequentActivityType(), isNull);
    });
  });
}