import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/route/app_route.dart';
import '../task/model/note_data.dart';
import '../task/model/notes_repository.dart';
import '../task/providers/notes_providers.dart';

/// Tile representing a single note in any list. Reads its data from the
/// [notesProvider] (which wraps [NotesRepository]). Supports two modes:
///
/// * Pinned-style single-card (with explicit [noteId])
/// * "All notes" list ([compact=false]) which renders a real list of
///   every note in the repository, in priority order.
class NoteList extends ConsumerWidget {
  const NoteList({
    super.key,
    this.noteId,
    this.titleOverride,
    this.timeOverride,
    this.compact = true,
  });

  final String? noteId;
  final String? titleOverride;
  final String? timeOverride;

  /// When true (default) renders as a single "pinned" card. When false,
  /// renders a vertical list of every note in the repository, sorted by
  /// priority.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesProvider);
    if (compact) {
      return _buildPinned(context, notes);
    }
    return _buildList(context, notes);
  }

  Widget _buildPinned(BuildContext context, List<NoteData> notes) {
    final note = (noteId != null
            ? notes.firstWhere(
                (n) => n.id == noteId,
                orElse: () => notes.isNotEmpty
                    ? notes.first
                    : NoteData(
                        id: 'placeholder',
                        title: 'No notes yet',
                        description: '',
                        category: 'Notes',
                        categoryColor: AppColors.grey,
                        categoryIcon: Icons.note_outlined,
                      ),
              )
            : (notes.isNotEmpty ? notes.first : null));

    final title = titleOverride ?? note?.title ?? 'No notes yet';
    final time = timeOverride ?? 'Recently';
    final accent = note?.categoryColor ?? AppColors.royalBlue;
    final categoryName = note?.category ?? 'Notes';
    final id = note?.id;

    return _NoteCard(
      title: title,
      time: time,
      accent: accent,
      icon: note?.categoryIcon ?? Icons.person_outline,
      category: categoryName,
      onTap: id == null || id == 'placeholder'
          ? null
          : () {
              Navigator.pushNamed(context, Routes.taskRoute, arguments: id);
            },
    );
  }

  Widget _buildList(BuildContext context, List<NoteData> notes) {
    final sorted = [...notes]
      ..sort((a, b) => comparePriority(a.priority, b.priority));
    if (sorted.isEmpty) {
      return _EmptyList();
    }
    return Column(
      children: [
        for (final n in sorted)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _NoteCard(
              title: n.title,
              time: n.dueDate.isEmpty ? 'Recently' : n.dueDate,
              accent: n.categoryColor,
              icon: n.categoryIcon,
              category: n.category,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  Routes.taskRoute,
                  arguments: n.id,
                );
              },
            ),
          ),
      ],
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.title,
    required this.time,
    required this.accent,
    required this.icon,
    required this.category,
    required this.onTap,
  });
  final String title;
  final String time;
  final Color accent;
  final IconData icon;
  final String category;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.04),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 11,
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          'No notes yet — tap + to add your first one!',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}