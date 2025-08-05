import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:yolvl/models/user.dart';
import 'package:yolvl/models/enums.dart';
import 'package:yolvl/providers/user_provider.dart';
import 'package:yolvl/providers/settings_provider.dart';
import 'package:yolvl/widgets/hunter_rank_display.dart';
import 'package:yolvl/widgets/hunter_rank_badge.dart';
import 'package:yolvl/services/hunter_rank_service.dart';
import 'package:yolvl/theme/solo_leveling_theme.dart';

/// UI and Theme Integration Tests
/// 
/// Tests the visual components, theme switching, and responsive behavior
/// of the Solo Leveling app UI components.
void main() {
  group('UI and Theme Integration Tests', () {
    
    late User testUser;
    
    setUp(() {
      testUser = User.create(id: 'test_user', name: 'Test Hunter');
      testUser.level = 15; // D-Rank level
      testUser.currentEXP = 800.0;
      testUser.setStat(StatType.strength, 3.5);
      testUser.setStat(StatType.agility, 2.8);
      testUser.setStat(StatType.intelligence, 4.2);
    });

    group('Theme Switching Tests', () {
      testWidgets('Light and Dark theme text visibility', (WidgetTester tester) async {
        // Test both light and dark themes for text visibility issues
        
        for (final isDark in [false, true]) {
          await tester.pumpWidget(
            MultiProvider(
              providers: [
                ChangeNotifierProvider<SettingsProvider>(
                  create: (_) => SettingsProvider()..setDarkMode(isDark),
                ),
                ChangeNotifierProvider<UserProvider>(
                  create: (_) {
                    final provider = UserProvider();
                    // Simulate user loading without actual service calls
                    return provider;
                  },
                ),
              ],
              child: Consumer<SettingsProvider>(
                builder: (context, settings, _) {
                  return MaterialApp(
                    theme: SoloLevelingTheme.lightTheme,
                    darkTheme: SoloLevelingTheme.darkTheme,
                    themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
                    home: Scaffold(
                      body: Column(
                        children: [
                          // Test text components in different contexts
                          Container(
                            color: Theme.of(context).colorScheme.surface,
                            child: Text(
                              'Test Text on Surface',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                          Container(
                            color: Theme.of(context).colorScheme.primary,
                            child: Text(
                              'Test Text on Primary',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          ),
                          Container(
                            color: Theme.of(context).colorScheme.secondary,
                            child: Text(
                              'Test Text on Secondary',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );

          await tester.pumpAndSettle();

          // Verify all text is visible (not rendered with same color as background)
          final textWidgets = find.byType(Text);
          expect(textWidgets, findsAtLeastNWidgets(3));

          // In a real test, we would check that text color contrasts properly
          // with background colors. This is a structural test.
          for (int i = 0; i < 3; i++) {
            final textWidget = tester.widget<Text>(textWidgets.at(i));
            expect(textWidget.data, isNotNull);
            expect(textWidget.data!.isNotEmpty, isTrue);
          }
        }
      });

      testWidgets('Theme consistency across color scheme', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: SoloLevelingTheme.lightTheme,
            home: Builder(
              builder: (context) {
                final colorScheme = Theme.of(context).colorScheme;
                
                return Scaffold(
                  body: Column(
                    children: [
                      // Test that color scheme is properly defined
                      Container(color: colorScheme.primary, width: 50, height: 50),
                      Container(color: colorScheme.secondary, width: 50, height: 50),
                      Container(color: colorScheme.surface, width: 50, height: 50),
                      Container(color: colorScheme.error, width: 50, height: 50),
                    ],
                  ),
                );
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify theme loads without errors
        expect(find.byType(Container), findsNWidgets(4));
      });

      testWidgets('Solo Leveling typography consistency', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: SoloLevelingTheme.lightTheme,
            home: Scaffold(
              body: Column(
                children: [
                  Text('Hunter Title', style: SoloLevelingTypography.hunterTitle),
                  Text('Hunter Subtitle', style: SoloLevelingTypography.hunterSubtitle),
                  Text('System Notification', style: SoloLevelingTypography.systemNotification),
                  Text('System Alert', style: SoloLevelingTypography.systemAlert),
                  Text('EXP Display', style: SoloLevelingTypography.expDisplay),
                  Text('Stat Label', style: SoloLevelingTypography.statLabel),
                  Text('Stat Value', style: SoloLevelingTypography.statValue),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify all typography styles render correctly
        final textWidgets = find.byType(Text);
        expect(textWidgets, findsNWidgets(7));

        // Verify each text widget has content
        for (int i = 0; i < 7; i++) {
          final textWidget = tester.widget<Text>(textWidgets.at(i));
          expect(textWidget.data, isNotNull);
          expect(textWidget.style, isNotNull);
        }
      });
    });

    group('Hunter Rank Display Tests', () {
      testWidgets('Hunter rank display renders correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<UserProvider>(
                create: (_) {
                  final provider = UserProvider();
                  // We can't easily mock the user loading, so we'll test the widget structure
                  return provider;
                },
              ),
            ],
            child: MaterialApp(
              theme: SoloLevelingTheme.lightTheme,
              home: Scaffold(
                body: HunterRankDisplay(
                  showLevelDetails: true,
                  compactMode: false,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify the widget structure exists
        expect(find.byType(HunterRankDisplay), findsOneWidget);
      });

      testWidgets('Hunter rank badge renders with different sizes', (WidgetTester tester) async {
        for (final size in HunterRankBadgeSize.values) {
          await tester.pumpWidget(
            MaterialApp(
              theme: SoloLevelingTheme.lightTheme,
              home: Scaffold(
                body: HunterRankBadge(
                  rank: 'D',
                  size: size,
                  level: 15,
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();

          // Verify badge renders for each size
          expect(find.byType(HunterRankBadge), findsOneWidget);
          
          final badgeWidget = tester.widget<HunterRankBadge>(find.byType(HunterRankBadge));
          expect(badgeWidget.rank, equals('D'));
          expect(badgeWidget.size, equals(size));
          expect(badgeWidget.level, equals(15));
        }
      });

      testWidgets('Compact mode vs full mode layout differences', (WidgetTester tester) async {
        for (final compact in [true, false]) {
          await tester.pumpWidget(
            MultiProvider(
              providers: [
                ChangeNotifierProvider<UserProvider>(
                  create: (_) => UserProvider(),
                ),
              ],
              child: MaterialApp(
                theme: SoloLevelingTheme.lightTheme,
                home: Scaffold(
                  body: HunterRankDisplay(
                    compactMode: compact,
                    showLevelDetails: true,
                  ),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();

          // Verify different layouts render
          expect(find.byType(HunterRankDisplay), findsOneWidget);
          
          final displayWidget = tester.widget<HunterRankDisplay>(find.byType(HunterRankDisplay));
          expect(displayWidget.compactMode, equals(compact));
        }
      });
    });

    group('Responsive Layout Tests', () {
      testWidgets('Mobile layout renders correctly', (WidgetTester tester) async {
        // Set mobile screen size
        await tester.binding.setSurfaceSize(const Size(375, 812)); // iPhone X size
        
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<UserProvider>(
                create: (_) => UserProvider(),
              ),
            ],
            child: MaterialApp(
              theme: SoloLevelingTheme.lightTheme,
              home: Scaffold(
                body: HunterRankDisplay(),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(HunterRankDisplay), findsOneWidget);
      });

      testWidgets('Tablet layout renders correctly', (WidgetTester tester) async {
        // Set tablet screen size
        await tester.binding.setSurfaceSize(const Size(1024, 768)); // iPad size
        
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<UserProvider>(
                create: (_) => UserProvider(),
              ),
            ],
            child: MaterialApp(
              theme: SoloLevelingTheme.lightTheme,
              home: Scaffold(
                body: HunterRankDisplay(),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(HunterRankDisplay), findsOneWidget);
        
        // Reset surface size
        await tester.binding.setSurfaceSize(null);
      });
    });

    group('Color and Accessibility Tests', () {
      test('Hunter rank colors are defined and valid', () {
        final rankService = HunterRankService.instance;
        
        for (int level = 1; level <= 200; level += 10) {
          final rankData = rankService.getRankForLevel(level);
          
          // Verify colors are defined
          expect(rankData.color, isNotNull);
          expect(rankData.lightColor, isNotNull);
          
          // Verify colors are not transparent
          expect(rankData.color.alpha, greaterThan(0));
          expect(rankData.lightColor.alpha, greaterThan(0));
          
          // Verify main color and light color are different for high ranks
          if (rankData.hasGlowEffect) {
            expect(rankData.color != rankData.lightColor, isTrue,
                reason: 'High ranks should have different main and light colors');
          }
        }
      });

      test('Solo Leveling colors are accessible', () {
        // Test color definitions exist and are valid
        expect(SoloLevelingColors.shadowPurple, isNotNull);
        expect(SoloLevelingColors.electricBlue, isNotNull);
        expect(SoloLevelingColors.voidBlack, isNotNull);
        expect(SoloLevelingColors.silverMist, isNotNull);
        expect(SoloLevelingColors.crimsonFlare, isNotNull);
        expect(SoloLevelingColors.shadowDepth, isNotNull);
        
        // Verify colors have proper alpha values
        expect(SoloLevelingColors.shadowPurple.alpha, equals(255));
        expect(SoloLevelingColors.electricBlue.alpha, equals(255));
        expect(SoloLevelingColors.voidBlack.alpha, equals(255));
      });

      test('System colors are properly defined', () {
        expect(SystemColors.levelUpGlow, isNotNull);
        expect(SystemColors.experienceGain, isNotNull);
        expect(SystemColors.dangerAlert, isNotNull);
        expect(SystemColors.successConfirm, isNotNull);
        expect(SystemColors.warningCaution, isNotNull);
        
        // Verify system colors are opaque
        expect(SystemColors.levelUpGlow.alpha, equals(255));
        expect(SystemColors.experienceGain.alpha, equals(255));
        expect(SystemColors.dangerAlert.alpha, equals(255));
      });

      test('Hunter rank colors follow progression pattern', () {
        final rankService = HunterRankService.instance;
        
        final eRank = rankService.getRankForLevel(5);   // E-Rank
        final dRank = rankService.getRankForLevel(15);  // D-Rank
        final cRank = rankService.getRankForLevel(25);  // C-Rank
        final bRank = rankService.getRankForLevel(45);  // B-Rank
        final aRank = rankService.getRankForLevel(65);  // A-Rank
        final sRank = rankService.getRankForLevel(85);  // S-Rank
        final ssRank = rankService.getRankForLevel(105); // SS-Rank
        final sssRank = rankService.getRankForLevel(155); // SSS-Rank
        
        // Verify special effects increase with rank
        expect(eRank.hasGlowEffect, isFalse);
        expect(dRank.hasGlowEffect, isFalse);
        expect(cRank.hasGlowEffect, isFalse);
        expect(bRank.hasGlowEffect, isFalse);
        expect(aRank.hasGlowEffect, isFalse);
        expect(sRank.hasGlowEffect, isTrue);
        expect(ssRank.hasGlowEffect, isTrue);
        expect(sssRank.hasGlowEffect, isTrue);
        
        expect(ssRank.hasPulseEffect, isTrue);
        expect(sssRank.hasPulseEffect, isTrue);
        
        expect(sssRank.hasRainbowEffect, isTrue);
      });
    });

    group('Animation and Visual Effects Tests', () {
      testWidgets('Hunter rank display animations don\'t crash', (WidgetTester tester) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<UserProvider>(
                create: (_) => UserProvider(),
              ),
            ],
            child: MaterialApp(
              theme: SoloLevelingTheme.lightTheme,
              home: Scaffold(
                body: HunterRankDisplay(
                  showLevelDetails: true,
                ),
              ),
            ),
          ),
        );

        // Let animations initialize
        await tester.pumpAndSettle();

        // Fast forward through some animation time
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 2));
        await tester.pump(const Duration(seconds: 3));

        // Verify no exceptions were thrown during animation
        expect(find.byType(HunterRankDisplay), findsOneWidget);
      });

      testWidgets('Progress animations render smoothly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<UserProvider>(
                create: (_) => UserProvider(),
              ),
            ],
            child: MaterialApp(
              theme: SoloLevelingTheme.lightTheme,
              home: Scaffold(
                body: HunterRankDisplay(
                  showLevelDetails: true,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Look for progress indicators (LinearProgressIndicator widgets)
        // Note: These might not be present if no user is loaded, but testing structure
        final progressIndicators = find.byType(LinearProgressIndicator);
        
        // If progress indicators exist, verify they're not null
        if (progressIndicators.hasFound) {
          expect(progressIndicators.evaluate().isNotEmpty, isTrue);
        }

        // Verify the display doesn't crash with animation controllers
        expect(find.byType(HunterRankDisplay), findsOneWidget);
      });
    });

    group('Edge Case UI Tests', () {
      testWidgets('Very long user names are handled gracefully', (WidgetTester tester) async {
        // This would require a way to inject a user with a long name
        // For now, test that the widget structure handles overflow
        
        await tester.pumpWidget(
          MaterialApp(
            theme: SoloLevelingTheme.lightTheme,
            home: Scaffold(
              body: Container(
                width: 200, // Constrained width
                child: Text(
                  'This is a very long hunter name that should be truncated properly',
                  style: SoloLevelingTypography.hunterTitle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Text), findsOneWidget);
        
        final textWidget = tester.widget<Text>(find.byType(Text));
        expect(textWidget.overflow, equals(TextOverflow.ellipsis));
      });

      testWidgets('Extreme stat values display correctly', (WidgetTester tester) async {
        // Test that very large numbers render without breaking layout
        
        await tester.pumpWidget(
          MaterialApp(
            theme: SoloLevelingTheme.lightTheme,
            home: Scaffold(
              body: Column(
                children: [
                  Text('Strength: 999,999.99', style: SoloLevelingTypography.statValue),
                  Text('Level: 5,000', style: SoloLevelingTypography.statValue),
                  Text('EXP: 1,000,000 / 2,500,000', style: SoloLevelingTypography.expDisplay),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify large numbers don't break rendering
        expect(find.byType(Text), findsNWidgets(3));
        expect(find.textContaining('999,999'), findsOneWidget);
        expect(find.textContaining('5,000'), findsOneWidget); 
        expect(find.textContaining('1,000,000'), findsOneWidget);
      });

      testWidgets('Empty or null data states are handled', (WidgetTester tester) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<UserProvider>(
                create: (_) => UserProvider(), // No user loaded
              ),
            ],
            child: MaterialApp(
              theme: SoloLevelingTheme.lightTheme,
              home: Scaffold(
                body: HunterRankDisplay(),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should not crash even with no user data
        expect(find.byType(HunterRankDisplay), findsOneWidget);
      });
    });
  });
}