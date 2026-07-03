import 'package:flutter/material.dart';

class ChecklistItem extends StatefulWidget {
  final String title;
  final bool isChecked;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final ValueChanged<String>? onChanged;
  final bool isEditing;
  final TextEditingController? controller;
  final FocusNode? focusNode;

  const ChecklistItem({
    super.key,
    required this.title,
    required this.isChecked,
    this.onTap,
    this.onDelete,
    this.onChanged,
    this.isEditing = false,
    this.controller,
    this.focusNode,
  });

  @override
  State<ChecklistItem> createState() => _ChecklistItemState();
}

class _ChecklistItemState extends State<ChecklistItem>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isChecked
        ? Colors.grey.withOpacity(0.06)
        : (_pressed ? Colors.black.withOpacity(0.04) : Colors.white);

    return AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: GestureDetector(
        onTapDown: widget.isEditing
            ? null
            : (_) => setState(() => _pressed = true),
        onTapUp: widget.isEditing
            ? null
            : (_) => setState(() => _pressed = false),
        onTapCancel: widget.isEditing ? null : () => setState(() => _pressed = false),
        onTap: widget.isEditing ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isChecked
                  ? Colors.transparent
                  : Colors.black.withOpacity(0.06),
            ),
          ),
          child: Row(
            children: [
              _AnimatedCheckBox(
                isChecked: widget.isChecked,
                onTap: widget.isEditing ? null : widget.onTap,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: widget.isEditing
                    ? TextField(
                        controller: widget.controller,
                        focusNode: widget.focusNode,
                        onChanged: widget.onChanged,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1E1E1E),
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: "List item",
                          hintStyle: TextStyle(
                            color: Colors.black38,
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 4),
                        ),
                      )
                    : AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              widget.isChecked ? FontWeight.w400 : FontWeight.w500,
                          decoration: widget.isChecked
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          decorationColor: Colors.grey.shade400,
                          color: widget.isChecked
                              ? Colors.grey.shade500
                              : const Color(0xFF1E1E1E),
                        ),
                        child: Text(widget.title),
                      ),
              ),
              if (widget.isEditing && widget.onDelete != null)
                _DeleteButton(onTap: widget.onDelete!),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedCheckBox extends StatelessWidget {
  final bool isChecked;
  final VoidCallback? onTap;
  const _AnimatedCheckBox({required this.isChecked, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        height: 24,
        width: 24,
        decoration: BoxDecoration(
          color: isChecked ? const Color(0xFF34C759) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: isChecked
                ? const Color(0xFF34C759)
                : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: animation,
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: isChecked
              ? const Icon(Icons.check_rounded,
                  size: 16, color: Colors.white, key: ValueKey('checked'))
              : const SizedBox.shrink(key: ValueKey('unchecked')),
        ),
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  final VoidCallback onTap;
  const _DeleteButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.close_rounded,
          color: Colors.red,
          size: 14,
        ),
      ),
    );
  }
}