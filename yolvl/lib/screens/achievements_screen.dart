import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/achievement.dart';
import '../providers/achievement_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/achievement_card.dart';
import '../widgets/achievement_progress_card.dart';

/// Screen displaying user achievements and progress
class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Load achievements when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final achievementProvider = context.read<AchievementProvider>();
      await achievementProvider.loadAchievements();
      
      // Also load progress if we have user context
      final userProvider = context.read<UserProvider>();
      if (userProvider.hasUser) {
        await achievementProvider.loadAchievementProgress(userProvider.currentUser!);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Unlocked', icon: Icon(Icons.star)),
            Tab(text: 'Progress', icon: Icon(Icons.trending_up)),
          ],
        ),
      ),
      body: Consumer<AchievementProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.errorMessage != null) {
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
                    'Error loading achievements',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.errorMessage!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadAchievements(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Achievement stats header
              _buildStatsHeader(context, provider),
              
              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildUnlockedTab(context, provider),
                    _buildProgressTab(context, provider),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsHeader(BuildContext context, AchievementProvider provider) {
    final stats = provider.achievementStats;
    if (stats == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            context,
            'Unlocked',
            '${stats.unlockedCount}/${stats.totalCount}',
            Icons.star,
          ),
          _buildStatItem(
            context,
            'Progress',
            '${stats.completionPercentage}%',
            Icons.trending_up,
          ),
          _buildStatItem(
            context,
            'Recent',
            '${provider.recentAchievements.length}',
            Icons.schedule,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildUnlockedTab(BuildContext context, AchievementProvider provider) {
    final achievements = provider.unlockedAchievements;

    if (achievements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star_border,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No achievements yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Start logging activities to unlock your first achievement!',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AchievementCard(
            achievement: achievement,
            onTap: () => _showAchievementDetails(context, achievement),
          ),
        );
      },
    );
  }

  Widget _buildProgressTab(BuildContext context, AchievementProvider provider) {
    final progressList = provider.achievementProgress;

    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (progressList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.trending_up,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No progress data',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Start logging activities to track your achievement progress!',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Separate locked and unlocked achievements
    final lockedProgress = progressList.where((p) => !p.isUnlocked).toList();
    final unlockedProgress = progressList.where((p) => p.isUnlocked).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (lockedProgress.isNotEmpty) ...[
          Text(
            'In Progress',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...lockedProgress.map((progress) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AchievementProgressCard(
              progress: progress,
              onTap: () => _showProgressDetails(context, progress),
            ),
          )),
        ],
        
        if (unlockedProgress.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Completed',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...unlockedProgress.map((progress) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AchievementProgressCard(
              progress: progress,
              onTap: () => _showProgressDetails(context, progress),
            ),
          )),
        ],
      ],
    );
  }

  void _showAchievementDetails(BuildContext context, Achievement achievement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              achievement.achievementTypeEnum.icon,
              color: achievement.achievementTypeEnum.color,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(achievement.achievementTypeEnum.displayName),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              achievement.achievementTypeEnum.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(width: 4),
                Text(
                  'Unlocked ${achievement.formattedUnlockTime}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            if (achievement.value != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    size: 16,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Value: ${achievement.value}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.star,
                  size: 16,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(width: 4),
                Text(
                  'Rarity: ${achievement.achievementTypeEnum.rarity}/5',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showProgressDetails(BuildContext context, AchievementProgress progress) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              progress.type.icon,
              color: progress.isUnlocked 
                  ? progress.type.color 
                  : Theme.of(context).colorScheme.outline,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(progress.type.displayName),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              progress.type.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress.progress,
              backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                progress.isUnlocked 
                    ? progress.type.color 
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${progress.currentValue} / ${progress.targetValue} (${progress.progressPercentage}%)',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (progress.isUnlocked) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Completed!',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}