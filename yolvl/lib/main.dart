import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'utils/hive_config.dart';
import 'utils/accessibility_helper.dart';
import 'providers/user_provider.dart';
import 'providers/activity_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/achievement_provider.dart';
import 'providers/daily_login_provider.dart';
import 'screens/app_wrapper_screen.dart';
import 'screens/onboarding_screen.dart';
import 'theme/solo_leveling_theme.dart';

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
        ChangeNotifierProvider(create: (_) => DailyLoginProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return MaterialApp(
            title: 'YOLVL - Solo Leveling Life',
            theme: SoloLevelingTheme.buildLightTheme(),
            darkTheme: SoloLevelingTheme.buildDarkTheme(),
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

  // Theme methods removed - now using SoloLevelingTheme class
  // This provides better organization and more comprehensive theming
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
    final dailyLoginProvider = context.read<DailyLoginProvider>();
    
    try {
      // Initialize settings first
      await settingsProvider.initialize();
      
      // Initialize user data
      await userProvider.initializeApp();
      
      // Initialize daily login system
      await dailyLoginProvider.initialize();
      
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
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: SoloLevelingGradients.hunterProgress,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: SoloLevelingColors.electricBlue.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Solo Leveling',
                style: SoloLevelingTypography.hunterTitle.copyWith(
                  fontSize: 36,
                  shadows: [
                    Shadow(
                      color: SoloLevelingColors.electricBlue.withValues(alpha: 0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Level up your life',
                style: SoloLevelingTypography.hunterSubtitle.copyWith(
                  color: SoloLevelingColors.silverMist,
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

        // User is ready, show main app with daily login integration
        return const AppWrapperScreen();
      },
    );
  }
}

