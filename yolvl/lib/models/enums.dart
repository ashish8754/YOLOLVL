import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

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

  /// Get icon for the activity type
  IconData get icon {
    switch (this) {
      case ActivityType.workoutWeights:
        return Icons.fitness_center;
      case ActivityType.workoutCardio:
        return Icons.directions_run;
      case ActivityType.workoutYoga:
        return Icons.self_improvement;
      case ActivityType.studySerious:
        return Icons.school;
      case ActivityType.studyCasual:
        return Icons.menu_book;
      case ActivityType.meditation:
        return Icons.spa;
      case ActivityType.socializing:
        return Icons.people;
      case ActivityType.quitBadHabit:
        return Icons.block;
      case ActivityType.sleepTracking:
        return Icons.bedtime;
      case ActivityType.dietHealthy:
        return Icons.restaurant;
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

  /// Get emoji icon for the stat type
  String get icon {
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