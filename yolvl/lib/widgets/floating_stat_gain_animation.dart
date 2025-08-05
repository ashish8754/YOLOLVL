import 'package:flutter/material.dart';
import 'dart:math';
import '../models/enums.dart';
import '../theme/solo_leveling_theme.dart';

/// Widget that shows floating stat gain animations
class FloatingStatGainAnimation extends StatefulWidget {
  final Map<StatType, double> statGains;
  final double expGained;
  final VoidCallback? onAnimationComplete;
  final bool enableHapticFeedback;
  final bool enableParticleEffects;
  final bool enableScreenFlash;

  const FloatingStatGainAnimation({
    super.key,
    required this.statGains,
    required this.expGained,
    this.onAnimationComplete,
    this.enableHapticFeedback = true,
    this.enableParticleEffects = true,
    this.enableScreenFlash = true,
  });

  @override
  State<FloatingStatGainAnimation> createState() => _FloatingStatGainAnimationState();
}

class _FloatingStatGainAnimationState extends State<FloatingStatGainAnimation>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;
  final List<_ParticleData> _particles = [];
  final Random _random = Random();
  late List<Animation<double>> _particleAnimations;

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
    
    // Initialize particle animations
    _particleAnimations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeOut,
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
            text: '${entry.key.emojiIcon} +${entry.value.toStringAsFixed(2)}',
            color: entry.key.color,
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

  Duration _getAnimationDuration(int index) {
    final gainAmount = _getGainAmount(index);
    if (gainAmount > 5.0) {
      return const Duration(milliseconds: 2500); // Epic gains
    } else if (gainAmount > 1.0) {
      return const Duration(milliseconds: 2000); // Medium gains
    } else {
      return const Duration(milliseconds: 1500); // Small gains
    }
  }

  double _getGainAmount(int index) {
    final gains = widget.statGains.values.toList();
    if (index < gains.length) {
      return gains[index];
    } else if (index == gains.length && widget.expGained > 0) {
      return widget.expGained / 10; // Scale EXP for comparison
    }
    return 0.0;
  }

  _AnimationStyle _getAnimationStyle(double gainAmount) {
    if (gainAmount > 5.0) {
      return _AnimationStyle.epic;
    } else if (gainAmount > 1.0) {
      return _AnimationStyle.medium;
    } else {
      return _AnimationStyle.small;
    }
  }

  bool _hasMajorGains() {
    return widget.statGains.values.any((gain) => gain > 3.0) || widget.expGained > 50;
  }

  void _generateParticles() {
    final particleCount = _hasMajorGains() ? 15 : 8;
    for (int i = 0; i < particleCount; i++) {
      _particles.add(_ParticleData(
        startX: _random.nextDouble(),
        startY: _random.nextDouble(),
        endX: _random.nextDouble(),
        endY: _random.nextDouble() - 0.5,
        color: _hasMajorGains() 
            ? SoloLevelingColors.electricBlue
            : SoloLevelingColors.hunterGreen,
        size: _random.nextDouble() * 3 + 1,
        animationDelay: _random.nextInt(500),
      ));
    }
  }

  List<Widget> _buildParticleEffects() {
    if (_particles.isEmpty) return [];
    
    return _particles.asMap().entries.map((entry) {
      final index = entry.key;
      final particle = entry.value;
      final controllerIndex = index % _controllers.length;
      
      return AnimatedBuilder(
        animation: _particleAnimations[controllerIndex],
        builder: (context, child) {
          final progress = _particleAnimations[controllerIndex].value;
          return Positioned(
            left: MediaQuery.of(context).size.width * 
                (particle.startX + (particle.endX - particle.startX) * progress),
            top: MediaQuery.of(context).size.height * 
                (particle.startY + (particle.endY - particle.startY) * progress),
            child: Container(
              width: particle.size,
              height: particle.size,
              decoration: BoxDecoration(
                color: particle.color.withValues(alpha: (1.0 - progress) * 0.8),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: particle.color.withValues(alpha: (1.0 - progress) * 0.4),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          );
        },
      );
    }).toList();
  }
}

/// Animation style configuration for different gain amounts
class _AnimationStyle {
  final double fontSize;
  final double iconSize;
  final FontWeight fontWeight;
  final double padding;
  final double borderRadius;
  final double borderWidth;
  final double glowRadius;
  final double glowSpread;
  final bool hasOuterGlow;

  const _AnimationStyle({
    required this.fontSize,
    required this.iconSize,
    required this.fontWeight,
    required this.padding,
    required this.borderRadius,
    required this.borderWidth,
    required this.glowRadius,
    required this.glowSpread,
    required this.hasOuterGlow,
  });

  // Small gains (+0.1 to +1.0)
  static const small = _AnimationStyle(
    fontSize: 16,
    iconSize: 18,
    fontWeight: FontWeight.w600,
    padding: 12,
    borderRadius: 20,
    borderWidth: 1,
    glowRadius: 8,
    glowSpread: 2,
    hasOuterGlow: false,
  );

  // Medium gains (+1.1 to +5.0)
  static const medium = _AnimationStyle(
    fontSize: 20,
    iconSize: 22,
    fontWeight: FontWeight.w700,
    padding: 16,
    borderRadius: 25,
    borderWidth: 2,
    glowRadius: 12,
    glowSpread: 3,
    hasOuterGlow: false,
  );

  // Epic gains (+5.1+)
  static const epic = _AnimationStyle(
    fontSize: 24,
    iconSize: 28,
    fontWeight: FontWeight.w800,
    padding: 20,
    borderRadius: 30,
    borderWidth: 3,
    glowRadius: 20,
    glowSpread: 5,
    hasOuterGlow: true,
  );
}

/// Particle data for visual effects
class _ParticleData {
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final Color color;
  final double size;
  final int animationDelay;

  _ParticleData({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.color,
    required this.size,
    required this.animationDelay,
  });
}

/// Enhanced overlay widget with position awareness and animation management
class FloatingGainOverlay extends StatefulWidget {
  final Widget child;
  final Map<StatType, double>? statGains;
  final double? expGained;
  final bool showGains;
  final VoidCallback? onAnimationComplete;
  final bool enableHapticFeedback;
  final bool enableParticleEffects;
  final bool enableScreenFlash;
  final Alignment animationAlignment;

  const FloatingGainOverlay({
    super.key,
    required this.child,
    this.statGains,
    this.expGained,
    this.showGains = false,
    this.onAnimationComplete,
    this.enableHapticFeedback = true,
    this.enableParticleEffects = true,
    this.enableScreenFlash = true,
    this.animationAlignment = Alignment.center,
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
            child: Align(
              alignment: widget.animationAlignment,
              child: FloatingStatGainAnimation(
                statGains: widget.statGains!,
                expGained: widget.expGained ?? 0.0,
                onAnimationComplete: _onAnimationComplete,
                enableHapticFeedback: widget.enableHapticFeedback,
                enableParticleEffects: widget.enableParticleEffects,
                enableScreenFlash: widget.enableScreenFlash,
              ),
            ),
          ),
      ],
    );
  }
}