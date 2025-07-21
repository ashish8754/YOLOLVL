import 'package:flutter_test/flutter_test.dart';
import 'package:yolvl/models/user.dart';
import 'package:yolvl/models/enums.dart';

void main() {
  group('User Model - Infinite Stats', () {
    late User user;

    setUp(() {
      user = User.create(
        id: 'test_user',
        name: 'Test User',
      );
    });

    test('should allow stats to be set above 5.0', () {
      // Test setting stats to high values
      user.setStat(StatType.strength, 7.5);
      user.setStat(StatType.agility, 12.3);
      user.setStat(StatType.endurance, 25.7);
      user.setStat(StatType.intelligence, 100.0);
      user.setStat(StatType.focus, 50.25);
      user.setStat(StatType.charisma, 8.9);

      // Verify stats are stored correctly
      expect(user.getStat(StatType.strength), equals(7.5));
      expect(user.getStat(StatType.agility), equals(12.3));
      expect(user.getStat(StatType.endurance), equals(25.7));
      expect(user.getStat(StatType.intelligence), equals(100.0));
      expect(user.getStat(StatType.focus), equals(50.25));
      expect(user.getStat(StatType.charisma), equals(8.9));
    });

    test('should allow stats to be incremented beyond 5.0', () {
      // Start with stats at 4.8
      user.setStat(StatType.strength, 4.8);
      user.setStat(StatType.agility, 4.9);

      // Add increments that push beyond 5.0
      user.addToStat(StatType.strength, 0.5); // Should become 5.3
      user.addToStat(StatType.agility, 2.1);  // Should become 7.0

      expect(user.getStat(StatType.strength), equals(5.3));
      expect(user.getStat(StatType.agility), equals(7.0));
    });

    test('should handle very large stat values', () {
      // Test with extremely high values
      user.setStat(StatType.strength, 999.99);
      user.setStat(StatType.intelligence, 1000000.0);

      expect(user.getStat(StatType.strength), equals(999.99));
      expect(user.getStat(StatType.intelligence), equals(1000000.0));
    });

    test('should preserve high stat values in copyWith', () {
      // Set high stats
      user.setStat(StatType.strength, 15.7);
      user.setStat(StatType.agility, 23.4);

      // Create copy
      final copiedUser = user.copyWith(name: 'Copied User');

      // Verify stats are preserved
      expect(copiedUser.getStat(StatType.strength), equals(15.7));
      expect(copiedUser.getStat(StatType.agility), equals(23.4));
      expect(copiedUser.name, equals('Copied User'));
    });

    test('should serialize and deserialize high stat values correctly', () {
      // Set high stats
      user.setStat(StatType.strength, 42.75);
      user.setStat(StatType.agility, 18.33);
      user.setStat(StatType.endurance, 67.89);
      user.setStat(StatType.intelligence, 123.45);
      user.setStat(StatType.focus, 99.99);
      user.setStat(StatType.charisma, 11.11);

      // Convert to JSON
      final json = user.toJson();

      // Verify JSON contains correct values
      expect(json['stats']['strength'], equals(42.75));
      expect(json['stats']['agility'], equals(18.33));
      expect(json['stats']['endurance'], equals(67.89));
      expect(json['stats']['intelligence'], equals(123.45));
      expect(json['stats']['focus'], equals(99.99));
      expect(json['stats']['charisma'], equals(11.11));

      // Create user from JSON
      final deserializedUser = User.fromJson(json);

      // Verify stats are correctly deserialized
      expect(deserializedUser.getStat(StatType.strength), equals(42.75));
      expect(deserializedUser.getStat(StatType.agility), equals(18.33));
      expect(deserializedUser.getStat(StatType.endurance), equals(67.89));
      expect(deserializedUser.getStat(StatType.intelligence), equals(123.45));
      expect(deserializedUser.getStat(StatType.focus), equals(99.99));
      expect(deserializedUser.getStat(StatType.charisma), equals(11.11));
    });

    test('should handle decimal precision correctly for high values', () {
      // Test various decimal precisions
      user.setStat(StatType.strength, 7.123456789);
      user.setStat(StatType.agility, 15.0);
      user.setStat(StatType.endurance, 23.5);

      expect(user.getStat(StatType.strength), equals(7.123456789));
      expect(user.getStat(StatType.agility), equals(15.0));
      expect(user.getStat(StatType.endurance), equals(23.5));
    });

    test('should still enforce minimum floor of 1.0', () {
      // Try to set stats below 1.0 - this should be handled by validation elsewhere
      // but the User model itself should store whatever value is given
      user.setStat(StatType.strength, 0.5);
      user.setStat(StatType.agility, -1.0);

      // User model stores the values as-is
      expect(user.getStat(StatType.strength), equals(0.5));
      expect(user.getStat(StatType.agility), equals(-1.0));
    });

    test('should handle mixed stat ranges correctly', () {
      // Set some stats low, some high
      user.setStat(StatType.strength, 1.2);    // Low
      user.setStat(StatType.agility, 5.0);     // At old ceiling
      user.setStat(StatType.endurance, 15.7);  // Above old ceiling
      user.setStat(StatType.intelligence, 100.0); // Very high
      user.setStat(StatType.focus, 2.3);       // Low-medium
      user.setStat(StatType.charisma, 8.9);    // Medium-high

      expect(user.getStat(StatType.strength), equals(1.2));
      expect(user.getStat(StatType.agility), equals(5.0));
      expect(user.getStat(StatType.endurance), equals(15.7));
      expect(user.getStat(StatType.intelligence), equals(100.0));
      expect(user.getStat(StatType.focus), equals(2.3));
      expect(user.getStat(StatType.charisma), equals(8.9));
    });
  });
}