import 'package:flutter/material.dart';
import 'solo_leveling_theme.dart';

/// Solo Leveling inspired icon mappings using Material Icons
/// Maps app concepts to manhwa-inspired icon selections
class SoloLevelingIcons {
  // Private constructor to prevent instantiation
  SoloLevelingIcons._();

  // === STAT ICONS ===
  /// Icons for the 6 core stats with manhwa theming
  static const Map<String, IconData> statIcons = {
    'strength': Icons.fitness_center,           // Physical power
    'agility': Icons.speed,                     // Speed and dexterity  
    'endurance': Icons.favorite,                // Health and stamina
    'intelligence': Icons.psychology,           // Mental capacity
    'focus': Icons.center_focus_strong,         // Concentration
    'charisma': Icons.people_alt,              // Social influence
  };

  // === QUEST/ACTIVITY ICONS ===
  /// Icons for different activity types as "quests"
  static const Map<String, IconData> questIcons = {
    'workout': Icons.fitness_center,            // Physical training
    'cardio': Icons.directions_run,             // Cardio quest
    'study': Icons.menu_book,                   // Knowledge quest
    'reading': Icons.import_contacts,           // Reading quest
    'meditation': Icons.self_improvement,       // Mental quest
    'work': Icons.work,                         // Professional quest
    'hobby': Icons.palette,                     // Creative quest
    'social': Icons.people,                     // Social quest
    'sleep': Icons.bedtime,                     // Rest quest
    'other': Icons.extension,                   // Miscellaneous quest
    
    // Activity type mappings
    'workoutweights': Icons.fitness_center,     // Weight training
    'workoutcardio': Icons.directions_run,      // Cardio training
    'workoutyoga': Icons.self_improvement,      // Yoga/flexibility
    'studyserious': Icons.auto_stories,         // Serious study
    'studycasual': Icons.menu_book,             // Casual study
    'socializing': Icons.people,                // Social activities
    'quitbadhabit': Icons.block,                // Habit breaking
    'sleeptracking': Icons.bedtime,             // Sleep tracking
    'diethealthy': Icons.eco,                   // Healthy eating
  };

  // === HUNTER RANK ICONS ===
  /// Icons for different Hunter ranks with increasing prestige
  static const Map<String, IconData> rankIcons = {
    'E': Icons.shield_outlined,                 // Basic shield
    'D': Icons.shield,                          // Filled shield
    'C': Icons.military_tech,                   // Military badge
    'B': Icons.star_border,                     // Star outline
    'A': Icons.star,                            // Filled star
    'S': Icons.workspace_premium,               // Premium badge
    'SS': Icons.diamond,                        // Diamond
    'SSS': Icons.auto_awesome,                  // Magical/awesome
  };

  // === SYSTEM INTERFACE ICONS ===
  /// Icons for System notifications and interface elements
  static const IconData systemNotification = Icons.notifications_active;
  static const IconData systemAlert = Icons.priority_high;
  static const IconData systemSuccess = Icons.check_circle;
  static const IconData systemWarning = Icons.warning;
  static const IconData systemError = Icons.error;
  static const IconData systemInfo = Icons.info;
  
  // System window controls
  static const IconData systemClose = Icons.close;
  static const IconData systemMinimize = Icons.minimize;
  static const IconData systemMaximize = Icons.crop_square;

  // === ACHIEVEMENT ICONS ===
  /// Icons for different achievement categories
  static const Map<String, IconData> achievementIcons = {
    'level': Icons.trending_up,                 // Level achievements
    'streak': Icons.local_fire_department,      // Streak achievements
    'stat': Icons.bar_chart,                    // Stat achievements
    'quest': Icons.assignment_turned_in,        // Quest achievements
    'special': Icons.emoji_events,              // Special achievements
    'milestone': Icons.flag,                    // Milestone achievements
    'perfect': Icons.stars,                     // Perfect day achievements
    'legendary': Icons.auto_awesome,            // Legendary achievements
  };

  // === NAVIGATION ICONS ===
  /// Main navigation icons with RPG theming
  static const IconData dashboard = Icons.dashboard;
  static const IconData history = Icons.history;
  static const IconData stats = Icons.analytics;
  static const IconData achievements = Icons.emoji_events;
  static const IconData settings = Icons.settings;
  
  // Navigation icons with Solo Leveling theme
  static const IconData navDashboard = Icons.dashboard;
  static const IconData navHistory = Icons.history;
  static const IconData navStats = Icons.analytics;
  static const IconData navAchievements = Icons.emoji_events;
  static const IconData navSettings = Icons.settings;
  static const IconData navProfile = Icons.person;
  
  // Notification icons
  static const IconData notificationError = Icons.error;
  
  // Additional navigation
  static const IconData profile = Icons.person;
  static const IconData inventory = Icons.inventory;
  static const IconData quests = Icons.assignment;

  // === PROGRESSION ICONS ===
  /// Icons for progression and growth
  static const IconData levelUp = Icons.trending_up;
  static const IconData experience = Icons.flash_on;
  static const IconData progression = Icons.timeline;
  static const IconData mastery = Icons.workspace_premium;

  // === ACTION ICONS ===
  /// Icons for user actions
  static const IconData addQuest = Icons.add_task;
  static const IconData completeQuest = Icons.task_alt;
  static const IconData deleteQuest = Icons.delete_outline;
  static const IconData editQuest = Icons.edit;
  static const IconData pauseQuest = Icons.pause_circle_outline;
  static const IconData resumeQuest = Icons.play_circle_outline;

  // === UTILITY METHODS ===
  
  /// Get stat icon by stat name
  static IconData getStatIcon(dynamic statName) {
    // Handle both String and StatType enum
    String key;
    if (statName is String) {
      key = statName.toLowerCase();
    } else {
      key = statName.toString().split('.').last.toLowerCase();
    }
    return statIcons[key] ?? Icons.help_outline;
  }

  /// Get quest icon by activity type
  static IconData getQuestIcon(dynamic activityType) {
    // Handle both String and ActivityType enum
    String key;
    if (activityType is String) {
      key = activityType.toLowerCase();
    } else {
      key = activityType.toString().split('.').last.toLowerCase();
    }
    return questIcons[key] ?? Icons.extension;
  }

  /// Get rank icon by hunter rank
  static IconData getRankIcon(String rank) {
    return rankIcons[rank.toUpperCase()] ?? Icons.help_outline;
  }

  /// Get achievement icon by achievement type
  static IconData getAchievementIcon(dynamic achievementType) {
    // Handle both String and AchievementType enum
    String key;
    if (achievementType is String) {
      key = achievementType.toLowerCase();
    } else {
      key = achievementType.toString().split('.').last.toLowerCase();
    }
    return achievementIcons[key] ?? Icons.emoji_events;
  }

  /// Get appropriate color for a stat icon
  static Color getStatIconColor(dynamic statName, BuildContext context) {
    final theme = Theme.of(context);
    String key;
    if (statName is String) {
      key = statName.toLowerCase();
    } else {
      key = statName.toString().split('.').last.toLowerCase();
    }
    switch (key) {
      case 'strength':
        return SoloLevelingColors.crimsonRed;
      case 'agility':
        return SoloLevelingColors.electricBlue;
      case 'endurance':
        return SoloLevelingColors.hunterGreen;
      case 'intelligence':
        return SoloLevelingColors.electricPurple;
      case 'focus':
        return SoloLevelingColors.mysticTeal;
      case 'charisma':
        return SoloLevelingColors.goldRank;
      default:
        return theme.colorScheme.onSurface;
    }
  }

  /// Get appropriate color for a rank icon
  static Color getRankIconColor(String rank) {
    return HunterRankColors.getRankColor(rank);
  }

  /// Get system icon with appropriate color
  static Widget getSystemIcon(IconData icon, {
    double? size,
    Color? color,
    bool isActive = false,
  }) {
    return Icon(
      icon,
      size: size ?? 24,
      color: color ?? (isActive 
        ? SoloLevelingColors.electricBlue 
        : SoloLevelingColors.systemGray),
    );
  }

  /// Create an animated system icon with glow effect
  static Widget getAnimatedSystemIcon(IconData icon, {
    double? size,
    Color? color,
    bool isGlowing = false,
    Duration duration = const Duration(milliseconds: 1000),
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: isGlowing ? 0.5 : 1.0, end: isGlowing ? 1.0 : 0.5),
      duration: duration,
      builder: (context, value, child) {
        return Container(
          decoration: isGlowing ? BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: (color ?? SoloLevelingColors.electricBlue).withValues(alpha: value * 0.5),
                blurRadius: 10 * value,
                spreadRadius: 2 * value,
              ),
            ],
          ) : null,
          child: Icon(
            icon,
            size: size ?? 24,
            color: color ?? SoloLevelingColors.electricBlue,
          ),
        );
      },
    );
  }
}

/// Factory class for creating Solo Leveling themed icons with consistent styling
class SoloLevelingIconFactory {
  SoloLevelingIconFactory._();

  /// Create a navigation icon with Solo Leveling styling
  static Widget forNavigation(
    IconData iconData, {
    double? size,
    bool isActive = false,
    String? semanticLabel,
  }) {
    return Icon(
      iconData,
      size: size ?? 24,
      semanticLabel: semanticLabel,
    );
  }

  /// Create a stat icon with appropriate theming
  static Widget forStat(
    dynamic statName, {
    double? size,
    BuildContext? context,
  }) {
    final iconData = SoloLevelingIcons.getStatIcon(statName);
    final color = context != null 
        ? SoloLevelingIcons.getStatIconColor(statName, context)
        : null;
    
    return Icon(
      iconData,
      size: size ?? 24,
      color: color,
    );
  }

  /// Create a quest icon with Solo Leveling styling
  static Widget forQuest(
    dynamic activityType, {
    double? size,
    Color? color,
  }) {
    return Icon(
      SoloLevelingIcons.getQuestIcon(activityType),
      size: size ?? 24,
      color: color,
    );
  }

  /// Create a rank icon with appropriate coloring
  static Widget forRank(
    String rank, {
    double? size,
  }) {
    return Icon(
      SoloLevelingIcons.getRankIcon(rank),
      size: size ?? 24,
      color: SoloLevelingIcons.getRankIconColor(rank),
    );
  }

  /// Create an achievement icon
  static Widget forAchievement(
    dynamic achievementType, {
    double? size,
    Color? color,
  }) {
    return Icon(
      SoloLevelingIcons.getAchievementIcon(achievementType),
      size: size ?? 24,
      color: color,
    );
  }
}

/// Extension methods for easy icon usage throughout the app
extension SoloLevelingIconExtensions on String {
  /// Get stat icon for this string
  IconData get asStatIcon => SoloLevelingIcons.getStatIcon(this);
  
  /// Get quest icon for this string
  IconData get asQuestIcon => SoloLevelingIcons.getQuestIcon(this);
  
  /// Get rank icon for this string
  IconData get asRankIcon => SoloLevelingIcons.getRankIcon(this);
  
  /// Get achievement icon for this string
  IconData get asAchievementIcon => SoloLevelingIcons.getAchievementIcon(this);
}