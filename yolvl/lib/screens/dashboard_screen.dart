import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/activity_provider.dart';
import '../providers/achievement_provider.dart';
import '../widgets/hunter_profile_card.dart';
import '../widgets/hunter_stats_panel.dart';
import '../widgets/hunter_achievements_showcase.dart';
import '../widgets/stats_overview_chart.dart';
import '../widgets/daily_quest_panel.dart';
import '../widgets/level_up_overlay.dart';
import '../services/activity_service.dart';
import 'activity_logging_screen.dart';
import 'achievements_screen.dart';

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
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
        body: Consumer3<UserProvider, ActivityProvider, AchievementProvider>(
          builder:
              (
                context,
                userProvider,
                activityProvider,
                achievementProvider,
                child,
              ) {
                if (userProvider.isLoading || activityProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
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
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.7),
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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SafeArea(
                          minimum: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 0.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Hunter Profile Card - Main hunter info display
                                HunterProfileCard(
                                  displayMode: HunterProfileDisplayMode.expanded,
                                  onTap: _navigateToProfile,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                ),

                                // Hunter Achievements Showcase
                                HunterAchievementsShowcase(
                                  displayMode:
                                      HunterAchievementsDisplayMode.showcase,
                                  maxAchievements: 6,
                                  onViewAllTap: _navigateToAchievements,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  height: 200,
                                ),

                                // Hunter Stats Panel - Detailed stats view
                                HunterStatsPanel(
                                  displayMode: HunterStatsPanelMode.overview,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  height: 280,
                                ),

                                // Legacy components for backward compatibility
                                // Can be removed once fully migrated to Hunter components
                                const SizedBox(height: 16),

                                // Daily Quest Panel - Quest tracking and management
                                DailyQuestPanel(
                                  onQuestTap: () =>
                                      _navigateToQuestLogging(context),
                                ),

                                // Stats Overview Chart - Visual stats representation
                                const SizedBox(height: 16),
                                const StatsOverviewChart(),

                                // Bottom spacing for FAB
                                const SizedBox(height: 88),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
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
    final achievementProvider = context.read<AchievementProvider>();

    await Future.wait([
      userProvider.refreshUser(),
      activityProvider.refreshAll(),
      achievementProvider.refreshAchievements(),
    ]);
  }

  Future<void> _navigateToActivityLogging() async {
    final result = await Navigator.of(context).push<ActivityLogResult>(
      MaterialPageRoute(builder: (context) => const ActivityLoggingScreen()),
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

  Future<void> _navigateToQuestLogging(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ActivityLoggingScreen()),
    );
  }

  void _navigateToProfile() {
    // TODO: Navigate to detailed profile screen
    // For now, show a simple dialog with profile options
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hunter Profile'),
        content: const Text('Profile management coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _navigateToAchievements() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const AchievementsScreen()));
  }
}
