import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/route/app_route.dart';
import '../../../widgets/empty_state.dart';
import '../../../task/model/note_data.dart';
import '../../data/calendar_repository.dart';
import '../providers/calendar_providers.dart';
import 'month_grid.dart' show isoDate;

/// Lists the tasks scheduled on the currently selected date. Each row taps
/// through to the existing Task screen (no new screen needed – the
/// calendar just provides a different lens on the same notes).
class DayTaskList extends ConsumerWidget {
  const DayTaskList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedDateProvider);
    final iso = isoDate(selected);
    final tasks = ref.watch(calendarRepositoryProvider).notesOnDate(iso);

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
                  color: Colors.black.withOpacity(0.05),
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
        else
          ...tasks.map(
            (n) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CalendarTaskCard(note: n),
            ),
          ),
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

/// Same rendering as [NoteListTile] but wrapped in a styled card so the
/// calendar screen can have its own look without modifying the shared
/// widget.
class _CalendarTaskCard extends StatelessWidget {
  const _CalendarTaskCard({required this.note});
  final NoteData note;

  @override
  Widget build(BuildContext context) {
    final accent = note.categoryColor;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.05),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.pushNamed(context, Routes.taskRoute, arguments: note.id);
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
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