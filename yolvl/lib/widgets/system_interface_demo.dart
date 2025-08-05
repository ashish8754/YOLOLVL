import 'package:flutter/material.dart';
import '../services/system_overlay_service.dart';
import '../widgets/system_notification.dart';
import '../widgets/system_alert_dialog.dart';
import '../theme/solo_leveling_theme.dart';
import '../theme/glassmorphism_effects.dart';
import '../theme/solo_leveling_icons.dart';

/// Demo screen showing how to use the System interface components
class SystemInterfaceDemo extends StatefulWidget {
  const SystemInterfaceDemo({super.key});

  @override
  State<SystemInterfaceDemo> createState() => _SystemInterfaceDemoState();
}

class _SystemInterfaceDemoState extends State<SystemInterfaceDemo> {
  final SystemOverlayService _systemOverlay = SystemOverlayService();

  @override
  void initState() {
    super.initState();
    _systemOverlay.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Interface Demo'),
        backgroundColor: SoloLevelingColors.voidBlack,
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: SoloLevelingGradients.mainBackground,
            ),
          ),
          
          // Main content
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildNotificationSection(),
                const SizedBox(height: 32),
                _buildAlertDialogSection(),
                const SizedBox(height: 32),
                _buildAdvancedExamplesSection(),
                const SizedBox(height: 32),
                _buildServiceInfoSection(),
              ],
            ),
          ),
          
          // System notifications overlay
          ListenableBuilder(
            listenable: _systemOverlay,
            builder: (context, child) {
              return SystemNotificationDisplay(
                notifications: _systemOverlay.notifications,
                onNotificationDismissed: (index) {
                  _systemOverlay.dismissNotification(index);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSection() {
    return GlassmorphismEffects.hunterPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SYSTEM NOTIFICATIONS',
            style: SoloLevelingTypography.hunterTitle.copyWith(
              fontSize: 18,
              color: SoloLevelingColors.electricBlue,
            ),
          ),
          const SizedBox(height: 16),
          
          Text(
            'Test different notification types:',
            style: SoloLevelingTypography.systemNotification,
          ),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildDemoButton(
                'Level Up',
                () => _systemOverlay.showLevelUp(
                  newLevel: 25,
                  expGained: 1250,
                ),
                SystemColors.levelUpGlow,
              ),
              _buildDemoButton(
                'Stat Gain',
                () => _systemOverlay.showStatGain(
                  statName: 'Strength',
                  gainAmount: 2.5,
                  newValue: 45.8,
                ),
                SystemColors.systemSuccess,
              ),
              _buildDemoButton(
                'Achievement',
                () => _systemOverlay.showAchievement(
                  achievementName: 'First Steps',
                  description: 'Complete your first quest',
                ),
                SoloLevelingColors.mysticPurple,
              ),
              _buildDemoButton(
                'Quest Complete',
                () => _systemOverlay.showQuestComplete(
                  questName: 'Daily Workout',
                  expGained: 500,
                  statsAffected: ['Strength', 'Endurance'],
                ),
                SystemColors.systemSuccess,
              ),
              _buildDemoButton(
                'Warning',
                () => _systemOverlay.showWarning(
                  message: 'Your stats will degrade if you don\'t log activities!',
                ),
                SystemColors.systemWarning,
              ),
              _buildDemoButton(
                'Error',
                () => _systemOverlay.showError(
                  message: 'Failed to save activity data',
                ),
                SystemColors.systemError,
              ),
              _buildDemoButton(
                'Multiple Stats',
                () => _systemOverlay.showMultipleStatGains(
                  {
                    'Strength': 1.2,
                    'Endurance': 0.8,
                    'Agility': 1.5,
                  },
                  {
                    'Strength': 32.4,
                    'Endurance': 28.6,
                    'Agility': 41.2,
                  },
                ),
                SoloLevelingColors.hunterGreen,
              ),
              _buildDemoButton(
                'Clear All',
                () => _systemOverlay.dismissAll(),
                SoloLevelingColors.shadowGray,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertDialogSection() {
    return GlassmorphismEffects.hunterPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SYSTEM ALERT DIALOGS',
            style: SoloLevelingTypography.hunterTitle.copyWith(
              fontSize: 18,
              color: SoloLevelingColors.electricBlue,
            ),
          ),
          const SizedBox(height: 16),
          
          Text(
            'Test different dialog types:',
            style: SoloLevelingTypography.systemNotification,
          ),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildDemoButton(
                'Level Up Dialog',
                () => SystemAlerts.showLevelUp(
                  context: context,
                  newLevel: 30,
                  expGained: 2500,
                  statGains: {
                    'Strength': 3.2,
                    'Agility': 2.8,
                    'Intelligence': 1.5,
                  },
                  newAbilities: [
                    'Shadow Step',
                    'Increased Mana Pool',
                  ],
                ),
                SystemColors.levelUpGlow,
              ),
              _buildDemoButton(
                'Achievement',
                () => SystemAlerts.showAchievement(
                  context: context,
                  achievementName: 'Hunter\'s Dedication',
                  description: 'Log activities for 30 consecutive days',
                  rewardDescription: '+500 EXP, +5 All Stats',
                ),
                SoloLevelingColors.mysticPurple,
              ),
              _buildDemoButton(
                'Confirmation',
                () => SystemAlerts.showConfirmation(
                  context: context,
                  title: 'DELETE ACTIVITY',
                  message: 'Are you sure you want to delete this activity?\nThis action cannot be undone.',
                  destructive: true,
                ).then((confirmed) {
                  if (confirmed == true) {
                    _systemOverlay.showSuccess(
                      message: 'Activity deleted successfully',
                    );
                  }
                }),
                SystemColors.systemError,
              ),
              _buildDemoButton(
                'Warning',
                () => SystemAlerts.showWarning(
                  context: context,
                  title: 'STAT DEGRADATION',
                  message: 'You haven\'t logged any workout activities for 3 days.\nYour physical stats will start degrading tomorrow.',
                ).then((acknowledged) {
                  if (acknowledged == true) {
                    _systemOverlay.showInfo(
                      message: 'Degradation warning acknowledged',
                    );
                  }
                }),
                SystemColors.systemWarning,
              ),
              _buildDemoButton(
                'Error Dialog',
                () => SystemAlerts.showError(
                  context: context,
                  title: 'BACKUP FAILED',
                  message: 'Could not create backup file.\nPlease check your storage permissions and try again.',
                ),
                SystemColors.systemError,
              ),
              _buildDemoButton(
                'Info Dialog',
                () => SystemAlerts.showInfo(
                  context: context,
                  title: 'SYSTEM UPDATE',
                  message: 'New features have been added:\n• Enhanced stat tracking\n• Achievement system\n• Daily quests',
                ),
                SystemColors.systemInfo,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedExamplesSection() {
    return GlassmorphismEffects.hunterPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ADVANCED INTEGRATION EXAMPLES',
            style: SoloLevelingTypography.hunterTitle.copyWith(
              fontSize: 18,
              color: SoloLevelingColors.electricBlue,
            ),
          ),
          const SizedBox(height: 16),
          
          Text(
            'Real-world usage scenarios:',
            style: SoloLevelingTypography.systemNotification,
          ),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildDemoButton(
                'Activity Logged',
                () => _systemOverlay.showActivityLogged(
                  activityName: 'Weight Training',
                  expGained: 750,
                  duration: const Duration(hours: 1, minutes: 30),
                  statsAffected: ['Strength', 'Endurance'],
                ),
                SystemColors.systemSuccess,
              ),
              _buildDemoButton(
                'Daily Streak',
                () => _systemOverlay.showDailyStreak(streakDays: 15),
                SoloLevelingColors.hunterGreen,
              ),
              _buildDemoButton(
                'Degradation Warning',
                () => _systemOverlay.showDegradationWarning(
                  activities: ['Cardio', 'Study'],
                  daysMissed: 3,
                ),
                SystemColors.systemWarning,
              ),
              _buildDemoButton(
                'Backup Complete',
                () => _systemOverlay.showBackupComplete(
                  fileName: 'yolvl_backup_2024_08_04.json',
                ),
                SystemColors.systemSuccess,
              ),
              _buildDemoButton(
                'Custom Notification',
                () => _showCustomNotification(),
                SoloLevelingColors.mysticPurple,
              ),
              _buildDemoButton(
                'Sequence Demo',
                () => _showSequenceDemo(),
                SoloLevelingColors.electricBlue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceInfoSection() {
    return GlassmorphismEffects.systemPanel(
      isActive: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SERVICE STATUS',
            style: SoloLevelingTypography.hunterTitle.copyWith(
              fontSize: 16,
              color: SoloLevelingColors.electricBlue,
            ),
          ),
          const SizedBox(height: 12),
          
          ListenableBuilder(
            listenable: _systemOverlay,
            builder: (context, child) {
              final stats = _systemOverlay.getStatistics();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusRow('Active Notifications', '${stats['activeNotifications']}'),
                  _buildStatusRow('Max Capacity', '${stats['maxCapacity']}'),
                  _buildStatusRow('At Capacity', '${stats['isAtCapacity']}'),
                  _buildStatusRow('Initialized', '${stats['isInitialized']}'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: SoloLevelingTypography.systemNotification.copyWith(
              fontSize: 12,
              color: SoloLevelingColors.silverMist,
            ),
          ),
          Text(
            value,
            style: SoloLevelingTypography.systemNotification.copyWith(
              fontSize: 12,
              color: SoloLevelingColors.electricBlue,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoButton(String text, VoidCallback onPressed, Color color) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: SoloLevelingColors.pureLight,
        elevation: 8,
        shadowColor: color.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(
        text,
        style: SoloLevelingTypography.systemNotification.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showCustomNotification() {
    final customNotification = SystemNotificationData(
      title: 'CUSTOM SYSTEM MESSAGE',
      message: 'This is a custom notification with special content!',
      type: SystemNotificationType.info,
      customIcon: SoloLevelingIcons.systemNotification,
      displayDuration: const Duration(seconds: 6),
      onTap: () {
        SystemAlerts.showInfo(
          context: context,
          title: 'NOTIFICATION TAPPED',
          message: 'You tapped on the custom notification!',
        );
      },
      metadata: {'custom': true, 'demo': 'advanced'},
    );

    _systemOverlay.showNotification(customNotification);
  }

  void _showSequenceDemo() async {
    // Show a sequence of notifications to demonstrate queuing
    _systemOverlay.showInfo(
      title: 'SEQUENCE DEMO',
      message: 'Starting notification sequence...',
    );

    await Future.delayed(const Duration(milliseconds: 500));
    
    _systemOverlay.showStatGain(
      statName: 'Intelligence',
      gainAmount: 1.0,
      newValue: 25.0,
    );

    await Future.delayed(const Duration(milliseconds: 500));
    
    _systemOverlay.showQuestComplete(
      questName: 'Learning Quest',
      expGained: 200,
      statsAffected: ['Intelligence'],
    );

    await Future.delayed(const Duration(milliseconds: 500));
    
    _systemOverlay.showSuccess(
      title: 'SEQUENCE COMPLETE',
      message: 'All notifications have been queued!',
    );
  }
}