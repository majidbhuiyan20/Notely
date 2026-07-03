import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../model/note_data.dart';
import '../model/notes_repository.dart';
import '../../widgets/back_button.dart';
import 'task_form.dart';

class EditTaskScreen extends StatefulWidget {
  const EditTaskScreen({super.key, this.noteId});
  final String? noteId;

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  late final NotesRepository _repo;
  NoteData? _note;
  TaskFormController? _form;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _repo = NotesRepository.instance;
    _repo.addListener(_onRepoChanged);
    _hydrate();
  }

  void _hydrate() {
    _note = widget.noteId == null ? null : _repo.noteById(widget.noteId!);
    if (_note != null) {
      _form = TaskFormController(
        title: _note!.title,
        description: _note!.description,
        category: _note!.category,
        priority: _note!.priority,
        checklist: _note!.checklist,
      );
      _form!.onChanged = () {
        if (mounted) setState(() {});
      };
    }
    _initialized = true;
  }

  void _onRepoChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepoChanged);
    _form?.dispose();
    super.dispose();
  }

  void _save() {
    final note = _note;
    final form = _form;
    if (note == null || form == null) {
      Navigator.pop(context);
      return;
    }
    final snap = form.snapshot();
    note.title = snap.title.isEmpty ? 'Untitled' : snap.title;
    note.description = snap.description;
    note.category = snap.category;
    note.priority = snap.priority;
    note.checklist
      ..clear()
      ..addAll(snap.checklist);

    final meta = _repo.categoryMeta(snap.category);
    note.categoryColor = meta.color;
    note.categoryIcon = meta.icon;

    _repo.replaceNote(note);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        appBar: const NotelyAppBar(title: 'Edit Note'),
        body: const SizedBox.shrink(),
      );
    }

    final form = _form;
    final accent = AppColors.royalBlue;

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
            child: TaskFormBody(controller: form),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: TaskFormSaveButton(
              label: 'SAVE CHANGES',
              onPressed: _save,
            ),
          ),
        ],
      ),
    );
  }
}
