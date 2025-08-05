import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../theme/solo_leveling_icons.dart';

part 'enums.g.dart';

/// Enum representing different types of activities that can be logged
@HiveType(typeId: 0)
enum ActivityType {
  @HiveField(0)
  workoutWeights,
  
  @HiveField(1)
  workoutCardio,
  
  @HiveField(2)
  workoutYoga,
  
  @HiveField(3)
  studySerious,
  
  @HiveField(4)
  studyCasual,
  
  @HiveField(5)
  meditation,
  
  @HiveField(6)
  socializing,
  
  @HiveField(7)
  quitBadHabit,
  
  @HiveField(8)
  sleepTracking,
  
  @HiveField(9)
  dietHealthy;

  /// Get display name for the activity type
  String get displayName {
    switch (this) {
      case ActivityType.workoutWeights:
        return 'Workout - Weights';
      case ActivityType.workoutCardio:
        return 'Workout - Cardio';
      case ActivityType.workoutYoga:
        return 'Workout - Yoga/Flexibility';
      case ActivityType.studySerious:
        return 'Study - Serious';
      case ActivityType.studyCasual:
        return 'Study - Casual';
      case ActivityType.meditation:
        return 'Meditation/Mindfulness';
      case ActivityType.socializing:
        return 'Socializing';
      case ActivityType.quitBadHabit:
        return 'Quit Bad Habit';
      case ActivityType.sleepTracking:
        return 'Sleep Tracking';
      case ActivityType.dietHealthy:
        return 'Diet/Healthy Eating';
    }
  }

  /// Get category for degradation purposes
  ActivityCategory get category {
    switch (this) {
      case ActivityType.workoutWeights:
      case ActivityType.workoutCardio:
      case ActivityType.workoutYoga:
        return ActivityCategory.workout;
      case ActivityType.studySerious:
      case ActivityType.studyCasual:
        return ActivityCategory.study;
      case ActivityType.meditation:
      case ActivityType.socializing:
      case ActivityType.quitBadHabit:
      case ActivityType.sleepTracking:
      case ActivityType.dietHealthy:
        return ActivityCategory.other;
    }
  }

  /// Get Solo Leveling themed icon for the activity type
  IconData get icon {
    return SoloLevelingIcons.getQuestIcon(this);
  }
  
  /// Get the original Material icon for backward compatibility
  IconData get materialIcon {
    switch (this) {
      case ActivityType.workoutWeights:
        return Icons.fitness_center;
      case ActivityType.workoutCardio:
        return Icons.directions_run;
      case ActivityType.workoutYoga:
        return Icons.self_improvement;
      case ActivityType.studySerious:
        return Icons.auto_stories;
      case ActivityType.studyCasual:
        return Icons.menu_book;
      case ActivityType.meditation:
        return Icons.psychology;
      case ActivityType.socializing:
        return Icons.groups;
      case ActivityType.quitBadHabit:
        return Icons.block;
      case ActivityType.sleepTracking:
        return Icons.bedtime;
      case ActivityType.dietHealthy:
        return Icons.eco;
    }
  }

  /// Get color for the activity type
  Color get color {
    switch (this) {
      case ActivityType.workoutWeights:
        return const Color(0xFFE74C3C); // Red
      case ActivityType.workoutCardio:
        return const Color(0xFFE67E22); // Orange
      case ActivityType.workoutYoga:
        return const Color(0xFF9B59B6); // Purple
      case ActivityType.studySerious:
        return const Color(0xFF3498DB); // Blue
      case ActivityType.studyCasual:
        return const Color(0xFF5DADE2); // Light Blue
      case ActivityType.meditation:
        return const Color(0xFF1ABC9C); // Teal
      case ActivityType.socializing:
        return const Color(0xFFF39C12); // Yellow
      case ActivityType.quitBadHabit:
        return const Color(0xFF95A5A6); // Gray
      case ActivityType.sleepTracking:
        return const Color(0xFF6C5CE7); // Indigo
      case ActivityType.dietHealthy:
        return const Color(0xFF00B894); // Green
    }
  }
}

/// Enum representing different stat types
@HiveType(typeId: 1)
enum StatType {
  @HiveField(0)
  strength,
  
  @HiveField(1)
  agility,
  
  @HiveField(2)
  endurance,
  
  @HiveField(3)
  intelligence,
  
  @HiveField(4)
  focus,
  
  @HiveField(5)
  charisma;

  /// Get display name for the stat type
  String get displayName {
    switch (this) {
      case StatType.strength:
        return 'Strength';
      case StatType.agility:
        return 'Agility';
      case StatType.endurance:
        return 'Endurance';
      case StatType.intelligence:
        return 'Intelligence';
      case StatType.focus:
        return 'Focus';
      case StatType.charisma:
        return 'Charisma';
    }
  }

  /// Get Solo Leveling themed icon for the stat type
  IconData get icon {
    return SoloLevelingIcons.getStatIcon(this);
  }
  
  /// Get emoji icon for the stat type (for display purposes)
  String get emojiIcon {
    switch (this) {
      case StatType.strength:
        return '💪';
      case StatType.agility:
        return '🏃';
      case StatType.endurance:
        return '🏋️';
      case StatType.intelligence:
        return '🧠';
      case StatType.focus:
        return '🎯';
      case StatType.charisma:
        return '✨';
    }
  }

  /// Get color for the stat type
  Color get color {
    switch (this) {
      case StatType.strength:
        return const Color(0xFFE74C3C); // Red
      case StatType.agility:
        return const Color(0xFF9B59B6); // Purple
      case StatType.endurance:
        return const Color(0xFF27AE60); // Green
      case StatType.intelligence:
        return const Color(0xFF3498DB); // Blue
      case StatType.focus:
        return const Color(0xFFF39C12); // Orange
      case StatType.charisma:
        return const Color(0xFFE91E63); // Pink
    }
  }
}

/// Categories for activity types (used for degradation logic)
enum ActivityCategory {
  workout,
  study,
  other,
}

/// Enum representing different types of achievements
@HiveType(typeId: 6)
enum AchievementType {
  @HiveField(0)
  firstActivity,
  
  @HiveField(1)
  streak7Days,
  
  @HiveField(2)
  streak30Days,
  
  @HiveField(3)
  level5Reached,
  
  @HiveField(4)
  level10Reached,
  
  @HiveField(5)
  level25Reached,
  
  @HiveField(6)
  totalActivities50,
  
  @HiveField(7)
  totalActivities100,
  
  @HiveField(8)
  totalActivities500,
  
  @HiveField(9)
  workoutWarrior,
  
  @HiveField(10)
  studyScholar,
  
  @HiveField(11)
  wellRounded;

  /// Get display name for the achievement type
  String get displayName {
    switch (this) {
      case AchievementType.firstActivity:
        return 'First Steps';
      case AchievementType.streak7Days:
        return 'Week Warrior';
      case AchievementType.streak30Days:
        return 'Monthly Master';
      case AchievementType.level5Reached:
        return 'Rising Star';
      case AchievementType.level10Reached:
        return 'Dedicated Leveler';
      case AchievementType.level25Reached:
        return 'Elite Hunter';
      case AchievementType.totalActivities50:
        return 'Active Lifestyle';
      case AchievementType.totalActivities100:
        return 'Consistency King';
      case AchievementType.totalActivities500:
        return 'Legendary Grinder';
      case AchievementType.workoutWarrior:
        return 'Workout Warrior';
      case AchievementType.studyScholar:
        return 'Study Scholar';
      case AchievementType.wellRounded:
        return 'Well Rounded';
    }
  }

  /// Get description for the achievement type
  String get description {
    switch (this) {
      case AchievementType.firstActivity:
        return 'Log your first activity';
      case AchievementType.streak7Days:
        return 'Maintain a 7-day activity streak';
      case AchievementType.streak30Days:
        return 'Maintain a 30-day activity streak';
      case AchievementType.level5Reached:
        return 'Reach Level 5';
      case AchievementType.level10Reached:
        return 'Reach Level 10';
      case AchievementType.level25Reached:
        return 'Reach Level 25';
      case AchievementType.totalActivities50:
        return 'Log 50 total activities';
      case AchievementType.totalActivities100:
        return 'Log 100 total activities';
      case AchievementType.totalActivities500:
        return 'Log 500 total activities';
      case AchievementType.workoutWarrior:
        return 'Log 25 workout activities';
      case AchievementType.studyScholar:
        return 'Log 25 study activities';
      case AchievementType.wellRounded:
        return 'Log at least 5 activities of each type';
    }
  }

  /// Get target value for the achievement
  int get targetValue {
    switch (this) {
      case AchievementType.firstActivity:
        return 1;
      case AchievementType.streak7Days:
        return 7;
      case AchievementType.streak30Days:
        return 30;
      case AchievementType.level5Reached:
        return 5;
      case AchievementType.level10Reached:
        return 10;
      case AchievementType.level25Reached:
        return 25;
      case AchievementType.totalActivities50:
        return 50;
      case AchievementType.totalActivities100:
        return 100;
      case AchievementType.totalActivities500:
        return 500;
      case AchievementType.workoutWarrior:
        return 25;
      case AchievementType.studyScholar:
        return 25;
      case AchievementType.wellRounded:
        return 5;
    }
  }

  /// Get Solo Leveling themed icon for the achievement type
  IconData get icon {
    return SoloLevelingIcons.getAchievementIcon(this);
  }
  
  /// Get the original Material icon for backward compatibility
  IconData get materialIcon {
    switch (this) {
      case AchievementType.firstActivity:
        return Icons.play_circle;
      case AchievementType.streak7Days:
        return Icons.local_fire_department;
      case AchievementType.streak30Days:
        return Icons.whatshot;
      case AchievementType.level5Reached:
        return Icons.star_outline;
      case AchievementType.level10Reached:
        return Icons.star;
      case AchievementType.level25Reached:
        return Icons.auto_awesome;
      case AchievementType.totalActivities50:
        return Icons.trending_up;
      case AchievementType.totalActivities100:
        return Icons.show_chart;
      case AchievementType.totalActivities500:
        return Icons.timeline;
      case AchievementType.workoutWarrior:
        return Icons.fitness_center;
      case AchievementType.studyScholar:
        return Icons.auto_stories;
      case AchievementType.wellRounded:
        return Icons.psychology;
    }
  }

  /// Get color for the achievement type
  Color get color {
    switch (this) {
      case AchievementType.firstActivity:
        return const Color(0xFF4CAF50); // Green
      case AchievementType.streak7Days:
        return const Color(0xFFFF9800); // Orange
      case AchievementType.streak30Days:
        return const Color(0xFFFF5722); // Deep Orange
      case AchievementType.level5Reached:
        return const Color(0xFF2196F3); // Blue
      case AchievementType.level10Reached:
        return const Color(0xFF3F51B5); // Indigo
      case AchievementType.level25Reached:
        return const Color(0xFF9C27B0); // Purple
      case AchievementType.totalActivities50:
        return const Color(0xFF009688); // Teal
      case AchievementType.totalActivities100:
        return const Color(0xFF607D8B); // Blue Grey
      case AchievementType.totalActivities500:
        return const Color(0xFFFFD700); // Gold
      case AchievementType.workoutWarrior:
        return const Color(0xFFE74C3C); // Red
      case AchievementType.studyScholar:
        return const Color(0xFF3498DB); // Blue
      case AchievementType.wellRounded:
        return const Color(0xFF1ABC9C); // Turquoise
    }
  }

  /// Get rarity level (1-5, 5 being rarest)
  int get rarity {
    switch (this) {
      case AchievementType.firstActivity:
        return 1;
      case AchievementType.streak7Days:
        return 2;
      case AchievementType.totalActivities50:
        return 2;
      case AchievementType.level5Reached:
        return 2;
      case AchievementType.workoutWarrior:
        return 3;
      case AchievementType.studyScholar:
        return 3;
      case AchievementType.totalActivities100:
        return 3;
      case AchievementType.level10Reached:
        return 3;
      case AchievementType.streak30Days:
        return 4;
      case AchievementType.wellRounded:
        return 4;
      case AchievementType.level25Reached:
        return 4;
      case AchievementType.totalActivities500:
        return 5;
    }
  }
}