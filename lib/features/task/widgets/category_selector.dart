import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../category/model/category_model.dart';

/// Horizontal pill row used in the create / edit task form. Stateless:
/// the selected category is owned entirely by the parent's
/// [TaskFormController] and bubbled back up via [onCategorySelected].
class CategorySelector extends StatelessWidget {
  const CategorySelector({
    super.key,
    required this.initialCategory,
    required this.onCategorySelected,
  });

  final String initialCategory;
  final ValueChanged<String> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Category",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E1E1E),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 50,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: CategoryModel.all.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final category = CategoryModel.all[index];
              final isSelected = initialCategory == category.title;
              return GestureDetector(
                onTap: () => onCategorySelected(category.title),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.royalBlue
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.royalBlue
                          : Colors.grey.shade200,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.royalBlue.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : [],
                  ),
                  child: Center(
                    child: Text(
                      category.title,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}