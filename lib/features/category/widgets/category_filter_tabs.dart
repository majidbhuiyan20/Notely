import 'package:flutter/material.dart';

enum CategoryFilter { all, pending, completed }

extension CategoryFilterX on CategoryFilter {
  String get label {
    switch (this) {
      case CategoryFilter.all:
        return 'All';
      case CategoryFilter.pending:
        return 'Pending';
      case CategoryFilter.completed:
        return 'Completed';
    }
  }
}

/// Pill-style segmented filter row with counts on each tab.
class CategoryFilterTabs extends StatelessWidget {
  const CategoryFilterTabs({
    super.key,
    required this.active,
    required this.onChanged,
    required this.allCount,
    required this.pendingCount,
    required this.completedCount,
    this.color = const Color(0xFF4169E1),
  });

  final CategoryFilter active;
  final ValueChanged<CategoryFilter> onChanged;
  final int allCount;
  final int pendingCount;
  final int completedCount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E5EA).withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _Tab(
            label: 'All',
            count: allCount,
            isActive: active == CategoryFilter.all,
            color: color,
            onTap: () => onChanged(CategoryFilter.all),
          ),
          _Tab(
            label: 'Pending',
            count: pendingCount,
            isActive: active == CategoryFilter.pending,
            color: const Color(0xFFFF9500),
            onTap: () => onChanged(CategoryFilter.pending),
          ),
          _Tab(
            label: 'Completed',
            count: completedCount,
            isActive: active == CategoryFilter.completed,
            color: const Color(0xFF34C759),
            onTap: () => onChanged(CategoryFilter.completed),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.count,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isActive ? color : Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive
                      ? color.withOpacity(0.12)
                      : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isActive ? color : Colors.grey.shade600,
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