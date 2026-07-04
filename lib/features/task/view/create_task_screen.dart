import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../model/note_data.dart';
import '../model/notes_repository.dart';
import '../providers/notes_providers.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/back_button.dart';
import 'task_form.dart';

/// Screen for creating a brand new note. Mirrors the EditNote layout
/// (title, category, description, checklist) so the two experiences
/// feel consistent. On Save the new note is persisted to sqflite (and
/// pushed to Firestore in the background) via [TasksNotifier].
///
/// Uses a [ValueNotifier] for the spinner-vs-button-label toggle instead
/// of `setState` so toggling it doesn't trigger a full widget rebuild.
class CreateTaskScreen extends ConsumerStatefulWidget {
  const CreateTaskScreen({super.key, this.initialCategory});

  /// Optional category to preselect when navigating from the category
  /// details screen.
  final String? initialCategory;

  @override
  ConsumerState<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen> {
  late final TaskFormController _form;
  final ValueNotifier<bool> _busy = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _form = TaskFormController(
      category: widget.initialCategory ?? 'Personal',
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
    if (snap.title.isEmpty && snap.checklist.isEmpty) {
      AppSnackbar.error(
        context,
        'Add a title or checklist item first.',
      );
      return;
    }

    final id = 'n_${DateTime.now().microsecondsSinceEpoch}';
    final meta = NotesRepository.instance.categoryMeta(snap.category);
    final note = NoteData(
      id: id,
      title: snap.title.isEmpty ? 'Untitled' : snap.title,
      description: snap.description,
      category: snap.category,
      categoryColor: meta.color,
      categoryIcon: meta.icon,
      status: NoteStatus.pending,
      priority: snap.priority,
      dueDate: _dueDateDisplay(snap.dueDate),
      dueTime: snap.dueTime,
      dueDateIso: snap.dueDate == null ? null : _iso(snap.dueDate!),
      checklist: snap.checklist,
    );

    _busy.value = true;
    try {
      await ref.read(tasksProvider.notifier).upsert(note);
      if (!mounted) return;
      AppSnackbar.success(context, 'Note created');
      Navigator.pop(context, note);
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, e.toString());
    } finally {
      if (mounted) _busy.value = false;
    }
  }

  /// Cheap human-readable label for the task details screen's "Due Date"
  /// row. Calendar feature reads [NoteData.dueDateIso] separately.
  String _dueDateDisplay(DateTime? d) {
    if (d == null) return '';
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

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.royalBlue;
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: NotelyAppBar(
        title: 'New Note',
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
                  label: busy ? 'SAVING…' : 'CREATE NOTE',
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