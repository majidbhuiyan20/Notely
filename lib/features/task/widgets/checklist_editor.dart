import 'package:flutter/material.dart';
import 'check_list_item.dart';
import 'section_label.dart';
import '../model/note_data.dart';

/// Editable checklist used inside the Edit Note screen.
class ChecklistEditor extends StatelessWidget {
  const ChecklistEditor({
    super.key,
    required this.checklist,
    required this.controllers,
    required this.focusNodes,
    required this.focusedItemId,
    required this.onToggle,
    required this.onAdd,
    required this.onRemove,
    required this.onTextChanged,
  });

  final List<ChecklistItemModel> checklist;
  final Map<String, TextEditingController> controllers;
  final Map<String, FocusNode> focusNodes;
  final String? focusedItemId;
  final ValueChanged<String> onToggle;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;
  final ValueChanged<({String id, String text})> onTextChanged;

  @override
  Widget build(BuildContext context) {
    final completed = checklist.where((c) => c.isChecked).length;
    final total = checklist.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4169E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'CHECKLIST',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF34C759).withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$completed/$total done',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B5E20),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GroupedCard(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Column(
              children: [
                for (int i = 0; i < checklist.length; i++) ...[
                  ChecklistItem(
                    title: checklist[i].title,
                    isChecked: checklist[i].isChecked,
                    isEditing: focusedItemId == checklist[i].id,
                    controller: controllers[checklist[i].id],
                    focusNode: focusNodes[checklist[i].id],
                    onTap: () => onToggle(checklist[i].id),
                    onDelete: () => onRemove(checklist[i].id),
                    onChanged: (v) => onTextChanged((id: checklist[i].id, text: v)),
                  ),
                  if (i != checklist.length - 1)
                    const Divider(
                        height: 1,
                        indent: 42,
                        color: Color(0x14000000)),
                ],
                _AddItemRow(onTap: onAdd),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AddItemRow extends StatelessWidget {
  const _AddItemRow({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Row(
            children: [
              Container(
                height: 24,
                width: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                  border:
                      Border.all(color: Colors.grey.shade300, width: 2),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  size: 14,
                  color: Colors.black45,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Add item',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}