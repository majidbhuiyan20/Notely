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
    await _persistChecklistChange(note);
  }

  Future<void> _markAllComplete(NoteData note) async {
    for (final c in note.checklist) {
      c.isChecked = true;
    }
    note.status = NoteStatus.completed;
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
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

  Future<void> _togglePin(NoteData note) async {
    final updated =
        await ref.read(tasksProvider.notifier).togglePin(note.id);
    if (!mounted || updated == null) return;
    AppSnackbar.info(
      context,
      updated.isPinned ? 'Pinned to top' : 'Unpinned',
    );
  }

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(tasksProvider).value ?? const [];
    final note = _resolve(notes);

    if (note == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const NotelyAppBar(title: 'Note Details'),
        body: const Center(
          child: Text(
            'Note not found',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: NotelyAppBar(
        title: 'Note Details',
        actions: [
          IconButton(
            onPressed: () => _togglePin(note),
            icon: Icon(
              note.isPinned
                  ? Icons.push_pin_rounded
                  : Icons.push_pin_outlined,
              color: note.isPinned
                  ? AppColors.brandPrimary
                  : AppColors.textPrimary,
              size: 22,
            ),
            tooltip: note.isPinned ? 'Unpin' : 'Pin to top',
          ),
          IconButton(
            onPressed: _openEdit,
            icon: const Icon(
              Icons.edit_outlined,
              color: AppColors.textPrimary,
              size: 22,
            ),
            tooltip: 'Edit',
          ),
          IconButton(
            onPressed: () => _confirmDelete(note),
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.error,
              size: 22,
            ),
            tooltip: 'Delete',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TaskHeroCard(note: note, onEdit: _openEdit),
            const SizedBox(height: AppSpacing.lg),
            TaskMetaSection(note: note),
            const SizedBox(height: AppSpacing.lg),
            TaskDescriptionSection(note: note),
            const SizedBox(height: AppSpacing.lg),
            TaskChecklistSection(
              note: note,
              onToggle: (i) => _toggleChecklist(note, i),
            ),
            const SizedBox(height: AppSpacing.xl),
            _MarkAllCompleteButton(
              onPressed: () => _markAllComplete(note),
            ),
            const SizedBox(height: AppSpacing.md),
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
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.brandGradient,
        ),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: AppElevation.brandGlow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: onPressed,
          child: SizedBox(
            width: double.infinity,
            height: 58,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.check_rounded, color: Colors.white, size: 22),
                SizedBox(width: AppSpacing.xs),
                Text(
                  'MARK ALL COMPLETE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
