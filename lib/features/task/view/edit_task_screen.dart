import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../model/note_data.dart';
import '../model/notes_repository.dart';
import '../providers/notes_providers.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/back_button.dart';
import 'task_form.dart';

/// Edit screen for an existing note. Mirrors [CreateTaskScreen] layout.
/// On Save the updated note is persisted to sqflite (and pushed to
/// Firestore in the background) via [TasksNotifier].
class EditTaskScreen extends ConsumerStatefulWidget {
  const EditTaskScreen({super.key, this.noteId});
  final String? noteId;

  @override
  ConsumerState<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends ConsumerState<EditTaskScreen> {
  NoteData? _note;
  TaskFormController? _form;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Wait for the next frame so `ref` is ready, then hydrate from the
    // list already loaded by the splash/tasksProvider.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hydrate();
    });
  }

  void _hydrate() {
    final id = widget.noteId;
    if (id == null) return;
    final list = ref.read(tasksProvider).value ?? const [];
    final note = list.cast<NoteData?>().firstWhere(
          (n) => n?.id == id,
          orElse: () => null,
        );
    if (note == null) return;
    setState(() {
      _note = note;
      _form = TaskFormController(
        title: note.title,
        description: note.description,
        category: note.category,
        priority: note.priority,
        dueDate:
            note.dueDateIso == null ? null : _parseIso(note.dueDateIso!),
        dueTime: note.dueTime,
        checklist: note.checklist,
      );
      _form!.onChanged = () {
        if (mounted) setState(() {});
      };
    });
  }

  @override
  void dispose() {
    _form?.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    final note = _note;
    final form = _form;
    if (note == null || form == null) {
      Navigator.pop(context);
      return;
    }

    final snap = form.snapshot();
    final updated = note.copy();
    updated.title = snap.title.isEmpty ? 'Untitled' : snap.title;
    updated.description = snap.description;
    updated.category = snap.category;
    updated.priority = snap.priority;
    updated.dueDateIso = snap.dueDate == null ? null : _iso(snap.dueDate!);
    updated.dueDate = snap.dueDate == null ? '' : _dueDateDisplay(snap.dueDate!);
    updated.dueTime = snap.dueDate == null ? '' : snap.dueTime;
    updated.checklist
      ..clear()
      ..addAll(snap.checklist);

    final meta = NotesRepository.instance.categoryMeta(snap.category);
    updated.categoryColor = meta.color;
    updated.categoryIcon = meta.icon;

    setState(() => _busy = true);
    try {
      await ref.read(tasksProvider.notifier).upsert(updated);
      if (!mounted) return;
      AppSnackbar.success(context, 'Note updated');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _dueDateDisplay(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _iso(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  DateTime? _parseIso(String iso) {
    try {
      final parts = iso.split('-');
      if (parts.length != 3) return null;
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.royalBlue;
    final form = _form;

    if (form == null || _note == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        appBar: NotelyAppBar(
          title: 'Edit Note',
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: const Center(
          child: Text(
            'Note not found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: NotelyAppBar(
        title: 'Edit Note',
        actions: [
          TextButton(
            onPressed: _busy ? null : _save,
            style: TextButton.styleFrom(foregroundColor: accent),
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: TaskFormBody(controller: form),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: TaskFormSaveButton(
              label: _busy ? 'SAVING…' : 'SAVE CHANGES',
              onPressed: _busy ? null : _save,
            ),
          ),
        ],
      ),
    );
  }
}