import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/onboarding.dart';
import '../models/enums.dart';
import '../services/onboarding_service.dart';
import '../providers/user_provider.dart';
import '../utils/page_transitions.dart';
import 'main_navigation_screen.dart';

/// Onboarding screen with questionnaire for new users
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final OnboardingAnswers _answers = OnboardingAnswers();
  
  late List<OnboardingQuestion> _questions;
  int _currentQuestionIndex = 0;
  bool _isLoading = false;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _questions = OnboardingService.getOnboardingQuestions();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentQuestionIndex = index;
                      });
                    },
                    itemCount: _questions.length + 1, // +1 for completion page
                    itemBuilder: (context, index) {
                      if (index < _questions.length) {
                        return _buildQuestionPage(_questions[index]);
                      } else {
                        return _buildCompletionPage();
                      }
                    },
                  ),
                ),
                _buildBottomNavigation(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final progress = (_currentQuestionIndex + 1) / (_questions.length + 1);
    
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Solo Leveling',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const Spacer(),
              if (_currentQuestionIndex < _questions.length)
                TextButton(
                  onPressed: _skipOnboarding,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currentQuestionIndex < _questions.length
                ? 'Question ${_currentQuestionIndex + 1} of ${_questions.length}'
                : 'Complete!',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionPage(OnboardingQuestion question) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            question.question,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 48),
          Expanded(
            child: _buildQuestionInput(question),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionInput(OnboardingQuestion question) {
    switch (question.type) {
      case OnboardingQuestionType.scale:
        return _buildScaleInput(question);
      case OnboardingQuestionType.frequency:
        return _buildFrequencyInput(question);
      case OnboardingQuestionType.text:
        return _buildTextInput(question);
    }
  }

  Widget _buildScaleInput(OnboardingQuestion question) {
    final currentValue = _answers.getAnswer<int>(question.id) ?? 5;
    
    return Column(
      children: [
        Text(
          currentValue.toString(),
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 24),
        Slider(
          value: currentValue.toDouble(),
          min: (question.minValue ?? 1).toDouble(),
          max: (question.maxValue ?? 10).toDouble(),
          divisions: (question.maxValue ?? 10) - (question.minValue ?? 1),
          onChanged: (value) {
            setState(() {
              _answers.setAnswer(question.id, value.round());
            });
          },
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${question.minValue ?? 1}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            Text(
              '${question.maxValue ?? 10}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFrequencyInput(OnboardingQuestion question) {
    final currentValue = _answers.getAnswer<int>(question.id) ?? 0;
    
    return Column(
      children: [
        Text(
          currentValue.toString(),
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          question.id == 'workout_frequency' 
              ? 'sessions per week'
              : question.id == 'study_hours'
                  ? 'hours per week'
                  : 'per week',
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 24),
        Slider(
          value: currentValue.toDouble(),
          min: (question.minValue ?? 0).toDouble(),
          max: (question.maxValue ?? 7).toDouble(),
          divisions: (question.maxValue ?? 7) - (question.minValue ?? 0),
          onChanged: (value) {
            setState(() {
              _answers.setAnswer(question.id, value.round());
            });
          },
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${question.minValue ?? 0}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            Text(
              '${question.maxValue ?? 7}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextInput(OnboardingQuestion question) {
    final controller = TextEditingController(
      text: _answers.getAnswer<String>(question.id) ?? '',
    );
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Share any recent achievements or current baselines...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainer,
          ),
          onChanged: (value) {
            _answers.setAnswer(question.id, value.isEmpty ? null : value);
          },
        ),
        const SizedBox(height: 16),
        Text(
          'This is optional and helps personalize your experience',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionPage() {
    final stats = OnboardingService.calculateInitialStats(_answers);
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Icon(
            Icons.check_circle,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          const Text(
            'Ready to Begin!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your initial stats have been calculated based on your responses.',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Expanded(
            child: _buildStatsPreview(stats),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsPreview(Map<StatType, double> stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Starting Stats',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          ...stats.entries.map((entry) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                _getStatIcon(entry.key),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getStatName(entry.key),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  entry.value.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    final isLastQuestion = _currentQuestionIndex >= _questions.length;
    final canProceed = isLastQuestion || _canProceedFromCurrentQuestion();
    
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          if (_currentQuestionIndex > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : _previousQuestion,
                child: const Text('Previous'),
              ),
            ),
          if (_currentQuestionIndex > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading || !canProceed ? null : () {
                if (isLastQuestion) {
                  _completeOnboarding();
                } else {
                  _nextQuestion();
                }
              },
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isLastQuestion ? 'Start Journey' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceedFromCurrentQuestion() {
    if (_currentQuestionIndex >= _questions.length) return true;
    
    final question = _questions[_currentQuestionIndex];
    return !question.isRequired || _answers.hasAnswer(question.id);
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = context.read<UserProvider>();
      await userProvider.completeOnboarding(answers: _answers);
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const MainNavigationScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete onboarding: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _skipOnboarding() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip Onboarding?'),
        content: const Text(
          'You can skip the questionnaire and start with default stats. '
          'You can always reset your progress later in settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Skip'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final userProvider = context.read<UserProvider>();
        await userProvider.skipOnboarding();
        
        if (mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const MainNavigationScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to skip onboarding: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Icon _getStatIcon(StatType statType) {
    switch (statType) {
      case StatType.strength:
        return const Icon(Icons.fitness_center, color: Colors.red);
      case StatType.agility:
        return const Icon(Icons.directions_run, color: Colors.orange);
      case StatType.endurance:
        return const Icon(Icons.favorite, color: Colors.pink);
      case StatType.intelligence:
        return const Icon(Icons.psychology, color: Colors.blue);
      case StatType.focus:
        return const Icon(Icons.center_focus_strong, color: Colors.purple);
      case StatType.charisma:
        return const Icon(Icons.people, color: Colors.green);
    }
  }

  String _getStatName(StatType statType) {
    switch (statType) {
      case StatType.strength:
        return 'Strength';
      case StatType.agility:
        return 'Agility';
      case StatType.endurance:
        return 'Endurance';
      case StatType.intelligence:
        return 'Intelligence';
      case StatType.focus:
        return 'Focus';
      case StatType.charisma:
        return 'Charisma';
    }
  }
}