import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../model/note_data.dart';
import '../widgets/category_selector.dart';
import '../widgets/checklist_editor.dart';
import '../widgets/priority_selector.dart';

/// State container for the note form. Holds all controllers + per-field
/// values so the parent screen stays stateless and rebuilds can be
/// driven by a single [ListenableBuilder].
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

/// Premium form body. Uses the new AppColors/AppRadius tokens. Stacked
/// cards on a tinted background.
class TaskFormBody extends StatelessWidget {
  const TaskFormBody({
    super.key,
    required this.controller,
    this.padding =
        const EdgeInsets.fromLTRB(20, 8, 20, 120),
  });

  final TaskFormController controller;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FormHeader(),
              const SizedBox(height: AppSpacing.lg),
              const _SectionLabel('Title'),
              const SizedBox(height: AppSpacing.xs),
              _FormCard(
                child: _TitleField(controller: controller.titleController),
              ),
              const SizedBox(height: AppSpacing.lg),
              const _SectionLabel('Description'),
              const SizedBox(height: AppSpacing.xs),
              _FormCard(
                child: _DescriptionField(
                  controller: controller.descriptionController,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const _SectionLabel('Category'),
              const SizedBox(height: AppSpacing.xs),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: CategorySelector(
                  initialCategory: controller.category,
                  onCategorySelected: controller.setCategory,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const _SectionLabel('Priority'),
              const SizedBox(height: AppSpacing.xs),
              _FormCard(
                padding: const EdgeInsets.all(6),
                child: PrioritySelector(
                  initialPriority: controller.priority,
                  onPrioritySelected: controller.setPriority,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const _SectionLabel('Schedule'),
              const SizedBox(height: AppSpacing.xs),
              _DueDateCard(
                date: controller.dueDate,
                time: controller.dueTime,
                onDateChanged: controller.setDueDate,
                onTimeChanged: controller.setDueTime,
              ),
              const SizedBox(height: AppSpacing.lg),
              const _SectionLabel('Checklist'),
              const SizedBox(height: AppSpacing.xs),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: AppElevation.cardShadow,
                ),
                clipBehavior: Clip.antiAlias,
                child: ChecklistEditor(
                  checklist: controller.checklist,
                  controllers: controller.itemControllers,
                  focusNodes: controller.itemFocusNodes,
                  focusedItemId: controller.focusedItemId,
                  onToggle: controller.toggleItem,
                  onAdd: controller.addItem,
                  onRemove: controller.removeItem,
                  onTextChanged: controller.onItemTextChanged,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        );
      },
    );
  }
}

/// Eye-catching top block with category colour swatch and date stamp.
/// Anchors the screen visually so it doesn't feel like a form dump.
class _FormHeader extends StatelessWidget {
  const _FormHeader();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: kHeroGradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppElevation.brandGlow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(
              Icons.edit_note_rounded,
              size: 28,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${months[now.month - 1]} ${now.day}, ${now.year}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Capture your idea',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          letterSpacing: 1.4,
          fontWeight: FontWeight.w700,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.child, this.padding});
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppElevation.cardShadow,
      ),
      child: child,
    );
  }
}

class _TitleField extends StatelessWidget {
  const _TitleField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 2,
      minLines: 1,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: -0.4,
        height: 1.3,
      ),
      decoration: InputDecoration(
        hintText: 'What is this note about?',
        hintStyle: TextStyle(
          color: AppColors.textTertiary.withValues(alpha: 0.85),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        border: InputBorder.none,
        isCollapsed: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        filled: false,
        counterText: '',
      ),
    );
  }
}

class _DescriptionField extends StatelessWidget {
  const _DescriptionField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 10,
      minLines: 5,
      textInputAction: TextInputAction.newline,
      keyboardType: TextInputType.multiline,
      style: const TextStyle(
        fontSize: 15,
        color: AppColors.textPrimary,
        height: 1.55,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText:
            'Write your thoughts, meeting notes, or anything worth keeping…',
        hintStyle: TextStyle(
          color: AppColors.textTertiary.withValues(alpha: 0.85),
          fontSize: 15,
          fontWeight: FontWeight.w500,
          height: 1.55,
        ),
        border: InputBorder.none,
        isCollapsed: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        filled: false,
      ),
    );
  }
}

/// Tappable rows for date + optional time, on a premium card.
class _DueDateCard extends StatelessWidget {
  const _DueDateCard({
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
    final hasTime = time.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppElevation.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _Row(
            icon: Icons.event_outlined,
            label: 'Date',
            value: hasDate ? _formatDate(date!) : 'No due date',
            placeholder: !hasDate,
            onTap: () => _pickDate(context),
            onClear: hasDate ? () => onDateChanged(null) : null,
          ),
          const _Divider(),
          _Row(
            icon: Icons.schedule_outlined,
            label: 'Time',
            value:
                hasTime ? DateFormatter.formatTime12h(time) : 'All day',
            placeholder: !hasTime,
            onTap: hasDate ? () => _pickTime(context) : null,
            onClear: hasTime ? () => onTimeChanged('') : null,
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final wasEmpty = date == null;
    final initial = date ?? DateTime.now();
    DateTime selected =
        DateTime(initial.year, initial.month, initial.day);

    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: SizedBox(
          height: 340,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.md,
                ),
                child: Text(
                  'Pick a date',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
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
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xs,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(selected),
                    child: const Text('Set date'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (picked == null) return;
    onDateChanged(picked);

    if (wasEmpty && time.isEmpty && context.mounted) {
      HapticFeedback.lightImpact();
    }
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

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onTap,
    required this.onClear,
  });
  final IconData icon;
  final String label;
  final String value;
  final bool placeholder;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                icon,
                size: 18,
                color: AppColors.brandPrimary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: placeholder
                          ? AppColors.textTertiary
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (onClear != null)
              InkResponse(
                onTap: onClear,
                radius: 18,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: AppColors.textTertiary,
                  ),
                ),
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.only(left: AppSpacing.lg + 38 + AppSpacing.md),
        child: Divider(height: 1, color: AppColors.divider),
      );
}

/// Premium gradient pill save button.
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
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.brandGradient,
        ),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: AppElevation.brandGlow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: onPressed,
          child: SizedBox(
            width: double.infinity,
            height: 58,
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
