import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/route/app_route.dart';
import '../model/note_data.dart';
import '../model/notes_repository.dart';
import '../widgets/task_checklist_section.dart';
import '../widgets/task_description_section.dart';
import '../widgets/task_hero_card.dart';
import '../widgets/task_meta_section.dart';
import '../../widgets/back_button.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key, this.noteId});
  final String? noteId;

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  late final NotesRepository _repo;
  NoteData? _note;

  @override
  void initState() {
    super.initState();
    _repo = NotesRepository.instance;
    _note = _resolveNote();
    _repo.addListener(_onRepoChanged);
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepoChanged);
    super.dispose();
  }

  NoteData? _resolveNote() {
    if (widget.noteId == null) return null;
    return _repo.noteById(widget.noteId!);
  }

  void _onRepoChanged() {
    setState(() {
      _note = _resolveNote();
    });
  }

  void _toggleChecklist(int index) {
    final n = _note;
    if (n == null) return;
    setState(() {
      n.checklist[index].isChecked = !n.checklist[index].isChecked;
    });
  }

  void _markAllComplete() {
    final n = _note;
    if (n == null) return;
    setState(() {
      for (final c in n.checklist) {
        c.isChecked = true;
      }
      n.status = NoteStatus.completed;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Marked all checklist items done'),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFF34C759),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openEdit() {
    if (_note == null) return;
    Navigator.pushNamed(
      context,
      Routes.editTaskRoute,
      arguments: _note!.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final note = _note;

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
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert_rounded,
                color: Color(0xFF1E1E1E), size: 22),
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
            TaskChecklistSection(note: note, onToggle: _toggleChecklist),
            const SizedBox(height: 28),
            _MarkAllCompleteButton(onPressed: _markAllComplete),
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