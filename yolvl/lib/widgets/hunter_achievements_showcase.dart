import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../models/achievement.dart';
import '../providers/achievement_provider.dart';
import '../theme/solo_leveling_theme.dart';
import '../theme/glassmorphism_effects.dart';

/// Hunter Achievements Showcase component displaying achievements in Solo Leveling style
/// Features recent achievements, progress indicators, and achievement categories
class HunterAchievementsShowcase extends StatefulWidget {
  final HunterAchievementsDisplayMode displayMode;
  final int maxAchievements;
  final bool showProgress;
  final bool enableAnimations;
  final VoidCallback? onViewAllTap;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;

  const HunterAchievementsShowcase({
    super.key,
    this.displayMode = HunterAchievementsDisplayMode.showcase,
    this.maxAchievements = 6,
    this.showProgress = true,
    this.enableAnimations = true,
    this.onViewAllTap,
    this.margin,
    this.width,
    this.height,
  });

  @override
  State<HunterAchievementsShowcase> createState() => _HunterAchievementsShowcaseState();
}

class _HunterAchievementsShowcaseState extends State<HunterAchievementsShowcase>
    with TickerProviderStateMixin {
  late AnimationController _showcaseAnimationController;
  late AnimationController _badgeGlowController;
  late List<AnimationController> _achievementControllers;
  late List<Animation<double>> _achievementAnimations;
  late Animation<double> _badgeGlowAnimation;

  String _selectedCategory = 'all';
  final List<String> _categories = ['all', 'level', 'streak', 'activity', 'special'];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Main showcase reveal animation
    _showcaseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Badge glow effect for rare achievements
    _badgeGlowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Individual achievement badge animations
    _achievementControllers = List.generate(widget.maxAchievements, (index) {
      return AnimationController(
        duration: Duration(milliseconds: 600 + (index * 100)),
        vsync: this,
      );
    });

    _achievementAnimations = _achievementControllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.elasticOut,
      ));
    }).toList();

    _badgeGlowAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _badgeGlowController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    if (widget.enableAnimations) {
      _startShowcaseAnimation();
    } else {
      // Set all animations to complete state
      _showcaseAnimationController.value = 1.0;
      for (final controller in _achievementControllers) {
        controller.value = 1.0;
      }
    }

    // Start continuous badge glow
    _badgeGlowController.repeat(reverse: true);
  }

  void _startShowcaseAnimation() {
    _showcaseAnimationController.forward();
    
    // Stagger individual achievement animations
    for (int i = 0; i < _achievementControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) {
          _achievementControllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _showcaseAnimationController.dispose();
    _badgeGlowController.dispose();
    for (final controller in _achievementControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AchievementProvider>(
      builder: (context, achievementProvider, child) {
        return _buildShowcaseContainer(achievementProvider);
      },
    );
  }

  Widget _buildShowcaseContainer(AchievementProvider achievementProvider) {
    return Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin ?? const EdgeInsets.all(16),
      child: GlassmorphismEffects.hunterPanel(
        glowEffect: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildShowcaseHeader(),
            if (widget.displayMode == HunterAchievementsDisplayMode.detailed) ...[
              const SizedBox(height: 12),
              _buildCategoryFilter(),
            ],
            const SizedBox(height: 16),
            Expanded(
              child: _buildAchievementsContent(achievementProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShowcaseHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: SoloLevelingColors.electricBlue.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.military_tech,
            color: SoloLevelingColors.electricBlue,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Hunter Achievements',
          style: SoloLevelingTypography.hunterSubtitle.copyWith(
            fontSize: 20,
            color: SoloLevelingColors.electricBlue,
          ),
        ),
        const Spacer(),
        if (widget.onViewAllTap != null)
          TextButton(
            onPressed: widget.onViewAllTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View All',
                  style: SoloLevelingTypography.systemNotification.copyWith(
                    fontSize: 14,
                    color: SoloLevelingColors.hunterGreen,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  color: SoloLevelingColors.hunterGreen,
                  size: 14,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((category) {
          final isSelected = _selectedCategory == category;
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = category),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? SoloLevelingColors.electricBlue.withValues(alpha: 0.3)
                      : SoloLevelingColors.shadowDepth.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected 
                        ? SoloLevelingColors.electricBlue.withValues(alpha: 0.6)
                        : SoloLevelingColors.shadowGray.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Text(
                  category.toUpperCase(),
                  style: SoloLevelingTypography.systemNotification.copyWith(
                    fontSize: 12,
                    color: isSelected 
                        ? SoloLevelingColors.electricBlue
                        : SoloLevelingColors.silverMist,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAchievementsContent(AchievementProvider achievementProvider) {
    switch (widget.displayMode) {
      case HunterAchievementsDisplayMode.compact:
        return _buildCompactShowcase(achievementProvider);
      case HunterAchievementsDisplayMode.showcase:
        return _buildGridShowcase(achievementProvider);
      case HunterAchievementsDisplayMode.detailed:
        return _buildDetailedShowcase(achievementProvider);
    }
  }

  Widget _buildCompactShowcase(AchievementProvider achievementProvider) {
    final achievements = _getFilteredAchievements(achievementProvider)
        .take(widget.maxAchievements).toList();

    if (achievements.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: achievements.asMap().entries.map((entry) {
          final index = entry.key;
          final achievement = entry.value;
          
          return AnimatedBuilder(
            animation: _achievementAnimations[index],
            builder: (context, child) {
              return Transform.scale(
                scale: _achievementAnimations[index].value,
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 12),
                  child: _buildCompactAchievementBadge(achievement),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGridShowcase(AchievementProvider achievementProvider) {
    final achievements = _getFilteredAchievements(achievementProvider);
    final progressItems = _getProgressItems(achievementProvider);
    final combinedItems = [...achievements, ...progressItems]
        .take(widget.maxAchievements).toList();

    if (combinedItems.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: math.min(combinedItems.length, _achievementAnimations.length),
      itemBuilder: (context, index) {
        final item = combinedItems[index];
        
        return AnimatedBuilder(
          animation: _achievementAnimations[index],
          builder: (context, child) {
            return Transform.scale(
              scale: _achievementAnimations[index].value,
              child: item is Achievement
                  ? _buildAchievementBadge(item)
                  : _buildProgressBadge(item as AchievementProgress),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailedShowcase(AchievementProvider achievementProvider) {
    final achievements = _getFilteredAchievements(achievementProvider);
    final progressItems = _getProgressItems(achievementProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (achievements.isNotEmpty) ...[
            Text(
              'Unlocked Achievements',
              style: SoloLevelingTypography.hunterSubtitle.copyWith(
                fontSize: 16,
                color: SoloLevelingColors.hunterGreen,
              ),
            ),
            const SizedBox(height: 12),
            _buildAchievementsList(achievements.take(3).toList()),
            const SizedBox(height: 20),
          ],
          if (progressItems.isNotEmpty && widget.showProgress) ...[
            Text(
              'Progress Tracking',
              style: SoloLevelingTypography.hunterSubtitle.copyWith(
                fontSize: 16,
                color: SoloLevelingColors.electricBlue,
              ),
            ),
            const SizedBox(height: 12),
            _buildProgressList(progressItems.take(3).toList()),
          ],
        ],
      ),
    );
  }

  Widget _buildAchievementsList(List<Achievement> achievements) {
    return Column(
      children: achievements.asMap().entries.map((entry) {
        final index = entry.key;
        final achievement = entry.value;
        
        return AnimatedBuilder(
          animation: _achievementAnimations[index],
          builder: (context, child) {
            return Transform.scale(
              scale: _achievementAnimations[index].value,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: _buildDetailedAchievementItem(achievement),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildProgressList(List<AchievementProgress> progressItems) {
    return Column(
      children: progressItems.asMap().entries.map((entry) {
        final index = entry.key;
        final progress = entry.value;
        
        return AnimatedBuilder(
          animation: _achievementAnimations[index + 3], // Offset for achievements
          builder: (context, child) {
            return Transform.scale(
              scale: _achievementAnimations[math.min(index + 3, _achievementAnimations.length - 1)].value,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: _buildProgressItem(progress),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildCompactAchievementBadge(Achievement achievement) {
    final achievementType = achievement.achievementTypeEnum;
    final isRare = achievementType.rarity >= 4;

    return AnimatedBuilder(
      animation: _badgeGlowAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: achievementType.color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: achievementType.color.withValues(alpha: 0.5),
              width: 2,
            ),
            boxShadow: isRare ? [
              BoxShadow(
                color: achievementType.color.withValues(alpha: 0.4 * _badgeGlowAnimation.value),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ] : null,
          ),
          child: Column(
            children: [
              Icon(
                achievementType.icon,
                color: achievementType.color,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                achievementType.displayName,
                style: SoloLevelingTypography.systemNotification.copyWith(
                  fontSize: 8,
                  color: SoloLevelingColors.ghostWhite,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAchievementBadge(Achievement achievement) {
    final achievementType = achievement.achievementTypeEnum;
    final isRare = achievementType.rarity >= 4;

    return AnimatedBuilder(
      animation: _badgeGlowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                achievementType.color.withValues(alpha: 0.3),
                achievementType.color.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: achievementType.color.withValues(alpha: 0.6),
              width: 2,
            ),
            boxShadow: isRare ? [
              BoxShadow(
                color: achievementType.color.withValues(alpha: 0.5 * _badgeGlowAnimation.value),
                blurRadius: 12,
                spreadRadius: 3,
              ),
            ] : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: achievementType.color.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  achievementType.icon,
                  color: achievementType.color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                achievementType.displayName,
                style: SoloLevelingTypography.systemNotification.copyWith(
                  fontSize: 10,
                  color: SoloLevelingColors.ghostWhite,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                achievement.formattedUnlockTime,
                style: SoloLevelingTypography.systemNotification.copyWith(
                  fontSize: 8,
                  color: SoloLevelingColors.silverMist,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressBadge(AchievementProgress progress) {
    final achievementType = progress.type;
    
    return Container(
      decoration: BoxDecoration(
        color: SoloLevelingColors.shadowDepth.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: achievementType.color.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: achievementType.color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              achievementType.icon,
              color: achievementType.color.withValues(alpha: 0.7),
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${progress.progressPercentage}%',
            style: SoloLevelingTypography.systemNotification.copyWith(
              fontSize: 12,
              color: achievementType.color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            achievementType.displayName,
            style: SoloLevelingTypography.systemNotification.copyWith(
              fontSize: 8,
              color: SoloLevelingColors.silverMist,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedAchievementItem(Achievement achievement) {
    final achievementType = achievement.achievementTypeEnum;
    final isRare = achievementType.rarity >= 4;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            achievementType.color.withValues(alpha: 0.2),
            achievementType.color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: achievementType.color.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: achievementType.color.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              achievementType.icon,
              color: achievementType.color,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      achievementType.displayName,
                      style: SoloLevelingTypography.hunterSubtitle.copyWith(
                        fontSize: 16,
                        color: SoloLevelingColors.ghostWhite,
                      ),
                    ),
                    if (isRare) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: SoloLevelingColors.goldRank.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: SoloLevelingColors.goldRank.withValues(alpha: 0.6),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'RARE',
                          style: SoloLevelingTypography.systemNotification.copyWith(
                            fontSize: 8,
                            color: SoloLevelingColors.goldRank,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  achievementType.description,
                  style: SoloLevelingTypography.systemNotification.copyWith(
                    fontSize: 12,
                    color: SoloLevelingColors.silverMist,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Unlocked ${achievement.formattedUnlockTime}',
                  style: SoloLevelingTypography.systemNotification.copyWith(
                    fontSize: 10,
                    color: achievementType.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(AchievementProgress progress) {
    final achievementType = progress.type;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SoloLevelingColors.shadowDepth.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: achievementType.color.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: achievementType.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  achievementType.icon,
                  color: achievementType.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievementType.displayName,
                      style: SoloLevelingTypography.systemNotification.copyWith(
                        fontSize: 14,
                        color: SoloLevelingColors.ghostWhite,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      achievementType.description,
                      style: SoloLevelingTypography.systemNotification.copyWith(
                        fontSize: 12,
                        color: SoloLevelingColors.silverMist,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${progress.currentValue}/${progress.targetValue}',
                style: SoloLevelingTypography.systemNotification.copyWith(
                  fontSize: 12,
                  color: achievementType.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress',
                    style: SoloLevelingTypography.systemNotification.copyWith(
                      fontSize: 10,
                      color: SoloLevelingColors.silverMist,
                    ),
                  ),
                  Text(
                    '${progress.progressPercentage}%',
                    style: SoloLevelingTypography.systemNotification.copyWith(
                      fontSize: 10,
                      color: achievementType.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.progress,
                  backgroundColor: SoloLevelingColors.shadowGray.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(achievementType.color),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.military_tech_outlined,
            color: SoloLevelingColors.silverMist.withValues(alpha: 0.5),
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'No achievements yet',
            style: SoloLevelingTypography.systemNotification.copyWith(
              fontSize: 16,
              color: SoloLevelingColors.silverMist,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete activities to earn your first achievement!',
            style: SoloLevelingTypography.systemNotification.copyWith(
              fontSize: 12,
              color: SoloLevelingColors.silverMist.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<Achievement> _getFilteredAchievements(AchievementProvider achievementProvider) {
    var achievements = achievementProvider.unlockedAchievements;
    
    if (_selectedCategory != 'all') {
      achievements = achievements.where((achievement) {
        final type = achievement.achievementTypeEnum;
        switch (_selectedCategory) {
          case 'level':
            return type.name.contains('level') || type.name.contains('Level');
          case 'streak':
            return type.name.contains('streak') || type.name.contains('Streak');
          case 'activity':
            return type.name.contains('Activities') || type.name.contains('activity');
          case 'special':
            return type.rarity >= 4;
          default:
            return true;
        }
      }).toList();
    }
    
    // Sort by unlock date (most recent first)
    achievements.sort((a, b) => b.unlockedAt.compareTo(a.unlockedAt));
    
    return achievements;
  }

  List<AchievementProgress> _getProgressItems(AchievementProvider achievementProvider) {
    if (!widget.showProgress) return [];
    
    // Get achievement progress from provider
    final allProgress = achievementProvider.achievementProgress;
    
    // Filter out completed achievements and sort by progress
    final progressItems = allProgress
        .where((progress) => !progress.isUnlocked && progress.currentValue > 0)
        .toList();
    
    progressItems.sort((a, b) => b.progress.compareTo(a.progress));
    
    return progressItems;
  }
}

/// Display modes for the Hunter Achievements Showcase
enum HunterAchievementsDisplayMode {
  compact,    // Horizontal scrollable achievement badges
  showcase,   // Grid layout with achievements and progress
  detailed,   // Full list with descriptions and progress bars
}