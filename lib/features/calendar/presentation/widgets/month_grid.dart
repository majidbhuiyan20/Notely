import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/calendar_repository.dart';
import '../providers/calendar_providers.dart';

/// Renders a single month as a 7×6 grid. Each tap selects the day,
/// persists it through [selectedDateProvider], and triggers a re-render of
/// the day-task list via [CalendarRepository].notesOnDate.
class MonthGrid extends ConsumerWidget {
  const MonthGrid({super.key});

  static const List<String> _weekdayLabels = [
    'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(visibleMonthProvider);
    final selected = ref.watch(selectedDateProvider);
    final today = _truncate(DateTime.now());
    final counts = ref.watch(calendarRepositoryProvider).countsByDate();

    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingBlanks = first.weekday % 7; // Sun=0 … Sat=6

    final cells = <Widget>[];

    for (final l in _weekdayLabels) {
      cells.add(_Header(label: l));
    }

    for (var i = 0; i < leadingBlanks; i++) {
      cells.add(const SizedBox.shrink());
    }

    for (var d = 1; d <= daysInMonth; d++) {
      final date = DateTime(month.year, month.month, d);
      final iso = _iso(date);
      cells.add(_DayCell(
        date: date,
        iso: iso,
        count: counts[iso] ?? 0,
        isToday: date == today,
        isSelected: date == selected,
        onTap: () {
          ref.read(selectedDateProvider.notifier).select(date);
        },
      ));
    }

    while (cells.length < 7 + 42) {
      cells.add(const SizedBox.shrink());
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          GridView.count(
            crossAxisCount: 7,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            childAspectRatio: 1.0,
            children: cells,
          ),
        ],
      ),
    );
  }

  DateTime _truncate(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
  String _iso(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.iso,
    required this.count,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  final DateTime date;
  final String iso;
  final int count;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = isSelected
        ? const Color(0xFF4169E1)
        : (isToday ? const Color(0xFF7B91FF) : Colors.transparent);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isToday && !isSelected
                ? Border.all(color: accent, width: 1.2)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      isSelected || isToday ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : const Color(0xFF1E1E1E),
                ),
              ),
              const SizedBox(height: 2),
              if (count > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(count.clamp(1, 3), (i) {
                    return Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF4169E1),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                )
              else
                const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

/// Convenience: same as [NoteData.dueDateIso] formatter.
String isoDate(DateTime d) {
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${d.year}-$m-$day';
}