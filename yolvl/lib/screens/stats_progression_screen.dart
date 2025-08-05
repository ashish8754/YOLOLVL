import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/activity_provider.dart';
import '../models/enums.dart';
import '../widgets/stats_progression_chart.dart';

/// Screen for viewing detailed stats progression over time
class StatsProgressionScreen extends StatefulWidget {
  const StatsProgressionScreen({super.key});

  @override
  State<StatsProgressionScreen> createState() => _StatsProgressionScreenState();
}

class _StatsProgressionScreenState extends State<StatsProgressionScreen> {
  TimeRange _selectedTimeRange = TimeRange.last7Days;
  StatType? _selectedStat;
  bool _showAllStats = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final activityProvider = context.read<ActivityProvider>();
    final dateRange = _getDateRangeFromTimeRange(_selectedTimeRange);
    
    await activityProvider.loadActivityHistory(
      startDate: dateRange.start,
      endDate: dateRange.end,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Stats Progression'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        elevation: 0,
        actions: [
          PopupMenuButton<StatType?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (StatType? stat) {
              setState(() {
                _selectedStat = stat;
                _showAllStats = stat == null;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem<StatType?>(
                value: null,
                child: Row(
                  children: [
                    Icon(Icons.show_chart),
                    SizedBox(width: 8),
                    Text('All Stats'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              ...StatType.values.map((stat) => PopupMenuItem<StatType?>(
                value: stat,
                child: Row(
                  children: [
                    Icon(stat.icon, size: 16),
                    const SizedBox(width: 8),
                    Text(stat.displayName),
                  ],
                ),
              )),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Time range selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Time Range',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: TimeRange.values.map((range) {
                      final isSelected = _selectedTimeRange == range;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(range.displayName),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedTimeRange = range;
                              });
                              _loadData();
                            }
                          },
                          selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                          checkmarkColor: Theme.of(context).colorScheme.primary,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          // Charts
          Expanded(
            child: Consumer2<UserProvider, ActivityProvider>(
              builder: (context, userProvider, activityProvider, child) {
                if (activityProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (activityProvider.errorMessage != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading data',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          activityProvider.errorMessage!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (activityProvider.activityHistory.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.show_chart,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No data available',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start logging activities to see progression charts',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (_showAllStats) ...[
                          // Show all stats in separate charts
                          ...StatType.values.map((statType) => Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: StatsProgressionChart(
                              statType: statType,
                              timeRange: _selectedTimeRange,
                              activities: activityProvider.activityHistory,
                              currentStatValue: userProvider.stats[statType] ?? 1.0,
                            ),
                          )),
                        ] else if (_selectedStat != null) ...[
                          // Show single selected stat
                          StatsProgressionChart(
                            statType: _selectedStat!,
                            timeRange: _selectedTimeRange,
                            activities: activityProvider.activityHistory,
                            currentStatValue: userProvider.stats[_selectedStat!] ?? 1.0,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  DateTimeRange _getDateRangeFromTimeRange(TimeRange timeRange) {
    final now = DateTime.now();
    
    switch (timeRange) {
      case TimeRange.last7Days:
        return DateTimeRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        );
      case TimeRange.last30Days:
        return DateTimeRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );
      case TimeRange.last3Months:
        return DateTimeRange(
          start: DateTime(now.year, now.month - 3, now.day),
          end: now,
        );
      case TimeRange.last6Months:
        return DateTimeRange(
          start: DateTime(now.year, now.month - 6, now.day),
          end: now,
        );
      case TimeRange.lastYear:
        return DateTimeRange(
          start: DateTime(now.year - 1, now.month, now.day),
          end: now,
        );
      case TimeRange.allTime:
        return DateTimeRange(
          start: DateTime(2020, 1, 1), // Far back date
          end: now,
        );
    }
  }
}

/// Enum for time range selection
enum TimeRange {
  last7Days,
  last30Days,
  last3Months,
  last6Months,
  lastYear,
  allTime,
}

extension TimeRangeExtension on TimeRange {
  String get displayName {
    switch (this) {
      case TimeRange.last7Days:
        return 'Last 7 Days';
      case TimeRange.last30Days:
        return 'Last 30 Days';
      case TimeRange.last3Months:
        return 'Last 3 Months';
      case TimeRange.last6Months:
        return 'Last 6 Months';
      case TimeRange.lastYear:
        return 'Last Year';
      case TimeRange.allTime:
        return 'All Time';
    }
  }
}