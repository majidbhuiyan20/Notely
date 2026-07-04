import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The day the user is currently viewing in the calendar. Defaults to
/// today. Mutated by the month grid and the day-task list.
class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void select(DateTime d) => state = DateTime(d.year, d.month, d.day);
  void clearToToday() {
    final now = DateTime.now();
    state = DateTime(now.year, now.month, now.day);
  }
}

final selectedDateProvider =
    NotifierProvider<SelectedDateNotifier, DateTime>(SelectedDateNotifier.new);

/// The month currently visible in the month grid header. Defaults to the
/// current month. Independent of [selectedDateProvider] so navigating to
/// a different month doesn't move the selection.
class VisibleMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final s = ref.watch(selectedDateProvider);
    return DateTime(s.year, s.month, 1);
  }

  void setMonth(int year, int month) =>
      state = DateTime(year, month, 1);
}

final visibleMonthProvider =
    NotifierProvider<VisibleMonthNotifier, DateTime>(VisibleMonthNotifier.new);