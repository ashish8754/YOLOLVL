import 'package:flutter/foundation.dart';
import '../models/daily_reward.dart';
import '../models/user.dart';
import '../services/daily_login_service.dart';

/// Provider for managing daily login state and rewards
/// 
/// Provides reactive state management for daily login functionality including:
/// - Login streak tracking
/// - Daily reward management
/// - Monthly calendar state
/// - Reward claiming mechanics
/// - Integration with user progression system
class DailyLoginProvider extends ChangeNotifier {
  // State variables
  int _currentStreak = 0;
  int _totalLoginDays = 0;
  DateTime? _lastLoginDate;
  bool _canLoginToday = true;
  double _streakMultiplier = 1.0;
  
  // Daily reward state
  DailyReward? _todayReward;
  bool _hasClaimedToday = false;
  bool _isClaimingReward = false;
  
  // Monthly calendar state
  List<DailyReward> _monthlyCalendar = [];
  int _currentCalendarYear = DateTime.now().year;
  int _currentCalendarMonth = DateTime.now().month;
  bool _isLoadingCalendar = false;
  
  // Error state
  String? _errorMessage;
  
  // Getters
  int get currentStreak => _currentStreak;
  int get totalLoginDays => _totalLoginDays;
  DateTime? get lastLoginDate => _lastLoginDate;
  bool get canLoginToday => _canLoginToday;
  double get streakMultiplier => _streakMultiplier;
  
  DailyReward? get todayReward => _todayReward;
  bool get hasClaimedToday => _hasClaimedToday;
  bool get isClaimingReward => _isClaimingReward;
  
  List<DailyReward> get monthlyCalendar => _monthlyCalendar;
  int get currentCalendarYear => _currentCalendarYear;
  int get currentCalendarMonth => _currentCalendarMonth;
  bool get isLoadingCalendar => _isLoadingCalendar;
  
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  
  /// Initialize the provider with current data
  Future<void> initialize() async {
    try {
      await DailyLoginService.initialize();
      await _refreshLoginState();
      await _refreshMonthlyCalendar();
    } catch (e) {
      _setError('Failed to initialize daily login system: $e');
    }
  }

  /// Refresh login state from service
  Future<void> _refreshLoginState() async {
    try {
      final stats = DailyLoginService.getLoginStatistics();
      
      _currentStreak = (stats['currentStreak'] as int?) ?? 0;
      _totalLoginDays = (stats['totalLoginDays'] as int?) ?? 0;
      _lastLoginDate = stats['lastLoginDate'] as DateTime?;
      _canLoginToday = (stats['canLoginToday'] as bool?) ?? true;
      _streakMultiplier = (stats['streakMultiplier'] as double?) ?? 1.0;
      
      // Check if today's reward exists and is claimed
      final today = DateTime.now();
      _todayReward = DailyLoginService.getRewardForDate(today);
      _hasClaimedToday = _todayReward?.isClaimed ?? false;
      
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Failed to refresh login state: $e');
    }
  }

  /// Perform daily login and get reward
  Future<DailyReward?> performDailyLogin(User user) async {
    if (!_canLoginToday) {
      _setError('Already logged in today');
      return null;
    }

    try {
      _clearError();
      
      final reward = await DailyLoginService.performDailyLogin(user);
      if (reward != null) {
        _todayReward = reward;
        _currentStreak++;
        _totalLoginDays++;
        _lastLoginDate = DateTime.now();
        _canLoginToday = false;
        _streakMultiplier = DailyLoginService.calculateCurrentStreak().toDouble();
        
        notifyListeners();
        
        // Refresh calendar to show updated rewards
        await _refreshMonthlyCalendar();
      } else {
        _setError('Failed to generate daily login reward');
      }
      
      return reward;
    } catch (e) {
      _setError('Failed to perform daily login: $e');
      return null;
    }
  }

  /// Claim a daily reward
  Future<bool> claimReward(DailyReward reward, User user) async {
    if (_isClaimingReward) return false;
    
    try {
      _isClaimingReward = true;
      _clearError();
      notifyListeners();
      
      final success = await DailyLoginService.claimReward(reward, user);
      
      if (success) {
        // Update the reward in our state
        if (_todayReward?.date.day == reward.date.day &&
            _todayReward?.date.month == reward.date.month &&
            _todayReward?.date.year == reward.date.year) {
          _todayReward = reward.claim();
          _hasClaimedToday = true;
        }
        
        // Update monthly calendar
        final rewardIndex = _monthlyCalendar.indexWhere((r) =>
            r.date.day == reward.date.day &&
            r.date.month == reward.date.month &&
            r.date.year == reward.date.year);
        
        if (rewardIndex >= 0) {
          _monthlyCalendar[rewardIndex] = reward.claim();
        }
        
        notifyListeners();
        return true;
      } else {
        _setError('Failed to claim reward');
        return false;
      }
    } catch (e) {
      _setError('Error claiming reward: $e');
      return false;
    } finally {
      _isClaimingReward = false;
      notifyListeners();
    }
  }

  /// Refresh monthly calendar
  Future<void> _refreshMonthlyCalendar() async {
    if (_isLoadingCalendar) return;
    
    try {
      _isLoadingCalendar = true;
      notifyListeners();
      
      // We need a user object to generate calendar
      // This would normally come from UserProvider
      // For now, create a minimal user for calendar generation
      final tempUser = User.create(id: 'temp', name: 'User');
      
      final calendar = DailyLoginService.generateMonthlyCalendar(
        _currentCalendarYear,
        _currentCalendarMonth,
        tempUser,
      );
      
      // Ensure we have a proper list of DailyReward objects
      _monthlyCalendar = List<DailyReward>.from(calendar);
      
      _clearError();
    } catch (e) {
      _setError('Failed to load monthly calendar: $e');
      _monthlyCalendar = []; // Reset to empty list on error
    } finally {
      _isLoadingCalendar = false;
      notifyListeners();
    }
  }

  /// Load calendar for specific month
  Future<void> loadCalendarForMonth(int year, int month, User user) async {
    if (_isLoadingCalendar) return;
    
    try {
      _isLoadingCalendar = true;
      _currentCalendarYear = year;
      _currentCalendarMonth = month;
      notifyListeners();
      
      final calendar = DailyLoginService.generateMonthlyCalendar(year, month, user);
      _monthlyCalendar = List<DailyReward>.from(calendar);
      
      _clearError();
    } catch (e) {
      _setError('Failed to load calendar for $year-$month: $e');
      _monthlyCalendar = []; // Reset to empty list on error
    } finally {
      _isLoadingCalendar = false;
      notifyListeners();
    }
  }

  /// Navigate to previous month
  Future<void> previousMonth(User user) async {
    int newMonth = _currentCalendarMonth - 1;
    int newYear = _currentCalendarYear;
    
    if (newMonth < 1) {
      newMonth = 12;
      newYear--;
    }
    
    await loadCalendarForMonth(newYear, newMonth, user);
  }

  /// Navigate to next month
  Future<void> nextMonth(User user) async {
    int newMonth = _currentCalendarMonth + 1;
    int newYear = _currentCalendarYear;
    
    if (newMonth > 12) {
      newMonth = 1;
      newYear++;
    }
    
    await loadCalendarForMonth(newYear, newMonth, user);
  }

  /// Go to current month
  Future<void> goToCurrentMonth(User user) async {
    final now = DateTime.now();
    await loadCalendarForMonth(now.year, now.month, user);
  }

  /// Get reward for specific date
  DailyReward? getRewardForDate(DateTime date) {
    try {
      return _monthlyCalendar.firstWhere(
        (reward) => 
            reward.date.day == date.day &&
            reward.date.month == date.month &&
            reward.date.year == date.year,
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if date has claimable reward
  bool hasClaimableReward(DateTime date) {
    final reward = getRewardForDate(date);
    return reward != null && reward.canClaimToday && !reward.isClaimed;
  }

  /// Get streak status message
  String getStreakStatusMessage() {
    if (_currentStreak == 0) {
      return 'Start your streak today!';
    } else if (_currentStreak == 1) {
      return 'Great start! Keep it going!';
    } else if (_currentStreak < 7) {
      return 'Building momentum! $_currentStreak days strong!';
    } else if (_currentStreak < 30) {
      return 'Impressive streak! $_currentStreak days in a row!';
    } else {
      return 'Legendary dedication! $_currentStreak days of consistency!';
    }
  }

  /// Get next milestone information
  Map<String, dynamic> getNextMilestone() {
    final nextMilestones = [7, 14, 21, 30, 60, 90, 100];
    
    for (int milestone in nextMilestones) {
      if (_currentStreak < milestone) {
        return {
          'days': milestone,
          'remaining': milestone - _currentStreak,
          'progress': _currentStreak / milestone,
        };
      }
    }
    
    // Beyond major milestones, show next 10-day increment
    final nextIncrement = ((_currentStreak ~/ 10) + 1) * 10;
    return {
      'days': nextIncrement,
      'remaining': nextIncrement - _currentStreak,
      'progress': _currentStreak / nextIncrement,
    };
  }

  /// Reset streak (for testing or admin purposes)
  Future<void> resetStreak() async {
    try {
      await DailyLoginService.resetStreak();
      await _refreshLoginState();
      await _refreshMonthlyCalendar();
    } catch (e) {
      _setError('Failed to reset streak: $e');
    }
  }

  /// Force refresh all data
  Future<void> refresh(User user) async {
    await _refreshLoginState();
    await loadCalendarForMonth(_currentCalendarYear, _currentCalendarMonth, user);
  }

  /// Set error message
  void _setError(String message) {
    _errorMessage = message;
    if (kDebugMode) {
      print('DailyLoginProvider Error: $message');
    }
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Clear error manually
  void clearError() {
    _clearError();
  }

  @override
  void dispose() {
    super.dispose();
  }
}