import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/enums.dart';
import '../models/user.dart';
import '../models/activity_log.dart';
import '../models/settings.dart';
import '../models/achievement.dart';

/// Configuration class for Hive local storage
class HiveConfig {
  static const String userBoxName = 'user_box';
  static const String activityBoxName = 'activity_box';
  static const String settingsBoxName = 'settings_box';
  static const String achievementBoxName = 'achievement_box';

  /// Initialize Hive with proper configuration
  static Future<void> initialize() async {
    // Initialize Hive for Flutter (this handles path setup automatically)
    await Hive.initFlutter();
    
    // Register adapters for all models
    _registerAdapters();
    
    // Open boxes
    await _openBoxes();
  }

  /// Register all Hive adapters
  static void _registerAdapters() {
    // Register enum adapters
    Hive.registerAdapter(ActivityTypeAdapter());
    Hive.registerAdapter(StatTypeAdapter());
    Hive.registerAdapter(AchievementTypeAdapter());
    
    // Register model adapters
    Hive.registerAdapter(UserAdapter());
    Hive.registerAdapter(ActivityLogAdapter());
    Hive.registerAdapter(SettingsAdapter());
    Hive.registerAdapter(AchievementAdapter());
  }

  /// Open all required Hive boxes
  static Future<void> _openBoxes() async {
    try {
      await Hive.openBox<User>(userBoxName);
      await Hive.openBox<ActivityLog>(activityBoxName);
      await Hive.openBox<Settings>(settingsBoxName);
      await Hive.openBox<Achievement>(achievementBoxName);
    } catch (e) {
      throw Exception('Failed to open Hive boxes: $e');
    }
  }

  /// Get a specific box by name
  static Box getBox(String boxName) {
    if (!Hive.isBoxOpen(boxName)) {
      throw Exception('Box $boxName is not open');
    }
    return Hive.box(boxName);
  }

  /// Get a typed box by name
  static Box<T> getTypedBox<T>(String boxName) {
    if (!Hive.isBoxOpen(boxName)) {
      throw Exception('Box $boxName is not open');
    }
    return Hive.box<T>(boxName);
  }

  /// Close all boxes (for cleanup)
  static Future<void> closeBoxes() async {
    await Hive.close();
  }
}