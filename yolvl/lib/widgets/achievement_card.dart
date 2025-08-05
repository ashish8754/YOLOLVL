import 'package:flutter/material.dart';
import '../models/achievement.dart';
import 'solo_leveling_icon.dart';
import '../theme/solo_leveling_icons.dart';

/// Widget displaying an unlocked achievement
class AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final VoidCallback? onTap;
  final bool showAnimation;

  const AchievementCard({
    super.key,
    required this.achievement,
    this.onTap,
    this.showAnimation = false,
  });

  @override
  Widget build(BuildContext context) {
    final achievementType = achievement.achievementTypeEnum;
    
    return Card(
      elevation: showAnimation ? 8 : 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: showAnimation ? LinearGradient(
              colors: [
                achievementType.color.withOpacity(0.1),
                achievementType.color.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ) : null,
          ),
          child: Row(
            children: [
              // Achievement icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: achievementType.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: achievementType.color.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: SoloLevelingIconFactory.forAchievement(
                  achievementType,
                  size: 28,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Achievement details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            achievementType.displayName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildRarityStars(context, achievementType.rarity),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      achievementType.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Unlocked ${achievement.formattedUnlockTime}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        
                        if (achievement.value != null) ...[
                          const SizedBox(width: 16),
                          Icon(
                            Icons.trending_up,
                            size: 14,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${achievement.value}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // Unlock indicator
              if (showAnimation)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: achievementType.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'NEW!',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRarityStars(BuildContext context, int rarity) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rarity ? Icons.star : Icons.star_border,
          size: 16,
          color: index < rarity 
              ? Colors.amber 
              : Theme.of(context).colorScheme.outline.withOpacity(0.3),
        );
      }),
    );
  }
}

/// Widget for displaying achievement unlock animation
class AchievementUnlockAnimation extends StatefulWidget {
  final Achievement achievement;
  final VoidCallback? onAnimationComplete;

  const AchievementUnlockAnimation({
    super.key,
    required this.achievement,
    this.onAnimationComplete,
  });

  @override
  State<AchievementUnlockAnimation> createState() => _AchievementUnlockAnimationState();
}

class _AchievementUnlockAnimationState extends State<AchievementUnlockAnimation>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
    
    _startAnimation();
  }

  void _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    
    _scaleController.forward();
    _slideController.forward();
    
    await Future.delayed(const Duration(milliseconds: 2000));
    
    if (widget.onAnimationComplete != null) {
      widget.onAnimationComplete!();
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleController, _fadeController, _slideController]),
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                margin: const EdgeInsets.all(16),
                child: AchievementCard(
                  achievement: widget.achievement,
                  showAnimation: true,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}