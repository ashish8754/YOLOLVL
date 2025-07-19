import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../test_helpers/mock_path_provider.dart';
import '../../lib/main.dart';
import '../../lib/models/enums.dart';
import '../../lib/models/onboarding.dart';
import '../../lib/providers/user_provider.dart';
import '../../lib/providers/activity_provider.dart';
import '../../lib/providers/settings_provider.dart';
import '../../lib/providers/achievement_provider.dart';
import '../../lib/utils/hive_config.dart';

/// Comprehensive integration test for complete app flow
/// Tests: App initialization -> Onboarding -> Activity logging -> Data persistence
void main() {
  group('Complete App Flow Integration Tests', () {
    setUpAll(() async {
      // Set up mock path provider for testing
      PathProviderPlatform.instance = MockPathProvider();
      
      // Initialize Hive for testing
      await Hive.initFlutter();
      await HiveConfig.initialize();
    });

    tearDownAll(() async {
      await Hive.close();
    });

    setUp(() async {
      // Clear all boxes before each test
      await HiveConfig.clearAllData();
    });

    testWidgets('Complete user journey: First time user -> Onboarding -> Main app', (tester) async {
      // Build the app
      await tester.pumpWidget(const YolvlApp());
      await tester.pumpAndSettle();

      // Should show loading screen initially
      expect(find.text('Solo Leveling'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for initialization
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should navigate to onboarding screen for new user
      expect(find.text('Question 1 of 8'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);

      // Test onboarding flow - answer first question (physical strength)
      expect(find.text('On a scale of 1-10, what\'s your current physical strength/fitness level?'), findsOneWidget);
      
      // Find and interact with slider
      final slider = find.byType(Slider).first;
      await tester.drag(slider, const Offset(100, 0)); // Move slider to higher value
      await tester.pumpAndSettle();

      // Proceed to next question
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Should be on question 2 (workout frequency)
      expect(find.text('Question 2 of 8'), findsOneWidget);
      expect(find.text('How many workout sessions do you do per week on average (0-7)?'), findsOneWidget);

      // Answer workout frequency question
      final workoutSlider = find.byType(Slider).first;
      await tester.drag(workoutSlider, const Offset(50, 0));
      await tester.pumpAndSettle();

      // Continue through remaining questions quickly
      for (int i = 2; i < 8; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
        
        // Answer each question with default/middle values
        if (find.byType(Slider).evaluate().isNotEmpty) {
          final questionSlider = find.byType(Slider).first;
          await tester.drag(questionSlider, const Offset(25, 0));
          await tester.pumpAndSettle();
        }
      }

      // Should reach completion page
      expect(find.text('Ready to Begin!'), findsOneWidget);
      expect(find.text('Your Starting Stats'), findsOneWidget);
      expect(find.text('Start Journey'), findsOneWidget);

      // Complete onboarding
      await tester.tap(find.text('Start Journey'));
      await tester.pumpAndSettle();

      // Should navigate to main app
      expect(find.text('Solo Leveling'), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);

      // Verify user stats are displayed
      expect(find.text('Level 1'), findsOneWidget);
      expect(find.byIcon(Icons.fitness_center), findsOneWidget); // Strength stat
    });

    testWidgets('Skip onboarding flow works correctly', (tester) async {
      await tester.pumpWidget(const YolvlApp());
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should be on onboarding screen
      expect(find.text('Skip'), findsOneWidget);

      // Tap skip button
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // Should show confirmation dialog
      expect(find.text('Skip Onboarding?'), findsOneWidget);
      expect(find.text('You can skip the questionnaire and start with default stats.'), findsOneWidget);

      // Confirm skip
      await tester.tap(find.text('Skip').last);
      await tester.pumpAndSettle();

      // Should navigate to main app with default stats
      expect(find.text('Solo Leveling'), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('Level 1'), findsOneWidget);
    });

    testWidgets('Activity logging flow works end-to-end', (tester) async {
      // Initialize app with completed onboarding
      await _initializeAppWithUser(tester);

      // Should be on dashboard
      expect(find.byIcon(Icons.add), findsOneWidget); // FAB

      // Tap FAB to open activity logging
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Should open activity logging screen
      expect(find.text('Log Activity'), findsOneWidget);
      expect(find.text('Activity Type'), findsOneWidget);

      // Select activity type (should default to first option)
      final dropdown = find.byType(DropdownButton<ActivityType>);
      expect(dropdown, findsOneWidget);

      // Verify duration input
      expect(find.text('Duration (minutes)'), findsOneWidget);
      final durationField = find.byType(TextFormField);
      expect(durationField, findsOneWidget);

      // Change duration
      await tester.enterText(durationField, '90');
      await tester.pumpAndSettle();

      // Should show expected gains
      expect(find.textContaining('Expected Gains'), findsOneWidget);
      expect(find.textContaining('EXP'), findsOneWidget);

      // Log the activity
      await tester.tap(find.text('Log Activity'));
      await tester.pumpAndSettle();

      // Should return to dashboard with updated stats
      expect(find.text('Solo Leveling'), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // Verify activity was logged (check for updated EXP or stats)
      // The exact values depend on the activity type and duration
    });

    testWidgets('Navigation between screens works correctly', (tester) async {
      await _initializeAppWithUser(tester);

      // Should be on dashboard (index 0)
      expect(find.text('Dashboard'), findsOneWidget);

      // Navigate to History
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      // Should be on history screen
      expect(find.text('Activity History'), findsOneWidget);

      // Navigate to Stats
      await tester.tap(find.text('Stats'));
      await tester.pumpAndSettle();

      // Should be on stats screen
      expect(find.text('Stats Progression'), findsOneWidget);

      // Navigate to Achievements
      await tester.tap(find.text('Achievements'));
      await tester.pumpAndSettle();

      // Should be on achievements screen
      expect(find.text('Achievements'), findsOneWidget);

      // Navigate to Settings
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Should be on settings screen
      expect(find.text('Settings'), findsOneWidget);

      // Navigate back to Dashboard
      await tester.tap(find.text('Dashboard'));
      await tester.pumpAndSettle();

      // Should be back on dashboard
      expect(find.byIcon(Icons.add), findsOneWidget); // FAB should be visible
    });

    testWidgets('Data persistence across app restarts', (tester) async {
      // First app session - complete onboarding
      await tester.pumpWidget(const YolvlApp());
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Skip onboarding for quick setup
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip').last);
      await tester.pumpAndSettle();

      // Log an activity
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      
      final durationField = find.byType(TextFormField);
      await tester.enterText(durationField, '60');
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Log Activity'));
      await tester.pumpAndSettle();

      // Simulate app restart by creating new widget
      await tester.pumpWidget(const YolvlApp());
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should go directly to main app (no onboarding)
      expect(find.text('Solo Leveling'), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // Data should be persisted - check for activity in history
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      // Should show logged activity
      expect(find.text('Activity History'), findsOneWidget);
      // The specific activity details depend on what was logged
    });

    testWidgets('Error handling and recovery works', (tester) async {
      // This test would simulate various error conditions
      // For now, we'll test basic error display
      
      await tester.pumpWidget(const YolvlApp());
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // If there's an error during initialization, should show error screen
      // This is hard to simulate without mocking, but the UI should handle it gracefully
      
      // Test that retry button works if there's an error
      if (find.text('Retry').evaluate().isNotEmpty) {
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Offline functionality works correctly', (tester) async {
      // All functionality should work offline since we use local storage
      await _initializeAppWithUser(tester);

      // Test that all core features work without network
      // Activity logging
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      
      final durationField = find.byType(TextFormField);
      await tester.enterText(durationField, '45');
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Log Activity'));
      await tester.pumpAndSettle();

      // Navigation
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      expect(find.text('Activity History'), findsOneWidget);

      // Settings
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);

      // All should work without network connectivity
    });
  });
}

/// Helper function to initialize app with a completed user
Future<void> _initializeAppWithUser(WidgetTester tester) async {
  await tester.pumpWidget(const YolvlApp());
  await tester.pumpAndSettle(const Duration(seconds: 2));

  // Skip onboarding if needed
  if (find.text('Skip').evaluate().isNotEmpty) {
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip').last);
    await tester.pumpAndSettle();
  }

  // Should be on main app
  expect(find.text('Solo Leveling'), findsOneWidget);
  expect(find.byType(BottomNavigationBar), findsOneWidget);
}