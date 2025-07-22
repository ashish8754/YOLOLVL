import '../models/user.dart';
import '../models/enums.dart';
import '../models/onboarding.dart';
import '../repositories/user_repository.dart';
import 'exp_service.dart';
import 'onboarding_service.dart';

/// Service for managing user profile, progression, and app initialization
class UserService {
  final UserRepository _userRepository;

  UserService(this._userRepository);

  /// Initialize the app and get or create the current user
  Future<AppInitializationResult> initializeApp() async {
    try {
      final existingUser = _userRepository.getCurrentUser();
      
      if (existingUser != null) {
        // User exists, check if onboarding is complete
        if (existingUser.hasCompletedOnboarding) {
          return AppInitializationResult(
            user: existingUser,
            needsOnboarding: false,
            isFirstTime: false,
          );
        } else {
          // User exists but hasn't completed onboarding
          return AppInitializationResult(
            user: existingUser,
            needsOnboarding: true,
            isFirstTime: false,
          );
        }
      } else {
        // No user exists, create new user
        final newUser = await createNewUser();
        return AppInitializationResult(
          user: newUser,
          needsOnboarding: true,
          isFirstTime: true,
        );
      }
    } catch (e) {
      throw UserServiceException('Failed to initialize app: $e');
    }
  }

  /// Create a new user with default values
  Future<User> createNewUser({String? name, String? avatarPath}) async {
    try {
      final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      final userName = name ?? 'Player';
      
      final user = await _userRepository.createUser(
        id: userId,
        name: userName,
        avatarPath: avatarPath,
      );
      
      return user;
    } catch (e) {
      throw UserServiceException('Failed to create new user: $e');
    }
  }

  /// Get the current user
  User? getCurrentUser() {
    try {
      return _userRepository.getCurrentUser();
    } catch (e) {
      throw UserServiceException('Failed to get current user: $e');
    }
  }

  /// Update user profile information
  Future<User> updateUserProfile({
    required String userId,
    String? name,
    String? avatarPath,
  }) async {
    try {
      final user = _userRepository.findByKey(userId);
      if (user == null) {
        throw UserServiceException('User not found');
      }

      // Update the existing user object directly
      if (name != null) {
        user.name = name;
      }
      if (avatarPath != null) {
        user.avatarPath = avatarPath;
      }

      await _userRepository.updateUser(user);
      return user;
    } catch (e) {
      throw UserServiceException('Failed to update user profile: $e');
    }
  }

  /// Complete onboarding with questionnaire answers
  Future<User> completeOnboarding({
    required String userId,
    OnboardingAnswers? answers,
  }) async {
    try {
      final user = _userRepository.findByKey(userId);
      if (user == null) {
        throw UserServiceException('User not found');
      }

      // Calculate initial stats from answers or use defaults
      Map<StatType, double> initialStats;
      if (answers != null && OnboardingService.areRequiredQuestionsAnswered(answers)) {
        initialStats = OnboardingService.calculateInitialStats(answers);
      } else {
        initialStats = OnboardingService.getDefaultStats();
      }

      // Complete onboarding in repository
      await _userRepository.completeOnboarding(userId, initialStats);
      
      // Return updated user
      final updatedUser = _userRepository.findByKey(userId);
      if (updatedUser == null) {
        throw UserServiceException('Failed to retrieve updated user after onboarding');
      }

      return updatedUser;
    } catch (e) {
      throw UserServiceException('Failed to complete onboarding: $e');
    }
  }

  /// Skip onboarding and use default stats
  Future<User> skipOnboarding(String userId) async {
    try {
      return await completeOnboarding(userId: userId, answers: null);
    } catch (e) {
      throw UserServiceException('Failed to skip onboarding: $e');
    }
  }

  /// Add EXP to user and handle level progression
  Future<LevelProgressionResult> addEXP({
    required String userId,
    required double expToAdd,
  }) async {
    try {
      if (expToAdd < 0) {
        throw ArgumentError('EXP to add must be non-negative');
      }

      final user = _userRepository.findByKey(userId);
      if (user == null) {
        throw UserServiceException('User not found');
      }

      // Calculate level progression
      final levelUpResult = EXPService.checkLevelUp(user.copyWith(
        currentEXP: user.currentEXP + expToAdd,
      ));

      // Apply the EXP and level changes
      final leveledUp = await _userRepository.addEXP(userId, expToAdd);
      
      // Get updated user
      final updatedUser = _userRepository.findByKey(userId);
      if (updatedUser == null) {
        throw UserServiceException('Failed to retrieve updated user after EXP addition');
      }

      return LevelProgressionResult(
        user: updatedUser,
        expGained: expToAdd,
        leveledUp: leveledUp,
        levelsGained: levelUpResult.levelsGained,
        previousLevel: user.level,
      );
    } catch (e) {
      throw UserServiceException('Failed to add EXP: $e');
    }
  }

  /// Update user stats
  Future<User> updateStats({
    required String userId,
    required Map<StatType, double> statUpdates,
  }) async {
    try {
      await _userRepository.updateUserStats(userId, statUpdates);
      
      final updatedUser = _userRepository.findByKey(userId);
      if (updatedUser == null) {
        throw UserServiceException('Failed to retrieve updated user after stat update');
      }

      return updatedUser;
    } catch (e) {
      throw UserServiceException('Failed to update stats: $e');
    }
  }

  /// Get user's current level progression info
  UserLevelInfo getUserLevelInfo(String userId) {
    try {
      final user = _userRepository.findByKey(userId);
      if (user == null) {
        throw UserServiceException('User not found');
      }

      final currentThreshold = EXPService.calculateEXPThreshold(user.level);
      final nextThreshold = EXPService.calculateEXPThreshold(user.level + 1);
      final progress = EXPService.calculateEXPProgress(user);
      final expNeeded = EXPService.getEXPNeededForNextLevel(user);

      return UserLevelInfo(
        currentLevel: user.level,
        currentEXP: user.currentEXP,
        currentLevelThreshold: currentThreshold,
        nextLevelThreshold: nextThreshold,
        progressPercentage: progress,
        expNeededForNextLevel: expNeeded,
      );
    } catch (e) {
      throw UserServiceException('Failed to get user level info: $e');
    }
  }

  /// Reset user progress (for testing or user request)
  Future<User> resetUserProgress(String userId) async {
    try {
      await _userRepository.resetUserProgress(userId);
      
      final resetUser = _userRepository.findByKey(userId);
      if (resetUser == null) {
        throw UserServiceException('Failed to retrieve user after reset');
      }

      return resetUser;
    } catch (e) {
      throw UserServiceException('Failed to reset user progress: $e');
    }
  }

  /// Check if user needs tutorial
  bool needsTutorial(String userId) {
    try {
      final user = _userRepository.findByKey(userId);
      if (user == null) return true;
      
      // User needs tutorial if they just completed onboarding
      // or if they're a new user
      return !user.hasCompletedOnboarding || 
             DateTime.now().difference(user.createdAt).inDays < 1;
    } catch (e) {
      return true; // Default to showing tutorial on error
    }
  }

  /// Get user statistics summary
  UserStatsSummary getUserStatsSummary(String userId) {
    try {
      final user = _userRepository.findByKey(userId);
      if (user == null) {
        throw UserServiceException('User not found');
      }

      // Calculate total stat points
      double totalStats = 0;
      final Map<StatType, double> currentStats = {};

      for (final statType in StatType.values) {
        final statValue = user.getStat(statType);
        currentStats[statType] = statValue;
        totalStats += statValue;
      }

      // Calculate days since creation
      final daysSinceCreation = DateTime.now().difference(user.createdAt).inDays;
      
      return UserStatsSummary(
        totalStatPoints: totalStats,
        averageStatValue: totalStats / StatType.values.length,
        highestStat: currentStats.entries
            .reduce((a, b) => a.value > b.value ? a : b),
        lowestStat: currentStats.entries
            .reduce((a, b) => a.value < b.value ? a : b),
        daysSinceCreation: daysSinceCreation,
        overallProgress: totalStats / (StatType.values.length * 6.0), // Use 6.0 as baseline for progress calculation
      );
    } catch (e) {
      throw UserServiceException('Failed to get user stats summary: $e');
    }
  }

  /// Apply stat reversals for activity deletion
  /// This method handles the reversal of stat gains and EXP when an activity is deleted
  Future<User> applyStatReversals({
    required String userId,
    required Map<StatType, double> statReversals,
    required double expToReverse,
  }) async {
    try {
      final user = _userRepository.findByKey(userId);
      if (user == null) {
        throw UserServiceException('User not found');
      }

      // Apply stat reversals with floor constraint of 1.0
      for (final entry in statReversals.entries) {
        final currentValue = user.getStat(entry.key);
        final newValue = (currentValue - entry.value).clamp(1.0, double.infinity);
        user.setStat(entry.key, newValue);
      }

      // Handle EXP reversal and potential level-down
      final levelDownResult = EXPService.handleEXPReversal(user, expToReverse);
      
      // Update user with new level and EXP
      user.level = levelDownResult.level;
      user.currentEXP = levelDownResult.currentEXP;

      // Save updated user
      await _userRepository.updateUser(user);
      
      return user;
    } catch (e) {
      throw UserServiceException('Failed to apply stat reversals: $e');
    }
  }

  /// Handle level-down scenarios when EXP is reversed
  /// This method specifically handles the complex logic of level reduction
  Future<LevelDownResult> handleLevelDown({
    required String userId,
    required double expToReverse,
  }) async {
    try {
      final user = _userRepository.findByKey(userId);
      if (user == null) {
        throw UserServiceException('User not found');
      }

      final previousLevel = user.level;
      final previousEXP = user.currentEXP;

      // Calculate level-down using EXP service
      final levelDownResult = EXPService.handleEXPReversal(user, expToReverse);
      
      // Update user with new values
      user.level = levelDownResult.level;
      user.currentEXP = levelDownResult.currentEXP;

      // Save updated user
      await _userRepository.updateUser(user);

      final levelsLost = previousLevel - user.level;

      return LevelDownResult.success(
        user: user,
        previousLevel: previousLevel,
        newLevel: user.level,
        levelsLost: levelsLost,
        previousEXP: previousEXP,
        newEXP: user.currentEXP,
        expReversed: expToReverse,
      );
    } catch (e) {
      throw UserServiceException('Failed to handle level-down: $e');
    }
  }
}

/// Result of app initialization
class AppInitializationResult {
  final User user;
  final bool needsOnboarding;
  final bool isFirstTime;

  const AppInitializationResult({
    required this.user,
    required this.needsOnboarding,
    required this.isFirstTime,
  });

  @override
  String toString() {
    return 'AppInitializationResult(user: ${user.id}, needsOnboarding: $needsOnboarding, isFirstTime: $isFirstTime)';
  }
}

/// Result of level progression
class LevelProgressionResult {
  final User user;
  final double expGained;
  final bool leveledUp;
  final int levelsGained;
  final int previousLevel;

  const LevelProgressionResult({
    required this.user,
    required this.expGained,
    required this.leveledUp,
    required this.levelsGained,
    required this.previousLevel,
  });

  @override
  String toString() {
    return 'LevelProgressionResult(leveledUp: $leveledUp, levelsGained: $levelsGained, expGained: $expGained)';
  }
}

/// User level information
class UserLevelInfo {
  final int currentLevel;
  final double currentEXP;
  final double currentLevelThreshold;
  final double nextLevelThreshold;
  final double progressPercentage;
  final double expNeededForNextLevel;

  const UserLevelInfo({
    required this.currentLevel,
    required this.currentEXP,
    required this.currentLevelThreshold,
    required this.nextLevelThreshold,
    required this.progressPercentage,
    required this.expNeededForNextLevel,
  });

  @override
  String toString() {
    return 'UserLevelInfo(level: $currentLevel, exp: $currentEXP, progress: ${(progressPercentage * 100).toStringAsFixed(1)}%)';
  }
}

/// User statistics summary
class UserStatsSummary {
  final double totalStatPoints;
  final double averageStatValue;
  final MapEntry<StatType, double> highestStat;
  final MapEntry<StatType, double> lowestStat;
  final int daysSinceCreation;
  final double overallProgress;

  const UserStatsSummary({
    required this.totalStatPoints,
    required this.averageStatValue,
    required this.highestStat,
    required this.lowestStat,
    required this.daysSinceCreation,
    required this.overallProgress,
  });

  @override
  String toString() {
    return 'UserStatsSummary(totalStats: $totalStatPoints, avgStat: ${averageStatValue.toStringAsFixed(2)}, days: $daysSinceCreation)';
  }
}

/// Result of level-down operation
class LevelDownResult {
  final bool success;
  final String? errorMessage;
  final User user;
  final int previousLevel;
  final int newLevel;
  final int levelsLost;
  final double previousEXP;
  final double newEXP;
  final double expReversed;

  const LevelDownResult._({
    required this.success,
    this.errorMessage,
    required this.user,
    required this.previousLevel,
    required this.newLevel,
    required this.levelsLost,
    required this.previousEXP,
    required this.newEXP,
    required this.expReversed,
  });

  factory LevelDownResult.success({
    required User user,
    required int previousLevel,
    required int newLevel,
    required int levelsLost,
    required double previousEXP,
    required double newEXP,
    required double expReversed,
  }) {
    return LevelDownResult._(
      success: true,
      user: user,
      previousLevel: previousLevel,
      newLevel: newLevel,
      levelsLost: levelsLost,
      previousEXP: previousEXP,
      newEXP: newEXP,
      expReversed: expReversed,
    );
  }

  factory LevelDownResult.error(String errorMessage) {
    // Create a dummy user for error case
    final dummyUser = User.create(id: '', name: '');
    return LevelDownResult._(
      success: false,
      errorMessage: errorMessage,
      user: dummyUser,
      previousLevel: 0,
      newLevel: 0,
      levelsLost: 0,
      previousEXP: 0.0,
      newEXP: 0.0,
      expReversed: 0.0,
    );
  }

  @override
  String toString() {
    if (success) {
      return 'LevelDownResult(success: true, previousLevel: $previousLevel, newLevel: $newLevel, levelsLost: $levelsLost)';
    } else {
      return 'LevelDownResult(success: false, error: $errorMessage)';
    }
  }
}

/// Custom exception for UserService operations
class UserServiceException implements Exception {
  final String message;
  
  UserServiceException(this.message);
  
  @override
  String toString() => 'UserServiceException: $message';
}