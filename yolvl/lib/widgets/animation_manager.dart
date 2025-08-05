import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/enums.dart';
import 'stat_animation_controller.dart';
import 'level_up_animation.dart';
import 'floating_stat_gain_animation.dart';

/// Comprehensive animation manager for the YoLvL app
/// Coordinates all types of animations: stat gains, level ups, achievements, etc.
class YoLvLAnimationManager extends ChangeNotifier {
  late StatAnimationController _statAnimationController;
  final GlobalKey _overlayKey = GlobalKey();
  OverlayEntry? _currentOverlay;
  
  // Animation settings
  bool _hapticFeedbackEnabled = true;
  bool _particleEffectsEnabled = true;
  bool _screenFlashEnabled = true;
  bool _soundEffectsEnabled = true;

  YoLvLAnimationManager() {
    _statAnimationController = StatAnimationController();
  }

  /// Getters for animation settings
  bool get hapticFeedbackEnabled => _hapticFeedbackEnabled;
  bool get particleEffectsEnabled => _particleEffectsEnabled;
  bool get screenFlashEnabled => _screenFlashEnabled;
  bool get soundEffectsEnabled => _soundEffectsEnabled;

  /// Update animation settings
  void updateSettings({
    bool? hapticFeedback,
    bool? particleEffects,
    bool? screenFlash,
    bool? soundEffects,
  }) {
    if (hapticFeedback != null) _hapticFeedbackEnabled = hapticFeedback;
    if (particleEffects != null) _particleEffectsEnabled = particleEffects;
    if (screenFlash != null) _screenFlashEnabled = screenFlash;
    if (soundEffects != null) _soundEffectsEnabled = soundEffects;
    notifyListeners();
  }

  /// Show stat gain animations
  void showStatGains({
    required Map<StatType, double> statGains,
    double expGained = 0.0,
    VoidCallback? onComplete,
    AnimationPriority priority = AnimationPriority.normal,
  }) {
    if (statGains.isEmpty && expGained <= 0) return;

    _statAnimationController.queueStatGainAnimation(
      statGains: statGains,
      expGained: expGained,
      onComplete: onComplete,
      enableHapticFeedback: _hapticFeedbackEnabled,
      enableParticleEffects: _particleEffectsEnabled,
      enableScreenFlash: _screenFlashEnabled,
      priority: priority,
    );
  }

  /// Show batch stat gains (for multiple activities completed)
  void showBatchStatGains({
    required List<Map<StatType, double>> batchStatGains,
    required List<double> batchExpGained,
    VoidCallback? onAllComplete,
    Duration staggerDelay = const Duration(milliseconds: 150),
  }) {
    _statAnimationController.queueBatchStatAnimations(
      batchStatGains: batchStatGains,
      batchExpGained: batchExpGained,
      onAllComplete: onAllComplete,
      enableHapticFeedback: _hapticFeedbackEnabled,
      enableParticleEffects: _particleEffectsEnabled,
      enableScreenFlash: false, // Disabled for batch to prevent flicker
      staggerDelay: staggerDelay,
    );
  }

  /// Show epic level-up animation
  void showLevelUpAnimation({
    required BuildContext context,
    required int newLevel,
    required Map<StatType, double> statIncreases,
    VoidCallback? onComplete,
  }) {
    _showFullScreenAnimation(
      context: context,
      animation: LevelUpAnimation(
        newLevel: newLevel,
        statIncreases: statIncreases,
        enableHapticFeedback: _hapticFeedbackEnabled,
        enableParticleEffects: _particleEffectsEnabled,
        onAnimationComplete: () {
          _clearCurrentOverlay();
          
          // Show stat increases after level up animation
          if (statIncreases.isNotEmpty) {
            Future.delayed(const Duration(milliseconds: 500), () {
              showStatGains(
                statGains: statIncreases,
                priority: AnimationPriority.high,
                onComplete: onComplete,
              );
            });
          } else {
            onComplete?.call();
          }
        },
      ),
    );
  }

  /// Show quest completion animation
  void showQuestCompletion({
    required BuildContext context,
    required String questName,
    required Map<StatType, double> rewards,
    required double expReward,
    VoidCallback? onComplete,
  }) {
    _showFullScreenAnimation(
      context: context,
      animation: QuestCompletionAnimation(
        questName: questName,
        rewards: rewards,
        expReward: expReward,
        onAnimationComplete: () {
          _clearCurrentOverlay();
          
          // Show rewards after quest completion
          Future.delayed(const Duration(milliseconds: 300), () {
            showStatGains(
              statGains: rewards,
              expGained: expReward,
              onComplete: onComplete,
            );
          });
        },
      ),
    );
  }

  /// Show achievement unlock animation
  void showAchievementUnlock({
    required BuildContext context,
    required String achievementName,
    required String description,
    required IconData icon,
    VoidCallback? onComplete,
  }) {
    _showFullScreenAnimation(
      context: context,
      animation: _AchievementUnlockAnimation(
        achievementName: achievementName,
        description: description,
        icon: icon,
        enableHapticFeedback: _hapticFeedbackEnabled,
        onAnimationComplete: () {
          _clearCurrentOverlay();
          onComplete?.call();
        },
      ),
    );
  }

  /// Show streak celebration
  void showStreakCelebration({
    required BuildContext context,
    required int streakDays,
    VoidCallback? onComplete,
  }) {
    if (_hapticFeedbackEnabled) {
      HapticFeedback.mediumImpact();
    }

    showStatGains(
      statGains: {
        // Small bonus for streaks
        StatType.focus: 0.1 * streakDays.clamp(1, 10),
      },
      onComplete: onComplete,
      priority: AnimationPriority.high,
    );
  }

  /// Show milestone celebration (e.g., 100th activity)
  void showMilestoneCelebration({
    required BuildContext context,
    required String milestone,
    required Map<StatType, double> bonusRewards,
    VoidCallback? onComplete,
  }) {
    _showFullScreenAnimation(
      context: context,
      animation: _MilestoneCelebrationAnimation(
        milestone: milestone,
        bonusRewards: bonusRewards,
        enableHapticFeedback: _hapticFeedbackEnabled,
        enableParticleEffects: _particleEffectsEnabled,
        onAnimationComplete: () {
          _clearCurrentOverlay();
          
          // Show bonus rewards
          if (bonusRewards.isNotEmpty) {
            Future.delayed(const Duration(milliseconds: 400), () {
              showStatGains(
                statGains: bonusRewards,
                priority: AnimationPriority.high,
                onComplete: onComplete,
              );
            });
          } else {
            onComplete?.call();
          }
        },
      ),
    );
  }

  /// Clear all animations
  void clearAllAnimations() {
    _statAnimationController.clearAll();
    _clearCurrentOverlay();
  }

  /// Show full-screen overlay animation
  void _showFullScreenAnimation({
    required BuildContext context,
    required Widget animation,
  }) {
    _clearCurrentOverlay(); // Clear any existing overlay

    _currentOverlay = OverlayEntry(
      builder: (context) => Material(
        color: Colors.black54,
        child: animation,
      ),
    );

    Overlay.of(context).insert(_currentOverlay!);
  }

  /// Clear current full-screen overlay
  void _clearCurrentOverlay() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }

  /// Get the stat animation controller for direct access
  StatAnimationController get statAnimationController => _statAnimationController;

  @override
  void dispose() {
    _statAnimationController.dispose();
    _clearCurrentOverlay();
    super.dispose();
  }
}

/// Achievement unlock animation
class _AchievementUnlockAnimation extends StatefulWidget {
  final String achievementName;
  final String description;
  final IconData icon;
  final bool enableHapticFeedback;
  final VoidCallback? onAnimationComplete;

  const _AchievementUnlockAnimation({
    required this.achievementName,
    required this.description,
    required this.icon,
    required this.enableHapticFeedback,
    this.onAnimationComplete,
  });

  @override
  State<_AchievementUnlockAnimation> createState() => 
      _AchievementUnlockAnimationState();
}

class _AchievementUnlockAnimationState extends State<_AchievementUnlockAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _startAnimation();
  }

  void _setupAnimation() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.7, curve: Curves.easeInOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  void _startAnimation() async {
    if (widget.enableHapticFeedback) {
      HapticFeedback.mediumImpact();
    }

    await _controller.forward();
    widget.onAnimationComplete?.call();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                margin: const EdgeInsets.all(32),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.amber.withValues(alpha: 0.3),
                      Colors.orange.withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.amber.withValues(
                      alpha: _glowAnimation.value * 0.8,
                    ),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(
                        alpha: _glowAnimation.value * 0.5,
                      ),
                      blurRadius: 20 * _glowAnimation.value,
                      spreadRadius: 5 * _glowAnimation.value,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withValues(
                              alpha: _glowAnimation.value * 0.6,
                            ),
                            blurRadius: 15 * _glowAnimation.value,
                            spreadRadius: 3 * _glowAnimation.value,
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.icon,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'ACHIEVEMENT UNLOCKED!',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(
                            color: Colors.amber.withValues(
                              alpha: _glowAnimation.value * 0.8,
                            ),
                            blurRadius: 10 * _glowAnimation.value,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.achievementName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.description,
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Milestone celebration animation
class _MilestoneCelebrationAnimation extends StatefulWidget {
  final String milestone;
  final Map<StatType, double> bonusRewards;
  final bool enableHapticFeedback;
  final bool enableParticleEffects;
  final VoidCallback? onAnimationComplete;

  const _MilestoneCelebrationAnimation({
    required this.milestone,
    required this.bonusRewards,
    required this.enableHapticFeedback,
    required this.enableParticleEffects,
    this.onAnimationComplete,
  });

  @override
  State<_MilestoneCelebrationAnimation> createState() => 
      _MilestoneCelebrationAnimationState();
}

class _MilestoneCelebrationAnimationState 
    extends State<_MilestoneCelebrationAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _startAnimation();
  }

  void _setupAnimation() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.bounceOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  void _startAnimation() async {
    if (widget.enableHapticFeedback) {
      HapticFeedback.heavyImpact();
    }

    await _controller.forward();
    widget.onAnimationComplete?.call();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                margin: const EdgeInsets.all(32),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Colors.purple,
                      Colors.deepPurple,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star,
                      size: 60,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'MILESTONE REACHED!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.milestone,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (widget.bonusRewards.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Bonus Rewards:',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: widget.bonusRewards.entries.map((entry) {
                          return Chip(
                            avatar: Icon(
                              entry.key.icon,
                              size: 16,
                              color: Colors.white,
                            ),
                            label: Text(
                              '+${entry.value.toStringAsFixed(1)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            backgroundColor: Colors.white24,
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Mixin for easy animation integration
mixin YoLvLAnimationMixin<T extends StatefulWidget> on State<T> {
  late YoLvLAnimationManager _animationManager;

  YoLvLAnimationManager get animationManager => _animationManager;

  @override
  void initState() {
    super.initState();
    _animationManager = YoLvLAnimationManager();
  }

  @override
  void dispose() {
    _animationManager.dispose();
    super.dispose();
  }

  /// Wrap your widget tree with animation support
  Widget withAnimations(Widget child) {
    return StatAnimationDisplay(
      controller: _animationManager.statAnimationController,
      child: child,
    );
  }
}