import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/hunter_rank_service.dart';
import '../theme/solo_leveling_theme.dart';

/// Hunter Rank Badge component with Solo Leveling themed styling
/// Supports different sizes, glow effects, and special animations for higher ranks
class HunterRankBadge extends StatefulWidget {
  final String rank;
  final HunterRankBadgeSize size;
  final int? level;
  final double glowIntensity;
  final bool showLevelText;
  final bool enableAnimations;
  final VoidCallback? onTap;

  const HunterRankBadge({
    super.key,
    required this.rank,
    this.size = HunterRankBadgeSize.medium,
    this.level,
    this.glowIntensity = 0.0,
    this.showLevelText = false,
    this.enableAnimations = true,
    this.onTap,
  });

  @override
  State<HunterRankBadge> createState() => _HunterRankBadgeState();
}

class _HunterRankBadgeState extends State<HunterRankBadge>
    with TickerProviderStateMixin {
  late AnimationController _rainbowController;
  late AnimationController _pulseController;
  late AnimationController _unlockController;
  late Animation<double> _rainbowAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _unlockScaleAnimation;
  late Animation<double> _unlockRotationAnimation;

  final HunterRankService _rankService = HunterRankService.instance;
  late HunterRankData _rankData;

  @override
  void initState() {
    super.initState();
    _rankData = _rankService.getRankByString(widget.rank) ?? 
                _rankService.getRankByString('E')!;

    _initializeAnimations();
    _startContinuousAnimations();
  }

  void _initializeAnimations() {
    // Rainbow effect for SSS rank
    _rainbowController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Pulse effect for high ranks
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Unlock animation for new rank achievements
    _unlockController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _rainbowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rainbowController,
      curve: Curves.linear,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _unlockScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _unlockController,
      curve: Curves.elasticOut,
    ));

    _unlockRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _unlockController,
      curve: Curves.easeInOut,
    ));
  }

  void _startContinuousAnimations() {
    if (!widget.enableAnimations) return;

    // Start rainbow animation for SSS rank
    if (_rankData.hasRainbowEffect) {
      _rainbowController.repeat();
    }

    // Start pulse animation for high ranks
    if (_rankData.hasPulseEffect) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(HunterRankBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.rank != widget.rank) {
      _rankData = _rankService.getRankByString(widget.rank) ?? 
                  _rankService.getRankByString('E')!;
      _restartAnimations();
    }
  }

  void _restartAnimations() {
    _rainbowController.stop();
    _pulseController.stop();
    
    if (widget.enableAnimations) {
      _startContinuousAnimations();
    }
  }

  @override
  void dispose() {
    _rainbowController.dispose();
    _pulseController.dispose();
    _unlockController.dispose();
    super.dispose();
  }

  /// Trigger unlock animation for new rank achievements
  void triggerUnlockAnimation() {
    if (widget.enableAnimations) {
      _unlockController.reset();
      _unlockController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final badgeSize = _getBadgeSize();
    final fontSize = _getFontSize();

    return Semantics(
      label: '${_rankData.name}${widget.level != null ? ', Level ${widget.level}' : ''}',
      button: widget.onTap != null,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: widget.enableAnimations && _rankData.hasPulseEffect 
              ? _pulseAnimation 
              : const AlwaysStoppedAnimation(1.0),
          builder: (context, child) {
            return Transform.scale(
              scale: widget.enableAnimations && _rankData.hasPulseEffect 
                  ? _pulseAnimation.value 
                  : 1.0,
              child: AnimatedBuilder(
                animation: _unlockScaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _unlockScaleAnimation.value,
                    child: Transform.rotate(
                      angle: _unlockRotationAnimation.value,
                      child: Container(
                        width: badgeSize,
                        height: badgeSize,
                        decoration: _buildBadgeDecoration(),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Glow effect layer
                            if (_rankData.hasGlowEffect || widget.glowIntensity > 0)
                              _buildGlowEffect(badgeSize),
                            
                            // Rainbow effect for SSS rank
                            if (_rankData.hasRainbowEffect && widget.enableAnimations)
                              _buildRainbowEffect(badgeSize),
                            
                            // Main rank text
                            _buildRankText(fontSize),
                            
                            // Level text overlay (if enabled)
                            if (widget.showLevelText && widget.level != null)
                              _buildLevelText(fontSize),
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
      ),
    );
  }

  BoxDecoration _buildBadgeDecoration() {
    final baseColor = _rankData.color;
    final lightColor = _rankData.lightColor;

    return BoxDecoration(
      gradient: RadialGradient(
        center: Alignment.topLeft,
        radius: 1.5,
        colors: [
          lightColor.withValues(alpha: 0.8),
          baseColor,
          baseColor.withValues(alpha: 0.9),
        ],
        stops: const [0.0, 0.6, 1.0],
      ),
      borderRadius: _getBorderRadius(),
      border: Border.all(
        color: lightColor.withValues(alpha: 0.6),
        width: _getBorderWidth(),
      ),
      boxShadow: [
        // Base shadow
        BoxShadow(
          color: SoloLevelingColors.voidBlack.withValues(alpha: 0.5),
          blurRadius: 8,
          spreadRadius: 1,
          offset: const Offset(0, 4),
        ),
        // Rank-specific glow shadow
        if (_rankData.hasGlowEffect || widget.glowIntensity > 0)
          BoxShadow(
            color: baseColor.withValues(alpha: 0.4 * (widget.glowIntensity + 0.5)),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 0),
          ),
      ],
    );
  }

  Widget _buildGlowEffect(double size) {
    return AnimatedBuilder(
      animation: widget.glowIntensity > 0 
          ? const AlwaysStoppedAnimation(1.0) 
          : _pulseAnimation,
      builder: (context, child) {
        final intensity = widget.glowIntensity > 0 
            ? widget.glowIntensity 
            : _pulseAnimation.value;
        
        return Container(
          width: size * 1.2,
          height: size * 1.2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _rankData.lightColor.withValues(alpha: 0.3 * intensity),
                _rankData.color.withValues(alpha: 0.1 * intensity),
                Colors.transparent,
              ],
              stops: const [0.0, 0.7, 1.0],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRainbowEffect(double size) {
    return AnimatedBuilder(
      animation: _rainbowAnimation,
      builder: (context, child) {
        final colors = HunterRankColors.sssRank;
        final currentColorIndex = (_rainbowAnimation.value * colors.length).floor();
        final nextColorIndex = (currentColorIndex + 1) % colors.length;
        final lerpFactor = (_rainbowAnimation.value * colors.length) - currentColorIndex;
        
        final currentColor = Color.lerp(
          colors[currentColorIndex],
          colors[nextColorIndex],
          lerpFactor,
        )!;

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: _getBorderRadius(),
            border: Border.all(
              color: currentColor.withValues(alpha: 0.8),
              width: _getBorderWidth() * 2,
            ),
            boxShadow: [
              BoxShadow(
                color: currentColor.withValues(alpha: 0.5),
                blurRadius: 20,
                spreadRadius: 3,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRankText(double fontSize) {
    return Text(
      widget.rank.toUpperCase(),
      style: SoloLevelingTypography.rankDisplay.copyWith(
        fontSize: fontSize,
        color: Colors.white,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
        shadows: [
          Shadow(
            color: SoloLevelingColors.voidBlack.withValues(alpha: 0.8),
            blurRadius: 4,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildLevelText(double fontSize) {
    return Positioned(
      bottom: 2,
      right: 2,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: SoloLevelingColors.voidBlack.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _rankData.lightColor.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
        child: Text(
          '${widget.level}',
          style: SoloLevelingTypography.systemNotification.copyWith(
            fontSize: fontSize * 0.4,
            color: _rankData.lightColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  double _getBadgeSize() {
    switch (widget.size) {
      case HunterRankBadgeSize.small:
        return 40.0;
      case HunterRankBadgeSize.medium:
        return 60.0;
      case HunterRankBadgeSize.large:
        return 80.0;
      case HunterRankBadgeSize.extraLarge:
        return 100.0;
    }
  }

  double _getFontSize() {
    switch (widget.size) {
      case HunterRankBadgeSize.small:
        return 16.0;
      case HunterRankBadgeSize.medium:
        return 20.0;
      case HunterRankBadgeSize.large:
        return 24.0;
      case HunterRankBadgeSize.extraLarge:
        return 28.0;
    }
  }

  BorderRadius _getBorderRadius() {
    final radius = _getBadgeSize() * 0.2;
    return BorderRadius.circular(radius);
  }

  double _getBorderWidth() {
    switch (widget.size) {
      case HunterRankBadgeSize.small:
        return 1.0;
      case HunterRankBadgeSize.medium:
        return 1.5;
      case HunterRankBadgeSize.large:
        return 2.0;
      case HunterRankBadgeSize.extraLarge:
        return 2.5;
    }
  }
}

/// Specialized badge for rank-up celebrations
class HunterRankCelebrationBadge extends StatefulWidget {
  final String newRank;
  final String oldRank;
  final CelebrationType celebrationType;
  final VoidCallback? onAnimationComplete;

  const HunterRankCelebrationBadge({
    super.key,
    required this.newRank,
    required this.oldRank,
    required this.celebrationType,
    this.onAnimationComplete,
  });

  @override
  State<HunterRankCelebrationBadge> createState() => _HunterRankCelebrationBadgeState();
}

class _HunterRankCelebrationBadgeState extends State<HunterRankCelebrationBadge>
    with TickerProviderStateMixin {
  late AnimationController _celebrationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _celebrationController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 4 * math.pi,
    ).animate(CurvedAnimation(
      parent: _celebrationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeInOut),
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _celebrationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeIn),
    ));

    // Start celebration animation
    _celebrationController
      ..forward()
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onAnimationComplete?.call();
        }
      });
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _celebrationController,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Celebration effects background
                  _buildCelebrationEffects(),
                  
                  // New rank badge
                  HunterRankBadge(
                    rank: widget.newRank,
                    size: HunterRankBadgeSize.extraLarge,
                    glowIntensity: 1.0,
                    enableAnimations: true,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCelebrationEffects() {
    switch (widget.celebrationType) {
      case CelebrationType.basic:
        return _buildBasicCelebration();
      case CelebrationType.enhanced:
        return _buildEnhancedCelebration();
      case CelebrationType.elite:
        return _buildEliteCelebration();
      case CelebrationType.legendary:
        return _buildLegendaryCelebration();
      case CelebrationType.mythical:
        return _buildMythicalCelebration();
      case CelebrationType.transcendent:
        return _buildTranscendentCelebration();
    }
  }

  Widget _buildBasicCelebration() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            SystemColors.levelUpGlow.withValues(alpha: 0.3),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedCelebration() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            HunterRankColors.getRankColor(widget.newRank, light: true).withValues(alpha: 0.4),
            HunterRankColors.getRankColor(widget.newRank).withValues(alpha: 0.2),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildEliteCelebration() {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            SystemColors.levelUpGlow.withValues(alpha: 0.5),
            HunterRankColors.getRankColor(widget.newRank).withValues(alpha: 0.3),
            Colors.transparent,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: HunterRankColors.getRankColor(widget.newRank).withValues(alpha: 0.6),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
    );
  }

  Widget _buildLegendaryCelebration() {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [
            Color(0xFFFFD700),
            Color(0xFFFFA500),
            Colors.transparent,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: SystemColors.levelUpGlow.withValues(alpha: 0.8),
            blurRadius: 40,
            spreadRadius: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildMythicalCelebration() {
    return Container(
      width: 200,
      height: 200,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Color(0xFFC0C0C0),
            Color(0xFF94A3B8),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildTranscendentCelebration() {
    return AnimatedBuilder(
      animation: _celebrationController,
      builder: (context, child) {
        final colors = HunterRankColors.sssRank;
        final colorIndex = (_celebrationController.value * colors.length * 3).floor() % colors.length;
        
        return Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                colors[colorIndex].withValues(alpha: 0.6),
                colors[(colorIndex + 1) % colors.length].withValues(alpha: 0.4),
                Colors.transparent,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: colors[colorIndex].withValues(alpha: 0.8),
                blurRadius: 50,
                spreadRadius: 10,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Enum for different Hunter Rank Badge sizes
enum HunterRankBadgeSize {
  small,
  medium,
  large,
  extraLarge,
}