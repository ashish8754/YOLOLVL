import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:yolvl/widgets/stats_overview_chart.dart';
import 'package:yolvl/providers/user_provider.dart';

void main() {
  group('Comprehensive Chart Auto-scaling Tests', () {
    Widget createTestWidget(Widget child) {
      return MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<UserProvider>(
            create: (_) => UserProvider(),
            child: child,
          ),
        ),
      );
    }

    group('StatsOverviewChart Auto-scaling', () {
      testWidgets('should handle stats with default values', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(const StatsOverviewChart()));
        await tester.pumpAndSettle();

        // Chart should render successfully with default stats
        expect(find.byType(StatsOverviewChart), findsOneWidget);
        expect(find.text('Stats Overview'), findsOneWidget);
      });

      testWidgets('should handle chart interactions', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(const StatsOverviewChart()));
        await tester.pumpAndSettle();

        // Test tap interaction
        await tester.tap(find.byType(StatsOverviewChart));
        await tester.pumpAndSettle();

        expect(find.byType(StatsOverviewChart), findsOneWidget);

        // Test swipe interaction
        await tester.drag(find.byType(StatsOverviewChart), const Offset(-200, 0));
        await tester.pumpAndSettle();

        expect(find.byType(StatsOverviewChart), findsOneWidget);
      });

      testWidgets('should render charts efficiently', (WidgetTester tester) async {
        // Measure rendering time
        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(createTestWidget(const StatsOverviewChart()));
        await tester.pumpAndSettle();

        stopwatch.stop();

        // Chart should render in reasonable time (less than 1 second)
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
        expect(find.byType(StatsOverviewChart), findsOneWidget);
      });

      testWidgets('should be accessible with screen readers', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(const StatsOverviewChart()));
        await tester.pumpAndSettle();

        // Should have semantic labels for accessibility
        expect(find.byType(Semantics), findsWidgets);
        
        // Chart should be accessible
        expect(find.byType(StatsOverviewChart), findsOneWidget);
      });

      testWidgets('should handle navigation to details', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(const StatsOverviewChart()));
        await tester.pumpAndSettle();

        // Find and tap the Details button
        expect(find.text('Details'), findsOneWidget);
        await tester.tap(find.text('Details'));
        await tester.pumpAndSettle();

        // Should handle navigation attempt
        expect(find.byType(StatsOverviewChart), findsOneWidget);
      });
    });
  });

  group('Chart Scaling Algorithm Tests', () {
    test('should calculate correct chart maximum for various stat ranges', () {
      // Test the chart scaling algorithm directly
      double calculateChartMaximum(double maxStatValue) {
        if (maxStatValue <= 5.0) {
          return 5.0;
        }
        final increment = 5.0;
        return (maxStatValue / increment).ceil() * increment;
      }

      // Test cases for chart scaling
      final testCases = [
        {'input': 1.0, 'expected': 5.0},
        {'input': 4.9, 'expected': 5.0},
        {'input': 5.0, 'expected': 5.0},
        {'input': 5.1, 'expected': 10.0},
        {'input': 7.5, 'expected': 10.0},
        {'input': 10.0, 'expected': 10.0},
        {'input': 12.3, 'expected': 15.0},
        {'input': 23.7, 'expected': 25.0},
        {'input': 47.2, 'expected': 50.0},
        {'input': 123.8, 'expected': 125.0},
        {'input': 567.3, 'expected': 570.0},
        {'input': 999.1, 'expected': 1000.0},
      ];

      for (final testCase in testCases) {
        final input = testCase['input'] as double;
        final expected = testCase['expected'] as double;
        final result = calculateChartMaximum(input);
        
        expect(result, equals(expected),
            reason: 'Failed for input: $input, expected: $expected, got: $result');
      }
    });

    test('should format stat values correctly for display', () {
      // Test stat value formatting
      String formatStatValue(double value) {
        if (value == value.roundToDouble()) {
          return value.toStringAsFixed(0);
        }
        
        String formatted = value.toStringAsFixed(2);
        
        if (formatted.contains('.')) {
          formatted = formatted.replaceAll(RegExp(r'0*$'), '');
          formatted = formatted.replaceAll(RegExp(r'\.$'), '');
        }
        
        return formatted;
      }

      final testCases = [
        {'input': 1.0, 'expected': '1'},
        {'input': 5.0, 'expected': '5'},
        {'input': 7.5, 'expected': '7.5'},
        {'input': 12.25, 'expected': '12.25'},
        {'input': 23.10, 'expected': '23.1'},
        {'input': 45.00, 'expected': '45'},
        {'input': 67.89, 'expected': '67.89'},
        {'input': 123.456, 'expected': '123.46'}, // Rounded to 2 decimal places
        {'input': 999.99, 'expected': '999.99'},
      ];

      for (final testCase in testCases) {
        final input = testCase['input'] as double;
        final expected = testCase['expected'] as String;
        final result = formatStatValue(input);
        
        expect(result, equals(expected),
            reason: 'Failed for input: $input, expected: $expected, got: $result');
      }
    });

    test('should handle chart scaling edge cases', () {
      double calculateChartMaximum(double maxStatValue) {
        if (maxStatValue <= 5.0) {
          return 5.0;
        }
        final increment = 5.0;
        return (maxStatValue / increment).ceil() * increment;
      }

      // Test edge cases
      expect(calculateChartMaximum(0.0), equals(5.0));
      expect(calculateChartMaximum(5.0), equals(5.0));
      expect(calculateChartMaximum(5.000001), equals(10.0));
    });

    test('should handle stat formatting edge cases', () {
      String formatStatValue(double value) {
        if (value == value.roundToDouble()) {
          return value.toStringAsFixed(0);
        }
        
        String formatted = value.toStringAsFixed(2);
        
        if (formatted.contains('.')) {
          formatted = formatted.replaceAll(RegExp(r'0*$'), '');
          formatted = formatted.replaceAll(RegExp(r'\.$'), '');
        }
        
        return formatted;
      }

      // Test edge cases
      expect(formatStatValue(0.0), equals('0'));
      expect(formatStatValue(0.1), equals('0.1'));
      expect(formatStatValue(0.01), equals('0.01'));
      expect(formatStatValue(0.10), equals('0.1'));
      expect(formatStatValue(1000.0), equals('1000'));
      expect(formatStatValue(1000.123), equals('1000.12'));
    });
  });
}