import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:yolvl/providers/user_provider.dart';
import 'package:yolvl/providers/activity_provider.dart';
import 'package:yolvl/widgets/level_exp_display.dart';
import 'package:yolvl/widgets/stats_overview_chart.dart';
import 'package:yolvl/widgets/daily_summary_widget.dart';

void main() {
  group('Dashboard Widgets Tests', () {
    late UserProvider userProvider;
    late ActivityProvider activityProvider;

    setUp(() {
      userProvider = UserProvider();
      activityProvider = ActivityProvider();
    });

    Widget createTestWidget(Widget child) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<UserProvider>.value(value: userProvider),
          ChangeNotifierProvider<ActivityProvider>.value(value: activityProvider),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: child,
          ),
        ),
      );
    }

    testWidgets('LevelExpDisplay renders without error', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const LevelExpDisplay()));
      
      // Should render without throwing errors
      expect(find.byType(LevelExpDisplay), findsOneWidget);
      expect(find.text('Player'), findsOneWidget);
      expect(find.text('Level 1'), findsOneWidget);
    });

    testWidgets('StatsOverviewChart renders without error', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const StatsOverviewChart()));
      
      // Should render without throwing errors
      expect(find.byType(StatsOverviewChart), findsOneWidget);
      expect(find.text('Stats Overview'), findsOneWidget);
    });

    testWidgets('DailySummaryWidget renders without error', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const DailySummaryWidget()));
      
      // Should render without throwing errors
      expect(find.byType(DailySummaryWidget), findsOneWidget);
      expect(find.text('Daily Summary'), findsOneWidget);
    });
  });
}