import 'package:flutter/material.dart';
import 'level_up_celebration.dart';

/// Overlay widget that shows level up celebration on top of other content
class LevelUpOverlay extends StatelessWidget {
  final Widget child;
  final bool showCelebration;
  final int? newLevel;
  final VoidCallback? onAnimationComplete;

  const LevelUpOverlay({
    super.key,
    required this.child,
    required this.showCelebration,
    this.newLevel,
    this.onAnimationComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main content
        child,
        
        // Level up celebration overlay
        if (showCelebration && newLevel != null)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: LevelUpCelebration(
                newLevel: newLevel!,
                onAnimationComplete: onAnimationComplete,
              ),
            ),
          ),
      ],
    );
  }
}