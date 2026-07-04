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
///
/// Busy state lives in a [ValueNotifier] so toggling it doesn't trigger
/// a full rebuild that could race with Riverpod's provider rebuild chain.
/// The note being edited is derived from [tasksProvider] so the screen
/// itself is a stateless [ConsumerWidget] — no `setState`, no hydration
/// race.
class EditTaskScreen extends ConsumerWidget {
  const EditTaskScreen({super.key, this.noteId});
  final String? noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = AppColors.royalBlue;
    final id = noteId;
    final list = ref.watch(tasksProvider).value ?? const [];
    final note = id == null
        ? null
        : list.cast<NoteData?>().firstWhere(
            (n) => n?.id == id,
            orElse: () => null,
          );

    if (note == null) {
      return _NoteNotFound(accent: accent);
    }

    return _EditTaskScreenBody(note: note, accent: accent);
  }
}

class _EditTaskScreenBody extends ConsumerStatefulWidget {
  const _EditTaskScreenBody({required this.note, required this.accent});
  final NoteData note;
  final Color accent;

  @override
  ConsumerState<_EditTaskScreenBody> createState() =>
      _EditTaskScreenBodyState();
}

class _EditTaskScreenBodyState extends ConsumerState<_EditTaskScreenBody> {
  late final TaskFormController _form;
  final ValueNotifier<bool> _busy = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    final note = widget.note;
    _form = TaskFormController(
      title: note.title,
      description: note.description,
      category: note.category,
      priority: note.priority,
      dueDate: note.dueDateIso == null ? null : _parseIso(note.dueDateIso!),
      dueTime: note.dueTime,
      checklist: note.checklist,
    );
  }

  @override
  void dispose() {
    _form.dispose();
    _busy.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy.value) return;
    final snap = _form.snapshot();
    final updated = widget.note.copy();
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

    _busy.value = true;
    try {
      await ref.read(tasksProvider.notifier).upsert(updated);
      if (!mounted) return;
      AppSnackbar.success(context, 'Note updated');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, e.toString());
    } finally {
      if (mounted) _busy.value = false;
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
    final accent = widget.accent;
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: NotelyAppBar(
        title: 'Edit Note',
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: _busy,
            builder: (context, busy, _) {
              return TextButton(
                onPressed: busy ? null : _save,
                style: TextButton.styleFrom(foregroundColor: accent),
                child: busy
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
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: TaskFormBody(controller: _form),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: _busy,
            builder: (context, busy, _) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: TaskFormSaveButton(
                  label: busy ? 'SAVING…' : 'SAVE CHANGES',
                  onPressed: busy ? null : _save,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Empty state for [EditTaskScreen] when the requested note id can't be
/// found in [tasksProvider]. Kept as a dedicated widget so the parent
/// stays a stateless [ConsumerWidget].
class _NoteNotFound extends StatelessWidget {
  const _NoteNotFound({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
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
}