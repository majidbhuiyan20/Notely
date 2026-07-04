import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../task/model/note_data.dart';
import '../../task/providers/notes_providers.dart';
import '../../widgets/title_section.dart';
import 'recent_note_card.dart';

/// Horizontal scroll of the most recent non-pinned notes. Surfaces
/// recent activity above the full All Notes list. Hides itself when
/// there's nothing to show so the home screen stays uncluttered.
class RecentNotesRow extends ConsumerWidget {
  const RecentNotesRow({super.key, this.limit = 5});
  final int limit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(notesListProvider);
    final recent = _recentNonPinned(all, limit);

    if (recent.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TitleSection(
          title: 'Recent',
          showSeeAll: false,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: recent.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => SizedBox(
              width: 240,
              child: RecentNoteCard(note: recent[i]),
            ),
          ),
        ),
      ],
    );
  }

  List<NoteData> _recentNonPinned(List<NoteData> notes, int limit) {
    final filtered = notes.where((n) => !n.isPinned).toList();
    filtered.sort((a, b) {
      // Pinned surfaced first, then due-date if both set, then title alpha.
      if (a.dueDateIso != null && b.dueDateIso != null) {
        return b.dueDateIso!.compareTo(a.dueDateIso!);
      }
      if (a.dueDateIso != null) return -1;
      if (b.dueDateIso != null) return 1;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    if (filtered.length > limit) {
      return filtered.sublist(0, limit);
    }
    return filtered;
  }
}