import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yolvl/models/enums.dart';
import 'package:yolvl/widgets/floating_stat_gain_animation.dart';

void main() {
  group('FloatingStatGainAnimation', () {
    testWidgets('should display stat gains', (WidgetTester tester) async {
      final statGains = {
        StatType.strength: 0.06,
        StatType.endurance: 0.04,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingStatGainAnimation(
              statGains: statGains,
              expGained: 60.0,
            ),
          ),
        ),
      );

      // The animation should start immediately
      await tester.pump();
      
      // Check that the animation widgets are present
      expect(find.byType(AnimatedBuilder), findsAtLeastNWidgets(1));
    });

    testWidgets('should show floating gain overlay', (WidgetTester tester) async {
      final statGains = {
        StatType.strength: 0.06,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: FloatingGainOverlay(
            showGains: true,
            statGains: statGains,
            expGained: 60.0,
            child: const Text('Test Child'),
          ),
        ),
      );

      // Should show the child
      expect(find.text('Test Child'), findsOneWidget);
      
      // Should show the animation when showGains is true
      expect(find.byType(FloatingStatGainAnimation), findsOneWidget);
    });

    testWidgets('should not show animation when showGains is false', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FloatingGainOverlay(
            showGains: false,
            child: const Text('Test Child'),
          ),
        ),
      );

      // Should show the child
      expect(find.text('Test Child'), findsOneWidget);
      
      // Should not show the animation when showGains is false
      expect(find.byType(FloatingStatGainAnimation), findsNothing);
    });
  });
}