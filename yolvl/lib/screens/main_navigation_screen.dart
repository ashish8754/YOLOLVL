import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dashboard_screen.dart';
import 'activity_history_screen.dart';
import 'activity_logging_screen.dart';
import 'stats_progression_screen.dart';
import 'achievements_screen.dart';
import 'settings_screen.dart';
import '../services/activity_service.dart';
import '../services/app_lifecycle_service.dart';
import '../providers/user_provider.dart';
import '../providers/activity_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/achievement_provider.dart';
import '../widgets/level_exp_display.dart';
import '../widgets/stats_overview_chart.dart';
import '../widgets/daily_summary_widget.dart';
import '../widgets/animated_fab.dart';
import '../utils/page_transitions.dart';

/// Main navigation screen with bottom navigation bar
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late final AppLifecycleService _appLifecycleService;
  late AnimationController _tabAnimationController;
  late Animation<double> _tabAnimation;
  
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _appLifecycleService = AppLifecycleService();
    _tabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _tabAnimation = CurvedAnimation(
      parent: _tabAnimationController,
      curve: Curves.easeInOutCubic,
    );
    _tabAnimationController.forward();
    
    _screens = [
      DashboardScreenContent(appLifecycleService: _appLifecycleService),
      const ActivityHistoryScreen(),
      const StatsProgressionScreen(),
      const AchievementsScreen(),
      const SettingsScreen(),
    ];
  }

  @override
  void dispose() {
    _appLifecycleService.dispose();
    _tabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.1, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              )),
              child: child,
            ),
          );
        },
        child: Container(
          key: ValueKey<int>(_currentIndex),
          child: _screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        selectedFontSize: 12,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: 'Achievements',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: Consumer<ActivityProvider>(
        builder: (context, activityProvider, child) {
          // Show pulse animation if no activities logged today
          final hasActivitiesToday = activityProvider.todaysActivities.isNotEmpty;
          return PulseFAB(
            onPressed: _navigateToActivityLogging,
            icon: Icons.add,
            tooltip: 'Log Activity',
            showPulse: !hasActivitiesToday,
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  void _onTabTapped(int index) {
    if (index != _currentIndex) {
      _tabAnimationController.reset();
      setState(() {
        _currentIndex = index;
      });
      _tabAnimationController.forward();
    }
  }

  Future<void> _navigateToActivityLogging() async {
    final result = await Navigator.of(context).pushSlideFade<ActivityLogResult>(
      const ActivityLoggingScreen(),
      direction: AxisDirection.up,
    );

    // If activity was logged successfully, refresh the current screen
    if (result != null && result.success) {
      // Trigger refresh based on current screen
      if (_currentIndex == 0) {
        // Dashboard - will be handled by the dashboard screen itself
      } else if (_currentIndex == 1) {
        // History - could trigger refresh here if needed
      }
    }
  }
}

/// Dashboard screen content without the scaffold (to be used in navigation)
class DashboardScreenContent extends StatefulWidget {
  final AppLifecycleService? appLifecycleService;
  
  const DashboardScreenContent({super.key, this.appLifecycleService});

  @override
  State<DashboardScreenContent> createState() => _DashboardScreenContentState();
}

class _DashboardScreenContentState extends State<DashboardScreenContent> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    if (_isInitialized) return;
    
    final userProvider = context.read<UserProvider>();
    final activityProvider = context.read<ActivityProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    final achievementProvider = context.read<AchievementProvider>();
    
    try {
      // Initialize settings first (includes notification service)
      await settingsProvider.initialize();
      
      // Initialize app lifecycle service (passed from parent)
      if (widget.appLifecycleService != null) {
        await widget.appLifecycleService!.initialize();
      }
      
      // Set up notification callbacks
      activityProvider.setLevelUpCallback((newLevel) {
        settingsProvider.sendLevelUpNotification(newLevel);
      });
      
      activityProvider.setStreakMilestoneCallback((streakDays) {
        settingsProvider.sendStreakNotification(streakDays);
      });
      
      if (!userProvider.hasUser) {
        await userProvider.initializeApp();
      }
      
      await activityProvider.initialize();
      await achievementProvider.loadAchievements();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing dashboard: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  const LevelExpDisplay(),
                  const SizedBox(height: 24),
                  const StatsOverviewChart(),
                  const SizedBox(height: 24),
                  const DailySummaryWidget(),
                  const SizedBox(height: 100), // Space for FAB
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _refreshData() async {
    final userProvider = context.read<UserProvider>();
    final activityProvider = context.read<ActivityProvider>();
    
    // Also refresh degradation status
    if (widget.appLifecycleService != null) {
      await widget.appLifecycleService!.refreshDegradationStatus();
    }
    
    await Future.wait([
      userProvider.refreshUser(),
      activityProvider.refreshAll(),
    ]);
  }
}