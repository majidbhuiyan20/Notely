import 'package:flutter/material.dart';
import '../model/note_data.dart';
import 'meta_row.dart';

/// Polished 3-segment pill selector. Selected segment fills with the
/// priority's brand colour, the others stay neutral. Animates on tap so
/// the user gets clear feedback.
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
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (final p in NotePriority.values)
            Expanded(
              child: _Segment(
                priority: p,
                selected: p == initialPriority,
                onTap: () => onPrioritySelected(p),
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.priority,
    required this.selected,
    required this.onTap,
  });

  final NotePriority priority;
  final bool selected;
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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          if (selected)
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: selected ? Colors.white : color,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF1E1E1E),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
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