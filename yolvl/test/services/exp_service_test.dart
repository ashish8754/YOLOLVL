import 'package:flutter_test/flutter_test.dart';
import 'package:yolvl/services/exp_service.dart';
import 'package:yolvl/models/user.dart';
import 'package:yolvl/models/enums.dart';

void main() {
  group('EXPService', () {
    group('calculateEXPThreshold', () {
      test('should calculate correct threshold for level 1', () {
        expect(EXPService.calculateEXPThreshold(1), equals(1000.0));
      });

      test('should calculate correct threshold for level 2', () {
        expect(EXPService.calculateEXPThreshold(2), equals(1200.0));
      });

      test('should calculate correct threshold for level 3', () {
        expect(EXPService.calculateEXPThreshold(3), equals(1440.0));
      });

      test('should calculate correct threshold for level 5', () {
        // 1000 * (1.2^4) = 1000 * 2.0736 = 2073.6
        expect(EXPService.calculateEXPThreshold(5), closeTo(2073.6, 0.1));
      });

      test('should calculate correct threshold for level 10', () {
        // 1000 * (1.2^9) = 1000 * 5.159780352 ≈ 5159.78
        expect(EXPService.calculateEXPThreshold(10), closeTo(5159.78, 0.1));
      });

      test('should throw error for level 0', () {
        expect(() => EXPService.calculateEXPThreshold(0), throwsArgumentError);
      });

      test('should throw error for negative level', () {
        expect(() => EXPService.calculateEXPThreshold(-1), throwsArgumentError);
      });
    });

    group('calculateEXPGain', () {
      test('should calculate 1 EXP per minute for standard activities', () {
        expect(EXPService.calculateEXPGain('workoutWeights', 60), equals(60.0));
        expect(EXPService.calculateEXPGain('studySerious', 30), equals(30.0));
        expect(EXPService.calculateEXPGain('meditation', 15), equals(15.0));
      });

      test('should return fixed 60 EXP for quit bad habit', () {
        expect(EXPService.calculateEXPGain('quitBadHabit', 1), equals(60.0));
        expect(EXPService.calculateEXPGain('quitBadHabit', 60), equals(60.0));
        expect(EXPService.calculateEXPGain('quitBadHabit', 120), equals(60.0));
      });

      test('should handle zero duration', () {
        expect(EXPService.calculateEXPGain('workoutWeights', 0), equals(0.0));
        expect(EXPService.calculateEXPGain('quitBadHabit', 0), equals(60.0));
      });

      test('should throw error for negative duration', () {
        expect(() => EXPService.calculateEXPGain('workoutWeights', -1), throwsArgumentError);
      });
    });

    group('checkLevelUp', () {
      test('should return false when EXP is below threshold', () {
        final user = User.create(id: 'test', name: 'Test')
          ..currentEXP = 500.0
          ..level = 1;

        final result = EXPService.checkLevelUp(user);

        expect(result.canLevelUp, isFalse);
        expect(result.newLevel, equals(1));
        expect(result.excessEXP, equals(0.0));
        expect(result.levelsGained, equals(0));
      });

      test('should return true when EXP meets threshold', () {
        final user = User.create(id: 'test', name: 'Test')
          ..currentEXP = 1000.0
          ..level = 1;

        final result = EXPService.checkLevelUp(user);

        expect(result.canLevelUp, isTrue);
        expect(result.newLevel, equals(2));
        expect(result.excessEXP, equals(0.0));
        expect(result.levelsGained, equals(1));
      });

      test('should handle excess EXP rollover', () {
        final user = User.create(id: 'test', name: 'Test')
          ..currentEXP = 1150.0
          ..level = 1;

        final result = EXPService.checkLevelUp(user);

        expect(result.canLevelUp, isTrue);
        expect(result.newLevel, equals(2));
        expect(result.excessEXP, equals(150.0));
        expect(result.levelsGained, equals(1));
      });

      test('should handle multiple level-ups', () {
        final user = User.create(id: 'test', name: 'Test')
          ..currentEXP = 2500.0 // Enough for level 1->2->3
          ..level = 1;

        final result = EXPService.checkLevelUp(user);

        expect(result.canLevelUp, isTrue);
        expect(result.newLevel, equals(3));
        expect(result.levelsGained, equals(2));
        // 2500 - 1000 (level 1->2) - 1200 (level 2->3) = 300
        expect(result.excessEXP, equals(300.0));
      });

      test('should handle edge case at exact threshold', () {
        final user = User.create(id: 'test', name: 'Test')
          ..currentEXP = 1200.0
          ..level = 2;

        final result = EXPService.checkLevelUp(user);

        expect(result.canLevelUp, isTrue);
        expect(result.newLevel, equals(3));
        expect(result.excessEXP, equals(0.0));
        expect(result.levelsGained, equals(1));
      });
    });

    group('applyLevelUp', () {
      test('should not modify user when no level-up is possible', () {
        final user = User.create(id: 'test', name: 'Test')
          ..currentEXP = 500.0
          ..level = 1;

        final result = EXPService.applyLevelUp(user);

        expect(result.level, equals(1));
        expect(result.currentEXP, equals(500.0));
      });

      test('should update user level and EXP when level-up occurs', () {
        final user = User.create(id: 'test', name: 'Test')
          ..currentEXP = 1150.0
          ..level = 1;

        final result = EXPService.applyLevelUp(user);

        expect(result.level, equals(2));
        expect(result.currentEXP, equals(150.0));
      });

      test('should handle multiple level-ups correctly', () {
        final user = User.create(id: 'test', name: 'Test')
          ..currentEXP = 2500.0
          ..level = 1;

        final result = EXPService.applyLevelUp(user);

        expect(result.level, equals(3));
        expect(result.currentEXP, equals(300.0));
      });
    });

    group('addEXP', () {
      test('should add EXP without level-up', () {
        final user = User.create(id: 'test', name: 'Test')
          ..currentEXP = 500.0
          ..level = 1;

        final result = EXPService.addEXP(user, 200.0);

        expect(result.level, equals(1));
        expect(result.currentEXP, equals(700.0));
      });

      test('should add EXP and trigger level-up', () {
        final user = User.create(id: 'test', name: 'Test')
          ..currentEXP = 800.0
          ..level = 1;

        final result = EXPService.addEXP(user, 300.0);

        expect(result.level, equals(2));
        expect(result.currentEXP, equals(100.0)); // 1100 - 1000 = 100
      });

      test('should handle zero EXP addition', () {
        final user = User.create(id: 'test', name: 'Test')
          ..currentEXP = 500.0
          ..level = 1;

        final result = EXPService.addEXP(user, 0.0);

        expect(result.level, equals(1));
        expect(result.currentEXP, equals(500.0));
      });

      test('should throw error for negative EXP', () {
        final user = User.create(id: 'test', name: 'Test');
        expect(() => EXPService.addEXP(user, -100.0), throwsArgumentError);
      });
    });

    group('calculateEXPProgress', () {
      test('should calculate correct progress percentage', () {
        final user = User.create(id: 'test', name: 'Test')
          ..currentEXP = 500.0
          ..level = 1;

        final progress = EXPService.calculateEXPProgress(user);
        expect(progress, equals(0.5)); // 500/1000 = 0.5
      });

      test('should handle progress at threshold', () {
        final user = User.create(id: 'test', name: 'Test')
          ..currentEXP = 1000.0
          ..level = 1;

        final progress = EXPService.calculateEXPProgress(user);
        expect(progress, equals(1.0));
      });

      test('should clamp progress above 1.0', () {
        final user = User.create(id: 'test', name: 'Test')
          ..currentEXP = 1500.0
          ..level = 1;

        final progress = EXPService.calculateEXPProgress(user);
        expect(progress, equals(1.0));
      });
    });

    group('getEXPNeededForNextLevel', () {
      test('should calculate EXP needed correctly', () {
        final user = User.create(id: 'test', name: 'Test')
          ..currentEXP = 300.0
          ..level = 1;

        final needed = EXPService.getEXPNeededForNextLevel(user);
        expect(needed, equals(700.0)); // 1000 - 300 = 700
      });

      test('should return 0 when at threshold', () {
        final user = User.create(id: 'test', name: 'Test')
          ..currentEXP = 1000.0
          ..level = 1;

        final needed = EXPService.getEXPNeededForNextLevel(user);
        expect(needed, equals(0.0));
      });

      test('should return 0 when above threshold', () {
        final user = User.create(id: 'test', name: 'Test')
          ..currentEXP = 1500.0
          ..level = 1;

        final needed = EXPService.getEXPNeededForNextLevel(user);
        expect(needed, equals(0.0));
      });
    });
  });
}