import 'package:flutter_test/flutter_test.dart';
import 'package:yolvl/providers/user_provider.dart';
import 'package:yolvl/services/user_service.dart';
import 'package:yolvl/services/app_lifecycle_service.dart';
import 'package:yolvl/models/user.dart';
import 'package:yolvl/models/enums.dart';

void main() {
  group('UserProvider Tests', () {
    late UserProvider userProvider;

    setUp(() {
      userProvider = UserProvider();
    });

    test('should initialize with default values', () {
      expect(userProvider.currentUser, isNull);
      expect(userProvider.isLoading, isFalse);
      expect(userProvider.errorMessage, isNull);
      expect(userProvider.needsOnboarding, isFalse);
      expect(userProvider.isFirstTime, isFalse);
      expect(userProvider.hasUser, isFalse);
      expect(userProvider.degradationWarnings, isEmpty);
      expect(userProvider.hasPendingDegradation, isFalse);
    });

    test('should provide default user profile values when no user', () {
      expect(userProvider.userName, equals('Player'));
      expect(userProvider.avatarPath, isNull);
      expect(userProvider.level, equals(1));
      expect(userProvider.currentEXP, equals(0.0));
      expect(userProvider.expThreshold, equals(1000.0));
      expect(userProvider.expProgress, equals(0.0));
      expect(userProvider.canLevelUp, isFalse);
    });

    test('should provide default stats when no user', () {
      final stats = userProvider.stats;
      expect(stats.length, equals(StatType.values.length));
      
      for (final statType in StatType.values) {
        expect(stats[statType], equals(1.0));
        expect(userProvider.getStat(statType), equals(1.0));
      }
    });

    test('should clear error message', () {
      // Simulate an error state
      userProvider.clearError();
      expect(userProvider.errorMessage, isNull);
    });

    test('should provide access to app lifecycle service', () {
      expect(userProvider.appLifecycleService, isNotNull);
      expect(userProvider.appLifecycleService, isA<AppLifecycleService>());
    });
  });
}