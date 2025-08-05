import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import the system interface components
import '../services/system_overlay_service.dart';
import '../widgets/system_notification.dart';
import '../widgets/system_alert_dialog.dart';
import '../widgets/system_interface_demo.dart';

// Import existing providers and screens
import '../providers/user_provider.dart';
import '../providers/activity_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/achievement_provider.dart';
import '../screens/dashboard_screen.dart';
import '../screens/activity_history_screen.dart';
import '../screens/stats_progression_screen.dart';
import '../screens/achievements_screen.dart';
import '../screens/settings_screen.dart';
import '../theme/solo_leveling_theme.dart';
import '../theme/solo_leveling_icons.dart';

/// Enhanced main navigation screen with System interface integration
/// This shows how to modify the existing MainNavigationScreen to include
/// System notifications and dialogs
class EnhancedMainNavigationScreen extends StatefulWidget {
  const EnhancedMainNavigationScreen({super.key});

  @override
  State<EnhancedMainNavigationScreen> createState() => _EnhancedMainNavigationScreenState();
}

class _EnhancedMainNavigationScreenState extends State<EnhancedMainNavigationScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  final SystemOverlayService _systemOverlay = SystemOverlayService();

  // Animation controllers for enhanced UI
  late AnimationController _navAnimationController;
  late Animation<double> _navAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize system overlay service
    _systemOverlay.initialize();
    
    // Setup navigation animation
    _navAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _navAnimation = CurvedAnimation(
      parent: _navAnimationController,
      curve: Curves.easeInOut,
    );
    
    _navAnimationController.forward();
    
    // Setup app lifecycle listeners for system notifications
    _setupAppLifecycleListeners();
  }

  @override
  void dispose() {
    _navAnimationController.dispose();
    _systemOverlay.dispose();
    super.dispose();
  }

  void _setupAppLifecycleListeners() {
    // Listen to user provider changes for level ups
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      // Example: Listen for level changes (this would be integrated into UserProvider)
      // userProvider.addListener(() {
      //   if (userProvider.hasLeveledUp) {
      //     _handleLevelUp(userProvider.level, userProvider.lastExpGained);
      //   }
      // });
    });
  }

  void _handleLevelUp(int newLevel, double expGained) {
    // Show level up notification
    _systemOverlay.showLevelUp(
      newLevel: newLevel,
      expGained: expGained.toInt(),
      onTap: () {
        // Show detailed level up dialog when notification is tapped
        SystemAlerts.showLevelUp(
          context: context,
          newLevel: newLevel,
          expGained: expGained.toInt(),
          statGains: _calculateStatGainsForLevel(newLevel),
          newAbilities: _getNewAbilitiesForLevel(newLevel),
        );
      },
    );
  }

  Map<String, double> _calculateStatGainsForLevel(int level) {
    // Example stat gains calculation
    return {
      'Strength': (level * 0.1),
      'Agility': (level * 0.08),
      'Endurance': (level * 0.12),
      'Intelligence': (level * 0.06),
      'Focus': (level * 0.07),
      'Charisma': (level * 0.05),
    };
  }

  List<String> _getNewAbilitiesForLevel(int level) {
    // Example abilities unlocked at certain levels
    final abilities = <String>[];
    
    if (level == 10) abilities.add('Daily Quest System');
    if (level == 25) abilities.add('Advanced Stat Tracking');
    if (level == 50) abilities.add('Achievement Mastery');
    if (level == 100) abilities.add('Shadow Clone Training');
    
    return abilities;
  }

  List<Widget> _buildScreens() {
    return [
      const DashboardScreen(),
      const ActivityHistoryScreen(),
      const StatsProgressionScreen(),
      const AchievementsScreen(),
      const SettingsScreen(),
      // Add the system interface demo as a hidden screen
      const SystemInterfaceDemo(),
    ];
  }

  List<BottomNavigationBarItem> _buildNavItems() {
    return [
      BottomNavigationBarItem(
        icon: Icon(SoloLevelingIcons.dashboard),
        label: 'Hunter HQ',
        tooltip: 'Dashboard - Main hunter status and overview',
      ),
      BottomNavigationBarItem(
        icon: Icon(SoloLevelingIcons.history),
        label: 'Quest Log',
        tooltip: 'Activity History - View completed quests',
      ),
      BottomNavigationBarItem(
        icon: Icon(SoloLevelingIcons.stats),
        label: 'Stats',
        tooltip: 'Stats Progression - Track your growth',
      ),
      BottomNavigationBarItem(
        icon: Icon(SoloLevelingIcons.achievements),
        label: 'Achievements',
        tooltip: 'Achievements - Unlock rewards and titles',
      ),
      BottomNavigationBarItem(
        icon: Icon(SoloLevelingIcons.settings),
        label: 'System',
        tooltip: 'Settings - Configure your hunter profile',
      ),
    ];
  }

  void _onNavItemTapped(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });
      
      // Show navigation feedback
      _systemOverlay.showInfo(
        title: 'SYSTEM',
        message: 'Navigated to ${_getScreenName(index)}',
      );
    }
  }

  String _getScreenName(int index) {
    switch (index) {
      case 0: return 'Hunter HQ';
      case 1: return 'Quest Log';
      case 2: return 'Stats Overview';
      case 3: return 'Achievements';
      case 4: return 'System Settings';
      default: return 'Unknown Screen';
    }
  }

  void _onFloatingActionButtonPressed() {
    // Show activity logging notification
    _systemOverlay.showInfo(
      title: 'QUEST LOGGING',
      message: 'Time to record your achievements!',
    );

    // Navigate to activity logging with system notification
    Navigator.of(context).pushNamed('/activity-logging').then((_) {
      // Show welcome back notification when returning
      _systemOverlay.showInfo(
        title: 'WELCOME BACK',
        message: 'Ready to log your next quest?',
      );
    });
  }

  Widget _buildFloatingActionButton() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return FloatingActionButton.extended(
          onPressed: _onFloatingActionButtonPressed,
          icon: Icon(SoloLevelingIcons.addQuest),
          label: const Text('LOG QUEST'),
          tooltip: 'Log Activity - Record your training and activities',
          backgroundColor: SoloLevelingColors.hunterGreen,
          foregroundColor: SoloLevelingColors.pureLight,
          elevation: 12,
          extendedPadding: const EdgeInsets.symmetric(horizontal: 20),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = _buildScreens();
    final navItems = _buildNavItems();

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: SoloLevelingGradients.mainBackground,
            ),
          ),
          
          // Main screen content
          FadeTransition(
            opacity: _navAnimation,
            child: IndexedStack(
              index: _currentIndex,
              children: screens,
            ),
          ),
          
          // System notification overlay
          ListenableBuilder(
            listenable: _systemOverlay,
            builder: (context, child) {
              return SystemNotificationDisplay(
                notifications: _systemOverlay.notifications,
                onNotificationDismissed: (index) {
                  _systemOverlay.dismissNotification(index);
                },
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 60,
                ),
              );
            },
          ),
        ],
      ),
      
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: SoloLevelingColors.voidBlack.withValues(alpha: 0.8),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, -4),
            ),
            BoxShadow(
              color: SoloLevelingColors.electricBlue.withValues(alpha: 0.1),
              blurRadius: 30,
              spreadRadius: 0,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(_navAnimation),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onNavItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: SoloLevelingColors.voidBlack.withValues(alpha: 0.95),
            selectedItemColor: SoloLevelingColors.electricBlue,
            unselectedItemColor: SoloLevelingColors.silverMist,
            elevation: 0,
            selectedFontSize: 11,
            unselectedFontSize: 10,
            iconSize: 24,
            items: navItems,
          ),
        ),
      ),
      
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      
      // Add a drawer with system interface demo access
      drawer: _buildSystemDrawer(),
    );
  }

  Widget _buildSystemDrawer() {
    return Drawer(
      backgroundColor: SoloLevelingColors.shadowDepth,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: SoloLevelingGradients.systemPanel,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  SoloLevelingIcons.systemNotification,
                  color: SoloLevelingColors.electricBlue,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'SYSTEM INTERFACE',
                  style: SoloLevelingTypography.hunterTitle.copyWith(
                    fontSize: 18,
                    color: SoloLevelingColors.electricBlue,
                  ),
                ),
                Text(
                  'Developer Tools',
                  style: SoloLevelingTypography.systemNotification.copyWith(
                    fontSize: 12,
                    color: SoloLevelingColors.silverMist,
                  ),
                ),
              ],
            ),
          ),
          
          ListTile(
            leading: Icon(
              SoloLevelingIcons.systemInfo,
              color: SoloLevelingColors.electricBlue,
            ),
            title: Text(
              'System Interface Demo',
              style: SoloLevelingTypography.systemNotification,
            ),
            subtitle: Text(
              'Test notifications and dialogs',
              style: SoloLevelingTypography.systemNotification.copyWith(
                fontSize: 12,
                color: SoloLevelingColors.silverMist,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SystemInterfaceDemo(),
                ),
              );
            },
          ),
          
          ListTile(
            leading: Icon(
              SoloLevelingIcons.systemSuccess,
              color: SoloLevelingColors.hunterGreen,
            ),
            title: Text(
              'Test Level Up',
              style: SoloLevelingTypography.systemNotification,
            ),
            onTap: () {
              Navigator.pop(context);
              _handleLevelUp(25, 1500);
            },
          ),
          
          ListTile(
            leading: Icon(
              SoloLevelingIcons.systemWarning,
              color: SystemColors.systemWarning,
            ),
            title: Text(
              'Test Warning',
              style: SoloLevelingTypography.systemNotification,
            ),
            onTap: () {
              Navigator.pop(context);
              _systemOverlay.showDegradationWarning(
                activities: ['Workout', 'Study'],
                daysMissed: 3,
              );
            },
          ),
          
          ListTile(
            leading: Icon(
              SoloLevelingIcons.systemError,
              color: SystemColors.systemError,
            ),
            title: Text(
              'Clear All Notifications',
              style: SoloLevelingTypography.systemNotification,
            ),
            onTap: () {
              Navigator.pop(context);
              _systemOverlay.dismissAll();
            },
          ),
          
          const Spacer(),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: ListenableBuilder(
              listenable: _systemOverlay,
              builder: (context, child) {
                final stats = _systemOverlay.getStatistics();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'System Status',
                      style: SoloLevelingTypography.systemNotification.copyWith(
                        color: SoloLevelingColors.electricBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Active: ${stats['activeNotifications']}/${stats['maxCapacity']}',
                      style: SoloLevelingTypography.systemNotification.copyWith(
                        fontSize: 12,
                        color: SoloLevelingColors.silverMist,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Provider integration helper
/// This class shows how to integrate the System overlay service with existing providers
class SystemIntegrationHelper {
  static void integrateWithProviders(BuildContext context) {
    final systemOverlay = SystemOverlayService();
    systemOverlay.initialize();

    // Example: Listen to UserProvider changes
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    // Example: Listen to ActivityProvider changes
    final activityProvider = Provider.of<ActivityProvider>(context, listen: false);
    
    // Example: Listen to AchievementProvider changes  
    final achievementProvider = Provider.of<AchievementProvider>(context, listen: false);

    // Add listeners (this would be done in the actual provider implementations)
    /*
    userProvider.addListener(() {
      if (userProvider.hasLeveledUp) {
        systemOverlay.showLevelUp(
          newLevel: userProvider.level,
          expGained: userProvider.lastExpGained.toInt(),
        );
      }
    });

    activityProvider.addListener(() {
      if (activityProvider.hasNewActivity) {
        systemOverlay.showActivityLogged(
          activityName: activityProvider.lastLoggedActivity.activityType.toString(),
          expGained: activityProvider.lastExpGained,
          duration: activityProvider.lastLoggedActivity.duration,
        );
      }
    });

    achievementProvider.addListener(() {
      if (achievementProvider.hasNewAchievement) {
        systemOverlay.showAchievement(
          achievementName: achievementProvider.lastUnlockedAchievement.name,
          description: achievementProvider.lastUnlockedAchievement.description,
        );
      }
    });
    */
  }
}