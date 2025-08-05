import 'package:flutter/material.dart';
import 'solo_leveling_theme.dart';
import 'glassmorphism_effects.dart';

/// Demo screen showcasing Solo Leveling theme system
/// This file demonstrates how to use the comprehensive theme system
class SoloLevelingThemeDemo extends StatelessWidget {
  const SoloLevelingThemeDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SoloLevelingColors.midnightBase,
      appBar: AppBar(
        title: Text(
          'Solo Leveling Theme Demo',
          style: SoloLevelingTypography.hunterTitle.copyWith(fontSize: 20),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: SoloLevelingGradients.mainBackground,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Color Palette Section
              _buildSectionTitle('Color Palette'),
              _buildColorPalette(),
              
              const SizedBox(height: 32),
              
              // Hunter Ranks Section
              _buildSectionTitle('Hunter Ranks'),
              _buildHunterRanks(),
              
              const SizedBox(height: 32),
              
              // Typography Section
              _buildSectionTitle('Typography'),
              _buildTypographyExamples(),
              
              const SizedBox(height: 32),
              
              // Glassmorphism Effects Section
              _buildSectionTitle('Glassmorphism Effects'),
              _buildGlassmorphismExamples(),
              
              const SizedBox(height: 32),
              
              // System Colors Section
              _buildSectionTitle('System Colors'),
              _buildSystemColors(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: SoloLevelingTypography.hunterTitle.copyWith(fontSize: 24),
      ),
    );
  }

  Widget _buildColorPalette() {
    final colors = [
      ('Void Black', SoloLevelingColors.voidBlack),
      ('Midnight Base', SoloLevelingColors.midnightBase),
      ('Shadow Depth', SoloLevelingColors.shadowDepth),
      ('Hunter Green', SoloLevelingColors.hunterGreen),
      ('Electric Blue', SoloLevelingColors.electricBlue),
      ('Mystic Purple', SoloLevelingColors.mysticPurple),
      ('Crimson Red', SoloLevelingColors.crimsonRed),
      ('Ghost White', SoloLevelingColors.ghostWhite),
      ('Silver Mist', SoloLevelingColors.silverMist),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: colors.map((colorData) {
        return Container(
          width: 100,
          height: 80,
          decoration: BoxDecoration(
            color: colorData.$2,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: SoloLevelingColors.electricBlue.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: SoloLevelingColors.voidBlack.withValues(alpha: 0.7),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Text(
                  colorData.$1,
                  style: SoloLevelingTypography.systemNotification.copyWith(
                    fontSize: 10,
                    color: SoloLevelingColors.ghostWhite,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHunterRanks() {
    final ranks = ['E', 'D', 'C', 'B', 'A', 'S', 'SS', 'SSS'];
    
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: ranks.map((rank) {
        final color = HunterRankColors.getRankColor(rank);
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Center(
            child: Text(
              rank,
              style: SoloLevelingTypography.rankDisplay.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTypographyExamples() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hunter Title Style',
          style: SoloLevelingTypography.hunterTitle,
        ),
        const SizedBox(height: 8),
        Text(
          'Hunter Subtitle Style',
          style: SoloLevelingTypography.hunterSubtitle,
        ),
        const SizedBox(height: 8),
        Text(
          'System Notification Style',
          style: SoloLevelingTypography.systemNotification,
        ),
        const SizedBox(height: 8),
        Text(
          'System Alert Style',
          style: SoloLevelingTypography.systemAlert,
        ),
        const SizedBox(height: 8),
        Text(
          'Stat Value: 999,999',
          style: SoloLevelingTypography.statValue,
        ),
        const SizedBox(height: 8),
        Text(
          'LEVEL 100',
          style: SoloLevelingTypography.levelDisplay,
        ),
      ],
    );
  }

  Widget _buildGlassmorphismExamples() {
    return Column(
      children: [
        // Basic Glassmorphic Container
        const Text(
          'Basic Glassmorphic Container',
          style: SoloLevelingTypography.systemNotification,
        ).withGlass(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
        ),
        
        // Hunter Panel
        const Text(
          'Hunter Panel with Glow Effect',
          style: SoloLevelingTypography.hunterSubtitle,
        ).withHunterPanel(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(bottom: 16),
          glowEffect: true,
        ),
        
        // System Panel
        const Text(
          'Active System Panel',
          style: SoloLevelingTypography.systemNotification,
        ).withSystemPanel(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          isActive: true,
        ),
        
        // Stat Card Example
        GlassmorphismEffects.statCard(
          rank: 'S',
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            children: [
              Text(
                'S-RANK HUNTER',
                style: SoloLevelingTypography.rankDisplay.copyWith(
                  color: HunterRankColors.getRankColor('S'),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Power Level: 15,847',
                style: SoloLevelingTypography.statValue.copyWith(fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSystemColors() {
    final systemColors = [
      ('Success', SystemColors.systemSuccess),
      ('Warning', SystemColors.systemWarning),
      ('Error', SystemColors.systemError),
      ('Info', SystemColors.systemInfo),
      ('Level Up', SystemColors.levelUpGlow),
      ('Critical Hit', SystemColors.criticalHit),
      ('Healing', SystemColors.healingGreen),
      ('Mana', SystemColors.manaBlue),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: systemColors.map((colorData) {
        return Container(
          width: 120,
          height: 60,
          decoration: BoxDecoration(
            color: colorData.$2,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: colorData.$2.withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Center(
            child: Text(
              colorData.$1,
              style: SoloLevelingTypography.systemNotification.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Extension methods to demonstrate theme usage
extension SoloLevelingThemeUsage on BuildContext {
  /// Example of how to access theme colors easily
  void showHunterNotification(String message, String rank) {
    final rankColor = HunterRankColors.getRankColor(rank);
    
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        backgroundColor: SoloLevelingColors.shadowDepth,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: rankColor, width: 2),
        ),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: rankColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                rank,
                style: SoloLevelingTypography.systemNotification.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: SoloLevelingTypography.systemNotification,
              ),
            ),
          ],
        ),
      ),
    );
  }
}