import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/daily_reward.dart';
import '../models/user.dart';
import '../providers/daily_login_provider.dart';
import '../providers/user_provider.dart';
import '../theme/solo_leveling_theme.dart';
import '../theme/glassmorphism_effects.dart';
import 'system_notification.dart';

/// Reward Calendar Widget with monthly view and rewards
/// 
/// Displays a monthly calendar showing daily login rewards, claimed status,
/// and milestone bonuses. Features Solo Leveling theming with glassmorphism effects.
class RewardCalendar extends StatefulWidget {
  final bool showHeader;
  final bool allowNavigation;
  final Function(DailyReward)? onRewardTap;

  const RewardCalendar({
    super.key,
    this.showHeader = true,
    this.allowNavigation = true,
    this.onRewardTap,
  });

  @override
  State<RewardCalendar> createState() => _RewardCalendarState();
}

class _RewardCalendarState extends State<RewardCalendar>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<DailyLoginProvider, UserProvider>(
      builder: (context, dailyLoginProvider, userProvider, child) {
        return GlassmorphismEffects.glassmorphicContainer(
          blur: 15,
          opacity: 0.1,
          context: context,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: SoloLevelingColors.electricBlue.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                if (widget.showHeader)
                  _buildHeader(dailyLoginProvider, userProvider),
                _buildCalendarGrid(dailyLoginProvider),
                _buildLegend(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(DailyLoginProvider provider, UserProvider userProvider) {
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        gradient: SoloLevelingGradients.systemPanel,
      ),
      child: Row(
        children: [
          if (widget.allowNavigation)
            IconButton(
              onPressed: _isNavigating ? null : () => _navigateToPrevious(provider, userProvider),
              icon: Icon(
                Icons.chevron_left,
                color: SoloLevelingColors.silverMist,
              ),
            ),
          
          Expanded(
            child: Column(
              children: [
                Icon(
                  Icons.calendar_month,
                  size: 24,
                  color: SoloLevelingColors.electricBlue,
                ),
                const SizedBox(height: 4),
                Text(
                  '${monthNames[provider.currentCalendarMonth - 1]} ${provider.currentCalendarYear}',
                  style: SoloLevelingTypography.hunterSubtitle.copyWith(
                    fontSize: 18,
                    color: SoloLevelingColors.ghostWhite,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'Daily Login Calendar',
                  style: SoloLevelingTypography.systemNotification.copyWith(
                    fontSize: 12,
                    color: SoloLevelingColors.silverMist,
                  ),
                ),
              ],
            ),
          ),
          
          if (widget.allowNavigation)
            IconButton(
              onPressed: _isNavigating ? null : () => _navigateToNext(provider, userProvider),
              icon: Icon(
                Icons.chevron_right,
                color: SoloLevelingColors.silverMist,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(DailyLoginProvider provider) {
    if (provider.isLoadingCalendar) {
      return Container(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  SoloLevelingColors.electricBlue,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading Calendar...',
                style: SoloLevelingTypography.systemNotification.copyWith(
                  color: SoloLevelingColors.silverMist,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: _slideAnimation.value * MediaQuery.of(context).size.width,
          child: _buildCalendarContent(provider),
        );
      },
    );
  }

  Widget _buildCalendarContent(DailyLoginProvider provider) {
    final calendar = provider.monthlyCalendar;
    final today = DateTime.now();
    final currentMonth = provider.currentCalendarMonth;
    final currentYear = provider.currentCalendarYear;

    // Get first day of month and its weekday
    final firstDay = DateTime(currentYear, currentMonth, 1);
    final firstWeekday = firstDay.weekday % 7; // Convert to 0-6 (Sunday = 0)
    final daysInMonth = DateTime(currentYear, currentMonth + 1, 0).day;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Week day headers
          _buildWeekHeaders(),
          const SizedBox(height: 8),
          
          // Calendar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: 42, // 6 weeks * 7 days
            itemBuilder: (context, index) {
              final dayIndex = index - firstWeekday + 1;
              
              if (dayIndex < 1 || dayIndex > daysInMonth) {
                return const SizedBox(); // Empty cell
              }

              final date = DateTime(currentYear, currentMonth, dayIndex);
              final reward = calendar.isNotEmpty && dayIndex <= calendar.length
                  ? calendar[dayIndex - 1]
                  : null;

              final isToday = date.day == today.day &&
                  date.month == today.month &&
                  date.year == today.year;

              return _buildCalendarDay(date, reward, isToday);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeekHeaders() {
    const weekDays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    
    return Row(
      children: weekDays.map((day) => 
        Expanded(
          child: Center(
            child: Text(
              day,
              style: SoloLevelingTypography.statLabel.copyWith(
                fontSize: 12,
                color: SoloLevelingColors.silverMist,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ).toList(),
    );
  }

  Widget _buildCalendarDay(DateTime date, DailyReward? reward, bool isToday) {
    final isPast = date.isBefore(DateTime.now().subtract(const Duration(days: 1)));
    final isFuture = date.isAfter(DateTime.now());
    final canClaim = reward?.canClaimToday ?? false;
    final isClaimed = reward?.isClaimed ?? false;

    Color backgroundColor;
    Color borderColor;
    Color textColor;
    
    if (isToday) {
      backgroundColor = SoloLevelingColors.electricBlue.withValues(alpha: 0.2);
      borderColor = SoloLevelingColors.electricBlue;
      textColor = SoloLevelingColors.electricBlue;
    } else if (isClaimed) {
      backgroundColor = SoloLevelingColors.hunterGreen.withValues(alpha: 0.2);
      borderColor = SoloLevelingColors.hunterGreen;
      textColor = SoloLevelingColors.hunterGreen;
    } else if (canClaim) {
      backgroundColor = SoloLevelingColors.mysticPurple.withValues(alpha: 0.2);
      borderColor = SoloLevelingColors.mysticPurple;
      textColor = SoloLevelingColors.mysticPurple;
    } else if (isFuture) {
      backgroundColor = SoloLevelingColors.shadowDepth;
      borderColor = SoloLevelingColors.shadowGray;
      textColor = SoloLevelingColors.shadowGray;
    } else {
      backgroundColor = SoloLevelingColors.deepShadow;
      borderColor = SoloLevelingColors.shadowGray;
      textColor = SoloLevelingColors.silverMist;
    }

    return GestureDetector(
      onTap: reward != null ? () => _onRewardTap(reward) : null,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: borderColor,
            width: isToday ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            // Day number
            Center(
              child: Text(
                '${date.day}',
                style: SoloLevelingTypography.systemNotification.copyWith(
                  fontSize: 14,
                  color: textColor,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            
            // Reward indicators
            if (reward != null) ...[
              // Milestone indicator
              if (reward.isMilestone)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Icon(
                    Icons.star,
                    size: 12,
                    color: SoloLevelingColors.goldRank,
                  ),
                ),
              
              // Weekend bonus indicator
              if (reward.isWeekendBonus)
                Positioned(
                  top: 2,
                  left: 2,
                  child: Icon(
                    Icons.weekend,
                    size: 10,
                    color: SoloLevelingColors.mysticPurple,
                  ),
                ),
              
              // Claimed checkmark
              if (isClaimed)
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Icon(
                    Icons.check_circle,
                    size: 12,
                    color: SoloLevelingColors.hunterGreen,
                  ),
                ),
              
              // Notification dot for claimable rewards
              if (canClaim)
                Positioned(
                  bottom: 2,
                  left: 2,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: SoloLevelingColors.hunterGreen,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        color: SoloLevelingColors.shadowDepth.withValues(alpha: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Legend',
            style: SoloLevelingTypography.statLabel.copyWith(
              fontSize: 12,
              color: SoloLevelingColors.silverMist,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildLegendItem(
                Icons.circle,
                'Today',
                SoloLevelingColors.electricBlue,
              ),
              _buildLegendItem(
                Icons.check_circle,
                'Claimed',
                SoloLevelingColors.hunterGreen,
              ),
              _buildLegendItem(
                Icons.star,
                'Milestone',
                SoloLevelingColors.goldRank,
              ),
              _buildLegendItem(
                Icons.weekend,
                'Weekend',
                SoloLevelingColors.mysticPurple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: SoloLevelingTypography.statLabel.copyWith(
            fontSize: 10,
            color: SoloLevelingColors.silverMist,
          ),
        ),
      ],
    );
  }

  void _onRewardTap(DailyReward reward) {
    if (widget.onRewardTap != null) {
      widget.onRewardTap!(reward);
    } else {
      _showRewardDetails(reward);
    }
  }

  void _showRewardDetails(DailyReward reward) {
    showDialog(
      context: context,
      builder: (context) => RewardDetailsDialog(reward: reward),
    );
  }

  Future<void> _navigateToPrevious(DailyLoginProvider provider, UserProvider userProvider) async {
    if (_isNavigating) return;
    
    setState(() {
      _isNavigating = true;
    });

    await _slideController.forward();
    
    final user = userProvider.currentUser;
    if (user != null) {
      await provider.previousMonth(user);
    }
    
    _slideController.reverse();
    
    setState(() {
      _isNavigating = false;
    });
  }

  Future<void> _navigateToNext(DailyLoginProvider provider, UserProvider userProvider) async {
    if (_isNavigating) return;
    
    setState(() {
      _isNavigating = true;
    });

    await _slideController.forward();
    
    final user = userProvider.currentUser;
    if (user != null) {
      await provider.nextMonth(user);
    }
    
    _slideController.reverse();
    
    setState(() {
      _isNavigating = false;
    });
  }
}

/// Dialog showing detailed reward information
class RewardDetailsDialog extends StatelessWidget {
  final DailyReward reward;

  const RewardDetailsDialog({
    super.key,
    required this.reward,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassmorphismEffects.glassmorphicContainer(
        blur: 20,
        opacity: 0.1,
        context: context,
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: SoloLevelingColors.electricBlue.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildRewardsList(),
              const SizedBox(height: 16),
              _buildCloseButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        if (reward.isMilestone)
          Icon(
            Icons.star,
            size: 32,
            color: SoloLevelingColors.goldRank,
          )
        else
          Icon(
            Icons.card_giftcard,
            size: 32,
            color: SoloLevelingColors.electricBlue,
          ),
        const SizedBox(height: 8),
        Text(
          reward.displayDescription,
          style: SoloLevelingTypography.hunterSubtitle.copyWith(
            fontSize: 18,
            color: SoloLevelingColors.ghostWhite,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          '${reward.date.day}/${reward.date.month}/${reward.date.year}',
          style: SoloLevelingTypography.systemNotification.copyWith(
            fontSize: 14,
            color: SoloLevelingColors.silverMist,
          ),
        ),
      ],
    );
  }

  Widget _buildRewardsList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: SoloLevelingColors.shadowDepth,
        border: Border.all(
          color: SoloLevelingColors.shadowGray,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rewards:',
            style: SoloLevelingTypography.statLabel.copyWith(
              fontSize: 14,
              color: SoloLevelingColors.silverMist,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...reward.rewards.map((rewardItem) => _buildRewardItem(rewardItem)),
        ],
      ),
    );
  }

  Widget _buildRewardItem(RewardItem rewardItem) {
    IconData icon;
    Color color;
    
    switch (rewardItem.type) {
      case RewardType.exp:
        icon = Icons.flash_on;
        color = SoloLevelingColors.electricBlue;
        break;
      case RewardType.statBoost:
        icon = Icons.trending_up;
        color = SoloLevelingColors.hunterGreen;
        break;
      case RewardType.specialItem:
        icon = Icons.star;
        color = SoloLevelingColors.mysticPurple;
        break;
      case RewardType.streakMultiplier:
        icon = Icons.close;
        color = SoloLevelingColors.goldRank;
        break;
      default:
        icon = Icons.card_giftcard;
        color = SoloLevelingColors.silverMist;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              rewardItem.displayText,
              style: SoloLevelingTypography.systemNotification.copyWith(
                fontSize: 14,
                color: rewardItem.isRare 
                    ? SoloLevelingColors.mysticPurple 
                    : SoloLevelingColors.ghostWhite,
              ),
            ),
          ),
          if (rewardItem.isRare)
            Icon(
              Icons.auto_awesome,
              size: 16,
              color: SoloLevelingColors.mysticPurple,
            ),
        ],
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).pop(),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          backgroundColor: SoloLevelingColors.electricBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          'CLOSE',
          style: SoloLevelingTypography.systemNotification.copyWith(
            color: SoloLevelingColors.pureLight,
          ),
        ),
      ),
    );
  }
}