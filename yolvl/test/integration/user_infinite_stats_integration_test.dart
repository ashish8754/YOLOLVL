import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:yolvl/models/user.dart';
import 'package:yolvl/models/enums.dart';
import 'package:yolvl/repositories/user_repository.dart';

void main() {
  group('User Repository - Infinite Stats Integration', () {
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
    });

    tearDown(() async {
      await tearDownTestHive();
    });

    test('should persist and retrieve high stat values correctly', () async {
      // Create user through repository
      final user = await userRepository.createUser(
        id: 'test_user_high_stats',
        name: 'High Stats User',
      );

      // Set various high stat values
      user.setStat(StatType.strength, 15.75);
      user.setStat(StatType.agility, 23.33);
      user.setStat(StatType.endurance, 67.89);
      user.setStat(StatType.intelligence, 123.45);
      user.setStat(StatType.focus, 99.99);
      user.setStat(StatType.charisma, 8.12);

      // Update user in repository
      await userRepository.updateUser(user);

      // Retrieve from repository
      final retrievedUser = userRepository.getCurrentUser();

      // Verify all high stat values are preserved
      expect(retrievedUser, isNotNull);
      expect(retrievedUser!.getStat(StatType.strength), equals(15.75));
      expect(retrievedUser.getStat(StatType.agility), equals(23.33));
      expect(retrievedUser.getStat(StatType.endurance), equals(67.89));
      expect(retrievedUser.getStat(StatType.intelligence), equals(123.45));
      expect(retrievedUser.getStat(StatType.focus), equals(99.99));
      expect(retrievedUser.getStat(StatType.charisma), equals(8.12));
    });

    test('should handle extremely high stat values in persistence', () async {
      // Create user through repository
      final user = await userRepository.createUser(
        id: 'test_user_extreme_stats',
        name: 'Extreme Stats User',
      );

      // Set extremely high values
      user.setStat(StatType.strength, 999.999);
      user.setStat(StatType.intelligence, 10000.0);
      user.setStat(StatType.endurance, 5000.5);

      // Update and retrieve
      await userRepository.updateUser(user);
      final retrievedUser = userRepository.getCurrentUser();

      // Verify extreme values are preserved
      expect(retrievedUser, isNotNull);
      expect(retrievedUser!.getStat(StatType.strength), equals(999.999));
      expect(retrievedUser.getStat(StatType.intelligence), equals(10000.0));
      expect(retrievedUser.getStat(StatType.endurance), equals(5000.5));
    });

    test('should preserve decimal precision for high stat values', () async {
      // Create user through repository
      final user = await userRepository.createUser(
        id: 'test_user_precise_stats',
        name: 'Precise Stats User',
      );

      // Set stats with various decimal precisions
      user.setStat(StatType.strength, 7.123456789);
      user.setStat(StatType.agility, 15.0);
      user.setStat(StatType.endurance, 23.5);
      user.setStat(StatType.intelligence, 42.75);

      // Update and retrieve
      await userRepository.updateUser(user);
      final retrievedUser = userRepository.getCurrentUser();

      // Verify decimal precision is preserved
      expect(retrievedUser, isNotNull);
      expect(retrievedUser!.getStat(StatType.strength), equals(7.123456789));
      expect(retrievedUser.getStat(StatType.agility), equals(15.0));
      expect(retrievedUser.getStat(StatType.endurance), equals(23.5));
      expect(retrievedUser.getStat(StatType.intelligence), equals(42.75));
    });

    test('should handle mixed stat ranges correctly', () async {
      // Create user through repository
      final user = await userRepository.createUser(
        id: 'test_user_mixed_stats',
        name: 'Mixed Stats User',
      );

      // Set mixed range values
      user.setStat(StatType.strength, 1.1);     // Low
      user.setStat(StatType.agility, 5.0);      // At old ceiling
      user.setStat(StatType.endurance, 12.5);   // Above old ceiling
      user.setStat(StatType.intelligence, 100.0); // Very high
      user.setStat(StatType.focus, 3.7);        // Medium
      user.setStat(StatType.charisma, 25.8);    // High

      // Update and retrieve
      await userRepository.updateUser(user);
      final retrievedUser = userRepository.getCurrentUser();

      // Verify all mixed values are preserved
      expect(retrievedUser, isNotNull);
      expect(retrievedUser!.getStat(StatType.strength), equals(1.1));
      expect(retrievedUser.getStat(StatType.agility), equals(5.0));
      expect(retrievedUser.getStat(StatType.endurance), equals(12.5));
      expect(retrievedUser.getStat(StatType.intelligence), equals(100.0));
      expect(retrievedUser.getStat(StatType.focus), equals(3.7));
      expect(retrievedUser.getStat(StatType.charisma), equals(25.8));
    });

    test('should update high stat values correctly', () async {
      // Create initial user through repository
      final user = await userRepository.createUser(
        id: 'test_user_update_stats',
        name: 'Update Stats User',
      );

      user.setStat(StatType.strength, 10.0);
      await userRepository.updateUser(user);

      // Update to higher value
      user.setStat(StatType.strength, 25.75);
      user.addToStat(StatType.agility, 15.5); // Should become 16.5 (1.0 + 15.5)
      await userRepository.updateUser(user);

      // Retrieve and verify updates
      final retrievedUser = userRepository.getCurrentUser();
      expect(retrievedUser, isNotNull);
      expect(retrievedUser!.getStat(StatType.strength), equals(25.75));
      expect(retrievedUser.getStat(StatType.agility), equals(16.5));
    });

    test('should handle stat progression beyond old ceiling', () async {
      // Create user through repository
      final user = await userRepository.createUser(
        id: 'test_user_progression',
        name: 'Progression User',
      );

      // Start with stats near old ceiling
      user.setStat(StatType.strength, 4.8);
      user.setStat(StatType.intelligence, 4.9);
      await userRepository.updateUser(user);

      // Simulate multiple activity gains that push beyond 5.0
      user.addToStat(StatType.strength, 0.3); // 5.1
      user.addToStat(StatType.strength, 0.5); // 5.6
      user.addToStat(StatType.strength, 1.2); // 6.8

      user.addToStat(StatType.intelligence, 0.2); // 5.1
      user.addToStat(StatType.intelligence, 2.5); // 7.6
      user.addToStat(StatType.intelligence, 5.0); // 12.6

      await userRepository.updateUser(user);

      // Verify progression beyond old ceiling
      final retrievedUser = userRepository.getCurrentUser();
      expect(retrievedUser, isNotNull);
      expect(retrievedUser!.getStat(StatType.strength), closeTo(6.8, 0.001));
      expect(retrievedUser.getStat(StatType.intelligence), closeTo(12.6, 0.001));
    });
  });
}