import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Comprehensive Solo Leveling-inspired theme system for YoLvL app
/// Captures the dark, mysterious, and epic aesthetic of the manhwa
class SoloLevelingTheme {
  // Private constructor to prevent instantiation
  SoloLevelingTheme._();

  /// Core Solo Leveling Color Palette
  static const SoloLevelingColors colors = SoloLevelingColors._();
  
  /// Hunter Rank Color System
  static const HunterRankColors hunterRanks = HunterRankColors._();
  
  /// System Interface Colors
  static const SystemColors system = SystemColors._();
  
  /// Gradient Definitions
  static const SoloLevelingGradients gradients = SoloLevelingGradients._();
  
  /// Typography System
  static const SoloLevelingTypography typography = SoloLevelingTypography._();

  /// Build the main dark theme with Solo Leveling aesthetics
  static ThemeData buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Core color scheme
      colorScheme: ColorScheme.dark(
        // Base colors - Deep midnight theme
        surface: SoloLevelingColors.midnightBase,
        surfaceContainer: SoloLevelingColors.shadowDepth,
        surfaceContainerHighest: SoloLevelingColors.voidBlack,
        
        // Primary - Hunter green for stats/progress
        primary: SoloLevelingColors.hunterGreen,
        primaryContainer: SoloLevelingColors.hunterGreenDark,
        onPrimary: SoloLevelingColors.pureLight,
        onPrimaryContainer: SoloLevelingColors.electricBlue,
        
        // Secondary - Electric blue for EXP/system
        secondary: SoloLevelingColors.electricBlue,
        secondaryContainer: SoloLevelingColors.electricBlueDark,
        onSecondary: SoloLevelingColors.pureLight,
        onSecondaryContainer: SoloLevelingColors.mysticPurple,
        
        // Tertiary - Mystic purple for special elements
        tertiary: SoloLevelingColors.mysticPurple,
        tertiaryContainer: SoloLevelingColors.mysticPurpleDark,
        onTertiary: SoloLevelingColors.pureLight,
        onTertiaryContainer: SoloLevelingColors.hunterGreen,
        
        // Error - Crimson red for warnings/dangers
        error: SoloLevelingColors.crimsonRed,
        errorContainer: SoloLevelingColors.crimsonRedDark,
        onError: SoloLevelingColors.pureLight,
        onErrorContainer: SoloLevelingColors.crimsonRed,
        
        // Text colors
        onSurface: SoloLevelingColors.ghostWhite,
        onSurfaceVariant: SoloLevelingColors.silverMist,
        outline: SoloLevelingColors.shadowGray,
        outlineVariant: SoloLevelingColors.deepShadow,
        
        // Special colors
        inverseSurface: SoloLevelingColors.pureLight,
        onInverseSurface: SoloLevelingColors.midnightBase,
        inversePrimary: SoloLevelingColors.hunterGreenLight,
        
        // Shadow and scrim
        shadow: SoloLevelingColors.voidBlack,
        scrim: SoloLevelingColors.voidBlack.withValues(alpha: 0.8),
      ),
      
      // Typography
      textTheme: const SoloLevelingTypography._().buildTextTheme(),
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: SoloLevelingColors.voidBlack.withValues(alpha: 0.9),
        foregroundColor: SoloLevelingColors.ghostWhite,
        elevation: 0,
        scrolledUnderElevation: 4,
        shadowColor: SoloLevelingColors.electricBlue.withValues(alpha: 0.3),
        titleTextStyle: SoloLevelingTypography.hunterTitle,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: SoloLevelingColors.shadowDepth,
        shadowColor: SoloLevelingColors.electricBlue.withValues(alpha: 0.2),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: SoloLevelingColors.electricBlue.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SoloLevelingColors.hunterGreen,
          foregroundColor: SoloLevelingColors.pureLight,
          elevation: 8,
          shadowColor: SoloLevelingColors.hunterGreen.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: SoloLevelingTypography.systemNotification,
        ),
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: SoloLevelingColors.electricBlue,
        foregroundColor: SoloLevelingColors.pureLight,
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SoloLevelingColors.shadowDepth,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: SoloLevelingColors.electricBlue.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: SoloLevelingColors.silverMist.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: SoloLevelingColors.electricBlue, width: 2),
        ),
        labelStyle: TextStyle(color: SoloLevelingColors.silverMist),
        hintStyle: TextStyle(color: SoloLevelingColors.shadowGray),
      ),
      
      // Progress Indicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: SoloLevelingColors.electricBlue,
        linearTrackColor: SoloLevelingColors.shadowGray,
        circularTrackColor: SoloLevelingColors.shadowGray,
      ),
      
      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return SoloLevelingColors.hunterGreen;
          }
          return SoloLevelingColors.shadowGray;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return SoloLevelingColors.hunterGreen.withValues(alpha: 0.5);
          }
          return SoloLevelingColors.deepShadow;
        }),
      ),
      
      // Divider Theme
      dividerTheme: DividerThemeData(
        color: SoloLevelingColors.deepShadow,
        thickness: 1,
        space: 1,
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: SoloLevelingColors.voidBlack.withValues(alpha: 0.95),
        selectedItemColor: SoloLevelingColors.electricBlue,
        unselectedItemColor: SoloLevelingColors.silverMist,
        type: BottomNavigationBarType.fixed,
        elevation: 16,
        selectedLabelStyle: SoloLevelingTypography.systemNotification.copyWith(fontSize: 12),
        unselectedLabelStyle: SoloLevelingTypography.systemNotification.copyWith(fontSize: 12),
      ),
    );
  }

  /// Build light theme (minimal Solo Leveling inspiration for accessibility)
  static ThemeData buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      colorScheme: ColorScheme.light(
        surface: const Color(0xFFFAFAFA),
        surfaceContainer: const Color(0xFFF5F5F5),
        primary: SoloLevelingColors.hunterGreenLight,
        secondary: const Color(0xFF1E40AF),
        tertiary: const Color(0xFF7C3AED),
        error: const Color(0xFFDC2626),
        onSurface: const Color(0xFF1F2937),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      
      textTheme: const SoloLevelingTypography._().buildLightTextTheme(),
    );
  }
}

/// Core color palette inspired by Solo Leveling manhwa
class SoloLevelingColors {
  const SoloLevelingColors._();
  
  // Base theme colors - Dark and mysterious
  static const Color voidBlack = Color(0xFF000000);
  static const Color midnightBase = Color(0xFF0A0B1E);
  static const Color shadowDepth = Color(0xFF161B22);
  static const Color deepShadow = Color(0xFF21262D);
  
  // Primary colors - Hunter theme
  static const Color hunterGreen = Color(0xFF10B981);
  static const Color hunterGreenDark = Color(0xFF047857);
  static const Color hunterGreenLight = Color(0xFF34D399);
  
  // Secondary colors - Electric/System theme
  static const Color electricBlue = Color(0xFF6366F1);
  static const Color electricBlueDark = Color(0xFF4338CA);
  static const Color electricBlueLight = Color(0xFF818CF8);
  
  // Tertiary colors - Mystic/Magic theme
  static const Color mysticPurple = Color(0xFF8B5CF6);
  static const Color mysticPurpleDark = Color(0xFF7C3AED);
  static const Color mysticPurpleLight = Color(0xFFDDD6FE);
  
  // Error/Warning colors
  static const Color crimsonRed = Color(0xFFEF4444);
  static const Color crimsonRedDark = Color(0xFFDC2626);
  static const Color crimsonRedLight = Color(0xFFFECACA);
  
  // Text and UI colors
  static const Color pureLight = Color(0xFFF8FAFC);
  static const Color ghostWhite = Color(0xFFF1F5F9);
  static const Color silverMist = Color(0xFFCBD5E1);
  static const Color shadowGray = Color(0xFF64748B);
  
  // Additional colors for icons and system elements
  static const Color electricPurple = Color(0xFF8B5CF6);
  static const Color mysticTeal = Color(0xFF14B8A6);
  static const Color goldRank = Color(0xFFF59E0B);
  static const Color systemGray = Color(0xFF9CA3AF);
}

/// Hunter rank color system from Solo Leveling
class HunterRankColors {
  const HunterRankColors._();
  
  // E-Rank (Gray - Weakest)
  static const Color eRank = Color(0xFF6B7280);
  static const Color eRankLight = Color(0xFF9CA3AF);
  
  // D-Rank (Brown)
  static const Color dRank = Color(0xFF92400E);
  static const Color dRankLight = Color(0xFFD97706);
  
  // C-Rank (Green)
  static const Color cRank = Color(0xFF047857);
  static const Color cRankLight = Color(0xFF10B981);
  
  // B-Rank (Blue)
  static const Color bRank = Color(0xFF1D4ED8);
  static const Color bRankLight = Color(0xFF3B82F6);
  
  // A-Rank (Purple)
  static const Color aRank = Color(0xFF7C3AED);
  static const Color aRankLight = Color(0xFF8B5CF6);
  
  // S-Rank (Gold)
  static const Color sRank = Color(0xFFD97706);
  static const Color sRankLight = Color(0xFFF59E0B);
  
  // SS-Rank (Silver)
  static const Color ssRank = Color(0xFF64748B);
  static const Color ssRankLight = Color(0xFF94A3B8);
  
  // SSS-Rank (Rainbow/Prismatic)
  static const List<Color> sssRank = [
    Color(0xFFEF4444), // Red
    Color(0xFFF59E0B), // Orange
    Color(0xFFEAB308), // Yellow
    Color(0xFF10B981), // Green
    Color(0xFF3B82F6), // Blue
    Color(0xFF8B5CF6), // Purple
  ];
  
  /// Get rank color by rank enum or string
  static Color getRankColor(String rank, {bool light = false}) {
    switch (rank.toUpperCase()) {
      case 'E':
        return light ? eRankLight : eRank;
      case 'D':
        return light ? dRankLight : dRank;
      case 'C':
        return light ? cRankLight : cRank;
      case 'B':
        return light ? bRankLight : bRank;
      case 'A':
        return light ? aRankLight : aRank;
      case 'S':
        return light ? sRankLight : sRank;
      case 'SS':
        return light ? ssRankLight : ssRank;
      case 'SSS':
        return sssRank[0]; // Return primary color for SSS
      default:
        return light ? eRankLight : eRank;
    }
  }
}

/// System interface colors for UI elements
class SystemColors {
  const SystemColors._();
  
  // System notification colors
  static const Color systemSuccess = Color(0xFF10B981);
  static const Color systemWarning = Color(0xFFF59E0B);
  static const Color systemError = Color(0xFFEF4444);
  static const Color systemInfo = Color(0xFF6366F1);
  
  // Special effect colors
  static const Color levelUpGlow = Color(0xFFFFD700);
  static const Color criticalHit = Color(0xFFFF6B6B);
  static const Color healingGreen = Color(0xFF51CF66);
  static const Color manaBlue = Color(0xFF4DABF7);
  
  // Stat-specific colors
  static const Color strengthRed = Color(0xFFE03131);
  static const Color agilityGreen = Color(0xFF2B8A3E);
  static const Color enduranceOrange = Color(0xFFE8590C);
  static const Color intelligenceBlue = Color(0xFF1864AB);
  static const Color focusPurple = Color(0xFF7048E8);
  static const Color charismaYellow = Color(0xFFE67700);
}

/// Gradient definitions for backgrounds and UI elements
class SoloLevelingGradients {
  const SoloLevelingGradients._();
  
  // Main background gradients
  static const LinearGradient mainBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      SoloLevelingColors.midnightBase,
      SoloLevelingColors.shadowDepth,
      SoloLevelingColors.voidBlack,
    ],
    stops: [0.0, 0.6, 1.0],
  );
  
  // Hunter rank gradients
  static const LinearGradient hunterProgress = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      SoloLevelingColors.hunterGreen,
      SoloLevelingColors.electricBlue,
    ],
  );
  
  // System interface gradients
  static const LinearGradient systemPanel = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1F2937),
      Color(0xFF111827),
    ],
  );
  
  // Level up celebration gradient
  static const RadialGradient levelUpCelebration = RadialGradient(
    center: Alignment.center,
    radius: 1.0,
    colors: [
      Color(0xFFFFD700),
      Color(0xFFFFA500),
      Color(0xFFFF6347),
      Colors.transparent,
    ],
    stops: [0.0, 0.3, 0.6, 1.0],
  );
  
  // Stats progress gradients
  static const LinearGradient strengthGradient = LinearGradient(
    colors: [Color(0xFFE03131), Color(0xFFFF6B6B)],
  );
  
  static const LinearGradient agilityGradient = LinearGradient(
    colors: [Color(0xFF2B8A3E), Color(0xFF51CF66)],
  );
  
  static const LinearGradient enduranceGradient = LinearGradient(
    colors: [Color(0xFFE8590C), Color(0xFFFF8C42)],
  );
  
  static const LinearGradient intelligenceGradient = LinearGradient(
    colors: [Color(0xFF1864AB), Color(0xFF4DABF7)],
  );
  
  static const LinearGradient focusGradient = LinearGradient(
    colors: [Color(0xFF7048E8), Color(0xFF9775FA)],
  );
  
  static const LinearGradient charismaGradient = LinearGradient(
    colors: [Color(0xFFE67700), Color(0xFFFFB347)],
  );
}

/// Typography system with Solo Leveling-inspired styling
class SoloLevelingTypography {
  const SoloLevelingTypography._();
  
  // Base font family
  static const String fontFamily = 'Roboto';
  
  // Hunter-themed text styles
  static const TextStyle hunterTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w900,
    color: SoloLevelingColors.electricBlue,
    letterSpacing: 1.2,
    height: 1.2,
  );
  
  static const TextStyle hunterSubtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: SoloLevelingColors.hunterGreen,
    letterSpacing: 0.8,
  );
  
  // System notification styles
  static const TextStyle systemNotification = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: SoloLevelingColors.ghostWhite,
    letterSpacing: 0.5,
  );
  
  static const TextStyle systemAlert = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: SoloLevelingColors.crimsonRed,
    letterSpacing: 0.8,
  );
  
  // Stat display styles
  static const TextStyle statValue = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: SoloLevelingColors.electricBlue,
    letterSpacing: 1.0,
  );
  
  static const TextStyle statLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: SoloLevelingColors.silverMist,
    letterSpacing: 1.2,
  );
  
  // Level and EXP styles
  static const TextStyle levelDisplay = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: SoloLevelingColors.electricBlue,
    letterSpacing: 1.5,
  );
  
  static const TextStyle expDisplay = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: SoloLevelingColors.hunterGreen,
    letterSpacing: 0.8,
  );
  
  // Rank display style
  static const TextStyle rankDisplay = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.2,
  );
  
  /// Build complete text theme for dark mode
  TextTheme buildTextTheme() {
    return TextTheme(
      // Display styles
      displayLarge: hunterTitle.copyWith(fontSize: 36),
      displayMedium: hunterTitle.copyWith(fontSize: 32),
      displaySmall: hunterTitle,
      
      // Headline styles
      headlineLarge: hunterSubtitle.copyWith(fontSize: 24),
      headlineMedium: hunterSubtitle.copyWith(fontSize: 20),
      headlineSmall: hunterSubtitle,
      
      // Title styles
      titleLarge: systemNotification.copyWith(fontSize: 20),
      titleMedium: systemNotification,
      titleSmall: systemNotification.copyWith(fontSize: 14),
      
      // Body styles
      bodyLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: SoloLevelingColors.ghostWhite,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: SoloLevelingColors.silverMist,
        height: 1.4,
      ),
      bodySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: SoloLevelingColors.shadowGray,
        height: 1.3,
      ),
      
      // Label styles
      labelLarge: systemNotification.copyWith(fontSize: 14),
      labelMedium: statLabel.copyWith(fontSize: 12),
      labelSmall: statLabel.copyWith(fontSize: 10),
    );
  }
  
  /// Build light theme text styles (for accessibility)
  TextTheme buildLightTextTheme() {
    return TextTheme(
      displayLarge: hunterTitle.copyWith(fontSize: 36, color: const Color(0xFF1F2937)),
      displayMedium: hunterTitle.copyWith(fontSize: 32, color: const Color(0xFF1F2937)),
      displaySmall: hunterTitle.copyWith(color: const Color(0xFF1F2937)),
      
      headlineLarge: hunterSubtitle.copyWith(fontSize: 24, color: const Color(0xFF374151)),
      headlineMedium: hunterSubtitle.copyWith(fontSize: 20, color: const Color(0xFF374151)),
      headlineSmall: hunterSubtitle.copyWith(color: const Color(0xFF374151)),
      
      titleLarge: systemNotification.copyWith(fontSize: 20, color: const Color(0xFF111827)),
      titleMedium: systemNotification.copyWith(color: const Color(0xFF111827)),
      titleSmall: systemNotification.copyWith(fontSize: 14, color: const Color(0xFF111827)),
      
      bodyLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF374151),
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF6B7280),
        height: 1.4,
      ),
      bodySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF9CA3AF),
        height: 1.3,
      ),
      
      labelLarge: systemNotification.copyWith(fontSize: 14, color: const Color(0xFF1F2937)),
      labelMedium: statLabel.copyWith(fontSize: 12, color: const Color(0xFF6B7280)),
      labelSmall: statLabel.copyWith(fontSize: 10, color: const Color(0xFF9CA3AF)),
    );
  }
}

/// Extension methods for easier theme access
extension SoloLevelingThemeExtension on BuildContext {
  /// Quick access to Solo Leveling colors
  SoloLevelingColors get soloColors => SoloLevelingTheme.colors;
  
  /// Quick access to Hunter rank colors
  HunterRankColors get hunterRanks => SoloLevelingTheme.hunterRanks;
  
  /// Quick access to system colors
  SystemColors get systemColors => SoloLevelingTheme.system;
  
  /// Quick access to gradients
  SoloLevelingGradients get soloGradients => SoloLevelingTheme.gradients;
  
  /// Quick access to typography
  SoloLevelingTypography get soloTypography => SoloLevelingTheme.typography;
}