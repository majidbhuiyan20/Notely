import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'note_data.dart';

/// Simple in-memory data store. Acts as a singleton so all screens
/// see the same data and edits propagate everywhere via the listener API.
class NotesRepository {
  NotesRepository._internal() {
    _seed();
  }

  static final NotesRepository instance = NotesRepository._internal();

  final List<NoteData> _notes = [];
  final List<VoidCallback> _listeners = [];

  List<NoteData> get notes => List.unmodifiable(_notes);

  void addListener(VoidCallback cb) {
    if (!_listeners.contains(cb)) _listeners.add(cb);
  }

  void removeListener(VoidCallback cb) => _listeners.remove(cb);

  void _notify() {
    for (final cb in List<VoidCallback>.from(_listeners)) {
      cb();
    }
  }

  // ---------- queries ----------

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

  /// Returns notes whose [NoteData.dueDateIso] matches the supplied ISO
  /// date (yyyy-MM-dd). Used by the calendar feature.
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

  // ---------- mutations ----------

  void addNote(NoteData note) {
    _notes.add(note);
    _notify();
  }

  void replaceNote(NoteData updated) {
    final i = _notes.indexWhere((n) => n.id == updated.id);
    if (i == -1) return;
    _notes[i] = updated;
    _notify();
  }

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

  void toggleStatus(String id) {
    final n = noteById(id);
    if (n == null) return;
    n.status = n.status == NoteStatus.completed
        ? NoteStatus.pending
        : NoteStatus.completed;
    _notify();
  }

  // ---------- seed ----------

  void _seed() {
    _notes.addAll([
      // Personal
      NoteData(
        id: 'n1',
        title: 'Product RoadMap',
        description:
            "Plan the next quarter's feature releases and coordinate with the design team.",
        category: 'Personal',
        categoryColor: AppColors.green,
        categoryIcon: Icons.person_outline,
        status: NoteStatus.pending,
        priority: NotePriority.high,
        dueDate: 'Today, 10:00 AM',
        assignee: 'John Doe',
        reminder: '10 Min Before',
        checklist: [
          ChecklistItemModel(id: '1', title: 'Define product vision', isChecked: true),
          ChecklistItemModel(id: '2', title: 'Competitor analysis', isChecked: true),
          ChecklistItemModel(id: '3', title: 'Feature prioritization', isChecked: false),
          ChecklistItemModel(id: '4', title: 'Release schedule', isChecked: false),
        ],
      ),
      NoteData(
        id: 'n2',
        title: 'Morning Routine',
        description: 'Stretch, hydrate, journal, plan day.',
        category: 'Personal',
        categoryColor: AppColors.green,
        categoryIcon: Icons.person_outline,
        status: NoteStatus.completed,
        priority: NotePriority.low,
        dueDate: 'Daily, 7:00 AM',
        assignee: 'Me',
        reminder: 'None',
      ),
      NoteData(
        id: 'n3',
        title: 'Weekend Trip Planning',
        description: 'Book hotel and pack essentials.',
        category: 'Personal',
        categoryColor: AppColors.green,
        categoryIcon: Icons.person_outline,
        status: NoteStatus.pending,
        priority: NotePriority.medium,
        dueDate: 'Saturday',
        assignee: 'Family',
        reminder: '1 Day Before',
      ),

      // Work
      NoteData(
        id: 'n4',
        title: 'Quarterly Review',
        description: 'Compile Q3 metrics and prepare slides for stakeholders.',
        category: 'Work',
        categoryColor: AppColors.orange,
        categoryIcon: Icons.work_outline,
        status: NoteStatus.pending,
        priority: NotePriority.high,
        dueDate: 'Friday, 3:00 PM',
        assignee: 'Sarah K.',
        reminder: '30 Min Before',
        checklist: [
          ChecklistItemModel(id: '1', title: 'Pull revenue KPIs', isChecked: true),
          ChecklistItemModel(id: '2', title: 'Draft executive summary', isChecked: false),
          ChecklistItemModel(id: '3', title: 'Review with manager', isChecked: false),
        ],
      ),
      NoteData(
        id: 'n5',
        title: 'Team Sync Notes',
        description: 'Capture action items from weekly team standup.',
        category: 'Work',
        categoryColor: AppColors.orange,
        categoryIcon: Icons.work_outline,
        status: NoteStatus.completed,
        priority: NotePriority.medium,
        dueDate: 'Mon, 11:00 AM',
        assignee: 'Team',
        reminder: 'None',
      ),
      NoteData(
        id: 'n6',
        title: 'Client Proposal Draft',
        description: 'Outline scope, timeline, and pricing for Acme Corp.',
        category: 'Work',
        categoryColor: AppColors.orange,
        categoryIcon: Icons.work_outline,
        status: NoteStatus.pending,
        priority: NotePriority.medium,
        dueDate: 'Wed, 5:00 PM',
        assignee: 'Michael P.',
        reminder: '1 Hour Before',
      ),
      NoteData(
        id: 'n7',
        title: 'Bug Triage Sprint',
        description: 'Review, prioritize and assign open issues from this sprint.',
        category: 'Work',
        categoryColor: AppColors.orange,
        categoryIcon: Icons.work_outline,
        status: NoteStatus.completed,
        priority: NotePriority.low,
        dueDate: 'Yesterday',
        assignee: 'Engineering',
        reminder: 'None',
      ),
      NoteData(
        id: 'n8',
        title: 'Annual Performance Self-Review',
        description: 'Reflect on goals, achievements, and areas to grow.',
        category: 'Work',
        categoryColor: AppColors.orange,
        categoryIcon: Icons.work_outline,
        status: NoteStatus.pending,
        priority: NotePriority.high,
        dueDate: 'Oct 30, 5:00 PM',
        assignee: 'Self',
        reminder: '2 Days Before',
      ),

      // Health
      NoteData(
        id: 'n9',
        title: '30-Day Workout Challenge',
        description: 'Daily 30 min workout. Track progress.',
        category: 'Health',
        categoryColor: AppColors.red,
        categoryIcon: Icons.favorite_border,
        status: NoteStatus.pending,
        priority: NotePriority.medium,
        dueDate: 'Daily',
        assignee: 'Me',
        reminder: 'Every Morning',
        checklist: [
          ChecklistItemModel(id: '1', title: 'Stretching', isChecked: true),
          ChecklistItemModel(id: '2', title: 'Cardio', isChecked: true),
          ChecklistItemModel(id: '3', title: 'Cool down', isChecked: false),
        ],
      ),
      NoteData(
        id: 'n10',
        title: 'Annual Health Checkup',
        description: 'Schedule appointment with primary care physician.',
        category: 'Health',
        categoryColor: AppColors.red,
        categoryIcon: Icons.favorite_border,
        status: NoteStatus.completed,
        priority: NotePriority.high,
        dueDate: 'Last week',
        assignee: 'Dr. Lee',
        reminder: 'Done',
      ),
      NoteData(
        id: 'n11',
        title: 'Meal Prep Sunday',
        description: 'Plan and cook meals for the week.',
        category: 'Health',
        categoryColor: AppColors.red,
        categoryIcon: Icons.favorite_border,
        status: NoteStatus.pending,
        priority: NotePriority.low,
        dueDate: 'Sunday, 11:00 AM',
        assignee: 'Me',
        reminder: 'Morning Of',
      ),
      NoteData(
        id: 'n12',
        title: 'Hydration Goal',
        description: 'Drink at least 2.5L of water per day.',
        category: 'Health',
        categoryColor: AppColors.red,
        categoryIcon: Icons.favorite_border,
        status: NoteStatus.completed,
        priority: NotePriority.low,
        dueDate: 'Daily',
        assignee: 'Me',
        reminder: 'None',
      ),
      NoteData(
        id: 'n13',
        title: 'Sleep Tracking',
        description: 'Try to sleep 7+ hours every night this month.',
        category: 'Health',
        categoryColor: AppColors.red,
        categoryIcon: Icons.favorite_border,
        status: NoteStatus.pending,
        priority: NotePriority.medium,
        dueDate: 'Daily',
        assignee: 'Me',
        reminder: '10:00 PM',
      ),

      // Ideas
      NoteData(
        id: 'n14',
        title: 'App Idea: Habit Garden',
        description: 'Tie habit streaks to a virtual growing garden.',
        category: 'Ideas',
        categoryColor: AppColors.purple,
        categoryIcon: Icons.lightbulb_outline,
        status: NoteStatus.pending,
        priority: NotePriority.high,
        dueDate: 'Whenever',
        assignee: 'Brain',
        reminder: 'None',
      ),
      NoteData(
        id: 'n15',
        title: 'Blog Post: Focus Modes',
        description: 'Write about three deep-work setups that worked for me.',
        category: 'Ideas',
        categoryColor: AppColors.purple,
        categoryIcon: Icons.lightbulb_outline,
        status: NoteStatus.pending,
        priority: NotePriority.medium,
        dueDate: 'Next week',
        assignee: 'Me',
        reminder: 'None',
      ),

      // Shopping
      NoteData(
        id: 'n16',
        title: 'Weekly Grocery',
        description: 'Milk, eggs, bread, veggies, fruits.',
        category: 'Shopping',
        categoryColor: AppColors.pink,
        categoryIcon: Icons.shopping_cart_outlined,
        status: NoteStatus.pending,
        priority: NotePriority.low,
        dueDate: 'Saturday',
        assignee: 'Me',
        reminder: 'None',
      ),
      NoteData(
        id: 'n17',
        title: 'Birthday Gift - Mom',
        description: 'Order a scarf and write a card.',
        category: 'Shopping',
        categoryColor: AppColors.pink,
        categoryIcon: Icons.shopping_cart_outlined,
        status: NoteStatus.pending,
        priority: NotePriority.high,
        dueDate: 'Oct 25',
        assignee: 'Me',
        reminder: '1 Week Before',
      ),
      NoteData(
        id: 'n18',
        title: 'Replace Phone Charger',
        description: 'Buy a 2m USB-C cable.',
        category: 'Shopping',
        categoryColor: AppColors.pink,
        categoryIcon: Icons.shopping_cart_outlined,
        status: NoteStatus.completed,
        priority: NotePriority.low,
        dueDate: 'Yesterday',
        assignee: 'Me',
        reminder: 'None',
      ),

      // Dated samples used by the calendar feature. The dates are picked
      // relative to "today" at app start – see [_today].
      NoteData(
        id: 'n19',
        title: 'Doctor Appointment',
        description: 'Annual physical checkup and blood work.',
        category: 'Health',
        categoryColor: AppColors.red,
        categoryIcon: Icons.favorite_border,
        status: NoteStatus.pending,
        priority: NotePriority.high,
        dueDate: 'Today',
        dueDateIso: _todayIso(),
        assignee: 'Dr. Lee',
        reminder: '1 Hour Before',
      ),
      NoteData(
        id: 'n20',
        title: 'Project Sync',
        description: 'Weekly project status sync with the design team.',
        category: 'Work',
        categoryColor: AppColors.orange,
        categoryIcon: Icons.work_outline,
        status: NoteStatus.pending,
        priority: NotePriority.medium,
        dueDate: 'Today',
        dueDateIso: _todayIso(),
        assignee: 'Team',
        reminder: '15 Min Before',
      ),
      NoteData(
        id: 'n21',
        title: 'Yoga Class',
        description: 'Evening yoga session at the studio.',
        category: 'Health',
        categoryColor: AppColors.red,
        categoryIcon: Icons.favorite_border,
        status: NoteStatus.pending,
        priority: NotePriority.low,
        dueDate: 'Tomorrow',
        dueDateIso: _todayIso(addDays: 1),
        assignee: 'Me',
        reminder: 'Morning Of',
      ),
      NoteData(
        id: 'n22',
        title: 'Pick Up Dry Cleaning',
        description: 'Drop off and pick up suits from the dry cleaner.',
        category: 'Shopping',
        categoryColor: AppColors.pink,
        categoryIcon: Icons.shopping_cart_outlined,
        status: NoteStatus.pending,
        priority: NotePriority.low,
        dueDate: 'In 2 days',
        dueDateIso: _todayIso(addDays: 2),
        assignee: 'Me',
        reminder: 'None',
      ),
    ]);
  }
}

/// Returns the local-date ISO string for [addDays] days from today.
String _todayIso({int addDays = 0}) {
  final now = DateTime.now();
  final d = DateTime(now.year, now.month, now.day).add(Duration(days: addDays));
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
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