import 'enums.dart';

/// Represents a single onboarding question
class OnboardingQuestion {
  final String id;
  final String question;
  final OnboardingQuestionType type;
  final int? minValue;
  final int? maxValue;
  final bool isRequired;

  const OnboardingQuestion({
    required this.id,
    required this.question,
    required this.type,
    this.minValue,
    this.maxValue,
    this.isRequired = true,
  });
}

/// Types of onboarding questions
enum OnboardingQuestionType {
  scale,      // 1-10 scale
  frequency,  // 0-7 frequency
  text,       // Optional text field
}

/// Represents user's answers to onboarding questions
class OnboardingAnswers {
  final Map<String, dynamic> answers;

  OnboardingAnswers({Map<String, dynamic>? answers}) 
      : answers = answers ?? {};

  /// Set answer for a question
  void setAnswer(String questionId, dynamic value) {
    answers[questionId] = value;
  }

  /// Get answer for a question
  T? getAnswer<T>(String questionId) {
    return answers[questionId] as T?;
  }

  /// Check if question has been answered
  bool hasAnswer(String questionId) {
    return answers.containsKey(questionId) && answers[questionId] != null;
  }

  /// Get all answered question IDs
  List<String> getAnsweredQuestions() {
    return answers.keys.where((key) => answers[key] != null).toList();
  }

  /// Clear all answers
  void clear() {
    answers.clear();
  }

  /// Convert answers to initial stats
  Map<StatType, double> toInitialStats() {
    // Default stats if no answers provided
    final Map<StatType, double> stats = {
      StatType.strength: 1.0,
      StatType.agility: 1.0,
      StatType.endurance: 1.0,
      StatType.intelligence: 1.0,
      StatType.focus: 1.0,
      StatType.charisma: 1.0,
    };

    // Map answers to stats (scale 1-10 responses to 1-5 base stats)
    
    // Physical strength/fitness level (1-10) -> Strength (1-5)
    final strengthAnswer = getAnswer<int>('physical_strength');
    if (strengthAnswer != null) {
      stats[StatType.strength] = _scaleToStatValue(strengthAnswer);
    }

    // Workout sessions per week (0-7) -> Endurance (1-5)
    final workoutAnswer = getAnswer<int>('workout_frequency');
    if (workoutAnswer != null) {
      // Scale 0-7 to 1-5: (value / 7) * 4 + 1
      stats[StatType.endurance] = ((workoutAnswer / 7) * 4 + 1).clamp(1.0, 5.0);
    }

    // Agility/flexibility level (1-10) -> Agility (1-5)
    final agilityAnswer = getAnswer<int>('agility_flexibility');
    if (agilityAnswer != null) {
      stats[StatType.agility] = _scaleToStatValue(agilityAnswer);
    }

    // Study hours per week (converted to 1-10 scale) -> Intelligence (1-5)
    final studyAnswer = getAnswer<int>('study_hours');
    if (studyAnswer != null) {
      // Assume max 40 hours/week study time, scale to 1-10, then to 1-5
      final scaledStudy = ((studyAnswer / 40) * 10).clamp(1, 10);
      stats[StatType.intelligence] = _scaleToStatValue(scaledStudy.round());
    }

    // Mental focus/discipline (1-10) -> Focus (1-5)
    final focusAnswer = getAnswer<int>('mental_focus');
    if (focusAnswer != null) {
      stats[StatType.focus] = _scaleToStatValue(focusAnswer);
    }

    // Bad habit resistance (0-10) -> Focus boost (1-5)
    final habitAnswer = getAnswer<int>('habit_resistance');
    if (habitAnswer != null) {
      // This also contributes to focus
      final habitFocus = _scaleToStatValue(habitAnswer);
      stats[StatType.focus] = ((stats[StatType.focus]! + habitFocus) / 2).clamp(1.0, 5.0);
    }

    // Social charisma/confidence (1-10) -> Charisma (1-5)
    final charismaAnswer = getAnswer<int>('social_charisma');
    if (charismaAnswer != null) {
      stats[StatType.charisma] = _scaleToStatValue(charismaAnswer);
    }

    return stats;
  }

  /// Convert 1-10 scale to 1-5 stat value
  double _scaleToStatValue(int scaleValue) {
    // Scale 1-10 to 1-5: ((value - 1) / 9) * 4 + 1
    return (((scaleValue - 1) / 9) * 4 + 1).clamp(1.0, 5.0);
  }

  @override
  String toString() {
    return 'OnboardingAnswers(answers: $answers)';
  }
}