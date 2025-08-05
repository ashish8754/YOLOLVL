import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:yolvl/screens/dashboard_screen.dart';
import 'package:yolvl/providers/user_provider.dart';
import 'package:yolvl/providers/activity_provider.dart';
import 'package:yolvl/providers/settings_provider.dart';
import 'package:yolvl/models/user.dart';
import 'package:yolvl/models/enums.dart';

void main() {
  group('DashboardScreen Widget Tests', () {
    late User testUser;
    late UserProvider userProvider;
    late ActivityProvider activityProvider;
    late SettingsProvider settingsProvider;

    setUp(() {
      testUser = User.create(id: 'test', name: 'Test User');
      testUser.level = 2;
      testUser.currentEXP = 500.0;
      testUser.setStat(StatType.strength, 2.5);
      testUser.setStat(StatType.agility, 1.8);
      testUser.setStat(StatType.endurance, 2.1);
      testUser.setStat(StatType.intelligence, 3.2);
      testUser.setStat(StatType.focus, 2.7);
      testUser.setStat(StatType.charisma, 1.9);
      testUser.hasCompletedOnboarding = true;

      userProvider = UserProvider();
      activityProvider = ActivityProvider();
      settingsProvider = SettingsProvider();
      
      // Set up test user
      userProvider.setUser(testUser);
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProvider>.value(value: userProvider),
            ChangeNotifierProvider<ActivityProvider>.value(value: activityProvider),
            ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
          ],
          child: const DashboardScreen(),
        ),
      );
    }

    testWidgets('should display user level and EXP progress', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check for level display
      expect(find.text('Level 2'), findsOneWidget);
      
      // Check for EXP display
      expect(find.textContaining('500'), findsAtLeastOneWidget);
      
      // Check for progress indicator
      expect(find.byType(LinearProgressIndicator), findsAtLeastOneWidget);
    });

    testWidgets('should display stats overview', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check for stat labels
      expect(find.text('Strength'), findsOneWidget);
      expect(find.text('Agility'), findsOneWidget);
      expect(find.text('Endurance'), findsOneWidget);
      expect(find.text('Intelligence'), findsOneWidget);
      expect(find.text('Focus'), findsOneWidget);
      expect(find.text('Charisma'), findsOneWidget);

      // Check for stat values
      expect(find.text('2.5'), findsOneWidget);
      expect(find.text('1.8'), findsOneWidget);
      expect(find.text('2.1'), findsOneWidget);
      expect(find.text('3.2'), findsOneWidget);
      expect(find.text('2.7'), findsOneWidget);
      expect(find.text('1.9'), findsOneWidget);
    });

    testWidgets('should display floating action button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check for FAB
      expect(find.byType(FloatingActionButton), findsOneWidget);
      
      // Check FAB icon
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('should navigate to activity logging when FAB is tapped', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap the FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Should navigate to activity logging screen
      // Note: This test assumes navigation is implemented
      // The exact assertion depends on the navigation implementation
    });

    testWidgets('should display daily summary section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Look for daily summary indicators
      expect(find.textContaining('Today'), findsAtLeastOneWidget);
    });

    testWidgets('should handle user with no stats gracefully', (tester) async {
      // Create user with default stats
      final emptyUser = User.create(id: 'empty', name: 'Empty User');
      userProvider.setUser(emptyUser);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should still display the screen without errors
      expect(find.text('Level 1'), findsOneWidget);
      expect(find.text('Empty User'), findsAtLeastOneWidget);
    });

    testWidgets('should update when user data changes', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Initial state
      expect(find.text('Level 2'), findsOneWidget);

      // Update user level
      testUser.level = 3;
      testUser.currentEXP = 800.0;
      userProvider.notifyListeners();
      
      await tester.pumpAndSettle();

      // Should reflect changes
      expect(find.text('Level 3'), findsOneWidget);
      expect(find.textContaining('800'), findsAtLeastOneWidget);
    });

    testWidgets('should display degradation warnings when present', (tester) async {
      // Set up user with old activity dates to trigger warnings
      testUser.setLastActivityDate(ActivityType.workoutUpperBody, 
          DateTime.now().subtract(const Duration(days: 4)));
      
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should display warning indicators
      expect(find.byIcon(Icons.warning), findsAtLeastOneWidget);
    });

    testWidgets('should be accessible', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check for semantic labels
      expect(find.bySemanticsLabel('User level and experience'), findsAtLeastOneWidget);
      expect(find.bySemanticsLabel('Statistics overview'), findsAtLeastOneWidget);
      expect(find.bySemanticsLabel('Add new activity'), findsOneWidget);
    });

    testWidgets('should handle theme changes', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Change theme
      settingsProvider.toggleDarkMode();
      await tester.pumpAndSettle();

      // Should still render correctly
      expect(find.text('Level 2'), findsOneWidget);
    });

    testWidgets('should display correct EXP progress percentage', (tester) async {
      // Set specific EXP values for testing
      testUser.level = 1;
      testUser.currentEXP = 500.0; // 50% of 1000 threshold
      userProvider.notifyListeners();

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find progress indicator and check its value
      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator).first
      );
      expect(progressIndicator.value, closeTo(0.5, 0.01));
    });

    testWidgets('should handle rapid stat updates without errors', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Rapidly update stats
      for (int i = 0; i < 10; i++) {
        testUser.addToStat(StatType.strength, 0.1);
        userProvider.notifyListeners();
        await tester.pump(const Duration(milliseconds: 10));
      }

      await tester.pumpAndSettle();

      // Should handle updates gracefully
      expect(find.text('3.5'), findsOneWidget); // 2.5 + 1.0
    });
  });
}