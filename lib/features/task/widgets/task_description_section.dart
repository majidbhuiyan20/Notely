import 'package:flutter/material.dart';
import 'section_label.dart';
import '../model/note_data.dart';

/// The "DESCRIPTION" section card.
class TaskDescriptionSection extends StatelessWidget {
  const TaskDescriptionSection({super.key, required this.note});
  final NoteData note;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel(label: 'DESCRIPTION'),
        const SizedBox(height: 8),
        GroupedCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              note.description,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF1E1E1E),
                height: 1.45,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ],
    );
  }
}