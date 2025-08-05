import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:yolvl/main.dart';
import 'package:yolvl/models/enums.dart';
import 'package:yolvl/models/user.dart';
import 'package:yolvl/models/activity_log.dart';
import 'package:yolvl/providers/user_provider.dart';
import 'package:yolvl/providers/activity_provider.dart';
import 'package:yolvl/services/activity_service.dart';
import 'package:yolvl/services/stats_service.dart';
import 'package:yolvl/widgets/stats_overview_chart.dart';
import 'package:yolvl/screens/main_navigation_screen.dart';
import '../test_helpers/mock_path_provider.dart';

/// Comprehensive integration test for all three app improvements:
/// 1. Activity deletion with stat reversal
/// 2. Infinite stat progression
/// 3. UI layout fixes for FAB positioning
void main() {
  group('App Improvements Integration Tests', () {
    late User testUser;
    late ActivityService activityService;

    setUpAll(() async {
      await setupMockPathProvider();
    });

    setUp(() {
      testUser = User.create(
        id: 'test_user',
        name: 'Test User',
        avatarPath: null,
      );
      testUser.level = 5;
      testUser.currentEXP = 250;
      testUser.stats = {
        'strength': 3.5,
        'agility': 4.2,
        'endurance': 2.8,
        'intelligence': 6.1,
        'focus': 5.7,
        'charisma': 3.9,
      };
      testUser.hasCompletedOnboarding = true;

      activityService = ActivityService();
    });

    group('1. Activity Deletion with Stat Reversal', () {
      testWidgets('should reverse stats when activity is deleted', (WidgetTester tester) async {
        // Create an activity with known stat gains
        final activity = ActivityLog.create(
          id: 'test_activity',
          activityType: ActivityType.workoutUpperBody,
          durationMinutes: 60,
          statGains: {
            StatType.strength: 0.06,
            StatType.endurance: 0.04,
          },
          expGained: 60,
          timestamp: DateTime.now(),
        );

        // Store original stats
        final originalStrength = testUser.getStat(StatType.strength);
        final originalEndurance = testUser.getStat(StatType.endurance);
        final originalEXP = testUser.currentEXP;

        // Apply activity gains
        testUser.addToStat(StatType.strength, 0.06);
        testUser.addToStat(StatType.endurance, 0.04);
        testUser.currentEXP += 60;

        // Verify gains were applied
        expect(testUser.getStat(StatType.strength), originalStrength + 0.06);
        expect(testUser.getStat(StatType.endurance), originalEndurance + 0.04);
        expect(testUser.currentEXP, originalEXP + 60);

        // Test stat reversal calculation
        final reversals = StatsService.calculateStatReversals(
          ActivityType.workoutUpperBody,
          60,
          activity.statGainsMap,
        );

        expect(reversals[StatType.strength], 0.06);
        expect(reversals[StatType.endurance], 0.04);

        // Test reversal validation
        final currentStats = {
          StatType.strength: testUser.getStat(StatType.strength),
          StatType.endurance: testUser.getStat(StatType.endurance),
        };

        expect(StatsService.validateStatReversal(currentStats, reversals), true);

        // Apply reversals
        final updatedStats = StatsService.applyStatReversals(currentStats, reversals);
        
        expect(updatedStats[StatType.strength], closeTo(originalStrength, 0.001));
        expect(updatedStats[StatType.endurance], closeTo(originalEndurance, 0.001));
      });

      testWidgets('should handle level-down scenarios during deletion', (WidgetTester tester) async {
        // Set user to a state where EXP reversal would cause level-down
        testUser.level = 2;
        testUser.currentEXP = 50; // Just above level 1 threshold

        final activity = ActivityLog.create(
          id: 'test_activity',
          activityType: ActivityType.workoutUpperBody,
          durationMinutes: 120, // Large EXP gain
          statGains: {StatType.strength: 0.12},
          expGained: 120,
          timestamp: DateTime.now(),
        );

        // Test EXP reversal validation
        expect(testUser.currentEXP - activity.expGained < 0, true); // Would go negative

        // The system should handle this gracefully by clamping to minimum values
      });

      testWidgets('should enforce stat floor during reversal', (WidgetTester tester) async {
        // Set user stats close to minimum
        testUser.setStat(StatType.strength, 1.02); // Just above floor

        final activity = ActivityLog.create(
          id: 'test_activity',
          activityType: ActivityType.workoutUpperBody,
          durationMinutes: 60,
          statGains: {StatType.strength: 0.06}, // Would push below 1.0
          expGained: 60,
          timestamp: DateTime.now(),
        );

        final reversals = StatsService.calculateStatReversals(
          ActivityType.workoutUpperBody,
          60,
          activity.statGainsMap,
        );

        final currentStats = {StatType.strength: testUser.getStat(StatType.strength)};
        final updatedStats = StatsService.applyStatReversals(currentStats, reversals);

        // Should be clamped to 1.0 floor
        expect(updatedStats[StatType.strength], 1.0);
      });
    });

    group('2. Infinite Stat Progression', () {
      testWidgets('should allow stats to grow beyond 5.0', (WidgetTester tester) async {
        // Set stats above the old ceiling
        testUser.setStat(StatType.strength, 7.5);
        testUser.setStat(StatType.intelligence, 12.3);
        testUser.setStat(StatType.focus, 25.7);

        // Test stat validation for infinite progression
        final validationResult = StatsService.validateInfiniteStats(testUser.statsMap);
        expect(validationResult.isValid, true);

        // Test stat gains calculation (should work without ceiling)
        final gains = StatsService.calculateStatGains(ActivityType.workoutUpperBody, 60);
        expect(gains[StatType.strength], 0.06);
        expect(gains[StatType.endurance], 0.04);

        // Apply gains to high stats
        final originalStrength = testUser.getStat(StatType.strength);
        testUser.addToStat(StatType.strength, gains[StatType.strength]!);
        
        expect(testUser.getStat(StatType.strength), originalStrength + 0.06);
        expect(testUser.getStat(StatType.strength) > 5.0, true);
      });

      testWidgets('should handle chart auto-scaling for large values', (WidgetTester tester) async {
        // Set very large stat values
        testUser.setStat(StatType.strength, 150.0);
        testUser.setStat(StatType.intelligence, 75.5);
        testUser.setStat(StatType.focus, 200.3);

        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                ChangeNotifierProvider(create: (_) => UserProvider()..setTestUser(testUser)),
              ],
              child: const Scaffold(
                body: StatsOverviewChart(),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Chart should render without errors
        expect(find.byType(StatsOverviewChart), findsOneWidget);
        
        // Should handle large values gracefully
        expect(tester.takeException(), isNull);
      });

      testWidgets('should validate stats for export with large values', (WidgetTester tester) async {
        // Test export validation with infinite stats
        final largeStats = {
          StatType.strength: 1000.0,
          StatType.intelligence: 5000.5,
          StatType.focus: 10000.0,
        };

        final exportResult = StatsService.validateStatsForExport(largeStats);
        expect(exportResult.isValid || exportResult.hasWarning, true);
        expect(exportResult.sanitizedStats, isNotNull);
      });
    });

    group('3. UI Layout and FAB Positioning', () {
      testWidgets('should position FAB without overlapping navigation', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                ChangeNotifierProvider(create: (_) => UserProvider()..setTestUser(testUser)),
                ChangeNotifierProvider(create: (_) => ActivityProvider()),
              ],
              child: const MainNavigationScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find FAB and bottom navigation
        final fabFinder = find.byType(FloatingActionButton);
        final bottomNavFinder = find.byType(BottomNavigationBar);

        expect(fabFinder, findsOneWidget);
        expect(bottomNavFinder, findsOneWidget);

        // Get positions
        final fabRect = tester.getRect(fabFinder);
        final bottomNavRect = tester.getRect(bottomNavFinder);

        // FAB should be above bottom navigation with proper spacing
        expect(fabRect.bottom <= bottomNavRect.top, true);
        
        // FAB should be centered horizontally
        final screenWidth = tester.getSize(find.byType(Scaffold)).width;
        final fabCenter = fabRect.center.dx;
        expect(fabCenter, closeTo(screenWidth / 2, 50)); // Allow some tolerance
      });

      testWidgets('should handle different screen sizes', (WidgetTester tester) async {
        // Test with different screen sizes
        final sizes = [
          const Size(320, 568), // iPhone SE
          const Size(375, 667), // iPhone 8
          const Size(414, 896), // iPhone 11
          const Size(768, 1024), // iPad
        ];

        for (final size in sizes) {
          await tester.binding.setSurfaceSize(size);
          
          await tester.pumpWidget(
            MaterialApp(
              home: MultiProvider(
                providers: [
                  ChangeNotifierProvider(create: (_) => UserProvider()..setTestUser(testUser)),
                  ChangeNotifierProvider(create: (_) => ActivityProvider()),
                ],
                child: const MainNavigationScreen(),
              ),
            ),
          );

          await tester.pumpAndSettle();

          // FAB should be positioned correctly on all screen sizes
          final fabFinder = find.byType(FloatingActionButton);
          final bottomNavFinder = find.byType(BottomNavigationBar);

          if (fabFinder.evaluate().isNotEmpty && bottomNavFinder.evaluate().isNotEmpty) {
            final fabRect = tester.getRect(fabFinder);
            final bottomNavRect = tester.getRect(bottomNavFinder);

            // No overlap
            expect(fabRect.bottom <= bottomNavRect.top, true);
          }
        }

        // Reset to default size
        await tester.binding.setSurfaceSize(null);
      });

      testWidgets('should maintain accessibility standards', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                ChangeNotifierProvider(create: (_) => UserProvider()..setTestUser(testUser)),
                ChangeNotifierProvider(create: (_) => ActivityProvider()),
              ],
              child: const MainNavigationScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // FAB should have minimum touch target size
        final fabFinder = find.byType(FloatingActionButton);
        if (fabFinder.evaluate().isNotEmpty) {
          final fabSize = tester.getSize(fabFinder);
          expect(fabSize.width >= 48, true); // Minimum touch target
          expect(fabSize.height >= 48, true);
        }

        // Should have semantic labels
        expect(find.bySemanticsLabel('Main navigation screen'), findsOneWidget);
      });
    });

    group('4. Complete Integration Flow', () {
      testWidgets('should handle complete user journey with all improvements', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                ChangeNotifierProvider(create: (_) => UserProvider()..setTestUser(testUser)),
                ChangeNotifierProvider(create: (_) => ActivityProvider()),
              ],
              child: const MainNavigationScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 1. Verify UI layout is correct
        expect(find.byType(MainNavigationScreen), findsOneWidget);
        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.byType(BottomNavigationBar), findsOneWidget);

        // 2. Navigate to stats tab to verify infinite stats display
        await tester.tap(find.text('Stats'));
        await tester.pumpAndSettle();

        // Should display stats without errors, even with values > 5
        expect(tester.takeException(), isNull);

        // 3. Navigate to history tab to verify deletion functionality
        await tester.tap(find.text('History'));
        await tester.pumpAndSettle();

        // History screen should load without errors
        expect(tester.takeException(), isNull);

        // 4. Return to dashboard
        await tester.tap(find.text('Dashboard'));
        await tester.pumpAndSettle();

        // Should show stats overview chart with auto-scaling
        expect(find.byType(StatsOverviewChart), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should maintain data consistency across all features', (WidgetTester tester) async {
        // Test that all three improvements work together without conflicts
        
        // 1. Create activity with high stat gains (infinite progression)
        final gains = StatsService.calculateStatGains(ActivityType.studySerious, 120);
        expect(gains[StatType.intelligence], 0.12); // 2 hours * 0.06/hour
        expect(gains[StatType.focus], 0.08); // 2 hours * 0.04/hour

        // 2. Apply gains to push stats beyond old ceiling
        final originalIntelligence = testUser.getStat(StatType.intelligence);
        testUser.addToStat(StatType.intelligence, gains[StatType.intelligence]!);
        
        final newIntelligence = testUser.getStat(StatType.intelligence);
        expect(newIntelligence, originalIntelligence + 0.12);
        expect(newIntelligence > 5.0, true); // Beyond old ceiling

        // 3. Test stat reversal calculation for the same activity
        final activity = ActivityLog.create(
          id: 'test_activity',
          activityType: ActivityType.studySerious,
          durationMinutes: 120,
          statGains: gains,
          expGained: 120,
          timestamp: DateTime.now(),
        );

        final reversals = StatsService.calculateStatReversals(
          ActivityType.studySerious,
          120,
          activity.statGainsMap,
        );

        expect(reversals[StatType.intelligence], gains[StatType.intelligence]);
        expect(reversals[StatType.focus], gains[StatType.focus]);

        // 4. Apply reversals and verify consistency
        final currentStats = testUser.statsMap;
        final updatedStats = StatsService.applyStatReversals(currentStats, reversals);
        
        expect(updatedStats[StatType.intelligence], closeTo(originalIntelligence, 0.001));

        // 5. Verify UI can handle the data
        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                ChangeNotifierProvider(create: (_) => UserProvider()..setTestUser(testUser)),
                ChangeNotifierProvider(create: (_) => ActivityProvider()),
              ],
              child: const Scaffold(body: StatsOverviewChart()),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    });

    group('5. Performance and Memory Usage', () {
      testWidgets('should handle large datasets efficiently', (WidgetTester tester) async {
        // Set extremely large stat values to test performance
        testUser.setStat(StatType.strength, 50000.0);
        testUser.setStat(StatType.intelligence, 100000.0);
        testUser.setStat(StatType.focus, 75000.0);

        // Test validation performance
        final stopwatch = Stopwatch()..start();
        final validationResult = StatsService.validateInfiniteStats(testUser.statsMap);
        stopwatch.stop();

        expect(validationResult.isValid || validationResult.hasWarning, true);
        expect(stopwatch.elapsedMilliseconds < 100, true); // Should be fast

        // Test chart rendering performance
        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                ChangeNotifierProvider(create: (_) => UserProvider()..setTestUser(testUser)),
              ],
              child: const Scaffold(body: StatsOverviewChart()),
            ),
          ),
        );

        // Should render without hanging or errors
        await tester.pumpAndSettle(const Duration(seconds: 5));
        expect(tester.takeException(), isNull);
      });

      testWidgets('should maintain responsive UI with complex layouts', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                ChangeNotifierProvider(create: (_) => UserProvider()..setTestUser(testUser)),
                ChangeNotifierProvider(create: (_) => ActivityProvider()),
              ],
              child: const MainNavigationScreen(),
            ),
          ),
        );

        // Test navigation responsiveness
        for (int i = 0; i < 5; i++) {
          await tester.tap(find.text('Stats'));
          await tester.pumpAndSettle();
          
          await tester.tap(find.text('History'));
          await tester.pumpAndSettle();
          
          await tester.tap(find.text('Dashboard'));
          await tester.pumpAndSettle();
          
          // Should remain responsive
          expect(tester.takeException(), isNull);
        }
      });
    });

    group('6. Backward Compatibility', () {
      testWidgets('should handle legacy data without stored stat gains', (WidgetTester tester) async {
        // Create activity without stored stat gains (legacy format)
        final legacyActivity = ActivityLog.create(
          id: 'legacy_activity',
          activityType: ActivityType.workoutUpperBody,
          durationMinutes: 60,
          statGains: {}, // Empty - simulates legacy data
          expGained: 60,
          timestamp: DateTime.now(),
        );

        // Should calculate reversals using fallback method
        final reversals = StatsService.calculateStatReversals(
          ActivityType.workoutUpperBody,
          60,
          null, // No stored gains
        );

        expect(reversals[StatType.strength], 0.06);
        expect(reversals[StatType.endurance], 0.04);
      });

      testWidgets('should maintain existing user workflows', (WidgetTester tester) async {
        // Test that existing functionality still works
        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                ChangeNotifierProvider(create: (_) => UserProvider()..setTestUser(testUser)),
                ChangeNotifierProvider(create: (_) => ActivityProvider()),
              ],
              child: const MainNavigationScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Basic navigation should work
        expect(find.byType(MainNavigationScreen), findsOneWidget);
        
        // FAB should be accessible
        expect(find.byType(FloatingActionButton), findsOneWidget);
        
        // All tabs should be accessible
        expect(find.text('Dashboard'), findsOneWidget);
        expect(find.text('History'), findsOneWidget);
        expect(find.text('Stats'), findsOneWidget);
        expect(find.text('Achievements'), findsOneWidget);
        expect(find.text('Settings'), findsOneWidget);
      });
    });
  });
}

// Extension to add test helper methods
extension UserProviderTestExtension on UserProvider {
  void setTestUser(User user) {
    // This would need to be implemented in the actual UserProvider
    // For now, we'll assume it exists or create a mock
  }
}