import 'package:flutter/material.dart';
import '../model/note_data.dart';
import 'meta_row.dart';

/// Tappable row used inside the create/edit form to choose a priority.
/// Visually mirrors the read-only [ColorChip] used in the task details
/// screen so the picker and the displayed value stay consistent.
class PrioritySelector extends StatelessWidget {
  const PrioritySelector({
    super.key,
    required this.initialPriority,
    required this.onPrioritySelected,
  });

  final NotePriority initialPriority;
  final ValueChanged<NotePriority> onPrioritySelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final p in NotePriority.values)
          _PriorityChip(
            priority: p,
            onTap: () => onPrioritySelected(p),
          ),
      ],
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.priority, required this.onTap});
  final NotePriority priority;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = priorityColor(priority);
    final label = priorityLabel(priority);
    final icon = switch (priority) {
      NotePriority.high => Icons.priority_high_rounded,
      NotePriority.medium => Icons.drag_handle_rounded,
      NotePriority.low => Icons.south_rounded,
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.25),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact read-only summary chip shown in some contexts (e.g. card header).
class PriorityBadge extends StatelessWidget {
  const PriorityBadge({super.key, required this.priority});
  final NotePriority priority;

  @override
  Widget build(BuildContext context) {
    final color = priorityColor(priority);
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}