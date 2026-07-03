import 'package:flutter/material.dart';
import 'meta_row.dart';
import 'section_label.dart';
import '../model/note_data.dart';

/// The "DETAILS" section in the task screen — grouped list of metadata.
class TaskMetaSection extends StatelessWidget {
  const TaskMetaSection({super.key, required this.note});
  final NoteData note;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel(label: 'DETAILS'),
        const SizedBox(height: 8),
        GroupedCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MetaRow(
                icon: Icons.calendar_today_rounded,
                label: 'Due Date',
                valueWidget: Text(
                  note.dueDate,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const InsetDivider(),
              MetaRow(
                icon: Icons.timer_outlined,
                label: 'Created',
                valueWidget: Text(
                  'May 22, 2025 - 9:20 AM',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const InsetDivider(),
              MetaRow(
                icon: Icons.flag_outlined,
                label: 'Priority',
                valueWidget: ColorChip(
                  label: priorityLabel(note.priority),
                  color: priorityColor(note.priority),
                  leadingDot: true,
                ),
              ),
              const InsetDivider(),
              MetaRow(
                icon: Icons.check_circle_outline_rounded,
                label: 'Status',
                valueWidget: ColorChip(
                  label: statusLabel(note.status),
                  color: statusColor(note.status),
                ),
              ),
              const InsetDivider(),
              MetaRow(
                icon: Icons.person_outline_rounded,
                label: 'Assignee',
                valueWidget: Text(
                  note.assignee,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              const InsetDivider(indent: 50),
              MetaRow(
                icon: Icons.notifications_active_outlined,
                label: 'Reminder',
                valueWidget: Text(
                  note.reminder,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}