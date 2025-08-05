import 'package:flutter/material.dart';
import '../theme/solo_leveling_theme.dart';
import '../theme/solo_leveling_icons.dart';

/// A themed icon widget that wraps regular icons with Solo Leveling styling
/// Supports glow effects, rank-based coloring, and animations
class SoloLevelingIcon extends StatefulWidget {
  /// The icon to display
  final IconData icon;
  
  /// Size of the icon
  final double? size;
  
  /// Color of the icon (if null, uses theme-appropriate color)
  final Color? color;
  
  /// Whether to apply glow effect
  final bool hasGlow;
  
  /// Intensity of glow effect (0.0 to 1.0)
  final double glowIntensity;
  
  /// Whether the icon should pulse
  final bool isPulsing;
  
  /// Hunter rank for rank-based coloring
  final String? hunterRank;
  
  /// Stat name for stat-based coloring
  final String? statName;
  
  /// Whether the icon is in an active state
  final bool isActive;
  
  /// Custom glow color
  final Color? glowColor;
  
  /// Animation duration for pulse effect
  final Duration animationDuration;
  
  /// Semantic label for accessibility
  final String? semanticLabel;

  const SoloLevelingIcon({
    super.key,
    required this.icon,
    this.size,
    this.color,
    this.hasGlow = false,
    this.glowIntensity = 0.5,
    this.isPulsing = false,
    this.hunterRank,
    this.statName,
    this.isActive = false,
    this.glowColor,
    this.animationDuration = const Duration(milliseconds: 1500),
    this.semanticLabel,
  });

  /// Create a stat icon with appropriate theming
  factory SoloLevelingIcon.stat({
    required String statName,
    double? size,
    bool hasGlow = false,
    bool isPulsing = false,
    bool isActive = false,
    String? semanticLabel,
  }) {
    return SoloLevelingIcon(
      icon: SoloLevelingIcons.getStatIcon(statName),
      size: size,
      statName: statName,
      hasGlow: hasGlow,
      isPulsing: isPulsing,
      isActive: isActive,
      semanticLabel: semanticLabel ?? '$statName stat',
    );
  }

  /// Create a quest/activity icon with appropriate theming
  factory SoloLevelingIcon.quest({
    required String activityType,
    double? size,
    bool hasGlow = false,
    bool isPulsing = false,
    bool isActive = false,
    double glowIntensity = 0.5,
    String? semanticLabel,
  }) {
    return SoloLevelingIcon(
      icon: SoloLevelingIcons.getQuestIcon(activityType),
      size: size,
      color: SoloLevelingColors.hunterGreen,
      hasGlow: hasGlow,
      isPulsing: isPulsing,
      isActive: isActive,
      glowIntensity: glowIntensity,
      semanticLabel: semanticLabel ?? '$activityType quest',
    );
  }

  /// Create a hunter rank icon with appropriate theming
  factory SoloLevelingIcon.rank({
    required String rank,
    double? size,
    bool hasGlow = false,
    bool isPulsing = false,
    bool isActive = false,
    String? semanticLabel,
  }) {
    // Higher ranks get automatic glow effects
    final autoGlow = ['S', 'SS', 'SSS'].contains(rank.toUpperCase());
    final autoPulse = ['SS', 'SSS'].contains(rank.toUpperCase());
    
    return SoloLevelingIcon(
      icon: SoloLevelingIcons.getRankIcon(rank),
      size: size,
      hunterRank: rank,
      hasGlow: hasGlow || autoGlow,
      isPulsing: isPulsing || autoPulse,
      isActive: isActive,
      glowIntensity: rank.toUpperCase() == 'SSS' ? 1.0 : 0.7,
      semanticLabel: semanticLabel ?? 'Hunter rank $rank',
    );
  }

  /// Create an achievement icon with appropriate theming
  factory SoloLevelingIcon.achievement({
    required String achievementType,
    double? size,
    bool hasGlow = false,
    bool isPulsing = false,
    bool isActive = false,
    String? semanticLabel,
  }) {
    return SoloLevelingIcon(
      icon: SoloLevelingIcons.getAchievementIcon(achievementType),
      size: size,
      color: SoloLevelingColors.goldRank,
      hasGlow: hasGlow,
      isPulsing: isPulsing,
      isActive: isActive,
      semanticLabel: semanticLabel ?? '$achievementType achievement',
    );
  }

  /// Create a system interface icon with appropriate theming
  factory SoloLevelingIcon.system({
    required IconData icon,
    double? size,
    bool hasGlow = false,
    bool isPulsing = false,
    bool isActive = false,
    String? semanticLabel,
  }) {
    return SoloLevelingIcon(
      icon: icon,
      size: size,
      color: SoloLevelingColors.electricBlue,
      hasGlow: hasGlow,
      isPulsing: isPulsing,
      isActive: isActive,
      semanticLabel: semanticLabel,
    );
  }

  @override
  State<SoloLevelingIcon> createState() => _SoloLevelingIconState();
}

class _SoloLevelingIconState extends State<SoloLevelingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.isPulsing) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(SoloLevelingIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing != oldWidget.isPulsing) {
      if (widget.isPulsing) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
        _animationController.reset();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getIconColor(BuildContext context) {
    if (widget.color != null) {
      return widget.color!;
    }

    if (widget.hunterRank != null) {
      return SoloLevelingIcons.getRankIconColor(widget.hunterRank!);
    }

    if (widget.statName != null) {
      return SoloLevelingIcons.getStatIconColor(widget.statName!, context);
    }

    return widget.isActive
        ? SoloLevelingColors.electricBlue
        : Theme.of(context).colorScheme.onSurface;
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _getIconColor(context);
    final effectiveGlowColor = widget.glowColor ?? iconColor;
    
    Widget iconWidget = Icon(
      widget.icon,
      size: widget.size ?? 24,
      color: iconColor,
      semanticLabel: widget.semanticLabel,
    );

    // Apply pulse animation if enabled
    if (widget.isPulsing) {
      iconWidget = AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: child,
          );
        },
        child: iconWidget,
      );
    }

    // Apply glow effect if enabled
    if (widget.hasGlow) {
      final glowWidget = AnimatedBuilder(
        animation: widget.isPulsing ? _glowAnimation : 
                   const AlwaysStoppedAnimation(1.0),
        builder: (context, child) {
          final glowValue = widget.isPulsing ? _glowAnimation.value : 1.0;
          
          return Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: effectiveGlowColor.withValues(
                    alpha: widget.glowIntensity * glowValue * 0.6
                  ),
                  blurRadius: (widget.size ?? 24) * 0.5 * glowValue,
                  spreadRadius: 2 * glowValue,
                ),
                BoxShadow(
                  color: effectiveGlowColor.withValues(
                    alpha: widget.glowIntensity * glowValue * 0.3
                  ),
                  blurRadius: (widget.size ?? 24) * 1.0 * glowValue,
                  spreadRadius: 4 * glowValue,
                ),
              ],
            ),
            child: child,
          );
        },
        child: iconWidget,
      );
      
      return glowWidget;
    }

    return iconWidget;
  }
}

/// Extension methods for easy themed icon creation
extension IconDataSoloLevelingExtension on IconData {
  /// Convert this IconData to a SoloLevelingIcon
  SoloLevelingIcon toSoloLevelingIcon({
    double? size,
    Color? color,
    bool hasGlow = false,
    bool isPulsing = false,
    bool isActive = false,
    String? semanticLabel,
  }) {
    return SoloLevelingIcon(
      icon: this,
      size: size,
      color: color,
      hasGlow: hasGlow,
      isPulsing: isPulsing,
      isActive: isActive,
      semanticLabel: semanticLabel,
    );
  }

  /// Convert this IconData to a glowing SoloLevelingIcon
  SoloLevelingIcon withGlow({
    double? size,
    Color? color,
    double glowIntensity = 0.5,
    Color? glowColor,
    String? semanticLabel,
  }) {
    return SoloLevelingIcon(
      icon: this,
      size: size,
      color: color,
      hasGlow: true,
      glowIntensity: glowIntensity,
      glowColor: glowColor,
      semanticLabel: semanticLabel,
    );
  }

  /// Convert this IconData to a pulsing SoloLevelingIcon
  SoloLevelingIcon withPulse({
    double? size,
    Color? color,
    bool hasGlow = false,
    Duration animationDuration = const Duration(milliseconds: 1500),
    String? semanticLabel,
  }) {
    return SoloLevelingIcon(
      icon: this,
      size: size,
      color: color,
      hasGlow: hasGlow,
      isPulsing: true,
      animationDuration: animationDuration,
      semanticLabel: semanticLabel,
    );
  }
}