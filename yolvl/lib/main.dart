import 'package:flutter/material.dart';
import 'utils/hive_config.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for local storage
  await HiveConfig.initialize();
  
  runApp(const YolvlApp());
}

class YolvlApp extends StatelessWidget {
  const YolvlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'YOLVL - Solo Leveling Life',
        theme: ThemeData(
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
        ),
        home: const PlaceholderScreen(),
        debugShowCheckedModeBanner: false,
      );
  }
}

/// Temporary placeholder screen until dashboard is implemented
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'YOLVL',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Solo Leveling Life',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Gamify your self-improvement journey',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                'App is being built...\nCore infrastructure ready!',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}