import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/activity_log.dart';
import '../theme/solo_leveling_theme.dart';
import '../widgets/solo_leveling_icon.dart';

/// Quest-themed card widget that displays activity logs as quest entries
/// Transforms the Solo Leveling activity system into an RPG quest interface
class QuestCard extends StatefulWidget {
  final ActivityLog quest;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  final bool showDeleteOption;
  final bool isDeleting;

  const QuestCard({
    super.key,
    required this.quest,
    this.onDelete,
    this.onTap,
    this.showDeleteOption = true,
    this.isDeleting = false,
  });

  @override
  State<QuestCard> createState() => _QuestCardState();
}

class _QuestCardState extends State<QuestCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _glowAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Start subtle glow animation
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String get _questDifficulty {
    final duration = widget.quest.durationMinutes;
    if (duration <= 15) return 'Easy';
    if (duration <= 45) return 'Normal';
    if (duration <= 90) return 'Hard';
    return 'Elite';
  }

  Color get _difficultyColor {
    final duration = widget.quest.durationMinutes;
    if (duration <= 15) return HunterRankColors.cRank;
    if (duration <= 45) return HunterRankColors.bRank;
    if (duration <= 90) return HunterRankColors.aRank;
    return HunterRankColors.sRank;
  }

  IconData get _questStatusIcon {
    // Since this is a completed quest (from history), always show completed
    return Icons.check_circle;
  }

  @override
  Widget build(BuildContext context) {
    final questType = widget.quest.activityTypeEnum;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _isHovered = true),
      onTapUp: (_) => setState(() => _isHovered = false),
      onTapCancel: () => setState(() => _isHovered = false),
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: SoloLevelingColors.electricBlue.withValues(
                  alpha: 0.3 + (_glowAnimation.value * 0.2)
                ),
                width: 1.5,
              ),
              boxShadow: [
                // Electric blue glow effect
                BoxShadow(
                  color: SoloLevelingColors.electricBlue.withValues(
                    alpha: _glowAnimation.value * 0.2
                  ),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
                // Depth shadow
                BoxShadow(
                  color: SoloLevelingColors.voidBlack.withValues(alpha: 0.5),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      SoloLevelingColors.shadowDepth.withValues(alpha: 0.95),
                      SoloLevelingColors.midnightBase.withValues(alpha: 0.98),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Quest content
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Quest header with icon, name, and status
                          Row(
                            children: [
                              // Quest type icon with glow
                              SoloLevelingIcon.quest(
                                activityType: questType.name,
                                size: 28,
                                hasGlow: true,
                                glowIntensity: 0.6,
                                semanticLabel: '${questType.displayName} quest icon',
                              ),
                              
                              const SizedBox(width: 12),
                              
                              // Quest info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Quest name (activity type)
                                    Text(
                                      'Quest: ${questType.displayName}',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        color: SoloLevelingColors.ghostWhite,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 4),
                                    
                                    // Quest completion time
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 14,
                                          color: SoloLevelingColors.silverMist,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Completed ${_formatQuestTime(widget.quest.timestamp)}',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: SoloLevelingColors.silverMist,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Quest status and menu
                              Column(
                                children: [
                                  Icon(
                                    _questStatusIcon,
                                    color: SoloLevelingColors.hunterGreen,
                                    size: 24,
                                  ),
                                  if (widget.showDeleteOption)
                                    PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'delete' && widget.onDelete != null) {
                                          _showDeleteConfirmation(context);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.delete_sweep,
                                                size: 16,
                                                color: SoloLevelingColors.crimsonRed,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Reverse Quest',
                                                style: TextStyle(
                                                  color: SoloLevelingColors.crimsonRed,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      icon: Icon(
                                        Icons.more_vert,
                                        color: SoloLevelingColors.silverMist,
                                        size: 18,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Quest details row
                          Row(
                            children: [
                              // Quest difficulty
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _difficultyColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _difficultyColor.withValues(alpha: 0.4),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.trending_up,
                                      size: 14,
                                      color: _difficultyColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _questDifficulty,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _difficultyColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(width: 12),
                              
                              // Quest duration
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: SoloLevelingColors.electricBlue.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: SoloLevelingColors.electricBlue.withValues(alpha: 0.4),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.schedule,
                                      size: 14,
                                      color: SoloLevelingColors.electricBlue,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${widget.quest.durationMinutes}m',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: SoloLevelingColors.electricBlue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Quest rewards section
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: SoloLevelingColors.hunterGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: SoloLevelingColors.hunterGreen.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Rewards header
                                Row(
                                  children: [
                                    Icon(
                                      Icons.card_giftcard,
                                      size: 16,
                                      color: SoloLevelingColors.hunterGreen,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Quest Rewards:',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: SoloLevelingColors.hunterGreen,
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 8),
                                
                                // Rewards list
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    // EXP reward
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: SoloLevelingColors.electricBlue.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.flash_on,
                                            size: 12,
                                            color: SoloLevelingColors.electricBlue,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '+${widget.quest.expGained.toInt()} EXP',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: SoloLevelingColors.electricBlue,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Stat rewards
                                    ...widget.quest.statGainsMap.entries.map((entry) {
                                      final statType = entry.key;
                                      final gain = entry.value;
                                      
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statType.color.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SoloLevelingIcon.stat(
                                              statName: statType.name,
                                              size: 12,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '+${gain.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: statType.color,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          // Quest description/notes
                          if (widget.quest.notes != null && widget.quest.notes!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: SoloLevelingColors.shadowDepth.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: SoloLevelingColors.silverMist.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.note_alt,
                                        size: 14,
                                        color: SoloLevelingColors.silverMist,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Quest Notes:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: SoloLevelingColors.silverMist,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    widget.quest.notes!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: SoloLevelingColors.ghostWhite.withValues(alpha: 0.8),
                                      fontStyle: FontStyle.italic,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // Loading overlay when deleting
                    if (widget.isDeleting)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: SoloLevelingColors.voidBlack.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      SoloLevelingColors.crimsonRed,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Reversing Quest...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: SoloLevelingColors.ghostWhite,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SoloLevelingColors.shadowDepth,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: SoloLevelingColors.crimsonRed.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber,
              color: SoloLevelingColors.crimsonRed,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'Reverse Quest',
              style: TextStyle(
                color: SoloLevelingColors.ghostWhite,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to reverse this ${widget.quest.activityTypeEnum.displayName} quest?',
              style: TextStyle(
                fontSize: 16,
                color: SoloLevelingColors.ghostWhite,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SoloLevelingColors.crimsonRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: SoloLevelingColors.crimsonRed.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: SoloLevelingColors.crimsonRed,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'This will reverse:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: SoloLevelingColors.crimsonRed,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• ${widget.quest.expGained.toInt()} EXP',
                    style: TextStyle(
                      color: SoloLevelingColors.ghostWhite,
                      fontSize: 13,
                    ),
                  ),
                  ...widget.quest.statGainsMap.entries.map((entry) => 
                    Text(
                      '• ${entry.key.displayName}: ${entry.value.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: SoloLevelingColors.ghostWhite,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This action cannot be undone.',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: SoloLevelingColors.silverMist,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: SoloLevelingColors.silverMist),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: SoloLevelingColors.crimsonRed,
              foregroundColor: SoloLevelingColors.pureLight,
            ),
            child: const Text('Reverse Quest'),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.onDelete != null) {
      // Provide haptic feedback
      HapticFeedback.mediumImpact();
      widget.onDelete!();
    }
  }

  String _formatQuestTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      final hour = dateTime.hour;
      final minute = dateTime.minute;
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      
      return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
    }
  }
}