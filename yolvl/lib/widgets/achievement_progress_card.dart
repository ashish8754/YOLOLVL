import 'package:flutter/material.dart';
import '../models/achievement.dart';

/// Widget displaying achievement progress for locked achievements
class AchievementProgressCard extends StatelessWidget {
  final AchievementProgress progress;
  final VoidCallback? onTap;

  const AchievementProgressCard({
    super.key,
    required this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = progress.isUnlocked;
    final achievementType = progress.type;
    
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Achievement icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isCompleted 
                          ? achievementType.color.withOpacity(0.1)
                          : Theme.of(context).colorScheme.outline.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isCompleted 
                            ? achievementType.color.withOpacity(0.3)
                            : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      achievementType.icon,
                      color: isCompleted 
                          ? achievementType.color
                          : Theme.of(context).colorScheme.outline,
                      size: 24,
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
                                  color: isCompleted 
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                ),
                              ),
                            ),
                            if (isCompleted)
                              Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 20,
                              ),
                          ],
                        ),
                        
                        const SizedBox(height: 4),
                        
                        Text(
                          achievementType.description,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Progress percentage
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCompleted 
                          ? Colors.green.withOpacity(0.1)
                          : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${progress.progressPercentage}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isCompleted 
                            ? Colors.green
                            : Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      Text(
                        '${progress.currentValue} / ${progress.targetValue}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  LinearProgressIndicator(
                    value: progress.progress,
                    backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCompleted 
                          ? Colors.green
                          : achievementType.color,
                    ),
                    minHeight: 6,
                  ),
                ],
              ),
              
              // Rarity stars
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Rarity: ',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  _buildRarityStars(context, achievementType.rarity),
                  const Spacer(),
                  if (progress.canUnlock)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: achievementType.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: achievementType.color.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        'Ready to unlock!',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: achievementType.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
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
          size: 14,
          color: index < rarity 
              ? Colors.amber 
              : Theme.of(context).colorScheme.outline.withOpacity(0.3),
        );
      }),
    );
  }
}