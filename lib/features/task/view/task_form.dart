import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../model/note_data.dart';
import '../widgets/category_selector.dart';
import '../widgets/checklist_editor.dart';
import '../widgets/edit_field_card.dart';
import '../widgets/priority_selector.dart';

/// Shared form body used by both Create and Edit task screens. Keeps the
/// layout, controllers, checklist state and Save button in a single place so
/// the screens stay in sync visually.
///
/// The controller is a [ChangeNotifier] rather than a bare class with an
/// `onChanged` callback so consumers can `addListener` (or use it as a
/// Riverpod-like notifier) without each parent having to wire a
/// `setState` lambda and risk mid-frame rebuilds.
class TaskFormController extends ChangeNotifier {
  TaskFormController({
    String? title,
    String? description,
    String category = 'Personal',
    NotePriority priority = NotePriority.medium,
    DateTime? dueDate,
    String? dueTime,
    List<ChecklistItemModel>? checklist,
  })  : _title = TextEditingController(text: title ?? ''),
        _description = TextEditingController(text: description ?? ''),
        _category = category,
        _priority = priority,
        _dueDate = dueDate,
        _dueTime = dueTime ?? '',
        _checklist = List<ChecklistItemModel>.from(checklist ?? const []),
        _itemControllers = {},
        _itemFocusNodes = {} {
    _title.addListener(notifyListeners);
    _description.addListener(notifyListeners);
    for (final item in _checklist) {
      final controller = TextEditingController(text: item.title);
      _itemControllers[item.id] = controller;
      _itemFocusNodes[item.id] = _buildFocusNode();
      controller.addListener(notifyListeners);
    }
  }

  final TextEditingController _title;
  final TextEditingController _description;
  String _category;
  NotePriority _priority;
  DateTime? _dueDate;
  String _dueTime;
  final List<ChecklistItemModel> _checklist;
  final Map<String, TextEditingController> _itemControllers;
  final Map<String, FocusNode> _itemFocusNodes;
  String? _focusedItemId;

  TextEditingController get titleController => _title;
  TextEditingController get descriptionController => _description;
  String get category => _category;
  NotePriority get priority => _priority;
  DateTime? get dueDate => _dueDate;
  String get dueTime => _dueTime;
  List<ChecklistItemModel> get checklist => _checklist;
  Map<String, TextEditingController> get itemControllers => _itemControllers;
  Map<String, FocusNode> get itemFocusNodes => _itemFocusNodes;
  String? get focusedItemId => _focusedItemId;

  FocusNode _buildFocusNode() {
    final node = FocusNode();
    node.addListener(notifyListeners);
    return node;
  }

  void setCategory(String value) {
    _category = value;
    notifyListeners();
  }

  void setPriority(NotePriority value) {
    _priority = value;
    notifyListeners();
  }

  void setDueDate(DateTime? value) {
    _dueDate = value;
    if (value == null) _dueTime = '';
    notifyListeners();
  }

  void setDueTime(String value) {
    _dueTime = value;
    notifyListeners();
  }

  void addItem() {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    _checklist.add(ChecklistItemModel(id: newId, title: ''));
    final controller = TextEditingController();
    _itemControllers[newId] = controller;
    _itemFocusNodes[newId] = _buildFocusNode();
    controller.addListener(notifyListeners);
    _focusedItemId = newId;
    notifyListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _itemFocusNodes[newId]?.requestFocus();
    });
  }

  void removeItem(String id) {
    _checklist.removeWhere((c) => c.id == id);
    final c = _itemControllers.remove(id);
    c?.removeListener(notifyListeners);
    c?.dispose();
    final f = _itemFocusNodes.remove(id);
    f?.removeListener(notifyListeners);
    f?.dispose();
    notifyListeners();
  }

  void toggleItem(String id) {
    final i = _checklist.indexWhere((c) => c.id == id);
    if (i != -1) _checklist[i].isChecked = !_checklist[i].isChecked;
    notifyListeners();
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
      dueTime: _dueTime,
      checklist: List<ChecklistItemModel>.from(_checklist),
    );
  }

  @override
  void dispose() {
    _title.removeListener(notifyListeners);
    _description.removeListener(notifyListeners);
    for (final c in _itemControllers.values) {
      c.removeListener(notifyListeners);
      c.dispose();
    }
    for (final f in _itemFocusNodes.values) {
      f.removeListener(notifyListeners);
      f.dispose();
    }
    super.dispose();
  }
}

class TaskFormResult {
  TaskFormResult({
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.dueDate,
    required this.dueTime,
    required this.checklist,
  });
  final String title;
  final String description;
  final String category;
  final NotePriority priority;
  final DateTime? dueDate;
  final String dueTime;
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
    // Listen to controller changes (text edits, category picks, checklist
    // add/remove) so the body stays in sync without each parent wiring
    // its own `setState` callback. The `_TaskFormBodyListener` does the
    // actual rebuild — `build` itself stays pure.
    return _TaskFormBodyListener(
      controller: controller,
      child: SingleChildScrollView(
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
              date: controller.dueDate,
              time: controller.dueTime,
              onDateChanged: controller.setDueDate,
              onTimeChanged: controller.setDueTime,
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
      ),
    );
  }
}

/// Subscribes to a [TaskFormController] and rebuilds when it changes.
/// Why this exists: controllers like [_TitleCard] and [CategorySelector]
/// were previously driven by an `onChanged` callback that called
/// `setState` on the parent — a pattern that races with Riverpod's
/// provider-driven rebuild chain. Using a [Listenable] + [ListenableBuilder]
/// keeps the rebuild scoped to this widget and avoids racing with parent
/// rebuilds.
class _TaskFormBodyListener extends StatelessWidget {
  const _TaskFormBodyListener({
    required this.controller,
    required this.child,
  });

  final TaskFormController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => child,
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

/// iOS-style tappable rows for the date + (optional) time of a note.
///
/// After the user picks a date, an "Add a time?" confirm sheet appears.
/// Saying yes opens `showTimePicker`; saying no keeps the task all-day.
/// The date is required to set a time — clearing the date also clears
/// the time.
class _DueDateRow extends StatelessWidget {
  const _DueDateRow({
    required this.date,
    required this.time,
    required this.onDateChanged,
    required this.onTimeChanged,
  });

  final DateTime? date;
  final String time;
  final ValueChanged<DateTime?> onDateChanged;
  final ValueChanged<String> onTimeChanged;

  @override
  Widget build(BuildContext context) {
    final hasDate = date != null;
    return Column(
      children: [
        EditFieldCard(
          label: 'DUE DATE',
          child: Row(
            children: [
              Expanded(
                child: Text(
                  hasDate ? _formatDate(date!) : 'No due date',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: hasDate
                        ? const Color(0xFF1E1E1E)
                        : Colors.grey.shade500,
                  ),
                ),
              ),
              if (hasDate)
                GestureDetector(
                  onTap: () => onDateChanged(null),
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
                onTap: () => _pickDate(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.royalBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    hasDate ? 'Change' : 'Set date',
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
        ),
        if (hasDate) ...[
          const SizedBox(height: 10),
          EditFieldCard(
            label: 'TIME',
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    time.isEmpty
                        ? 'No time set (all-day)'
                        : DateFormatter.formatTime12h(time),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: time.isEmpty
                          ? Colors.grey.shade500
                          : const Color(0xFF1E1E1E),
                    ),
                  ),
                ),
                if (time.isNotEmpty)
                  GestureDetector(
                    onTap: () => onTimeChanged(''),
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
                  onTap: () => _pickTime(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.royalBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      time.isEmpty ? 'Add time' : 'Change',
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
          ),
        ],
      ],
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final wasEmpty = date == null;
    final initial = date ?? DateTime.now();
    DateTime selected = DateTime(initial.year, initial.month, initial.day);

    final picked = await showModalBottomSheet<DateTime>(
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
                      onPressed: () => Navigator.of(ctx).pop(selected),
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

    if (picked == null) return;
    onDateChanged(picked);

    // Auto-prompt for a time whenever the user picks a brand-new date
    // and the existing entry had no time yet (or was empty before).
    if (wasEmpty && time.isEmpty && context.mounted) {
      await _maybeAskForTime(context);
    }
  }

  Future<void> _maybeAskForTime(BuildContext context) async {
    final ask = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Add a time?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E1E1E),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Schedules the note on your calendar at a specific hour.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1E1E1E),
                        side: BorderSide(color: Colors.grey.shade300),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.royalBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Pick time',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (ask != true || !context.mounted) return;
    await _pickTime(context);
  }

  Future<void> _pickTime(BuildContext context) async {
    final initial =
        DateFormatter.parseTime24h(time) ?? TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) {
        return MediaQuery(
          data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked == null) return;
    onTimeChanged(DateFormatter.formatTime24h(picked));
  }

  String _formatDate(DateTime d) {
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
