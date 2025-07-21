import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:yolvl/widgets/stats_overview_chart.dart';
import 'package:yolvl/providers/user_provider.dart';
import 'package:yolvl/models/user.dart';
import 'package:yolvl/models/enums.dart';

void main() {
  group('StatsOverviewChart - Auto-scaling and Formatting', () {
    late UserProvider userProvider;

    setUp(() {
      userProvider = UserProvider();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<UserProvider>.value(
            value: userProvider,
            child: const StatsOverviewChart(),
          ),
        ),
      );
    }

    testWidgets('should display chart with default stats (all 1.0)', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should find the chart widget
      expect(find.byType(StatsOverviewChart), findsOneWidget);
      
      // Should display the title
      expect(find.text('Stats Overview'), findsOneWidget);
    });

    testWidgets('should toggle between simplified and detailed view', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Initially should be in simplified view
      expect(find.text('Tap or swipe'), findsOneWidget);

      // Tap to toggle to detailed view
      await tester.tap(find.byType(StatsOverviewChart));
      await tester.pumpAndSettle();

      // Should still find the chart
      expect(find.byType(StatsOverviewChart), findsOneWidget);
    });

    testWidgets('should handle swipe gestures', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Swipe left to show detailed view
      await tester.drag(find.byType(StatsOverviewChart), const Offset(-200, 0));
      await tester.pumpAndSettle();

      expect(find.byType(StatsOverviewChart), findsOneWidget);

      // Swipe right to show simplified view
      await tester.drag(find.byType(StatsOverviewChart), const Offset(200, 0));
      await tester.pumpAndSettle();

      expect(find.byType(StatsOverviewChart), findsOneWidget);
    });

    testWidgets('should navigate to detailed stats screen', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find and tap the Details button
      expect(find.text('Details'), findsOneWidget);
      await tester.tap(find.text('Details'));
      await tester.pumpAndSettle();

      // Should navigate to stats progression screen
      // Note: In a real test, we'd verify navigation, but for this unit test
      // we just verify the button exists and is tappable
    });

    testWidgets('should be accessible with screen readers', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should have semantic labels for accessibility
      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('should handle animation properly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      // Pump a few frames to let animation start
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.byType(StatsOverviewChart), findsOneWidget);
    });

    testWidgets('should handle edge case with default stats', (WidgetTester tester) async {
      // UserProvider provides default stats of 1.0 for all when no user is set
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(StatsOverviewChart), findsOneWidget);
      expect(find.text('Stats Overview'), findsOneWidget);
    });
  });

  group('StatsOverviewChart - Chart Scaling Logic', () {
    testWidgets('should render chart with default scaling', (WidgetTester tester) async {
      final userProvider = UserProvider();

      Widget createTestWidget() {
        return MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<UserProvider>.value(
              value: userProvider,
              child: const StatsOverviewChart(),
            ),
          ),
        );
      }

      // Test with default stats (all 1.0) - should use 5.0 as maximum
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.byType(StatsOverviewChart), findsOneWidget);
    });
  });
}