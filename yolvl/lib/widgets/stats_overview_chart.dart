import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/user_provider.dart';
import '../models/enums.dart';
import '../screens/stats_progression_screen.dart';
import '../utils/accessibility_helper.dart';
import '../utils/page_transitions.dart';

/// Widget displaying user stats as a bar chart with swipe gestures
class StatsOverviewChart extends StatefulWidget {
  const StatsOverviewChart({super.key});

  @override
  State<StatsOverviewChart> createState() => _StatsOverviewChartState();
}

class _StatsOverviewChartState extends State<StatsOverviewChart>
    with TickerProviderStateMixin {
  late AnimationController _chartAnimationController;
  late Animation<double> _chartAnimation;
  bool _showDetailed = false;

  @override
  void initState() {
    super.initState();
    _chartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _chartAnimation = CurvedAnimation(
      parent: _chartAnimationController,
      curve: Curves.easeInOutCubic,
    );
    _chartAnimationController.forward();
  }

  @override
  void dispose() {
    _chartAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final stats = userProvider.stats;
        
        return Semantics(
          label: 'Stats overview chart. ${_getStatsSemanticDescription(stats)}',
          button: true,
          hint: 'Tap to toggle detailed view, or swipe left and right to change view',
          onTap: () {
            setState(() {
              _showDetailed = !_showDetailed;
            });
            _chartAnimationController.reset();
            _chartAnimationController.forward();
            AccessibilityHelper.announceToScreenReader(
              context, 
              _showDetailed ? 'Showing detailed stats view' : 'Showing simplified stats view'
            );
          },
          child: GestureDetector(
            onTap: () {
              setState(() {
                _showDetailed = !_showDetailed;
              });
              _chartAnimationController.reset();
              _chartAnimationController.forward();
              AccessibilityHelper.announceToScreenReader(
                context, 
                _showDetailed ? 'Showing detailed stats view' : 'Showing simplified stats view'
              );
            },
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity != null) {
                if (details.primaryVelocity! > 0) {
                  // Swipe right - show simplified view
                  setState(() {
                    _showDetailed = false;
                  });
                  AccessibilityHelper.announceToScreenReader(context, 'Showing simplified stats view');
                } else {
                  // Swipe left - show detailed view
                  setState(() {
                    _showDetailed = true;
                  });
                  AccessibilityHelper.announceToScreenReader(context, 'Showing detailed stats view');
                }
                _chartAnimationController.reset();
                _chartAnimationController.forward();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: _showDetailed ? [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title with navigation button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Stats Overview',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            _showDetailed ? Icons.visibility : Icons.visibility_off,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Tap or swipe',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(width: 8),
                          AccessibilityHelper.createAccessibleButton(
                            onPressed: () {
                              Navigator.of(context).pushSlideFade(
                                const StatsProgressionScreen(),
                                direction: AxisDirection.left,
                              );
                            },
                            semanticLabel: 'View detailed stats progression',
                            tooltip: 'Open detailed stats progression screen',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.show_chart, 
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Details',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Animated Bar Chart
                  AnimatedBuilder(
                    animation: _chartAnimation,
                    builder: (context, child) {
                      return SizedBox(
                        height: 200,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: _getMaxStatValue(stats) + 1,
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                tooltipBgColor: Theme.of(context).colorScheme.surfaceContainer,
                                tooltipBorder: BorderSide(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                                ),
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  final statType = StatType.values[group.x.toInt()];
                                  return BarTooltipItem(
                                    '${statType.displayName}\n${rod.toY.toStringAsFixed(2)}',
                                    TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  );
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    if (value.toInt() >= 0 && value.toInt() < StatType.values.length) {
                                      final statType = StatType.values[value.toInt()];
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          _showDetailed ? statType.displayName.substring(0, 3) : statType.icon,
                                          style: TextStyle(
                                            fontSize: _showDetailed ? 10 : 16,
                                            fontWeight: _showDetailed ? FontWeight.w500 : FontWeight.normal,
                                          ),
                                        ),
                                      );
                                    }
                                    return const Text('');
                                  },
                                  reservedSize: 32,
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: _showDetailed,
                                  reservedSize: 40,
                                  interval: 1,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      value.toStringAsFixed(0),
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                        fontSize: 12,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(
                              show: _showDetailed,
                              border: Border(
                                bottom: BorderSide(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                                ),
                                left: BorderSide(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                                ),
                              ),
                            ),
                            gridData: FlGridData(
                              show: _showDetailed,
                              drawVerticalLine: false,
                              horizontalInterval: 1,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                                  strokeWidth: 1,
                                );
                              },
                            ),
                            barGroups: _createBarGroups(stats, context, _chartAnimation.value),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Legend with animation
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 300),
                    crossFadeState: _showDetailed ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    firstChild: Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: StatType.values.map((statType) {
                        final value = stats[statType] ?? 1.0;
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _getStatColor(statType, context),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${statType.icon} ${value.toStringAsFixed(1)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                    secondChild: Column(
                      children: StatType.values.map((statType) {
                        final value = stats[statType] ?? 1.0;
                        return Semantics(
                          label: AccessibilityHelper.getStatSemanticLabel(statType.displayName, value),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Container(
                              constraints: const BoxConstraints(
                                minHeight: AccessibilityHelper.minTouchTargetSize,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: _getStatColor(statType, context),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Center(
                                      child: Text(
                                        statType.icon,
                                        style: const TextStyle(fontSize: 10, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      statType.displayName,
                                      style: AccessibilityHelper.getAccessibleTextStyle(
                                        context,
                                        TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    value.toStringAsFixed(2),
                                    style: AccessibilityHelper.getAccessibleTextStyle(
                                      context,
                                      TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: _getStatColor(statType, context),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Get semantic description of all stats for screen readers
  String _getStatsSemanticDescription(Map<StatType, double> stats) {
    final descriptions = StatType.values.map((statType) {
      final value = stats[statType] ?? 1.0;
      return '${statType.displayName}: ${value.toStringAsFixed(2)}';
    }).join(', ');
    return descriptions;
  }

  /// Create bar groups for the chart with animation
  List<BarChartGroupData> _createBarGroups(Map<StatType, double> stats, BuildContext context, double animationValue) {
    return StatType.values.asMap().entries.map((entry) {
      final index = entry.key;
      final statType = entry.value;
      final value = stats[statType] ?? 1.0;
      final animatedValue = value * animationValue;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: animatedValue,
            color: _getStatColor(statType, context),
            width: _showDetailed ? 16 : 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
            backDrawRodData: BackgroundBarChartRodData(
              show: _showDetailed,
              toY: _getMaxStatValue(stats) + 1,
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
            ),
          ),
        ],
      );
    }).toList();
  }

  /// Get color for each stat type
  Color _getStatColor(StatType statType, BuildContext context) {
    switch (statType) {
      case StatType.strength:
        return const Color(0xFFE74C3C); // Red
      case StatType.agility:
        return const Color(0xFF3498DB); // Blue
      case StatType.endurance:
        return const Color(0xFF2ECC71); // Green
      case StatType.intelligence:
        return const Color(0xFF9B59B6); // Purple
      case StatType.focus:
        return const Color(0xFFF39C12); // Orange
      case StatType.charisma:
        return const Color(0xFF1ABC9C); // Teal
    }
  }

  /// Get maximum stat value for chart scaling
  double _getMaxStatValue(Map<StatType, double> stats) {
    if (stats.isEmpty) return 5.0;
    
    final maxValue = stats.values.reduce((a, b) => a > b ? a : b);
    // Round up to next integer and add some padding
    return (maxValue + 1).ceilToDouble();
  }
}