import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/enums.dart';
import '../theme/solo_leveling_theme.dart';
import '../widgets/solo_leveling_icon.dart';

/// Quest Completion Dialog that celebrates activity completion with RPG-style rewards
/// Shows quest rewards, stat gains, and provides epic Solo Leveling themed feedback
class QuestCompletionDialog extends StatefulWidget {
  final ActivityType questType;
  final int duration;
  final double expGained;
  final Map<StatType, double> statGains;
  final String? questNotes;
  final bool leveledUp;
  final int? newLevel;
  final VoidCallback? onClose;

  const QuestCompletionDialog({
    super.key,
    required this.questType,
    required this.duration,
    required this.expGained,
    required this.statGains,
    this.questNotes,
    this.leveledUp = false,
    this.newLevel,
    this.onClose,
  });

  @override
  State<QuestCompletionDialog> createState() => _QuestCompletionDialogState();
}

class _QuestCompletionDialogState extends State<QuestCompletionDialog>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _rewardController;
  late AnimationController _particleController;
  late AnimationController _levelUpController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _rewardSlideAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _particleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Main dialog animation
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Reward reveal animation
    _rewardController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Particle effects animation
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Level up animation (if applicable)
    _levelUpController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Setup animations
    _scaleAnimation = CurvedAnimation(
      parent: _mainController,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeInOut,
    );

    _rewardSlideAnimation = CurvedAnimation(
      parent: _rewardController,
      curve: Curves.bounceOut,
    );

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _particleController,
      curve: Curves.easeInOut,
    ));

    _particleAnimation = CurvedAnimation(
      parent: _particleController,
      curve: Curves.linear,
    );

    // Start animations sequence
    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    // Haptic feedback for quest completion
    HapticFeedback.heavyImpact();
    
    // Start main dialog
    _mainController.forward();
    
    // Start particle effects
    _particleController.repeat();
    
    // Delay before showing rewards
    await Future.delayed(const Duration(milliseconds: 500));
    _rewardController.forward();
    
    // Level up animation if applicable
    if (widget.leveledUp) {
      await Future.delayed(const Duration(milliseconds: 800));
      HapticFeedback.heavyImpact();
      _levelUpController.forward();
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _rewardController.dispose();
    _particleController.dispose();
    _levelUpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        widget.onClose?.call();
        return true;
      },
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Background overlay with particles
            AnimatedBuilder(
              animation: _particleAnimation,
              builder: (context, child) {
                return Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.0,
                      colors: [
                        SoloLevelingColors.electricBlue.withValues(alpha: 0.1),
                        SoloLevelingColors.voidBlack.withValues(alpha: 0.8),
                        SoloLevelingColors.voidBlack.withValues(alpha: 0.95),
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                  child: CustomPaint(
                    painter: _QuestParticlePainter(
                      animation: _particleAnimation,
                      glowIntensity: _glowAnimation.value,
                    ),
                  ),
                );
              },
            ),
            
            // Main dialog
            Center(
              child: AnimatedBuilder(
                animation: _mainController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.9,
                        constraints: const BoxConstraints(maxWidth: 400),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: SoloLevelingColors.electricBlue.withValues(alpha: 0.6),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: SoloLevelingColors.electricBlue.withValues(alpha: 0.4),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                            BoxShadow(
                              color: SoloLevelingColors.voidBlack.withValues(alpha: 0.8),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  SoloLevelingColors.shadowDepth.withValues(alpha: 0.98),
                                  SoloLevelingColors.midnightBase.withValues(alpha: 0.99),
                                  SoloLevelingColors.deepShadow.withValues(alpha: 0.98),
                                ],
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Quest completion header
                                  _buildCompletionHeader(),
                                  
                                  const SizedBox(height: 24),
                                  
                                  // Quest details
                                  _buildQuestDetails(),
                                  
                                  const SizedBox(height: 24),
                                  
                                  // Rewards section
                                  AnimatedBuilder(
                                    animation: _rewardController,
                                    builder: (context, child) {
                                      return Transform.translate(
                                        offset: Offset(0, 50 * (1 - _rewardSlideAnimation.value)),
                                        child: Opacity(
                                          opacity: _rewardSlideAnimation.value,
                                          child: _buildRewardsSection(),
                                        ),
                                      );
                                    },
                                  ),
                                  
                                  // Level up celebration (if applicable)
                                  if (widget.leveledUp) ...[
                                    const SizedBox(height: 20),
                                    AnimatedBuilder(
                                      animation: _levelUpController,
                                      builder: (context, child) {
                                        return Transform.scale(
                                          scale: _levelUpController.value,
                                          child: Opacity(
                                            opacity: _levelUpController.value,
                                            child: _buildLevelUpSection(),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                  
                                  const SizedBox(height: 24),
                                  
                                  // Quest notes (if any)
                                  if (widget.questNotes != null && widget.questNotes!.isNotEmpty)
                                    _buildQuestNotes(),
                                  
                                  const SizedBox(height: 24),
                                  
                                  // Action buttons
                                  _buildActionButtons(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionHeader() {
    return Column(
      children: [
        // Quest completed badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                SoloLevelingColors.hunterGreen,
                SoloLevelingColors.hunterGreenLight,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: SoloLevelingColors.hunterGreen.withValues(alpha: 0.5),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                color: SoloLevelingColors.pureLight,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'QUEST COMPLETED',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: SoloLevelingColors.pureLight,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Quest icon and name
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SoloLevelingIcon.quest(
              activityType: widget.questType.name,
              size: 40,
              hasGlow: true,
              isPulsing: true,
              glowIntensity: 0.8,
            ),
            const SizedBox(width: 16),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quest: ${widget.questType.displayName}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: SoloLevelingColors.ghostWhite,
                    ),
                  ),
                  Text(
                    _getQuestCompletionMessage(),
                    style: TextStyle(
                      fontSize: 14,
                      color: SoloLevelingColors.silverMist,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuestDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SoloLevelingColors.shadowDepth.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: SoloLevelingColors.silverMist.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildQuestStat(
            icon: Icons.schedule,
            label: 'Duration',
            value: '${widget.duration}min',
            color: SoloLevelingColors.electricBlue,
          ),
          _buildQuestStat(
            icon: Icons.trending_up,
            label: 'Difficulty',
            value: _getQuestDifficulty(),
            color: _getQuestDifficultyColor(),
          ),
          _buildQuestStat(
            icon: Icons.military_tech,
            label: 'Category',
            value: widget.questType.category.name.toUpperCase(),
            color: SoloLevelingColors.mysticPurple,
          ),
        ],
      ),
    );
  }

  Widget _buildQuestStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: SoloLevelingColors.silverMist,
          ),
        ),
      ],
    );
  }

  Widget _buildRewardsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SoloLevelingColors.hunterGreen.withValues(alpha: 0.15),
            SoloLevelingColors.electricBlue.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: SoloLevelingColors.hunterGreen.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Rewards header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.card_giftcard,
                color: SoloLevelingColors.goldRank,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Quest Rewards',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: SoloLevelingColors.ghostWhite,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // EXP reward
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SoloLevelingColors.electricBlue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: SoloLevelingColors.electricBlue.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.flash_on,
                  color: SoloLevelingColors.electricBlue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '+${widget.expGained.toInt()} EXP',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: SoloLevelingColors.electricBlue,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Stat rewards
          if (widget.statGains.isNotEmpty) ...[
            Text(
              'Stat Gains:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: SoloLevelingColors.silverMist,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.statGains.entries.map((entry) {
                final statType = entry.key;
                final gain = entry.value;
                
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statType.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: statType.color.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SoloLevelingIcon.stat(
                        statName: statType.name,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '+${gain.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: statType.color,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLevelUpSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            SoloLevelingColors.goldRank.withValues(alpha: 0.3),
            SoloLevelingColors.goldRank.withValues(alpha: 0.1),
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: SoloLevelingColors.goldRank,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: SoloLevelingColors.goldRank.withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_awesome,
                color: SoloLevelingColors.goldRank,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'LEVEL UP!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: SoloLevelingColors.goldRank,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (widget.newLevel != null)
            Text(
              'Level ${widget.newLevel}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: SoloLevelingColors.ghostWhite,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuestNotes() {
    return Container(
      padding: const EdgeInsets.all(12),
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
                size: 16,
                color: SoloLevelingColors.silverMist,
              ),
              const SizedBox(width: 6),
              Text(
                'Quest Notes:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: SoloLevelingColors.silverMist,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.questNotes!,
            style: TextStyle(
              fontSize: 14,
              color: SoloLevelingColors.ghostWhite.withValues(alpha: 0.8),
              fontStyle: FontStyle.italic,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onClose?.call();
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: SoloLevelingColors.silverMist),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Continue',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: SoloLevelingColors.silverMist,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getQuestCompletionMessage() {
    final duration = widget.duration;
    if (duration >= 120) {
      return 'Exceptional dedication and endurance!';
    } else if (duration >= 60) {
      return 'Strong commitment to growth!';
    } else if (duration >= 30) {
      return 'Steady progress on your journey!';
    } else {
      return 'Every step counts towards mastery!';
    }
  }

  String _getQuestDifficulty() {
    final duration = widget.duration;
    if (duration <= 15) return 'Easy';
    if (duration <= 45) return 'Normal';
    if (duration <= 90) return 'Hard';
    return 'Elite';
  }

  Color _getQuestDifficultyColor() {
    final duration = widget.duration;
    if (duration <= 15) return HunterRankColors.cRank;
    if (duration <= 45) return HunterRankColors.bRank;
    if (duration <= 90) return HunterRankColors.aRank;
    return HunterRankColors.sRank;
  }
}

/// Custom painter for animated particles in the background
class _QuestParticlePainter extends CustomPainter {
  final Animation<double> animation;
  final double glowIntensity;

  _QuestParticlePainter({
    required this.animation,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = SoloLevelingColors.electricBlue.withValues(alpha: 0.3 * glowIntensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    // Draw floating particles
    for (int i = 0; i < 20; i++) {
      final progress = (animation.value + i * 0.1) % 1.0;
      final x = (size.width * 0.1) + (size.width * 0.8 * ((i * 0.3) % 1.0));
      final y = size.height * (1 - progress);
      
      final radius = 2 + (glowIntensity * 3);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Helper function to show the quest completion dialog
Future<void> showQuestCompletionDialog({
  required BuildContext context,
  required ActivityType questType,
  required int duration,
  required double expGained,
  required Map<StatType, double> statGains,
  String? questNotes,
  bool leveledUp = false,
  int? newLevel,
  VoidCallback? onClose,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => QuestCompletionDialog(
      questType: questType,
      duration: duration,
      expGained: expGained,
      statGains: statGains,
      questNotes: questNotes,
      leveledUp: leveledUp,
      newLevel: newLevel,
      onClose: onClose,
    ),
  );
}