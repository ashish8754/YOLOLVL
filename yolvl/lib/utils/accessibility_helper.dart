import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';

/// Helper class for accessibility features
class AccessibilityHelper {
  /// Minimum touch target size for accessibility
  static const double minTouchTargetSize = 44.0;

  /// Provide haptic feedback for interactions
  static void provideFeedback() {
    HapticFeedback.selectionClick();
  }

  /// Get semantic label for stat values
  static String getStatSemanticLabel(String statName, double value) {
    return '$statName: ${value.toStringAsFixed(2)} points';
  }

  /// Get semantic label for progress bars
  static String getProgressSemanticLabel(String label, double progress, double current, double max) {
    final percentage = (progress * 100).toStringAsFixed(1);
    return '$label: $percentage percent complete. ${current.toStringAsFixed(0)} out of ${max.toStringAsFixed(0)}';
  }

  /// Get semantic label for level information
  static String getLevelSemanticLabel(int level, double exp, double threshold) {
    final progress = (exp / threshold * 100).toStringAsFixed(1);
    return 'Level $level. Experience: ${exp.toStringAsFixed(0)} out of ${threshold.toStringAsFixed(0)}. $progress percent to next level.';
  }

  /// Create accessible button with proper touch target
  static Widget createAccessibleButton({
    required Widget child,
    required VoidCallback onPressed,
    String? semanticLabel,
    String? tooltip,
    EdgeInsets? padding,
  }) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: Tooltip(
        message: tooltip ?? '',
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(
              minWidth: minTouchTargetSize,
              minHeight: minTouchTargetSize,
            ),
            padding: padding ?? const EdgeInsets.all(8),
            child: child,
          ),
        ),
      ),
    );
  }

  /// Create accessible card with proper semantics
  static Widget createAccessibleCard({
    required Widget child,
    String? semanticLabel,
    VoidCallback? onTap,
    EdgeInsets? padding,
    Color? backgroundColor,
    BorderRadius? borderRadius,
  }) {
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      child: Card(
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: minTouchTargetSize,
            ),
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }

  /// Check if high contrast mode is enabled
  static bool isHighContrastEnabled(BuildContext context) {
    return MediaQuery.of(context).highContrast;
  }

  /// Get accessible text style based on system settings
  static TextStyle getAccessibleTextStyle(BuildContext context, TextStyle baseStyle) {
    final mediaQuery = MediaQuery.of(context);
    final textScaleFactor = mediaQuery.textScaler.scale(1.0);
    
    return baseStyle.copyWith(
      fontSize: (baseStyle.fontSize ?? 14) * textScaleFactor,
      // Increase contrast in high contrast mode
      color: isHighContrastEnabled(context) 
          ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)
          : baseStyle.color,
    );
  }

  /// Create accessible progress indicator
  static Widget createAccessibleProgressIndicator({
    required double value,
    required String label,
    Color? color,
    Color? backgroundColor,
    double height = 8,
  }) {
    return Builder(
      builder: (context) {
        final percentage = (value * 100).toStringAsFixed(1);
        return Semantics(
          label: '$label: $percentage percent',
          value: percentage,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: backgroundColor ?? Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(height / 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(height / 2),
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  color ?? Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Announce message to screen readers
  static void announceToScreenReader(BuildContext context, String message) {
    SemanticsService.announce(message, TextDirection.ltr);
  }
}

/// Widget that provides high contrast theme support
class HighContrastTheme extends StatelessWidget {
  final Widget child;
  final bool forceHighContrast;

  const HighContrastTheme({
    super.key,
    required this.child,
    this.forceHighContrast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isHighContrast = forceHighContrast || AccessibilityHelper.isHighContrastEnabled(context);
    
    if (!isHighContrast) {
      return child;
    }

    // Apply high contrast theme
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
          primary: Theme.of(context).brightness == Brightness.dark 
              ? Colors.white 
              : Colors.black,
          onPrimary: Theme.of(context).brightness == Brightness.dark 
              ? Colors.black 
              : Colors.white,
          surface: Theme.of(context).brightness == Brightness.dark 
              ? Colors.black 
              : Colors.white,
          onSurface: Theme.of(context).brightness == Brightness.dark 
              ? Colors.white 
              : Colors.black,
        ),
      ),
      child: child,
    );
  }
}

/// Responsive breakpoints for different screen sizes
class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;

  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobile;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobile && width < desktop;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktop;
  }

  static double getResponsivePadding(BuildContext context) {
    if (isMobile(context)) return 16.0;
    if (isTablet(context)) return 24.0;
    return 32.0;
  }

  static int getResponsiveColumns(BuildContext context) {
    if (isMobile(context)) return 1;
    if (isTablet(context)) return 2;
    return 3;
  }
}

/// Widget that adapts layout based on screen size
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (ResponsiveBreakpoints.isDesktop(context) && desktop != null) {
      return desktop!;
    } else if (ResponsiveBreakpoints.isTablet(context) && tablet != null) {
      return tablet!;
    } else {
      return mobile;
    }
  }
}