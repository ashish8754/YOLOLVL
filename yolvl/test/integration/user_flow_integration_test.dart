import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:yolvl/main.dart';
import 'package:yolvl/providers/user_provider.dart';
import 'package:yolvl/providers/activity_provider.dart';
import 'package:yolvl/providers/settings_provider.dart';
import 'package:yolvl/models/enums.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('User Flow Integration Tests', () {
    testWidgets('Complete onboarding to activity logging flow', (tester) async {
      // Start the app
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      // Should start with onboarding if first time
      expect(find.text('Welcome'), findsAtLeastOneWidget);

      // Complete onboarding questionnaire
      await _completeOnboarding(tester);

      // Should navigate to dashboard
      expect(find.text('Level 1'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // Tap FAB to log activity
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Should open activity logging screen
      expect(find.text('Log Activity'), findsAtLeastOneWidget);

      // Select activity type
      await tester.tap(find.text('Workout - Weights'));
      await tester.pumpAndSettle();

      // Enter duration
      await tester.enterText(find.byType(TextFormField), '60');
      await tester.pumpAndSettle();

      // Submit activity
      await tester.tap(find.text('Log Activity'));
      await tester.pumpAndSettle();

      // Should return to dashboard with updated stats
      expect(find.text('Level 1'), findsOneWidget);
      
      // Stats should have increased
      expect(find.textContaining('1.06'), findsAtLeastOneWidget); // Strength gain
    });

    testWidgets('Activity logging with level up flow', (tester) async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      // Skip onboarding for this test
      await _skipOnboarding(tester);

      // Log multiple activities to trigger level up
      for (int i = 0; i < 20; i++) {
        await _logActivity(tester, ActivityType.workoutUpperBody, 60);
        await tester.pumpAndSettle();
      }

      // Should have leveled up
      expect(find.text('Level 2'), findsOneWidget);
      
      // Should show level up celebration
      expect(find.textContaining('Level Up!'), findsAtLeastOneWidget);
    });

    testWidgets('Settings and theme change flow', (tester) async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      await _skipOnboarding(tester);

      // Navigate to settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Should be on settings screen
      expect(find.text('Settings'), findsOneWidget);

      // Toggle dark mode
      await tester.tap(find.text('Dark Mode'));
      await tester.pumpAndSettle();

      // Theme should change
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme?.brightness, equals(Brightness.dark));

      // Navigate back to dashboard
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Should maintain theme
      expect(find.text('Level 1'), findsOneWidget);
    });

    testWidgets('Activity history and filtering flow', (tester) async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      await _skipOnboarding(tester);

      // Log several different activities
      await _logActivity(tester, ActivityType.workoutUpperBody, 60);
      await _logActivity(tester, ActivityType.studySerious, 90);
      await _logActivity(tester, ActivityType.meditation, 30);

      // Navigate to history
      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      // Should show activity history
      expect(find.text('Activity History'), findsOneWidget);
      expect(find.text('Workout - Weights'), findsOneWidget);
      expect(find.text('Study - Serious'), findsOneWidget);
      expect(find.text('Meditation'), findsOneWidget);

      // Test filtering
      await tester.tap(find.text('Filter'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Workout'));
      await tester.pumpAndSettle();

      // Should only show workout activities
      expect(find.text('Workout - Weights'), findsOneWidget);
      expect(find.text('Study - Serious'), findsNothing);
    });

    testWidgets('Degradation warning flow', (tester) async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      await _skipOnboarding(tester);

      // Log an activity
      await _logActivity(tester, ActivityType.workoutUpperBody, 60);

      // Simulate time passing (this would require mocking DateTime)
      // For now, we'll test the UI components exist
      
      // Should show degradation warnings in dashboard
      expect(find.byIcon(Icons.warning), findsAtLeastOneWidget);
      
      // Tap warning to see details
      await tester.tap(find.byIcon(Icons.warning));
      await tester.pumpAndSettle();

      // Should show degradation details
      expect(find.textContaining('days without'), findsAtLeastOneWidget);
    });

    testWidgets('Backup and restore flow', (tester) async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      await _skipOnboarding(tester);

      // Log some activities to create data
      await _logActivity(tester, ActivityType.workoutUpperBody, 60);
      await _logActivity(tester, ActivityType.studySerious, 90);

      // Navigate to backup screen
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Backup & Restore'));
      await tester.pumpAndSettle();

      // Should be on backup screen
      expect(find.text('Backup & Restore'), findsOneWidget);

      // Test export functionality
      await tester.tap(find.text('Export Data'));
      await tester.pumpAndSettle();

      // Should show export confirmation
      expect(find.textContaining('exported'), findsAtLeastOneWidget);
    });

    testWidgets('Accessibility navigation flow', (tester) async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      await _skipOnboarding(tester);

      // Test semantic navigation
      expect(find.bySemanticsLabel('Dashboard'), findsOneWidget);
      expect(find.bySemanticsLabel('Add new activity'), findsOneWidget);

      // Test keyboard navigation
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // Should focus on next element
      expect(tester.binding.focusManager.primaryFocus, isNotNull);
    });

    testWidgets('Performance with large dataset', (tester) async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      await _skipOnboarding(tester);

      // Log many activities to test performance
      for (int i = 0; i < 100; i++) {
        await _logActivity(tester, ActivityType.workoutUpperBody, 60);
        
        // Only pump occasionally to speed up test
        if (i % 10 == 0) {
          await tester.pumpAndSettle();
        }
      }

      await tester.pumpAndSettle();

      // Should still be responsive
      expect(find.text('Level'), findsAtLeastOneWidget);
      
      // Navigate to history
      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      // Should load history efficiently
      expect(find.text('Activity History'), findsOneWidget);
    });

    testWidgets('Error recovery flow', (tester) async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      await _skipOnboarding(tester);

      // Try to log invalid activity (negative duration)
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '-10');
      await tester.tap(find.text('Log Activity'));
      await tester.pumpAndSettle();

      // Should show error message
      expect(find.textContaining('error'), findsAtLeastOneWidget);
      
      // Should remain on logging screen
      expect(find.text('Log Activity'), findsOneWidget);

      // Fix the input
      await tester.enterText(find.byType(TextFormField), '60');
      await tester.tap(find.text('Log Activity'));
      await tester.pumpAndSettle();

      // Should succeed and return to dashboard
      expect(find.text('Level 1'), findsOneWidget);
    });
  });
}

// Helper functions for common test operations

Future<void> _completeOnboarding(WidgetTester tester) async {
  // Fill out onboarding questionnaire
  final questions = [
    'Physical strength',
    'Workout frequency',
    'Agility/flexibility',
    'Study hours',
    'Mental focus',
    'Habit resistance',
    'Social charisma',
  ];

  for (final question in questions) {
    if (find.textContaining(question).evaluate().isNotEmpty) {
      await tester.tap(find.text('5')); // Select middle value
      await tester.pumpAndSettle();
    }
  }

  // Complete onboarding
  await tester.tap(find.text('Complete'));
  await tester.pumpAndSettle();
}

Future<void> _skipOnboarding(WidgetTester tester) async {
  if (find.text('Skip').evaluate().isNotEmpty) {
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
  }
}

Future<void> _logActivity(WidgetTester tester, ActivityType activityType, int duration) async {
  // Open activity logging
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();

  // Select activity type
  await tester.tap(find.text(activityType.displayName));
  await tester.pumpAndSettle();

  // Enter duration
  await tester.enterText(find.byType(TextFormField), duration.toString());
  await tester.pumpAndSettle();

  // Submit
  await tester.tap(find.text('Log Activity'));
  await tester.pumpAndSettle();
}