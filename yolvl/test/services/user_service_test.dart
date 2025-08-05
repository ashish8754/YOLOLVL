import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import '../../lib/services/user_service.dart';
import '../../lib/repositories/user_repository.dart';
import '../../lib/models/user.dart';
import '../../lib/models/enums.dart';
import '../../lib/models/onboarding.dart';
import '../../lib/services/onboarding_service.dart';

void main() {
  group('UserService', () {
    late UserService userService;
    late UserRepository userRepository;

    setUp(() async {
      await setUpTestHive();
      
      // Register adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(ActivityTypeAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(StatTypeAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(UserAdapter());
      }

      // Open test box with correct name
      await Hive.openBox<User>('user_box');
      
      userRepository = UserRepository();
      userService = UserService(userRepository);
    });

    tearDown(() async {
      await tearDownTestHive();
    });

    group('App Initialization', () {
      test('should create new user on first app launch', () async {
        final result = await userService.initializeApp();
        
        expect(result.isFirstTime, isTrue);
        expect(result.needsOnboarding, isTrue);
        expect(result.user.level, equals(1));
        expect(result.user.currentEXP, equals(0.0));
        expect(result.user.hasCompletedOnboarding, isFalse);
      });

      test('should return existing user with completed onboarding', () async {
        // Create and complete onboarding for a user
        final user = await userService.createNewUser(name: 'Test User');
        await userService.completeOnboarding(userId: user.id);
        
        final result = await userService.initializeApp();
        
        expect(result.isFirstTime, isFalse);
        expect(result.needsOnboarding, isFalse);
        expect(result.user.hasCompletedOnboarding, isTrue);
        expect(result.user.name, equals('Test User'));
      });

      test('should return existing user needing onboarding', () async {
        // Create user but don't complete onboarding
        await userService.createNewUser(name: 'Incomplete User');
        
        final result = await userService.initializeApp();
        
        expect(result.isFirstTime, isFalse);
        expect(result.needsOnboarding, isTrue);
        expect(result.user.hasCompletedOnboarding, isFalse);
      });
    });

    group('User Creation', () {
      test('should create new user with default values', () async {
        final user = await userService.createNewUser();
        
        expect(user.name, equals('Player'));
        expect(user.level, equals(1));
        expect(user.currentEXP, equals(0.0));
        expect(user.hasCompletedOnboarding, isFalse);
        expect(user.getStat(StatType.strength), equals(1.0));
      });

      test('should create new user with custom name', () async {
        final user = await userService.createNewUser(name: 'Custom Player');
        
        expect(user.name, equals('Custom Player'));
        expect(user.id.isNotEmpty, isTrue);
      });
    });

    group('Profile Management', () {
      test('should update user profile', () async {
        final user = await userService.createNewUser(name: 'Original Name');
        
        final updatedUser = await userService.updateUserProfile(
          userId: user.id,
          name: 'Updated Name',
          avatarPath: '/path/to/avatar.png',
        );
        
        expect(updatedUser.name, equals('Updated Name'));
        expect(updatedUser.avatarPath, equals('/path/to/avatar.png'));
      });

      test('should throw exception when updating non-existent user', () async {
        expect(
          () => userService.updateUserProfile(
            userId: 'non_existent',
            name: 'New Name',
          ),
          throwsA(isA<UserServiceException>()),
        );
      });
    });

    group('Onboarding', () {
      test('should complete onboarding with questionnaire answers', () async {
        final user = await userService.createNewUser();
        
        final answers = OnboardingAnswers();
        answers.setAnswer('physical_strength', 8);
        answers.setAnswer('workout_frequency', 5);
        answers.setAnswer('agility_flexibility', 6);
        answers.setAnswer('study_hours', 20);
        answers.setAnswer('mental_focus', 7);
        answers.setAnswer('habit_resistance', 9);
        answers.setAnswer('social_charisma', 4);
        
        final completedUser = await userService.completeOnboarding(
          userId: user.id,
          answers: answers,
        );
        
        expect(completedUser.hasCompletedOnboarding, isTrue);
        expect(completedUser.getStat(StatType.strength), greaterThan(1.0));
        expect(completedUser.getStat(StatType.charisma), greaterThan(1.0));
      });

      test('should complete onboarding with default stats when skipping', () async {
        final user = await userService.createNewUser();
        
        final completedUser = await userService.skipOnboarding(user.id);
        
        expect(completedUser.hasCompletedOnboarding, isTrue);
        expect(completedUser.getStat(StatType.strength), equals(1.0));
        expect(completedUser.getStat(StatType.agility), equals(1.0));
        expect(completedUser.getStat(StatType.endurance), equals(1.0));
        expect(completedUser.getStat(StatType.intelligence), equals(1.0));
        expect(completedUser.getStat(StatType.focus), equals(1.0));
        expect(completedUser.getStat(StatType.charisma), equals(1.0));
      });

      test('should use default stats for incomplete answers', () async {
        final user = await userService.createNewUser();
        
        final answers = OnboardingAnswers();
        answers.setAnswer('physical_strength', 5); // Only partial answers
        
        final completedUser = await userService.completeOnboarding(
          userId: user.id,
          answers: answers,
        );
        
        expect(completedUser.hasCompletedOnboarding, isTrue);
        // Should use default stats since answers are incomplete
        expect(completedUser.getStat(StatType.strength), equals(1.0));
      });
    });

    group('EXP and Level Progression', () {
      test('should add EXP without leveling up', () async {
        final user = await userService.createNewUser();
        await userService.completeOnboarding(userId: user.id);
        
        final result = await userService.addEXP(
          userId: user.id,
          expToAdd: 500.0,
        );
        
        expect(result.expGained, equals(500.0));
        expect(result.leveledUp, isFalse);
        expect(result.levelsGained, equals(0));
        expect(result.user.currentEXP, equals(500.0));
        expect(result.user.level, equals(1));
      });

      test('should add EXP and level up', () async {
        final user = await userService.createNewUser();
        await userService.completeOnboarding(userId: user.id);
        
        final result = await userService.addEXP(
          userId: user.id,
          expToAdd: 1200.0, // More than level 1 threshold (1000)
        );
        
        expect(result.expGained, equals(1200.0));
        expect(result.leveledUp, isTrue);
        expect(result.levelsGained, equals(1));
        expect(result.user.level, equals(2));
        expect(result.user.currentEXP, equals(200.0)); // Excess EXP
      });

      test('should handle multiple level ups', () async {
        final user = await userService.createNewUser();
        await userService.completeOnboarding(userId: user.id);
        
        final result = await userService.addEXP(
          userId: user.id,
          expToAdd: 3000.0, // Enough for multiple levels
        );
        
        expect(result.leveledUp, isTrue);
        expect(result.levelsGained, greaterThan(1));
        expect(result.user.level, greaterThan(2));
      });

      test('should throw exception for negative EXP', () async {
        final user = await userService.createNewUser();
        
        expect(
          () => userService.addEXP(userId: user.id, expToAdd: -100.0),
          throwsA(isA<UserServiceException>()),
        );
      });
    });

    group('Stats Management', () {
      test('should update user stats', () async {
        final user = await userService.createNewUser();
        await userService.completeOnboarding(userId: user.id);
        
        final statUpdates = {
          StatType.strength: 0.5,
          StatType.agility: 0.3,
        };
        
        final updatedUser = await userService.updateStats(
          userId: user.id,
          statUpdates: statUpdates,
        );
        
        expect(updatedUser.getStat(StatType.strength), equals(1.5));
        expect(updatedUser.getStat(StatType.agility), equals(1.3));
        expect(updatedUser.getStat(StatType.endurance), equals(1.0)); // Unchanged
      });
    });

    group('Level Information', () {
      test('should get user level info', () async {
        final user = await userService.createNewUser();
        await userService.completeOnboarding(userId: user.id);
        await userService.addEXP(userId: user.id, expToAdd: 500.0);
        
        final levelInfo = userService.getUserLevelInfo(user.id);
        
        expect(levelInfo.currentLevel, equals(1));
        expect(levelInfo.currentEXP, equals(500.0));
        expect(levelInfo.currentLevelThreshold, equals(1000.0));
        expect(levelInfo.progressPercentage, equals(0.5));
        expect(levelInfo.expNeededForNextLevel, equals(500.0));
      });
    });

    group('User Statistics', () {
      test('should get user stats summary', () async {
        final user = await userService.createNewUser();
        
        // Complete onboarding with some stats
        final answers = OnboardingAnswers();
        answers.setAnswer('physical_strength', 10);
        answers.setAnswer('workout_frequency', 7);
        answers.setAnswer('agility_flexibility', 8);
        answers.setAnswer('study_hours', 30);
        answers.setAnswer('mental_focus', 9);
        answers.setAnswer('habit_resistance', 8);
        answers.setAnswer('social_charisma', 6);
        
        await userService.completeOnboarding(userId: user.id, answers: answers);
        
        final summary = userService.getUserStatsSummary(user.id);
        
        expect(summary.totalStatPoints, greaterThan(6.0)); // More than default
        expect(summary.averageStatValue, greaterThan(1.0));
        expect(summary.daysSinceCreation, equals(0)); // Created today
        expect(summary.overallProgress, greaterThan(0.2)); // Some progress
        expect(summary.highestStat.key, isA<StatType>());
        expect(summary.lowestStat.key, isA<StatType>());
      });
    });

    group('Tutorial and Reset', () {
      test('should detect if user needs tutorial', () async {
        final user = await userService.createNewUser();
        
        // New user should need tutorial
        expect(userService.needsTutorial(user.id), isTrue);
        
        // After completing onboarding, still needs tutorial (new user)
        await userService.completeOnboarding(userId: user.id);
        expect(userService.needsTutorial(user.id), isTrue);
      });

      test('should reset user progress', () async {
        final user = await userService.createNewUser();
        await userService.completeOnboarding(userId: user.id);
        await userService.addEXP(userId: user.id, expToAdd: 1500.0);
        await userService.updateStats(
          userId: user.id,
          statUpdates: {StatType.strength: 2.0},
        );
        
        final resetUser = await userService.resetUserProgress(user.id);
        
        expect(resetUser.level, equals(1));
        expect(resetUser.currentEXP, equals(0.0));
        expect(resetUser.getStat(StatType.strength), equals(1.0));
      });
    });

    group('Error Handling', () {
      test('should throw exception for non-existent user operations', () async {
        expect(
          () => userService.addEXP(userId: 'non_existent', expToAdd: 100.0),
          throwsA(isA<UserServiceException>()),
        );
        
        expect(
          () => userService.updateStats(
            userId: 'non_existent',
            statUpdates: {StatType.strength: 1.0},
          ),
          throwsA(isA<UserServiceException>()),
        );
        
        expect(
          () => userService.getUserLevelInfo('non_existent'),
          throwsA(isA<UserServiceException>()),
        );
      });
    });

    group('Static Methods and Logic', () {
      test('should create AppInitializationResult correctly', () {
        final user = User.create(id: 'test', name: 'Test User');
        
        final result = AppInitializationResult(
          user: user,
          needsOnboarding: true,
          isFirstTime: true,
        );
        
        expect(result.user.id, equals('test'));
        expect(result.needsOnboarding, isTrue);
        expect(result.isFirstTime, isTrue);
      });

      test('should create LevelProgressionResult correctly', () {
        final user = User.create(id: 'test', name: 'Test User');
        
        final result = LevelProgressionResult(
          user: user,
          expGained: 100.0,
          leveledUp: true,
          levelsGained: 1,
          previousLevel: 1,
        );
        
        expect(result.expGained, equals(100.0));
        expect(result.leveledUp, isTrue);
        expect(result.levelsGained, equals(1));
        expect(result.previousLevel, equals(1));
      });

      test('should create UserLevelInfo correctly', () {
        final levelInfo = UserLevelInfo(
          currentLevel: 2,
          currentEXP: 500.0,
          currentLevelThreshold: 1000.0,
          nextLevelThreshold: 1200.0,
          progressPercentage: 0.5,
          expNeededForNextLevel: 500.0,
        );
        
        expect(levelInfo.currentLevel, equals(2));
        expect(levelInfo.currentEXP, equals(500.0));
        expect(levelInfo.progressPercentage, equals(0.5));
        expect(levelInfo.expNeededForNextLevel, equals(500.0));
      });

      test('should create UserStatsSummary correctly', () {
        final highestStat = MapEntry(StatType.strength, 3.5);
        final lowestStat = MapEntry(StatType.agility, 1.2);
        
        final summary = UserStatsSummary(
          totalStatPoints: 12.5,
          averageStatValue: 2.08,
          highestStat: highestStat,
          lowestStat: lowestStat,
          daysSinceCreation: 5,
          overallProgress: 0.42,
        );
        
        expect(summary.totalStatPoints, equals(12.5));
        expect(summary.averageStatValue, closeTo(2.08, 0.01));
        expect(summary.highestStat.key, equals(StatType.strength));
        expect(summary.lowestStat.key, equals(StatType.agility));
        expect(summary.daysSinceCreation, equals(5));
        expect(summary.overallProgress, closeTo(0.42, 0.01));
      });
    });

    group('UserServiceException', () {
      test('should create exception with message', () {
        final exception = UserServiceException('Test error message');
        
        expect(exception.message, equals('Test error message'));
        expect(exception.toString(), equals('UserServiceException: Test error message'));
      });
    });

    group('Integration with OnboardingService', () {
      test('should integrate with onboarding service for stat calculation', () {
        // Test that UserService would use OnboardingService correctly
        final answers = OnboardingAnswers();
        answers.setAnswer('physical_strength', 8);
        answers.setAnswer('workout_frequency', 5);
        answers.setAnswer('agility_flexibility', 6);
        answers.setAnswer('study_hours', 20);
        answers.setAnswer('mental_focus', 7);
        answers.setAnswer('habit_resistance', 9);
        answers.setAnswer('social_charisma', 4);
        
        // Verify that required questions are answered
        expect(OnboardingService.areRequiredQuestionsAnswered(answers), isTrue);
        
        // Verify that stats can be calculated
        final stats = OnboardingService.calculateInitialStats(answers);
        expect(stats.length, equals(6));
        expect(stats[StatType.strength], greaterThan(1.0));
        expect(stats[StatType.charisma], greaterThan(1.0));
      });

      test('should handle incomplete onboarding answers', () {
        final answers = OnboardingAnswers();
        answers.setAnswer('physical_strength', 5); // Only partial answers
        
        // Should not be considered complete
        expect(OnboardingService.areRequiredQuestionsAnswered(answers), isFalse);
        
        // Should still be able to calculate stats (will use defaults)
        final stats = OnboardingService.calculateInitialStats(answers);
        expect(stats.length, equals(6));
        
        // Should be able to get default stats
        final defaultStats = OnboardingService.getDefaultStats();
        expect(defaultStats.length, equals(6));
        expect(defaultStats[StatType.strength], equals(1.0));
      });
    });

    group('User Model Integration', () {
      test('should work with User model stat operations', () {
        final user = User.create(id: 'test', name: 'Test User');
        
        // Test initial stats
        expect(user.getStat(StatType.strength), equals(1.0));
        expect(user.getStat(StatType.agility), equals(1.0));
        
        // Test stat updates
        user.setStat(StatType.strength, 2.5);
        expect(user.getStat(StatType.strength), equals(2.5));
        
        // Test stat additions
        user.addToStat(StatType.strength, 0.5);
        expect(user.getStat(StatType.strength), equals(3.0));
        
        // Test EXP and leveling
        expect(user.level, equals(1));
        expect(user.currentEXP, equals(0.0));
        expect(user.canLevelUp, isFalse);
        
        // Add EXP to trigger level up
        user.currentEXP = 1200.0; // More than threshold (1000 for level 1)
        expect(user.canLevelUp, isTrue);
        
        final excess = user.levelUp();
        expect(user.level, equals(2));
        expect(excess, equals(200.0)); // 1200 - 1000 = 200
      });

      test('should handle onboarding completion flag', () {
        final user = User.create(id: 'test', name: 'Test User');
        
        expect(user.hasCompletedOnboarding, isFalse);
        
        // Simulate completing onboarding
        user.hasCompletedOnboarding = true;
        expect(user.hasCompletedOnboarding, isTrue);
      });

      test('should handle activity date tracking', () {
        final user = User.create(id: 'test', name: 'Test User');
        final now = DateTime.now();
        
        // Initially no activity dates
        expect(user.getLastActivityDate(ActivityType.workoutUpperBody), isNull);
        
        // Set activity date
        user.setLastActivityDate(ActivityType.workoutUpperBody, now);
        expect(user.getLastActivityDate(ActivityType.workoutUpperBody), equals(now));
      });
    });

    group('Error Handling Scenarios', () {
      test('should handle invalid stat types gracefully', () {
        final user = User.create(id: 'test', name: 'Test User');
        
        // Getting non-existent stat should return default
        expect(user.getStat(StatType.strength), equals(1.0));
        
        // Setting stat should work
        user.setStat(StatType.strength, 2.0);
        expect(user.getStat(StatType.strength), equals(2.0));
      });

      test('should handle edge cases in level calculations', () {
        final user = User.create(id: 'test', name: 'Test User');
        
        // Test exact threshold
        user.currentEXP = 1000.0; // Exactly at threshold
        expect(user.canLevelUp, isTrue);
        
        final excess = user.levelUp();
        expect(user.level, equals(2));
        expect(user.currentEXP, equals(0.0)); // Should be 0 after level up
      });
    });

    group('Data Validation', () {
      test('should validate user creation parameters', () {
        // Test with valid parameters
        final user1 = User.create(id: 'valid_id', name: 'Valid Name');
        expect(user1.id, equals('valid_id'));
        expect(user1.name, equals('Valid Name'));
        
        // Test with empty name (should still work, validation is in repository)
        final user2 = User.create(id: 'test', name: '');
        expect(user2.name, equals(''));
      });

      test('should handle stat boundary conditions', () {
        final user = User.create(id: 'test', name: 'Test User');
        
        // Test setting very high stats
        user.setStat(StatType.strength, 100.0);
        expect(user.getStat(StatType.strength), equals(100.0));
        
        // Test setting very low stats
        user.setStat(StatType.strength, 0.1);
        expect(user.getStat(StatType.strength), equals(0.1));
        
        // Test negative stats
        user.setStat(StatType.strength, -1.0);
        expect(user.getStat(StatType.strength), equals(-1.0));
      });
    });
  });
}