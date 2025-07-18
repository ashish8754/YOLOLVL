import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/onboarding_service.dart';
import '../../lib/models/onboarding.dart';
import '../../lib/models/enums.dart';

void main() {
  group('OnboardingService', () {
    test('should return 8 onboarding questions', () {
      final questions = OnboardingService.getOnboardingQuestions();
      
      expect(questions.length, equals(8));
      
      // Verify specific questions exist
      expect(questions.any((q) => q.id == 'physical_strength'), isTrue);
      expect(questions.any((q) => q.id == 'workout_frequency'), isTrue);
      expect(questions.any((q) => q.id == 'agility_flexibility'), isTrue);
      expect(questions.any((q) => q.id == 'study_hours'), isTrue);
      expect(questions.any((q) => q.id == 'mental_focus'), isTrue);
      expect(questions.any((q) => q.id == 'habit_resistance'), isTrue);
      expect(questions.any((q) => q.id == 'social_charisma'), isTrue);
      expect(questions.any((q) => q.id == 'achievements'), isTrue);
    });

    test('should have correct question types and requirements', () {
      final questions = OnboardingService.getOnboardingQuestions();
      
      // Physical strength should be scale 1-10, required
      final strengthQ = questions.firstWhere((q) => q.id == 'physical_strength');
      expect(strengthQ.type, equals(OnboardingQuestionType.scale));
      expect(strengthQ.minValue, equals(1));
      expect(strengthQ.maxValue, equals(10));
      expect(strengthQ.isRequired, isTrue);
      
      // Workout frequency should be frequency 0-7, required
      final workoutQ = questions.firstWhere((q) => q.id == 'workout_frequency');
      expect(workoutQ.type, equals(OnboardingQuestionType.frequency));
      expect(workoutQ.minValue, equals(0));
      expect(workoutQ.maxValue, equals(7));
      expect(workoutQ.isRequired, isTrue);
      
      // Achievements should be text, optional
      final achievementsQ = questions.firstWhere((q) => q.id == 'achievements');
      expect(achievementsQ.type, equals(OnboardingQuestionType.text));
      expect(achievementsQ.isRequired, isFalse);
    });

    group('Answer Validation', () {
      test('should validate scale answers correctly', () {
        final questions = OnboardingService.getOnboardingQuestions();
        final strengthQ = questions.firstWhere((q) => q.id == 'physical_strength');
        
        // Valid answers
        expect(OnboardingService.validateAnswer(strengthQ, 1), isTrue);
        expect(OnboardingService.validateAnswer(strengthQ, 5), isTrue);
        expect(OnboardingService.validateAnswer(strengthQ, 10), isTrue);
        
        // Invalid answers
        expect(OnboardingService.validateAnswer(strengthQ, 0), isFalse);
        expect(OnboardingService.validateAnswer(strengthQ, 11), isFalse);
        expect(OnboardingService.validateAnswer(strengthQ, null), isFalse);
        expect(OnboardingService.validateAnswer(strengthQ, 'invalid'), isFalse);
      });

      test('should validate frequency answers correctly', () {
        final questions = OnboardingService.getOnboardingQuestions();
        final workoutQ = questions.firstWhere((q) => q.id == 'workout_frequency');
        
        // Valid answers
        expect(OnboardingService.validateAnswer(workoutQ, 0), isTrue);
        expect(OnboardingService.validateAnswer(workoutQ, 3), isTrue);
        expect(OnboardingService.validateAnswer(workoutQ, 7), isTrue);
        
        // Invalid answers
        expect(OnboardingService.validateAnswer(workoutQ, -1), isFalse);
        expect(OnboardingService.validateAnswer(workoutQ, 8), isFalse);
        expect(OnboardingService.validateAnswer(workoutQ, null), isFalse);
      });

      test('should validate text answers correctly', () {
        final questions = OnboardingService.getOnboardingQuestions();
        final achievementsQ = questions.firstWhere((q) => q.id == 'achievements');
        
        // Valid answers (including null for optional)
        expect(OnboardingService.validateAnswer(achievementsQ, 'Some achievement'), isTrue);
        expect(OnboardingService.validateAnswer(achievementsQ, ''), isTrue);
        expect(OnboardingService.validateAnswer(achievementsQ, null), isTrue);
        
        // Invalid answers
        expect(OnboardingService.validateAnswer(achievementsQ, 123), isFalse);
      });
    });

    group('Initial Stats Calculation', () {
      test('should return default stats when no answers provided', () {
        final answers = OnboardingAnswers();
        final stats = OnboardingService.calculateInitialStats(answers);
        
        expect(stats[StatType.strength], equals(1.0));
        expect(stats[StatType.agility], equals(1.0));
        expect(stats[StatType.endurance], equals(1.0));
        expect(stats[StatType.intelligence], equals(1.0));
        expect(stats[StatType.focus], equals(1.0));
        expect(stats[StatType.charisma], equals(1.0));
      });

      test('should calculate stats correctly from scale answers', () {
        final answers = OnboardingAnswers();
        answers.setAnswer('physical_strength', 10); // Max strength
        answers.setAnswer('agility_flexibility', 1); // Min agility
        answers.setAnswer('mental_focus', 5); // Mid focus
        answers.setAnswer('social_charisma', 7); // Above mid charisma
        
        final stats = OnboardingService.calculateInitialStats(answers);
        
        // 10 on 1-10 scale should map to 5.0 on 1-5 scale
        expect(stats[StatType.strength], closeTo(5.0, 0.1));
        
        // 1 on 1-10 scale should map to 1.0 on 1-5 scale
        expect(stats[StatType.agility], closeTo(1.0, 0.1));
        
        // 5 on 1-10 scale should map to ~2.8 on 1-5 scale
        expect(stats[StatType.focus], closeTo(2.8, 0.2));
        
        // 7 on 1-10 scale should map to ~3.7 on 1-5 scale
        expect(stats[StatType.charisma], closeTo(3.7, 0.2));
      });

      test('should calculate endurance from workout frequency', () {
        final answers = OnboardingAnswers();
        answers.setAnswer('workout_frequency', 7); // Max frequency
        
        final stats = OnboardingService.calculateInitialStats(answers);
        
        // 7 sessions/week should map to 5.0 endurance
        expect(stats[StatType.endurance], closeTo(5.0, 0.1));
      });

      test('should calculate intelligence from study hours', () {
        final answers = OnboardingAnswers();
        answers.setAnswer('study_hours', 20); // Half of max (40)
        
        final stats = OnboardingService.calculateInitialStats(answers);
        
        // 20 hours should map to mid-range intelligence
        expect(stats[StatType.intelligence], greaterThan(2.0));
        expect(stats[StatType.intelligence], lessThan(4.0));
      });

      test('should combine focus from mental focus and habit resistance', () {
        final answers = OnboardingAnswers();
        answers.setAnswer('mental_focus', 8);
        answers.setAnswer('habit_resistance', 6);
        
        final stats = OnboardingService.calculateInitialStats(answers);
        
        // Focus should be average of both contributions
        expect(stats[StatType.focus], greaterThan(3.0));
        expect(stats[StatType.focus], lessThan(5.0));
      });
    });

    group('Completion Tracking', () {
      test('should detect when required questions are answered', () {
        final answers = OnboardingAnswers();
        
        // Initially not complete
        expect(OnboardingService.areRequiredQuestionsAnswered(answers), isFalse);
        
        // Add all required answers
        answers.setAnswer('physical_strength', 5);
        answers.setAnswer('workout_frequency', 3);
        answers.setAnswer('agility_flexibility', 4);
        answers.setAnswer('study_hours', 10);
        answers.setAnswer('mental_focus', 6);
        answers.setAnswer('habit_resistance', 7);
        answers.setAnswer('social_charisma', 5);
        // achievements is optional, so not needed
        
        expect(OnboardingService.areRequiredQuestionsAnswered(answers), isTrue);
      });

      test('should calculate completion percentage correctly', () {
        final answers = OnboardingAnswers();
        
        // 0% initially
        expect(OnboardingService.getCompletionPercentage(answers), equals(0.0));
        
        // Add one required answer (1/7 = ~0.14)
        answers.setAnswer('physical_strength', 5);
        expect(OnboardingService.getCompletionPercentage(answers), closeTo(0.14, 0.02));
        
        // Add all required answers
        answers.setAnswer('workout_frequency', 3);
        answers.setAnswer('agility_flexibility', 4);
        answers.setAnswer('study_hours', 10);
        answers.setAnswer('mental_focus', 6);
        answers.setAnswer('habit_resistance', 7);
        answers.setAnswer('social_charisma', 5);
        
        expect(OnboardingService.getCompletionPercentage(answers), equals(1.0));
      });

      test('should identify unanswered required questions', () {
        final answers = OnboardingAnswers();
        answers.setAnswer('physical_strength', 5);
        answers.setAnswer('workout_frequency', 3);
        // Missing other required questions
        
        final unanswered = OnboardingService.getUnansweredRequiredQuestions(answers);
        expect(unanswered.length, equals(5)); // 7 required - 2 answered = 5
        expect(unanswered.any((q) => q.id == 'agility_flexibility'), isTrue);
        expect(unanswered.any((q) => q.id == 'achievements'), isFalse); // Optional
      });
    });

    test('should get default stats', () {
      final defaultStats = OnboardingService.getDefaultStats();
      
      expect(defaultStats.length, equals(6));
      expect(defaultStats[StatType.strength], equals(1.0));
      expect(defaultStats[StatType.agility], equals(1.0));
      expect(defaultStats[StatType.endurance], equals(1.0));
      expect(defaultStats[StatType.intelligence], equals(1.0));
      expect(defaultStats[StatType.focus], equals(1.0));
      expect(defaultStats[StatType.charisma], equals(1.0));
    });

    test('should create onboarding summary', () {
      final answers = OnboardingAnswers();
      answers.setAnswer('physical_strength', 8);
      answers.setAnswer('workout_frequency', 4);
      answers.setAnswer('study_hours', 15);
      answers.setAnswer('achievements', 'Completed a marathon');
      
      final summary = OnboardingService.createOnboardingSummary(answers);
      
      expect(summary.length, equals(4));
      expect(summary.values.any((v) => v.contains('8/10')), isTrue);
      expect(summary.values.any((v) => v.contains('4 sessions/week')), isTrue);
      expect(summary.values.any((v) => v.contains('15 hours/week')), isTrue);
      expect(summary.values.any((v) => v.contains('marathon')), isTrue);
    });
  });

  group('OnboardingAnswers', () {
    test('should handle answer setting and getting', () {
      final answers = OnboardingAnswers();
      
      expect(answers.hasAnswer('test'), isFalse);
      
      answers.setAnswer('test', 5);
      expect(answers.hasAnswer('test'), isTrue);
      expect(answers.getAnswer<int>('test'), equals(5));
    });

    test('should convert to initial stats correctly', () {
      final answers = OnboardingAnswers();
      answers.setAnswer('physical_strength', 10);
      answers.setAnswer('social_charisma', 1);
      
      final stats = answers.toInitialStats();
      
      expect(stats[StatType.strength], closeTo(5.0, 0.1));
      expect(stats[StatType.charisma], closeTo(1.0, 0.1));
      expect(stats[StatType.agility], equals(1.0)); // Default
    });

    test('should clear answers', () {
      final answers = OnboardingAnswers();
      answers.setAnswer('test1', 5);
      answers.setAnswer('test2', 'value');
      
      expect(answers.getAnsweredQuestions().length, equals(2));
      
      answers.clear();
      expect(answers.getAnsweredQuestions().length, equals(0));
    });
  });
}