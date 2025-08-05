import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import '../theme/solo_leveling_theme.dart';
import '../theme/glassmorphism_effects.dart';

/// Enhanced Solo Leveling themed level up celebration widget
/// Features dramatic animations, particle effects, and rank-based celebrations
class LevelUpCelebration extends StatefulWidget {
  final int newLevel;
  final int? previousLevel;
  final String? previousRank;
  final String? newRank;
  final Map<String, double>? statIncreases;
  final bool isFirstLevelUp;
  final VoidCallback? onAnimationComplete;
  final VoidCallback? onSoundEffect;

  const LevelUpCelebration({
    super.key,
    required this.newLevel,
    this.previousLevel,
    this.previousRank,
    this.newRank,
    this.statIncreases,
    this.isFirstLevelUp = false,
    this.onAnimationComplete,
    this.onSoundEffect,
  });

  @override
  State<LevelUpCelebration> createState() => _LevelUpCelebrationState();
}

class _LevelUpCelebrationState extends State<LevelUpCelebration>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _particleController;
  late AnimationController _glowController;
  late AnimationController _shakeController;
  late AnimationController _textController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _shakeAnimation;
  late Animation<double> _textAnimation;
  
  late CelebrationType _celebrationType;
  late Color _primaryColor;
  late Color _secondaryColor;
  
  bool _hasRankUp = false;
  bool _isMilestone = false;

  @override
  void initState() {
    super.initState();
    
    _determineCelebrationType();
    _setupAnimationControllers();
    _setupAnimations();
    _startAnimation();
  }
  
  void _determineCelebrationType() {
    // Check if there's a rank up
    _hasRankUp = widget.previousRank != null && 
                 widget.newRank != null && 
                 widget.previousRank != widget.newRank;
    
    // Check if it's a milestone level (every 10 levels)
    _isMilestone = widget.newLevel % 10 == 0;
    
    // Determine celebration type
    if (widget.isFirstLevelUp) {
      _celebrationType = CelebrationType.firstLevelUp;
      _primaryColor = SystemColors.levelUpGlow;
      _secondaryColor = SoloLevelingColors.hunterGreen;
    } else if (_hasRankUp) {
      _celebrationType = CelebrationType.rankUp;
      final rankColor = HunterRankColors.getRankColor(widget.newRank!);
      _primaryColor = rankColor;
      _secondaryColor = SoloLevelingColors.electricBlue;
    } else if (_isMilestone) {
      _celebrationType = CelebrationType.milestone;
      _primaryColor = SoloLevelingColors.electricBlue;
      _secondaryColor = SoloLevelingColors.mysticPurple;
    } else {
      _celebrationType = CelebrationType.standard;
      _primaryColor = SoloLevelingColors.hunterGreen;
      _secondaryColor = SoloLevelingColors.electricBlue;
    }
  }
  
  void _setupAnimationControllers() {
    final duration = _getCelebrationDuration();
    
    _scaleController = AnimationController(
      duration: Duration(milliseconds: (duration * 0.4).round()),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: Duration(milliseconds: (duration * 0.3).round()),
      vsync: this,
    );
    
    _particleController = AnimationController(
      duration: Duration(milliseconds: (duration * 0.8).round()),
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: Duration(milliseconds: (duration * 0.6).round()),
      vsync: this,
    );
    
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _textController = AnimationController(
      duration: Duration(milliseconds: (duration * 0.5).round()),
      vsync: this,
    );
  }
  
  void _setupAnimations() {
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: _celebrationType == CelebrationType.rankUp 
          ? Curves.elasticOut 
          : Curves.bounceOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _particleController,
      curve: Curves.easeOut,
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
    
    _shakeAnimation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticInOut,
    ));
    
    _textAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutBack,
    ));
  }
  
  int _getCelebrationDuration() {
    switch (_celebrationType) {
      case CelebrationType.firstLevelUp:
        return 4000;
      case CelebrationType.rankUp:
        return 5000;
      case CelebrationType.milestone:
        return 3500;
      case CelebrationType.standard:
        return 2500;
    }
  }

  void _startAnimation() async {
    // Trigger haptic feedback based on celebration type
    _triggerHapticFeedback();
    
    // Trigger sound effect callback
    if (widget.onSoundEffect != null) {
      widget.onSoundEffect!();
    }
    
    // Start background fade and glow
    _fadeController.forward();
    _glowController.forward();
    
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Add screen shake for epic celebrations
    if (_celebrationType == CelebrationType.rankUp || 
        _celebrationType == CelebrationType.milestone) {
      _shakeController.forward();
    }
    
    await Future.delayed(const Duration(milliseconds: 200));
    
    // Start main content animations
    _scaleController.forward();
    _textController.forward();
    _particleController.forward();
    
    // Wait for animation completion
    final duration = _getCelebrationDuration();
    await Future.delayed(Duration(milliseconds: duration - 500));
    
    // Fade out
    _fadeController.reverse();
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (widget.onAnimationComplete != null) {
      widget.onAnimationComplete!();
    }
  }
  
  void _triggerHapticFeedback() {
    switch (_celebrationType) {
      case CelebrationType.firstLevelUp:
      case CelebrationType.rankUp:
        HapticFeedback.heavyImpact();
        break;
      case CelebrationType.milestone:
        HapticFeedback.mediumImpact();
        break;
      case CelebrationType.standard:
        HapticFeedback.lightImpact();
        break;
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _particleController.dispose();
    _glowController.dispose();
    _shakeController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return AnimatedBuilder(
      animation: Listenable.merge([
        _scaleController, 
        _fadeController, 
        _particleController,
        _glowController,
        _shakeController,
        _textController,
      ]),
      builder: (context, child) {
        return Transform.translate(
          offset: _celebrationType == CelebrationType.rankUp || 
                  _celebrationType == CelebrationType.milestone
                  ? Offset(_shakeAnimation.value * 8, 0)
                  : Offset.zero,
          child: Stack(
            children: [
              // Glassmorphic background with glow
              Positioned.fill(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.5 * _glowAnimation.value,
                      colors: [
                        _primaryColor.withValues(alpha: 0.3 * _fadeAnimation.value),
                        _secondaryColor.withValues(alpha: 0.2 * _fadeAnimation.value),
                        SoloLevelingColors.electricBlue.withValues(alpha: 0.1 * _fadeAnimation.value),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.4, 0.7, 1.0],
                    ),
                  ),
                ),
              ),
              
              // Electric particle background
              CustomPaint(
                painter: ElectricParticlePainter(
                  animationValue: _particleAnimation.value,
                  primaryColor: _primaryColor,
                  secondaryColor: _secondaryColor,
                  celebrationType: _celebrationType,
                ),
                size: screenSize,
              ),
              
              // Energy burst effects for rank ups
              if (_hasRankUp || _celebrationType == CelebrationType.milestone)
                Positioned.fill(
                  child: CustomPaint(
                    painter: EnergyBurstPainter(
                      animationValue: _glowAnimation.value,
                      color: _primaryColor,
                    ),
                    size: screenSize,
                  ),
                ),
              
              // Main celebration content
              Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: _buildCelebrationContent(context),
                  ),
                ),
              ),
              
              // Floating stat increase indicators
              if (widget.statIncreases != null && widget.statIncreases!.isNotEmpty)
                ..._buildStatIncreaseIndicators(context),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildCelebrationContent(BuildContext context) {
    return GlassmorphismEffects.hunterPanel(
      glowEffect: true,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main celebration icon with glow
          _buildCelebrationIcon(),
          
          const SizedBox(height: 24),
          
          // Main title with epic styling
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.5),
              end: Offset.zero,
            ).animate(_textAnimation),
            child: _buildMainTitle(),
          ),
          
          const SizedBox(height: 16),
          
          // Level display
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.5),
              end: Offset.zero,
            ).animate(_textAnimation),
            child: _buildLevelDisplay(),
          ),
          
          // Rank up display
          if (_hasRankUp) ...[
            const SizedBox(height: 16),
            _buildRankUpDisplayContent(),
          ],
          
          const SizedBox(height: 20),
          
          // Congratulatory message
          FadeTransition(
            opacity: _textAnimation,
            child: _buildCongratulatoryMessage(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCelebrationIcon() {
    IconData iconData;
    switch (_celebrationType) {
      case CelebrationType.firstLevelUp:
        iconData = Icons.star_border;
        break;
      case CelebrationType.rankUp:
        iconData = Icons.military_tech;
        break;
      case CelebrationType.milestone:
        iconData = Icons.emoji_events;
        break;
      case CelebrationType.standard:
        iconData = Icons.trending_up;
        break;
    }
    
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withValues(alpha: 0.6),
            blurRadius: 20 * _glowAnimation.value,
            spreadRadius: 4 * _glowAnimation.value,
          ),
        ],
      ),
      child: Icon(
        iconData,
        size: 80,
        color: _primaryColor,
      ),
    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
     .shimmer(
       duration: 1500.ms,
       colors: [Colors.transparent, _primaryColor.withValues(alpha: 0.3)],
     );
  }
  
  Widget _buildMainTitle() {
    String title;
    switch (_celebrationType) {
      case CelebrationType.firstLevelUp:
        title = 'AWAKENING COMPLETE!';
        break;
      case CelebrationType.rankUp:
        title = 'RANK UP!';
        break;
      case CelebrationType.milestone:
        title = 'MILESTONE ACHIEVED!';
        break;
      case CelebrationType.standard:
        title = 'LEVEL UP!';
        break;
    }
    
    return Text(
      title,
      style: SoloLevelingTypography.hunterTitle.copyWith(
        fontSize: 32,
        color: _primaryColor,
        fontWeight: FontWeight.w900,
        letterSpacing: 2.0,
        shadows: [
          Shadow(
            color: _primaryColor.withValues(alpha: 0.8),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
     .shimmer(
       duration: 2000.ms,
       colors: [Colors.transparent, _primaryColor.withValues(alpha: 0.4)],
     );
  }
  
  Widget _buildLevelDisplay() {
    return Column(
      children: [
        Text(
          'LEVEL',
          style: SoloLevelingTypography.systemNotification.copyWith(
            color: SoloLevelingColors.silverMist,
            letterSpacing: 3.0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${widget.newLevel}',
          style: SoloLevelingTypography.levelDisplay.copyWith(
            fontSize: 48,
            color: _secondaryColor,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(
                color: _secondaryColor.withValues(alpha: 0.6),
                blurRadius: 15,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildRankUpDisplayContent() {
    return Column(
      children: [
        Text(
          'HUNTER RANK PROMOTION',
          style: SoloLevelingTypography.systemAlert.copyWith(
            color: _primaryColor,
            fontSize: 16,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: HunterRankColors.getRankColor(widget.previousRank!),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: HunterRankColors.getRankColor(widget.previousRank!).withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Text(
                widget.previousRank!,
                style: SoloLevelingTypography.rankDisplay.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Icon(
                Icons.arrow_forward,
                color: _primaryColor,
                size: 32,
              ).animate(onPlay: (controller) => controller.repeat())
               .scale(
                 duration: 1000.ms,
                 begin: const Offset(1.0, 1.0),
                 end: const Offset(1.2, 1.2),
               ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: HunterRankColors.getRankColor(widget.newRank!),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: HunterRankColors.getRankColor(widget.newRank!).withValues(alpha: 0.6),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Text(
                widget.newRank!,
                style: SoloLevelingTypography.rankDisplay.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
             .shimmer(
               duration: 1500.ms,
               colors: [Colors.transparent, HunterRankColors.getRankColor(widget.newRank!)],
             ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildCongratulatoryMessage() {
    String message;
    switch (_celebrationType) {
      case CelebrationType.firstLevelUp:
        message = 'Welcome to the world of Hunters!';
        break;
      case CelebrationType.rankUp:
        message = 'Your power has transcended to a new level!';
        break;
      case CelebrationType.milestone:
        message = 'An impressive milestone reached!';
        break;
      case CelebrationType.standard:
        message = 'Your strength continues to grow!';
        break;
    }
    
    return Text(
      message,
      style: SoloLevelingTypography.systemNotification.copyWith(
        color: SoloLevelingColors.ghostWhite.withValues(alpha: 0.9),
        fontSize: 16,
      ),
      textAlign: TextAlign.center,
    );
  }
  
  List<Widget> _buildStatIncreaseIndicators(BuildContext context) {
    final List<Widget> indicators = [];
    final screenSize = MediaQuery.of(context).size;
    
    int index = 0;
    widget.statIncreases!.forEach((statName, increase) {
      final angle = (index * 60) * (math.pi / 180); // 60 degrees apart
      final radius = 120.0;
      
      final x = screenSize.width / 2 + radius * math.cos(angle);
      final y = screenSize.height / 2 + radius * math.sin(angle);
      
      indicators.add(
        Positioned(
          left: x - 40,
          top: y - 20,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset.zero,
              end: Offset(math.cos(angle) * 0.3, math.sin(angle) * 0.3),
            ).animate(CurvedAnimation(
              parent: _textController,
              curve: Curves.easeOutBack,
            )),
            child: FadeTransition(
              opacity: _textController,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: SoloLevelingColors.hunterGreen.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: SoloLevelingColors.hunterGreen.withValues(alpha: 0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Text(
                  '+${increase.toStringAsFixed(2)} ${statName.toUpperCase()}',
                  style: SoloLevelingTypography.systemNotification.copyWith(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      
      index++;
    });
    
    return indicators;
  }
}

/// Enhanced electric particle painter for Solo Leveling effects
class ElectricParticlePainter extends CustomPainter {
  final double animationValue;
  final Color primaryColor;
  final Color secondaryColor;
  final CelebrationType celebrationType;
  final List<ElectricParticle> particles;

  ElectricParticlePainter({
    required this.animationValue,
    required this.primaryColor,
    required this.secondaryColor,
    required this.celebrationType,
  }) : particles = _generateElectricParticles(celebrationType, primaryColor, secondaryColor);

  static List<ElectricParticle> _generateElectricParticles(
    CelebrationType type, 
    Color primary, 
    Color secondary,
  ) {
    final random = math.Random();
    final particleCount = _getParticleCount(type);
    
    return List.generate(particleCount, (index) {
      return ElectricParticle(
        startX: random.nextDouble(),
        startY: random.nextDouble(),
        endX: random.nextDouble(),
        endY: random.nextDouble(),
        color: random.nextBool() ? primary : secondary,
        size: random.nextDouble() * 4 + 2,
        velocity: random.nextDouble() * 3 + 1,
        rotationSpeed: random.nextDouble() * 4 + 2,
        pulsePhase: random.nextDouble() * 2 * math.pi,
        lightningBolt: type == CelebrationType.rankUp && random.nextDouble() > 0.7,
      );
    });
  }
  
  static int _getParticleCount(CelebrationType type) {
    switch (type) {
      case CelebrationType.firstLevelUp:
        return 80;
      case CelebrationType.rankUp:
        return 120;
      case CelebrationType.milestone:
        return 100;
      case CelebrationType.standard:
        return 60;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      if (particle.lightningBolt) {
        _drawLightningBolt(canvas, size, particle);
      } else {
        _drawElectricParticle(canvas, size, particle);
      }
    }
    
    // Draw energy rings for epic celebrations
    if (celebrationType == CelebrationType.rankUp || 
        celebrationType == CelebrationType.milestone) {
      _drawEnergyRings(canvas, size);
    }
  }
  
  void _drawElectricParticle(Canvas canvas, Size size, ElectricParticle particle) {
    final progress = animationValue;
    final x = particle.startX * size.width + 
              (particle.endX - particle.startX) * size.width * progress;
    final y = particle.startY * size.height + 
              (particle.endY - particle.startY) * size.height * progress;
    
    // Pulsing opacity based on phase
    final pulseValue = math.sin(progress * 4 * math.pi + particle.pulsePhase);
    final opacity = (0.3 + 0.7 * pulseValue.abs()) * (1.0 - progress * 0.5);
    
    final paint = Paint()
      ..color = particle.color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 2);
    
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(progress * particle.rotationSpeed * 2 * math.pi);
    
    // Draw glowing particle
    canvas.drawCircle(
      Offset.zero,
      particle.size * (1.0 + pulseValue * 0.3),
      paint,
    );
    
    canvas.restore();
  }
  
  void _drawLightningBolt(Canvas canvas, Size size, ElectricParticle particle) {
    final progress = animationValue;
    final startX = particle.startX * size.width;
    final startY = particle.startY * size.height;
    final endX = particle.endX * size.width;
    final endY = particle.endY * size.height;
    
    final currentEndX = startX + (endX - startX) * progress;
    final currentEndY = startY + (endY - startY) * progress;
    
    final paint = Paint()
      ..color = particle.color.withValues(alpha: 0.8 * (1.0 - progress * 0.6))
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 3);
    
    final path = Path();
    path.moveTo(startX, startY);
    
    // Create zigzag lightning effect
    final segments = 5;
    for (int i = 1; i <= segments; i++) {
      final t = i / segments;
      final x = startX + (currentEndX - startX) * t;
      final y = startY + (currentEndY - startY) * t;
      
      // Add random offset for lightning effect
      final offset = math.sin(t * math.pi * 4) * 20 * (1.0 - t);
      path.lineTo(x + offset, y);
    }
    
    canvas.drawPath(path, paint);
  }
  
  void _drawEnergyRings(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final progress = animationValue;
    
    for (int i = 0; i < 3; i++) {
      final ringProgress = (progress - i * 0.2).clamp(0.0, 1.0);
      final radius = 50.0 + ringProgress * 200.0;
      final opacity = (1.0 - ringProgress) * 0.3;
      
      final paint = Paint()
        ..color = primaryColor.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 5);
      
      canvas.drawCircle(Offset(centerX, centerY), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

/// Energy burst painter for rank-up celebrations
class EnergyBurstPainter extends CustomPainter {
  final double animationValue;
  final Color color;

  EnergyBurstPainter({
    required this.animationValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final progress = animationValue;
    
    // Draw radiating energy lines
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6 * (1.0 - progress))
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 4);
    
    for (int i = 0; i < 16; i++) {
      final angle = i * math.pi / 8;
      final startRadius = 30.0;
      final endRadius = progress * 300.0;
      
      final startX = centerX + startRadius * math.cos(angle);
      final startY = centerY + startRadius * math.sin(angle);
      final endX = centerX + endRadius * math.cos(angle);
      final endY = centerY + endRadius * math.sin(angle);
      
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

/// Electric particle data class
class ElectricParticle {
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final Color color;
  final double size;
  final double velocity;
  final double rotationSpeed;
  final double pulsePhase;
  final bool lightningBolt;

  ElectricParticle({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.color,
    required this.size,
    required this.velocity,
    required this.rotationSpeed,
    required this.pulsePhase,
    this.lightningBolt = false,
  });
}

/// Celebration type enum
enum CelebrationType {
  standard,
  milestone,
  rankUp,
  firstLevelUp,
}