import '../models/user.dart';
import '../models/enums.dart';
import '../utils/hive_config.dart';
import 'base_repository.dart';

/// Repository for User data operations
class UserRepository extends BaseRepository<User> {
  UserRepository() : super(HiveConfig.userBoxName);

  /// Get the current user (assuming single user for now)
  User? getCurrentUser() {
    try {
      final users = findAll();
      return users.isNotEmpty ? users.first : null;
    } catch (e) {
      throw RepositoryException('Failed to get current user: $e');
    }
  }

  /// Create and save a new user
  Future<User> createUser({
    required String id,
    required String name,
    String? avatarPath,
  }) async {
    try {
      // Check if user already exists
      if (existsByKey(id)) {
        throw RepositoryException('User with id $id already exists');
      }

      final user = User.create(
        id: id,
        name: name,
        avatarPath: avatarPath,
      );

      await box.put(id, user);
      return user;
    } catch (e) {
      throw RepositoryException('Failed to create user: $e');
    }
  }

  /// Update user profile
  Future<void> updateUser(User user) async {
    try {
      user.updateLastActive();
      await save(user);
    } catch (e) {
      throw RepositoryException('Failed to update user: $e');
    }
  }

  /// Update user stats
  Future<void> updateUserStats(String userId, Map<StatType, double> statUpdates) async {
    try {
      final user = findByKey(userId);
      if (user == null) {
        throw RepositoryException('User with id $userId not found');
      }

      for (final entry in statUpdates.entries) {
        user.addToStat(entry.key, entry.value);
      }

      user.updateLastActive();
      await save(user);
    } catch (e) {
      throw RepositoryException('Failed to update user stats: $e');
    }
  }

  /// Add EXP to user and handle level ups
  Future<bool> addEXP(String userId, double exp) async {
    try {
      final user = findByKey(userId);
      if (user == null) {
        throw RepositoryException('User with id $userId not found');
      }

      user.currentEXP += exp;
      bool leveledUp = false;

      // Handle multiple level ups
      while (user.canLevelUp) {
        user.levelUp();
        leveledUp = true;
      }

      user.updateLastActive();
      await save(user);
      
      return leveledUp;
    } catch (e) {
      throw RepositoryException('Failed to add EXP: $e');
    }
  }

  /// Update last activity date for specific activity type
  Future<void> updateLastActivityDate(String userId, ActivityType activityType) async {
    try {
      final user = findByKey(userId);
      if (user == null) {
        throw RepositoryException('User with id $userId not found');
      }

      user.setLastActivityDate(activityType, DateTime.now());
      user.updateLastActive();
      await save(user);
    } catch (e) {
      throw RepositoryException('Failed to update last activity date: $e');
    }
  }

  /// Get user's last activity dates
  Map<ActivityType, DateTime> getLastActivityDates(String userId) {
    try {
      final user = findByKey(userId);
      if (user == null) {
        throw RepositoryException('User with id $userId not found');
      }

      final Map<ActivityType, DateTime> result = {};
      for (final entry in user.lastActivityDates.entries) {
        final activityType = ActivityType.values.firstWhere(
          (type) => type.name == entry.key,
          orElse: () => ActivityType.workoutUpperBody,
        );
        result[activityType] = entry.value;
      }
      return result;
    } catch (e) {
      throw RepositoryException('Failed to get last activity dates: $e');
    }
  }

  /// Complete onboarding for user
  Future<void> completeOnboarding(String userId, Map<StatType, double> initialStats) async {
    try {
      final user = findByKey(userId);
      if (user == null) {
        throw RepositoryException('User with id $userId not found');
      }

      // Update stats with onboarding values
      for (final entry in initialStats.entries) {
        user.setStat(entry.key, entry.value);
      }

      user.hasCompletedOnboarding = true;
      user.updateLastActive();
      await save(user);
    } catch (e) {
      throw RepositoryException('Failed to complete onboarding: $e');
    }
  }

  /// Reset user progress (for testing or user request)
  Future<void> resetUserProgress(String userId) async {
    try {
      final user = findByKey(userId);
      if (user == null) {
        throw RepositoryException('User with id $userId not found');
      }

      // Reset to level 1 with default stats
      user.level = 1;
      user.currentEXP = 0.0;
      user.stats = {
        StatType.strength.name: 1.0,
        StatType.agility.name: 1.0,
        StatType.endurance.name: 1.0,
        StatType.intelligence.name: 1.0,
        StatType.focus.name: 1.0,
        StatType.charisma.name: 1.0,
      };
      user.lastActivityDates.clear();
      user.updateLastActive();
      
      await save(user);
    } catch (e) {
      throw RepositoryException('Failed to reset user progress: $e');
    }
  }

  @override
  bool validateEntity(User entity) {
    // Validate user data
    if (entity.id.isEmpty || entity.name.isEmpty) {
      return false;
    }
    if (entity.level < 1) {
      return false;
    }
    if (entity.currentEXP < 0) {
      return false;
    }
    // Validate stats are not below minimum
    for (final statValue in entity.stats.values) {
      if (statValue < 1.0) {
        return false;
      }
    }
    return true;
  }
}