import 'package:flutter/material.dart';
import '../model/note_data.dart';

/// iOS-style row inside a grouped list.
class MetaRow extends StatelessWidget {
  const MetaRow({
    super.key,
    required this.icon,
    required this.label,
    required this.valueWidget,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Widget valueWidget;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF8E8E93), size: 20),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF1E1E1E),
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            valueWidget,
          ],
        ),
      ),
    );
  }
}

/// Small colored pill used for priority / status.
class ColorChip extends StatelessWidget {
  const ColorChip({
    super.key,
    required this.label,
    required this.color,
    this.leadingDot = false,
  });

  final String label;
  final Color color;
  final bool leadingDot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingDot) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// Lookup helper for the canonical priority color.
Color priorityColor(NotePriority p) {
  switch (p) {
    case NotePriority.high:
      return const Color(0xFFFF3B30);
    case NotePriority.medium:
      return const Color(0xFFFF9500);
    case NotePriority.low:
      return const Color(0xFF34C759);
  }
}

/// Lookup helper for the canonical status color.
Color statusColor(NoteStatus s) {
  switch (s) {
    case NoteStatus.completed:
      return const Color(0xFF34C759);
    case NoteStatus.pending:
      return const Color(0xFFAF52DE);
  }
}

/// Human-readable label for [NotePriority].
String priorityLabel(NotePriority p) {
  switch (p) {
    case NotePriority.high:
      return 'High';
    case NotePriority.medium:
      return 'Medium';
    case NotePriority.low:
      return 'Low';
  }
}

/// Human-readable label for [NoteStatus].
String statusLabel(NoteStatus s) {
  switch (s) {
    case NoteStatus.pending:
      return 'Pending';
    case NoteStatus.completed:
      return 'Completed';
  }
}