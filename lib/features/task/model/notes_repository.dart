import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'note_data.dart';

/// In-memory mirror of the sqflite task table. The local DB is the
/// source of truth; this singleton exists so existing screens (home,
/// calendar, category, profile) can read derived statistics without
/// each one opening sqflite on its own.
///
/// Writes do NOT happen here directly anymore — they go through
/// [TaskRepository] which updates sqflite, then calls
/// [replaceAll]/[addOrUpdate]/[remove] to keep this mirror in sync.
class NotesRepository {
  NotesRepository._internal();

  static final NotesRepository instance = NotesRepository._internal();

  final List<NoteData> _notes = [];
  final List<VoidCallback> _listeners = [];

  /// Read-only view of the current notes. Always a fresh list so callers
  /// can't mutate the underlying storage by accident.
  List<NoteData> get notes => List.unmodifiable(_notes);

  // ---------- listener plumbing ----------

  void addListener(VoidCallback cb) {
    if (!_listeners.contains(cb)) _listeners.add(cb);
  }

  void removeListener(VoidCallback cb) => _listeners.remove(cb);

  void _notify() {
    for (final cb in List<VoidCallback>.from(_listeners)) {
      cb();
    }
  }

  // ---------- mirror maintenance (called by TaskRepository) ----------

  /// Replaces the entire mirror with [next] and notifies listeners.
  void replaceAll(List<NoteData> next) {
    _notes
      ..clear()
      ..addAll(next);
    _notify();
  }

  /// Inserts a new note or updates an existing one with the same id.
  void addOrUpdate(NoteData note) {
    final i = _notes.indexWhere((n) => n.id == note.id);
    if (i == -1) {
      _notes.add(note);
    } else {
      _notes[i] = note;
    }
    _notify();
  }

  /// Removes the note with [id]. No-op if it doesn't exist.
  void remove(String id) {
    final before = _notes.length;
    _notes.removeWhere((n) => n.id == id);
    if (_notes.length != before) _notify();
  }

  // ---------- queries (unchanged from original) ----------

  NoteData? noteById(String id) {
    try {
      return _notes.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }

  Iterable<NoteData> notesByCategory(String category) =>
      _notes.where((n) => n.category == category);

  Iterable<NoteData> notesByCategoryAndStatus(
          String category, NoteStatus status) =>
      _notes.where((n) => n.category == category && n.status == status);

  Iterable<NoteData> notesOnDate(String isoDate) =>
      _notes.where((n) => n.dueDateIso == isoDate);

  int totalFor(String category) => notesByCategory(category).length;
  int completedFor(String category) =>
      notesByCategoryAndStatus(category, NoteStatus.completed).length;
  int pendingFor(String category) => totalFor(category) - completedFor(category);

  double progressFor(String category) {
    final total = totalFor(category);
    if (total == 0) return 0;
    return completedFor(category) / total;
  }

  // ---------- mutations from screens that still hit the singleton ----------

  void addNote(NoteData note) => addOrUpdate(note);

  void replaceNote(NoteData updated) => addOrUpdate(updated);

  /// Maps a category name to its color/icon (falls back to a neutral palette).
  ({Color color, IconData icon}) categoryMeta(String name) {
    switch (name) {
      case 'Personal':
        return (color: AppColors.green, icon: Icons.person_outline);
      case 'Work':
        return (color: AppColors.orange, icon: Icons.work_outline);
      case 'Health':
        return (color: AppColors.red, icon: Icons.favorite_border);
      case 'Finance':
        return (
          color: AppColors.teal,
          icon: Icons.account_balance_wallet_outlined,
        );
      case 'Travel':
        return (color: AppColors.cyan, icon: Icons.flight_takeoff);
      case 'Shopping':
        return (
          color: AppColors.pink,
          icon: Icons.shopping_cart_outlined,
        );
      case 'Food':
        return (color: AppColors.coral, icon: Icons.restaurant);
      case 'Ideas':
        return (color: AppColors.purple, icon: Icons.lightbulb_outline);
      case 'Music':
        return (color: AppColors.indigo, icon: Icons.music_note);
      case 'Sports':
        return (
          color: AppColors.crimson,
          icon: Icons.sports_basketball,
        );
      case 'Education':
        return (color: AppColors.violet, icon: Icons.school_outlined);
      case 'Photography':
        return (
          color: AppColors.turquoise,
          icon: Icons.camera_alt_outlined,
        );
      case 'Coding':
        return (color: AppColors.blue, icon: Icons.code);
      case 'Art':
        return (color: AppColors.magenta, icon: Icons.palette_outlined);
      case 'Gardening':
        return (
          color: AppColors.lime,
          icon: Icons.local_florist_outlined,
        );
      case 'Gaming':
        return (
          color: AppColors.brown,
          icon: Icons.sports_esports_outlined,
        );
      case 'Movies':
        return (
          color: AppColors.gold,
          icon: Icons.movie_filter_outlined,
        );
      case 'Books':
        return (color: AppColors.orange, icon: Icons.menu_book_outlined);
      case 'Weather':
        return (color: AppColors.mint, icon: Icons.wb_sunny_outlined);
      case 'All Notes':
        return (color: AppColors.royalBlue, icon: Icons.note_alt_outlined);
      default:
        return (
          color: AppColors.grey,
          icon: Icons.more_horiz_outlined,
        );
    }
  }
}

/// Convenience: priority sort comparator — High → Medium → Low.
int comparePriority(NotePriority a, NotePriority b) {
  const order = {
    NotePriority.high: 0,
    NotePriority.medium: 1,
    NotePriority.low: 2,
  };
  return order[a]!.compareTo(order[b]!);
}