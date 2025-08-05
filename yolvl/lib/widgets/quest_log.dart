import 'package:flutter/material.dart';
import '../models/activity_log.dart';
import '../theme/solo_leveling_theme.dart';
import '../widgets/quest_card.dart';

/// Quest Log widget that displays activity history as a quest journal
/// Transforms the activity history into an RPG-style quest log interface
class QuestLog extends StatelessWidget {
  final List<ActivityLog> quests;
  final ScrollController scrollController;
  final bool isLoadingMore;
  final bool hasMoreData;
  final Function(String) onDeleteQuest;
  final bool isDeleting;

  const QuestLog({
    super.key,
    required this.quests,
    required this.scrollController,
    required this.isLoadingMore,
    required this.hasMoreData,
    required this.onDeleteQuest,
    this.isDeleting = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Stack(
      children: [
        // Background pattern - theme aware
        Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      SoloLevelingColors.midnightBase,
                      SoloLevelingColors.shadowDepth,
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFFFAFAFA),
                      const Color(0xFFF5F5F5),
                    ],
                  ),
          ),
        ),
        
        // Quest log content
        CustomScrollView(
          controller: scrollController,
          slivers: [
            // Quest log header
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: isDark
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            SoloLevelingColors.electricBlue.withValues(alpha: 0.1),
                            SoloLevelingColors.mysticPurple.withValues(alpha: 0.1),
                          ],
                        )
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF1E40AF).withValues(alpha: 0.05),
                            const Color(0xFF7C3AED).withValues(alpha: 0.05),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? SoloLevelingColors.electricBlue.withValues(alpha: 0.3)
                        : const Color(0xFF1E40AF).withValues(alpha: 0.2),
                    width: 1,
                  ),
                  boxShadow: isDark
                      ? [
                          BoxShadow(
                            color: SoloLevelingColors.electricBlue.withValues(alpha: 0.2),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Column(
                  children: [
                    // Quest log icon and title
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? SoloLevelingColors.electricBlue.withValues(alpha: 0.2)
                                : const Color(0xFF1E40AF).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? SoloLevelingColors.electricBlue.withValues(alpha: 0.4)
                                  : const Color(0xFF1E40AF).withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.book,
                            color: isDark
                                ? SoloLevelingColors.electricBlue
                                : const Color(0xFF1E40AF),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quest Journal',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? SoloLevelingColors.ghostWhite
                                      : const Color(0xFF1F2937),
                                  letterSpacing: 1.0,
                                ),
                              ),
                              Text(
                                'Record of completed quests and adventures',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? SoloLevelingColors.silverMist
                                      : const Color(0xFF6B7280),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Quest statistics
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? SoloLevelingColors.shadowDepth.withValues(alpha: 0.5)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? SoloLevelingColors.silverMist.withValues(alpha: 0.2)
                              : const Color(0xFFE5E7EB),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildQuestStat(
                            context,
                            icon: Icons.assignment_turned_in,
                            label: 'Completed',
                            value: quests.length.toString(),
                            color: isDark
                                ? SoloLevelingColors.hunterGreen
                                : const Color(0xFF059669),
                          ),
                          _buildQuestStat(
                            context,
                            icon: Icons.flash_on,
                            label: 'Total EXP',
                            value: _calculateTotalEXP().toString(),
                            color: isDark
                                ? SoloLevelingColors.electricBlue
                                : const Color(0xFF1E40AF),
                          ),
                          _buildQuestStat(
                            context,
                            icon: Icons.trending_up,
                            label: 'Progress',
                            value: _getQuestRank(),
                            color: isDark
                                ? SoloLevelingColors.goldRank
                                : const Color(0xFFD97706),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Quest entries
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == quests.length) {
                      // Loading indicator at the bottom
                      return Container(
                        padding: const EdgeInsets.all(20),
                        alignment: Alignment.center,
                        child: isLoadingMore
                            ? Column(
                                children: [
                                  SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        SoloLevelingColors.electricBlue,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Loading more quests...',
                                    style: TextStyle(
                                      color: SoloLevelingColors.silverMist,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      );
                    }

                    final quest = quests[index];
                    final isFirstOfDay = index == 0 || 
                        !_isSameDay(quest.timestamp, quests[index - 1].timestamp);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date separator
                        if (isFirstOfDay)
                          Container(
                            margin: EdgeInsets.only(
                              bottom: 12,
                              top: index == 0 ? 0 : 24,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          SoloLevelingColors.electricBlue.withValues(alpha: 0.5),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 16),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: SoloLevelingColors.electricBlue.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: SoloLevelingColors.electricBlue.withValues(alpha: 0.4),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 14,
                                        color: SoloLevelingColors.electricBlue,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _formatQuestDate(quest.timestamp),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: SoloLevelingColors.electricBlue,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          SoloLevelingColors.electricBlue.withValues(alpha: 0.5),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        // Quest card
                        QuestCard(
                          quest: quest,
                          onDelete: () => onDeleteQuest(quest.id),
                          isDeleting: isDeleting,
                        ),
                      ],
                    );
                  },
                  childCount: quests.length + (hasMoreData ? 1 : 0),
                ),
              ),
            ),
            
            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),
          ],
        ),
        
        // Deletion progress indicator
        if (isDeleting && quests.isNotEmpty)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    SoloLevelingColors.crimsonRed.withValues(alpha: 0.8),
                    SoloLevelingColors.crimsonRed,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: SoloLevelingColors.crimsonRed.withValues(alpha: 0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  SoloLevelingColors.crimsonRed,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuestStat(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withValues(alpha: isDark ? 0.4 : 0.3),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
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
            color: isDark
                ? SoloLevelingColors.silverMist
                : const Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  String _formatQuestDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final questDate = DateTime(date.year, date.month, date.day);

    if (questDate == today) {
      return 'Today\'s Quests';
    } else if (questDate == yesterday) {
      return 'Yesterday\'s Quests';
    } else {
      final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      
      return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
    }
  }

  int _calculateTotalEXP() {
    return quests.fold(0, (sum, quest) => sum + quest.expGained.toInt());
  }

  String _getQuestRank() {
    final totalQuests = quests.length;
    if (totalQuests < 10) return 'Novice';
    if (totalQuests < 25) return 'Rookie';
    if (totalQuests < 50) return 'Hunter';
    if (totalQuests < 100) return 'Elite';
    if (totalQuests < 250) return 'Master';
    return 'Legend';
  }
}

/// Empty state widget for when no quests are available
class EmptyQuestLog extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onGetStarted;

  const EmptyQuestLog({
    super.key,
    this.title = 'No quests completed yet',
    this.subtitle = 'Start your hunter journey by completing your first quest!',
    this.onGetStarted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Empty state illustration
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  SoloLevelingColors.electricBlue.withValues(alpha: 0.2),
                  SoloLevelingColors.electricBlue.withValues(alpha: 0.05),
                  Colors.transparent,
                ],
              ),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.auto_stories,
              size: 60,
              color: SoloLevelingColors.electricBlue.withValues(alpha: 0.6),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Title
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: SoloLevelingColors.ghostWhite,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 12),
          
          // Subtitle
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: SoloLevelingColors.silverMist,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          
          if (onGetStarted != null) ...[
            const SizedBox(height: 32),
            
            // Get started button
            ElevatedButton.icon(
              onPressed: onGetStarted,
              style: ElevatedButton.styleFrom(
                backgroundColor: SoloLevelingColors.hunterGreen,
                foregroundColor: SoloLevelingColors.pureLight,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 8,
                shadowColor: SoloLevelingColors.hunterGreen.withValues(alpha: 0.5),
              ),
              icon: const Icon(Icons.play_arrow, size: 20),
              label: const Text(
                'Start Your Journey',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}