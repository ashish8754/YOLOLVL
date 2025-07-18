import '../models/onboarding.dart';
import '../models/enums.dart';

/// Service for handling user onboarding questionnaire and stat initialization
class OnboardingService {
  /// Get the list of onboarding questions
  static List<OnboardingQuestion> getOnboardingQuestions() {
    return [
      const OnboardingQuestion(
        id: 'physical_strength',
        question: 'On a scale of 1-10, what\'s your current physical strength/fitness level?',
        type: OnboardingQuestionType.scale,
        minValue: 1,
        maxValue: 10,
      ),
      const OnboardingQuestion(
        id: 'workout_frequency',
        question: 'How many workout sessions do you do per week on average (0-7)?',
        type: OnboardingQuestionType.frequency,
        minValue: 0,
        maxValue: 7,
      ),
      const OnboardingQuestion(
        id: 'agility_flexibility',
        question: 'On a scale of 1-10, how would you rate your agility/flexibility?',
        type: OnboardingQuestionType.scale,
        minValue: 1,
        maxValue: 10,
      ),
      const OnboardingQuestion(
        id: 'study_hours',
        question: 'How many hours per week do you spend studying/learning seriously?',
        type: OnboardingQuestionType.frequency,
        minValue: 0,
        maxValue: 40, // Reasonable max for study hours
      ),
      const OnboardingQuestion(
        id: 'mental_focus',
        question: 'On a scale of 1-10, your mental focus/discipline?',
        type: OnboardingQuestionType.scale,
        minValue: 1,
        maxValue: 10,
      ),
      const OnboardingQuestion(
        id: 'habit_resistance',
        question: 'How often do you successfully resist bad habits daily (0=never, 10=always)?',
        type: OnboardingQuestionType.scale,
        minValue: 0,
        maxValue: 10,
      ),
      const OnboardingQuestion(
        id: 'social_charisma',
        question: 'On a scale of 1-10, your social charisma/confidence?',
        type: OnboardingQuestionType.scale,
        minValue: 1,
        maxValue: 10,
      ),
      const OnboardingQuestion(
        id: 'achievements',
        question: 'Any recent achievements or baselines (optional text field)?',
        type: OnboardingQuestionType.text,
        isRequired: false,
      ),
    ];
  }

  /// Validate an answer for a specific question
  static bool validateAnswer(OnboardingQuestion question, dynamic answer) {
    if (question.isRequired && answer == null) {
      return false;
    }

    if (answer == null && !question.isRequired) {
      return true; // Optional question, null is valid
    }

    switch (question.type) {
      case OnboardingQuestionType.scale:
      case OnboardingQuestionType.frequency:
        if (answer is! int) return false;
        final intAnswer = answer as int;
        return intAnswer >= (question.minValue ?? 0) && 
               intAnswer <= (question.maxValue ?? 10);
      
      case OnboardingQuestionType.text:
        return answer is String; // Any string is valid for text
    }
  }

  /// Calculate initial stats from onboarding answers
  static Map<StatType, double> calculateInitialStats(OnboardingAnswers answers) {
    return answers.toInitialStats();
  }

  /// Get default stats (used when skipping onboarding)
  static Map<StatType, double> getDefaultStats() {
    return {
      StatType.strength: 1.0,
      StatType.agility: 1.0,
      StatType.endurance: 1.0,
      StatType.intelligence: 1.0,
      StatType.focus: 1.0,
      StatType.charisma: 1.0,
    };
  }

  /// Check if all required questions are answered
  static bool areRequiredQuestionsAnswered(OnboardingAnswers answers) {
    final questions = getOnboardingQuestions();
    final requiredQuestions = questions.where((q) => q.isRequired).toList();
    
    for (final question in requiredQuestions) {
      if (!answers.hasAnswer(question.id)) {
        return false;
      }
      
      final answer = answers.getAnswer(question.id);
      if (!validateAnswer(question, answer)) {
        return false;
      }
    }
    
    return true;
  }

  /// Get completion percentage of onboarding
  static double getCompletionPercentage(OnboardingAnswers answers) {
    final questions = getOnboardingQuestions();
    final requiredQuestions = questions.where((q) => q.isRequired).toList();
    
    if (requiredQuestions.isEmpty) return 1.0;
    
    int answeredCount = 0;
    for (final question in requiredQuestions) {
      if (answers.hasAnswer(question.id)) {
        final answer = answers.getAnswer(question.id);
        if (validateAnswer(question, answer)) {
          answeredCount++;
        }
      }
    }
    
    return answeredCount / requiredQuestions.length;
  }

  /// Get list of unanswered required questions
  static List<OnboardingQuestion> getUnansweredRequiredQuestions(OnboardingAnswers answers) {
    final questions = getOnboardingQuestions();
    final requiredQuestions = questions.where((q) => q.isRequired).toList();
    
    return requiredQuestions.where((question) {
      if (!answers.hasAnswer(question.id)) return true;
      
      final answer = answers.getAnswer(question.id);
      return !validateAnswer(question, answer);
    }).toList();
  }

  /// Create a summary of the user's onboarding responses
  static Map<String, String> createOnboardingSummary(OnboardingAnswers answers) {
    final questions = getOnboardingQuestions();
    final Map<String, String> summary = {};
    
    for (final question in questions) {
      final answer = answers.getAnswer(question.id);
      if (answer != null) {
        String displayValue;
        switch (question.type) {
          case OnboardingQuestionType.scale:
            displayValue = '$answer/10';
            break;
          case OnboardingQuestionType.frequency:
            if (question.id == 'workout_frequency') {
              displayValue = '$answer sessions/week';
            } else if (question.id == 'study_hours') {
              displayValue = '$answer hours/week';
            } else {
              displayValue = answer.toString();
            }
            break;
          case OnboardingQuestionType.text:
            displayValue = answer.toString();
            break;
        }
        summary[question.question] = displayValue;
      }
    }
    
    return summary;
  }
}