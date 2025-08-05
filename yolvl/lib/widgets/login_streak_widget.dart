import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/daily_login_provider.dart';
import '../theme/solo_leveling_theme.dart';
import '../theme/glassmorphism_effects.dart';
import 'daily_login_dialog.dart';

/// Login Streak Widget displaying current streak status
/// 
/// Shows current login streak, progress to next milestone, and quick access
/// to daily login dialog. Features glassmorphism design and animated progress bars.
class LoginStreakWidget extends StatefulWidget {
  final bool showTitle;
  final bool isCompact;
  final VoidCallback? onTap;

  const LoginStreakWidget({
    super.key,
    this.showTitle = true,
    this.isCompact = false,
    this.onTap,
  });

  @override
  State<LoginStreakWidget> createState() => _LoginStreakWidgetState();
}

class _LoginStreakWidgetState extends State<LoginStreakWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));

    _pulseController.repeat(reverse: true);
    _progressController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DailyLoginProvider>(
      builder: (context, dailyLoginProvider, child) {
        if (widget.isCompact) {
          return _buildCompactWidget(dailyLoginProvider);
        } else {
          return _buildFullWidget(dailyLoginProvider);
        }
      },
    );
  }

  Widget _buildFullWidget(DailyLoginProvider provider) {
    return GestureDetector(
      onTap: widget.onTap ?? () => _showDailyLoginDialog(context),
      child: GlassmorphismEffects.glassmorphicContainer(
        blur: 15,
        opacity: 0.1,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _getStreakColor(provider.currentStreak).withValues(alpha: 0.3),
              width: 1,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getStreakColor(provider.currentStreak).withValues(alpha: 0.1),
                SoloLevelingColors.voidBlack.withValues(alpha: 0.3),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.showTitle) ...[
                _buildHeader(provider),
                const SizedBox(height: 16),
              ],
              _buildStreakDisplay(provider),
              const SizedBox(height: 16),
              _buildProgressSection(provider),
              const SizedBox(height: 12),
              _buildActionButton(provider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactWidget(DailyLoginProvider provider) {
    return GestureDetector(
      onTap: widget.onTap ?? () => _showDailyLoginDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: SoloLevelingColors.shadowDepth,
          border: Border.all(
            color: _getStreakColor(provider.currentStreak).withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: provider.canLoginToday ? _pulseAnimation.value : 1.0,
                  child: Icon(
                    Icons.local_fire_department,
                    size: 20,
                    color: _getStreakColor(provider.currentStreak),
                  ),
                );
              },
            ),
            const SizedBox(width: 6),
            Text(
              '${provider.currentStreak}',
              style: SoloLevelingTypography.statValue.copyWith(
                fontSize: 16,
                color: _getStreakColor(provider.currentStreak),
              ),
            ),
            if (provider.canLoginToday) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.notification_important,
                size: 16,
                color: SoloLevelingColors.hunterGreen,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(DailyLoginProvider provider) {
    return Row(
      children: [
        Icon(
          Icons.local_fire_department,
          size: 24,
          color: _getStreakColor(provider.currentStreak),
        ),
        const SizedBox(width: 8),
        Text(
          'Login Streak',
          style: SoloLevelingTypography.hunterSubtitle.copyWith(
            fontSize: 18,
            color: SoloLevelingColors.ghostWhite,
          ),
        ),
        const Spacer(),
        if (provider.canLoginToday)
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: SoloLevelingColors.hunterGreen,
                  ),
                  child: Text(
                    'READY',
                    style: SoloLevelingTypography.systemNotification.copyWith(
                      fontSize: 10,
                      color: SoloLevelingColors.pureLight,
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildStreakDisplay(DailyLoginProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Current Streak',
            '${provider.currentStreak}',
            'days',
            _getStreakColor(provider.currentStreak),
            Icons.local_fire_department,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Multiplier',
            '${provider.streakMultiplier.toStringAsFixed(1)}',
            'x bonus',
            SoloLevelingColors.mysticPurple,
            Icons.trending_up,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String suffix, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: SoloLevelingColors.shadowDepth,
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: SoloLevelingTypography.statValue.copyWith(
              fontSize: 22,
              color: color,
            ),
          ),
          Text(
            suffix,
            style: SoloLevelingTypography.statLabel.copyWith(
              fontSize: 10,
              color: SoloLevelingColors.silverMist,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: SoloLevelingTypography.statLabel.copyWith(
              fontSize: 11,
              color: SoloLevelingColors.shadowGray,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(DailyLoginProvider provider) {
    final milestoneInfo = provider.getNextMilestone();
    final progress = milestoneInfo['progress'] as double;
    final remaining = milestoneInfo['remaining'] as int;
    final nextMilestone = milestoneInfo['days'] as int;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Next Milestone',
              style: SoloLevelingTypography.statLabel.copyWith(
                fontSize: 12,
                color: SoloLevelingColors.silverMist,
              ),
            ),
            Text(
              '$remaining days to $nextMilestone',
              style: SoloLevelingTypography.statLabel.copyWith(
                fontSize: 12,
                color: SoloLevelingColors.electricBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return _buildProgressBar(progress * _progressAnimation.value);
          },
        ),
      ],
    );
  }

  Widget _buildProgressBar(double progress) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: SoloLevelingColors.deepShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation<Color>(
            _getProgressColor(progress),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(DailyLoginProvider provider) {
    if (provider.canLoginToday) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _showDailyLoginDialog(context),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 10),
            backgroundColor: SoloLevelingColors.hunterGreen,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.login,
                size: 16,
                color: SoloLevelingColors.pureLight,
              ),
              const SizedBox(width: 8),
              Text(
                'CLAIM DAILY REWARD',
                style: SoloLevelingTypography.systemNotification.copyWith(
                  fontSize: 14,
                  color: SoloLevelingColors.pureLight,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: SoloLevelingColors.deepShadow,
          border: Border.all(
            color: SoloLevelingColors.shadowGray,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: 16,
              color: SoloLevelingColors.hunterGreen,
            ),
            const SizedBox(width: 8),
            Text(
              'REWARD CLAIMED TODAY',
              style: SoloLevelingTypography.systemNotification.copyWith(
                fontSize: 14,
                color: SoloLevelingColors.silverMist,
              ),
            ),
          ],
        ),
      );
    }
  }

  Color _getStreakColor(int streak) {
    if (streak == 0) return SoloLevelingColors.shadowGray;
    if (streak < 7) return SoloLevelingColors.hunterGreen;
    if (streak < 14) return SoloLevelingColors.electricBlue;
    if (streak < 30) return SoloLevelingColors.mysticPurple;
    return SoloLevelingColors.goldRank;
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.3) return SoloLevelingColors.hunterGreen;
    if (progress < 0.7) return SoloLevelingColors.electricBlue;
    return SoloLevelingColors.mysticPurple;
  }

  void _showDailyLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const DailyLoginDialog(showOnStartup: false),
    );
  }
}

/// Simplified streak indicator for app bars or compact spaces
class StreakIndicator extends StatelessWidget {
  final int streak;
  final bool hasNotification;
  final VoidCallback? onTap;

  const StreakIndicator({
    super.key,
    required this.streak,
    this.hasNotification = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: _getStreakColor(streak).withValues(alpha: 0.2),
          border: Border.all(
            color: _getStreakColor(streak).withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department,
              size: 16,
              color: _getStreakColor(streak),
            ),
            const SizedBox(width: 4),
            Text(
              '$streak',
              style: SoloLevelingTypography.statValue.copyWith(
                fontSize: 14,
                color: _getStreakColor(streak),
              ),
            ),
            if (hasNotification) ...[
              const SizedBox(width: 4),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: SoloLevelingColors.hunterGreen,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStreakColor(int streak) {
    if (streak == 0) return SoloLevelingColors.shadowGray;
    if (streak < 7) return SoloLevelingColors.hunterGreen;
    if (streak < 14) return SoloLevelingColors.electricBlue;
    if (streak < 30) return SoloLevelingColors.mysticPurple;
    return SoloLevelingColors.goldRank;
  }
}