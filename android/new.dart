import 'package:flutter/material.dart';

class ChecklistItem extends StatelessWidget {
  final String title;
  final bool isChecked;
  final VoidCallback? onTap; // Added to make it interactive

  const ChecklistItem({
    super.key,
    required this.title,
    required this.isChecked,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isChecked ? Colors.grey.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isChecked ? Colors.transparent : Colors.black.withOpacity(
                  0.05),
            ),
          ),
          child: Row(
            children: [
              // Custom Checkbox
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 22,
                width: 22,
                decoration: BoxDecoration(
                  color: isChecked ? const Color(0xFF1B5E20) : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isChecked ? const Color(0xFF1B5E20) : Colors.grey
                        .shade300,
                    width: 2,
                  ),
                ),
                child: isChecked
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              // Task Title
              Expanded( // Added expanded to prevent overflow for long text
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isChecked ? FontWeight.w400 : FontWeight.w500,
                    decoration: isChecked ? TextDecoration.lineThrough : null,
                    color: isChecked ? Colors.grey.shade500 : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}