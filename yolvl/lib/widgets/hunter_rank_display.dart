import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../providers/user_provider.dart';
import '../services/hunter_rank_service.dart';
import '../theme/solo_leveling_theme.dart';
import '../theme/glassmorphism_effects.dart';
import '../utils/accessibility_helper.dart';
import 'hunter_rank_badge.dart';

/// Widget displaying user Hunter Rank with Solo Leveling themed styling
/// Replaces the basic level display with immersive rank progression
class HunterRankDisplay extends StatefulWidget {
  final bool showLevelDetails;
  final bool compactMode;
  final VoidCallback? onTap;

  const HunterRankDisplay({
    super.key,
    this.showLevelDetails = true,
    this.compactMode = false,
    this.onTap,
  });

  @override
  State<HunterRankDisplay> createState() => _HunterRankDisplayState();
}

class _HunterRankDisplayState extends State<HunterRankDisplay>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _glowController;
  late AnimationController _pulseController;
  late Animation<double> _progressAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _pulseAnimation;
  
  final HunterRankService _rankService = HunterRankService.instance;
  double _previousProgress = 0.0;

  @override
  void initState() {
    super.initState();
    
    // Progress animation for rank progression bar
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Glow animation for high-rank effects
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Pulse animation for special ranks
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOutCubic,
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Start continuous animations for special effects
    _glowController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _progressController.dispose();
    _glowController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _updateProgress(double newProgress) {
    if (newProgress != _previousProgress) {
      _progressController.reset();
      _progressAnimation = Tween<double>(
        begin: _previousProgress,
        end: newProgress,
      ).animate(CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOutCubic,
      ));
      _progressController.forward();
      _previousProgress = newProgress;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final level = userProvider.level;
        final currentEXP = userProvider.currentEXP;
        final expThreshold = userProvider.expThreshold;
        final expProgress = userProvider.expProgress.clamp(0.0, 1.0);
        final userName = userProvider.userName;

        final currentRank = _rankService.getRankForLevel(level);
        final nextRank = _rankService.getNextRank(level);
        final rankProgress = _rankService.getRankProgress(level);
        final levelsToNextRank = _rankService.getLevelsToNextRank(level);

        // Update animations when progress changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateProgress(expProgress);
        });

        return Semantics(
          label: _getSemanticLabel(currentRank, level, userName, expProgress),
          child: GestureDetector(
            onTap: widget.onTap,
            child: widget.compactMode
                ? _buildCompactLayout(context, currentRank, level, userName, expProgress)
                : ResponsiveLayout(
                    mobile: _buildMobileLayout(context, currentRank, nextRank, level, 
                        userName, expProgress, rankProgress, levelsToNextRank, currentEXP, expThreshold, userProvider),
                    tablet: _buildTabletLayout(context, currentRank, nextRank, level, 
                        userName, expProgress, rankProgress, levelsToNextRank, currentEXP, expThreshold, userProvider),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildCompactLayout(BuildContext context, HunterRankData rank, int level, String userName, double expProgress) {
    return GlassmorphismEffects.glassmorphicContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      context: context,
      child: Row(
        children: [
          HunterRankBadge(
            rank: rank.rank,
            size: HunterRankBadgeSize.small,
            level: level,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  userName,
                  style: SoloLevelingTypography.systemNotification.copyWith(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${rank.rank}-Rank (Lv.$level)',
                  style: SoloLevelingTypography.statLabel.copyWith(
                    color: rank.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _buildMiniProgressIndicator(expProgress, rank.color),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, HunterRankData currentRank, HunterRankData? nextRank,
      int level, String userName, double expProgress, double rankProgress, int levelsToNextRank,
      double currentEXP, double expThreshold, UserProvider userProvider) {
    
    return GlassmorphismEffects.hunterPanel(
      glowEffect: currentRank.hasGlowEffect,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserRankInfo(context, userName, currentRank, level),
          const SizedBox(height: 20),
          if (widget.showLevelDetails) ...[
            _buildRankProgressSection(context, currentRank, nextRank, rankProgress, levelsToNextRank),
            const SizedBox(height: 16),
            _buildExpProgressSection(context, currentEXP, expThreshold, expProgress, userProvider),
          ],
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context, HunterRankData currentRank, HunterRankData? nextRank,
      int level, String userName, double expProgress, double rankProgress, int levelsToNextRank,
      double currentEXP, double expThreshold, UserProvider userProvider) {
    
    return GlassmorphismEffects.hunterPanel(
      glowEffect: currentRank.hasGlowEffect,
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildUserRankInfo(context, userName, currentRank, level),
          ),
          const SizedBox(width: 32),
          Expanded(
            flex: 3,
            child: widget.showLevelDetails
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRankProgressSection(context, currentRank, nextRank, rankProgress, levelsToNextRank),
                      const SizedBox(height: 16),
                      _buildExpProgressSection(context, currentEXP, expThreshold, expProgress, userProvider),
                    ],
                  )
                : Container(),
          ),
        ],
      ),
    );
  }

  Widget _buildUserRankInfo(BuildContext context, String userName, HunterRankData rank, int level) {
    return Row(
      children: [
        // Animated Hunter Rank Badge
        AnimatedBuilder(
          animation: rank.hasPulseEffect ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
          builder: (context, child) {
            return Transform.scale(
              scale: rank.hasPulseEffect ? _pulseAnimation.value : 1.0,
              child: HunterRankBadge(
                rank: rank.rank,
                size: HunterRankBadgeSize.large,
                level: level,
                glowIntensity: rank.hasGlowEffect ? _glowAnimation.value : 0.0,
              ),
            );
          },
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName,
                style: AccessibilityHelper.getAccessibleTextStyle(
                  context,
                  SoloLevelingTypography.hunterTitle.copyWith(fontSize: 20),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                rank.name,
                style: AccessibilityHelper.getAccessibleTextStyle(
                  context,
                  SoloLevelingTypography.hunterSubtitle.copyWith(
                    color: rank.color,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Level $level',
                style: AccessibilityHelper.getAccessibleTextStyle(
                  context,
                  SoloLevelingTypography.systemNotification.copyWith(
                    color: SoloLevelingColors.silverMist,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRankProgressSection(BuildContext context, HunterRankData currentRank, 
      HunterRankData? nextRank, double rankProgress, int levelsToNextRank) {
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Hunter Rank Progress',
              style: AccessibilityHelper.getAccessibleTextStyle(
                context,
                SoloLevelingTypography.systemNotification.copyWith(
                  fontSize: 14,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (nextRank != null)
              Text(
                nextRank.rank == 'SSS' ? 'MAX RANK' : 'Next: ${nextRank.rank}-Rank',
                style: AccessibilityHelper.getAccessibleTextStyle(
                  context,
                  SoloLevelingTypography.systemNotification.copyWith(
                    fontSize: 12,
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        _buildRankProgressBar(currentRank, nextRank, rankProgress),
        if (levelsToNextRank > 0) ...[
          const SizedBox(height: 4),
          Text(
            '$levelsToNextRank levels to next rank',
            style: AccessibilityHelper.getAccessibleTextStyle(
              context,
              SoloLevelingTypography.systemNotification.copyWith(
                fontSize: 12,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRankProgressBar(HunterRankData currentRank, HunterRankData? nextRank, double progress) {
    return Semantics(
      label: AccessibilityHelper.getRankProgressSemanticLabel(currentRank.rank, nextRank?.rank, progress),
      child: Container(
        height: 12,
        decoration: BoxDecoration(
          color: SoloLevelingColors.shadowDepth,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: currentRank.color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Stack(
            children: [
              // Background gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      currentRank.color.withValues(alpha: 0.1),
                      nextRank?.color.withValues(alpha: 0.1) ?? currentRank.color.withValues(alpha: 0.1),
                    ],
                  ),
                ),
              ),
              // Animated progress bar
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            currentRank.color,
                            nextRank?.color ?? currentRank.lightColor,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpProgressSection(BuildContext context, double currentEXP, double expThreshold, 
      double expProgress, UserProvider userProvider) {
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Experience Points',
              style: AccessibilityHelper.getAccessibleTextStyle(
                context,
                SoloLevelingTypography.systemNotification.copyWith(
                  fontSize: 14,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${currentEXP.toStringAsFixed(0)} / ${expThreshold.toStringAsFixed(0)}',
              style: AccessibilityHelper.getAccessibleTextStyle(
                context,
                SoloLevelingTypography.expDisplay.copyWith(
                  fontSize: 12,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildExpProgressBar(expProgress),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(expProgress * 100).toStringAsFixed(1)}% to next level',
              style: AccessibilityHelper.getAccessibleTextStyle(
                context,
                SoloLevelingTypography.systemNotification.copyWith(
                  fontSize: 12,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (userProvider.canLevelUp)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: SystemColors.levelUpGlow,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: SystemColors.levelUpGlow.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Text(
                  'LEVEL UP!',
                  style: SoloLevelingTypography.systemAlert.copyWith(
                    fontSize: 10,
                    color: SoloLevelingColors.voidBlack,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpProgressBar(double progress) {
    return Semantics(
      label: 'Experience progress: ${(progress * 100).toStringAsFixed(1)}% to next level',
      child: Container(
        height: 10,
        decoration: BoxDecoration(
          color: SoloLevelingColors.shadowDepth,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: SoloLevelingColors.electricBlue.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return LinearProgressIndicator(
                value: _progressAnimation.value,
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  SoloLevelingColors.electricBlue,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMiniProgressIndicator(double progress, Color color) {
    return Container(
      width: 30,
      height: 6,
      decoration: BoxDecoration(
        color: SoloLevelingColors.shadowDepth,
        borderRadius: BorderRadius.circular(3),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    );
  }

  String _getSemanticLabel(HunterRankData rank, int level, String userName, double expProgress) {
    final levelsToNextRank = _rankService.getLevelsToNextRank(level);
    return '$userName, ${AccessibilityHelper.getHunterRankSemanticLabel(rank.rank, rank.name, level, expProgress, levelsToNextRank > 0 ? levelsToNextRank : null)}';
  }
}

/// Responsive layout widget for different screen sizes
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (ResponsiveBreakpoints.isDesktop(context) && desktop != null) {
      return desktop!;
    } else if (ResponsiveBreakpoints.isTablet(context) && tablet != null) {
      return tablet!;
    } else {
      return mobile;
    }
  }
}