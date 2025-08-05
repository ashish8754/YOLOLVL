import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../models/enums.dart';
import '../services/stats_service.dart';
import '../utils/accessibility_helper.dart';
import 'backup_screen.dart';

/// Settings screen with customization options
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSettings();
    });
  }

  Future<void> _initializeSettings() async {
    if (_isInitialized) return;
    
    final settingsProvider = context.read<SettingsProvider>();
    await settingsProvider.initialize();
    _isInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        elevation: 0,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          if (settingsProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (settingsProvider.errorMessage != null) {
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
                    'Error loading settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    settingsProvider.errorMessage!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => _initializeSettings(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildThemeSection(settingsProvider),
                const SizedBox(height: 24),
                _buildAccessibilitySection(settingsProvider),
                const SizedBox(height: 24),
                _buildActivitySection(settingsProvider),
                const SizedBox(height: 24),
                _buildCustomStatsSection(settingsProvider),
                const SizedBox(height: 24),
                _buildGameplaySection(settingsProvider),
                const SizedBox(height: 24),
                _buildNotificationSection(settingsProvider),
                const SizedBox(height: 24),
                _buildUISection(settingsProvider),
                const SizedBox(height: 24),
                _buildDataSection(settingsProvider),
                const SizedBox(height: 100), // Space for bottom navigation
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildThemeSection(SettingsProvider settingsProvider) {
    return _buildSection(
      title: 'Appearance',
      icon: Icons.palette,
      children: [
        SwitchListTile(
          title: const Text('Dark Mode'),
          subtitle: const Text('Use dark theme for better night viewing'),
          value: settingsProvider.isDarkMode,
          onChanged: (value) => settingsProvider.setDarkMode(value),
          secondary: Icon(
            settingsProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildActivitySection(SettingsProvider settingsProvider) {
    return _buildSection(
      title: 'Activities',
      icon: Icons.fitness_center,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Enable or disable specific activities for logging',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ),
        ...ActivityType.values.map((activityType) {
          return SwitchListTile(
            title: Text(activityType.displayName),
            subtitle: Text(_getActivityDescription(activityType)),
            value: settingsProvider.isActivityEnabled(activityType),
            onChanged: (value) => settingsProvider.setActivityEnabled(activityType, value),
            secondary: Icon(
              activityType.icon,
              color: activityType.color,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCustomStatsSection(SettingsProvider settingsProvider) {
    return _buildSection(
      title: 'Custom Stat Increments',
      icon: Icons.tune,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Adjust stat gain rates for each activity (leave empty for defaults)',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ),
        ...ActivityType.values.where((activity) => settingsProvider.isActivityEnabled(activity)).map((activityType) {
          return _buildCustomStatTile(activityType, settingsProvider);
        }),
        if (settingsProvider.hasCustomStatIncrements()) ...[
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: () => _showResetCustomStatsDialog(settingsProvider),
              icon: const Icon(Icons.restore),
              label: const Text('Reset All to Defaults'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCustomStatTile(ActivityType activityType, SettingsProvider settingsProvider) {
    final defaultGains = StatsService.getDefaultStatGains(activityType);
    
    return ExpansionTile(
      leading: Icon(activityType.icon, color: activityType.color),
      title: Text(activityType.displayName),
      subtitle: Text('${defaultGains.length} stat${defaultGains.length == 1 ? '' : 's'} affected'),
      children: defaultGains.entries.map((entry) {
        final statType = entry.key;
        final defaultValue = entry.value;
        final customValue = settingsProvider.getCustomStatIncrement(activityType, statType);
        
        return ListTile(
          leading: Icon(
            statType.icon,
            size: 20,
          ),
          title: Text(statType.displayName),
          subtitle: Text('Default: +${defaultValue.toStringAsFixed(3)}/hr'),
          trailing: SizedBox(
            width: 100,
            child: TextFormField(
              initialValue: customValue?.toStringAsFixed(3) ?? '',
              decoration: InputDecoration(
                hintText: defaultValue.toStringAsFixed(3),
                suffixText: '/hr',
                isDense: true,
                border: const OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                if (value.isEmpty) {
                  settingsProvider.removeCustomStatIncrement(activityType, statType);
                } else {
                  final increment = double.tryParse(value);
                  if (increment != null && increment >= 0) {
                    settingsProvider.setCustomStatIncrement(activityType, statType, increment);
                  }
                }
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGameplaySection(SettingsProvider settingsProvider) {
    return _buildSection(
      title: 'Gameplay',
      icon: Icons.games,
      children: [
        SwitchListTile(
          title: const Text('Relaxed Weekend Mode'),
          subtitle: const Text('Exclude weekends from stat degradation'),
          value: settingsProvider.relaxedWeekendMode,
          onChanged: (value) => settingsProvider.toggleRelaxedWeekendMode(),
          secondary: Icon(
            Icons.weekend,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        SwitchListTile(
          title: const Text('Degradation Warnings'),
          subtitle: const Text('Show warnings when stats are about to degrade'),
          value: settingsProvider.degradationWarningsEnabled,
          onChanged: (value) => settingsProvider.toggleDegradationWarnings(),
          secondary: Icon(
            Icons.warning,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationSection(SettingsProvider settingsProvider) {
    return _buildSection(
      title: 'Notifications',
      icon: Icons.notifications,
      children: [
        SwitchListTile(
          title: const Text('Daily Reminders'),
          subtitle: const Text('Get reminded to log your activities'),
          value: settingsProvider.notificationsEnabled,
          onChanged: (value) => settingsProvider.setNotificationsEnabled(value),
          secondary: Icon(
            Icons.notification_important,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        if (settingsProvider.notificationsEnabled)
          ListTile(
            leading: Icon(
              Icons.schedule,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Reminder Time'),
            subtitle: Text(settingsProvider.formattedReminderTime),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showTimePicker(settingsProvider),
          ),
      ],
    );
  }

  Widget _buildUISection(SettingsProvider settingsProvider) {
    return _buildSection(
      title: 'User Interface',
      icon: Icons.design_services,
      children: [
        SwitchListTile(
          title: const Text('Level Up Animations'),
          subtitle: const Text('Show celebration animations when leveling up'),
          value: settingsProvider.levelUpAnimationsEnabled,
          onChanged: (value) => settingsProvider.toggleLevelUpAnimations(),
          secondary: Icon(
            Icons.celebration,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        SwitchListTile(
          title: const Text('Haptic Feedback'),
          subtitle: const Text('Vibrate on interactions and achievements'),
          value: settingsProvider.hapticFeedbackEnabled,
          onChanged: (value) => settingsProvider.toggleHapticFeedback(),
          secondary: Icon(
            Icons.vibration,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildDataSection(SettingsProvider settingsProvider) {
    return _buildSection(
      title: 'Data Management',
      icon: Icons.storage,
      children: [
        ListTile(
          leading: Icon(
            Icons.backup,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: const Text('Backup & Restore'),
          subtitle: const Text('Export, import, and manage your data'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const BackupScreen(),
            ),
          ),
        ),
        ListTile(
          leading: Icon(
            Icons.info_outline,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: const Text('Last Backup'),
          subtitle: Text(_getLastBackupText(settingsProvider)),
          trailing: settingsProvider.needsBackup
              ? Icon(
                  Icons.warning,
                  color: Theme.of(context).colorScheme.error,
                )
              : Icon(
                  Icons.check_circle,
                  color: Colors.green,
                ),
        ),
        ListTile(
          leading: Icon(
            Icons.restore,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: const Text('Reset Settings'),
          subtitle: const Text('Reset all settings to default values'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showResetSettingsDialog(settingsProvider),
        ),
      ],
    );
  }

  Widget _buildAccessibilitySection(SettingsProvider settingsProvider) {
    return _buildSection(
      title: 'Accessibility',
      icon: Icons.accessibility,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Accessibility features to improve app usability',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        AccessibilityHelper.createAccessibleCard(
          semanticLabel: 'High contrast mode toggle',
          child: SwitchListTile(
            title: Text(
              'High Contrast Mode',
              style: AccessibilityHelper.getAccessibleTextStyle(
                context,
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            subtitle: Text(
              'Increase contrast for better visibility',
              style: AccessibilityHelper.getAccessibleTextStyle(
                context,
                const TextStyle(fontSize: 14),
              ),
            ),
            value: AccessibilityHelper.isHighContrastEnabled(context),
            onChanged: (value) {
              // This would need to be implemented in settings provider
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('High contrast mode is controlled by system settings'),
                ),
              );
            },
            secondary: Icon(
              Icons.contrast,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        AccessibilityHelper.createAccessibleCard(
          semanticLabel: 'Large text information',
          child: ListTile(
            leading: Icon(
              Icons.text_fields,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              'Large Text',
              style: AccessibilityHelper.getAccessibleTextStyle(
                context,
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            subtitle: Text(
              'Text size follows system accessibility settings',
              style: AccessibilityHelper.getAccessibleTextStyle(
                context,
                const TextStyle(fontSize: 14),
              ),
            ),
            trailing: Text(
              'System',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        AccessibilityHelper.createAccessibleCard(
          semanticLabel: 'Screen reader support information',
          child: ListTile(
            leading: Icon(
              Icons.record_voice_over,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              'Screen Reader Support',
              style: AccessibilityHelper.getAccessibleTextStyle(
                context,
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            subtitle: Text(
              'Full support for VoiceOver and TalkBack',
              style: AccessibilityHelper.getAccessibleTextStyle(
                context,
                const TextStyle(fontSize: 14),
              ),
            ),
            trailing: Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        AccessibilityHelper.createAccessibleCard(
          semanticLabel: 'Touch targets information',
          child: ListTile(
            leading: Icon(
              Icons.touch_app,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              'Large Touch Targets',
              style: AccessibilityHelper.getAccessibleTextStyle(
                context,
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            subtitle: Text(
              'All interactive elements meet accessibility guidelines',
              style: AccessibilityHelper.getAccessibleTextStyle(
                context,
                const TextStyle(fontSize: 14),
              ),
            ),
            trailing: Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  String _getActivityDescription(ActivityType activityType) {
    final defaultGains = StatsService.getDefaultStatGains(activityType);
    final statNames = defaultGains.keys.map((stat) => stat.displayName).join(', ');
    return 'Affects: $statNames';
  }

  Future<void> _showTimePicker(SettingsProvider settingsProvider) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: settingsProvider.dailyReminderHour,
        minute: settingsProvider.dailyReminderMinute,
      ),
    );

    if (picked != null) {
      await settingsProvider.setDailyReminderTime(picked.hour, picked.minute);
    }
  }

  String _getLastBackupText(SettingsProvider settingsProvider) {
    final lastBackup = settingsProvider.lastBackupDate;
    final now = DateTime.now();
    final difference = now.difference(lastBackup);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _showResetSettingsDialog(SettingsProvider settingsProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'This will reset all settings to their default values. Your user data and activity logs will not be affected. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await settingsProvider.resetToDefaults();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings reset to defaults'),
          ),
        );
      }
    }
  }

  Future<void> _showResetCustomStatsDialog(SettingsProvider settingsProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Custom Stats'),
        content: const Text(
          'This will reset all custom stat increments to their default values. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Reset all custom stat increments
      final customIncrements = settingsProvider.getAllCustomStatIncrements();
      for (final key in customIncrements.keys.toList()) {
        final parts = key.split('_');
        if (parts.length == 2) {
          final activityType = ActivityType.values.firstWhere(
            (type) => type.name == parts[0],
            orElse: () => ActivityType.workoutWeights,
          );
          final statType = StatType.values.firstWhere(
            (type) => type.name == parts[1],
            orElse: () => StatType.strength,
          );
          await settingsProvider.removeCustomStatIncrement(activityType, statType);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Custom stat increments reset to defaults'),
          ),
        );
      }
    }
  }
}