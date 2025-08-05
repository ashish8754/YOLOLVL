import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../models/enums.dart';
import '../providers/user_provider.dart';
import '../services/hunter_rank_service.dart';
import '../theme/solo_leveling_theme.dart';
import '../theme/glassmorphism_effects.dart';
import 'hunter_rank_badge.dart';

/// Hunter Profile Card component inspired by Solo Leveling Hunter ID cards
/// Displays user information in authentic Solo Leveling style with glassmorphism effects
class HunterProfileCard extends StatefulWidget {
  final HunterProfileDisplayMode displayMode;
  final VoidCallback? onTap;
  final bool showAvatar;
  final bool showRankBadge;
  final bool showLevelProgress;
  final bool showStats;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;

  const HunterProfileCard({
    super.key,
    this.displayMode = HunterProfileDisplayMode.expanded,
    this.onTap,
    this.showAvatar = true,
    this.showRankBadge = true,
    this.showLevelProgress = true,
    this.showStats = true,
    this.margin,
    this.width,
    this.height,
  });

  @override
  State<HunterProfileCard> createState() => _HunterProfileCardState();
}

class _HunterProfileCardState extends State<HunterProfileCard>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _dataUpdateController;
  late Animation<double> _glowAnimation;
  late Animation<double> _dataUpdateAnimation;

  final HunterRankService _rankService = HunterRankService.instance;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Subtle glow animation for rank effects
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Data update animation for smooth transitions
    _dataUpdateController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _dataUpdateAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _dataUpdateController, curve: Curves.elasticOut),
    );

    // Start continuous glow animation
    _glowController.repeat(reverse: true);
    _dataUpdateController.forward();
  }

  @override
  void dispose() {
    _glowController.dispose();
    _dataUpdateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.currentUser;
        if (user == null) {
          return _buildLoadingCard();
        }

        final rankData = _rankService.getRankForLevel(user.level);

        return AnimatedBuilder(
          animation: _dataUpdateAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _dataUpdateAnimation.value,
              child: _buildProfileCard(user, rankData),
            );
          },
        );
      },
    );
  }

  Widget _buildProfileCard(User user, HunterRankData rankData) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.width ?? _getCardWidth(),
        height: widget.height ?? _getCardHeight(),
        margin: widget.margin ?? const EdgeInsets.all(16),
        child: GlassmorphismEffects.hunterPanel(
          glowEffect: rankData.hasGlowEffect,
          context: context, // Pass context for theme awareness
          child: _buildCardContent(user, rankData),
        ),
      ),
    );
  }

  Widget _buildCardContent(User user, HunterRankData rankData) {
    switch (widget.displayMode) {
      case HunterProfileDisplayMode.compact:
        return _buildCompactContent(user, rankData);
      case HunterProfileDisplayMode.expanded:
        return _buildExpandedContent(user, rankData);
      case HunterProfileDisplayMode.detailed:
        return _buildDetailedContent(user, rankData);
    }
  }

  Widget _buildCompactContent(User user, HunterRankData rankData) {
    return Row(
      children: [
        // Avatar and Rank Badge
        if (widget.showAvatar || widget.showRankBadge)
          _buildAvatarSection(user, rankData, size: 50),

        const SizedBox(width: 16),

        // Basic Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHunterName(user, size: 18),
              const SizedBox(height: 4),
              _buildHunterTitle(rankData, size: 12),
              if (widget.showLevelProgress) ...[
                const SizedBox(height: 8),
                _buildLevelProgressCompact(user),
              ],
            ],
          ),
        ),

        // Level Display
        _buildLevelDisplay(user, size: 24),
      ],
    );
  }

  Widget _buildExpandedContent(User user, HunterRankData rankData) {
    return Column(
      children: [
        // Header Section with improved left alignment
        Row(
          children: [
            if (widget.showAvatar || widget.showRankBadge)
              _buildAvatarSection(user, rankData, size: 70),

            const SizedBox(width: 12), // Reduced spacing for better alignment

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHunterName(user, size: 24),
                  const SizedBox(height: 4), // Reduced spacing
                  _buildHunterTitle(rankData, size: 14),
                  const SizedBox(height: 6), // Reduced spacing
                  _buildHunterStats(user),
                ],
              ),
            ),

            const SizedBox(width: 8), // Add small spacing before level
            _buildLevelDisplay(user, size: 32),
          ],
        ),

        if (widget.showLevelProgress) ...[
          const SizedBox(height: 20),
          _buildLevelProgressExpanded(user),
        ],

        if (widget.showStats) ...[
          const SizedBox(height: 16),
          _buildQuickStatsOverview(user),
        ],
      ],
    );
  }

  Widget _buildDetailedContent(User user, HunterRankData rankData) {
    return Column(
      children: [
        // Header with full info
        _buildDetailedHeader(user, rankData),

        const Divider(
          color: SoloLevelingColors.electricBlue,
          thickness: 1,
          height: 32,
        ),

        // Detailed stats and progression
        if (widget.showStats) _buildDetailedStats(user),

        if (widget.showLevelProgress) ...[
          const SizedBox(height: 16),
          _buildDetailedProgression(user, rankData),
        ],
      ],
    );
  }

  Widget _buildAvatarSection(
    User user,
    HunterRankData rankData, {
    required double size,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Avatar Container
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      rankData.lightColor.withValues(alpha: 0.3),
                      rankData.color.withValues(alpha: 0.5),
                    ]
                  : [
                      rankData.color.withValues(alpha: 0.1),
                      rankData.color.withValues(alpha: 0.2),
                    ],
            ),
            border: Border.all(
              color: isDark
                  ? rankData.lightColor.withValues(alpha: 0.6)
                  : rankData.color.withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          child: ClipOval(
            child: user.avatarPath != null
                ? Image.asset(
                    user.avatarPath!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildDefaultAvatar(size * 0.6),
                  )
                : _buildDefaultAvatar(size * 0.6),
          ),
        ),

        // Rank Badge Overlay
        if (widget.showRankBadge)
          Positioned(
            bottom: -5,
            right: -5,
            child: AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return HunterRankBadge(
                  rank: rankData.rank,
                  size: HunterRankBadgeSize.small,
                  glowIntensity: rankData.hasGlowEffect
                      ? _glowAnimation.value
                      : 0.0,
                  showLevelText: false,
                  enableAnimations: true,
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildDefaultAvatar(double size) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark
            ? SoloLevelingColors.shadowDepth
            : const Color(0xFFE5E7EB),
      ),
      child: Icon(
        Icons.person,
        color: isDark ? SoloLevelingColors.silverMist : const Color(0xFF6B7280),
        size: size * 0.6,
      ),
    );
  }

  Widget _buildHunterName(User user, {required double size}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      user.name,
      style: SoloLevelingTypography.hunterTitle.copyWith(
        fontSize: size,
        color: isDark
            ? SoloLevelingColors.ghostWhite
            : const Color(0xFF0F172A), // Much darker text for better contrast
        fontWeight: FontWeight.bold,
        shadows: isDark
            ? null
            : [
                Shadow(
                  color: Colors.white.withValues(alpha: 0.8),
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildHunterTitle(HunterRankData rankData, {required double size}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lightModeColor = _getDarkerRankColor(rankData.color);
    return Text(
      rankData.name,
      style: SoloLevelingTypography.hunterSubtitle.copyWith(
        fontSize: size,
        color: isDark
            ? rankData.lightColor
            : lightModeColor,
        fontWeight: FontWeight.w600,
        shadows: isDark
            ? null
            : [
                Shadow(
                  color: Colors.white.withValues(alpha: 0.7),
                  offset: const Offset(0, 1),
                  blurRadius: 1,
                ),
              ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildLevelDisplay(User user, {required double size}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(
          'LV',
          style: SoloLevelingTypography.statLabel.copyWith(
            fontSize: size * 0.4,
            color: isDark
                ? SoloLevelingColors.silverMist
                : const Color(0xFF374151), // Much darker gray for better contrast
            fontWeight: FontWeight.w600,
            shadows: isDark
                ? null
                : [
                    Shadow(
                      color: Colors.white.withValues(alpha: 0.8),
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
          ),
        ),
        Text(
          '${user.level}',
          style: SoloLevelingTypography.levelDisplay.copyWith(
            fontSize: size,
            color: isDark
                ? SoloLevelingColors.electricBlue
                : const Color(0xFF1E3A8A), // Even darker blue for maximum contrast
            fontWeight: FontWeight.bold,
            shadows: isDark
                ? null
                : [
                    Shadow(
                      color: Colors.white.withValues(alpha: 0.8),
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
          ),
        ),
      ],
    );
  }

  Widget _buildHunterStats(User user) {
    return Row(
      children: [
        _buildStatChip('LV ${user.level}', SoloLevelingColors.electricBlue),
        const SizedBox(width: 8),
        _buildStatChip(
          '${user.currentEXP.toInt()} EXP',
          SoloLevelingColors.hunterGreen,
        ),
      ],
    );
  }

  Widget _buildStatChip(String text, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipColor = isDark ? color : _getLightModeChipColor(color);
    final backgroundColor = isDark
        ? color.withValues(alpha: 0.2)
        : Colors.white.withValues(alpha: 0.9); // More opaque background
    final borderColor = isDark
        ? color.withValues(alpha: 0.5)
        : chipColor.withValues(alpha: 0.6); // Stronger border

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
      ),
      child: Text(
        text,
        style: SoloLevelingTypography.systemNotification.copyWith(
          fontSize: 10,
          color: chipColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getLightModeChipColor(Color darkColor) {
    // Map dark mode colors to appropriate light mode colors with maximum contrast
    if (darkColor == SoloLevelingColors.electricBlue) {
      return const Color(0xFF1E3A8A); // Even darker blue
    } else if (darkColor == SoloLevelingColors.hunterGreen) {
      return const Color(0xFF047857); // Darker green
    }
    return darkColor; // Fallback to original color
  }

  Color _getDarkerRankColor(Color rankColor) {
    // Create much darker versions of rank colors for better contrast
    final hslColor = HSLColor.fromColor(rankColor);
    return hslColor.withLightness((hslColor.lightness * 0.3).clamp(0.0, 1.0)).toColor();
  }

  Widget _buildLevelProgressCompact(User user) {
    final progress = user.expProgress;
    final nextLevelExp = user.expThreshold;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'EXP',
              style: SoloLevelingTypography.statLabel.copyWith(
                fontSize: 10,
                color: isDark
                    ? SoloLevelingColors.silverMist
                    : const Color(0xFF374151), // Darker for better contrast
                fontWeight: FontWeight.w600,
                shadows: isDark
                    ? null
                    : [
                        Shadow(
                          color: Colors.white.withValues(alpha: 0.8),
                          offset: const Offset(0, 1),
                          blurRadius: 1,
                        ),
                      ],
              ),
            ),
            Text(
              '${user.currentEXP.toInt()}/${nextLevelExp.toInt()}',
              style: SoloLevelingTypography.statLabel.copyWith(
                fontSize: 10,
                color: isDark
                    ? SoloLevelingColors.hunterGreen
                    : const Color(0xFF047857), // Darker green
                fontWeight: FontWeight.bold,
                shadows: isDark
                    ? null
                    : [
                        Shadow(
                          color: Colors.white.withValues(alpha: 0.8),
                          offset: const Offset(0, 1),
                          blurRadius: 1,
                        ),
                      ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: isDark
              ? SoloLevelingColors.shadowGray.withValues(alpha: 0.3)
              : const Color(0xFFE5E7EB),
          valueColor: AlwaysStoppedAnimation<Color>(
            isDark ? SoloLevelingColors.hunterGreen : const Color(0xFF059669),
          ),
          minHeight: 6,
        ),
      ],
    );
  }

  Widget _buildLevelProgressExpanded(User user) {
    final progress = user.expProgress;
    final nextLevelExp = user.expThreshold;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? SoloLevelingColors.shadowDepth.withValues(alpha: 0.5)
            : const Color(0xFFF8FAFC), // Light gray background for light mode
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? SoloLevelingColors.hunterGreen.withValues(alpha: 0.3)
              : const Color(0xFF059669).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'EXP Progress',
                style: SoloLevelingTypography.systemNotification.copyWith(
                  fontSize: 14,
                  color: isDark
                      ? SoloLevelingColors.ghostWhite
                      : const Color(0xFF0F172A), // Much darker
                  fontWeight: FontWeight.bold,
                  shadows: isDark
                      ? null
                      : [
                          Shadow(
                            color: Colors.white.withValues(alpha: 0.8),
                            offset: const Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: SoloLevelingTypography.systemNotification.copyWith(
                  fontSize: 14,
                  color: isDark
                      ? SoloLevelingColors.hunterGreen
                      : const Color(0xFF047857), // Darker green
                  fontWeight: FontWeight.bold,
                  shadows: isDark
                      ? null
                      : [
                          Shadow(
                            color: Colors.white.withValues(alpha: 0.8),
                            offset: const Offset(0, 1),
                            blurRadius: 1,
                          ),
                        ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: isDark
                  ? SoloLevelingColors.shadowGray.withValues(alpha: 0.3)
                  : const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark
                    ? SoloLevelingColors.hunterGreen
                    : const Color(0xFF059669),
              ),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${user.currentEXP.toInt()} EXP',
                style: SoloLevelingTypography.expDisplay.copyWith(
                  fontSize: 12,
                  color: isDark
                      ? SoloLevelingColors.silverMist
                      : const Color(0xFF374151), // Much darker
                  fontWeight: FontWeight.w600,
                  shadows: isDark
                      ? null
                      : [
                          Shadow(
                            color: Colors.white.withValues(alpha: 0.8),
                            offset: const Offset(0, 1),
                            blurRadius: 1,
                          ),
                        ],
                ),
              ),
              Text(
                '${nextLevelExp.toInt()} EXP',
                style: SoloLevelingTypography.expDisplay.copyWith(
                  fontSize: 12,
                  color: isDark
                      ? SoloLevelingColors.silverMist
                      : const Color(0xFF374151), // Much darker
                  fontWeight: FontWeight.w600,
                  shadows: isDark
                      ? null
                      : [
                          Shadow(
                            color: Colors.white.withValues(alpha: 0.8),
                            offset: const Offset(0, 1),
                            blurRadius: 1,
                          ),
                        ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsOverview(User user) {
    final topStats = _getTopStats(user);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? SoloLevelingColors.shadowDepth.withValues(alpha: 0.3)
            : const Color(0xFFF1F5F9), // Light blue-gray for light mode
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? SoloLevelingColors.electricBlue.withValues(alpha: 0.2)
              : const Color(0xFF1E40AF).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: topStats.map((stat) => _buildQuickStatItem(stat)).toList(),
      ),
    );
  }

  Widget _buildQuickStatItem(MapEntry<StatType, double> stat) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statColor = isDark
        ? stat.key.color
        : _getLightModeStatColor(stat.key.color);

    return Column(
      children: [
        Icon(stat.key.icon, color: statColor, size: 16),
        const SizedBox(height: 4),
        Text(
          stat.value.toStringAsFixed(1),
          style: SoloLevelingTypography.statValue.copyWith(
            fontSize: 14,
            color: statColor,
          ),
        ),
        Text(
          stat.key.displayName,
          style: SoloLevelingTypography.statLabel.copyWith(
            fontSize: 8,
            color: isDark
                ? SoloLevelingColors.silverMist
                : const Color(0xFF374151), // Darker for better contrast
            fontWeight: FontWeight.w600,
            shadows: isDark
                ? null
                : [
                    Shadow(
                      color: Colors.white.withValues(alpha: 0.8),
                      offset: const Offset(0, 1),
                      blurRadius: 1,
                    ),
                  ],
          ),
        ),
      ],
    );
  }

  Color _getLightModeStatColor(Color darkColor) {
    // Map dark mode stat colors to appropriate light mode colors with better contrast
    if (darkColor == const Color(0xFFE03131)) {
      // Strength red
      return const Color(0xFFDC2626);
    } else if (darkColor == const Color(0xFF2B8A3E)) {
      // Agility green
      return const Color(0xFF059669);
    } else if (darkColor == const Color(0xFFE8590C)) {
      // Endurance orange
      return const Color(0xFFEA580C);
    } else if (darkColor == const Color(0xFF1864AB)) {
      // Intelligence blue
      return const Color(0xFF1E40AF);
    } else if (darkColor == const Color(0xFF7048E8)) {
      // Focus purple
      return const Color(0xFF7C3AED);
    } else if (darkColor == const Color(0xFFE67700)) {
      // Charisma yellow
      return const Color(0xFFD97706);
    }
    return darkColor; // Fallback to original color
  }

  Widget _buildDetailedHeader(User user, HunterRankData rankData) {
    return Row(
      children: [
        _buildAvatarSection(user, rankData, size: 80),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHunterName(user, size: 28),
              const SizedBox(height: 8),
              _buildHunterTitle(rankData, size: 16),
              const SizedBox(height: 12),
              _buildDetailedInfo(user, rankData),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedInfo(User user, HunterRankData rankData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hunter ID: ${user.id.substring(0, 8).toUpperCase()}',
          style: SoloLevelingTypography.systemNotification.copyWith(
            fontSize: 12,
            color: SoloLevelingColors.silverMist,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Registered: ${_formatDate(user.createdAt)}',
          style: SoloLevelingTypography.systemNotification.copyWith(
            fontSize: 12,
            color: SoloLevelingColors.silverMist,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Last Active: ${_formatDate(user.lastActive)}',
          style: SoloLevelingTypography.systemNotification.copyWith(
            fontSize: 12,
            color: SoloLevelingColors.silverMist,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedStats(User user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SoloLevelingColors.shadowDepth.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: SoloLevelingColors.electricBlue.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Core Stats',
            style: SoloLevelingTypography.hunterSubtitle.copyWith(
              fontSize: 18,
              color: SoloLevelingColors.electricBlue,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatsGrid(user),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(User user) {
    final stats = StatType.values;
    
    // Horizontal scrollable single row layout to prevent overflow completely
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: stats.map((stat) {
          final value = user.getStat(stat);
          return Padding(
            padding: const EdgeInsets.only(right: 12), // Increased spacing
            child: _buildMiniStatItem(stat, value),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMiniStatItem(StatType stat, double value) {
    return Container(
      width: 80, // Increased size for better visibility
      height: 65, // Optimized height to prevent overflow
      padding: const EdgeInsets.all(6), // Optimized for content fit
      decoration: BoxDecoration(
        color: stat.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10), // Increased from 6
        border: Border.all(color: stat.color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(stat.icon, color: stat.color, size: 18), // Increased from 12
          const SizedBox(height: 2), // Reduced spacing to prevent overflow
          Text(
            value.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 14, // Increased from 10
              color: stat.color,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            stat.displayName.length > 6 ? stat.displayName.substring(0, 6) : stat.displayName,
            style: TextStyle(
              fontSize: 8, // Increased from 5
              color: SoloLevelingColors.silverMist,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }


  Widget _buildDetailedProgression(User user, HunterRankData rankData) {
    final nextRank = _rankService.getNextRank(user.level);
    final levelsToNextRank = nextRank != null
        ? _rankService.getLevelsToNextRank(user.level)
        : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SoloLevelingColors.shadowDepth.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: rankData.lightColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progression',
            style: SoloLevelingTypography.hunterSubtitle.copyWith(
              fontSize: 18,
              color: rankData.lightColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildLevelProgressExpanded(user),
          if (nextRank != null) ...[
            const SizedBox(height: 16),
            _buildNextRankInfo(nextRank, levelsToNextRank),
          ],
        ],
      ),
    );
  }

  Widget _buildNextRankInfo(HunterRankData nextRank, int levelsToNextRank) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: nextRank.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: nextRank.lightColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          HunterRankBadge(
            rank: nextRank.rank,
            size: HunterRankBadgeSize.small,
            enableAnimations: false,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next Rank: ${nextRank.name}',
                  style: SoloLevelingTypography.systemNotification.copyWith(
                    fontSize: 14,
                    color: nextRank.lightColor,
                  ),
                ),
                Text(
                  '$levelsToNextRank levels remaining',
                  style: SoloLevelingTypography.systemNotification.copyWith(
                    fontSize: 12,
                    color: SoloLevelingColors.silverMist,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      width: widget.width ?? _getCardWidth(),
      height: widget.height ?? _getCardHeight(),
      margin: widget.margin ?? const EdgeInsets.all(16),
      child: GlassmorphismEffects.hunterPanel(
        child: const Center(
          child: CircularProgressIndicator(
            color: SoloLevelingColors.electricBlue,
          ),
        ),
      ),
    );
  }

  List<MapEntry<StatType, double>> _getTopStats(User user) {
    final stats = StatType.values
        .map((stat) => MapEntry(stat, user.getStat(stat)))
        .toList();
    stats.sort((a, b) => b.value.compareTo(a.value));
    return stats.take(3).toList();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return 'Just now';
    }
  }

  double _getCardWidth() {
    switch (widget.displayMode) {
      case HunterProfileDisplayMode.compact:
        return double.infinity;
      case HunterProfileDisplayMode.expanded:
        return double.infinity;
      case HunterProfileDisplayMode.detailed:
        return double.infinity;
    }
  }

  double _getCardHeight() {
    switch (widget.displayMode) {
      case HunterProfileDisplayMode.compact:
        return 80;
      case HunterProfileDisplayMode.expanded:
        return 200;
      case HunterProfileDisplayMode.detailed:
        return 400;
    }
  }

}

/// Display modes for the Hunter Profile Card
enum HunterProfileDisplayMode {
  compact, // Minimal info, single row layout
  expanded, // Standard info with stats overview
  detailed, // Full info with detailed stats and progression
}
