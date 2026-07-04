import 'package:flutter/material.dart';
import '../../../core/route/app_route.dart';
import '../../task/model/note_data.dart';
import '../../task/model/notes_repository.dart';
import '../../widgets/back_button.dart';
import '../../widgets/empty_state.dart';
import '../widgets/category_filter_tabs.dart';
import '../widgets/category_header.dart';
import '../widgets/category_progress_bar.dart';
import '../widgets/note_list_tile.dart';

class CategoryDetailsScreen extends StatefulWidget {
  const CategoryDetailsScreen({super.key, required this.categoryName});
  final String categoryName;

  @override
  State<CategoryDetailsScreen> createState() => _CategoryDetailsScreenState();
}

class _CategoryDetailsScreenState extends State<CategoryDetailsScreen> {
  CategoryFilter _filter = CategoryFilter.all;
  bool _sortByPriority = true;
  String _search = '';
  late final NotesRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = NotesRepository.instance;
    _repo.addListener(_onRepoChanged);
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepoChanged);
    super.dispose();
  }

  void _onRepoChanged() {
    if (mounted) setState(() {});
  }

  /// Returns the metadata for the current category: total / completed /
  /// progress / accent color.
  _CategoryStats _statsFor() {
    final meta = _repo.categoryMeta(widget.categoryName);
    final total = _repo.totalFor(widget.categoryName);
    final completed = _repo.completedFor(widget.categoryName);
    return _CategoryStats(
      color: meta.color,
      icon: meta.icon,
      total: total,
      completed: completed,
      progress: _repo.progressFor(widget.categoryName),
    );
  }

  List<NoteData> _filteredAndSorted() {
    Iterable<NoteData> source = _repo.notesByCategory(widget.categoryName);

    switch (_filter) {
      case CategoryFilter.all:
        break;
      case CategoryFilter.pending:
        source = source.where((n) => n.status == NoteStatus.pending);
        break;
      case CategoryFilter.completed:
        source = source.where((n) => n.status == NoteStatus.completed);
        break;
    }

    if (_search.trim().isNotEmpty) {
      final q = _search.toLowerCase();
      source = source.where((n) =>
          n.title.toLowerCase().contains(q) ||
          n.description.toLowerCase().contains(q));
    }

    final list = source.toList();
    if (_sortByPriority) {
      list.sort((a, b) => comparePriority(a.priority, b.priority));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final stats = _statsFor();
    final list = _filteredAndSorted();
    final pendingCount =
        _repo.pendingFor(widget.categoryName);
    final completedCount =
        _repo.completedFor(widget.categoryName);
    final total = stats.total;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: const NotelyAppBar(title: 'Category Details'),
      floatingActionButton: _CreateTaskFab(
        color: stats.color,
        categoryName: widget.categoryName,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          CategoryHeader(
            title: widget.categoryName,
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
            active: _filter,
            onChanged: (f) => setState(() => _filter = f),
            allCount: total,
            pendingCount: pendingCount,
            completedCount: completedCount,
            color: stats.color,
          ),
          const SizedBox(height: 12),
          _SearchField(
            value: _search,
            color: stats.color,
            onChanged: (v) => setState(() => _search = v),
          ),
          const SizedBox(height: 12),
          _SortRow(
            sortByPriority: _sortByPriority,
            count: list.length,
            onToggle: () =>
                setState(() => _sortByPriority = !_sortByPriority),
          ),
          const SizedBox(height: 8),
          if (list.isEmpty)
            EmptyState(
              icon: Icons.inbox_outlined,
              title: 'No ${_filter.label.toLowerCase()} tasks',
              subtitle: _filter == CategoryFilter.all
                  ? 'You haven\'t created any notes in this category yet.'
                  : 'Switch tabs to see your tasks.',
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
/// "Personal" when creating.
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
          final initial = categoryName == 'All Notes' ? null : categoryName;
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

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.value,
    required this.color,
    required this.onChanged,
  });

  final String value;
  final Color color;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search this category…',
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(Icons.search_rounded, color: color, size: 22),
          suffixIcon: value.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () => onChanged(''),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}