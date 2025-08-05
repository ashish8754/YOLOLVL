import 'package:hive/hive.dart';
import 'enums.dart';

part 'daily_reward.g.dart';

/// Represents different types of rewards that can be given for daily login
@HiveType(typeId: 10)
enum RewardType {
  @HiveField(0)
  exp,
  
  @HiveField(1)
  statBoost,
  
  @HiveField(2)
  achievementProgress,
  
  @HiveField(3)
  specialItem,
  
  @HiveField(4)
  streakMultiplier,
  
  @HiveField(5)
  hunterRankBonus,
}

/// Individual reward item that can be earned through daily login
@HiveType(typeId: 11)
class RewardItem {
  @HiveField(0)
  final RewardType type;
  
  @HiveField(1)
  final double value;
  
  @HiveField(2)
  final StatType? statType; // For stat boosts
  
  @HiveField(3)
  final String? itemName; // For special items
  
  @HiveField(4)
  final String? description;
  
  @HiveField(5)
  final bool isRare; // For special/milestone rewards
  
  RewardItem({
    required this.type,
    required this.value,
    this.statType,
    this.itemName,
    this.description,
    this.isRare = false,
  });

  /// Create an EXP bonus reward
  factory RewardItem.expBonus(double expAmount, {String? description, bool isRare = false}) {
    return RewardItem(
      type: RewardType.exp,
      value: expAmount,
      description: description ?? 'EXP Bonus: +${expAmount.toInt()}',
      isRare: isRare,
    );
  }

  /// Create a stat boost reward
  factory RewardItem.statBoost(StatType statType, double boostAmount, {String? description, bool isRare = false}) {
    return RewardItem(
      type: RewardType.statBoost,
      value: boostAmount,
      statType: statType,
      description: description ?? '${statType.name.toUpperCase()} Boost: +${boostAmount.toStringAsFixed(2)}',
      isRare: isRare,
    );
  }

  /// Create a streak multiplier reward
  factory RewardItem.streakMultiplier(double multiplier, {String? description, bool isRare = false}) {
    return RewardItem(
      type: RewardType.streakMultiplier,
      value: multiplier,
      description: description ?? 'Streak Multiplier: ${multiplier}x',
      isRare: isRare,
    );
  }

  /// Create a special item reward
  factory RewardItem.specialItem(String itemName, double value, {String? description, bool isRare = true}) {
    return RewardItem(
      type: RewardType.specialItem,
      value: value,
      itemName: itemName,
      description: description ?? 'Special Item: $itemName',
      isRare: isRare,
    );
  }

  /// Create a hunter rank bonus reward
  factory RewardItem.hunterRankBonus(double bonus, {String? description, bool isRare = false}) {
    return RewardItem(
      type: RewardType.hunterRankBonus,
      value: bonus,
      description: description ?? 'Hunter Rank Bonus: +${bonus.toInt()}%',
      isRare: isRare,
    );
  }

  /// Get display text for the reward
  String get displayText {
    return description ?? 'Reward: ${value.toStringAsFixed(2)}';
  }

  /// Convert to JSON for backup/export
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'value': value,
      'statType': statType?.name,
      'itemName': itemName,
      'description': description,
      'isRare': isRare,
    };
  }

  /// Create from JSON for backup/import
  factory RewardItem.fromJson(Map<String, dynamic> json) {
    return RewardItem(
      type: RewardType.values.firstWhere((e) => e.name == json['type']),
      value: json['value'].toDouble(),
      statType: json['statType'] != null ? StatType.values.firstWhere((e) => e.name == json['statType']) : null,
      itemName: json['itemName'],
      description: json['description'],
      isRare: json['isRare'] ?? false,
    );
  }
}

/// Daily login reward entry with all reward details and metadata
@HiveType(typeId: 12)
class DailyReward extends HiveObject {
  @HiveField(0)
  final DateTime date;
  
  @HiveField(1)
  final int dayOfMonth;
  
  @HiveField(2)
  final int streakDay;
  
  @HiveField(3)
  final List<RewardItem> rewards;
  
  @HiveField(4)
  final bool isClaimed;
  
  @HiveField(5)
  final DateTime? claimedAt;
  
  @HiveField(6)
  final bool isMilestone; // For special milestone days (7, 14, 21, 30)
  
  @HiveField(7)
  final bool isWeekendBonus;
  
  @HiveField(8)
  final bool isHolidayBonus;
  
  @HiveField(9)
  final double streakMultiplier; // Current streak multiplier
  
  DailyReward({
    required this.date,
    required this.dayOfMonth,
    required this.streakDay,
    required this.rewards,
    this.isClaimed = false,
    this.claimedAt,
    this.isMilestone = false,
    this.isWeekendBonus = false,
    this.isHolidayBonus = false,
    this.streakMultiplier = 1.0,
  });

  /// Create a new daily reward for a specific day
  factory DailyReward.forDay({
    required DateTime date,
    required int dayOfMonth,
    required int streakDay,
    required List<RewardItem> rewards,
    bool isMilestone = false,
    bool isWeekendBonus = false,
    bool isHolidayBonus = false,
    double streakMultiplier = 1.0,
  }) {
    return DailyReward(
      date: DateTime(date.year, date.month, date.day),
      dayOfMonth: dayOfMonth,
      streakDay: streakDay,
      rewards: rewards,
      isMilestone: isMilestone,
      isWeekendBonus: isWeekendBonus,
      isHolidayBonus: isHolidayBonus,
      streakMultiplier: streakMultiplier,
    );
  }

  /// Create a basic daily reward with standard EXP bonus
  factory DailyReward.basic({
    required DateTime date,
    required int dayOfMonth,
    required int streakDay,
    double baseExp = 50.0,
    double streakMultiplier = 1.0,
  }) {
    final weekday = date.weekday;
    final isWeekend = weekday == DateTime.saturday || weekday == DateTime.sunday;
    final isMilestone = _isMilestoneDay(streakDay);
    
    List<RewardItem> rewards = [];
    
    // Base EXP reward with streak multiplier
    final finalExp = baseExp * streakMultiplier;
    rewards.add(RewardItem.expBonus(finalExp, isRare: isMilestone));
    
    // Weekend bonus
    if (isWeekend) {
      rewards.add(RewardItem.statBoost(StatType.endurance, 0.1, description: 'Weekend Rest Bonus', isRare: false));
    }
    
    // Milestone rewards
    if (isMilestone) {
      rewards.addAll(_getMilestoneRewards(streakDay));
    }
    
    return DailyReward(
      date: DateTime(date.year, date.month, date.day),
      dayOfMonth: dayOfMonth,
      streakDay: streakDay,
      rewards: rewards,
      isMilestone: isMilestone,
      isWeekendBonus: isWeekend,
      streakMultiplier: streakMultiplier,
    );
  }

  /// Check if a streak day is a milestone
  static bool _isMilestoneDay(int streakDay) {
    return streakDay % 7 == 0 || streakDay == 1 || streakDay == 14 || streakDay == 21 || streakDay == 30;
  }

  /// Get milestone rewards for specific streak days
  static List<RewardItem> _getMilestoneRewards(int streakDay) {
    List<RewardItem> milestoneRewards = [];
    
    switch (streakDay) {
      case 1:
        milestoneRewards.add(RewardItem.specialItem('Hunter License', 1.0, 
            description: 'Welcome to the Hunter Association!', isRare: true));
        break;
      case 7:
        milestoneRewards.add(RewardItem.statBoost(StatType.strength, 0.5, 
            description: 'Weekly Training Bonus', isRare: true));
        milestoneRewards.add(RewardItem.streakMultiplier(1.1, 
            description: 'Consistency Bonus', isRare: true));
        break;
      case 14:
        milestoneRewards.add(RewardItem.expBonus(200.0, 
            description: 'Two Week Milestone', isRare: true));
        milestoneRewards.add(RewardItem.hunterRankBonus(5.0, 
            description: 'Dedication Bonus', isRare: true));
        break;
      case 21:
        milestoneRewards.add(RewardItem.statBoost(StatType.focus, 1.0, 
            description: 'Mental Fortitude Bonus', isRare: true));
        milestoneRewards.add(RewardItem.specialItem('Hunter Badge', 21.0, 
            description: 'Three Week Achievement', isRare: true));
        break;
      case 30:
        milestoneRewards.add(RewardItem.expBonus(500.0, 
            description: 'Monthly Master Bonus', isRare: true));
        milestoneRewards.add(RewardItem.streakMultiplier(1.5, 
            description: 'Mastery Multiplier', isRare: true));
        milestoneRewards.add(RewardItem.specialItem('Elite Hunter Title', 30.0, 
            description: 'Monthly Completion Reward', isRare: true));
        break;
      default:
        if (streakDay % 7 == 0) {
          milestoneRewards.add(RewardItem.expBonus(100.0 + (streakDay / 7) * 25, 
              description: 'Weekly Milestone', isRare: true));
        }
        break;
    }
    
    return milestoneRewards;
  }

  /// Claim this reward and return a copy with claimed status
  DailyReward claim() {
    return DailyReward(
      date: date,
      dayOfMonth: dayOfMonth,
      streakDay: streakDay,
      rewards: List.from(rewards),
      isClaimed: true,
      claimedAt: DateTime.now(),
      isMilestone: isMilestone,
      isWeekendBonus: isWeekendBonus,
      isHolidayBonus: isHolidayBonus,
      streakMultiplier: streakMultiplier,
    );
  }

  /// Get total EXP value from all rewards
  double get totalExpReward {
    return rewards
        .where((r) => r.type == RewardType.exp)
        .fold(0.0, (sum, r) => sum + r.value);
  }

  /// Get all stat boosts from rewards
  Map<StatType, double> get statBoosts {
    Map<StatType, double> boosts = {};
    for (var reward in rewards) {
      if (reward.type == RewardType.statBoost && reward.statType != null) {
        boosts[reward.statType!] = (boosts[reward.statType!] ?? 0.0) + reward.value;
      }
    }
    return boosts;
  }

  /// Get special items from rewards
  List<String> get specialItems {
    return rewards
        .where((r) => r.type == RewardType.specialItem && r.itemName != null)
        .map((r) => r.itemName!)
        .toList();
  }

  /// Check if reward can be claimed today
  bool get canClaimToday {
    final today = DateTime.now();
    final rewardDate = DateTime(date.year, date.month, date.day);
    final todayDate = DateTime(today.year, today.month, today.day);
    return !isClaimed && rewardDate.isAtSameMomentAs(todayDate);
  }

  /// Get display description for the reward
  String get displayDescription {
    if (isMilestone) {
      return 'Milestone Day $streakDay - Special Rewards!';
    } else if (isWeekendBonus) {
      return 'Weekend Bonus - Day $streakDay';
    } else if (isHolidayBonus) {
      return 'Holiday Special - Day $streakDay';
    } else {
      return 'Day $streakDay Login Reward';
    }
  }

  /// Convert to JSON for backup/export
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'dayOfMonth': dayOfMonth,
      'streakDay': streakDay,
      'rewards': rewards.map((r) => r.toJson()).toList(),
      'isClaimed': isClaimed,
      'claimedAt': claimedAt?.toIso8601String(),
      'isMilestone': isMilestone,
      'isWeekendBonus': isWeekendBonus,
      'isHolidayBonus': isHolidayBonus,
      'streakMultiplier': streakMultiplier,
    };
  }

  /// Create from JSON for backup/import
  factory DailyReward.fromJson(Map<String, dynamic> json) {
    return DailyReward(
      date: DateTime.parse(json['date']),
      dayOfMonth: json['dayOfMonth'],
      streakDay: json['streakDay'],
      rewards: (json['rewards'] as List).map((r) => RewardItem.fromJson(r)).toList(),
      isClaimed: json['isClaimed'],
      claimedAt: json['claimedAt'] != null ? DateTime.parse(json['claimedAt']) : null,
      isMilestone: json['isMilestone'] ?? false,
      isWeekendBonus: json['isWeekendBonus'] ?? false,
      isHolidayBonus: json['isHolidayBonus'] ?? false,
      streakMultiplier: json['streakMultiplier'] ?? 1.0,
    );
  }

  @override
  String toString() {
    return 'DailyReward(date: $date, streakDay: $streakDay, rewards: ${rewards.length}, claimed: $isClaimed)';
  }
}