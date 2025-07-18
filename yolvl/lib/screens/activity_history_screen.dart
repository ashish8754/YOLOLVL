import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/activity_provider.dart';
import '../models/activity_log.dart';
import '../models/enums.dart';
import '../widgets/activity_history_list.dart';
import '../widgets/activity_filter_widget.dart';

/// Screen for viewing activity history with filtering and pagination
class ActivityHistoryScreen extends StatefulWidget {
  const ActivityHistoryScreen({super.key});

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> {
  // Filter state
  ActivityType? _selectedActivityType;
  DateTime? _startDate;
  DateTime? _endDate;
  DateRange _selectedDateRange = DateRange.all;
  
  // Pagination state
  int _currentPage = 0;
  final int _pageSize = 20;
  bool _hasMoreData = true;
  
  // UI state
  bool _showFilters = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final activityProvider = context.read<ActivityProvider>();
    await activityProvider.loadActivityHistory(
      startDate: _startDate,
      endDate: _endDate,
      activityType: _selectedActivityType,
      page: 0,
      pageSize: _pageSize,
    );
    _currentPage = 0;
    _hasMoreData = activityProvider.activityHistory.length >= _pageSize;
  }

  Future<void> _loadMoreData() async {
    if (!_hasMoreData) return;
    
    final activityProvider = context.read<ActivityProvider>();
    final nextPage = _currentPage + 1;
    
    await activityProvider.loadActivityHistory(
      startDate: _startDate,
      endDate: _endDate,
      activityType: _selectedActivityType,
      page: nextPage,
      pageSize: _pageSize,
    );
    
    _currentPage = nextPage;
    _hasMoreData = activityProvider.activityHistory.length >= (nextPage + 1) * _pageSize;
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Activity History'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter section
          if (_showFilters)
            ActivityFilterWidget(
              selectedActivityType: _selectedActivityType,
              selectedDateRange: _selectedDateRange,
              startDate: _startDate,
              endDate: _endDate,
              onActivityTypeChanged: _onActivityTypeChanged,
              onDateRangeChanged: _onDateRangeChanged,
              onCustomDateRangeChanged: _onCustomDateRangeChanged,
              onClearFilters: _onClearFilters,
            ),
          
          // Activity list
          Expanded(
            child: Consumer<ActivityProvider>(
              builder: (context, activityProvider, child) {
                if (activityProvider.isLoading && _currentPage == 0) {
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
                          'Error loading activities',
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
                          onPressed: _loadInitialData,
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
                          Icons.history,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No activities found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _hasActiveFilters() 
                              ? 'Try adjusting your filters'
                              : 'Start logging activities to see them here',
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
                  onRefresh: _loadInitialData,
                  child: ActivityHistoryList(
                    activities: activityProvider.activityHistory,
                    scrollController: _scrollController,
                    isLoadingMore: activityProvider.isLoading && _currentPage > 0,
                    hasMoreData: _hasMoreData,
                    onDeleteActivity: _onDeleteActivity,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _onActivityTypeChanged(ActivityType? activityType) {
    setState(() {
      _selectedActivityType = activityType;
    });
    _loadInitialData();
  }

  void _onDateRangeChanged(DateRange dateRange) {
    setState(() {
      _selectedDateRange = dateRange;
      _setDateRangeFromEnum(dateRange);
    });
    _loadInitialData();
  }

  void _onCustomDateRangeChanged(DateTime? startDate, DateTime? endDate) {
    setState(() {
      _startDate = startDate;
      _endDate = endDate;
      _selectedDateRange = DateRange.custom;
    });
    _loadInitialData();
  }

  void _onClearFilters() {
    setState(() {
      _selectedActivityType = null;
      _startDate = null;
      _endDate = null;
      _selectedDateRange = DateRange.all;
    });
    _loadInitialData();
  }

  Future<void> _onDeleteActivity(String activityId) async {
    final confirmed = await _showDeleteConfirmation();
    if (confirmed == true) {
      final activityProvider = context.read<ActivityProvider>();
      final success = await activityProvider.deleteActivity(activityId);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activity deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(activityProvider.errorMessage ?? 'Failed to delete activity'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<bool?> _showDeleteConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Activity'),
        content: const Text('Are you sure you want to delete this activity? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _setDateRangeFromEnum(DateRange dateRange) {
    final now = DateTime.now();
    switch (dateRange) {
      case DateRange.today:
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = _startDate!.add(const Duration(days: 1));
        break;
      case DateRange.thisWeek:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        _startDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        _endDate = null;
        break;
      case DateRange.thisMonth:
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = null;
        break;
      case DateRange.last30Days:
        _startDate = now.subtract(const Duration(days: 30));
        _endDate = null;
        break;
      case DateRange.all:
        _startDate = null;
        _endDate = null;
        break;
      case DateRange.custom:
        // Keep existing custom dates
        break;
    }
  }

  bool _hasActiveFilters() {
    return _selectedActivityType != null || 
           _startDate != null || 
           _endDate != null ||
           _selectedDateRange != DateRange.all;
  }
}

/// Enum for predefined date ranges
enum DateRange {
  all,
  today,
  thisWeek,
  thisMonth,
  last30Days,
  custom,
}

extension DateRangeExtension on DateRange {
  String get displayName {
    switch (this) {
      case DateRange.all:
        return 'All Time';
      case DateRange.today:
        return 'Today';
      case DateRange.thisWeek:
        return 'This Week';
      case DateRange.thisMonth:
        return 'This Month';
      case DateRange.last30Days:
        return 'Last 30 Days';
      case DateRange.custom:
        return 'Custom Range';
    }
  }
}