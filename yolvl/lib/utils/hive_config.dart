import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/enums.dart';
import '../models/user.dart';
import '../models/activity_log.dart';
import '../models/settings.dart';

/// Configuration class for Hive local storage
class HiveConfig {
  static const String userBoxName = 'user_box';
  static const String activityBoxName = 'activity_box';
  static const String settingsBoxName = 'settings_box';

  /// Initialize Hive with proper configuration
  static Future<void> initialize() async {
    // Initialize Hive for Flutter
    await Hive.initFlutter();
    
    // Get application documents directory for storage
    final appDocumentDir = await getApplicationDocumentsDirectory();
    Hive.init(appDocumentDir.path);
    
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
    
    // Register model adapters
    Hive.registerAdapter(UserAdapter());
    Hive.registerAdapter(ActivityLogAdapter());
    Hive.registerAdapter(SettingsAdapter());
  }

  /// Open all required Hive boxes
  static Future<void> _openBoxes() async {
    try {
      await Hive.openBox(userBoxName);
      await Hive.openBox(activityBoxName);
      await Hive.openBox(settingsBoxName);
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

  /// Close all boxes (for cleanup)
  static Future<void> closeBoxes() async {
    await Hive.close();
  }
}