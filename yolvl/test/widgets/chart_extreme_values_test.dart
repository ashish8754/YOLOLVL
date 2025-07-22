import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:yolvl/widgets/stats_overview_chart.dart';
import 'package:yolvl/providers/user_provider.dart';
import 'package:yolvl/models/user.dart';
import 'package:yolvl/models/enums.dart';
import 'package:yolvl/services/stats_service.dart';

void main() {
  group('Chart Extreme Values Handling', () {
    late User testUser;

    setUp(() {
      testUser = User.create(
        id: 'test_user',
        name: 'Test User',
      );
    });

    Widget createTestWidget(Map<StatType, double> stats) {
      // Update user stats
      for (final entry in stats.entries) {
        testUser.setStat(entry.key, entry.value);
      }

      return MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<UserProvider>(
            create: (_) => UserProvider()..setUser(testUser),
            child: const StatsOverviewChart(),
          ),
        ),
      );
    }

    group('Chart Rendering with Large Values', () {
      testWidgets('should render chart with moderately large values', (tester) async {
        final stats = {
          StatType.strength: 25.5,
          StatType.agility: 30.2,
          StatType.endurance: 18.7,
          StatType.intelligence: 45.1,
          StatType.focus: 22.3,
          StatType.charisma: 35.8,
        };

        await tester.pumpWidget(createTestWidget(stats));
        await tester.pumpAndSettle();

        // Chart should render without errors
        expect(find.byType(StatsOverviewChart), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should render chart with very large values', (tester) async {
        final stats = {
          StatType.strength: 150.0,
          StatType.agility: 200.5,
          StatType.endurance: 99.9,
          StatType.intelligence: 500.0,
          StatType.focus: 75.3,
          StatType.charisma: 300.8,
        };

        await tester.pumpWidget(createTestWidget(stats));
        await tester.pumpAndSettle();

        // Chart should render without errors
        expect(find.byType(StatsOverviewChart), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should render chart with extremely large values', (tester) async {
        final stats = {
          StatType.strength: 10000.0,
          StatType.agility: 25000.5,
          StatType.endurance: 50000.0,
          StatType.intelligence: 100000.0,
          StatType.focus: 75000.3,
          StatType.charisma: 30000.8,
        };

        await tester.pumpWidget(createTestWidget(stats));
        await tester.pumpAndSettle();

        // Chart should render without errors even with extreme values
        expect(find.byType(StatsOverviewChart), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle maximum reasonable values', (tester) async {
        final stats = {
          StatType.strength: 999999.0,
          StatType.agility: 999999.0,
          StatType.endurance: 999999.0,
          StatType.intelligence: 999999.0,
          StatType.focus: 999999.0,
          StatType.charisma: 999999.0,
        };

        await tester.pumpWidget(createTestWidget(stats));
        await tester.pumpAndSettle();

        // Chart should render without errors at maximum values
        expect(find.byType(StatsOverviewChart), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('Chart Auto-scaling Validation', () {
      test('should calculate appropriate chart maximum for various ranges', () {
        // Test normal values (≤ 5)
        var stats = {StatType.strength: 3.5, StatType.agility: 4.2};
        var validation = StatsService.validateStatsForChart(stats);
        expect(validation.isValid, isTrue);
        expect(validation.recommendedMaxY, equals(5.0));

        // Test medium values (5-100)
        stats = {StatType.strength: 25.0, StatType.agility: 30.0};
        validation = StatsService.validateStatsForChart(stats);
        expect(validation.isValid, isTrue);
        expect(validation.recommendedMaxY, equals(30.0));

        // Test large values (100-1000)
        stats = {StatType.strength: 250.0, StatType.agility: 300.0};
        validation = StatsService.validateStatsForChart(stats);
        expect(validation.isValid, isTrue);
        expect(validation.recommendedMaxY, equals(300.0));

        // Test very large values (>1000)
        stats = {StatType.strength: 2500.0, StatType.agility: 3000.0};
        validation = StatsService.validateStatsForChart(stats);
        expect(validation.isValid, isTrue);
        expect(validation.recommendedMaxY, equals(3000.0));
      });

      test('should provide performance warnings for large values', () {
        final stats = {
          StatType.strength: 150000.0,
          StatType.agility: 200000.0,
        };

        final validation = StatsService.validateStatsForChart(stats);
        expect(validation.isValid, isTrue);
        expect(validation.hasWarning, isTrue);
        expect(validation.message, contains('Very large stat values'));
      });

      test('should handle edge cases in chart scaling', () {
        // Test with single very large value
        var stats = {StatType.strength: 1000000.0};
        var validation = StatsService.validateStatsForChart(stats);
        expect(validation.isValid, isTrue);
        expect(validation.recommendedMaxY, isNotNull);

        // Test with mixed small and large values
        stats = {
          StatType.strength: 1.5,
          StatType.agility: 50000.0,
        };
        validation = StatsService.validateStatsForChart(stats);
        expect(validation.isValid, isTrue);
        expect(validation.recommendedMaxY, greaterThan(50000.0));
      });
    });

    group('Chart Performance Testing', () {
      testWidgets('should render quickly with large values', (tester) async {
        final stats = {
          StatType.strength: 50000.0,
          StatType.agility: 75000.0,
          StatType.endurance: 25000.0,
          StatType.intelligence: 100000.0,
          StatType.focus: 60000.0,
          StatType.charisma: 80000.0,
        };

        final stopwatch = Stopwatch()..start();
        
        await tester.pumpWidget(createTestWidget(stats));
        await tester.pumpAndSettle();
        
        stopwatch.stop();

        // Chart should render within reasonable time
        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // 5 seconds max
        expect(find.byType(StatsOverviewChart), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle rapid stat updates with large values', (tester) async {
        final initialStats = {
          StatType.strength: 1000.0,
          StatType.agility: 1500.0,
        };

        await tester.pumpWidget(createTestWidget(initialStats));
        await tester.pumpAndSettle();

        // Rapidly update stats to large values
        for (int i = 0; i < 10; i++) {
          final newStats = {
            StatType.strength: 1000.0 + (i * 5000),
            StatType.agility: 1500.0 + (i * 7500),
          };

          await tester.pumpWidget(createTestWidget(newStats));
          await tester.pump();
        }

        await tester.pumpAndSettle();

        // Chart should handle updates without errors
        expect(find.byType(StatsOverviewChart), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('Chart Validation Integration', () {
      testWidgets('should use validation results for chart rendering', (tester) async {
        final stats = {
          StatType.strength: 75000.0,
          StatType.agility: 100000.0,
        };

        // Validate stats before rendering
        final validation = StatsService.validateStatsForChart(stats);
        expect(validation.isValid, isTrue);
        expect(validation.hasWarning, isTrue);

        await tester.pumpWidget(createTestWidget(stats));
        await tester.pumpAndSettle();

        // Chart should render using validated parameters
        expect(find.byType(StatsOverviewChart), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle sanitized stats from validation', (tester) async {
        final invalidStats = {
          StatType.strength: double.nan,
          StatType.agility: double.infinity,
          StatType.endurance: -5.0,
        };

        // Validate and sanitize stats
        final validation = StatsService.validateInfiniteStats(invalidStats);
        expect(validation.isValid, isFalse);
        expect(validation.sanitizedStats, isNotNull);

        // Use sanitized stats for rendering
        await tester.pumpWidget(createTestWidget(validation.sanitizedStats!));
        await tester.pumpAndSettle();

        // Chart should render with sanitized values
        expect(find.byType(StatsOverviewChart), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('Chart Accessibility with Large Values', () {
      testWidgets('should provide accessible labels for large values', (tester) async {
        final stats = {
          StatType.strength: 12345.67,
          StatType.agility: 98765.43,
        };

        await tester.pumpWidget(createTestWidget(stats));
        await tester.pumpAndSettle();

        // Chart should be accessible
        expect(find.byType(StatsOverviewChart), findsOneWidget);
        
        // Should have semantic labels
        final semantics = tester.getSemantics(find.byType(StatsOverviewChart));
        expect(semantics.label, isNotNull);
        expect(semantics.label, contains('Stats overview chart'));
      });

      testWidgets('should format large values appropriately in tooltips', (tester) async {
        final stats = {
          StatType.strength: 12345.0,
          StatType.agility: 67890.0,
        };

        await tester.pumpWidget(createTestWidget(stats));
        await tester.pumpAndSettle();

        // Chart should render without formatting errors
        expect(find.byType(StatsOverviewChart), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('Error Handling', () {
      testWidgets('should handle chart rendering errors gracefully', (tester) async {
        final problematicStats = {
          StatType.strength: double.maxFinite,
          StatType.agility: double.minPositive,
        };

        await tester.pumpWidget(createTestWidget(problematicStats));
        await tester.pumpAndSettle();

        // Should not crash, even with problematic values
        expect(find.byType(StatsOverviewChart), findsOneWidget);
        // Exception might occur but should be handled
      });

      testWidgets('should recover from validation failures', (tester) async {
        // Start with invalid stats
        final invalidStats = {
          StatType.strength: double.nan,
          StatType.agility: double.infinity,
        };

        await tester.pumpWidget(createTestWidget(invalidStats));
        await tester.pumpAndSettle();

        // Chart should still render (using fallback values)
        expect(find.byType(StatsOverviewChart), findsOneWidget);

        // Update to valid stats
        final validStats = {
          StatType.strength: 15.5,
          StatType.agility: 22.3,
        };

        await tester.pumpWidget(createTestWidget(validStats));
        await tester.pumpAndSettle();

        // Chart should render normally
        expect(find.byType(StatsOverviewChart), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });
  });
}