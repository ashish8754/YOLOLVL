import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:yolvl/models/enums.dart';
import 'package:yolvl/providers/activity_provider.dart';
import 'package:yolvl/providers/user_provider.dart';
import 'package:yolvl/screens/activity_logging_screen.dart';
import 'package:yolvl/services/activity_service.dart';

void main() {
  group('ActivityLoggingScreen', () {
    testWidgets('should display activity logging form', (WidgetTester tester) async {
      // Create test providers
      final activityProvider = ActivityProvider();
      final userProvider = UserProvider();

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: activityProvider),
              ChangeNotifierProvider.value(value: userProvider),
            ],
            child: const ActivityLoggingScreen(),
          ),
        ),
      );

      // Verify the screen elements are present
      expect(find.text('Log Activity'), findsOneWidget);
      expect(find.text('Activity Type'), findsOneWidget);
      expect(find.text('Duration (minutes)'), findsOneWidget);
      expect(find.text('Notes (Optional)'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Log Activity'), findsAtLeastNWidgets(2)); // Title + Button
    });

    testWidgets('should show dropdown with all activity types', (WidgetTester tester) async {
      final activityProvider = ActivityProvider();
      final userProvider = UserProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: activityProvider),
              ChangeNotifierProvider.value(value: userProvider),
            ],
            child: const ActivityLoggingScreen(),
          ),
        ),
      );

      // Tap the dropdown to open it
      await tester.tap(find.byType(DropdownButton<ActivityType>));
      await tester.pumpAndSettle();

      // Verify all activity types are present (allowing for duplicates in dropdown)
      for (final activityType in ActivityType.values) {
        expect(find.text(activityType.displayName), findsAtLeastNWidgets(1));
      }
    });

    testWidgets('should validate duration input', (WidgetTester tester) async {
      final activityProvider = ActivityProvider();
      final userProvider = UserProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: activityProvider),
              ChangeNotifierProvider.value(value: userProvider),
            ],
            child: const ActivityLoggingScreen(),
          ),
        ),
      );

      // Clear the duration field and enter invalid value
      final durationField = find.byType(TextFormField).first;
      await tester.tap(durationField);
      await tester.pumpAndSettle();
      
      // Clear and enter empty value
      await tester.enterText(durationField, '');
      await tester.pumpAndSettle();

      // Try to submit the form
      await tester.tap(find.text('Log Activity').last);
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Please enter a duration'), findsOneWidget);
    });

    testWidgets('should show expected gains preview', (WidgetTester tester) async {
      final activityProvider = ActivityProvider();
      final userProvider = UserProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: activityProvider),
              ChangeNotifierProvider.value(value: userProvider),
            ],
            child: const ActivityLoggingScreen(),
          ),
        ),
      );

      // Wait for the preview to load
      await tester.pumpAndSettle();

      // Should show expected gains section
      expect(find.text('Expected Gains:'), findsOneWidget);
      
      // Should show EXP gain
      expect(find.textContaining('EXP'), findsOneWidget);
    });
  });
}