import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../task/model/note_data.dart';
import '../../task/providers/notes_providers.dart';

/// A compact row of pill cards summarising the user's notes: total,
/// completed today, pending today, and category count. Pulled live from
/// [notesProvider].
class QuickStatsRow extends ConsumerWidget {
  const QuickStatsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesProvider);
    final stats = _compute(notes);
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.layers_rounded,
            label: 'Total',
            value: stats.total,
            color: const Color(0xFF4169E1),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.check_circle_rounded,
            label: 'Done',
            value: stats.completed,
            color: const Color(0xFF34C759),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.bolt_rounded,
            label: 'Pending',
            value: stats.pending,
            color: const Color(0xFFFF9500),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.bookmark_rounded,
            label: 'Categories',
            value: stats.categoriesUsed,
            color: const Color(0xFFAF52DE),
          ),
        ),
      ],
    );
  }

  _Stats _compute(List<NoteData> notes) {
    final total = notes.length;
    final completed = notes
        .where((n) => n.status == NoteStatus.completed)
        .length;
    final pending = total - completed;
    final categories = notes.map((n) => n.category).toSet().length;
    return _Stats(
      total: total,
      completed: completed,
      pending: pending,
      categoriesUsed: categories,
    );
  }
}

class _Stats {
  _Stats({
    required this.total,
    required this.completed,
    required this.pending,
    required this.categoriesUsed,
  });
  final int total;
  final int completed;
  final int pending;
  final int categoriesUsed;
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E1E1E),
              letterSpacing: -0.4,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}