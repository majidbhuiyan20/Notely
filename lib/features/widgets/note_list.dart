import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/route/app_route.dart';
import '../task/model/note_data.dart';
import '../task/model/notes_repository.dart' show comparePriority;
import '../task/providers/notes_providers.dart';
import '../widgets/note_actions_sheet.dart';

/// Renders a list of notes. Two modes:
///
/// * [pinned]=true  – one card per note in [pinnedNotesProvider], wrapped
///   in a horizontal scroller. Used by the "Pinned" section on Home.
/// * [pinned]=false – vertical list of every note, sorted pinned-first
///   then by priority. Used by the "All Notes" section.
class NoteList extends ConsumerWidget {
  const NoteList({
    super.key,
    this.pinned = false,
    this.scrollHorizontal = false,
  });

  /// When true, reads from [pinnedNotesProvider]. When false, reads from
  /// the full notes list.
  final bool pinned;

  /// When true, renders the notes as a horizontal scroller instead of a
  /// vertical column.
  final bool scrollHorizontal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(notesListProvider);
    final list = pinned
        ? ref.watch(pinnedNotesProvider)
        : _sortForAllNotes(all);

    if (list.isEmpty) {
      return _EmptyList(pinned: pinned);
    }

    if (scrollHorizontal || pinned) {
      return SizedBox(
        height: 110,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) => SizedBox(
            width: 280,
            child: _NoteCard(note: list[i]),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < list.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == list.length - 1 ? 0 : 12),
            child: _NoteCard(note: list[i]),
          ),
      ],
    );
  }

  List<NoteData> _sortForAllNotes(List<NoteData> notes) {
    final sorted = [...notes];
    sorted.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      final byPriority = comparePriority(a.priority, b.priority);
      if (byPriority != 0) return byPriority;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return sorted;
  }
}

class _NoteCard extends ConsumerWidget {
  const _NoteCard({required this.note});
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
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(accent == AppColors.royalBlue
                    ? Icons.note_alt_outlined
                    : note.categoryIcon),
              ).withPin(note.isPinned),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            note.title.isEmpty ? 'Untitled' : note.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E1E1E),
                              decoration: note.status == NoteStatus.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor: Colors.grey.shade400,
                            ),
                          ),
                        ),
                        if (note.isPinned) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.push_pin_rounded,
                            size: 14,
                            color: Color(0xFF4169E1),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      note.dueDate.isEmpty ? 'Recently' : note.dueDate,
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
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  note.category,
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
  const _EmptyList({required this.pinned});
  final bool pinned;

  @override
  Widget build(BuildContext context) {
    final text = pinned
        ? 'Long-press any note and choose Pin to top to surface it here.'
        : 'No notes yet — tap + to add your first one!';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            pinned ? Icons.push_pin_outlined : Icons.note_alt_outlined,
            color: Colors.grey.shade400,
            size: 18,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension on Widget {
  /// Returns a stack with a small pin badge overlaid on the top-right
  /// corner of this widget. Used to mark pinned tiles in the list.
  Widget withPin(bool pinned) {
    if (!pinned) return this;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        this,
        Positioned(
          right: -4,
          top: -4,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: const Color(0xFF4169E1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              Icons.push_pin_rounded,
              size: 9,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}