import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/route/app_route.dart';
import '../../task/model/note_data.dart';
import '../../task/model/notes_repository.dart';
import '../../task/providers/notes_providers.dart';
import '../../task/providers/search_providers.dart';
import '../../widgets/back_button.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/search_field.dart';
import '../providers/category_view_providers.dart';
import '../widgets/category_filter_tabs.dart';
import '../widgets/category_header.dart';
import '../widgets/category_progress_bar.dart';
import '../widgets/note_list_tile.dart';

/// Category details screen — fully Riverpod. No `setState`, no manual
/// `ChangeNotifier` listener — the [notesListProvider] stream drives
/// every rebuild, and local UI selections (filter tab, search, sort
/// order) live in dedicated [StateProvider]s.
class CategoryDetailsScreen extends ConsumerWidget {
  const CategoryDetailsScreen({super.key, required this.categoryName});
  final String categoryName;

  _CategoryStats _statsFor(List<NoteData> notes) {
    final meta = NotesRepository.instance.categoryMeta(categoryName);
    final total = notes.where((n) => n.category == categoryName).length;
    final completed = notes
        .where((n) =>
            n.category == categoryName &&
            n.status == NoteStatus.completed)
        .length;
    return _CategoryStats(
      color: meta.color,
      icon: meta.icon,
      total: total,
      completed: completed,
      progress: total == 0 ? 0.0 : completed / total,
    );
  }

  List<NoteData> _filteredAndSorted(
    List<NoteData> source,
    CategoryFilter filter,
    bool sortByPriority,
  ) {
    Iterable<NoteData> s = source.where((n) => n.category == categoryName);

    switch (filter) {
      case CategoryFilter.all:
        break;
      case CategoryFilter.pending:
        s = s.where((n) => n.status == NoteStatus.pending);
        break;
      case CategoryFilter.completed:
        s = s.where((n) => n.status == NoteStatus.completed);
        break;
    }

    final list = s.toList();
    if (sortByPriority) {
      list.sort((a, b) => comparePriority(a.priority, b.priority));
    }
    return list;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Subscribe to the live list — every push / delete from anywhere in
    // the app shows up here automatically.
    final notes = ref.watch(notesListProvider);
    // Subscribe to filtered list for search-driven highlighting. The
    // `_SearchField` widget itself owns the text controller + provider.
    ref.watch(searchQueryProvider);

    final stats = _statsFor(notes);
    final filter = ref.watch(categoryFilterProvider);
    final sortByPriority = ref.watch(categorySortByPriorityProvider);

    final list = _filteredAndSorted(notes, filter, sortByPriority);
    final hasQuery =
        ref.watch(searchQueryProvider.select((s) => s.trim().isNotEmpty));
    final pendingCount = notes
        .where((n) =>
            n.category == categoryName &&
            n.status == NoteStatus.pending)
        .length;
    final completedCount = notes
        .where((n) =>
            n.category == categoryName &&
            n.status == NoteStatus.completed)
        .length;
    final total = stats.total;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: const NotelyAppBar(title: 'Category Details'),
      floatingActionButton: _CreateTaskFab(
        color: stats.color,
        categoryName: categoryName,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          CategoryHeader(
            title: categoryName,
            totalCount: total,
            completedCount: completedCount,
            progress: stats.progress,
            color: stats.color,
          ),
          const SizedBox(height: 16),
          CategoryProgressBar(
            progress: stats.progress,
            color: stats.color,
            completed: completedCount,
            total: total,
          ),
          const SizedBox(height: 16),
          CategoryFilterTabs(
            active: filter,
            onChanged: (f) =>
                ref.read(categoryFilterProvider.notifier).set(f),
            allCount: total,
            pendingCount: pendingCount,
            completedCount: completedCount,
            color: stats.color,
          ),
          const SizedBox(height: 12),
          const SearchField(hintText: 'Search this category…'),
          const SizedBox(height: 12),
          _SortRow(
            sortByPriority: sortByPriority,
            count: list.length,
            onToggle: () => ref
                .read(categorySortByPriorityProvider.notifier)
                .toggle(),
          ),
          const SizedBox(height: 8),
          if (list.isEmpty)
            EmptyState(
              icon: hasQuery
                  ? Icons.search_off_rounded
                  : Icons.inbox_outlined,
              title: hasQuery
                  ? 'No matching ${filter.label.toLowerCase()} tasks'
                  : 'No ${filter.label.toLowerCase()} tasks',
              subtitle: hasQuery
                  ? 'Try a different search term or switch tabs.'
                  : (filter == CategoryFilter.all
                      ? 'You haven\'t created any notes in this category yet.'
                      : 'Switch tabs to see your tasks.'),
              color: stats.color,
            )
          else
            ...List.generate(list.length, (i) {
              return Padding(
                padding: EdgeInsets.only(
                    bottom: i == list.length - 1 ? 0 : 12),
                child: NoteListTile(note: list[i]),
              );
            }),
        ],
      ),
    );
  }
}

class _CategoryStats {
  _CategoryStats({
    required this.color,
    required this.icon,
    required this.total,
    required this.completed,
    required this.progress,
  });
  final Color color;
  final IconData icon;
  final int total;
  final int completed;
  final double progress;
}

class _SortRow extends StatelessWidget {
  const _SortRow({
    required this.sortByPriority,
    required this.count,
    required this.onToggle,
  });
  final bool sortByPriority;
  final int count;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Text(
            'TASKS',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: sortByPriority
                    ? const Color(0xFF4169E1).withOpacity(0.12)
                    : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.sort_rounded,
                    size: 13,
                    color: sortByPriority
                        ? const Color(0xFF4169E1)
                        : Colors.grey.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    sortByPriority ? 'Priority' : 'Default',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: sortByPriority
                          ? const Color(0xFF4169E1)
                          : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rounded floating action button used to create a new note from the
/// category details screen. Tapping it opens the Create Task screen with
/// the current category preselected so the new note lands in the right
/// place. "All Notes" is a virtual aggregate category and falls back to
/// no preselection when creating.
class _CreateTaskFab extends StatelessWidget {
  const _CreateTaskFab({
    required this.color,
    required this.categoryName,
  });
  final Color color;
  final String categoryName;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 6,
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
        label: const Text(
          'New note',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: 0.3,
          ),
        ),
        onPressed: () {
          final initial =
              categoryName == 'All Notes' ? null : categoryName;
          Navigator.pushNamed(
            context,
            Routes.createTaskRoute,
            arguments: initial,
          );
        },
      ),
    );
  }
}