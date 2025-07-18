import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/activity_provider.dart';
import '../models/enums.dart';

/// Widget displaying daily summary with streaks and activity counts
class DailySummaryWidget extends StatelessWidget {
  const DailySummaryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserProvider, ActivityProvider>(
      builder: (context, userProvider, activityProvider, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                'Daily Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Activity stats row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: '🔥',
                      title: 'Streak',
                      value: _getLongestStreak(activityProvider),
                      subtitle: 'days',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: '📊',
                      title: 'Today',
                      value: activityProvider.getTodaysActivityCount().toString(),
                      subtitle: 'activities',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: '⭐',
                      title: 'EXP',
                      value: activityProvider.getTodaysEXP().toStringAsFixed(0),
                      subtitle: 'gained',
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Degradation warnings
              if (userProvider.degradationWarnings.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Theme.of(context).colorScheme.error,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Degradation Warnings',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...userProvider.degradationWarnings.map((warning) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            _formatDegradationWarning(warning),
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Recent activities
              if (activityProvider.recentActivities.isNotEmpty) ...[
                Text(
                  'Recent Activities',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 8),
                ...activityProvider.recentActivities.take(3).map((activity) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          activity.activityTypeEnum.icon,
                          size: 16,
                          color: activity.activityTypeEnum.color,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            activity.activityTypeEnum.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                        Text(
                          '${activity.durationMinutes}min',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '+${activity.expGained.toStringAsFixed(0)} EXP',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.fitness_center,
                        size: 32,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No activities logged yet',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap the + button to start your journey!',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Build a stat card widget
  Widget _buildStatCard(
    BuildContext context, {
    required String icon,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 9,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  /// Get the longest streak from activity provider
  String _getLongestStreak(ActivityProvider activityProvider) {
    // For now, return a placeholder. This would need to be implemented
    // in the activity provider to calculate actual streaks
    return '0';
  }

  /// Format degradation warning message
  String _formatDegradationWarning(dynamic warning) {
    // This is a placeholder implementation
    // The actual warning format would depend on the DegradationWarning model
    return warning.toString();
  }
}

/// Extension to get activity type icon
extension ActivityTypeIcon on ActivityType {
  String get icon {
    switch (this) {
      case ActivityType.workoutWeights:
        return '🏋️';
      case ActivityType.workoutCardio:
        return '🏃';
      case ActivityType.workoutYoga:
        return '🧘';
      case ActivityType.studySerious:
        return '📚';
      case ActivityType.studyCasual:
        return '📖';
      case ActivityType.meditation:
        return '🧘‍♂️';
      case ActivityType.socializing:
        return '👥';
      case ActivityType.quitBadHabit:
        return '🚫';
      case ActivityType.sleepTracking:
        return '😴';
      case ActivityType.dietHealthy:
        return '🥗';
    }
  }
}