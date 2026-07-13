import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../task/model/note_data.dart';
import '../../task/providers/notes_providers.dart';
import 'stats_period_card.dart';

/// 2x2 grid of stat cards (Today / This Week / This Month / All Time).
/// Reads the live note list via [notesListProvider] and computes each
/// window's count + completed inline so the grid is self-contained.
class StatsGrid extends ConsumerWidget {
  const StatsGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesListProvider);
    final now = DateTime.now();

    int completedOf(List<NoteData> list) =>
        list.where((n) => n.status == NoteStatus.completed).length;

    final today = StatsBuckets.filter(notes, StatsPeriod.today, now);
    final week = StatsBuckets.filter(notes, StatsPeriod.week, now);
    final month = StatsBuckets.filter(notes, StatsPeriod.month, now);

    // Card stagger — each card waits this many ms before fading in.
    const delays = <int>[0, 60, 120, 180];

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatsPeriodCard(
                period: StatsPeriod.today,
                count: today.length,
                completed: completedOf(today),
                delayMs: delays[0],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: StatsPeriodCard(
                period: StatsPeriod.week,
                count: week.length,
                completed: completedOf(week),
                delayMs: delays[1],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: StatsPeriodCard(
                period: StatsPeriod.month,
                count: month.length,
                completed: completedOf(month),
                delayMs: delays[2],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: StatsPeriodCard(
                period: StatsPeriod.total,
                count: notes.length,
                completed: completedOf(notes),
                delayMs: delays[3],
              ),
            ),
          ],
        ),
      ],
    );
  }
}