import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/route/app_route.dart';
import '../model/note_data.dart';
import '../providers/notes_providers.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/back_button.dart';
import '../widgets/task_checklist_section.dart';
import '../widgets/task_description_section.dart';
import '../widgets/task_hero_card.dart';
import '../widgets/task_meta_section.dart';

/// Read-only detail view of a single note. Reads from the live
/// [tasksProvider] so any edit made in [EditTaskScreen] is reflected
/// here automatically. Offers Edit and Delete actions in the app bar.
class TaskScreen extends ConsumerStatefulWidget {
  const TaskScreen({super.key, this.noteId});
  final String? noteId;

  @override
  ConsumerState<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends ConsumerState<TaskScreen> {
  // Local-only state for optimistic checklist toggles. We don't roundtrip
  // through sqflite on every tap because that would be jarring; the
  // changes are persisted on a debounced timer below.
  bool _savingChecklist = false;

  NoteData? _resolve(List<NoteData> notes) {
    final id = widget.noteId;
    if (id == null) return null;
    for (final n in notes) {
      if (n.id == id) return n;
    }
    return null;
  }

  Future<void> _toggleChecklist(NoteData note, int index) async {
    note.checklist[index].isChecked = !note.checklist[index].isChecked;
    setState(() {});
    await _persistChecklistChange(note);
  }

  Future<void> _markAllComplete(NoteData note) async {
    for (final c in note.checklist) {
      c.isChecked = true;
    }
    note.status = NoteStatus.completed;
    setState(() {});
    await ref.read(tasksProvider.notifier).upsert(note);
    if (!mounted) return;
    AppSnackbar.success(context, 'Marked all checklist items done');
  }

  Future<void> _persistChecklistChange(NoteData note) async {
    if (_savingChecklist) return;
    _savingChecklist = true;
    try {
      await ref.read(tasksProvider.notifier).upsert(note);
    } finally {
      _savingChecklist = false;
    }
  }

  void _openEdit() {
    final id = widget.noteId;
    if (id == null) return;
    Navigator.pushNamed(context, Routes.editTaskRoute, arguments: id);
  }

  Future<void> _confirmDelete(NoteData note) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete note?'),
        content: Text(
          '"${note.title}" will be permanently deleted from this device '
          'and from your cloud backup.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(tasksProvider.notifier).delete(note.id);
    if (!mounted) return;
    AppSnackbar.success(context, 'Note deleted');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(tasksProvider).value ?? const [];
    final note = _resolve(notes);

    if (note == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        appBar: const NotelyAppBar(title: 'Note Details'),
        body: const Center(
          child: Text(
            'Note not found',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: NotelyAppBar(
        title: 'Note Details',
        actions: [
          IconButton(
            onPressed: _openEdit,
            icon: const Icon(Icons.edit_outlined,
                color: Color(0xFF1E1E1E), size: 22),
            tooltip: 'Edit',
          ),
          IconButton(
            onPressed: () => _confirmDelete(note),
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.error, size: 22),
            tooltip: 'Delete',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TaskHeroCard(note: note, onEdit: _openEdit),
            const SizedBox(height: 20),
            TaskMetaSection(note: note),
            const SizedBox(height: 20),
            TaskDescriptionSection(note: note),
            const SizedBox(height: 20),
            TaskChecklistSection(
              note: note,
              onToggle: (i) => _toggleChecklist(note, i),
            ),
            const SizedBox(height: 28),
            _MarkAllCompleteButton(
              onPressed: () => _markAllComplete(note),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _MarkAllCompleteButton extends StatelessWidget {
  const _MarkAllCompleteButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.check_rounded, size: 22),
        label: const Text(
          'MARK ALL COMPLETE',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.royalBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}