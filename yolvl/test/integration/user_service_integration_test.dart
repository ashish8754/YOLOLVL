import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import '../../lib/services/user_service.dart';
import '../../lib/repositories/user_repository.dart';
import '../../lib/models/user.dart';
import '../../lib/models/enums.dart';
import '../../lib/models/onboarding.dart';

void main() {
  group('UserService Integration Tests', () {
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

      await Hive.openBox<User>('user_box');
      
      userRepository = UserRepository();
      userService = UserService(userRepository);
    });

    tearDown(() async {
      await tearDownTestHive();
    });

    test('Complete user journey: First launch -> Onboarding -> Progress -> Level up', () async {
      // 1. First app launch - should create new user
      var initResult = await userService.initializeApp();
      expect(initResult.isFirstTime, isTrue);
      expect(initResult.needsOnboarding, isTrue);
      expect(initResult.user.level, equals(1));
      expect(initResult.user.currentEXP, equals(0.0));
      
      final userId = initResult.user.id;
      
      // 2. Complete onboarding with realistic answers
      final answers = OnboardingAnswers();
      answers.setAnswer('physical_strength', 6);  // Moderate fitness
      answers.setAnswer('workout_frequency', 3);  // 3 times per week
      answers.setAnswer('agility_flexibility', 4); // Below average
      answers.setAnswer('study_hours', 15);       // 15 hours per week
      answers.setAnswer('mental_focus', 7);       // Good focus
      answers.setAnswer('habit_resistance', 5);   // Average willpower
      answers.setAnswer('social_charisma', 8);    // Good social skills
      answers.setAnswer('achievements', 'Completed a coding bootcamp');
      
      final onboardedUser = await userService.completeOnboarding(
        userId: userId,
        answers: answers,
      );
      
      expect(onboardedUser.hasCompletedOnboarding, isTrue);
      expect(onboardedUser.getStat(StatType.strength), greaterThan(1.0));
      expect(onboardedUser.getStat(StatType.charisma), greaterThan(3.0)); // Should be high
      expect(onboardedUser.getStat(StatType.intelligence), greaterThan(2.0)); // From study hours
      
      // 3. Second app launch - should return existing user without onboarding
      initResult = await userService.initializeApp();
      expect(initResult.isFirstTime, isFalse);
      expect(initResult.needsOnboarding, isFalse);
      expect(initResult.user.hasCompletedOnboarding, isTrue);
      
      // 4. Simulate some activity and EXP gain
      var progressResult = await userService.addEXP(
        userId: userId,
        expToAdd: 300.0, // Some daily activities
      );
      
      expect(progressResult.leveledUp, isFalse);
      expect(progressResult.user.currentEXP, equals(300.0));
      expect(progressResult.user.level, equals(1));
      
      // 5. Add stats from activities
      await userService.updateStats(
        userId: userId,
        statUpdates: {
          StatType.strength: 0.12, // From 2 hours of workout
          StatType.endurance: 0.08,
          StatType.intelligence: 0.06, // From 1 hour of study
        },
      );
      
      // 6. More EXP to trigger level up
      progressResult = await userService.addEXP(
        userId: userId,
        expToAdd: 800.0, // Total 1100 EXP
      );
      
      expect(progressResult.leveledUp, isTrue);
      expect(progressResult.levelsGained, equals(1));
      expect(progressResult.user.level, equals(2));
      expect(progressResult.user.currentEXP, equals(100.0)); // 1100 - 1000 = 100
      
      // 7. Check level info
      final levelInfo = userService.getUserLevelInfo(userId);
      expect(levelInfo.currentLevel, equals(2));
      expect(levelInfo.currentEXP, equals(100.0));
      expect(levelInfo.progressPercentage, lessThan(0.1)); // Just started level 2
      
      // 8. Get stats summary
      final summary = userService.getUserStatsSummary(userId);
      expect(summary.totalStatPoints, greaterThan(8.0)); // Should have grown
      expect(summary.averageStatValue, greaterThan(1.3));
      expect(summary.daysSinceCreation, equals(0)); // Created today
      
      // 9. Update profile
      final updatedUser = await userService.updateUserProfile(
        userId: userId,
        name: 'Solo Leveler',
        avatarPath: '/avatars/hunter.png',
      );
      
      expect(updatedUser.name, equals('Solo Leveler'));
      expect(updatedUser.avatarPath, equals('/avatars/hunter.png'));
      
      // 10. Verify persistence by reinitializing
      final finalInitResult = await userService.initializeApp();
      expect(finalInitResult.user.name, equals('Solo Leveler'));
      expect(finalInitResult.user.level, equals(2));
      expect(finalInitResult.user.currentEXP, equals(100.0));
      expect(finalInitResult.user.hasCompletedOnboarding, isTrue);
    });

    test('Skip onboarding workflow', () async {
      // 1. First app launch
      final initResult = await userService.initializeApp();
      final userId = initResult.user.id;
      
      // 2. Skip onboarding
      final skippedUser = await userService.skipOnboarding(userId);
      
      expect(skippedUser.hasCompletedOnboarding, isTrue);
      expect(skippedUser.getStat(StatType.strength), equals(1.0));
      expect(skippedUser.getStat(StatType.agility), equals(1.0));
      expect(skippedUser.getStat(StatType.endurance), equals(1.0));
      expect(skippedUser.getStat(StatType.intelligence), equals(1.0));
      expect(skippedUser.getStat(StatType.focus), equals(1.0));
      expect(skippedUser.getStat(StatType.charisma), equals(1.0));
      
      // 3. Should not need onboarding on next launch
      final secondInitResult = await userService.initializeApp();
      expect(secondInitResult.needsOnboarding, isFalse);
    });

    test('Multiple level ups in single EXP addition', () async {
      // Setup user
      final initResult = await userService.initializeApp();
      final userId = initResult.user.id;
      await userService.skipOnboarding(userId);
      
      // Add massive EXP for multiple level ups
      final progressResult = await userService.addEXP(
        userId: userId,
        expToAdd: 5000.0, // Should trigger multiple levels
      );
      
      expect(progressResult.leveledUp, isTrue);
      expect(progressResult.levelsGained, greaterThan(2));
      expect(progressResult.user.level, greaterThan(3));
      
      // Verify level info is correct
      final levelInfo = userService.getUserLevelInfo(userId);
      expect(levelInfo.currentLevel, equals(progressResult.user.level));
      expect(levelInfo.currentEXP, equals(progressResult.user.currentEXP));
    });

    test('Reset user progress workflow', () async {
      // Setup advanced user
      final initResult = await userService.initializeApp();
      final userId = initResult.user.id;
      
      final answers = OnboardingAnswers();
      answers.setAnswer('physical_strength', 10);
      answers.setAnswer('workout_frequency', 7);
      answers.setAnswer('agility_flexibility', 9);
      answers.setAnswer('study_hours', 40);
      answers.setAnswer('mental_focus', 10);
      answers.setAnswer('habit_resistance', 10);
      answers.setAnswer('social_charisma', 8);
      
      await userService.completeOnboarding(userId: userId, answers: answers);
      await userService.addEXP(userId: userId, expToAdd: 3000.0);
      await userService.updateStats(
        userId: userId,
        statUpdates: {StatType.strength: 2.0, StatType.intelligence: 1.5},
      );
      
      // Verify user has progress
      var user = userService.getCurrentUser()!;
      expect(user.level, greaterThan(1));
      expect(user.currentEXP, greaterThan(0));
      expect(user.getStat(StatType.strength), greaterThan(3.0));
      
      // Reset progress
      final resetUser = await userService.resetUserProgress(userId);
      
      expect(resetUser.level, equals(1));
      expect(resetUser.currentEXP, equals(0.0));
      expect(resetUser.getStat(StatType.strength), equals(1.0));
      expect(resetUser.getStat(StatType.intelligence), equals(1.0));
      expect(resetUser.hasCompletedOnboarding, isTrue); // Onboarding status preserved
    });

    test('Error handling for invalid operations', () async {
      // Test operations on non-existent user
      expect(
        () => userService.addEXP(userId: 'invalid_id', expToAdd: 100.0),
        throwsA(isA<UserServiceException>()),
      );
      
      expect(
        () => userService.updateUserProfile(userId: 'invalid_id', name: 'Test'),
        throwsA(isA<UserServiceException>()),
      );
      
      expect(
        () => userService.getUserLevelInfo('invalid_id'),
        throwsA(isA<UserServiceException>()),
      );
      
      expect(
        () => userService.getUserStatsSummary('invalid_id'),
        throwsA(isA<UserServiceException>()),
      );
      
      // Test invalid EXP values
      final initResult = await userService.initializeApp();
      expect(
        () => userService.addEXP(userId: initResult.user.id, expToAdd: -50.0),
        throwsA(isA<UserServiceException>()),
      );
    });
  });
}