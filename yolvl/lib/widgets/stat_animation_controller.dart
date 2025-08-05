import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/enums.dart';
import 'floating_stat_gain_animation.dart';
import '../theme/solo_leveling_theme.dart';

/// Enhanced stat animation controller for managing multiple stat gain animations
/// Provides queue management and positioning for optimal visual presentation
class StatAnimationController extends ChangeNotifier {
  final List<_QueuedStatAnimation> _animationQueue = [];
  final List<_ActiveStatAnimation> _activeAnimations = [];
  final GlobalKey _containerKey = GlobalKey();
  
  bool _isProcessingQueue = false;
  static const int _maxConcurrentAnimations = 3;
  static const Duration _queueProcessDelay = Duration(milliseconds: 200);

  /// Queue a new stat gain animation
  void queueStatGainAnimation({
    required Map<StatType, double> statGains,
    required double expGained,
    VoidCallback? onComplete,
    bool enableHapticFeedback = true,
    bool enableParticleEffects = true,
    bool enableScreenFlash = true,
    AnimationPriority priority = AnimationPriority.normal,
  }) {
    final animation = _QueuedStatAnimation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      statGains: statGains,
      expGained: expGained,
      onComplete: onComplete,
      enableHapticFeedback: enableHapticFeedback,
      enableParticleEffects: enableParticleEffects,
      enableScreenFlash: enableScreenFlash,
      priority: priority,
      queuedAt: DateTime.now(),
    );

    // Insert based on priority
    if (priority == AnimationPriority.high) {
      _animationQueue.insert(0, animation);
    } else {
      _animationQueue.add(animation);
    }

    _processQueue();
  }

  /// Queue batch stat updates with staggered timing
  void queueBatchStatAnimations({
    required List<Map<StatType, double>> batchStatGains,
    required List<double> batchExpGained,
    VoidCallback? onAllComplete,
    bool enableHapticFeedback = true,
    bool enableParticleEffects = true,
    bool enableScreenFlash = false, // Usually disabled for batch to avoid flicker
    Duration staggerDelay = const Duration(milliseconds: 150),
  }) {
    int completedAnimations = 0;
    final totalAnimations = batchStatGains.length;

    for (int i = 0; i < batchStatGains.length; i++) {
      Future.delayed(staggerDelay * i, () {
        queueStatGainAnimation(
          statGains: batchStatGains[i],
          expGained: i < batchExpGained.length ? batchExpGained[i] : 0.0,
          enableHapticFeedback: enableHapticFeedback && i == 0, // Only first animation
          enableParticleEffects: enableParticleEffects,
          enableScreenFlash: enableScreenFlash && i == 0, // Only first animation
          priority: AnimationPriority.batch,
          onComplete: () {
            completedAnimations++;
            if (completedAnimations >= totalAnimations && onAllComplete != null) {
              onAllComplete();
            }
          },
        );
      });
    }
  }

  /// Process the animation queue
  void _processQueue() async {
    if (_isProcessingQueue || _animationQueue.isEmpty) return;
    if (_activeAnimations.length >= _maxConcurrentAnimations) return;

    _isProcessingQueue = true;

    while (_animationQueue.isNotEmpty && 
           _activeAnimations.length < _maxConcurrentAnimations) {
      final queuedAnimation = _animationQueue.removeAt(0);
      await _startAnimation(queuedAnimation);
      
      // Small delay between starting animations for better visual flow
      await Future.delayed(_queueProcessDelay);
    }

    _isProcessingQueue = false;
  }

  /// Start an individual animation
  Future<void> _startAnimation(_QueuedStatAnimation queuedAnimation) async {
    final position = _calculateOptimalPosition();
    
    final activeAnimation = _ActiveStatAnimation(
      id: queuedAnimation.id,
      statGains: queuedAnimation.statGains,
      expGained: queuedAnimation.expGained,
      position: position,
      onComplete: () {
        _onAnimationComplete(queuedAnimation.id);
        queuedAnimation.onComplete?.call();
      },
      enableHapticFeedback: queuedAnimation.enableHapticFeedback,
      enableParticleEffects: queuedAnimation.enableParticleEffects,
      enableScreenFlash: queuedAnimation.enableScreenFlash,
      startedAt: DateTime.now(),
    );

    _activeAnimations.add(activeAnimation);
    notifyListeners();
  }

  /// Calculate optimal position for new animation to avoid overlap
  Offset _calculateOptimalPosition() {
    if (_activeAnimations.isEmpty) {
      return const Offset(0.5, 0.4); // Center-ish
    }

    // Calculate positions to avoid overlap
    final basePositions = [
      const Offset(0.5, 0.4),  // Center
      const Offset(0.3, 0.3),  // Left-up
      const Offset(0.7, 0.3),  // Right-up
      const Offset(0.2, 0.5),  // Far left
      const Offset(0.8, 0.5),  // Far right
    ];

    // Find the first position that's not too close to existing animations
    for (final basePos in basePositions) {
      bool tooClose = false;
      for (final active in _activeAnimations) {
        final distance = (active.position - basePos).distance;
        if (distance < 0.2) {
          tooClose = true;
          break;
        }
      }
      if (!tooClose) return basePos;
    }

    // If all positions are taken, use a random offset
    final random = DateTime.now().millisecondsSinceEpoch % 100 / 100.0;
    return Offset(0.3 + (random * 0.4), 0.3 + (random * 0.3));
  }

  /// Handle animation completion
  void _onAnimationComplete(String animationId) {
    _activeAnimations.removeWhere((anim) => anim.id == animationId);
    notifyListeners();
    
    // Process more animations if queue has items
    _processQueue();
  }

  /// Clear all animations and queue
  void clearAll() {
    _animationQueue.clear();
    _activeAnimations.clear();
    notifyListeners();
  }

  /// Get current active animations for rendering
  List<_ActiveStatAnimation> get activeAnimations => List.unmodifiable(_activeAnimations);

  /// Get current queue size
  int get queueSize => _animationQueue.length;

  /// Check if any animations are active
  bool get hasActiveAnimations => _activeAnimations.isNotEmpty;

  @override
  void dispose() {
    clearAll();
    super.dispose();
  }
}

/// Priority levels for stat animations
enum AnimationPriority {
  low,
  normal,
  high,
  batch,
}

/// Internal class for queued animations
class _QueuedStatAnimation {
  final String id;
  final Map<StatType, double> statGains;
  final double expGained;
  final VoidCallback? onComplete;
  final bool enableHapticFeedback;
  final bool enableParticleEffects;
  final bool enableScreenFlash;
  final AnimationPriority priority;
  final DateTime queuedAt;

  _QueuedStatAnimation({
    required this.id,
    required this.statGains,
    required this.expGained,
    this.onComplete,
    required this.enableHapticFeedback,
    required this.enableParticleEffects,
    required this.enableScreenFlash,
    required this.priority,
    required this.queuedAt,
  });
}

/// Internal class for active animations
class _ActiveStatAnimation {
  final String id;
  final Map<StatType, double> statGains;
  final double expGained;
  final Offset position;
  final VoidCallback onComplete;
  final bool enableHapticFeedback;
  final bool enableParticleEffects;
  final bool enableScreenFlash;
  final DateTime startedAt;

  _ActiveStatAnimation({
    required this.id,
    required this.statGains,
    required this.expGained,
    required this.position,
    required this.onComplete,
    required this.enableHapticFeedback,
    required this.enableParticleEffects,
    required this.enableScreenFlash,
    required this.startedAt,
  });
}

/// Widget that manages and displays multiple stat animations
class StatAnimationDisplay extends StatefulWidget {
  final StatAnimationController controller;
  final Widget child;

  const StatAnimationDisplay({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  State<StatAnimationDisplay> createState() => _StatAnimationDisplayState();
}

class _StatAnimationDisplayState extends State<StatAnimationDisplay> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        ...widget.controller.activeAnimations.map((animation) {
          return Positioned.fill(
            child: Align(
              alignment: Alignment(
                animation.position.dx * 2 - 1, // Convert 0-1 to -1 to 1
                animation.position.dy * 2 - 1,
              ),
              child: FloatingStatGainAnimation(
                key: ValueKey(animation.id),
                statGains: animation.statGains,
                expGained: animation.expGained,
                onAnimationComplete: animation.onComplete,
                enableHapticFeedback: animation.enableHapticFeedback,
                enableParticleEffects: animation.enableParticleEffects,
                enableScreenFlash: animation.enableScreenFlash,
                startPosition: animation.position,
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}

/// Convenient mixin for widgets that need stat animations
mixin StatAnimationMixin<T extends StatefulWidget> on State<T> {
  late StatAnimationController _statAnimationController;

  StatAnimationController get statAnimationController => _statAnimationController;

  @override
  void initState() {
    super.initState();
    _statAnimationController = StatAnimationController();
  }

  @override
  void dispose() {
    _statAnimationController.dispose();
    super.dispose();
  }

  /// Convenience method to show stat gains
  void showStatGains({
    required Map<StatType, double> statGains,
    double expGained = 0.0,
    VoidCallback? onComplete,
    bool enableHapticFeedback = true,
    bool enableParticleEffects = true,
    bool enableScreenFlash = true,
  }) {
    _statAnimationController.queueStatGainAnimation(
      statGains: statGains,
      expGained: expGained,
      onComplete: onComplete,
      enableHapticFeedback: enableHapticFeedback,
      enableParticleEffects: enableParticleEffects,
      enableScreenFlash: enableScreenFlash,
    );
  }

  /// Convenience method to show batch stat gains
  void showBatchStatGains({
    required List<Map<StatType, double>> batchStatGains,
    required List<double> batchExpGained,
    VoidCallback? onAllComplete,
    bool enableHapticFeedback = true,
    bool enableParticleEffects = true,
    Duration staggerDelay = const Duration(milliseconds: 150),
  }) {
    _statAnimationController.queueBatchStatAnimations(
      batchStatGains: batchStatGains,
      batchExpGained: batchExpGained,
      onAllComplete: onAllComplete,
      enableHapticFeedback: enableHapticFeedback,
      enableParticleEffects: enableParticleEffects,
      staggerDelay: staggerDelay,
    );
  }

  /// Wrap your widget tree with stat animation support
  Widget withStatAnimations(Widget child) {
    return StatAnimationDisplay(
      controller: _statAnimationController,
      child: child,
    );
  }
}