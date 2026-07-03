import 'package:flutter/material.dart';
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
    final meta = _categoryMeta(widget.categoryName);
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

  /// Maps the category name to a color/icon. Falls back to a neutral palette
  /// if the category is not recognized.
  ({Color color, IconData icon}) _categoryMeta(String name) {
    switch (name) {
      case 'Personal':
        return (color: const Color(0xFF34C759), icon: Icons.person_outline);
      case 'Work':
        return (color: const Color(0xFFFF9500), icon: Icons.work_outline);
      case 'Health':
        return (color: const Color(0xFFFF3B30), icon: Icons.favorite_border);
      case 'Finance':
        return (
          color: const Color(0xFF30B0C7),
          icon: Icons.account_balance_wallet_outlined
        );
      case 'Travel':
        return (
          color: const Color(0xFF00C7BE),
          icon: Icons.flight_takeoff
        );
      case 'Shopping':
        return (
          color: const Color(0xFFFF2D55),
          icon: Icons.shopping_cart_outlined
        );
      case 'Food':
        return (color: const Color(0xFFFF7F50), icon: Icons.restaurant);
      case 'Ideas':
        return (
          color: const Color(0xFFAF52DE),
          icon: Icons.lightbulb_outline
        );
      case 'Music':
        return (color: const Color(0xFF5856D6), icon: Icons.music_note);
      case 'Sports':
        return (
          color: const Color(0xFFFF3B30),
          icon: Icons.sports_basketball
        );
      case 'Education':
        return (
          color: const Color(0xFFAF52DE),
          icon: Icons.school_outlined
        );
      case 'Photography':
        return (
          color: const Color(0xFF00C7BE),
          icon: Icons.camera_alt_outlined
        );
      case 'Coding':
        return (color: const Color(0xFF007AFF), icon: Icons.code);
      case 'Art':
        return (
          color: const Color(0xFFFF2D55),
          icon: Icons.palette_outlined
        );
      case 'Gardening':
        return (
          color: const Color(0xFF34C759),
          icon: Icons.local_florist_outlined
        );
      case 'Gaming':
        return (
          color: const Color(0xFF8E5524),
          icon: Icons.sports_esports_outlined
        );
      case 'Movies':
        return (
          color: const Color(0xFFFFCC00),
          icon: Icons.movie_filter_outlined
        );
      case 'Books':
        return (color: const Color(0xFFFF9500), icon: Icons.menu_book_outlined);
      case 'Weather':
        return (
          color: const Color(0xFFFFCC00),
          icon: Icons.wb_sunny_outlined
        );
      case 'All Notes':
        return (
          color: const Color(0xFF4169E1),
          icon: Icons.note_alt_outlined
        );
      default:
        return (
          color: const Color(0xFF8E8E93),
          icon: Icons.more_horiz_rounded
        );
    }
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