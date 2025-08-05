import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/activity_provider.dart';
import '../models/enums.dart';
import '../theme/solo_leveling_theme.dart';
import '../widgets/solo_leveling_icon.dart';

/// Daily Quest Panel that transforms today's activities into daily quests
/// Shows current progress, available quests, and rewards for daily activities
class DailyQuestPanel extends StatefulWidget {
  final VoidCallback? onQuestTap;

  const DailyQuestPanel({
    super.key,
    this.onQuestTap,
  });

  @override
  State<DailyQuestPanel> createState() => _DailyQuestPanelState();
}

class _DailyQuestPanelState extends State<DailyQuestPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserProvider, ActivityProvider>(
      builder: (context, userProvider, activityProvider, child) {
        final todaysQuests = activityProvider.recentActivities.take(3).toList();
        final todaysQuestCount = activityProvider.getTodaysActivityCount();
        final todaysEXP = activityProvider.getTodaysEXP();

        return AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: SoloLevelingColors.electricBlue.withValues(
                    alpha: 0.4 + (_glowAnimation.value * 0.3)
                  ),
                  width: 2,
                ),
                boxShadow: [
                  // Main glow effect
                  BoxShadow(
                    color: SoloLevelingColors.electricBlue.withValues(
                      alpha: _glowAnimation.value * 0.3
                    ),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                  // Depth shadow
                  BoxShadow(
                    color: SoloLevelingColors.voidBlack.withValues(alpha: 0.6),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        SoloLevelingColors.shadowDepth.withValues(alpha: 0.95),
                        SoloLevelingColors.midnightBase.withValues(alpha: 0.98),
                        SoloLevelingColors.deepShadow.withValues(alpha: 0.95),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Background pattern
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _QuestPanelPatternPainter(
                            color: SoloLevelingColors.electricBlue.withValues(alpha: 0.05),
                          ),
                        ),
                      ),
                      
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              children: [
                                // Daily quest icon
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        SoloLevelingColors.electricBlue.withValues(alpha: 0.3),
                                        SoloLevelingColors.mysticPurple.withValues(alpha: 0.3),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: SoloLevelingColors.electricBlue.withValues(alpha: 0.5),
                                      width: 1,
                                    ),
                                  ),
                                  child: SoloLevelingIcon.system(
                                    icon: Icons.today,
                                    size: 28,
                                    hasGlow: true,
                                    isPulsing: true,
                                    semanticLabel: 'Daily quests',
                                  ),
                                ),
                                
                                const SizedBox(width: 16),
                                
                                // Title and status
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Daily Quests',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          color: SoloLevelingColors.ghostWhite,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                      Text(
                                        _getDailyQuestStatus(todaysQuestCount),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: SoloLevelingColors.silverMist,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Quest counter
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: SoloLevelingColors.hunterGreen.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: SoloLevelingColors.hunterGreen.withValues(alpha: 0.4),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.assignment_turned_in,
                                        size: 16,
                                        color: SoloLevelingColors.hunterGreen,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$todaysQuestCount',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: SoloLevelingColors.hunterGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Daily progress summary
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: SoloLevelingColors.electricBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: SoloLevelingColors.electricBlue.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // EXP gained today
                                  Expanded(
                                    child: _buildDailyStat(
                                      context,
                                      icon: Icons.flash_on,
                                      label: 'EXP Earned',
                                      value: '+${todaysEXP.toStringAsFixed(0)}',
                                      color: SoloLevelingColors.electricBlue,
                                    ),
                                  ),
                                  
                                  Container(
                                    width: 1,
                                    height: 40,
                                    color: SoloLevelingColors.silverMist.withValues(alpha: 0.3),
                                  ),
                                  
                                  // Streak info
                                  Expanded(
                                    child: _buildDailyStat(
                                      context,
                                      icon: Icons.local_fire_department,
                                      label: 'Streak',
                                      value: _getStreakText(activityProvider),
                                      color: SoloLevelingColors.goldRank,
                                    ),
                                  ),
                                  
                                  Container(
                                    width: 1,
                                    height: 40,
                                    color: SoloLevelingColors.silverMist.withValues(alpha: 0.3),
                                  ),
                                  
                                  // Quest rank
                                  Expanded(
                                    child: _buildDailyStat(
                                      context,
                                      icon: Icons.military_tech,
                                      label: 'Rank',
                                      value: _getQuestRank(todaysQuestCount),
                                      color: _getQuestRankColor(todaysQuestCount),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Today's completed quests or empty state
                            if (todaysQuests.isNotEmpty) ...[
                              Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 18,
                                    color: SoloLevelingColors.hunterGreen,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Completed Today:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: SoloLevelingColors.ghostWhite,
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // Quest list
                              ...todaysQuests.map((quest) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: SoloLevelingColors.hunterGreen.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: SoloLevelingColors.hunterGreen.withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    SoloLevelingIcon.quest(
                                      activityType: quest.activityTypeEnum.name,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            quest.activityTypeEnum.displayName,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: SoloLevelingColors.ghostWhite,
                                            ),
                                          ),
                                          Text(
                                            '${quest.durationMinutes}min • +${quest.expGained.toInt()} EXP',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: SoloLevelingColors.silverMist,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: SoloLevelingColors.hunterGreen.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'COMPLETE',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: SoloLevelingColors.hunterGreen,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )).toList(),
                            ] else ...[
                              // Empty state
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: SoloLevelingColors.shadowDepth.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: SoloLevelingColors.silverMist.withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.assignment_outlined,
                                      size: 48,
                                      color: SoloLevelingColors.electricBlue.withValues(alpha: 0.6),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No quests completed today',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: SoloLevelingColors.ghostWhite,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Start your daily quest to begin earning EXP!',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: SoloLevelingColors.silverMist,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            
                            const SizedBox(height: 20),
                            
                            // Action button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: widget.onQuestTap,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: SoloLevelingColors.electricBlue,
                                  foregroundColor: SoloLevelingColors.pureLight,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  elevation: 8,
                                  shadowColor: SoloLevelingColors.electricBlue.withValues(alpha: 0.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.add_task, size: 20),
                                label: Text(
                                  todaysQuestCount > 0 ? 'Start New Quest' : 'Begin Daily Quests',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDailyStat(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: SoloLevelingColors.silverMist,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _getDailyQuestStatus(int questCount) {
    if (questCount == 0) {
      return 'Ready to start your adventure';
    } else if (questCount < 3) {
      return 'Making good progress';
    } else if (questCount < 5) {
      return 'Strong dedication today';
    } else {
      return 'Exceptional hunter performance';
    }
  }

  String _getStreakText(ActivityProvider activityProvider) {
    // This would need to be implemented in the activity provider
    // For now, return a placeholder
    return '1 day';
  }

  String _getQuestRank(int questCount) {
    if (questCount == 0) return 'E';
    if (questCount < 2) return 'D';
    if (questCount < 4) return 'C';
    if (questCount < 6) return 'B';
    if (questCount < 8) return 'A';
    return 'S';
  }

  Color _getQuestRankColor(int questCount) {
    if (questCount == 0) return HunterRankColors.eRank;
    if (questCount < 2) return HunterRankColors.dRank;
    if (questCount < 4) return HunterRankColors.cRank;
    if (questCount < 6) return HunterRankColors.bRank;
    if (questCount < 8) return HunterRankColors.aRank;
    return HunterRankColors.sRank;
  }
}

/// Custom painter for the quest panel background pattern
class _QuestPanelPatternPainter extends CustomPainter {
  final Color color;

  _QuestPanelPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    // Draw a subtle grid pattern
    const gridSize = 20.0;
    
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
    
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}