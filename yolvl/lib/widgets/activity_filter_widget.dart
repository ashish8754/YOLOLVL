import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../screens/activity_history_screen.dart';

/// Widget for filtering activity history
class ActivityFilterWidget extends StatelessWidget {
  final ActivityType? selectedActivityType;
  final DateRange selectedDateRange;
  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<ActivityType?> onActivityTypeChanged;
  final ValueChanged<DateRange> onDateRangeChanged;
  final Function(DateTime?, DateTime?) onCustomDateRangeChanged;
  final VoidCallback onClearFilters;

  const ActivityFilterWidget({
    super.key,
    required this.selectedActivityType,
    required this.selectedDateRange,
    required this.startDate,
    required this.endDate,
    required this.onActivityTypeChanged,
    required this.onDateRangeChanged,
    required this.onCustomDateRangeChanged,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: onClearFilters,
                child: const Text('Clear All'),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Activity Type Filter
          Text(
            'Activity Type',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ActivityType?>(
                value: selectedActivityType,
                hint: const Text('All Activities'),
                isExpanded: true,
                items: [
                  const DropdownMenuItem<ActivityType?>(
                    value: null,
                    child: Text('All Activities'),
                  ),
                  ...ActivityType.values.map((type) => DropdownMenuItem<ActivityType?>(
                    value: type,
                    child: Row(
                      children: [
                        Icon(
                          type.icon,
                          size: 20,
                          color: type.color,
                        ),
                        const SizedBox(width: 8),
                        Text(type.displayName),
                      ],
                    ),
                  )),
                ],
                onChanged: onActivityTypeChanged,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Date Range Filter
          Text(
            'Date Range',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: DateRange.values.map((range) {
              final isSelected = selectedDateRange == range;
              return FilterChip(
                label: Text(range.displayName),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    if (range == DateRange.custom) {
                      _showCustomDatePicker(context);
                    } else {
                      onDateRangeChanged(range);
                    }
                  }
                },
                selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                checkmarkColor: Theme.of(context).colorScheme.primary,
              );
            }).toList(),
          ),
          
          // Custom date range display
          if (selectedDateRange == DateRange.custom && (startDate != null || endDate != null))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.date_range,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formatCustomDateRange(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 16),
                      onPressed: () => _showCustomDatePicker(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showCustomDatePicker(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onCustomDateRangeChanged(picked.start, picked.end);
    }
  }

  String _formatCustomDateRange() {
    if (startDate == null && endDate == null) {
      return 'No date range selected';
    }
    
    final startStr = startDate != null 
        ? '${startDate!.day}/${startDate!.month}/${startDate!.year}'
        : 'Start';
    final endStr = endDate != null 
        ? '${endDate!.day}/${endDate!.month}/${endDate!.year}'
        : 'End';
    
    return '$startStr - $endStr';
  }
}