import 'package:flutter/material.dart';
import '../models/enums.dart';

/// Widget that shows floating stat gain animations
class FloatingStatGainAnimation extends StatefulWidget {
  final Map<StatType, double> statGains;
  final double expGained;
  final VoidCallback? onAnimationComplete;

  const FloatingStatGainAnimation({
    super.key,
    required this.statGains,
    required this.expGained,
    this.onAnimationComplete,
  });

  @override
  State<FloatingStatGainAnimation> createState() => _FloatingStatGainAnimationState();
}

class _FloatingStatGainAnimationState extends State<FloatingStatGainAnimation>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    final totalGains = widget.statGains.length + (widget.expGained > 0 ? 1 : 0);
    _controllers = List.generate(
      totalGains,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 1500),
        vsync: this,
      ),
    );

    _fadeAnimations = _controllers.map((controller) {
      return Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
        ),
      );
    }).toList();

    _slideAnimations = _controllers.map((controller) {
      return Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(0.0, -2.0),
      ).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeOutQuart,
        ),
      );
    }).toList();
  }

  void _startAnimations() async {
    // Start animations with slight delays
    for (int i = 0; i < _controllers.length; i++) {
      await Future.delayed(Duration(milliseconds: i * 100));
      if (mounted) {
        _controllers[i].forward();
      }
    }

    // Call completion callback after all animations finish
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted && widget.onAnimationComplete != null) {
      widget.onAnimationComplete!();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gains = <Widget>[];
    int animationIndex = 0;

    // Add stat gain animations
    for (final entry in widget.statGains.entries) {
      if (entry.value > 0) {
        gains.add(
          _buildFloatingGain(
            text: '${entry.key.icon} +${entry.value.toStringAsFixed(2)}',
            color: _getStatColor(entry.key),
            animationIndex: animationIndex,
          ),
        );
        animationIndex++;
      }
    }

    // Add EXP gain animation
    if (widget.expGained > 0) {
      gains.add(
        _buildFloatingGain(
          text: '⭐ +${widget.expGained.toStringAsFixed(0)} EXP',
          color: Theme.of(context).colorScheme.secondary,
          animationIndex: animationIndex,
        ),
      );
    }

    return Stack(
      children: gains,
    );
  }

  Widget _buildFloatingGain({
    required String text,
    required Color color,
    required int animationIndex,
  }) {
    if (animationIndex >= _controllers.length) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _controllers[animationIndex],
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimations[animationIndex],
          child: FadeTransition(
            opacity: _fadeAnimations[animationIndex],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      offset: const Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getStatColor(StatType statType) {
    switch (statType) {
      case StatType.strength:
        return Colors.red.shade600;
      case StatType.agility:
        return Colors.green.shade600;
      case StatType.endurance:
        return Colors.orange.shade600;
      case StatType.intelligence:
        return Colors.blue.shade600;
      case StatType.focus:
        return Colors.purple.shade600;
      case StatType.charisma:
        return Colors.pink.shade600;
    }
  }
}

/// Overlay widget to show floating gains on top of other content
class FloatingGainOverlay extends StatefulWidget {
  final Widget child;
  final Map<StatType, double>? statGains;
  final double? expGained;
  final bool showGains;
  final VoidCallback? onAnimationComplete;

  const FloatingGainOverlay({
    super.key,
    required this.child,
    this.statGains,
    this.expGained,
    this.showGains = false,
    this.onAnimationComplete,
  });

  @override
  State<FloatingGainOverlay> createState() => _FloatingGainOverlayState();
}

class _FloatingGainOverlayState extends State<FloatingGainOverlay> {
  bool _showAnimation = false;

  @override
  void didUpdateWidget(FloatingGainOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showGains && !oldWidget.showGains) {
      setState(() {
        _showAnimation = true;
      });
    }
  }

  void _onAnimationComplete() {
    setState(() {
      _showAnimation = false;
    });
    if (widget.onAnimationComplete != null) {
      widget.onAnimationComplete!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showAnimation && widget.statGains != null)
          Positioned.fill(
            child: Center(
              child: FloatingStatGainAnimation(
                statGains: widget.statGains!,
                expGained: widget.expGained ?? 0.0,
                onAnimationComplete: _onAnimationComplete,
              ),
            ),
          ),
      ],
    );
  }
}