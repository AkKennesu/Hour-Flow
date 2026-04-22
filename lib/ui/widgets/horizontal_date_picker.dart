import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HorizontalDatePicker extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const HorizontalDatePicker({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Generate dates for the current week (Sun to Sat) based on selected date
    final int currentWeekday = selectedDate.weekday == 7 ? 0 : selectedDate.weekday;
    final DateTime startOfWeek = selectedDate.subtract(Duration(days: currentWeekday));
    
    final List<DateTime> weekDates = List.generate(7, (index) {
      return startOfWeek.add(Duration(days: index));
    });

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 7,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final date = weekDates[index];
          final bool isSelected = date.year == selectedDate.year &&
              date.month == selectedDate.month &&
              date.day == selectedDate.day;

          return _DateTile(
            date: date,
            isSelected: isSelected,
            onTap: () => onDateSelected(date),
          );
        },
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final VoidCallback onTap;

  const _DateTile({
    required this.date,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String dayName = DateFormat('EEE').format(date);
    final String dayNumber = DateFormat('d').format(date);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected 
              ? theme.colorScheme.primary 
              : theme.colorScheme.surfaceContainerHigh,
          border: isSelected 
              ? null 
              : Border.all(color: theme.colorScheme.outlineVariant, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayName.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dayNumber,
              style: theme.textTheme.titleMedium?.copyWith(
                color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
