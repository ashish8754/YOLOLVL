import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'utils/hive_config.dart';
import 'utils/accessibility_helper.dart';
import 'providers/user_provider.dart';
import 'providers/activity_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/achievement_provider.dart';
import 'screens/main_navigation_screen.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize timezone data for notifications
  tz.initializeTimeZones();
  
  // Initialize Hive for local storage
  await HiveConfig.initialize();
  
  runApp(const YolvlApp());
}

class YolvlApp extends StatelessWidget {
  const YolvlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ActivityProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => AchievementProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return MaterialApp(
            title: 'YOLVL - Solo Leveling Life',
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            themeMode: settingsProvider.themeMode,
            home: HighContrastTheme(
              child: const MainNavigationScreen(),
            ),
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              // Ensure minimum text scale for accessibility
              final mediaQuery = MediaQuery.of(context);
              final textScaleFactor = mediaQuery.textScaler.scale(1.0).clamp(1.0, 2.0);
              
              return MediaQuery(
                data: mediaQuery.copyWith(
                  textScaler: TextScaler.linear(textScaleFactor),
                ),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      // Dark fantasy theme colors
      colorScheme: const ColorScheme.dark(
        surface: Color(0xFF0D1117), // Deep dark blue-black
        surfaceContainer: Color(0xFF161B22), // Slightly lighter dark
        primary: Color(0xFF238636), // Hunter green for stats/progress
        secondary: Color(0xFF1F6FEB), // Electric blue for EXP/level
        error: Color(0xFFF85149), // Warning red for degradation
        onSurface: Color(0xFFF0F6FC), // Near white text
        onPrimary: Color(0xFFF0F6FC), // Near white text
        onSecondary: Color(0xFFF0F6FC), // Near white text
      ),
      useMaterial3: true,
      fontFamily: 'Roboto',
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      // Light theme colors
      colorScheme: const ColorScheme.light(
        surface: Color(0xFFFFFFFF), // White
        surfaceContainer: Color(0xFFF6F8FA), // Light gray
        primary: Color(0xFF2DA44E), // Green
        secondary: Color(0xFF0969DA), // Blue
        error: Color(0xFFCF222E), // Red
        onSurface: Color(0xFF24292F), // Dark text
        onPrimary: Color(0xFFFFFFFF), // White text
        onSecondary: Color(0xFFFFFFFF), // White text
      ),
      useMaterial3: true,
      fontFamily: 'Roboto',
    );
  }
}

