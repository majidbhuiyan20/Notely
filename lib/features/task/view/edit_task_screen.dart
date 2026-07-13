import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../model/note_data.dart';
import '../model/notes_repository.dart';
import '../providers/notes_providers.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/back_button.dart';
import 'task_form.dart';

/// Edit screen for an existing note. Mirrors [CreateTaskScreen] layout
/// so the two experiences feel consistent.
class EditTaskScreen extends ConsumerWidget {
  const EditTaskScreen({super.key, this.noteId});
  final String? noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = noteId;
    final list = ref.watch(tasksProvider).value ?? const [];
    final note = id == null
        ? null
        : list.cast<NoteData?>().firstWhere(
            (n) => n?.id == id,
            orElse: () => null,
          );

    if (note == null) return const _NoteNotFound();

    return _EditTaskScreenBody(note: note);
  }
}

class _EditTaskScreenBody extends ConsumerStatefulWidget {
  const _EditTaskScreenBody({required this.note});
  final NoteData note;

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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: NotelyAppBar(
        title: 'Edit Note',
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: _busy,
            builder: (context, busy, _) {
              return TextButton(
                onPressed: busy ? null : _save,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.brandPrimary,
                ),
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
                          fontWeight: FontWeight.w800,
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
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 18,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            child: ValueListenableBuilder<bool>(
              valueListenable: _busy,
              builder: (context, busy, _) {
                return TaskFormSaveButton(
                  label: busy ? 'SAVING…' : 'SAVE CHANGES',
                  onPressed: busy ? null : _save,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteNotFound extends StatelessWidget {
  const _NoteNotFound();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
      body: Center(
        child: Text(
          'Note not found',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ),
    );
  }
}
