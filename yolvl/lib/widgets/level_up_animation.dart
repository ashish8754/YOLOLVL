import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/solo_leveling_theme.dart';
import '../theme/solo_leveling_icons.dart';
import '../theme/glassmorphism_effects.dart';
import '../models/enums.dart';
import 'stat_animation_controller.dart';
import 'dart:math' as math;

/// Epic level-up celebration animation with Solo Leveling theming
class LevelUpAnimation extends StatefulWidget {
  final int newLevel;
  final Map<StatType, double> statIncreases;
  final VoidCallback? onAnimationComplete;
  final bool enableHapticFeedback;
  final bool enableParticleEffects;

  const LevelUpAnimation({
    super.key,
    required this.newLevel,
    required this.statIncreases,
    this.onAnimationComplete,
    this.enableHapticFeedback = true,
    this.enableParticleEffects = true,
  });

  @override
  State<LevelUpAnimation> createState() => _LevelUpAnimationState();
}

class _LevelUpAnimationState extends State<LevelUpAnimation>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _particleController;
  late AnimationController _pulseController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _pulseAnimation;

  final List<_LevelUpParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _generateParticles();
    _startAnimation();
  }

  void _setupAnimations() {
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Main level display animations
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.4, curve: Curves.elasticOut),
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.1, 0.6, curve: Curves.easeInOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeIn),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );

    // Particle effects
    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _particleController,
        curve: Curves.easeOut,
      ),
    );

    // Pulsing background glow
    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _generateParticles() {
    if (!widget.enableParticleEffects) return;

    for (int i = 0; i < 25; i++) {
      _particles.add(_LevelUpParticle(
        startX: 0.5 + (_random.nextDouble() - 0.5) * 0.4,
        startY: 0.5 + (_random.nextDouble() - 0.5) * 0.4,
        endX: _random.nextDouble(),
        endY: _random.nextDouble(),
        color: i % 3 == 0 
            ? SoloLevelingColors.electricBlue
            : i % 2 == 0 
                ? SystemColors.levelUpGlow
                : SoloLevelingColors.hunterGreen,
        size: _random.nextDouble() * 4 + 2,
        rotationSpeed: (_random.nextDouble() - 0.5) * 4,
        delay: _random.nextInt(1000),
      ));
    }
  }

  void _startAnimation() async {
    // Haptic feedback for epic moment
    if (widget.enableHapticFeedback) {
      HapticFeedback.heavyImpact();
      // Additional feedback after delay
      Future.delayed(const Duration(milliseconds: 600), () {
        HapticFeedback.mediumImpact();
      });
    }

    // Start pulsing background
    _pulseController.repeat(reverse: true);

    // Start particle effects
    if (widget.enableParticleEffects) {
      _particleController.forward();
    }

    // Start main animation
    await _mainController.forward();

    // Show stat increases with staggered timing
    if (widget.statIncreases.isNotEmpty) {
      await _showStatIncreases();
    }

    // Stop pulsing
    _pulseController.stop();

    // Complete callback
    widget.onAnimationComplete?.call();
  }

  Future<void> _showStatIncreases() async {
    // Small delay before stat animations
    await Future.delayed(const Duration(milliseconds: 200));
    
    int index = 0;
    for (final entry in widget.statIncreases.entries) {
      Future.delayed(Duration(milliseconds: index * 150), () {
        // This would integrate with the StatAnimationController
        // For now, we'll just show a simple indicator
      });
      index++;
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _mainController,
        _particleController,
        _pulseController,
      ]),
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.5,
              colors: [
                SystemColors.levelUpGlow.withValues(
                  alpha: _pulseAnimation.value * 0.3,
                ),
                SoloLevelingColors.electricBlue.withValues(
                  alpha: _pulseAnimation.value * 0.2,
                ),
                Colors.transparent,
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Particle effects background
              if (widget.enableParticleEffects)
                ..._buildParticleEffects(),
              
              // Main level up display
              Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: _buildLevelUpDisplay(),
                    ),
                  ),
                ),
              ),
              
              // Stat increase indicators
              if (widget.statIncreases.isNotEmpty)
                _buildStatIncreaseIndicators(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLevelUpDisplay() {
    return GlassmorphismEffects.hunterPanel(
      glowEffect: true,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // "LEVEL UP!" text
          FadeTransition(
            opacity: _textFadeAnimation,
            child: Text(
              'LEVEL UP!',
              style: SoloLevelingTypography.hunterTitle.copyWith(
                fontSize: 32,
                color: SystemColors.levelUpGlow,
                shadows: [
                  Shadow(
                    color: SystemColors.levelUpGlow.withValues(
                      alpha: _glowAnimation.value * 0.8,
                    ),
                    blurRadius: 20 * _glowAnimation.value,
                    offset: Offset.zero,
                  ),
                  const Shadow(
                    color: SoloLevelingColors.voidBlack,
                    blurRadius: 4,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Level number with glow effect
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  SoloLevelingColors.electricBlue,
                  SoloLevelingColors.hunterGreen,
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: SoloLevelingColors.electricBlue.withValues(
                    alpha: _glowAnimation.value * 0.6,
                  ),
                  blurRadius: 25 * _glowAnimation.value,
                  spreadRadius: 5 * _glowAnimation.value,
                  offset: Offset.zero,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  SoloLevelingIcons.levelUp,
                  color: SoloLevelingColors.pureLight,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'LV. ${widget.newLevel}',
                  style: SoloLevelingTypography.levelDisplay.copyWith(
                    fontSize: 36,
                    color: SoloLevelingColors.pureLight,
                    shadows: [
                      const Shadow(
                        color: SoloLevelingColors.voidBlack,
                        blurRadius: 3,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Enhancement message
          FadeTransition(
            opacity: _textFadeAnimation,
            child: Text(
              'Your abilities have grown stronger!',
              style: SoloLevelingTypography.systemNotification.copyWith(
                color: SoloLevelingColors.silverMist,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatIncreaseIndicators() {
    return Positioned.fill(
      child: FadeTransition(
        opacity: _textFadeAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 200), // Space for main display
            
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 8,
              children: widget.statIncreases.entries.map((entry) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: SoloLevelingIcons.getStatIconColor(entry.key, context)
                        .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: SoloLevelingIcons.getStatIconColor(entry.key, context)
                          .withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        entry.key.icon,
                        size: 16,
                        color: SoloLevelingIcons.getStatIconColor(entry.key, context),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '+${entry.value.toStringAsFixed(1)}',
                        style: TextStyle(
                          color: SoloLevelingColors.ghostWhite,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildParticleEffects() {
    return _particles.asMap().entries.map((entry) {
      final index = entry.key;
      final particle = entry.value;
      final progress = _particleAnimation.value;
      
      return Positioned(
        left: MediaQuery.of(context).size.width *
            (particle.startX + (particle.endX - particle.startX) * progress),
        top: MediaQuery.of(context).size.height *
            (particle.startY + (particle.endY - particle.startY) * progress),
        child: Transform.rotate(
          angle: progress * particle.rotationSpeed * 2 * math.pi,
          child: Container(
            width: particle.size,
            height: particle.size,
            decoration: BoxDecoration(
              color: particle.color.withValues(alpha: (1.0 - progress) * 0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: particle.color.withValues(alpha: (1.0 - progress) * 0.5),
                  blurRadius: 6,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}

/// Particle data for level up effects
class _LevelUpParticle {
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final Color color;
  final double size;
  final double rotationSpeed;
  final int delay;

  _LevelUpParticle({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.color,
    required this.size,
    required this.rotationSpeed,
    required this.delay,
  });
}

/// Quest completion celebration animation
class QuestCompletionAnimation extends StatefulWidget {
  final String questName;
  final Map<StatType, double> rewards;
  final double expReward;
  final VoidCallback? onAnimationComplete;

  const QuestCompletionAnimation({
    super.key,
    required this.questName,
    required this.rewards,
    required this.expReward,
    this.onAnimationComplete,
  });

  @override
  State<QuestCompletionAnimation> createState() => _QuestCompletionAnimationState();
}

class _QuestCompletionAnimationState extends State<QuestCompletionAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
        curve: const Interval(0.0, 0.4, curve: Curves.bounceOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
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
    HapticFeedback.lightImpact();
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
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Center(
                child: GlassmorphismEffects.achievementNotification(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        SoloLevelingIcons.completeQuest,
                        size: 48,
                        color: SystemColors.systemSuccess,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'QUEST COMPLETE!',
                        style: SoloLevelingTypography.systemNotification.copyWith(
                          fontSize: 20,
                          color: SystemColors.systemSuccess,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.questName,
                        style: SoloLevelingTypography.systemNotification.copyWith(
                          color: SoloLevelingColors.ghostWhite,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (widget.expReward > 0) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: SoloLevelingColors.electricBlue.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: SoloLevelingColors.electricBlue.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                SoloLevelingIcons.experience,
                                size: 16,
                                color: SoloLevelingColors.electricBlue,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '+${widget.expReward.toStringAsFixed(0)} EXP',
                                style: TextStyle(
                                  color: SoloLevelingColors.electricBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}