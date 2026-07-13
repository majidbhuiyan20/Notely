import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/route/app_route.dart';
import '../task/model/note_data.dart';
import '../task/model/notes_repository.dart' show comparePriority;
import '../task/providers/notes_providers.dart';
import '../task/providers/search_providers.dart';
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

  final bool pinned;

  /// When true, renders the notes as a horizontal scroller instead of a
  /// vertical column.
  final bool scrollHorizontal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(notesListProvider);
    final filtered = ref.watch(filteredNotesProvider);

    final source = filtered ?? all;
    final list = pinned
        ? _filterPinned(source)
        : _sortForAllNotes(source);

    if (list.isEmpty) {
      return _EmptyList(pinned: pinned, query: filtered != null);
    }

    if (scrollHorizontal || pinned) {
      return SizedBox(
        height: 110,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: list.length,
          separatorBuilder: (_, idx) => const SizedBox(width: 12),
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

  List<NoteData> _filterPinned(List<NoteData> source) {
    final pinned = source.where((n) => n.isPinned).toList()
      ..sort((a, b) => comparePriority(a.priority, b.priority));
    return pinned;
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
    final completed = note.status == NoteStatus.completed;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => Navigator.pushNamed(
          context,
          Routes.taskRoute,
          arguments: note.id,
        ),
        onLongPress: () => showNoteActionsSheet(context, note),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppElevation.cardShadow,
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withValues(alpha: 0.18),
                      accent.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  accent == AppColors.royalBlue
                      ? Icons.note_alt_outlined
                      : note.categoryIcon,
                  color: accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
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
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              decoration: completed
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor: AppColors.textTertiary,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        if (note.isPinned)
                          const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Icon(
                              Icons.push_pin_rounded,
                              size: 14,
                              color: AppColors.brandPrimary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      note.dueDate.isEmpty ? 'No due date' : note.dueDate,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  note.category,
                  style: TextStyle(
                    fontSize: 11,
                    color: accent,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
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
  const _EmptyList({required this.pinned, this.query = false});
  final bool pinned;
  final bool query;

  @override
  Widget build(BuildContext context) {
    final String text;
    final IconData icon;
    if (query) {
      text = 'No notes match your search.';
      icon = Icons.search_off_rounded;
    } else if (pinned) {
      text =
          'Long-press any note and choose Pin to top to surface it here.';
      icon = Icons.push_pin_outlined;
    } else {
      text = 'No notes yet — tap + to add your first one!';
      icon = Icons.note_alt_outlined;
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppElevation.cardShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: AppColors.textTertiary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
