import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../theme/solo_leveling_theme.dart';
import '../theme/glassmorphism_effects.dart';
import '../theme/solo_leveling_icons.dart';

/// Enum for different types of system alerts
enum SystemAlertType {
  confirmation,
  information,
  warning,
  error,
  levelUp,
  achievement,
  questReward,
}

/// Data class for system alert content
class SystemAlertData {
  final String title;
  final String message;
  final SystemAlertType type;
  final IconData? customIcon;
  final Widget? customContent;
  final List<SystemAlertAction> actions;
  final bool dismissible;
  final bool showCloseButton;
  final VoidCallback? onDismiss;

  const SystemAlertData({
    required this.title,
    required this.message,
    required this.type,
    this.customIcon,
    this.customContent,
    this.actions = const [],
    this.dismissible = true,
    this.showCloseButton = true,
    this.onDismiss,
  });

  /// Create a confirmation dialog
  static SystemAlertData confirmation({
    required String title,
    required String message,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    String confirmText = 'CONFIRM',
    String cancelText = 'CANCEL',
    bool destructive = false,
  }) {
    return SystemAlertData(
      title: title,
      message: message,
      type: SystemAlertType.confirmation,
      actions: [
        SystemAlertAction(
          text: cancelText,
          isPrimary: false,
          onPressed: onCancel,
        ),
        SystemAlertAction(
          text: confirmText,
          isPrimary: true,
          isDestructive: destructive,
          onPressed: onConfirm,
        ),
      ],
    );
  }

  /// Create a level up celebration dialog
  static SystemAlertData levelUpCelebration({
    required int newLevel,
    required int expGained,
    Map<String, double>? statGains,
    List<String>? newAbilities,
    VoidCallback? onContinue,
  }) {
    String message = 'Congratulations Hunter!\n\nLevel: $newLevel\nEXP Gained: +$expGained';
    
    if (statGains != null && statGains.isNotEmpty) {
      message += '\n\nStat Gains:';
      for (final entry in statGains.entries) {
        message += '\n${entry.key}: +${entry.value.toStringAsFixed(2)}';
      }
    }

    if (newAbilities != null && newAbilities.isNotEmpty) {
      message += '\n\nNew Abilities Unlocked:';
      for (final ability in newAbilities) {
        message += '\n• $ability';
      }
    }

    return SystemAlertData(
      title: 'LEVEL UP ACHIEVED',
      message: message,
      type: SystemAlertType.levelUp,
      customIcon: SoloLevelingIcons.levelUp,
      actions: [
        SystemAlertAction(
          text: 'CONTINUE',
          isPrimary: true,
          onPressed: onContinue,
        ),
      ],
      dismissible: false,
      showCloseButton: false,
    );
  }

  /// Create an achievement unlock dialog
  static SystemAlertData achievementUnlock({
    required String achievementName,
    required String description,
    required String rewardDescription,
    VoidCallback? onClaim,
  }) {
    return SystemAlertData(
      title: 'ACHIEVEMENT UNLOCKED',
      message: '$achievementName\n\n$description\n\nReward: $rewardDescription',
      type: SystemAlertType.achievement,
      customIcon: SoloLevelingIcons.achievementIcons['special'],
      actions: [
        SystemAlertAction(
          text: 'CLAIM REWARD',
          isPrimary: true,
          onPressed: onClaim,
        ),
      ],
    );
  }

  /// Create a quest reward dialog
  static SystemAlertData questReward({
    required String questName,
    required int expReward,
    Map<String, double>? statRewards,
    List<String>? itemRewards,
    VoidCallback? onClaim,
  }) {
    String message = 'Quest "$questName" Complete!\n\nRewards:\n• EXP: +$expReward';
    
    if (statRewards != null && statRewards.isNotEmpty) {
      for (final entry in statRewards.entries) {
        message += '\n• ${entry.key}: +${entry.value.toStringAsFixed(2)}';
      }
    }

    if (itemRewards != null && itemRewards.isNotEmpty) {
      for (final item in itemRewards) {
        message += '\n• $item';
      }
    }

    return SystemAlertData(
      title: 'QUEST REWARDS',
      message: message,
      type: SystemAlertType.questReward,
      customIcon: SoloLevelingIcons.completeQuest,
      actions: [
        SystemAlertAction(
          text: 'CLAIM ALL',
          isPrimary: true,
          onPressed: onClaim,
        ),
      ],
    );
  }

  /// Create an error dialog
  static SystemAlertData error({
    required String title,
    required String message,
    VoidCallback? onOk,
  }) {
    return SystemAlertData(
      title: title,
      message: message,
      type: SystemAlertType.error,
      actions: [
        SystemAlertAction(
          text: 'OK',
          isPrimary: true,
          onPressed: onOk,
        ),
      ],
    );
  }

  /// Create a warning dialog
  static SystemAlertData warning({
    required String title,
    required String message,
    VoidCallback? onOk,
    VoidCallback? onCancel,
    String okText = 'OK',
    String cancelText = 'CANCEL',
  }) {
    final actions = <SystemAlertAction>[
      if (onCancel != null)
        SystemAlertAction(
          text: cancelText,
          isPrimary: false,
          onPressed: onCancel,
        ),
      SystemAlertAction(
        text: okText,
        isPrimary: true,
        onPressed: onOk,
      ),
    ];

    return SystemAlertData(
      title: title,
      message: message,
      type: SystemAlertType.warning,
      actions: actions,
    );
  }

  /// Create an information dialog
  static SystemAlertData info({
    required String title,
    required String message,
    VoidCallback? onOk,
  }) {
    return SystemAlertData(
      title: title,
      message: message,
      type: SystemAlertType.information,
      actions: [
        SystemAlertAction(
          text: 'OK',
          isPrimary: true,
          onPressed: onOk,
        ),
      ],
    );
  }
}

/// Action button data for system alerts
class SystemAlertAction {
  final String text;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isDestructive;
  final IconData? icon;

  const SystemAlertAction({
    required this.text,
    this.onPressed,
    this.isPrimary = false,
    this.isDestructive = false,
    this.icon,
  });
}

/// Solo Leveling style system alert dialog
class SystemAlertDialog extends StatefulWidget {
  final SystemAlertData data;

  const SystemAlertDialog({
    super.key,
    required this.data,
  });

  /// Show a system alert dialog
  static Future<T?> show<T>({
    required BuildContext context,
    required SystemAlertData data,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: data.dismissible && barrierDismissible,
      barrierColor: SoloLevelingColors.voidBlack.withValues(alpha: 0.8),
      builder: (context) => SystemAlertDialog(data: data),
    );
  }

  @override
  State<SystemAlertDialog> createState() => _SystemAlertDialogState();
}

class _SystemAlertDialogState extends State<SystemAlertDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    // Scale animation controller
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Glow animation controller
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Scale animation with bounce
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    // Glow effect animation
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _scaleController.forward();
    
    // Only animate glow for special dialogs
    if (_isSpecialDialog()) {
      _glowController.repeat(reverse: true);
    }

    // Haptic feedback
    if (_isSpecialDialog()) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  bool _isSpecialDialog() {
    return widget.data.type == SystemAlertType.levelUp ||
           widget.data.type == SystemAlertType.achievement ||
           widget.data.type == SystemAlertType.questReward;
  }

  Color _getTypeColor() {
    switch (widget.data.type) {
      case SystemAlertType.confirmation:
      case SystemAlertType.information:
        return SystemColors.systemInfo;
      case SystemAlertType.warning:
        return SystemColors.systemWarning;
      case SystemAlertType.error:
        return SystemColors.systemError;
      case SystemAlertType.levelUp:
        return SystemColors.levelUpGlow;
      case SystemAlertType.achievement:
        return SoloLevelingColors.mysticPurple;
      case SystemAlertType.questReward:
        return SystemColors.systemSuccess;
    }
  }

  IconData _getTypeIcon() {
    if (widget.data.customIcon != null) {
      return widget.data.customIcon!;
    }

    switch (widget.data.type) {
      case SystemAlertType.confirmation:
      case SystemAlertType.information:
        return SoloLevelingIcons.systemInfo;
      case SystemAlertType.warning:
        return SoloLevelingIcons.systemWarning;
      case SystemAlertType.error:
        return SoloLevelingIcons.systemError;
      case SystemAlertType.levelUp:
        return SoloLevelingIcons.levelUp;
      case SystemAlertType.achievement:
        return SoloLevelingIcons.achievementIcons['special']!;
      case SystemAlertType.questReward:
        return SoloLevelingIcons.completeQuest;
    }
  }

  void _dismiss() {
    widget.data.onDismiss?.call();
    Navigator.of(context).pop();
  }

  Widget _buildDialogContent() {
    if (widget.data.customContent != null) {
      return widget.data.customContent!;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header with icon and title
        Row(
          children: [
            AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    boxShadow: _isSpecialDialog() ? [
                      BoxShadow(
                        color: _getTypeColor().withValues(alpha: _glowAnimation.value * 0.6),
                        blurRadius: 15 + (_glowAnimation.value * 10),
                        spreadRadius: 3 + (_glowAnimation.value * 2),
                      ),
                    ] : null,
                  ),
                  child: Icon(
                    _getTypeIcon(),
                    color: _getTypeColor(),
                    size: 32,
                  ),
                );
              },
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                widget.data.title,
                style: SoloLevelingTypography.hunterTitle.copyWith(
                  color: _getTypeColor(),
                  fontSize: 20,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            if (widget.data.showCloseButton && widget.data.dismissible)
              GestureDetector(
                onTap: _dismiss,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: SoloLevelingColors.shadowGray.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    SoloLevelingIcons.systemClose,
                    color: SoloLevelingColors.silverMist,
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Message content
        Container(
          width: double.infinity,
          child: Text(
            widget.data.message,
            style: SoloLevelingTypography.systemNotification.copyWith(
              color: SoloLevelingColors.ghostWhite,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
        
        if (widget.data.actions.isNotEmpty) ...[
          const SizedBox(height: 32),
          
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: widget.data.actions.asMap().entries.map((entry) {
              final index = entry.key;
              final action = entry.value;
              
              return Padding(
                padding: EdgeInsets.only(left: index > 0 ? 12 : 0),
                child: _buildActionButton(action),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton(SystemAlertAction action) {
    Color buttonColor;
    Color textColor = SoloLevelingColors.pureLight;
    
    if (action.isDestructive) {
      buttonColor = SystemColors.systemError;
    } else if (action.isPrimary) {
      buttonColor = _getTypeColor();
    } else {
      buttonColor = SoloLevelingColors.shadowGray;
    }

    return ElevatedButton(
      onPressed: () {
        action.onPressed?.call();
        Navigator.of(context).pop();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: textColor,
        elevation: 8,
        shadowColor: buttonColor.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (action.icon != null) ...[
            Icon(action.icon, size: 18),
            const SizedBox(width: 8),
          ],
          Text(
            action.text,
            style: SoloLevelingTypography.systemNotification.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => widget.data.dismissible,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 400,
              minWidth: 300,
            ),
            child: AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _getTypeColor().withValues(
                        alpha: 0.4 + (_glowAnimation.value * 0.4)
                      ),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: SoloLevelingColors.voidBlack.withValues(alpha: 0.8),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                      if (_isSpecialDialog())
                        BoxShadow(
                          color: _getTypeColor().withValues(
                            alpha: _glowAnimation.value * 0.3
                          ),
                          blurRadius: 30 + (_glowAnimation.value * 20),
                          spreadRadius: 0,
                          offset: const Offset(0, 0),
                        ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              SoloLevelingColors.shadowDepth.withValues(alpha: 0.95),
                              _getTypeColor().withValues(alpha: 0.05),
                              SoloLevelingColors.voidBlack.withValues(alpha: 0.9),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                        padding: const EdgeInsets.all(24),
                        child: _buildDialogContent(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Convenience methods for showing common system alerts
class SystemAlerts {
  SystemAlerts._();

  /// Show a confirmation dialog
  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'CONFIRM',
    String cancelText = 'CANCEL',
    bool destructive = false,
  }) {
    return SystemAlertDialog.show<bool>(
      context: context,
      data: SystemAlertData.confirmation(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        destructive: destructive,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
  }

  /// Show a level up celebration
  static Future<void> showLevelUp({
    required BuildContext context,
    required int newLevel,
    required int expGained,
    Map<String, double>? statGains,
    List<String>? newAbilities,
  }) {
    return SystemAlertDialog.show<void>(
      context: context,
      data: SystemAlertData.levelUpCelebration(
        newLevel: newLevel,
        expGained: expGained,
        statGains: statGains,
        newAbilities: newAbilities,
        onContinue: () => Navigator.of(context).pop(),
      ),
      barrierDismissible: false,
    );
  }

  /// Show an achievement unlock
  static Future<void> showAchievement({
    required BuildContext context,
    required String achievementName,
    required String description,
    required String rewardDescription,
  }) {
    return SystemAlertDialog.show<void>(
      context: context,
      data: SystemAlertData.achievementUnlock(
        achievementName: achievementName,
        description: description,
        rewardDescription: rewardDescription,
        onClaim: () => Navigator.of(context).pop(),
      ),
    );
  }

  /// Show an error alert
  static Future<void> showError({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    return SystemAlertDialog.show<void>(
      context: context,
      data: SystemAlertData.error(
        title: title,
        message: message,
        onOk: () => Navigator.of(context).pop(),
      ),
    );
  }

  /// Show a warning alert
  static Future<bool?> showWarning({
    required BuildContext context,
    required String title,
    required String message,
    String okText = 'OK',
    String cancelText = 'CANCEL',
    bool showCancel = true,
  }) {
    return SystemAlertDialog.show<bool>(
      context: context,
      data: SystemAlertData.warning(
        title: title,
        message: message,
        okText: okText,
        cancelText: cancelText,
        onOk: () => Navigator.of(context).pop(true),
        onCancel: showCancel ? () => Navigator.of(context).pop(false) : null,
      ),
    );
  }

  /// Show an info alert
  static Future<void> showInfo({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    return SystemAlertDialog.show<void>(
      context: context,
      data: SystemAlertData.info(
        title: title,
        message: message,
        onOk: () => Navigator.of(context).pop(),
      ),
    );
  }
}