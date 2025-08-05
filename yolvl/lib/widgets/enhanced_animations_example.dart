import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../theme/solo_leveling_theme.dart';
import '../theme/solo_leveling_icons.dart';
import 'animation_manager.dart';
import 'stat_animation_controller.dart';

/// Example widget demonstrating the enhanced stat animations
/// This shows how to integrate the new animation system throughout the app
class EnhancedAnimationsExample extends StatefulWidget {
  const EnhancedAnimationsExample({super.key});

  @override
  State<EnhancedAnimationsExample> createState() => _EnhancedAnimationsExampleState();
}

class _EnhancedAnimationsExampleState extends State<EnhancedAnimationsExample>
    with YoLvLAnimationMixin {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced Animations Demo'),
        backgroundColor: SoloLevelingColors.voidBlack,
      ),
      backgroundColor: SoloLevelingColors.midnightBase,
      body: withAnimations(
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAnimationDemoSection(),
              const SizedBox(height: 20),
              _buildAnimationControls(),
              const SizedBox(height: 20),
              _buildAnimationSettings(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimationDemoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Animation Demo',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: SoloLevelingColors.electricBlue,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tap the buttons below to see different animation types:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: SoloLevelingColors.ghostWhite,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildDemoButton(
                  'Small Gains',
                  () => _showSmallGains(),
                  SoloLevelingColors.hunterGreen,
                ),
                _buildDemoButton(
                  'Medium Gains',
                  () => _showMediumGains(),
                  SoloLevelingColors.electricBlue,
                ),
                _buildDemoButton(
                  'Epic Gains',
                  () => _showEpicGains(),
                  SoloLevelingColors.electricPurple,
                ),
                _buildDemoButton(
                  'Batch Updates',
                  () => _showBatchUpdates(),
                  SoloLevelingColors.mysticTeal,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimationControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Special Animations',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: SoloLevelingColors.electricBlue,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildDemoButton(
                  'Level Up!',
                  () => _showLevelUp(),
                  SystemColors.levelUpGlow,
                ),
                _buildDemoButton(
                  'Quest Complete',
                  () => _showQuestComplete(),
                  SystemColors.systemSuccess,
                ),
                _buildDemoButton(
                  'Achievement',
                  () => _showAchievement(),
                  Colors.amber,
                ),
                _buildDemoButton(
                  'Milestone',
                  () => _showMilestone(),
                  Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => animationManager.clearAllAnimations(),
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear All Animations'),
              style: ElevatedButton.styleFrom(
                backgroundColor: SoloLevelingColors.crimsonRed,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimationSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Animation Settings',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: SoloLevelingColors.electricBlue,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Haptic Feedback'),
              subtitle: const Text('Vibration for significant gains'),
              value: animationManager.hapticFeedbackEnabled,
              onChanged: (value) {
                animationManager.updateSettings(hapticFeedback: value);
                setState(() {});
              },
            ),
            SwitchListTile(
              title: const Text('Particle Effects'),
              subtitle: const Text('Visual particle trails'),
              value: animationManager.particleEffectsEnabled,
              onChanged: (value) {
                animationManager.updateSettings(particleEffects: value);
                setState(() {});
              },
            ),
            SwitchListTile(
              title: const Text('Screen Flash'),
              subtitle: const Text('Screen flash for epic gains'),
              value: animationManager.screenFlashEnabled,
              onChanged: (value) {
                animationManager.updateSettings(screenFlash: value);
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoButton(String label, VoidCallback onPressed, Color color) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(label),
    );
  }

  void _showSmallGains() {
    animationManager.showStatGains(
      statGains: {
        StatType.strength: 0.2,
        StatType.endurance: 0.15,
      },
      expGained: 15,
    );
  }

  void _showMediumGains() {
    animationManager.showStatGains(
      statGains: {
        StatType.intelligence: 2.5,
        StatType.focus: 1.8,
        StatType.charisma: 1.2,
      },
      expGained: 45,
    );
  }

  void _showEpicGains() {
    animationManager.showStatGains(
      statGains: {
        StatType.strength: 8.5,
        StatType.agility: 6.2,
      },
      expGained: 120,
      priority: AnimationPriority.high,
    );
  }

  void _showBatchUpdates() {
    final batchGains = [
      {StatType.strength: 1.2, StatType.endurance: 0.8},
      {StatType.agility: 1.5, StatType.focus: 0.6},
      {StatType.intelligence: 2.1, StatType.charisma: 1.3},
    ];
    
    final batchExp = [25.0, 30.0, 35.0];

    animationManager.showBatchStatGains(
      batchStatGains: batchGains,
      batchExpGained: batchExp,
      staggerDelay: const Duration(milliseconds: 200),
    );
  }

  void _showLevelUp() {
    animationManager.showLevelUpAnimation(
      context: context,
      newLevel: 15,
      statIncreases: {
        StatType.strength: 2.0,
        StatType.agility: 1.8,
        StatType.endurance: 2.2,
        StatType.intelligence: 1.5,
        StatType.focus: 1.3,
        StatType.charisma: 1.7,
      },
    );
  }

  void _showQuestComplete() {
    animationManager.showQuestCompletion(
      context: context,
      questName: 'Complete 30-minute workout session',
      rewards: {
        StatType.strength: 1.5,
        StatType.endurance: 2.0,
      },
      expReward: 75,
    );
  }

  void _showAchievement() {
    animationManager.showAchievementUnlock(
      context: context,
      achievementName: 'Workout Warrior',
      description: 'Complete 25 workout activities',
      icon: SoloLevelingIcons.getAchievementIcon('workoutWarrior'),
    );
  }

  void _showMilestone() {
    animationManager.showMilestoneCelebration(
      context: context,
      milestone: '100 Activities Completed!',
      bonusRewards: {
        StatType.strength: 3.0,
        StatType.agility: 3.0,
        StatType.endurance: 3.0,
        StatType.intelligence: 3.0,
        StatType.focus: 3.0,
        StatType.charisma: 3.0,
      },
    );
  }
}

/// Example of how to integrate animations in an activity completion screen
class ActivityCompletionExample extends StatefulWidget {
  final Map<StatType, double> statGains;
  final double expGained;
  final String activityName;
  final bool isLevelUp;
  final int? newLevel;

  const ActivityCompletionExample({
    super.key,
    required this.statGains,
    required this.expGained,
    required this.activityName,
    this.isLevelUp = false,
    this.newLevel,
  });

  @override
  State<ActivityCompletionExample> createState() => _ActivityCompletionExampleState();
}

class _ActivityCompletionExampleState extends State<ActivityCompletionExample>
    with YoLvLAnimationMixin {

  @override
  void initState() {
    super.initState();
    // Show animations when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showCompletionAnimations();
    });
  }

  void _showCompletionAnimations() {
    if (widget.isLevelUp && widget.newLevel != null) {
      // Show level up first, then stat gains
      animationManager.showLevelUpAnimation(
        context: context,
        newLevel: widget.newLevel!,
        statIncreases: widget.statGains,
        onComplete: () {
          // Level up animation handles showing stat gains
        },
      );
    } else {
      // Just show regular stat gains
      animationManager.showStatGains(
        statGains: widget.statGains,
        expGained: widget.expGained,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Complete'),
        backgroundColor: SoloLevelingColors.voidBlack,
      ),
      backgroundColor: SoloLevelingColors.midnightBase,
      body: withAnimations(
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                SoloLevelingIcons.completeQuest,
                size: 80,
                color: SystemColors.systemSuccess,
              ),
              const SizedBox(height: 20),
              Text(
                'Activity Completed!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: SystemColors.systemSuccess,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.activityName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: SoloLevelingColors.ghostWhite,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              if (widget.isLevelUp) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: SystemColors.levelUpGlow.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: SystemColors.levelUpGlow.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '🎉 LEVEL UP TO ${widget.newLevel}! 🎉',
                    style: TextStyle(
                      color: SystemColors.levelUpGlow,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
              ],
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}