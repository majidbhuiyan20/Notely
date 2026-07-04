import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../model/note_data.dart';
import '../widgets/category_selector.dart';
import '../widgets/checklist_editor.dart';
import '../widgets/edit_field_card.dart';
import '../widgets/priority_selector.dart';

/// Shared form body used by both Create and Edit task screens. Keeps the
/// layout, controllers, checklist state and Save button in a single place so
/// the screens stay in sync visually.
class TaskFormController {
  TaskFormController({
    String? title,
    String? description,
    String category = 'Personal',
    NotePriority priority = NotePriority.medium,
    DateTime? dueDate,
    List<ChecklistItemModel>? checklist,
  })  : _title = TextEditingController(text: title ?? ''),
        _description = TextEditingController(text: description ?? ''),
        _category = category,
        _priority = priority,
        _dueDate = dueDate,
        _checklist = List<ChecklistItemModel>.from(checklist ?? const []),
        _itemControllers = {},
        _itemFocusNodes = {} {
    for (final item in _checklist) {
      _itemControllers[item.id] = TextEditingController(text: item.title);
      _itemFocusNodes[item.id] = _buildFocusNode();
    }
  }

  final TextEditingController _title;
  final TextEditingController _description;
  String _category;
  NotePriority _priority;
  DateTime? _dueDate;
  final List<ChecklistItemModel> _checklist;
  final Map<String, TextEditingController> _itemControllers;
  final Map<String, FocusNode> _itemFocusNodes;
  String? _focusedItemId;

  TextEditingController get titleController => _title;
  TextEditingController get descriptionController => _description;
  String get category => _category;
  NotePriority get priority => _priority;
  DateTime? get dueDate => _dueDate;
  List<ChecklistItemModel> get checklist => _checklist;
  Map<String, TextEditingController> get itemControllers => _itemControllers;
  Map<String, FocusNode> get itemFocusNodes => _itemFocusNodes;
  String? get focusedItemId => _focusedItemId;

  Function()? onChanged;

  FocusNode _buildFocusNode() {
    final node = FocusNode();
    node.addListener(() {
      if (onChanged == null) return;
      if (!node.hasFocus) onChanged!.call();
    });
    return node;
  }

  void setCategory(String value) {
    _category = value;
    onChanged?.call();
  }

  void setPriority(NotePriority value) {
    _priority = value;
    onChanged?.call();
  }

  void setDueDate(DateTime? value) {
    _dueDate = value;
    onChanged?.call();
  }

  void addItem() {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    _checklist.add(ChecklistItemModel(id: newId, title: ''));
    _itemControllers[newId] = TextEditingController();
    _itemFocusNodes[newId] = _buildFocusNode();
    _focusedItemId = newId;
    onChanged?.call();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _itemFocusNodes[newId]?.requestFocus();
    });
  }

  void removeItem(String id) {
    _checklist.removeWhere((c) => c.id == id);
    _itemControllers[id]?.dispose();
    _itemFocusNodes[id]?.dispose();
    _itemControllers.remove(id);
    _itemFocusNodes.remove(id);
    onChanged?.call();
  }

  void toggleItem(String id) {
    final i = _checklist.indexWhere((c) => c.id == id);
    if (i != -1) _checklist[i].isChecked = !_checklist[i].isChecked;
    onChanged?.call();
  }

  void onItemTextChanged(({String id, String text}) change) {
    final i = _checklist.indexWhere((c) => c.id == change.id);
    if (i != -1) _checklist[i].title = change.text;
  }

  /// Pulls current text from controllers and drops empty checklist items.
  /// Returns the values needed to build/save a [NoteData].
  TaskFormResult snapshot() {
    for (final item in _checklist) {
      final c = _itemControllers[item.id];
      if (c != null) item.title = c.text.trim();
    }
    _checklist.removeWhere((c) => c.title.isEmpty);
    return TaskFormResult(
      title: _title.text.trim(),
      description: _description.text.trim(),
      category: _category,
      priority: _priority,
      dueDate: _dueDate,
      checklist: List<ChecklistItemModel>.from(_checklist),
    );
  }

  void dispose() {
    _title.dispose();
    _description.dispose();
    for (final c in _itemControllers.values) {
      c.dispose();
    }
    for (final f in _itemFocusNodes.values) {
      f.dispose();
    }
  }
}

class TaskFormResult {
  TaskFormResult({
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.dueDate,
    required this.checklist,
  });
  final String title;
  final String description;
  final String category;
  final NotePriority priority;
  final DateTime? dueDate;
  final List<ChecklistItemModel> checklist;
}

class TaskFormBody extends StatelessWidget {
  const TaskFormBody({
    super.key,
    required this.controller,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 32),
  });

  final TaskFormController controller;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.royalBlue;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TitleCard(
            controller: controller.titleController,
            accent: accent,
          ),
          const SizedBox(height: 16),
          EditFieldCard(
            label: 'CATEGORY',
            child: CategorySelector(
              initialCategory: controller.category,
              onCategorySelected: controller.setCategory,
            ),
          ),
          const SizedBox(height: 16),
          EditFieldCard(
            label: 'DESCRIPTION',
            child: TextField(
              controller: controller.descriptionController,
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
          EditFieldCard(
            label: 'PRIORITY',
            child: PrioritySelector(
              initialPriority: controller.priority,
              onPrioritySelected: controller.setPriority,
            ),
          ),
          const SizedBox(height: 16),
          _DueDateRow(
            value: controller.dueDate,
            onChanged: controller.setDueDate,
          ),
          const SizedBox(height: 16),
          ChecklistEditor(
            checklist: controller.checklist,
            controllers: controller.itemControllers,
            focusNodes: controller.itemFocusNodes,
            focusedItemId: controller.focusedItemId,
            onToggle: controller.toggleItem,
            onAdd: controller.addItem,
            onRemove: controller.removeItem,
            onTextChanged: controller.onItemTextChanged,
          ),
        ],
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

class TaskFormSaveButton extends StatelessWidget {
  const TaskFormSaveButton({
    super.key,
    required this.label,
    required this.onPressed,
  });
  final String label;
  final VoidCallback? onPressed;

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
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

/// iOS-style tappable row that opens a modal date picker. Writes the
/// picked DateTime (or null if "Clear") through [onChanged].
class _DueDateRow extends StatelessWidget {
  const _DueDateRow({required this.value, required this.onChanged});
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    return EditFieldCard(
      label: 'DUE DATE',
      child: Row(
        children: [
          Expanded(
            child: Text(
              value == null ? 'No due date' : _format(value!),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: value == null ? Colors.grey.shade500 : const Color(0xFF1E1E1E),
              ),
            ),
          ),
          if (value != null)
            GestureDetector(
              onTap: () => onChanged(null),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  'Clear',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            ),
          GestureDetector(
            onTap: () => _pick(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.royalBlue.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                value == null ? 'Set date' : 'Change',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.royalBlue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final initial = value ?? DateTime.now();
    DateTime selected = DateTime(initial.year, initial.month, initial.day);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: SizedBox(
            height: 320,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: selected,
                    minimumYear: DateTime.now().year - 2,
                    maximumYear: DateTime.now().year + 5,
                    onDateTimeChanged: (d) =>
                        selected = DateTime(d.year, d.month, d.day),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        onChanged(selected);
                        Navigator.of(ctx).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.royalBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _format(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final today = DateTime.now();
    final t = DateTime(today.year, today.month, today.day);
    final day = DateTime(d.year, d.month, d.day);
    final delta = day.difference(t).inDays;
    final base = '${months[d.month - 1]} ${d.day}, ${d.year}';
    if (delta == 0) return 'Today ($base)';
    if (delta == 1) return 'Tomorrow ($base)';
    if (delta == -1) return 'Yesterday ($base)';
    if (delta > 0) return '$base • in $delta days';
    return '$base • ${-delta} days ago';
  }
}
