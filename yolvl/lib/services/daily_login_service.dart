import 'dart:math';
import 'package:hive/hive.dart';
import '../models/daily_reward.dart';
import '../models/enums.dart';
import '../models/user.dart';
import '../utils/hive_config.dart';

/// Service for managing daily login rewards, streaks, and calendar
/// 
/// Provides comprehensive daily login functionality including:
/// - Streak tracking with automatic reset on missed days
/// - Monthly reward calendar generation
/// - Milestone bonuses and special events
/// - Offline-first data storage using Hive
/// - Hunter rank-based bonus rewards
/// - Grace period for missed logins
class DailyLoginService {
  static const String dailyRewardBoxName = 'daily_reward_box';
  static const String loginStreakKey = 'login_streak';
  static const String lastLoginDateKey = 'last_login_date';
  static const String currentMonthRewardsKey = 'current_month_rewards';
  static const String totalLoginDaysKey = 'total_login_days';
  
  // Grace period for maintaining streak (in hours)
  static const int streakGracePeriodHours = 26;
  
  /// Initialize the daily login service
  static Future<void> initialize() async {
    if (!Hive.isBoxOpen(dailyRewardBoxName)) {
      await Hive.openBox(dailyRewardBoxName);
    }
  }

  /// Get the daily login box
  static Box get _box => HiveConfig.getBox(dailyRewardBoxName);

  /// Get current login streak
  static int getCurrentStreak() {
    return _box.get(loginStreakKey, defaultValue: 0);
  }

  /// Get last login date
  static DateTime? getLastLoginDate() {
    final dateString = _box.get(lastLoginDateKey);
    return dateString != null ? DateTime.parse(dateString) : null;
  }

  /// Get total login days across all time
  static int getTotalLoginDays() {
    return _box.get(totalLoginDaysKey, defaultValue: 0);
  }

  /// Check if user can login today (hasn't already logged in)
  static bool canLoginToday() {
    final lastLogin = getLastLoginDate();
    if (lastLogin == null) return true;

    final today = DateTime.now();
    final lastLoginDate = DateTime(lastLogin.year, lastLogin.month, lastLogin.day);
    final todayDate = DateTime(today.year, today.month, today.day);

    return !lastLoginDate.isAtSameMomentAs(todayDate);
  }

  /// Check if streak should continue based on grace period
  static bool shouldMaintainStreak() {
    final lastLogin = getLastLoginDate();
    if (lastLogin == null) return false;

    final now = DateTime.now();
    final hoursSinceLastLogin = now.difference(lastLogin).inHours;

    return hoursSinceLastLogin <= streakGracePeriodHours;
  }

  /// Calculate current streak considering grace period and missed days
  static int calculateCurrentStreak() {
    final lastLogin = getLastLoginDate();
    if (lastLogin == null) return 0;

    final today = DateTime.now();
    final daysDifference = today.difference(lastLogin).inDays;

    if (daysDifference == 0) {
      // Already logged in today
      return getCurrentStreak();
    } else if (daysDifference == 1 || shouldMaintainStreak()) {
      // Consecutive day or within grace period
      return getCurrentStreak();
    } else {
      // Streak broken
      return 0;
    }
  }

  /// Perform daily login and return the reward
  static Future<DailyReward?> performDailyLogin(User user) async {
    if (!canLoginToday()) {
      return null; // Already logged in today
    }

    final currentStreak = calculateCurrentStreak();
    final newStreak = currentStreak + 1;
    final today = DateTime.now();

    // Calculate streak multiplier based on consecutive days
    final streakMultiplier = _calculateStreakMultiplier(newStreak);

    // Generate today's reward
    final reward = await _generateDailyReward(
      date: today,
      streakDay: newStreak,
      user: user,
      streakMultiplier: streakMultiplier,
    );

    // Update streak and login data
    await _updateLoginData(newStreak, today);

    // Store the reward
    await _storeReward(reward);

    return reward;
  }

  /// Generate daily reward for a specific day
  static Future<DailyReward> _generateDailyReward({
    required DateTime date,
    required int streakDay,
    required User user,
    double streakMultiplier = 1.0,
  }) async {
    final dayOfMonth = date.day;
    final weekday = date.weekday;
    final isWeekend = weekday == DateTime.saturday || weekday == DateTime.sunday;
    final isMilestone = _isMilestoneDay(streakDay);
    final isHoliday = _isHolidayDate(date);

    List<RewardItem> rewards = [];

    // Base EXP reward (scales with user level and streak)
    double baseExp = _calculateBaseExp(user.level, streakDay);
    baseExp *= streakMultiplier;

    if (isHoliday) {
      baseExp *= 1.5; // Holiday bonus
    }

    rewards.add(RewardItem.expBonus(
      baseExp,
      description: 'Daily Login EXP${streakMultiplier > 1.0 ? ' (${streakMultiplier}x Streak)' : ''}',
      isRare: isMilestone,
    ));

    // Weekend bonus
    if (isWeekend) {
      rewards.add(RewardItem.statBoost(
        StatType.endurance,
        0.1 * streakMultiplier,
        description: 'Weekend Rest Bonus',
        isRare: false,
      ));
    }

    // Hunter rank bonus (based on user level)
    if (user.level >= 10 && streakDay % 3 == 0) {
      final rankBonus = _calculateHunterRankBonus(user.level);
      rewards.add(RewardItem.hunterRankBonus(
        rankBonus,
        description: 'Hunter Rank Bonus',
        isRare: false,
      ));
    }

    // Milestone rewards
    if (isMilestone) {
      rewards.addAll(_getMilestoneRewards(streakDay, user));
    }

    // Random stat boost (small chance)
    if (Random().nextDouble() < 0.2) {
      final randomStat = StatType.values[Random().nextInt(StatType.values.length)];
      final boostAmount = (0.05 + Random().nextDouble() * 0.15) * streakMultiplier;
      rewards.add(RewardItem.statBoost(
        randomStat,
        boostAmount,
        description: 'Lucky ${randomStat.name.toUpperCase()} Boost',
        isRare: Random().nextDouble() < 0.1,
      ));
    }

    return DailyReward.forDay(
      date: date,
      dayOfMonth: dayOfMonth,
      streakDay: streakDay,
      rewards: rewards,
      isMilestone: isMilestone,
      isWeekendBonus: isWeekend,
      isHolidayBonus: isHoliday,
      streakMultiplier: streakMultiplier,
    );
  }

  /// Calculate base EXP reward
  static double _calculateBaseExp(int userLevel, int streakDay) {
    double baseExp = 50.0;
    
    // Scale with user level
    baseExp += userLevel * 2.0;
    
    // Slight increase with streak length
    baseExp += min(streakDay * 0.5, 50.0);
    
    return baseExp;
  }

  /// Calculate streak multiplier
  static double _calculateStreakMultiplier(int streak) {
    if (streak <= 3) return 1.0;
    if (streak <= 7) return 1.1;
    if (streak <= 14) return 1.2;
    if (streak <= 21) return 1.3;
    if (streak <= 30) return 1.5;
    return 1.5 + ((streak - 30) ~/ 10) * 0.1; // +0.1 every 10 days after 30
  }

  /// Calculate hunter rank bonus percentage
  static double _calculateHunterRankBonus(int level) {
    if (level < 10) return 0.0;
    if (level < 25) return 5.0;
    if (level < 50) return 10.0;
    if (level < 100) return 15.0;
    return 20.0;
  }

  /// Check if day is a milestone day
  static bool _isMilestoneDay(int streakDay) {
    return streakDay == 1 || 
           streakDay % 7 == 0 || 
           streakDay == 14 || 
           streakDay == 21 || 
           streakDay == 30 ||
           streakDay % 30 == 0;
  }

  /// Check if date is a holiday (simple implementation)
  static bool _isHolidayDate(DateTime date) {
    // New Year's Day
    if (date.month == 1 && date.day == 1) return true;
    
    // Christmas
    if (date.month == 12 && date.day == 25) return true;
    
    // Halloween
    if (date.month == 10 && date.day == 31) return true;
    
    return false;
  }

  /// Get milestone rewards for specific streak days
  static List<RewardItem> _getMilestoneRewards(int streakDay, User user) {
    List<RewardItem> milestoneRewards = [];
    
    switch (streakDay) {
      case 1:
        milestoneRewards.add(RewardItem.specialItem(
          'Hunter License',
          1.0,
          description: 'Welcome to the Hunter Association!',
          isRare: true,
        ));
        break;
        
      case 7:
        milestoneRewards.add(RewardItem.statBoost(
          StatType.strength,
          0.5,
          description: 'Weekly Training Bonus',
          isRare: true,
        ));
        milestoneRewards.add(RewardItem.expBonus(
          100.0,
          description: 'Week 1 Completion Bonus',
          isRare: true,
        ));
        break;
        
      case 14:
        milestoneRewards.add(RewardItem.expBonus(
          200.0,
          description: 'Two Week Milestone',
          isRare: true,
        ));
        milestoneRewards.add(RewardItem.hunterRankBonus(
          10.0,
          description: 'Dedication Bonus',
          isRare: true,
        ));
        break;
        
      case 21:
        milestoneRewards.add(RewardItem.statBoost(
          StatType.focus,
          1.0,
          description: 'Mental Fortitude Bonus',
          isRare: true,
        ));
        milestoneRewards.add(RewardItem.specialItem(
          'Hunter Badge',
          21.0,
          description: 'Three Week Achievement',
          isRare: true,
        ));
        break;
        
      case 30:
        milestoneRewards.add(RewardItem.expBonus(
          500.0,
          description: 'Monthly Master Bonus',
          isRare: true,
        ));
        milestoneRewards.add(RewardItem.streakMultiplier(
          0.2,
          description: 'Mastery Multiplier Boost',
          isRare: true,
        ));
        milestoneRewards.add(RewardItem.specialItem(
          'Elite Hunter Title',
          30.0,
          description: 'Monthly Completion Reward',
          isRare: true,
        ));
        break;
        
      default:
        if (streakDay % 7 == 0) {
          final weekNumber = streakDay ~/ 7;
          milestoneRewards.add(RewardItem.expBonus(
            100.0 + (weekNumber * 25),
            description: 'Week $weekNumber Milestone',
            isRare: true,
          ));
        }
        if (streakDay % 30 == 0) {
          final monthNumber = streakDay ~/ 30;
          milestoneRewards.add(RewardItem.specialItem(
            'Month $monthNumber Champion',
            streakDay.toDouble(),
            description: 'Monthly Champion Title',
            isRare: true,
          ));
        }
        break;
    }
    
    return milestoneRewards;
  }

  /// Update login data after successful login
  static Future<void> _updateLoginData(int newStreak, DateTime loginDate) async {
    await _box.put(loginStreakKey, newStreak);
    await _box.put(lastLoginDateKey, loginDate.toIso8601String());
    
    final totalDays = getTotalLoginDays() + 1;
    await _box.put(totalLoginDaysKey, totalDays);
  }

  /// Store reward in local storage
  static Future<void> _storeReward(DailyReward reward) async {
    final key = 'reward_${reward.date.toIso8601String().split('T')[0]}';
    await _box.put(key, reward.toJson());
  }

  /// Get reward for a specific date
  static DailyReward? getRewardForDate(DateTime date) {
    final key = 'reward_${date.toIso8601String().split('T')[0]}';
    final rewardData = _box.get(key);
    return rewardData != null ? DailyReward.fromJson(Map<String, dynamic>.from(rewardData)) : null;
  }

  /// Claim a reward and apply its effects
  static Future<bool> claimReward(DailyReward reward, User user) async {
    if (reward.isClaimed || !reward.canClaimToday) {
      return false;
    }

    // Apply reward effects to user
    for (final rewardItem in reward.rewards) {
      switch (rewardItem.type) {
        case RewardType.exp:
          user.currentEXP += rewardItem.value;
          break;
          
        case RewardType.statBoost:
          if (rewardItem.statType != null) {
            user.addToStat(rewardItem.statType!, rewardItem.value);
          }
          break;
          
        case RewardType.hunterRankBonus:
          // Apply as EXP bonus for now
          user.currentEXP += rewardItem.value;
          break;
          
        default:
          // Other reward types can be handled by the UI or other services
          break;
      }
    }

    // Mark reward as claimed
    final claimedReward = reward.claim();
    await _storeReward(claimedReward);

    return true;
  }

  /// Generate monthly calendar of rewards
  static List<DailyReward> generateMonthlyCalendar(int year, int month, User user) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final currentStreak = getCurrentStreak();
    final lastLogin = getLastLoginDate();
    
    List<DailyReward> monthlyRewards = [];
    
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      final streakDay = _calculateStreakDayForDate(date, currentStreak, lastLogin);
      final streakMultiplier = _calculateStreakMultiplier(streakDay);
      
      // Check if reward already exists
      final existingReward = getRewardForDate(date);
      if (existingReward != null) {
        monthlyRewards.add(existingReward);
      } else {
        // Generate preview reward (not stored)
        final previewReward = DailyReward.basic(
          date: date,
          dayOfMonth: day,
          streakDay: streakDay,
          baseExp: _calculateBaseExp(user.level, streakDay),
          streakMultiplier: streakMultiplier,
        );
        monthlyRewards.add(previewReward);
      }
    }
    
    return monthlyRewards;
  }

  /// Calculate what the streak day would be for a given date
  static int _calculateStreakDayForDate(DateTime date, int currentStreak, DateTime? lastLogin) {
    if (lastLogin == null) return 1;
    
    final today = DateTime.now();
    final dateOnly = DateTime(date.year, date.month, date.day);
    final todayOnly = DateTime(today.year, today.month, today.day);
    
    if (dateOnly.isBefore(todayOnly)) {
      // Past date - would need historical data
      return max(1, currentStreak - todayOnly.difference(dateOnly).inDays);
    } else if (dateOnly.isAtSameMomentAs(todayOnly)) {
      // Today
      return canLoginToday() ? currentStreak + 1 : currentStreak;
    } else {
      // Future date - estimate based on continuous login
      return currentStreak + todayOnly.difference(dateOnly).inDays.abs() + 1;
    }
  }

  /// Get login statistics
  static Map<String, dynamic> getLoginStatistics() {
    return {
      'currentStreak': getCurrentStreak(),
      'totalLoginDays': getTotalLoginDays(),
      'lastLoginDate': getLastLoginDate(),
      'canLoginToday': canLoginToday(),
      'streakMultiplier': _calculateStreakMultiplier(getCurrentStreak()),
    };
  }

  /// Reset streak (for testing or manual intervention)
  static Future<void> resetStreak() async {
    await _box.put(loginStreakKey, 0);
  }

  /// Clear all daily login data (for testing)
  static Future<void> clearAllData() async {
    await _box.clear();
  }
}