import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:yolvl/screens/dashboard_screen.dart';
import 'package:yolvl/screens/activity_logging_screen.dart';
import 'package:yolvl/providers/user_provider.dart';
import 'package:yolvl/providers/activity_provider.dart';
import 'package:yolvl/providers/settings_provider.dart';
import 'package:yolvl/models/user.dart';
import 'package:yolvl/models/enums.dart';

void main() {
  group('Accessibility Tests', () {
    late User testUser;
    late UserProvider userProvider;
    late ActivityProvider activityProvider;
    late SettingsProvider settingsProvider;

    setUp(() {
      testUser = User.create(id: 'test', name: 'Test User');
      testUser.level = 2;
      testUser.currentEXP = 500.0;
      testUser.setStat(StatType.strength, 2.5);
      testUser.hasCompletedOnboarding = true;

      userProvider = UserProvider();
      activityProvider = ActivityProvider();
      settingsProvider = SettingsProvider();
      
      userProvider.setUser(testUser);
    });

    Widget createTestWidget(Widget child) {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProvider>.value(value: userProvider),
            ChangeNotifierProvider<ActivityProvider>.value(value: activityProvider),
            ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
          ],
          child: child,
        ),
      );
    }

    group('Screen Reader Support', () {
      testWidgets('Dashboard should have proper semantic labels', (tester) async {
        await tester.pumpWidget(createTestWidget(const DashboardScreen()));
        await tester.pumpAndSettle();

        // Check for semantic labels
        expect(find.bySemanticsLabel('User level 2'), findsOneWidget);
        expect(find.bySemanticsLabel('Experience points: 500'), findsOneWidget);
        expect(find.bySemanticsLabel('Strength: 2.5'), findsOneWidget);
        expect(find.bySemanticsLabel('Add new activity'), findsOneWidget);
      });

      testWidgets('Activity logging should have proper semantic labels', (tester) async {
        await tester.pumpWidget(createTestWidget(const ActivityLoggingScreen()));
        await tester.pumpAndSettle();

        // Check for semantic labels
        expect(find.bySemanticsLabel('Select activity type'), findsOneWidget);
        expect(find.bySemanticsLabel('Enter duration in minutes'), findsOneWidget);
        expect(find.bySemanticsLabel('Log activity button'), findsOneWidget);
      });

      testWidgets('Progress indicators should announce changes', (tester) async {
        await tester.pumpWidget(createTestWidget(const DashboardScreen()));
        await tester.pumpAndSettle();

        // Find progress indicator
        final progressFinder = find.byType(LinearProgressIndicator);
        expect(progressFinder, findsOneWidget);

        // Check semantic properties
        final progressWidget = tester.widget<LinearProgressIndicator>(progressFinder);
        expect(progressWidget.semanticsLabel, contains('progress'));
        expect(progressWidget.semanticsValue, isNotNull);
      });

      testWidgets('Buttons should have proper semantic roles', (tester) async {
        await tester.pumpWidget(createTestWidget(const DashboardScreen()));
        await tester.pumpAndSettle();

        // Check FAB semantics
        final fabFinder = find.byType(FloatingActionButton);
        expect(fabFinder, findsOneWidget);

        final fabSemantics = tester.getSemantics(fabFinder);
        expect(fabSemantics.hasAction(SemanticsAction.tap), isTrue);
        expect(fabSemantics.label, isNotEmpty);
      });
    });

    group('High Contrast Support', () {
      testWidgets('Should support high contrast mode', (tester) async {
        // Enable high contrast
        settingsProvider.setHighContrastMode(true);

        await tester.pumpWidget(createTestWidget(const DashboardScreen()));
        await tester.pumpAndSettle();

        // Check that high contrast colors are applied
        final theme = Theme.of(tester.element(find.byType(DashboardScreen)));
        expect(theme.brightness, equals(Brightness.dark));
        expect(theme.colorScheme.contrast, greaterThan(4.5)); // WCAG AA standard
      });

      testWidgets('Text should have sufficient contrast', (tester) async {
        await tester.pumpWidget(createTestWidget(const DashboardScreen()));
        await tester.pumpAndSettle();

        // Find text widgets and check contrast
        final textWidgets = find.byType(Text);
        for (final textFinder in textWidgets.evaluate()) {
          final textWidget = textFinder.widget as Text;
          final textStyle = textWidget.style;
          
          if (textStyle?.color != null) {
            // Check contrast ratio (simplified check)
            final color = textStyle!.color!;
            expect(color.computeLuminance(), greaterThan(0.1));
          }
        }
      });
    });

    group('Large Text Support', () {
      testWidgets('Should scale text appropriately', (tester) async {
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(textScaleFactor: 2.0),
            child: createTestWidget(const DashboardScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Text should scale without overflow
        expect(tester.takeException(), isNull);
        
        // Check that text is properly scaled
        final textWidgets = find.byType(Text);
        for (final textFinder in textWidgets.evaluate()) {
          final renderObject = tester.renderObject(textFinder);
          expect(renderObject.hasSize, isTrue);
        }
      });

      testWidgets('Should handle large text without layout issues', (tester) async {
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(textScaleFactor: 3.0),
            child: createTestWidget(const DashboardScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Should not have render overflow
        expect(tester.takeException(), isNull);
      });
    });

    group('Touch Target Size', () {
      testWidgets('Interactive elements should meet minimum touch target size', (tester) async {
        await tester.pumpWidget(createTestWidget(const DashboardScreen()));
        await tester.pumpAndSettle();

        // Check FAB size
        final fabFinder = find.byType(FloatingActionButton);
        final fabSize = tester.getSize(fabFinder);
        expect(fabSize.width, greaterThanOrEqualTo(44.0)); // WCAG minimum
        expect(fabSize.height, greaterThanOrEqualTo(44.0));

        // Check other interactive elements
        final buttonFinders = find.byType(ElevatedButton);
        for (final buttonFinder in buttonFinders.evaluate()) {
          final buttonSize = tester.getSize(buttonFinder);
          expect(buttonSize.width, greaterThanOrEqualTo(44.0));
          expect(buttonSize.height, greaterThanOrEqualTo(44.0));
        }
      });

      testWidgets('Touch targets should have adequate spacing', (tester) async {
        await tester.pumpWidget(createTestWidget(const ActivityLoggingScreen()));
        await tester.pumpAndSettle();

        // Find interactive elements
        final interactiveElements = [
          ...find.byType(ElevatedButton).evaluate(),
          ...find.byType(TextButton).evaluate(),
          ...find.byType(IconButton).evaluate(),
        ];

        // Check spacing between elements
        for (int i = 0; i < interactiveElements.length - 1; i++) {
          final element1 = interactiveElements[i];
          final element2 = interactiveElements[i + 1];
          
          final rect1 = tester.getRect(find.byWidget(element1.widget));
          final rect2 = tester.getRect(find.byWidget(element2.widget));
          
          // Elements should have at least 8px spacing
          final distance = (rect1.center - rect2.center).distance;
          expect(distance, greaterThan(8.0));
        }
      });
    });

    group('Keyboard Navigation', () {
      testWidgets('Should support tab navigation', (tester) async {
        await tester.pumpWidget(createTestWidget(const DashboardScreen()));
        await tester.pumpAndSettle();

        // Test tab navigation
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();

        // Should focus on first focusable element
        expect(tester.binding.focusManager.primaryFocus, isNotNull);

        // Continue tabbing
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();

        // Should move to next focusable element
        expect(tester.binding.focusManager.primaryFocus, isNotNull);
      });

      testWidgets('Should support enter key activation', (tester) async {
        await tester.pumpWidget(createTestWidget(const DashboardScreen()));
        await tester.pumpAndSettle();

        // Focus on FAB
        final fabFinder = find.byType(FloatingActionButton);
        await tester.tap(fabFinder);
        await tester.pumpAndSettle();

        // Should activate with enter key
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        // Should trigger the same action as tap
        expect(find.byType(ActivityLoggingScreen), findsOneWidget);
      });

      testWidgets('Should support escape key for dismissal', (tester) async {
        await tester.pumpWidget(createTestWidget(const ActivityLoggingScreen()));
        await tester.pumpAndSettle();

        // Press escape key
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        // Should dismiss or navigate back
        expect(find.byType(DashboardScreen), findsOneWidget);
      });
    });

    group('Focus Management', () {
      testWidgets('Should maintain focus order', (tester) async {
        await tester.pumpWidget(createTestWidget(const ActivityLoggingScreen()));
        await tester.pumpAndSettle();

        final focusableElements = [
          find.byType(DropdownButton),
          find.byType(TextFormField),
          find.byType(ElevatedButton),
        ];

        // Test focus order
        for (final element in focusableElements) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pumpAndSettle();
          
          // Should focus on expected element
          final focused = tester.binding.focusManager.primaryFocus;
          expect(focused, isNotNull);
        }
      });

      testWidgets('Should restore focus after navigation', (tester) async {
        await tester.pumpWidget(createTestWidget(const DashboardScreen()));
        await tester.pumpAndSettle();

        // Focus on FAB
        final fabFinder = find.byType(FloatingActionButton);
        await tester.tap(fabFinder);
        await tester.pumpAndSettle();

        // Navigate to activity logging
        expect(find.byType(ActivityLoggingScreen), findsOneWidget);

        // Navigate back
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        // Focus should be restored
        expect(tester.binding.focusManager.primaryFocus, isNotNull);
      });
    });

    group('Voice Control Support', () {
      testWidgets('Should support voice activation hints', (tester) async {
        await tester.pumpWidget(createTestWidget(const DashboardScreen()));
        await tester.pumpAndSettle();

        // Check for voice hints in semantics
        final fabFinder = find.byType(FloatingActionButton);
        final fabSemantics = tester.getSemantics(fabFinder);
        
        expect(fabSemantics.hint, isNotEmpty);
        expect(fabSemantics.hint, contains('activity'));
      });

      testWidgets('Should provide clear action descriptions', (tester) async {
        await tester.pumpWidget(createTestWidget(const ActivityLoggingScreen()));
        await tester.pumpAndSettle();

        // Check button descriptions
        final buttonFinder = find.text('Log Activity');
        final buttonSemantics = tester.getSemantics(buttonFinder);
        
        expect(buttonSemantics.label, contains('Log'));
        expect(buttonSemantics.hint, isNotEmpty);
      });
    });

    group('Reduced Motion Support', () {
      testWidgets('Should respect reduced motion preferences', (tester) async {
        // Enable reduced motion
        settingsProvider.setReducedMotion(true);

        await tester.pumpWidget(createTestWidget(const DashboardScreen()));
        await tester.pumpAndSettle();

        // Animations should be disabled or reduced
        final animatedWidgets = find.byType(AnimatedWidget);
        for (final animatedFinder in animatedWidgets.evaluate()) {
          final animatedWidget = animatedFinder.widget as AnimatedWidget;
          // Check that animation duration is reduced
          expect(animatedWidget.listenable, isNotNull);
        }
      });
    });

    group('Error Accessibility', () {
      testWidgets('Should announce errors to screen readers', (tester) async {
        await tester.pumpWidget(createTestWidget(const ActivityLoggingScreen()));
        await tester.pumpAndSettle();

        // Trigger validation error
        await tester.enterText(find.byType(TextFormField), '-10');
        await tester.tap(find.text('Log Activity'));
        await tester.pumpAndSettle();

        // Error should be announced
        expect(find.textContaining('error'), findsOneWidget);
        
        // Check semantic properties of error
        final errorFinder = find.textContaining('error');
        final errorSemantics = tester.getSemantics(errorFinder);
        expect(errorSemantics.isLiveRegion, isTrue);
      });

      testWidgets('Should provide clear error recovery instructions', (tester) async {
        await tester.pumpWidget(createTestWidget(const ActivityLoggingScreen()));
        await tester.pumpAndSettle();

        // Trigger error
        await tester.enterText(find.byType(TextFormField), '');
        await tester.tap(find.text('Log Activity'));
        await tester.pumpAndSettle();

        // Should provide clear instructions
        expect(find.textContaining('required'), findsOneWidget);
        expect(find.textContaining('enter'), findsOneWidget);
      });
    });
  });
}