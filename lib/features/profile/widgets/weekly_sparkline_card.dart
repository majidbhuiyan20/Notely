import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../task/model/note_data.dart';
import '../../task/providers/notes_providers.dart';

/// Compact 7-bar weekly sparkline. Shows Mon..Sun completion counts
/// for the current calendar week (matches what users mean by
/// "this week"). Reuses the same bucketing math as
/// `AnalyticsRepository._dailyWeek` but inlined here to keep the
/// profile feature self-contained.
class WeeklySparklineCard extends ConsumerWidget {
  const WeeklySparklineCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesListProvider);
    final buckets = _weeklyBuckets(notes, DateTime.now());

    // One-shot scale-in for the card itself so the chart "lands".
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.95, end: 1.0),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) {
        return Opacity(
          opacity: scale == 1.0 ? 1 : (scale - 0.95) / 0.05,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: _buildCard(context, buckets),
    );
  }

  Widget _buildCard(BuildContext context, List<_DayBucket> buckets) {
    final maxY = _maxY(buckets);
    final total = buckets.fold<int>(0, (a, b) => a + b.total);
    final done = buckets.fold<int>(0, (a, b) => a + b.completed);
    final peak = buckets.reduce(
      (a, b) => a.completed >= b.completed ? a : b,
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppElevation.cardShadow,
        border: Border.all(color: AppColors.divider, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppColors.brandGradient,
                  ),
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandPrimary.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly Activity',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Tasks completed this week',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '$done/$total done',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brandPrimary,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 130,
            child: total == 0
                ? const _EmptySparkline()
                : _Chart(buckets: buckets, maxY: maxY),
          ),
          if (total > 0 && peak.completed > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(
                  Icons.bolt_rounded,
                  size: 14,
                  color: AppColors.brandAccent,
                ),
                const SizedBox(width: 4),
                Text(
                  'Peak day: ${peak.label} (${peak.completed} completed)',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─── bucketing ──────────────────────────────────────────────────

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static List<_DayBucket> _weeklyBuckets(List<NoteData> notes, DateTime now) {
    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final results = <_DayBucket>[];

    for (int i = 0; i < 7; i++) {
      final d = monday.add(Duration(days: i));
      final iso = _iso(d);
      var total = 0;
      var completed = 0;
      for (final n in notes) {
        if (n.dueDateIso == iso) {
          total++;
          if (n.status == NoteStatus.completed) completed++;
        }
      }
      results.add(_DayBucket(
        label: dayLabels[i],
        total: total,
        completed: completed,
      ));
    }
    return results;
  }

  static int _maxY(List<_DayBucket> b) {
    var m = 0;
    for (final x in b) {
      if (x.total > m) m = x.total;
    }
    return m;
  }
}

class _DayBucket {
  const _DayBucket({
    required this.label,
    required this.total,
    required this.completed,
  });
  final String label;
  final int total;
  final int completed;
}

class _Chart extends StatelessWidget {
  const _Chart({required this.buckets, required this.maxY});
  final List<_DayBucket> buckets;
  final int maxY;

  @override
  Widget build(BuildContext context) {
    final groups = <BarChartGroupData>[];
    for (int i = 0; i < buckets.length; i++) {
      final b = buckets[i];
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: b.total.toDouble(),
              color: AppColors.brandPrimary.withValues(alpha: 0.18),
              width: 14,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(6)),
            ),
            BarChartRodData(
              toY: b.completed.toDouble(),
              gradient: const LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: AppColors.brandGradient,
              ),
              width: 14,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(6)),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        maxY: (maxY + 1).toDouble(),
        barGroups: groups,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, _) {
                final i = value.toInt();
                if (i < 0 || i >= buckets.length) {
                  return const SizedBox.shrink();
                }
                final isToday = buckets[i].label == _todayLabel();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    buckets[i].label,
                    style: TextStyle(
                      fontSize: 10,
                      color: isToday
                          ? AppColors.brandPrimary
                          : AppColors.textTertiary,
                      fontWeight:
                          isToday ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                );
              },
              interval: 1,
            ),
          ),
        ),
      ),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }

  static String _todayLabel() {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final w = DateTime.now().weekday; // Mon=1..Sun=7
    return labels[w - 1];
  }
}

class _EmptySparkline extends StatelessWidget {
  const _EmptySparkline();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.bar_chart_rounded,
            color: AppColors.textTertiary,
            size: 28,
          ),
          SizedBox(height: 8),
          Text(
            'No tasks scheduled this week yet',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}