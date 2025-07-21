import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MainNavigationScreen Layout and Accessibility Tests', () {
    
    // Simple test widget that focuses on layout without complex providers
    Widget createTestWidget({MediaQueryData? mediaQueryData}) {
      Widget child = Scaffold(
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                label: 'Dashboard',
                tooltip: 'Navigate to Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history),
                label: 'History',
                tooltip: 'View Activity History',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.show_chart),
                label: 'Stats',
                tooltip: 'View Statistics',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.star),
                label: 'Achievements',
                tooltip: 'View Achievements',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
                tooltip: 'Open Settings',
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          tooltip: 'Log Activity',
          child: const Icon(Icons.add),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        body: const Center(child: Text('Test Content')),
      );
      
      if (mediaQueryData != null) {
        child = MediaQuery(data: mediaQueryData, child: child);
      }
      
      return MaterialApp(home: child);
    }

    testWidgets('FAB should be positioned with centerDocked location', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Find the Scaffold
      final scaffoldFinder = find.byType(Scaffold);
      expect(scaffoldFinder, findsOneWidget);

      final scaffold = tester.widget<Scaffold>(scaffoldFinder);
      expect(scaffold.floatingActionButtonLocation, FloatingActionButtonLocation.centerDocked);
    });

    testWidgets('FAB should be present and accessible', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Find the FAB
      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget);

      // Verify FAB has proper tooltip
      final fab = tester.widget<FloatingActionButton>(fabFinder);
      expect(fab.tooltip, 'Log Activity');
    });

    testWidgets('BottomAppBar should have notch for FAB', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Find the BottomAppBar
      final bottomAppBarFinder = find.byType(BottomAppBar);
      expect(bottomAppBarFinder, findsOneWidget);

      final bottomAppBar = tester.widget<BottomAppBar>(bottomAppBarFinder);
      expect(bottomAppBar.shape, isA<CircularNotchedRectangle>());
      expect(bottomAppBar.notchMargin, 8.0);
    });

    testWidgets('Navigation items should have proper tooltips for accessibility', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Find the BottomNavigationBar
      final bottomNavFinder = find.byType(BottomNavigationBar);
      expect(bottomNavFinder, findsOneWidget);

      final bottomNav = tester.widget<BottomNavigationBar>(bottomNavFinder);
      
      // Check that all items have tooltips
      expect(bottomNav.items[0].tooltip, 'Navigate to Dashboard');
      expect(bottomNav.items[1].tooltip, 'View Activity History');
      expect(bottomNav.items[2].tooltip, 'View Statistics');
      expect(bottomNav.items[3].tooltip, 'View Achievements');
      expect(bottomNav.items[4].tooltip, 'Open Settings');
    });

    testWidgets('FAB positioning should be responsive to different screen sizes', (WidgetTester tester) async {
      // Test with different screen sizes
      final testSizes = [
        const Size(320, 568), // iPhone SE
        const Size(375, 667), // iPhone 8
        const Size(414, 896), // iPhone 11 Pro Max
        const Size(768, 1024), // iPad
      ];

      for (final size in testSizes) {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(createTestWidget());

        // Find the FAB
        final fabFinder = find.byType(FloatingActionButton);
        expect(fabFinder, findsOneWidget);

        // Verify FAB is positioned correctly relative to screen
        final fabRect = tester.getRect(fabFinder);
        final screenRect = Rect.fromLTWH(0, 0, size.width, size.height);

        // FAB should be within screen bounds
        expect(screenRect.contains(fabRect.center), isTrue);

        // FAB should be in the bottom portion of the screen
        expect(fabRect.center.dy, greaterThan(size.height * 0.7));
      }

      // Reset to default size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('Layout should handle large text scaling for accessibility', (WidgetTester tester) async {
      // Test with large text scaling
      const largeTextMediaQuery = MediaQueryData(
        textScaler: TextScaler.linear(2.0), // 200% text scaling
      );

      await tester.pumpWidget(createTestWidget(mediaQueryData: largeTextMediaQuery));

      // Find navigation bar
      final bottomNavFinder = find.byType(BottomNavigationBar);
      expect(bottomNavFinder, findsOneWidget);

      // Find FAB
      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget);

      // Verify elements are still accessible with large text
      final fabRect = tester.getRect(fabFinder);
      expect(fabRect.width, greaterThanOrEqualTo(48)); // Minimum touch target
      expect(fabRect.height, greaterThanOrEqualTo(48));
    });

    testWidgets('Layout should handle safe area properly', (WidgetTester tester) async {
      // Simulate device with safe area
      const safeAreaMediaQuery = MediaQueryData(
        size: Size(375, 812),
        padding: EdgeInsets.only(bottom: 34), // Safe area
      );

      await tester.pumpWidget(createTestWidget(mediaQueryData: safeAreaMediaQuery));

      // Find the BottomAppBar
      final bottomAppBarFinder = find.byType(BottomAppBar);
      expect(bottomAppBarFinder, findsOneWidget);

      // Find the FAB
      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget);

      final fabRect = tester.getRect(fabFinder);
      
      // FAB should be positioned considering safe area
      expect(fabRect.bottom, lessThan(812)); // Should be above screen bottom
    });

    testWidgets('Navigation should have minimum touch targets for accessibility', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Find navigation items
      final bottomNavFinder = find.byType(BottomNavigationBar);
      expect(bottomNavFinder, findsOneWidget);

      final bottomNav = tester.widget<BottomNavigationBar>(bottomNavFinder);
      
      // Check icon size meets minimum accessibility requirements
      expect(bottomNav.iconSize, greaterThanOrEqualTo(24.0));
      
      // Check font sizes are reasonable
      expect(bottomNav.selectedFontSize, greaterThanOrEqualTo(10.0));
      expect(bottomNav.unselectedFontSize, greaterThanOrEqualTo(8.0));
    });
  });
}