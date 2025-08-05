import 'dart:math';
import 'package:flutter/material.dart';
import '../models/daily_reward.dart';
import '../theme/solo_leveling_theme.dart';

/// Epic reward collection animation with particle effects
/// 
/// Displays spectacular animations when users claim daily login rewards,
/// featuring particle systems, glow effects, and Solo Leveling theming.
class RewardCollectionAnimation extends StatefulWidget {
  final DailyReward reward;
  final VoidCallback? onComplete;
  final bool autoStart;

  const RewardCollectionAnimation({
    super.key,
    required this.reward,
    this.onComplete,
    this.autoStart = true,
  });

  @override
  State<RewardCollectionAnimation> createState() => _RewardCollectionAnimationState();
}

class _RewardCollectionAnimationState extends State<RewardCollectionAnimation>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _particleController;
  late AnimationController _glowController;
  late AnimationController _textController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    
    if (widget.autoStart) {
      _startAnimation();
    }
  }

  void _initializeAnimations() {
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * pi,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeInOut),
    ));

    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _particleController,
      curve: Curves.easeOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOutSine,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOutBack),
    ));

    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (widget.onComplete != null) {
            widget.onComplete!();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _particleController.dispose();
    _glowController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _startAnimation() {
    _particleController.forward();
    _glowController.repeat(reverse: true);
    
    Future.delayed(const Duration(milliseconds: 300), () {
      _mainController.forward();
    });
    
    Future.delayed(const Duration(milliseconds: 800), () {
      _textController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background particle effects
          _buildParticleBackground(),
          
          // Glow effect
          _buildGlowEffect(),
          
          // Main reward display
          _buildRewardDisplay(),
          
          // Text animations
          _buildTextAnimations(),
        ],
      ),
    );
  }

  Widget _buildParticleBackground() {
    return AnimatedBuilder(
      animation: _particleAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: RewardParticlePainter(
            animationValue: _particleAnimation.value,
            isMilestone: widget.reward.isMilestone,
          ),
          child: Container(),
        );
      },
    );
  }

  Widget _buildGlowEffect() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          width: 200 + (_glowAnimation.value * 50),
          height: 200 + (_glowAnimation.value * 50),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _getRewardColor().withValues(alpha: 0.3 * _glowAnimation.value),
                _getRewardColor().withValues(alpha: 0.1 * _glowAnimation.value),
                Colors.transparent,
              ],
              stops: const [0.0, 0.7, 1.0],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRewardDisplay() {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value * 0.1, // Subtle rotation
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: _buildRewardIcon(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRewardIcon() {
    IconData icon;
    Color color = _getRewardColor();
    
    if (widget.reward.isMilestone) {
      icon = Icons.star;
    } else if (widget.reward.isWeekendBonus) {
      icon = Icons.weekend;
    } else {
      icon = Icons.card_giftcard;
    }

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.2),
        border: Border.all(
          color: color,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Icon(
        icon,
        size: 60,
        color: color,
      ),
    );
  }

  Widget _buildTextAnimations() {
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: Opacity(
            opacity: _textController.value,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 200), // Space for reward icon
                
                // Reward claimed text
                Text(
                  'REWARD CLAIMED!',
                  style: SoloLevelingTypography.hunterTitle.copyWith(
                    fontSize: 28,
                    color: _getRewardColor(),
                    shadows: [
                      Shadow(
                        color: _getRewardColor().withValues(alpha: 0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Reward description
                Text(
                  widget.reward.displayDescription,
                  style: SoloLevelingTypography.systemNotification.copyWith(
                    fontSize: 16,
                    color: SoloLevelingColors.ghostWhite,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 24),
                
                // Reward items list
                ...widget.reward.rewards.take(3).map((rewardItem) => 
                  _buildAnimatedRewardItem(rewardItem)),
                
                if (widget.reward.rewards.length > 3) ...[
                  const SizedBox(height: 8),
                  Text(
                    '+${widget.reward.rewards.length - 3} more rewards',
                    style: SoloLevelingTypography.systemNotification.copyWith(
                      fontSize: 14,
                      color: SoloLevelingColors.silverMist,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedRewardItem(RewardItem rewardItem) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + (Random().nextInt(300))),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 32),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: SoloLevelingColors.shadowDepth.withValues(alpha: 0.8),
                border: Border.all(
                  color: _getRewardItemColor(rewardItem).withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getRewardItemIcon(rewardItem),
                    size: 16,
                    color: _getRewardItemColor(rewardItem),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    rewardItem.displayText,
                    style: SoloLevelingTypography.systemNotification.copyWith(
                      fontSize: 14,
                      color: rewardItem.isRare 
                          ? SoloLevelingColors.mysticPurple 
                          : SoloLevelingColors.ghostWhite,
                    ),
                  ),
                  if (rewardItem.isRare) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: SoloLevelingColors.mysticPurple,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getRewardColor() {
    if (widget.reward.isMilestone) {
      return SoloLevelingColors.goldRank;
    } else if (widget.reward.isWeekendBonus) {
      return SoloLevelingColors.mysticPurple;
    } else {
      return SoloLevelingColors.electricBlue;
    }
  }

  IconData _getRewardItemIcon(RewardItem rewardItem) {
    switch (rewardItem.type) {
      case RewardType.exp:
        return Icons.flash_on;
      case RewardType.statBoost:
        return Icons.trending_up;
      case RewardType.specialItem:
        return Icons.star;
      case RewardType.streakMultiplier:
        return Icons.close;
      case RewardType.hunterRankBonus:
        return Icons.shield;
      default:
        return Icons.card_giftcard;
    }
  }

  Color _getRewardItemColor(RewardItem rewardItem) {
    switch (rewardItem.type) {
      case RewardType.exp:
        return SoloLevelingColors.electricBlue;
      case RewardType.statBoost:
        return SoloLevelingColors.hunterGreen;
      case RewardType.specialItem:
        return SoloLevelingColors.mysticPurple;
      case RewardType.streakMultiplier:
        return SoloLevelingColors.goldRank;
      case RewardType.hunterRankBonus:
        return SoloLevelingColors.crimsonRed;
      default:
        return SoloLevelingColors.silverMist;
    }
  }
}

/// Custom painter for reward particle effects
class RewardParticlePainter extends CustomPainter {
  final double animationValue;
  final bool isMilestone;
  
  RewardParticlePainter({
    required this.animationValue,
    required this.isMilestone,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42); // Fixed seed for consistent animation
    final paint = Paint();
    
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    // Number of particles based on reward type
    final particleCount = isMilestone ? 50 : 30;
    
    for (int i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * 2 * pi + (animationValue * pi);
      final distance = 50 + (animationValue * 150) + (random.nextDouble() * 50);
      
      final x = centerX + cos(angle) * distance;
      final y = centerY + sin(angle) * distance;
      
      // Particle size and opacity based on animation progress
      final particleSize = (1.0 + random.nextDouble() * 2) * (1.0 - animationValue);
      final opacity = (1.0 - animationValue) * (0.5 + random.nextDouble() * 0.5);
      
      // Color based on reward type
      Color particleColor;
      if (isMilestone) {
        final colors = [
          SoloLevelingColors.goldRank,
          SoloLevelingColors.mysticPurple,
          SoloLevelingColors.electricBlue,
        ];
        particleColor = colors[i % colors.length];
      } else {
        particleColor = SoloLevelingColors.electricBlue;
      }
      
      paint.color = particleColor.withValues(alpha: opacity);
      
      // Draw particle with glow effect
      canvas.drawCircle(
        Offset(x, y),
        particleSize * 3,
        paint..color = particleColor.withValues(alpha: opacity * 0.2),
      );
      
      canvas.drawCircle(
        Offset(x, y),
        particleSize,
        paint..color = particleColor.withValues(alpha: opacity),
      );
    }
    
    // Add sparkle effects for milestone rewards
    if (isMilestone) {
      _drawSparkles(canvas, size, random);
    }
  }

  void _drawSparkles(Canvas canvas, Size size, Random random) {
    final paint = Paint()
      ..color = SoloLevelingColors.goldRank.withValues(
        alpha: (1.0 - animationValue) * 0.8,
      )
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    for (int i = 0; i < 20; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final distance = random.nextDouble() * 200 + 50;
      
      final x = centerX + cos(angle) * distance;
      final y = centerY + sin(angle) * distance;
      
      final sparkleSize = random.nextDouble() * 10 + 5;
      
      // Draw cross-shaped sparkle
      canvas.drawLine(
        Offset(x - sparkleSize, y),
        Offset(x + sparkleSize, y),
        paint,
      );
      canvas.drawLine(
        Offset(x, y - sparkleSize),
        Offset(x, y + sparkleSize),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(RewardParticlePainter oldDelegate) {
    return animationValue != oldDelegate.animationValue;
  }
}

/// Overlay widget for displaying reward collection animation
class RewardCollectionOverlay extends StatefulWidget {
  final DailyReward reward;
  final VoidCallback? onComplete;

  const RewardCollectionOverlay({
    super.key,
    required this.reward,
    this.onComplete,
  });

  /// Show reward collection animation as overlay
  static void show(BuildContext context, DailyReward reward, {VoidCallback? onComplete}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (context) => RewardCollectionOverlay(
        reward: reward,
        onComplete: () {
          Navigator.of(context).pop();
          if (onComplete != null) {
            onComplete();
          }
        },
      ),
    );
  }

  @override
  State<RewardCollectionOverlay> createState() => _RewardCollectionOverlayState();
}

class _RewardCollectionOverlayState extends State<RewardCollectionOverlay> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: RewardCollectionAnimation(
          reward: widget.reward,
          onComplete: widget.onComplete,
        ),
      ),
    );
  }
}