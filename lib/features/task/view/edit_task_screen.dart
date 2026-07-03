import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../model/note_data.dart';
import '../model/notes_repository.dart';
import '../widgets/category_selector.dart';
import '../widgets/checklist_editor.dart';
import '../widgets/edit_field_card.dart';
import '../../widgets/back_button.dart';

class EditTaskScreen extends StatefulWidget {
  const EditTaskScreen({super.key, this.noteId});
  final String? noteId;

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  late NotesRepository _repo;
  NoteData? _note;
  bool _initialized = false;

  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late String _selectedCategory;
  late List<ChecklistItemModel> _checklist;
  late Map<String, TextEditingController> _itemControllers;
  late Map<String, FocusNode> _itemFocusNodes;
  String? _focusedItemId;

  @override
  void initState() {
    super.initState();
    _repo = NotesRepository.instance;
    _repo.addListener(_onRepoChanged);
    _hydrate();
  }

  void _hydrate() {
    _note = widget.noteId == null ? null : _repo.noteById(widget.noteId!);
    _titleController =
        TextEditingController(text: _note?.title ?? '');
    _contentController =
        TextEditingController(text: _note?.description ?? '');
    _selectedCategory = _note?.category ?? 'Personal';

    final initial = _note?.checklist ?? [];
    _checklist = initial
        .map((c) => ChecklistItemModel(
              id: c.id,
              title: c.title,
              isChecked: c.isChecked,
            ))
        .toList();

    _itemControllers = {
      for (final item in _checklist) item.id: TextEditingController(text: item.title),
    };
    _itemFocusNodes = {
      for (final item in _checklist)
        item.id: () {
          final node = FocusNode();
          node.addListener(() {
            if (!mounted) return;
            if (!node.hasFocus) {
              setState(() => _focusedItemId = null);
            }
          });
          return node;
        }(),
    };
    _initialized = true;
  }

  void _onRepoChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepoChanged);
    _titleController.dispose();
    _contentController.dispose();
    for (final c in _itemControllers.values) {
      c.dispose();
    }
    for (final f in _itemFocusNodes.values) {
      f.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      final newItem = ChecklistItemModel(id: newId, title: '');
      _checklist.add(newItem);
      _itemControllers[newId] = TextEditingController();
      final node = FocusNode();
      node.addListener(() {
        if (!mounted) return;
        if (!node.hasFocus) {
          setState(() => _focusedItemId = null);
        }
      });
      _itemFocusNodes[newId] = node;
      _focusedItemId = newId;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _itemFocusNodes[newId]?.requestFocus();
    });
  }

  void _removeItem(String id) {
    setState(() {
      _checklist.removeWhere((c) => c.id == id);
      _itemControllers[id]?.dispose();
      _itemFocusNodes[id]?.dispose();
      _itemControllers.remove(id);
      _itemFocusNodes.remove(id);
    });
  }

  void _toggleItem(String id) {
    setState(() {
      final i = _checklist.indexWhere((c) => c.id == id);
      if (i != -1) _checklist[i].isChecked = !_checklist[i].isChecked;
    });
  }

  void _onItemTextChanged(({String id, String text}) change) {
    final i = _checklist.indexWhere((c) => c.id == change.id);
    if (i != -1) _checklist[i].title = change.text;
  }

  void _save() {
    for (final item in _checklist) {
      final c = _itemControllers[item.id];
      if (c != null) {
        item.title = c.text.trim();
      }
    }
    _checklist.removeWhere((c) => c.title.isEmpty);

    final note = _note;
    if (note == null) {
      Navigator.pop(context);
      return;
    }

    note.title = _titleController.text.trim().isEmpty
        ? 'Untitled'
        : _titleController.text.trim();
    note.description = _contentController.text.trim();
    note.category = _selectedCategory;
    note.checklist
      ..clear()
      ..addAll(_checklist);

    _repo.replaceNote(note);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized || _note == null) {
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

    final accent = AppColors.royalBlue;

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
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TitleCard(
              controller: _titleController,
              accent: accent,
            ),
            const SizedBox(height: 16),
            EditFieldCard(
              label: 'CATEGORY',
              child: CategorySelector(
                initialCategory: _selectedCategory,
                onCategorySelected: (c) =>
                    setState(() => _selectedCategory = c),
              ),
            ),
            const SizedBox(height: 16),
            EditFieldCard(
              label: 'DESCRIPTION',
              child: TextField(
                controller: _contentController,
                maxLines: 6,
                minLines: 4,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF1E1E1E),
                  height: 1.45,
                  fontWeight: FontWeight.w400,
                ),
                decoration: InputDecoration(
                  hintText: 'Write your thoughts...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  isCollapsed: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ChecklistEditor(
              checklist: _checklist,
              controllers: _itemControllers,
              focusNodes: _itemFocusNodes,
              focusedItemId: _focusedItemId,
              onToggle: _toggleItem,
              onAdd: _addItem,
              onRemove: _removeItem,
              onTextChanged: _onItemTextChanged,
            ),
            const SizedBox(height: 28),
            _SaveButton(onPressed: _save),
          ],
        ),
      ),
    );
  }
}

class _TitleCard extends StatelessWidget {
  const _TitleCard({required this.controller, required this.accent});
  final TextEditingController controller;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return EditFieldCard(
      label: 'TITLE',
      child: TextField(
        controller: controller,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: Color(0xFF1E1E1E),
          letterSpacing: -0.4,
        ),
        maxLines: 2,
        minLines: 1,
        decoration: InputDecoration(
          hintText: 'Untitled Note',
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
          border: InputBorder.none,
          isCollapsed: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.royalBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'SAVE CHANGES',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}