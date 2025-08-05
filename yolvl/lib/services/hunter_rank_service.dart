import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../theme/solo_leveling_theme.dart';

/// Hunter Rank system inspired by Solo Leveling manhwa
/// Maps user levels to Hunter ranks with progression tracking and benefits
class HunterRankService {
  HunterRankService._();
  
  static final HunterRankService _instance = HunterRankService._();
  static HunterRankService get instance => _instance;

  /// Hunter rank definitions with level requirements
  static const Map<String, HunterRankData> _hunterRanks = {
    'E': HunterRankData(
      rank: 'E',
      name: 'E-Rank Hunter',
      minLevel: 1,
      maxLevel: 9,
      color: HunterRankColors.eRank,
      lightColor: HunterRankColors.eRankLight,
      description: 'Weakest hunters with basic awakened abilities',
      statBonus: 0.0,
      expBonus: 0.0,
    ),
    'D': HunterRankData(
      rank: 'D',
      name: 'D-Rank Hunter',
      minLevel: 10,
      maxLevel: 19,
      color: HunterRankColors.dRank,
      lightColor: HunterRankColors.dRankLight,
      description: 'Below average hunters with limited potential',
      statBonus: 0.02,
      expBonus: 0.05,
    ),
    'C': HunterRankData(
      rank: 'C',
      name: 'C-Rank Hunter',
      minLevel: 20,
      maxLevel: 34,
      color: HunterRankColors.cRank,
      lightColor: HunterRankColors.cRankLight,
      description: 'Average hunters capable of solo missions',
      statBonus: 0.05,
      expBonus: 0.10,
    ),
    'B': HunterRankData(
      rank: 'B',
      name: 'B-Rank Hunter',
      minLevel: 35,
      maxLevel: 54,
      color: HunterRankColors.bRank,
      lightColor: HunterRankColors.bRankLight,
      description: 'Above average hunters with significant power',
      statBonus: 0.08,
      expBonus: 0.15,
    ),
    'A': HunterRankData(
      rank: 'A',
      name: 'A-Rank Hunter',
      minLevel: 55,
      maxLevel: 79,
      color: HunterRankColors.aRank,
      lightColor: HunterRankColors.aRankLight,
      description: 'Elite hunters among the top 1% worldwide',
      statBonus: 0.12,
      expBonus: 0.20,
    ),
    'S': HunterRankData(
      rank: 'S',
      name: 'S-Rank Hunter',
      minLevel: 80,
      maxLevel: 99,
      color: HunterRankColors.sRank,
      lightColor: HunterRankColors.sRankLight,
      description: 'Top-tier hunters capable of raid leadership',
      statBonus: 0.18,
      expBonus: 0.25,
      hasGlowEffect: true,
    ),
    'SS': HunterRankData(
      rank: 'SS',
      name: 'SS-Rank Hunter',
      minLevel: 100,
      maxLevel: 149,
      color: HunterRankColors.ssRank,
      lightColor: HunterRankColors.ssRankLight,
      description: 'Legendary hunters with nation-level influence',
      statBonus: 0.25,
      expBonus: 0.30,
      hasGlowEffect: true,
      hasPulseEffect: true,
    ),
    'SSS': HunterRankData(
      rank: 'SSS',
      name: 'SSS-Rank Hunter',
      minLevel: 150,
      maxLevel: 999999, // Infinite progression like Sung Jin-Woo
      color: const Color(0xFFEF4444), // Red from sssRank
      lightColor: const Color(0xFFF59E0B), // Orange from sssRank
      description: 'Mythical hunters who transcend normal limits',
      statBonus: 0.35,
      expBonus: 0.40,
      hasGlowEffect: true,
      hasPulseEffect: true,
      hasRainbowEffect: true,
    ),
  };

  /// Get all available hunter ranks
  List<HunterRankData> get allRanks => _hunterRanks.values.toList();

  /// Get hunter rank data for a specific level
  HunterRankData getRankForLevel(int level) {
    for (final rankData in _hunterRanks.values) {
      if (level >= rankData.minLevel && level <= rankData.maxLevel) {
        return rankData;
      }
    }
    // Fallback to E-rank if no match found
    return _hunterRanks['E']!;
  }

  /// Get hunter rank data by rank string
  HunterRankData? getRankByString(String rank) {
    return _hunterRanks[rank.toUpperCase()];
  }
  
  /// Get hunter rank data by rank string (non-nullable version)
  HunterRankData getRankData(String rank) {
    return _hunterRanks[rank.toUpperCase()] ?? _hunterRanks['E']!;
  }

  /// Calculate progress within current rank
  double getRankProgress(int level) {
    final currentRank = getRankForLevel(level);
    
    if (currentRank.minLevel == currentRank.maxLevel) {
      return 1.0; // Single level rank (shouldn't happen with current setup)
    }
    
    final progressWithinRank = level - currentRank.minLevel;
    final totalLevelsInRank = currentRank.maxLevel - currentRank.minLevel + 1;
    
    return (progressWithinRank / totalLevelsInRank).clamp(0.0, 1.0);
  }

  /// Get next rank data (null if already at highest rank)
  HunterRankData? getNextRank(int level) {
    final currentRank = getRankForLevel(level);
    final currentRankIndex = _getRankIndex(currentRank.rank);
    
    if (currentRankIndex < allRanks.length - 1) {
      return allRanks[currentRankIndex + 1];
    }
    
    return null; // Already at highest rank
  }

  /// Get levels until next rank promotion
  int getLevelsToNextRank(int level) {
    final currentRank = getRankForLevel(level);
    final nextRank = getNextRank(level);
    
    if (nextRank == null) {
      return 0; // Already at max rank
    }
    
    return nextRank.minLevel - level;
  }

  /// Check if a level qualifies for rank up
  bool canRankUp(int oldLevel, int newLevel) {
    final oldRank = getRankForLevel(oldLevel);
    final newRank = getRankForLevel(newLevel);
    
    return oldRank.rank != newRank.rank;
  }

  /// Get rank up celebration data
  RankUpCelebration? getRankUpCelebration(int oldLevel, int newLevel) {
    if (!canRankUp(oldLevel, newLevel)) {
      return null;
    }
    
    final newRank = getRankForLevel(newLevel);
    
    return RankUpCelebration(
      oldRank: getRankForLevel(oldLevel),
      newRank: newRank,
      message: _getRankUpMessage(newRank),
      celebrationType: _getCelebrationType(newRank),
    );
  }

  /// Calculate stat bonus based on hunter rank
  double getStatBonus(int level, StatType statType) {
    final rank = getRankForLevel(level);
    return rank.statBonus;
  }

  /// Calculate EXP bonus based on hunter rank
  double getExpBonus(int level) {
    final rank = getRankForLevel(level);
    return rank.expBonus;
  }

  /// Get rank color with glow effects consideration
  Color getRankDisplayColor(int level, {bool forGlow = false}) {
    final rank = getRankForLevel(level);
    
    if (forGlow && rank.hasGlowEffect) {
      return rank.lightColor;
    }
    
    return rank.color;
  }

  /// Check if rank has special visual effects
  bool hasSpecialEffects(int level) {
    final rank = getRankForLevel(level);
    return rank.hasGlowEffect || rank.hasPulseEffect || rank.hasRainbowEffect;
  }

  /// Get rank achievements and milestones
  List<String> getRankAchievements(String rank) {
    switch (rank.toUpperCase()) {
      case 'E':
        return ['Awakened abilities unlocked', 'Basic hunter license obtained'];
      case 'D':
        return ['Solo mission capability', 'Party member qualification'];
      case 'C':
        return ['Independent hunter status', 'Guild recruitment eligibility'];
      case 'B':
        return ['Raid participation rights', 'Elite hunter recognition'];
      case 'A':
        return ['Guild leadership qualification', 'National hunter registry'];
      case 'S':
        return ['Raid command authority', 'International recognition'];
      case 'SS':
        return ['Legendary hunter status', 'Nation-level influence'];
      case 'SSS':
        return ['Transcendent hunter', 'Reality-bending capabilities'];
      default:
        return [];
    }
  }

  // Private helper methods
  int _getRankIndex(String rank) {
    const rankOrder = ['E', 'D', 'C', 'B', 'A', 'S', 'SS', 'SSS'];
    return rankOrder.indexOf(rank);
  }

  String _getRankUpMessage(HunterRankData newRank) {
    switch (newRank.rank) {
      case 'D':
        return 'You have proven yourself worthy of D-Rank!';
      case 'C':
        return 'Your abilities have reached C-Rank level!';
      case 'B':
        return 'Exceptional growth! You are now B-Rank!';
      case 'A':
        return 'Elite status achieved! Welcome to A-Rank!';
      case 'S':
        return 'Legendary power awakened! You are S-Rank!';
      case 'SS':
        return 'Transcendent abilities unlocked! SS-Rank Hunter!';
      case 'SSS':
        return 'You have surpassed all limits! SSS-Rank achieved!';
      default:
        return 'Congratulations on your rank promotion!';
    }
  }

  CelebrationType _getCelebrationType(HunterRankData rank) {
    switch (rank.rank) {
      case 'E':
      case 'D':
        return CelebrationType.basic;
      case 'C':
      case 'B':
        return CelebrationType.enhanced;
      case 'A':
        return CelebrationType.elite;
      case 'S':
        return CelebrationType.legendary;
      case 'SS':
        return CelebrationType.mythical;
      case 'SSS':
        return CelebrationType.transcendent;
      default:
        return CelebrationType.basic;
    }
  }
}

/// Data class for hunter rank information
class HunterRankData {
  final String rank;
  final String name;
  final int minLevel;
  final int maxLevel;
  final Color color;
  final Color lightColor;
  final String description;
  final double statBonus;
  final double expBonus;
  final bool hasGlowEffect;
  final bool hasPulseEffect;
  final bool hasRainbowEffect;

  const HunterRankData({
    required this.rank,
    required this.name,
    required this.minLevel,
    required this.maxLevel,
    required this.color,
    required this.lightColor,
    required this.description,
    required this.statBonus,
    required this.expBonus,
    this.hasGlowEffect = false,
    this.hasPulseEffect = false,
    this.hasRainbowEffect = false,
  });

  /// Check if this rank is higher than another rank
  bool isHigherThan(HunterRankData other) {
    const rankOrder = ['E', 'D', 'C', 'B', 'A', 'S', 'SS', 'SSS'];
    return rankOrder.indexOf(rank) > rankOrder.indexOf(other.rank);
  }

  /// Get formatted level range string
  String get levelRange {
    if (maxLevel >= 999999) {
      return '${minLevel}+';
    }
    return '$minLevel-$maxLevel';
  }

  @override
  String toString() => '$rank-Rank ($levelRange)';
}

/// Rank up celebration data
class RankUpCelebration {
  final HunterRankData oldRank;
  final HunterRankData newRank;
  final String message;
  final CelebrationType celebrationType;

  const RankUpCelebration({
    required this.oldRank,
    required this.newRank,
    required this.message,
    required this.celebrationType,
  });
}

/// Types of celebration effects for rank ups
enum CelebrationType {
  basic,      // Simple glow effect
  enhanced,   // Glow + particles
  elite,      // Enhanced effects + screen shake
  legendary,  // Golden effects + audio
  mythical,   // Silver effects + intense visuals
  transcendent, // Rainbow effects + reality distortion
}