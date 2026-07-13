import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../task/model/note_data.dart';

/// The four time windows the profile screen surfaces as stat cards.
///
/// * [today] — tasks whose due date is exactly the user's local today.
/// * [week]  — tasks due between Monday 00:00 and next Monday 00:00
///             (calendar week, not rolling 7-day window — matches what
///             users expect when they say "this week").
/// * [month] — tasks due in the current calendar month.
/// * [total] — every note the user has, regardless of due date.
///
/// Notes without a `dueDateIso` are intentionally excluded from today/
/// week/month and only count in [total]. This matches how every other
/// surface in the app already treats undated notes.
enum StatsPeriod { today, week, month, total }

extension StatsPeriodMeta on StatsPeriod {
  /// Human-readable label shown as the card title.
  String get label => switch (this) {
        StatsPeriod.today => 'Today',
        StatsPeriod.week => 'This Week',
        StatsPeriod.month => 'This Month',
        StatsPeriod.total => 'All Time',
      };

  /// Short sub-label under the big count number.
  String get subLabel => switch (this) {
        StatsPeriod.today => 'tasks due today',
        StatsPeriod.week => 'tasks this week',
        StatsPeriod.month => 'tasks this month',
        StatsPeriod.total => 'tasks in total',
      };

  /// Distinct gradient per card so the eye can tell them apart at a
  /// glance. Re-uses the design tokens already in `AppColors` so the
  /// profile screen matches the rest of the app.
  List<Color> get gradient => switch (this) {
        StatsPeriod.today => const [Color(0xFF7C3AED), Color(0xFF4F46E5)],
        StatsPeriod.week => const [Color(0xFF3B82F6), Color(0xFF06B6D4)],
        StatsPeriod.month => const [Color(0xFFFF9A6C), Color(0xFFFF6B9C)],
        StatsPeriod.total => const [Color(0xFF34D399), Color(0xFF14B8A6)],
      };

  IconData get icon => switch (this) {
        StatsPeriod.today => Icons.wb_sunny_rounded,
        StatsPeriod.week => Icons.calendar_view_week_rounded,
        StatsPeriod.month => Icons.calendar_month_rounded,
        StatsPeriod.total => Icons.all_inclusive_rounded,
      };
}

/// One row of stats for a single period. Reads the parent-supplied
/// [count] / [completed] / [pending] so the same widget can be reused
/// for the 2x2 grid and any future tile.
class StatsPeriodCard extends StatelessWidget {
  const StatsPeriodCard({
    super.key,
    required this.period,
    required this.count,
    required this.completed,
    required this.delayMs,
  });

  final StatsPeriod period;
  final int count;
  final int completed;
  final int delayMs;

  /// Slide-up + fade-in entry. Pure widget animation, no controller.
  Widget _wrap(Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeOutCubic,
      builder: (context, t, c) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 18),
            child: c,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = count - completed;
    final rate = count == 0 ? 0.0 : completed / count;
    final percent = (rate * 100).round();
    final gradient = period.gradient;

    // Stagger the entry by delayMs via Interval so the four cards
    // appear one after another rather than all at once.
    return FutureBuilder<void>(
      future: Future<void>.delayed(Duration(milliseconds: delayMs)),
      builder: (context, snap) {
        return AnimatedOpacity(
          duration: const Duration(milliseconds: 360),
          opacity: snap.connectionState == ConnectionState.done ? 1 : 0,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            offset: snap.connectionState == ConnectionState.done
                ? Offset.zero
                : const Offset(0, 0.18),
            child: _wrap(_build(context, gradient, pending, rate, percent)),
          ),
        );
      },
    );
  }

  Widget _build(
    BuildContext context,
    List<Color> gradient,
    int pending,
    double rate,
    int percent,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppElevation.cardShadow,
        border: Border.all(color: AppColors.divider, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.first.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(period.icon, color: Colors.white, size: 18),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: gradient.first.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '$percent%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: gradient.first,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            period.label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 2),
          _AnimatedCount(
            value: count,
            color: AppColors.textPrimary,
          ),
          const SizedBox(height: 2),
          Text(
            period.subLabel,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: rate.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 6,
                  backgroundColor: AppColors.surfaceAlt,
                  valueColor: AlwaysStoppedAnimation<Color>(gradient.first),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              _MiniMetric(
                dot: gradient.first,
                label: 'Done',
                value: completed.toString(),
              ),
              const SizedBox(width: AppSpacing.sm),
              _MiniMetric(
                dot: AppColors.textTertiary,
                label: 'Pending',
                value: pending.toString(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Animates a number from 0 → [value] on mount. Falls back to a static
/// Text when [value] is 0 so the empty state still renders.
class _AnimatedCount extends StatelessWidget {
  const _AnimatedCount({required this.value, required this.color});
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: value.toDouble()),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        return Text(
          v.round().toString(),
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: -1.0,
            height: 1.0,
          ),
        );
      },
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.dot,
    required this.label,
    required this.value,
  });

  final Color dot;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: dot,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$value $label',
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Pure helpers that bucket notes by [StatsPeriod]. Kept top-level so
/// `StatsGrid` (and any future caller) can reuse them without
/// instantiating a card.
class StatsBuckets {
  StatsBuckets._();

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// All notes whose `dueDateIso` falls inside [period]'s window. The
  /// [now] parameter is injected so callers (and tests) can pin time.
  static List<NoteData> filter(
    List<NoteData> notes,
    StatsPeriod period,
    DateTime now,
  ) {
    switch (period) {
      case StatsPeriod.total:
        return notes;
      case StatsPeriod.today:
        final iso = _isoDate(now);
        return [
          for (final n in notes)
            if (n.dueDateIso != null && n.dueDateIso == iso) n,
        ];
      case StatsPeriod.week:
        final today = DateTime(now.year, now.month, now.day);
        final monday = today.subtract(Duration(days: today.weekday - 1));
        final nextMonday = monday.add(const Duration(days: 7));
        return [
          for (final n in notes)
            if (n.dueDateIso != null)
              if (_inWindow(n.dueDateIso!, monday, nextMonday)) n,
        ];
      case StatsPeriod.month:
        final start = DateTime(now.year, now.month, 1);
        final end =
            now.month == 12 ? DateTime(now.year + 1, 1, 1) : DateTime(now.year, now.month + 1, 1);
        return [
          for (final n in notes)
            if (n.dueDateIso != null)
              if (_inWindow(n.dueDateIso!, start, end)) n,
        ];
    }
  }

  static bool _inWindow(String iso, DateTime startInclusive, DateTime endExclusive) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return false;
    return !dt.isBefore(startInclusive) && dt.isBefore(endExclusive);
  }
}