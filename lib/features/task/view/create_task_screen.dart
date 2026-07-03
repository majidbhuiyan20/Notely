import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../model/note_data.dart';
import '../model/notes_repository.dart';
import '../../widgets/back_button.dart';
import 'task_form.dart';

/// Screen for creating a brand new note. Mirrors the EditNote layout (title,
/// category, description, checklist) so the two experiences feel
/// consistent.
class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key, this.initialCategory});

  /// Optional category to preselect when navigating from the category
  /// details screen.
  final String? initialCategory;

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  late final NotesRepository _repo;
  late final TaskFormController _form;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _repo = NotesRepository.instance;
    _repo.addListener(_onRepoChanged);
    _form = TaskFormController(
      category: widget.initialCategory ?? 'Personal',
    );
    _form.onChanged = () {
      if (mounted) setState(() {});
    };
    _initialized = true;
  }

  void _onRepoChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepoChanged);
    _form.dispose();
    super.dispose();
  }

  void _save() {
    final snap = _form.snapshot();
    if (snap.title.isEmpty && snap.checklist.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a title or checklist item first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final id = 'n${DateTime.now().millisecondsSinceEpoch}';
    final meta = _repo.categoryMeta(snap.category);
    final note = NoteData(
      id: id,
      title: snap.title.isEmpty ? 'Untitled' : snap.title,
      description: snap.description,
      category: snap.category,
      categoryColor: meta.color,
      categoryIcon: meta.icon,
      status: NoteStatus.pending,
      priority: snap.priority,
      checklist: snap.checklist,
    );
    _repo.addNote(note);
    Navigator.pop(context, note);
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        appBar: const NotelyAppBar(title: 'New Note'),
        body: const SizedBox.shrink(),
      );
    }

    final accent = AppColors.royalBlue;
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: NotelyAppBar(
        title: 'New Note',
        actions: [
          TextButton(
            onPressed: _save,
            style: TextButton.styleFrom(foregroundColor: accent),
            child: const Text(
              'Save',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: TaskFormBody(controller: _form),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: TaskFormSaveButton(
              label: 'CREATE NOTE',
              onPressed: _save,
            ),
          ),
        ],
      ),
    );
  }
}
