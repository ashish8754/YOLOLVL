import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../theme/solo_leveling_theme.dart';
import '../theme/glassmorphism_effects.dart';
import '../theme/solo_leveling_icons.dart';

/// Enum for different types of system notifications
enum SystemNotificationType {
  info,
  success,
  warning,
  error,
  levelUp,
  achievement,
  statGain,
  questComplete,
}

/// Data class for system notification content
class SystemNotificationData {
  final String title;
  final String message;
  final SystemNotificationType type;
  final IconData? customIcon;
  final Widget? customContent;
  final Duration displayDuration;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;
  final Map<String, dynamic>? metadata;

  const SystemNotificationData({
    required this.title,
    required this.message,
    required this.type,
    this.customIcon,
    this.customContent,
    this.displayDuration = const Duration(seconds: 4),
    this.onTap,
    this.onDismiss,
    this.metadata,
  });

  /// Create a level up notification
  static SystemNotificationData levelUp({
    required int newLevel,
    int? expGained,
    VoidCallback? onTap,
    VoidCallback? onDismiss,
  }) {
    return SystemNotificationData(
      title: 'LEVEL UP!',
      message: expGained != null 
          ? 'Level $newLevel Achieved!\n+$expGained EXP Earned'
          : 'Level $newLevel Achieved!',
      type: SystemNotificationType.levelUp,
      customIcon: SoloLevelingIcons.levelUp,
      displayDuration: const Duration(seconds: 6),
      onTap: onTap,
      onDismiss: onDismiss,
      metadata: {'level': newLevel, 'exp': expGained},
    );
  }

  /// Create a stat gain notification
  static SystemNotificationData statGain({
    required String statName,
    required double gainAmount,
    required double newValue,
    VoidCallback? onTap,
    VoidCallback? onDismiss,
  }) {
    return SystemNotificationData(
      title: 'STAT INCREASED',
      message: '$statName: +${gainAmount.toStringAsFixed(2)}\nNew Value: ${newValue.toStringAsFixed(2)}',
      type: SystemNotificationType.statGain,
      customIcon: SoloLevelingIcons.getStatIcon(statName),
      displayDuration: const Duration(seconds: 3),
      onTap: onTap,
      onDismiss: onDismiss,
      metadata: {'stat': statName, 'gain': gainAmount, 'newValue': newValue},
    );
  }

  /// Create an achievement unlock notification
  static SystemNotificationData achievement({
    required String achievementName,
    required String description,
    VoidCallback? onTap,
    VoidCallback? onDismiss,
  }) {
    return SystemNotificationData(
      title: 'ACHIEVEMENT UNLOCKED',
      message: '$achievementName\n$description',
      type: SystemNotificationType.achievement,
      customIcon: SoloLevelingIcons.achievementIcons['special'],
      displayDuration: const Duration(seconds: 5),
      onTap: onTap,
      onDismiss: onDismiss,
      metadata: {'achievement': achievementName, 'description': description},
    );
  }

  /// Create a quest completion notification
  static SystemNotificationData questComplete({
    required String questName,
    required int expGained,
    List<String>? statsAffected,
    VoidCallback? onTap,
    VoidCallback? onDismiss,
  }) {
    String message = '$questName Complete!\n+$expGained EXP';
    if (statsAffected != null && statsAffected.isNotEmpty) {
      message += '\nStats: ${statsAffected.join(", ")}';
    }

    return SystemNotificationData(
      title: 'QUEST COMPLETE',
      message: message,
      type: SystemNotificationType.questComplete,
      customIcon: SoloLevelingIcons.completeQuest,
      displayDuration: const Duration(seconds: 4),
      onTap: onTap,
      onDismiss: onDismiss,
      metadata: {
        'quest': questName,
        'exp': expGained,
        'stats': statsAffected,
      },
    );
  }

  /// Create a system error notification
  static SystemNotificationData error({
    required String message,
    String title = 'SYSTEM ERROR',
    VoidCallback? onTap,
    VoidCallback? onDismiss,
  }) {
    return SystemNotificationData(
      title: title,
      message: message,
      type: SystemNotificationType.error,
      displayDuration: const Duration(seconds: 5),
      onTap: onTap,
      onDismiss: onDismiss,
    );
  }

  /// Create a system warning notification
  static SystemNotificationData warning({
    required String message,
    String title = 'WARNING',
    VoidCallback? onTap,
    VoidCallback? onDismiss,
  }) {
    return SystemNotificationData(
      title: title,
      message: message,
      type: SystemNotificationType.warning,
      displayDuration: const Duration(seconds: 4),
      onTap: onTap,
      onDismiss: onDismiss,
    );
  }

  /// Create a system info notification
  static SystemNotificationData info({
    required String message,
    String title = 'SYSTEM',
    VoidCallback? onTap,
    VoidCallback? onDismiss,
  }) {
    return SystemNotificationData(
      title: title,
      message: message,
      type: SystemNotificationType.info,
      displayDuration: const Duration(seconds: 3),
      onTap: onTap,
      onDismiss: onDismiss,
    );
  }
}

/// Solo Leveling style system notification widget
class SystemNotification extends StatefulWidget {
  final SystemNotificationData data;
  final VoidCallback? onDismissed;
  final bool autoHide;

  const SystemNotification({
    super.key,
    required this.data,
    this.onDismissed,
    this.autoHide = true,
  });

  @override
  State<SystemNotification> createState() => _SystemNotificationState();
}

class _SystemNotificationState extends State<SystemNotification>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _glowController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    // Slide animation controller
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    // Glow animation controller
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Slide in from top
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
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
    _slideController.forward();
    _glowController.repeat(reverse: true);

    // Auto-hide after duration
    if (widget.autoHide) {
      Future.delayed(widget.data.displayDuration, () {
        if (mounted) {
          _dismiss();
        }
      });
    }

    // Haptic feedback for important notifications
    if (_isImportantNotification()) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  bool _isImportantNotification() {
    return widget.data.type == SystemNotificationType.levelUp ||
           widget.data.type == SystemNotificationType.achievement ||
           widget.data.type == SystemNotificationType.error;
  }

  void _dismiss() {
    _slideController.reverse().then((_) {
      widget.data.onDismiss?.call();
      widget.onDismissed?.call();
    });
  }

  Color _getTypeColor() {
    switch (widget.data.type) {
      case SystemNotificationType.info:
        return SystemColors.systemInfo;
      case SystemNotificationType.success:
      case SystemNotificationType.questComplete:
        return SystemColors.systemSuccess;
      case SystemNotificationType.warning:
        return SystemColors.systemWarning;
      case SystemNotificationType.error:
        return SystemColors.systemError;
      case SystemNotificationType.levelUp:
        return SystemColors.levelUpGlow;
      case SystemNotificationType.achievement:
        return SoloLevelingColors.mysticPurple;
      case SystemNotificationType.statGain:
        return SoloLevelingColors.hunterGreen;
    }
  }

  IconData _getTypeIcon() {
    if (widget.data.customIcon != null) {
      return widget.data.customIcon!;
    }

    switch (widget.data.type) {
      case SystemNotificationType.info:
        return SoloLevelingIcons.systemInfo;
      case SystemNotificationType.success:
      case SystemNotificationType.questComplete:
        return SoloLevelingIcons.systemSuccess;
      case SystemNotificationType.warning:
        return SoloLevelingIcons.systemWarning;
      case SystemNotificationType.error:
        return SoloLevelingIcons.systemError;
      case SystemNotificationType.levelUp:
        return SoloLevelingIcons.levelUp;
      case SystemNotificationType.achievement:
        return SoloLevelingIcons.achievementIcons['special']!;
      case SystemNotificationType.statGain:
        return SoloLevelingIcons.progression;
    }
  }

  Widget _buildNotificationContent() {
    if (widget.data.customContent != null) {
      return widget.data.customContent!;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    boxShadow: _isImportantNotification() ? [
                      BoxShadow(
                        color: _getTypeColor().withValues(alpha: _glowAnimation.value * 0.5),
                        blurRadius: 10 + (_glowAnimation.value * 5),
                        spreadRadius: 2 + (_glowAnimation.value * 2),
                      ),
                    ] : null,
                  ),
                  child: Icon(
                    _getTypeIcon(),
                    color: _getTypeColor(),
                    size: 24,
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.data.title,
                    style: SoloLevelingTypography.systemNotification.copyWith(
                      color: _getTypeColor(),
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.data.message,
                    style: SoloLevelingTypography.systemNotification.copyWith(
                      color: SoloLevelingColors.ghostWhite,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _dismiss,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: SoloLevelingColors.shadowGray.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  SoloLevelingIcons.systemClose,
                  color: SoloLevelingColors.silverMist,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: GestureDetector(
          onTap: widget.data.onTap,
          child: GlassmorphismEffects.systemPanel(
            isActive: _isImportantNotification(),
            context: context,
            child: AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getTypeColor().withValues(
                        alpha: 0.3 + (_glowAnimation.value * 0.4)
                      ),
                      width: 1.5,
                    ),
                    boxShadow: _isImportantNotification() ? [
                      BoxShadow(
                        color: _getTypeColor().withValues(
                          alpha: _glowAnimation.value * 0.2
                        ),
                        blurRadius: 15 + (_glowAnimation.value * 10),
                        spreadRadius: 0,
                        offset: const Offset(0, 0),
                      ),
                    ] : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              SoloLevelingColors.shadowDepth.withValues(alpha: 0.95),
                              _getTypeColor().withValues(alpha: 0.05),
                              SoloLevelingColors.voidBlack.withValues(alpha: 0.8),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                        child: _buildNotificationContent(),
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

/// Widget for displaying system notifications with custom positioning
class SystemNotificationDisplay extends StatelessWidget {
  final List<SystemNotificationData> notifications;
  final Function(int index)? onNotificationDismissed;
  final EdgeInsets padding;
  final MainAxisAlignment alignment;

  const SystemNotificationDisplay({
    super.key,
    required this.notifications,
    this.onNotificationDismissed,
    this.padding = const EdgeInsets.only(top: 60),
    this.alignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: notifications.isEmpty,
        child: Container(
          padding: padding,
          child: Column(
            mainAxisAlignment: alignment,
            children: notifications.asMap().entries.map((entry) {
              final index = entry.key;
              final data = entry.value;
              
              return SystemNotification(
                data: data,
                onDismissed: () => onNotificationDismissed?.call(index),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}