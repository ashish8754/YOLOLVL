import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'level_up_celebration.dart';
import '../theme/solo_leveling_theme.dart';
import '../theme/glassmorphism_effects.dart';
import '../services/hunter_rank_service.dart';
import '../models/enums.dart';

/// Enhanced Solo Leveling themed level up overlay with glassmorphism effects
/// Provides full-screen celebration with blur background and epic animations
class LevelUpOverlay extends StatefulWidget {
  final Widget child;
  final bool showCelebration;
  final int? newLevel;
  final int? previousLevel;
  final Map<StatType, double>? statIncreases;
  final Map<String, double>? namedStatIncreases;
  final bool isFirstLevelUp;
  final VoidCallback? onAnimationComplete;
  final VoidCallback? onSoundEffect;

  const LevelUpOverlay({
    super.key,
    required this.child,
    required this.showCelebration,
    this.newLevel,
    this.previousLevel,
    this.statIncreases,
    this.namedStatIncreases,
    this.isFirstLevelUp = false,
    this.onAnimationComplete,
    this.onSoundEffect,
  });

  @override
  State<LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends State<LevelUpOverlay>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _contentController;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _blurAnimation;
  
  String? _previousRank;
  String? _newRank;
  bool _hasRankUp = false;
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkRankProgression();
  }
  
  @override
  void didUpdateWidget(LevelUpOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (!oldWidget.showCelebration && widget.showCelebration) {
      _checkRankProgression();
      _startCelebration();
    } else if (oldWidget.showCelebration && !widget.showCelebration) {
      _endCelebration();
    }
  }
  
  void _setupAnimations() {
    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));
    
    _blurAnimation = Tween<double>(
      begin: 0.0,
      end: 15.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeOut,
    ));
  }
  
  void _checkRankProgression() {
    if (widget.previousLevel != null && widget.newLevel != null) {
      final previousRankData = HunterRankService.instance.getRankForLevel(widget.previousLevel!);
      final newRankData = HunterRankService.instance.getRankForLevel(widget.newLevel!);
      _previousRank = previousRankData.rank;
      _newRank = newRankData.rank;
      _hasRankUp = _previousRank != _newRank;
    }
  }
  
  void _startCelebration() {
    _backgroundController.forward();
    _contentController.forward();
  }
  
  void _endCelebration() {
    _backgroundController.reverse();
    _contentController.reverse();
  }
  
  @override
  void dispose() {
    _backgroundController.dispose();
    _contentController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main content
        widget.child,
        
        // Level up celebration overlay with glassmorphism
        if (widget.showCelebration && widget.newLevel != null)
          AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return Positioned.fill(
                child: _buildEnhancedOverlay(context),
              );
            },
          ),
      ],
    );
  }
  
  Widget _buildEnhancedOverlay(BuildContext context) {
    return Stack(
      children: [
        // Glassmorphic background with blur
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: _blurAnimation.value,
              sigmaY: _blurAnimation.value,
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.5,
                  colors: [
                    SoloLevelingColors.voidBlack.withValues(alpha: 
                      0.4 * _backgroundAnimation.value,
                    ),
                    SoloLevelingColors.midnightBase.withValues(alpha: 
                      0.7 * _backgroundAnimation.value,
                    ),
                    SoloLevelingColors.shadowDepth.withValues(alpha: 
                      0.9 * _backgroundAnimation.value,
                    ),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ),
        ),
        
        // Electric energy overlay for epic celebrations
        if (_hasRankUp || widget.isFirstLevelUp || (widget.newLevel! % 10 == 0))
          Positioned.fill(
            child: _buildEnergyOverlay(),
          ),
        
        // Main celebration content
        Positioned.fill(
          child: FadeTransition(
            opacity: _contentController,
            child: LevelUpCelebration(
              newLevel: widget.newLevel!,
              previousLevel: widget.previousLevel,
              previousRank: _previousRank,
              newRank: _newRank,
              statIncreases: _buildNamedStatIncreases(),
              isFirstLevelUp: widget.isFirstLevelUp,
              onAnimationComplete: _onCelebrationComplete,
              onSoundEffect: widget.onSoundEffect,
            ),
          ),
        ),
        
        // Stats comparison panel (shows before/after stats)
        if (widget.statIncreases != null && widget.statIncreases!.isNotEmpty)
          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: _buildStatsComparisonPanel(),
          ),
        
        // Hunter abilities unlocked panel
        if (_hasRankUp)
          Positioned(
            bottom: 80,
            left: 20,
            right: 20,
            child: _buildAbilitiesUnlockedPanel(),
          ),
      ],
    );
  }
  
  Widget _buildEnergyOverlay() {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        return CustomPaint(
          painter: EnergyOverlayPainter(
            animationValue: _backgroundAnimation.value,
            hasRankUp: _hasRankUp,
            isFirstLevelUp: widget.isFirstLevelUp,
            newLevel: widget.newLevel!,
          ),
          size: MediaQuery.of(context).size,
        );
      },
    );
  }
  
  Widget _buildStatsComparisonPanel() {
    return FadeTransition(
      opacity: _contentController,
      child: GlassmorphismEffects.systemPanel(
        isActive: true,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'STAT INCREASES',
              style: SoloLevelingTypography.systemAlert.copyWith(
                color: SoloLevelingColors.electricBlue,
                fontSize: 14,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 12),
            ...widget.statIncreases!.entries.map((entry) {
              final statName = entry.key.name.toUpperCase();
              final increase = entry.value;
              final statColor = _getStatColor(entry.key);
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      statName,
                      style: SoloLevelingTypography.systemNotification.copyWith(
                        color: statColor,
                        fontSize: 14,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: statColor.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '+${increase.toStringAsFixed(2)}',
                        style: SoloLevelingTypography.systemNotification.copyWith(
                          color: statColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAbilitiesUnlockedPanel() {
    final rankData = HunterRankService.instance.getRankData(_newRank!);
    
    return FadeTransition(
      opacity: _contentController,
      child: GlassmorphismEffects.hunterPanel(
        glowEffect: true,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.military_tech,
                  color: rankData.color,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'NEW ABILITIES UNLOCKED',
                  style: SoloLevelingTypography.systemAlert.copyWith(
                    color: rankData.color,
                    fontSize: 16,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              rankData.description,
              style: SoloLevelingTypography.systemNotification.copyWith(
                color: SoloLevelingColors.ghostWhite,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildBonusIndicator(
                  'STAT BONUS',
                  '+${(rankData.statBonus * 100).toStringAsFixed(0)}%',
                  SoloLevelingColors.hunterGreen,
                ),
                _buildBonusIndicator(
                  'EXP BONUS',
                  '+${(rankData.expBonus * 100).toStringAsFixed(0)}%',
                  SoloLevelingColors.electricBlue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBonusIndicator(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: SoloLevelingTypography.systemNotification.copyWith(
            color: SoloLevelingColors.silverMist,
            fontSize: 12,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: SoloLevelingTypography.statValue.copyWith(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
  
  Color _getStatColor(StatType statType) {
    switch (statType) {
      case StatType.strength:
        return SystemColors.strengthRed;
      case StatType.agility:
        return SystemColors.agilityGreen;
      case StatType.endurance:
        return SystemColors.enduranceOrange;
      case StatType.intelligence:
        return SystemColors.intelligenceBlue;
      case StatType.focus:
        return SystemColors.focusPurple;
      case StatType.charisma:
        return SystemColors.charismaYellow;
    }
  }
  
  Map<String, double>? _buildNamedStatIncreases() {
    if (widget.namedStatIncreases != null) {
      return widget.namedStatIncreases;
    }
    
    if (widget.statIncreases == null) {
      return null;
    }
    
    return Map.fromEntries(
      widget.statIncreases!.entries.map(
        (entry) => MapEntry(entry.key.name, entry.value),
      ),
    );
  }
  
  void _onCelebrationComplete() {
    _endCelebration();
    
    // Delay callback to allow animation to complete
    Future.delayed(const Duration(milliseconds: 500), () {
      if (widget.onAnimationComplete != null) {
        widget.onAnimationComplete!();
      }
    });
  }
}

/// Energy overlay painter for dramatic background effects
class EnergyOverlayPainter extends CustomPainter {
  final double animationValue;
  final bool hasRankUp;
  final bool isFirstLevelUp;
  final int newLevel;

  EnergyOverlayPainter({
    required this.animationValue,
    required this.hasRankUp,
    required this.isFirstLevelUp,
    required this.newLevel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    // Draw energy waves
    if (hasRankUp || isFirstLevelUp) {
      _drawEnergyWaves(canvas, size, centerX, centerY);
    }
    
    // Draw milestone burst for every 10 levels
    if (newLevel % 10 == 0) {
      _drawMilestoneBurst(canvas, size, centerX, centerY);
    }
  }
  
  void _drawEnergyWaves(Canvas canvas, Size size, double centerX, double centerY) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 3);
    
    for (int i = 0; i < 5; i++) {
      final waveProgress = (animationValue - i * 0.1).clamp(0.0, 1.0);
      final radius = waveProgress * 300.0;
      final opacity = (1.0 - waveProgress) * 0.6;
      
      paint.color = (hasRankUp 
          ? SoloLevelingColors.electricBlue 
          : SoloLevelingColors.hunterGreen).withValues(alpha: opacity);
      
      canvas.drawCircle(Offset(centerX, centerY), radius, paint);
    }
  }
  
  void _drawMilestoneBurst(Canvas canvas, Size size, double centerX, double centerY) {
    final paint = Paint()
      ..color = SoloLevelingColors.mysticPurple.withValues(alpha: 
        0.4 * (1.0 - animationValue),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 5);
    
    // Draw radiating lines
    for (int i = 0; i < 12; i++) {
      final angle = i * math.pi / 6;
      final length = animationValue * 200.0;
      
      final startX = centerX + 30 * math.cos(angle);
      final startY = centerY + 30 * math.sin(angle);
      final endX = centerX + length * math.cos(angle);
      final endY = centerY + length * math.sin(angle);
      
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}