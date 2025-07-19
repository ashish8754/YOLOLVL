import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yolvl/widgets/stats_progression_chart.dart';
import 'package:yolvl/models/activity_log.dart';
import 'package:yolvl/models/enums.dart';
import 'package:yolvl/screens/stats_progression_screen.dart';

void main() {
  group('StatsProgressionChart', () {
    testWidgets('should display chart title and current stat value', (WidgetTester tester) async {
      // Create test data
      final activities = <ActivityLog>[
        ActivityLog.create(
          id: 'test1',
          activityType: ActivityType.workoutWeights,
          durationMinutes: 60,
          statGains: {StatType.strength: 0.06, StatType.endurance: 0.04},
          expGained: 60,
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatsProgressionChart(
              statType: StatType.strength,
              timeRange: TimeRange.last7Days,
              activities: activities,
              currentStatValue: 2.5,
            ),
          ),
        ),
      );

      // Verify chart title is displayed
      expect(find.text('Strength Progression'), findsOneWidget);
      
      // Verify current stat value is displayed
      expect(find.text('Current: 2.50'), findsOneWidget);
    });

    testWidgets('should display no data message when activities list is empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatsProgressionChart(
              statType: StatType.strength,
              timeRange: TimeRange.last7Days,
              activities: const [],
              currentStatValue: 1.0,
            ),
          ),
        ),
      );

      // Verify no data message is displayed
      expect(find.text('No strength activities found'), findsOneWidget);
    });

    testWidgets('should display stat summary when data is available', (WidgetTester tester) async {
      // Create test data with multiple activities
      final activities = <ActivityLog>[
        ActivityLog.create(
          id: 'test1',
          activityType: ActivityType.workoutWeights,
          durationMinutes: 60,
          statGains: {StatType.strength: 0.06},
          expGained: 60,
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
        ),
        ActivityLog.create(
          id: 'test2',
          activityType: ActivityType.workoutWeights,
          durationMinutes: 30,
          statGains: {StatType.strength: 0.03},
          expGained: 30,
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatsProgressionChart(
              statType: StatType.strength,
              timeRange: TimeRange.last7Days,
              activities: activities,
              currentStatValue: 1.09,
            ),
          ),
        ),
      );

      // Wait for chart to build
      await tester.pumpAndSettle();

      // Verify stat summary sections are displayed
      expect(find.text('Total Gain'), findsOneWidget);
      expect(find.text('Data Points'), findsOneWidget);
      expect(find.text('Avg/Day'), findsOneWidget);
    });
  });
}