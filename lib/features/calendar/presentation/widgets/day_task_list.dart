import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/route/app_route.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../widgets/empty_state.dart';
import '../../../task/model/note_data.dart';
import '../../data/calendar_repository.dart';
import '../providers/calendar_providers.dart';
import 'month_grid.dart' show isoDate;

/// Lists the tasks scheduled on the currently selected date. Tasks with
/// a `dueTime` are sorted chronologically and shown with a left time
/// column. All-day tasks (no time) appear below under an "All-day"
/// subheading.
class DayTaskList extends ConsumerWidget {
  const DayTaskList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedDateProvider);
    final iso = isoDate(selected);
    final tasks = ref.watch(calendarRepositoryProvider).notesOnDate(iso);

    final timed = <NoteData>[
      for (final n in tasks)
        if (n.dueTime.isNotEmpty) n,
    ]..sort((a, b) => a.dueTime.compareTo(b.dueTime));

    final allDay = <NoteData>[
      for (final n in tasks)
        if (n.dueTime.isEmpty) n,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Row(
            children: [
              Text(
                _weekday(selected.weekday).toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${tasks.length}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (tasks.isEmpty)
          const EmptyState(
            icon: Icons.event_available_outlined,
            title: 'No tasks',
            subtitle: 'Pick another day or add a note with this due date.',
            color: Color(0xFF4169E1),
          )
        else ...[
          for (final n in timed)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CalendarTaskCard(note: n, showTime: true),
            ),
          if (allDay.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 4, bottom: 6),
              child: Text(
                'ALL-DAY',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.0,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            for (final n in allDay)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CalendarTaskCard(note: n, showTime: false),
              ),
          ],
        ],
      ],
    );
  }

  String _weekday(int w) {
    const names = [
      'Sunday', 'Monday', 'Tuesday', 'Wednesday',
      'Thursday', 'Friday', 'Saturday',
    ];
    return names[w % 7];
  }
}

/// Same card style as before; gains a left time column when [showTime]
/// is true.
class _CalendarTaskCard extends StatelessWidget {
  const _CalendarTaskCard({required this.note, required this.showTime});
  final NoteData note;
  final bool showTime;

  @override
  Widget build(BuildContext context) {
    final accent = note.categoryColor;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.pushNamed(context, Routes.taskRoute, arguments: note.id);
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
          child: Row(
            children: [
              if (showTime) ...[
                SizedBox(
                  width: 56,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormatter.formatTime12h(note.dueTime),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E1E1E),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        width: 24,
                        height: 3,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  note.categoryIcon,
                  size: 20,
                  color: accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      note.category,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}