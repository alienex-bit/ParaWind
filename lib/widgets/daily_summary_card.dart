import 'package:flutter/material.dart';

class DailySummaryCard extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;

  const DailySummaryCard({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedDateTextColor = isDark
        ? Colors.white
        : Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            // Day Selector
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: List.generate(5, (i) {
                  final date = now.add(Duration(days: i));
                  final isSelected =
                      date.year == selectedDate.year &&
                      date.month == selectedDate.month &&
                      date.day == selectedDate.day;
                  final weekdays = [
                    'Mon',
                    'Tue',
                    'Wed',
                    'Thu',
                    'Fri',
                    'Sat',
                    'Sun',
                  ];
                  String dayName = '';
                  if (i == 0) {
                    dayName = 'TODAY';
                  } else if (i == 1) {
                    dayName = 'TOMORR';
                  } else {
                    dayName = weekdays[date.weekday - 1].toUpperCase();
                  }
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: () => onDateSelected(date),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          height: 52,
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.blueAccent.withValues(alpha: 0.2)
                                : Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blueAccent
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                dayName,
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  color: isSelected
                                      ? Colors.blueAccent
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                date.day.toString(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: isSelected
                                      ? selectedDateTextColor
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
