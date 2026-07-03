import 'package:flutter/material.dart';
import '../../../core/route/app_route.dart';
import '../../task/model/note_data.dart';
import '../../task/widgets/meta_row.dart';

/// A single note row inside the Category Details list.
/// Tap navigates to the task screen.
class NoteListTile extends StatelessWidget {
  const NoteListTile({
    super.key,
    required this.note,
    this.onTap,
  });

  final NoteData note;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pColor = priorityColor(note.priority);
    final sColor = statusColor(note.status);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap ??
          () => Navigator.pushNamed(
                context,
                Routes.taskRoute,
                arguments: note.id,
              ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox
            GestureDetector(
              onTap: () {
                note.status = note.status == NoteStatus.completed
                    ? NoteStatus.pending
                    : NoteStatus.completed;
                (context as Element).markNeedsBuild();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 24,
                width: 24,
                margin: const EdgeInsets.only(top: 2, right: 12),
                decoration: BoxDecoration(
                  color: note.status == NoteStatus.completed
                      ? const Color(0xFF34C759)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: note.status == NoteStatus.completed
                        ? const Color(0xFF34C759)
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: note.status == NoteStatus.completed
                    ? const Icon(Icons.check_rounded,
                        size: 16, color: Colors.white)
                    : null,
              ),
            ),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E1E1E),
                      decoration: note.status == NoteStatus.completed
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: Colors.grey.shade400,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    note.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _MiniChip(
                        icon: Icons.flag_rounded,
                        label: priorityLabel(note.priority),
                        color: pColor,
                      ),
                      _MiniChip(
                        icon: Icons.circle,
                        iconSize: 8,
                        label: statusLabel(note.status),
                        color: sColor,
                      ),
                      if (note.dueDate.isNotEmpty)
                        _MiniChip(
                          icon: Icons.schedule_rounded,
                          label: note.dueDate,
                          color: Colors.grey.shade600,
                          neutral: true,
                        ),
                      if (note.checklist.isNotEmpty)
                        _MiniChip(
                          icon: Icons.checklist_rounded,
                          label:
                              '${note.completedChecklist}/${note.totalChecklist}',
                          color: const Color(0xFF34C759),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({
    required this.icon,
    required this.label,
    required this.color,
    this.iconSize = 14,
    this.neutral = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final double iconSize;
  final bool neutral;

  @override
  Widget build(BuildContext context) {
    final bg = neutral ? const Color(0xFFF2F2F7) : color.withOpacity(0.12);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: iconSize),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}