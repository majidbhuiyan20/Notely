import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/route/app_route.dart';
import '../../task/model/note_data.dart';
import '../../widgets/note_actions_sheet.dart';

/// Compact card used in the Recent row. Differs from _NoteCard in
/// NoteList by fitting a 240x130 box with a two-line title preview
/// and the due date / category chip.
class RecentNoteCard extends ConsumerWidget {
  const RecentNoteCard({super.key, required this.note});
  final NoteData note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = note.categoryColor;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.04),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pushNamed(
          context,
          Routes.taskRoute,
          arguments: note.id,
        ),
        onLongPress: () => showNoteActionsSheet(context, note),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      accent.toARGB32() == const Color(0xFF4169E1).toARGB32()
                          ? Icons.note_alt_outlined
                          : note.categoryIcon,
                      size: 16,
                      color: accent,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      note.category,
                      style: TextStyle(
                        fontSize: 10,
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                note.title.isEmpty ? 'Untitled' : note.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E1E1E),
                  height: 1.25,
                  decoration: note.status == NoteStatus.completed
                      ? TextDecoration.lineThrough
                      : null,
                  decorationColor: Colors.grey.shade400,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 12,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      note.dueDate.isEmpty ? 'Recently' : note.dueDate,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
