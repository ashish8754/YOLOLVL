import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/activity_log.dart';
import '../models/enums.dart';
import '../screens/stats_progression_screen.dart';

/// Widget for displaying stat progression over time as a line chart
class StatsProgressionChart extends StatefulWidget {
  final StatType statType;
  final TimeRange timeRange;
  final List<ActivityLog> activities;
  final double currentStatValue;

  const StatsProgressionChart({
    super.key,
    required this.statType,
    required this.timeRange,
    required this.activities,
    required this.currentStatValue,
  });

  @override
  State<StatsProgressionChart> createState() => _StatsProgressionChartState();
}

class _StatsProgressionChartState extends State<StatsProgressionChart> {
  List<FlSpot> _chartData = [];
  double _minY = 0;
  double _maxY = 5;
  List<DateTime> _dataPoints = [];

  @override
  void initState() {
    super.initState();
    _calculateChartData();
  }

  @override
  void didUpdateWidget(StatsProgressionChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.statType != widget.statType ||
        oldWidget.timeRange != widget.timeRange ||
        oldWidget.activities != widget.activities) {
      _calculateChartData();
    }
  }

  void _calculateChartData() {
    final relevantActivities = widget.activities
        .where((activity) => activity.statGainsMap.containsKey(widget.statType))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (relevantActivities.isEmpty) {
      _chartData = [];
      _dataPoints = [];
      _minY = 1.0;
      _maxY = widget.currentStatValue + 1;
      return;
    }

    // Calculate cumulative stat progression
    final Map<DateTime, double> dailyGains = {};

    // Group activities by day and sum gains
    for (final activity in relevantActivities) {
      final date = DateTime(
        activity.timestamp.year,
        activity.timestamp.month,
        activity.timestamp.day,
      );
      
      final gain = activity.statGainsMap[widget.statType] ?? 0;
      dailyGains[date] = (dailyGains[date] ?? 0) + gain;
    }

    // Create data points for chart
    final sortedDates = dailyGains.keys.toList()..sort();
    _dataPoints = [];
    _chartData = [];

    // Start with base stat value (assuming 1.0 as starting point)
    double baseStatValue = 1.0;
    
    // Calculate what the base should be by working backwards from current value
    final totalGains = dailyGains.values.fold(0.0, (sum, gain) => sum + gain);
    baseStatValue = widget.currentStatValue - totalGains;
    if (baseStatValue < 1.0) baseStatValue = 1.0;

    double currentValue = baseStatValue;
    
    for (int i = 0; i < sortedDates.length; i++) {
      final date = sortedDates[i];
      final gain = dailyGains[date] ?? 0;
      currentValue += gain;
      
      _dataPoints.add(date);
      _chartData.add(FlSpot(i.toDouble(), currentValue));
    }

    // Add current value as the latest point if we have data
    if (_chartData.isNotEmpty) {
      _dataPoints.add(DateTime.now());
      _chartData.add(FlSpot(_chartData.length.toDouble(), widget.currentStatValue));
    }

    // Calculate Y-axis bounds
    if (_chartData.isNotEmpty) {
      final values = _chartData.map((spot) => spot.y).toList();
      _minY = values.reduce((a, b) => a < b ? a : b) - 0.5;
      _maxY = values.reduce((a, b) => a > b ? a : b) + 0.5;
      
      // Ensure minimum range
      if (_maxY - _minY < 1.0) {
        _maxY = _minY + 1.0;
      }
    } else {
      _minY = 1.0;
      _maxY = widget.currentStatValue + 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.statType.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                widget.statType.icon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.statType.displayName} Progression',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Current: ${widget.currentStatValue.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: widget.statType.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Chart
          SizedBox(
            height: 200,
            child: _chartData.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.show_chart,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No ${widget.statType.displayName.toLowerCase()} activities found',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: (_maxY - _minY) / 5,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                            strokeWidth: 1,
                          );
                        },
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
                            reservedSize: 30,
                            interval: _getBottomTitleInterval(),
                            getTitlesWidget: (value, meta) {
                              return _buildBottomTitle(value.toInt());
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            interval: (_maxY - _minY) / 5,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toStringAsFixed(1),
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
                      minX: 0,
                      maxX: _chartData.isNotEmpty ? (_chartData.length - 1).toDouble() : 1,
                      minY: _minY,
                      maxY: _maxY,
                      lineBarsData: [
                        LineChartBarData(
                          spots: _chartData,
                          isCurved: true,
                          color: widget.statType.color,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: widget.statType.color,
                                strokeWidth: 2,
                                strokeColor: Theme.of(context).colorScheme.surface,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: widget.statType.color.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        enabled: true,
                        touchTooltipData: LineTouchTooltipData(
                          tooltipBgColor: Theme.of(context).colorScheme.surfaceContainer,
                          tooltipBorder: BorderSide(
                            color: widget.statType.color.withValues(alpha: 0.5),
                          ),
                          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                            return touchedBarSpots.map((barSpot) {
                              final index = barSpot.x.toInt();
                              if (index >= 0 && index < _dataPoints.length) {
                                final date = _dataPoints[index];
                                final value = barSpot.y;
                                
                                return LineTooltipItem(
                                  '${_formatDate(date)}\n${widget.statType.displayName}: ${value.toStringAsFixed(2)}',
                                  TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                );
                              }
                              return null;
                            }).toList();
                          },
                        ),
                        handleBuiltInTouches: true,
                      ),
                    ),
                  ),
          ),
          
          // Stats summary
          if (_chartData.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatSummary(
                  'Total Gain',
                  '+${(widget.currentStatValue - _chartData.first.y).toStringAsFixed(2)}',
                  Icons.trending_up,
                ),
                _buildStatSummary(
                  'Data Points',
                  '${_chartData.length}',
                  Icons.scatter_plot,
                ),
                _buildStatSummary(
                  'Avg/Day',
                  '+${_calculateAverageGainPerDay().toStringAsFixed(3)}',
                  Icons.speed,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatSummary(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: widget.statType.color,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  double _getBottomTitleInterval() {
    if (_chartData.length <= 7) return 1;
    if (_chartData.length <= 14) return 2;
    if (_chartData.length <= 30) return 5;
    return (_chartData.length / 6).ceilToDouble();
  }

  Widget _buildBottomTitle(int index) {
    if (index >= 0 && index < _dataPoints.length) {
      final date = _dataPoints[index];
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          _formatDateShort(date),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            fontSize: 10,
          ),
        ),
      );
    }
    return const Text('');
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _formatDateShort(DateTime date) {
    if (widget.timeRange == TimeRange.last7Days) {
      final weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      return weekdays[date.weekday % 7];
    } else {
      return '${date.month}/${date.day}';
    }
  }

  double _calculateAverageGainPerDay() {
    if (_chartData.length < 2 || _dataPoints.isEmpty) return 0;
    
    final totalGain = widget.currentStatValue - _chartData.first.y;
    final daysDifference = _dataPoints.last.difference(_dataPoints.first).inDays;
    
    if (daysDifference <= 0) return totalGain;
    return totalGain / daysDifference;
  }
}