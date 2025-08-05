import 'package:flutter/material.dart';
import 'dart:ui';
import 'solo_leveling_theme.dart';

/// Custom glassmorphism effects for Solo Leveling theme
/// Provides frosted glass and translucent panel effects
class GlassmorphismEffects {
  GlassmorphismEffects._();

  /// Creates a glassmorphism container with frosted glass effect
  static Widget glassmorphicContainer({
    required Widget child,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    BorderRadius? borderRadius,
    double blur = 10.0,
    double opacity = 0.1,
    Color? backgroundColor,
    Border? border,
    List<BoxShadow>? boxShadow,
  }) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        border: border ??
            Border.all(
              color: SoloLevelingColors.electricBlue.withValues(alpha: 0.2),
              width: 1,
            ),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: SoloLevelingColors.electricBlue.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor ??
                  SoloLevelingColors.shadowDepth.withValues(alpha: opacity),
              borderRadius: borderRadius ?? BorderRadius.circular(16),
            ),
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }

  /// Creates a hunter panel with enhanced glassmorphism effect
  static Widget hunterPanel({
    required Widget child,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    bool glowEffect = false,
  }) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SoloLevelingColors.shadowDepth.withValues(alpha: 0.3),
            SoloLevelingColors.deepShadow.withValues(alpha: 0.2),
          ],
        ),
        border: Border.all(
          color: SoloLevelingColors.electricBlue.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: SoloLevelingColors.voidBlack.withValues(alpha: 0.5),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
          if (glowEffect)
            BoxShadow(
              color: SoloLevelingColors.electricBlue.withValues(alpha: 0.2),
              blurRadius: 25,
              spreadRadius: 0,
              offset: const Offset(0, 0),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  SoloLevelingColors.shadowDepth.withValues(alpha: 0.4),
                  SoloLevelingColors.voidBlack.withValues(alpha: 0.3),
                ],
              ),
            ),
            padding: padding ?? const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }

  /// Creates a system interface panel with electric glow
  static Widget systemPanel({
    required Widget child,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    bool isActive = false,
  }) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? SoloLevelingColors.electricBlue
              : SoloLevelingColors.electricBlue.withValues(alpha: 0.3),
          width: isActive ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: SoloLevelingColors.voidBlack.withValues(alpha: 0.6),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
          if (isActive)
            BoxShadow(
              color: SoloLevelingColors.electricBlue.withValues(alpha: 0.4),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 0),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: SoloLevelingColors.shadowDepth.withValues(alpha: 0.8),
            ),
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }

  /// Creates a stat display card with rank-based coloring
  static Widget statCard({
    required Widget child,
    required String rank,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    bool animated = false,
  }) {
    final rankColor = HunterRankColors.getRankColor(rank);
    
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SoloLevelingColors.shadowDepth.withValues(alpha: 0.4),
            SoloLevelingColors.deepShadow.withValues(alpha: 0.3),
          ],
        ),
        border: Border.all(
          color: rankColor.withValues(alpha: 0.6),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: SoloLevelingColors.voidBlack.withValues(alpha: 0.7),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: rankColor.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  SoloLevelingColors.shadowDepth.withValues(alpha: 0.6),
                  rankColor.withValues(alpha: 0.1),
                  SoloLevelingColors.voidBlack.withValues(alpha: 0.4),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }

  /// Creates a level up celebration overlay
  static Widget levelUpOverlay({
    required Widget child,
    bool isVisible = false,
    VoidCallback? onAnimationComplete,
  }) {
    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      onEnd: onAnimationComplete,
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              SystemColors.levelUpGlow.withValues(alpha: 0.3),
              SoloLevelingColors.electricBlue.withValues(alpha: 0.2),
              Colors.transparent,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            color: Colors.transparent,
            child: child,
          ),
        ),
      ),
    );
  }

  /// Creates an achievement notification panel
  static Widget achievementNotification({
    required Widget child,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SystemColors.systemSuccess.withValues(alpha: 0.2),
            SoloLevelingColors.hunterGreen.withValues(alpha: 0.1),
          ],
        ),
        border: Border.all(
          color: SystemColors.systemSuccess.withValues(alpha: 0.8),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: SystemColors.systemSuccess.withValues(alpha: 0.3),
            blurRadius: 15,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: SoloLevelingColors.shadowDepth.withValues(alpha: 0.9),
            ),
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Extension for easy access to glassmorphism effects
extension GlassmorphismExtension on Widget {
  /// Wraps widget in glassmorphic container
  Widget withGlass({
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    BorderRadius? borderRadius,
    double blur = 10.0,
    double opacity = 0.1,
  }) {
    return GlassmorphismEffects.glassmorphicContainer(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      blur: blur,
      opacity: opacity,
      child: this,
    );
  }

  /// Wraps widget in hunter panel
  Widget withHunterPanel({
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    bool glowEffect = false,
  }) {
    return GlassmorphismEffects.hunterPanel(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      glowEffect: glowEffect,
      child: this,
    );
  }

  /// Wraps widget in system panel
  Widget withSystemPanel({
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    bool isActive = false,
  }) {
    return GlassmorphismEffects.systemPanel(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      isActive: isActive,
      child: this,
    );
  }
}