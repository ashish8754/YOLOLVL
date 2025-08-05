import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../models/user.dart';
import '../models/enums.dart';
import '../providers/user_provider.dart';
import '../services/hunter_rank_service.dart';
import '../theme/solo_leveling_theme.dart';
import '../theme/glassmorphism_effects.dart';

/// Hunter Stats Panel component displaying all 6 core stats with Solo Leveling styling
/// Features animated progress indicators, stat bonuses, and detailed breakdowns
class HunterStatsPanel extends StatefulWidget {
  final HunterStatsPanelMode displayMode;
  final bool showStatBonuses;
  final bool showStatComparisons;
  final bool enableAnimations;
  final VoidCallback? onStatTap;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;

  const HunterStatsPanel({
    super.key,
    this.displayMode = HunterStatsPanelMode.overview,
    this.showStatBonuses = true,
    this.showStatComparisons = false,
    this.enableAnimations = true,
    this.onStatTap,
    this.margin,
    this.width,
    this.height,
  });

  @override
  State<HunterStatsPanel> createState() => _HunterStatsPanelState();
}

class _HunterStatsPanelState extends State<HunterStatsPanel>
    with TickerProviderStateMixin {
  late AnimationController _statsAnimationController;
  late AnimationController _pulseController;
  late List<AnimationController> _statControllers;
  late List<Animation<double>> _statAnimations;
  late Animation<double> _pulseAnimation;

  final HunterRankService _rankService = HunterRankService.instance;
  StatType? _selectedStat;
  bool _showDetailedBreakdown = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Main stats reveal animation
    _statsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Pulse effect for stat updates
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Individual stat animations
    _statControllers = StatType.values.map((stat) {
      return AnimationController(
        duration: Duration(milliseconds: 800 + (StatType.values.indexOf(stat) * 100)),
        vsync: this,
      );
    }).toList();

    _statAnimations = _statControllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.elasticOut,
      ));
    }).toList();

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Start initial animation
    if (widget.enableAnimations) {
      _startStatsAnimation();
    } else {
      // Set all animations to complete state
      _statsAnimationController.value = 1.0;
      for (final controller in _statControllers) {
        controller.value = 1.0;
      }
    }
  }

  void _startStatsAnimation() {
    _statsAnimationController.forward();
    
    // Stagger individual stat animations
    for (int i = 0; i < _statControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) {
          _statControllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _statsAnimationController.dispose();
    _pulseController.dispose();
    for (final controller in _statControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.currentUser;
        if (user == null) {
          return _buildLoadingPanel();
        }

        final rankData = _rankService.getRankForLevel(user.level);
        
        return _buildStatsPanel(user, rankData);
      },
    );
  }

  Widget _buildStatsPanel(User user, HunterRankData rankData) {
    return Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin ?? const EdgeInsets.all(16),
      child: GlassmorphismEffects.systemPanel(
        isActive: _selectedStat != null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPanelHeader(rankData),
            const SizedBox(height: 16),
            Expanded(
              child: _buildStatsContent(user, rankData),
            ),
            if (_showDetailedBreakdown && _selectedStat != null) ...[
              const SizedBox(height: 16),
              _buildStatBreakdown(user, _selectedStat!, rankData),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPanelHeader(HunterRankData rankData) {
    return Row(
      children: [
        Icon(
          Icons.analytics_outlined,
          color: SoloLevelingColors.electricBlue,
          size: 24,
        ),
        const SizedBox(width: 12),
        Text(
          'Hunter Stats',
          style: SoloLevelingTypography.hunterSubtitle.copyWith(
            fontSize: 20,
            color: SoloLevelingColors.electricBlue,
          ),
        ),
        const Spacer(),
        if (widget.displayMode == HunterStatsPanelMode.detailed)
          IconButton(
            onPressed: () {
              setState(() {
                _showDetailedBreakdown = !_showDetailedBreakdown;
              });
            },
            icon: Icon(
              _showDetailedBreakdown ? Icons.expand_less : Icons.expand_more,
              color: SoloLevelingColors.silverMist,
            ),
          ),
      ],
    );
  }

  Widget _buildStatsContent(User user, HunterRankData rankData) {
    switch (widget.displayMode) {
      case HunterStatsPanelMode.compact:
        return _buildCompactStats(user, rankData);
      case HunterStatsPanelMode.overview:
        return _buildOverviewStats(user, rankData);
      case HunterStatsPanelMode.detailed:
        return _buildDetailedStats(user, rankData);
    }
  }

  Widget _buildCompactStats(User user, HunterRankData rankData) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: StatType.values.asMap().entries.map((entry) {
          final index = entry.key;
          final stat = entry.value;
          final value = user.getStat(stat);
          
          return AnimatedBuilder(
            animation: _statAnimations[index],
            builder: (context, child) {
              return Transform.scale(
                scale: _statAnimations[index].value,
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 12),
                  child: _buildCompactStatItem(stat, value, rankData),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCompactStatItem(StatType stat, double value, HunterRankData rankData) {
    return GestureDetector(
      onTap: () => _onStatTapped(stat),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: stat.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: stat.color.withValues(alpha: _selectedStat == stat ? 0.6 : 0.3),
            width: _selectedStat == stat ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              stat.icon,
              color: stat.color,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              value.toStringAsFixed(1),
              style: SoloLevelingTypography.statValue.copyWith(
                fontSize: 16,
                color: stat.color,
              ),
            ),
            Text(
              stat.displayName,
              style: SoloLevelingTypography.statLabel.copyWith(
                fontSize: 8,
                color: SoloLevelingColors.silverMist,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewStats(User user, HunterRankData rankData) {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 2.2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: StatType.values.asMap().entries.map((entry) {
        final index = entry.key;
        final stat = entry.value;
        final value = user.getStat(stat);
        
        return AnimatedBuilder(
          animation: _statAnimations[index],
          builder: (context, child) {
            return Transform.scale(
              scale: _statAnimations[index].value,
              child: _buildOverviewStatItem(stat, value, rankData),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildOverviewStatItem(StatType stat, double value, HunterRankData rankData) {
    final bonus = widget.showStatBonuses ? _calculateStatBonus(value, rankData) : 0.0;
    
    return GestureDetector(
      onTap: () => _onStatTapped(stat),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              stat.color.withValues(alpha: 0.1),
              stat.color.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: stat.color.withValues(alpha: _selectedStat == stat ? 0.6 : 0.3),
            width: _selectedStat == stat ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: stat.color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                stat.icon,
                color: stat.color,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    stat.displayName,
                    style: SoloLevelingTypography.systemNotification.copyWith(
                      fontSize: 12,
                      color: SoloLevelingColors.ghostWhite,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value.toStringAsFixed(1),
                    style: SoloLevelingTypography.statValue.copyWith(
                      fontSize: 20,
                      color: stat.color,
                    ),
                  ),
                  if (widget.showStatBonuses && bonus > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      '+${bonus.toStringAsFixed(1)} bonus',
                      style: SoloLevelingTypography.statLabel.copyWith(
                        fontSize: 10,
                        color: SoloLevelingColors.hunterGreen,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedStats(User user, HunterRankData rankData) {
    return SingleChildScrollView(
      child: Column(
        children: StatType.values.asMap().entries.map((entry) {
          final index = entry.key;
          final stat = entry.value;
          final value = user.getStat(stat);
          
          return AnimatedBuilder(
            animation: _statAnimations[index],
            builder: (context, child) {
              return Transform.scale(
                scale: _statAnimations[index].value,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: _buildDetailedStatItem(stat, value, rankData),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDetailedStatItem(StatType stat, double value, HunterRankData rankData) {
    final bonus = widget.showStatBonuses ? _calculateStatBonus(value, rankData) : 0.0;
    final totalValue = value + bonus;
    final progress = _calculateStatProgress(value);
    
    return GestureDetector(
      onTap: () => _onStatTapped(stat),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              stat.color.withValues(alpha: 0.15),
              stat.color.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: stat.color.withValues(alpha: _selectedStat == stat ? 0.8 : 0.4),
            width: _selectedStat == stat ? 3 : 2,
          ),
          boxShadow: _selectedStat == stat ? [
            BoxShadow(
              color: stat.color.withValues(alpha: 0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ] : null,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: stat.color.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    stat.icon,
                    color: stat.color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stat.displayName,
                        style: SoloLevelingTypography.hunterSubtitle.copyWith(
                          fontSize: 18,
                          color: SoloLevelingColors.ghostWhite,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            value.toStringAsFixed(1),
                            style: SoloLevelingTypography.statValue.copyWith(
                              fontSize: 24,
                              color: stat.color,
                            ),
                          ),
                          if (widget.showStatBonuses && bonus > 0) ...[
                            Text(
                              ' + ${bonus.toStringAsFixed(1)}',
                              style: SoloLevelingTypography.statValue.copyWith(
                                fontSize: 18,
                                color: SoloLevelingColors.hunterGreen,
                              ),
                            ),
                            Text(
                              ' = ${totalValue.toStringAsFixed(1)}',
                              style: SoloLevelingTypography.statValue.copyWith(
                                fontSize: 20,
                                color: SoloLevelingColors.electricBlue,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: SoloLevelingTypography.systemNotification.copyWith(
                        fontSize: 14,
                        color: stat.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getStatRank(value),
                      style: SoloLevelingTypography.statLabel.copyWith(
                        fontSize: 10,
                        color: SoloLevelingColors.silverMist,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatProgressBar(stat, progress),
            if (widget.showStatComparisons) ...[
              const SizedBox(height: 12),
              _buildStatComparison(stat, value),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatProgressBar(StatType stat, double progress) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: SoloLevelingColors.shadowGray.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation<Color>(stat.color),
          minHeight: 8,
        ),
      ),
    );
  }

  Widget _buildStatComparison(StatType stat, double value) {
    final averageValue = _getAverageStat();
    final isAboveAverage = value > averageValue;
    
    return Row(
      children: [
        Icon(
          isAboveAverage ? Icons.trending_up : Icons.trending_down,
          color: isAboveAverage ? SoloLevelingColors.hunterGreen : SoloLevelingColors.crimsonRed,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          isAboveAverage 
              ? '${((value / averageValue - 1) * 100).toInt()}% above average'
              : '${((1 - value / averageValue) * 100).toInt()}% below average',
          style: SoloLevelingTypography.systemNotification.copyWith(
            fontSize: 12,
            color: isAboveAverage ? SoloLevelingColors.hunterGreen : SoloLevelingColors.crimsonRed,
          ),
        ),
      ],
    );
  }

  Widget _buildStatBreakdown(User user, StatType stat, HunterRankData rankData) {
    final baseValue = user.getStat(stat);
    final bonus = _calculateStatBonus(baseValue, rankData);
    final benefits = _getStatBenefits(stat, baseValue);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: stat.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: stat.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${stat.displayName} Breakdown',
            style: SoloLevelingTypography.hunterSubtitle.copyWith(
              fontSize: 16,
              color: stat.color,
            ),
          ),
          const SizedBox(height: 12),
          _buildBreakdownRow('Base Value', baseValue.toStringAsFixed(1), stat.color),
          if (bonus > 0)
            _buildBreakdownRow('Rank Bonus', '+${bonus.toStringAsFixed(1)}', SoloLevelingColors.hunterGreen),
          const Divider(color: SoloLevelingColors.shadowGray),
          _buildBreakdownRow('Total', (baseValue + bonus).toStringAsFixed(1), SoloLevelingColors.electricBlue),
          const SizedBox(height: 12),
          Text(
            'Benefits:',
            style: SoloLevelingTypography.systemNotification.copyWith(
              fontSize: 14,
              color: SoloLevelingColors.ghostWhite,
            ),
          ),
          const SizedBox(height: 8),
          ...benefits.map((benefit) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '• $benefit',
              style: SoloLevelingTypography.systemNotification.copyWith(
                fontSize: 12,
                color: SoloLevelingColors.silverMist,
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: SoloLevelingTypography.systemNotification.copyWith(
              fontSize: 12,
              color: SoloLevelingColors.silverMist,
            ),
          ),
          Text(
            value,
            style: SoloLevelingTypography.systemNotification.copyWith(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingPanel() {
    return Container(
      width: widget.width,
      height: widget.height ?? 300,
      margin: widget.margin ?? const EdgeInsets.all(16),
      child: GlassmorphismEffects.systemPanel(
        child: const Center(
          child: CircularProgressIndicator(
            color: SoloLevelingColors.electricBlue,
          ),
        ),
      ),
    );
  }

  void _onStatTapped(StatType stat) {
    setState(() {
      _selectedStat = _selectedStat == stat ? null : stat;
    });
    
    if (widget.enableAnimations) {
      _pulseController.forward().then((_) {
        _pulseController.reverse();
      });
    }
    
    widget.onStatTap?.call();
  }

  double _calculateStatBonus(double baseValue, HunterRankData rankData) {
    return baseValue * rankData.statBonus;
  }

  double _calculateStatProgress(double value) {
    // Logarithmic scale for infinite progression
    return (math.log(value) / math.log(100)).clamp(0.0, 1.0);
  }

  double _getAverageStat() {
    // This could be calculated from user data or use a global average
    return 5.0; // Placeholder average
  }

  String _getStatRank(double value) {
    if (value >= 50) return 'LEGENDARY';
    if (value >= 25) return 'ELITE';
    if (value >= 15) return 'EXPERT';
    if (value >= 10) return 'SKILLED';
    if (value >= 5) return 'TRAINED';
    return 'NOVICE';
  }

  List<String> _getStatBenefits(StatType stat, double value) {
    switch (stat) {
      case StatType.strength:
        return [
          'Increased physical power',
          'Better workout efficiency',
          'Enhanced stamina recovery',
        ];
      case StatType.agility:
        return [
          'Improved reaction time',
          'Better movement efficiency',
          'Enhanced coordination',
        ];
      case StatType.endurance:
        return [
          'Increased activity duration',
          'Faster recovery times',
          'Better stress resistance',
        ];
      case StatType.intelligence:
        return [
          'Enhanced learning speed',
          'Better problem solving',
          'Improved memory retention',
        ];
      case StatType.focus:
        return [
          'Increased concentration',
          'Better task completion',
          'Enhanced productivity',
        ];
      case StatType.charisma:
        return [
          'Improved social interactions',
          'Better leadership abilities',
          'Enhanced communication',
        ];
    }
  }
}

/// Display modes for the Hunter Stats Panel
enum HunterStatsPanelMode {
  compact,    // Horizontal scrollable stat chips
  overview,   // 2-column grid with basic info
  detailed,   // Full stat breakdown with progress bars
}