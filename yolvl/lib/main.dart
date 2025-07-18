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
import 'screens/onboarding_screen.dart';

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
              child: const AppInitializer(),
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

/// Widget that handles app initialization and routing to onboarding or main app
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    final userProvider = context.read<UserProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    
    try {
      // Initialize settings first
      await settingsProvider.initialize();
      
      // Initialize user data
      await userProvider.initializeApp();
      
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('Error initializing app: $e');
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_awesome,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Solo Leveling',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Level up your life',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 48),
              CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      );
    }

    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (userProvider.isLoading) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (userProvider.errorMessage != null) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to initialize app',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    userProvider.errorMessage!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _initializeApp,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        // Check if user needs onboarding
        if (userProvider.needsOnboarding || !userProvider.hasUser) {
          return const OnboardingScreen();
        }

        // User is ready, show main app
        return const MainNavigationScreen();
      },
    );
  }
}

