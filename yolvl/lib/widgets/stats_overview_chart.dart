import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/user_provider.dart';
import '../models/enums.dart';

/// Widget displaying user stats as a bar chart
class StatsOverviewChart extends StatelessWidget {
  const StatsOverviewChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final stats = userProvider.stats;
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                'Stats Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Bar Chart
              SizedBox(
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
                                  statType.icon,
                                  style: const TextStyle(fontSize: 16),
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
                          showTitles: true,
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
                      show: true,
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
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 1,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    barGroups: _createBarGroups(stats, context),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Legend
              Wrap(
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
                        '${statType.displayName}: ${value.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Create bar groups for the chart
  List<BarChartGroupData> _createBarGroups(Map<StatType, double> stats, BuildContext context) {
    return StatType.values.asMap().entries.map((entry) {
      final index = entry.key;
      final statType = entry.value;
      final value = stats[statType] ?? 1.0;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value,
            color: _getStatColor(statType, context),
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
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