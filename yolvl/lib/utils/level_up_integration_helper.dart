import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/level_up_overlay.dart';
import '../services/hunter_rank_service.dart';
import '../models/enums.dart';
import '../providers/user_provider.dart';

/// Integration helper for the enhanced Solo Leveling level-up celebration system
/// 
/// This helper provides easy-to-use methods for triggering level-up celebrations
/// with the appropriate parameters and animations based on the type of level-up
/// that occurred.
/// 
/// **Key Features:**
/// - Automatically detects celebration type (standard, milestone, rank-up, first)
/// - Calculates stat increases for display
/// - Handles sound effect hooks
/// - Provides proper integration with UserProvider
/// - Manages celebration state and cleanup
/// 
/// **Usage Example:**
/// ```dart
/// // In your widget where level-ups occur
/// class MyWidget extends StatefulWidget {
///   @override
///   _MyWidgetState createState() => _MyWidgetState();
/// }
/// 
/// class _MyWidgetState extends State<MyWidget> {
///   final LevelUpIntegrationHelper _levelUpHelper = LevelUpIntegrationHelper();
///   bool _showCelebration = false;
///   LevelUpCelebrationData? _celebrationData;
/// 
///   @override
///   Widget build(BuildContext context) {
///     return LevelUpOverlay(
///       showCelebration: _showCelebration,
///       newLevel: _celebrationData?.newLevel,
///       previousLevel: _celebrationData?.previousLevel,
///       statIncreases: _celebrationData?.statIncreases,
///       isFirstLevelUp: _celebrationData?.isFirstLevelUp ?? false,
///       onAnimationComplete: _onCelebrationComplete,
///       onSoundEffect: _onSoundEffect,
///       child: Scaffold(
///         // Your main app content
///         body: YourMainContent(),
///       ),
///     );
///   }
/// 
///   void _checkForLevelUp(User oldUser, User newUser) {
///     final celebrationData = _levelUpHelper.checkForLevelUp(
///       oldUser: oldUser,
///       newUser: newUser,
///     );
/// 
///     if (celebrationData != null) {
///       setState(() {
///         _showCelebration = true;
///         _celebrationData = celebrationData;
///       });
///     }
///   }
/// 
///   void _onCelebrationComplete() {
///     setState(() {
///       _showCelebration = false;
///       _celebrationData = null;
///     });
///   }
/// 
///   void _onSoundEffect() {
///     // Trigger your sound effects here
///     _levelUpHelper.playLevelUpSound(_celebrationData!.celebrationType);
///   }
/// }
/// ```
class LevelUpIntegrationHelper {
  static final Map<int, bool> _levelUpHistory = {};

  /// Check if a level-up occurred and return celebration data
  /// 
  /// This method compares the old and new user states to determine if a
  /// level-up occurred and what type of celebration should be triggered.
  LevelUpCelebrationData? checkForLevelUp({
    required dynamic oldUser, // User object
    required dynamic newUser, // User object
    Map<StatType, double>? customStatIncreases,
  }) {
    // Check if level actually increased
    if (newUser.level <= oldUser.level) {
      return null;
    }

    // Calculate stat increases if not provided
    Map<StatType, double> statIncreases = customStatIncreases ?? {};
    if (customStatIncreases == null) {
      statIncreases = _calculateStatIncreases(oldUser, newUser);
    }

    // Determine if this is the first level-up
    final isFirstLevelUp = oldUser.level == 1 && newUser.level == 2;

    // Get rank information
    final oldRank = HunterRankService.instance.getRankForLevel(oldUser.level);
    final newRank = HunterRankService.instance.getRankForLevel(newUser.level);
    final hasRankUp = oldRank.rank != newRank.rank;

    // Determine celebration type
    CelebrationType celebrationType;
    if (isFirstLevelUp) {
      celebrationType = CelebrationType.firstLevelUp;
    } else if (hasRankUp) {
      celebrationType = CelebrationType.rankUp;
    } else if (newUser.level % 10 == 0) {
      celebrationType = CelebrationType.milestone;
    } else {
      celebrationType = CelebrationType.standard;
    }

    // Mark this level as celebrated
    _levelUpHistory[newUser.level] = true;

    return LevelUpCelebrationData(
      previousLevel: oldUser.level,
      newLevel: newUser.level,
      statIncreases: statIncreases,
      celebrationType: celebrationType,
      isFirstLevelUp: isFirstLevelUp,
      hasRankUp: hasRankUp,
      previousRank: oldRank.rank,
      newRank: newRank.rank,
    );
  }

  /// Calculate stat increases between two user states
  Map<StatType, double> _calculateStatIncreases(dynamic oldUser, dynamic newUser) {
    final Map<StatType, double> increases = {};

    for (final statType in StatType.values) {
      final oldValue = oldUser.getStat(statType);
      final newValue = newUser.getStat(statType);
      final increase = newValue - oldValue;

      if (increase > 0) {
        increases[statType] = increase;
      }
    }

    return increases;
  }

  /// Play sound effect based on celebration type
  /// 
  /// This method provides hooks for sound effects. Implement your actual
  /// sound playing logic here or pass this callback to your sound service.
  void playLevelUpSound(CelebrationType type) {
    // Trigger haptic feedback
    switch (type) {
      case CelebrationType.firstLevelUp:
      case CelebrationType.rankUp:
        HapticFeedback.heavyImpact();
        break;
      case CelebrationType.milestone:
        HapticFeedback.mediumImpact();
        break;
      case CelebrationType.standard:
        HapticFeedback.lightImpact();
        break;
    }

    // TODO: Implement actual sound effects
    // Examples:
    // - AudioService.play('level_up_${type.name}.mp3');
    // - SoundPool.play(levelUpSounds[type]);
    // - FlutterAudioQuery.playAsset('sounds/level_up.wav');
    
    debugPrint('🎵 Playing ${type.name} level-up sound effect');
  }

  /// Get celebration intensity multiplier for animations
  double getCelebrationIntensity(CelebrationType type) {
    switch (type) {
      case CelebrationType.firstLevelUp:
        return 1.5;
      case CelebrationType.rankUp:
        return 2.0;
      case CelebrationType.milestone:
        return 1.3;
      case CelebrationType.standard:
        return 1.0;
    }
  }

  /// Check if a level has already been celebrated (prevents duplicate celebrations)
  bool hasLevelBeenCelebrated(int level) {
    return _levelUpHistory[level] ?? false;
  }

  /// Clear celebration history (useful for testing or resetting)
  void clearCelebrationHistory() {
    _levelUpHistory.clear();
  }

  /// Get recommended celebration duration in milliseconds
  int getCelebrationDuration(CelebrationType type) {
    switch (type) {
      case CelebrationType.firstLevelUp:
        return 4000;
      case CelebrationType.rankUp:
        return 5000;
      case CelebrationType.milestone:
        return 3500;
      case CelebrationType.standard:
        return 2500;
    }
  }

  /// Create a celebration message based on the type and context
  String getCelebrationMessage(LevelUpCelebrationData data) {
    switch (data.celebrationType) {
      case CelebrationType.firstLevelUp:
        return "Welcome to the world of Hunters! Your journey begins now.";
      case CelebrationType.rankUp:
        return "Congratulations! You've been promoted to ${data.newRank}-Rank Hunter!";
      case CelebrationType.milestone:
        return "Level ${data.newLevel} achieved! A significant milestone reached.";
      case CelebrationType.standard:
        return "Level up! Your power continues to grow steadily.";
    }
  }
}

/// Data class containing all information needed for level-up celebration
class LevelUpCelebrationData {
  final int previousLevel;
  final int newLevel;
  final Map<StatType, double> statIncreases;
  final CelebrationType celebrationType;
  final bool isFirstLevelUp;
  final bool hasRankUp;
  final String previousRank;
  final String newRank;

  const LevelUpCelebrationData({
    required this.previousLevel,
    required this.newLevel,
    required this.statIncreases,
    required this.celebrationType,
    required this.isFirstLevelUp,
    required this.hasRankUp,
    required this.previousRank,
    required this.newRank,
  });

  /// Convert stat increases to named format for display
  Map<String, double> get namedStatIncreases {
    return Map.fromEntries(
      statIncreases.entries.map(
        (entry) => MapEntry(entry.key.name, entry.value),
      ),
    );
  }
}

/// Celebration type enum (duplicated here for convenience)
enum CelebrationType {
  standard,
  milestone,
  rankUp,
  firstLevelUp,
}

/// Extension for easy UserProvider integration
extension LevelUpIntegrationExtension on UserProvider {
  /// Check for level-up and trigger celebration if needed
  /// 
  /// This extension method can be called after any operation that might
  /// result in a level-up to automatically trigger the appropriate celebration.
  /// 
  /// Usage:
  /// ```dart
  /// // After adding EXP or completing an activity
  /// final celebrationData = userProvider.checkAndTriggerLevelUpCelebration(
  ///   context: context,
  ///   onCelebrationTriggered: (data) {
  ///     // Handle celebration start
  ///     setState(() { showCelebration = true; });
  ///   },
  /// );
  /// ```
  LevelUpCelebrationData? checkAndTriggerLevelUpCelebration({
    required BuildContext context,
    required Function(LevelUpCelebrationData) onCelebrationTriggered,
    dynamic previousUserState,
  }) {
    if (previousUserState == null || currentUser == null) {
      return null;
    }

    final helper = LevelUpIntegrationHelper();
    final celebrationData = helper.checkForLevelUp(
      oldUser: previousUserState,
      newUser: currentUser!,
    );

    if (celebrationData != null) {
      onCelebrationTriggered(celebrationData);
    }

    return celebrationData;
  }
}

/// Widget mixin for easy level-up celebration integration
/// 
/// Mix this into your StatefulWidget's State class to get convenient
/// methods for handling level-up celebrations.
/// 
/// Usage:
/// ```dart
/// class _MyWidgetState extends State<MyWidget> with LevelUpCelebrationMixin {
///   @override
///   Widget build(BuildContext context) {
///     return buildWithLevelUpOverlay(
///       child: Scaffold(
///         body: YourContent(),
///       ),
///     );
///   }
/// 
///   void onUserChanged(User oldUser, User newUser) {
///     checkForLevelUpCelebration(oldUser, newUser);
///   }
/// }
/// ```
mixin LevelUpCelebrationMixin<T extends StatefulWidget> on State<T> {
  final LevelUpIntegrationHelper _levelUpHelper = LevelUpIntegrationHelper();
  bool _showCelebration = false;
  LevelUpCelebrationData? _celebrationData;

  /// Build your widget wrapped with the level-up overlay
  Widget buildWithLevelUpOverlay({required Widget child}) {
    return LevelUpOverlay(
      showCelebration: _showCelebration,
      newLevel: _celebrationData?.newLevel,
      previousLevel: _celebrationData?.previousLevel,
      statIncreases: _celebrationData?.statIncreases,
      isFirstLevelUp: _celebrationData?.isFirstLevelUp ?? false,
      onAnimationComplete: _onCelebrationComplete,
      onSoundEffect: _onSoundEffect,
      child: child,
    );
  }

  /// Check for level-up and trigger celebration if needed
  void checkForLevelUpCelebration(dynamic oldUser, dynamic newUser) {
    final celebrationData = _levelUpHelper.checkForLevelUp(
      oldUser: oldUser,
      newUser: newUser,
    );

    if (celebrationData != null) {
      setState(() {
        _showCelebration = true;
        _celebrationData = celebrationData;
      });
    }
  }

  /// Override this method to customize sound effects
  void _onSoundEffect() {
    if (_celebrationData != null) {
      _levelUpHelper.playLevelUpSound(_celebrationData!.celebrationType);
    }
  }

  /// Override this method to customize celebration completion behavior
  void _onCelebrationComplete() {
    setState(() {
      _showCelebration = false;
      _celebrationData = null;
    });
    
    // Optional: Trigger any post-celebration effects
    onCelebrationCompleted(_celebrationData);
  }

  /// Override this method to handle post-celebration logic
  void onCelebrationCompleted(LevelUpCelebrationData? data) {
    // Default: do nothing
    // Override in your widget to add custom behavior
  }
}