import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../utils/accessibility_helper.dart' as accessibility;
import 'hunter_rank_display.dart';

/// Widget displaying user level and EXP progress with smooth animations
/// 
/// **DEPRECATED**: This widget has been superseded by HunterRankDisplay.
/// It now serves as a backward compatibility layer that forwards to the new Hunter Rank system.
/// For new implementations, use HunterRankDisplay directly.
class LevelExpDisplay extends StatefulWidget {
  final bool useHunterRankSystem;
  
  const LevelExpDisplay({
    super.key,
    this.useHunterRankSystem = true, // Default to new system
  });

  @override
  State<LevelExpDisplay> createState() => _LevelExpDisplayState();
}

class _LevelExpDisplayState extends State<LevelExpDisplay>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  double _previousProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOutCubic,
    ));
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  void _updateProgress(double newProgress) {
    if (newProgress != _previousProgress) {
      _progressController.reset();
      _progressAnimation = Tween<double>(
        begin: _previousProgress,
        end: newProgress,
      ).animate(CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOutCubic,
      ));
      _progressController.forward();
      _previousProgress = newProgress;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Forward to new Hunter Rank system if enabled (default behavior)
    if (widget.useHunterRankSystem) {
      return const HunterRankDisplay();
    }
    
    // Legacy implementation for backward compatibility
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final level = userProvider.level;
        final currentEXP = userProvider.currentEXP;
        final expThreshold = userProvider.expThreshold;
        final expProgress = userProvider.expProgress.clamp(0.0, 1.0);
        final userName = userProvider.userName;

        // Update animation when progress changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateProgress(expProgress);
        });

        return Semantics(
          label: AccessibilityHelper.getLevelSemanticLabel(level, currentEXP, expThreshold),
          child: accessibility.ResponsiveLayout(
            mobile: _buildMobileLayout(context, level, currentEXP, expThreshold, expProgress, userName, userProvider),
            tablet: _buildTabletLayout(context, level, currentEXP, expThreshold, expProgress, userName, userProvider),
          ),
        );
      },
    );
  }

  Widget _buildMobileLayout(BuildContext context, int level, double currentEXP, double expThreshold, double expProgress, String userName, UserProvider userProvider) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveBreakpoints.getResponsivePadding(context)),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserInfo(context, userName, level),
          const SizedBox(height: 16),
          _buildExpProgress(context, currentEXP, expThreshold, expProgress, userProvider),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context, int level, double currentEXP, double expThreshold, double expProgress, String userName, UserProvider userProvider) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveBreakpoints.getResponsivePadding(context)),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildUserInfo(context, userName, level),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 3,
            child: _buildExpProgress(context, currentEXP, expThreshold, expProgress, userProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context, String userName, int level) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            userName,
            style: AccessibilityHelper.getAccessibleTextStyle(
              context,
              TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
        Semantics(
          label: 'Current level: $level',
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AccessibilityHelper.minTouchTargetSize,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                'Level $level',
                style: AccessibilityHelper.getAccessibleTextStyle(
                  context,
                  TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpProgress(BuildContext context, double currentEXP, double expThreshold, double expProgress, UserProvider userProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Experience',
              style: AccessibilityHelper.getAccessibleTextStyle(
                context,
                TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ),
            Semantics(
              label: 'Experience points: ${currentEXP.toStringAsFixed(0)} out of ${expThreshold.toStringAsFixed(0)}',
              child: Text(
                '${currentEXP.toStringAsFixed(0)} / ${expThreshold.toStringAsFixed(0)}',
                style: AccessibilityHelper.getAccessibleTextStyle(
                  context,
                  TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Accessible Animated Progress bar
        Semantics(
          label: AccessibilityHelper.getProgressSemanticLabel('Experience progress', expProgress, currentEXP, expThreshold),
          child: Container(
            height: 12,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return LinearProgressIndicator(
                    value: _progressAnimation.value,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.secondary,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Progress percentage with accessibility
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Semantics(
              label: '${(expProgress * 100).toStringAsFixed(1)} percent to next level',
              child: Text(
                '${(expProgress * 100).toStringAsFixed(1)}% to next level',
                style: AccessibilityHelper.getAccessibleTextStyle(
                  context,
                  TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
            if (userProvider.canLevelUp)
              Semantics(
                label: 'Ready to level up!',
                button: true,
                child: Container(
                  constraints: const BoxConstraints(
                    minHeight: AccessibilityHelper.minTouchTargetSize,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      'LEVEL UP!',
                      style: AccessibilityHelper.getAccessibleTextStyle(
                        context,
                        TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}