import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/activity_provider.dart';
import '../widgets/level_exp_display.dart';
import '../widgets/stats_overview_chart.dart';
import '../widgets/daily_summary_widget.dart';
import '../widgets/level_up_celebration.dart';
import '../widgets/level_up_overlay.dart';
import '../services/activity_service.dart';
import 'activity_logging_screen.dart';
import 'activity_history_screen.dart';

/// Main dashboard screen showing user progress and stats
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isInitialized = false;
  bool _showLevelUpAnimation = false;
  int? _celebrationLevel;

  @override
  void initState() {
    super.initState();
    // Schedule initialization for after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    if (_isInitialized) return;
    
    final userProvider = context.read<UserProvider>();
    final activityProvider = context.read<ActivityProvider>();
    
    try {
      // Initialize providers if needed
      if (!userProvider.hasUser) {
        await userProvider.initializeApp();
      }
      
      await activityProvider.initialize();
      _isInitialized = true;
    } catch (e) {
      // Handle initialization errors gracefully
      debugPrint('Error initializing dashboard: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LevelUpOverlay(
      showCelebration: _showLevelUpAnimation,
      newLevel: _celebrationLevel,
      onAnimationComplete: _onLevelUpAnimationComplete,
      child: Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Solo Leveling',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // TODO: Navigate to profile screen
            },
          ),
        ],
      ),
      body: Consumer2<UserProvider, ActivityProvider>(
        builder: (context, userProvider, activityProvider, child) {
          if (userProvider.isLoading || activityProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (userProvider.errorMessage != null) {
            return Center(
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
                    'Error loading data',
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
                    onPressed: () => _initializeData(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!userProvider.hasUser) {
            return const Center(
              child: Text(
                'No user data found',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Level and EXP Display
                  const LevelExpDisplay(),
                  
                  const SizedBox(height: 24),
                  
                  // Stats Overview Chart
                  const StatsOverviewChart(),
                  
                  const SizedBox(height: 24),
                  
                  // Daily Summary
                  const DailySummaryWidget(),
                  
                  const SizedBox(height: 100), // Space for FAB
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToActivityLogging(),
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add),
      ),
      ),
    );
  }

  Future<void> _refreshData() async {
    final userProvider = context.read<UserProvider>();
    final activityProvider = context.read<ActivityProvider>();
    
    await Future.wait([
      userProvider.refreshUser(),
      activityProvider.refreshAll(),
    ]);
  }

  Future<void> _navigateToActivityLogging() async {
    final result = await Navigator.of(context).push<ActivityLogResult>(
      MaterialPageRoute(
        builder: (context) => const ActivityLoggingScreen(),
      ),
    );

    // If activity was logged successfully, refresh the dashboard
    if (result != null && result.success) {
      await _refreshData();
      
      // Show level up celebration if user leveled up
      if (result.leveledUp) {
        _showLevelUpCelebration(result.newLevel);
      }
    }
  }

  void _showLevelUpCelebration(int newLevel) {
    setState(() {
      _celebrationLevel = newLevel;
      _showLevelUpAnimation = true;
    });
  }

  void _onLevelUpAnimationComplete() {
    setState(() {
      _showLevelUpAnimation = false;
      _celebrationLevel = null;
    });
  }
}