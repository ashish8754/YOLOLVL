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

/// Daily Login Dialog with Solo Leveling theming
/// 
/// Epic modal dialog that appears on app startup to handle daily login rewards.
/// Features glassmorphism effects, particle animations, and System-style notifications.
class DailyLoginDialog extends StatefulWidget {
  final VoidCallback? onClose;
  final bool showOnStartup;

  const DailyLoginDialog({
    super.key,
    this.onClose,
    this.showOnStartup = true,
  });

  /// Show daily login dialog if needed
  static Future<void> showIfNeeded(BuildContext context) async {
    final dailyLoginProvider = context.read<DailyLoginProvider>();
    
    if (dailyLoginProvider.canLoginToday) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const DailyLoginDialog(showOnStartup: true),
      );
    }
  }

  @override
  State<DailyLoginDialog> createState() => _DailyLoginDialogState();
}

class _DailyLoginDialogState extends State<DailyLoginDialog>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _particleController;
  late AnimationController _rewardController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _particleAnimation;
  
  DailyReward? _todayReward;
  bool _isClaimingReward = false;
  bool _hasClaimedReward = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadTodayReward();
  }

  void _initializeAnimations() {
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _rewardController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.elasticOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeOutCubic,
    ));

    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _particleController,
      curve: Curves.easeInOut,
    ));

    _mainController.forward();
    _particleController.repeat();
  }

  void _loadTodayReward() {
    final dailyLoginProvider = context.read<DailyLoginProvider>();
    _todayReward = dailyLoginProvider.todayReward;
    _hasClaimedReward = dailyLoginProvider.hasClaimedToday;
  }

  @override
  void dispose() {
    _mainController.dispose();
    _particleController.dispose();
    _rewardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<DailyLoginProvider, UserProvider>(
      builder: (context, dailyLoginProvider, userProvider, child) {
        return AnimatedBuilder(
          animation: _mainController,
          builder: (context, child) {
            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: Opacity(
                    opacity: _opacityAnimation.value,
                    child: _buildDialogContent(dailyLoginProvider, userProvider),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDialogContent(DailyLoginProvider dailyLoginProvider, UserProvider userProvider) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
      child: Stack(
        children: [
          // Particle effects background
          _buildParticleBackground(),
          
          // Main dialog content
          Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: SoloLevelingColors.electricBlue.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: SoloLevelingColors.electricBlue.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildStreakInfo(dailyLoginProvider),
                  const SizedBox(height: 24),
                  _buildRewardSection(dailyLoginProvider, userProvider),
                  const SizedBox(height: 24),
                  _buildActionButtons(dailyLoginProvider, userProvider),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildParticleBackground() {
    return AnimatedBuilder(
      animation: _particleAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticleEffectPainter(_particleAnimation.value),
          child: Container(),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Icon(
          Icons.login,
          size: 48,
          color: SoloLevelingColors.electricBlue,
        ),
        const SizedBox(height: 12),
        Text(
          'DAILY LOGIN',
          style: SoloLevelingTypography.hunterTitle.copyWith(
            fontSize: 24,
            color: SoloLevelingColors.electricBlue,
          ),
        ),
        Text(
          'Hunter Association System',
          style: SoloLevelingTypography.systemNotification.copyWith(
            fontSize: 14,
            color: SoloLevelingColors.silverMist,
          ),
        ),
      ],
    );
  }

  Widget _buildStreakInfo(DailyLoginProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: SoloLevelingColors.hunterGreen.withValues(alpha: 0.3),
          width: 1,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SoloLevelingColors.hunterGreen.withValues(alpha: 0.1),
            SoloLevelingColors.hunterGreenDark.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Current Streak',
            '${provider.currentStreak}',
            SoloLevelingColors.hunterGreen,
          ),
          Container(
            width: 1,
            height: 30,
            color: SoloLevelingColors.shadowGray,
          ),
          _buildStatItem(
            'Total Days',
            '${provider.totalLoginDays}',
            SoloLevelingColors.electricBlue,
          ),
          Container(
            width: 1,
            height: 30,
            color: SoloLevelingColors.shadowGray,
          ),
          _buildStatItem(
            'Multiplier',
            '${provider.streakMultiplier.toStringAsFixed(1)}x',
            SoloLevelingColors.mysticPurple,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: SoloLevelingTypography.statValue.copyWith(
            fontSize: 20,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
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

  Widget _buildRewardSection(DailyLoginProvider dailyLoginProvider, UserProvider userProvider) {
    if (_todayReward == null && dailyLoginProvider.canLoginToday) {
      return _buildLoginPrompt(dailyLoginProvider, userProvider);
    } else if (_todayReward != null) {
      return _buildRewardDisplay();
    } else {
      return _buildAlreadyClaimedMessage();
    }
  }

  Widget _buildLoginPrompt(DailyLoginProvider dailyLoginProvider, UserProvider userProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: SoloLevelingGradients.systemPanel,
        border: Border.all(
          color: SoloLevelingColors.electricBlue.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.celebration,
            size: 40,
            color: SoloLevelingColors.hunterGreen,
          ),
          const SizedBox(height: 12),
          Text(
            'Ready to claim your daily reward?',
            style: SoloLevelingTypography.systemNotification,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            dailyLoginProvider.getStreakStatusMessage(),
            style: SoloLevelingTypography.systemNotification.copyWith(
              fontSize: 14,
              color: SoloLevelingColors.silverMist,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRewardDisplay() {
    if (_todayReward == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SoloLevelingColors.mysticPurple.withValues(alpha: 0.2),
            SoloLevelingColors.electricBlue.withValues(alpha: 0.1),
          ],
        ),
        border: Border.all(
          color: _todayReward!.isMilestone 
              ? SoloLevelingColors.mysticPurple 
              : SoloLevelingColors.electricBlue.withValues(alpha: 0.3),
          width: _todayReward!.isMilestone ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          if (_todayReward!.isMilestone) ...[
            Icon(
              Icons.star,
              size: 32,
              color: SoloLevelingColors.mysticPurple,
            ),
            const SizedBox(height: 8),
            Text(
              'MILESTONE REWARD',
              style: SoloLevelingTypography.systemAlert.copyWith(
                color: SoloLevelingColors.mysticPurple,
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          Text(
            _todayReward!.displayDescription,
            style: SoloLevelingTypography.systemNotification,
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // Reward items
          ...(_todayReward!.rewards.take(3).map((reward) => _buildRewardItem(reward))),
          
          if (_todayReward!.rewards.length > 3) ...[
            const SizedBox(height: 8),
            Text(
              '+${_todayReward!.rewards.length - 3} more rewards',
              style: SoloLevelingTypography.systemNotification.copyWith(
                fontSize: 12,
                color: SoloLevelingColors.silverMist,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRewardItem(RewardItem reward) {
    IconData icon;
    Color color;
    
    switch (reward.type) {
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
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              reward.displayText,
              style: SoloLevelingTypography.systemNotification.copyWith(
                fontSize: 14,
                color: reward.isRare 
                    ? SoloLevelingColors.mysticPurple 
                    : SoloLevelingColors.ghostWhite,
              ),
            ),
          ),
          if (reward.isRare)
            Icon(
              Icons.auto_awesome,
              size: 16,
              color: SoloLevelingColors.mysticPurple,
            ),
        ],
      ),
    );
  }

  Widget _buildAlreadyClaimedMessage() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: SoloLevelingColors.shadowDepth,
        border: Border.all(
          color: SoloLevelingColors.shadowGray,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle,
            size: 40,
            color: SoloLevelingColors.hunterGreen,
          ),
          const SizedBox(height: 12),
          Text(
            'Daily reward already claimed!',
            style: SoloLevelingTypography.systemNotification,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Come back tomorrow for more rewards',
            style: SoloLevelingTypography.systemNotification.copyWith(
              fontSize: 14,
              color: SoloLevelingColors.silverMist,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(DailyLoginProvider dailyLoginProvider, UserProvider userProvider) {
    return Row(
      children: [
        // Close button
        Expanded(
          child: OutlinedButton(
            onPressed: _closeDialog,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(
                color: SoloLevelingColors.shadowGray,
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Later',
              style: SoloLevelingTypography.systemNotification.copyWith(
                color: SoloLevelingColors.silverMist,
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Action button
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _getActionButtonCallback(dailyLoginProvider, userProvider),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              backgroundColor: _getActionButtonColor(),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isClaimingReward
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    _getActionButtonText(dailyLoginProvider),
                    style: SoloLevelingTypography.systemNotification.copyWith(
                      color: SoloLevelingColors.pureLight,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  VoidCallback? _getActionButtonCallback(DailyLoginProvider dailyLoginProvider, UserProvider userProvider) {
    if (_isClaimingReward) return null;
    
    if (dailyLoginProvider.canLoginToday && _todayReward == null) {
      return () => _performLogin(dailyLoginProvider, userProvider);
    } else if (_todayReward != null && !_hasClaimedReward) {
      return () => _claimReward(dailyLoginProvider, userProvider);
    } else {
      return _closeDialog;
    }
  }

  String _getActionButtonText(DailyLoginProvider provider) {
    if (provider.canLoginToday && _todayReward == null) {
      return 'LOGIN';
    } else if (_todayReward != null && !_hasClaimedReward) {
      return 'CLAIM REWARD';
    } else {
      return 'CLOSE';
    }
  }

  Color _getActionButtonColor() {
    if (_todayReward?.isMilestone == true) {
      return SoloLevelingColors.mysticPurple;
    } else if (_todayReward != null && !_hasClaimedReward) {
      return SoloLevelingColors.hunterGreen;
    } else {
      return SoloLevelingColors.electricBlue;
    }
  }

  Future<void> _performLogin(DailyLoginProvider dailyLoginProvider, UserProvider userProvider) async {
    if (_isClaimingReward) return;
    
    setState(() {
      _isClaimingReward = true;
    });

    try {
      final user = userProvider.currentUser;
      if (user != null) {
        final reward = await dailyLoginProvider.performDailyLogin(user);
        if (reward != null) {
          setState(() {
            _todayReward = reward;
          });
          
          // Show success notification
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Daily login successful!')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to perform daily login: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isClaimingReward = false;
        });
      }
    }
  }

  Future<void> _claimReward(DailyLoginProvider dailyLoginProvider, UserProvider userProvider) async {
    if (_isClaimingReward || _todayReward == null) return;
    
    setState(() {
      _isClaimingReward = true;
    });

    try {
      final user = userProvider.currentUser;
      if (user != null) {
        final success = await dailyLoginProvider.claimReward(_todayReward!, user);
        
        if (success) {
          setState(() {
            _hasClaimedReward = true;
          });
          
          // Trigger reward animation
          _rewardController.forward();
          
          // Show success notification
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Reward claimed successfully!')),
            );
          }
          
          // Auto-close after claiming
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              _closeDialog();
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to claim reward: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isClaimingReward = false;
        });
      }
    }
  }

  void _closeDialog() {
    if (widget.onClose != null) {
      widget.onClose!();
    }
    Navigator.of(context).pop();
  }
}

/// Custom painter for particle effects
class ParticleEffectPainter extends CustomPainter {
  final double animationValue;
  
  ParticleEffectPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = SoloLevelingColors.electricBlue.withValues(alpha: 0.3)
      ..strokeWidth = 1.0;

    final random = Random(42); // Fixed seed for consistent animation
    
    for (int i = 0; i < 20; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 1.0 + (sin(animationValue * 2 * pi + i) * 2);
      
      paint.color = SoloLevelingColors.electricBlue.withValues(
        alpha: 0.1 + (sin(animationValue * pi + i) * 0.2),
      );
      
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(ParticleEffectPainter oldDelegate) {
    return animationValue != oldDelegate.animationValue;
  }
}