import 'package:flutter/material.dart';
import 'check_list_item.dart';
import 'section_label.dart';
import '../model/note_data.dart';

/// The full "CHECKLIST" section card with header progress pill,
/// toggleable items and a bottom progress bar.
class TaskChecklistSection extends StatelessWidget {
  const TaskChecklistSection({super.key, required this.note, required this.onToggle});

  final NoteData note;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final progress = note.checklistProgress;
    final completed = note.completedChecklist;
    final total = note.totalChecklist;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SectionLabel(label: 'CHECKLIST'),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF34C759).withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$completed/$total done',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B5E20),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GroupedCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Column(
                  children: [
                    for (int i = 0; i < note.checklist.length; i++) ...[
                      ChecklistItem(
                        title: note.checklist[i].title,
                        isChecked: note.checklist[i].isChecked,
                        onTap: () => onToggle(i),
                      ),
                      if (i != note.checklist.length - 1)
                        const Divider(
                            height: 1,
                            indent: 42,
                            color: Color(0x14000000)),
                    ],
                  ],
                ),
              ),
              Container(
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 14),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE5E5EA),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF34C759)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ],
    );
  }
}