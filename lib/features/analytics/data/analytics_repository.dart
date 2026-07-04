import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../task/model/note_data.dart';

/// The time range the analytics screen is currently zoomed into.
enum AnalyticsRange { day, week, month, year }

extension AnalyticsRangeLabel on AnalyticsRange {
  String get label => switch (this) {
        AnalyticsRange.day => 'Day',
        AnalyticsRange.week => 'Week',
        AnalyticsRange.month => 'Month',
        AnalyticsRange.year => 'Year',
      };
}

/// One bucket on the primary chart. [label] is the X-axis label,
/// [completed] / [total] drive the bar height (or the line point).
class TaskBucket {
  const TaskBucket({
    required this.label,
    required this.completed,
    required this.total,
  });

  final String label;
  final int completed;
  final int total;
}

/// One slice in the category pie chart.
class CategorySlice {
  const CategorySlice({
    required this.name,
    required this.count,
    required this.color,
  });

  final String name;
  final int count;
  final Color color;
}

/// Top-level summary numbers for the KPI strip.
class AnalyticsSummary {
  const AnalyticsSummary({
    required this.total,
    required this.completed,
    required this.rate,
  });

  final int total;
  final int completed;
  final double rate; // 0..1
}

/// Pure functions that derive analytics from a list of notes. No I/O,
/// no providers — callers (Riverpod providers, widgets in tests, etc.)
/// pass the data in. This keeps the analytics layer testable and free
/// of Firestore / sqflite coupling.
class AnalyticsRepository {
  const AnalyticsRepository();

  /// Builds the bar/line series for the primary chart, depending on the
  /// [range]. The bucketing is:
  ///
  /// * day   — 24 hourly buckets for [now]'s date.
  /// * week  — 7 daily buckets for the week ending [now].
  /// * month — 4 weekly buckets for the month ending [now].
  /// * year  — 12 monthly buckets for the year ending [now].
  List<TaskBucket> tasksForRange(
    List<NoteData> notes,
    AnalyticsRange range,
    DateTime now,
  ) {
    switch (range) {
      case AnalyticsRange.day:
        return _hourly(notes, now);
      case AnalyticsRange.week:
        return _dailyWeek(notes, now);
      case AnalyticsRange.month:
        return _weeklyMonth(notes, now);
      case AnalyticsRange.year:
        return _monthlyYear(notes, now);
    }
  }

  /// Per-category counts (for the pie chart). Sorted desc by count.
  List<CategorySlice> categoryCounts(List<NoteData> notes) {
    final counts = <String, int>{};
    final colors = <String, Color>{};
    for (final n in notes) {
      counts[n.category] = (counts[n.category] ?? 0) + 1;
      colors[n.category] = n.categoryColor;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [
      for (final e in entries)
        CategorySlice(name: e.key, count: e.value, color: colors[e.key]!),
    ];
  }

  /// Overall summary: total / completed / completion rate.
  AnalyticsSummary summary(List<NoteData> notes) {
    final total = notes.length;
    final completed =
        notes.where((n) => n.status == NoteStatus.completed).length;
    final rate = total == 0 ? 0.0 : completed / total;
    return AnalyticsSummary(
      total: total,
      completed: completed,
      rate: rate,
    );
  }

  // --- internal bucketing ---------------------------------------------

  /// 24 hourly buckets for [now]'s calendar day. Uses the local time
  /// and falls back to 0 for any hour the user has no notes for.
  List<TaskBucket> _hourly(List<NoteData> notes, DateTime now) {
    final byHour = List<int>.filled(24, 0);
    final completedByHour = List<int>.filled(24, 0);

    for (final n in notes) {
      // We can't know the created-at hour from NoteData alone, so we
      // approximate by bucketing each note into the hour encoded by
      // its `dueDate` string when it parses. When the note is overdue
      // (dueDateIso < dayStart) we still attribute it to "today" so
      // the bar shows real user data on the day screen.
      final iso = n.dueDateIso;
      if (iso == null) continue;
      final dt = DateTime.tryParse(iso);
      if (dt == null) continue;
      if (dt.year != now.year ||
          dt.month != now.month ||
          dt.day != now.day) {
        continue;
      }
      final h = math.min(23, math.max(0, dt.hour));
      byHour[h]++;
      if (n.status == NoteStatus.completed) completedByHour[h]++;
    }

    return [
      for (int h = 0; h < 24; h++)
        TaskBucket(
          label: h.toString().padLeft(2, '0'),
          completed: completedByHour[h],
          total: byHour[h],
        ),
    ];
  }

  /// 7 daily buckets for the rolling week ending [now].
  List<TaskBucket> _dailyWeek(List<NoteData> notes, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final results = <TaskBucket>[];

    // Walk back to Monday of this week (DateTime.weekday: Mon=1..Sun=7).
    final monday = today.subtract(Duration(days: today.weekday - 1));
    for (int i = 0; i < 7; i++) {
      final d = monday.add(Duration(days: i));
      final iso = _isoDate(d);
      var total = 0;
      var completed = 0;
      for (final n in notes) {
        if (n.dueDateIso == iso) {
          total++;
          if (n.status == NoteStatus.completed) completed++;
        }
      }
      results.add(TaskBucket(label: dayLabels[i], completed: completed, total: total));
    }
    return results;
  }

  /// 4 weekly buckets for the rolling month ending [now].
  List<TaskBucket> _weeklyMonth(List<NoteData> notes, DateTime now) {
    final results = <TaskBucket>[];
    final endOfWeek = DateTime(now.year, now.month, now.day);
    // Walk back to start of this week and group into 4 week-long buckets.
    final thisWeekStart =
        endOfWeek.subtract(Duration(days: endOfWeek.weekday - 1));
    for (int w = 3; w >= 0; w--) {
      final weekStart = thisWeekStart.subtract(Duration(days: w * 7));
      final weekEnd = weekStart.add(const Duration(days: 7));
      var total = 0;
      var completed = 0;
      for (final n in notes) {
        final iso = n.dueDateIso;
        if (iso == null) continue;
        final dt = DateTime.tryParse(iso);
        if (dt == null) continue;
        if (!dt.isBefore(weekStart) && dt.isBefore(weekEnd)) {
          total++;
          if (n.status == NoteStatus.completed) completed++;
        }
      }
      results.add(
        TaskBucket(
          label: 'W${4 - w}',
          completed: completed,
          total: total,
        ),
      );
    }
    return results;
  }

  /// 12 monthly buckets for the rolling year ending [now].
  List<TaskBucket> _monthlyYear(List<NoteData> notes, DateTime now) {
    const monthLabels = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final results = <TaskBucket>[];
    // Build a window of 12 months ending with [now]'s month.
    for (int i = 11; i >= 0; i--) {
      final totalMonths = now.year * 12 + (now.month - 1) - i;
      final realYear = totalMonths ~/ 12;
      final realMonth = (totalMonths % 12) + 1;
      var total = 0;
      var completed = 0;
      for (final n in notes) {
        final iso = n.dueDateIso;
        if (iso == null) continue;
        final dt = DateTime.tryParse(iso);
        if (dt == null) continue;
        if (dt.year == realYear && dt.month == realMonth) {
          total++;
          if (n.status == NoteStatus.completed) completed++;
        }
      }
      results.add(
        TaskBucket(
          label: monthLabels[realMonth - 1],
          completed: completed,
          total: total,
        ),
      );
    }
    return results;
  }

  String _isoDate(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }
}